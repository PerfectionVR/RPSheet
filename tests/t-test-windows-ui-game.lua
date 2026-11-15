-- Fake frame API, part 3: the game around the frames. UIParent, the tooltip, the mouse
-- and keys a test steers, timers a test runs, context menus and popups a test can
-- click, and the globals the options library reads. Loaded by t-test-windows-ui.lua.
local F = UIFAKE
local S = F.S

---------------------------------------------------------------------------
-- Globals env.lua would hand out as stubs: nil where the game has none, real otherwise
---------------------------------------------------------------------------
-- env.lua answers any unknown global with a stub. These don't exist in the game, and
-- code tests for them, so they must read as nil; fonts are made on demand.
local ABSENT = {
    InterfaceOptionsFramePanelContainer = true, InterfaceOptions_AddCategory = true, OpacitySliderFrame = true,
    ChatEdit_InsertLink = true, WOW_PROJECT_CAMELOT = true, AceGUIEditBoxInsertLink = true, AceGUIMultiLineEditBoxInsertLink = true,
    UIDROPDOWNMENU_OPEN_MENU = true, CloseDropDownMenus = true, ElvUI = true, Tukui = true,
}
do
    local mt = getmetatable(_G)
    local old = mt.__index
    mt.__index = function(t, key)
        if ABSENT[key] then return nil end
        local font = F.GameFont(key)
        if font then return font end
        return old(t, key)
    end
end

rawset(_G, "issecretvalue", function() return false end) -- the game has it since 12.0
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC = 1, 1, 2
ACCEPT, CANCEL, OKAY, CLOSE, YES, NO, NONE = "Accept", "Cancel", "Okay", "Close", "Yes", "No", "None"
NOT_BOUND, KEY_BUTTON1, KEY_BUTTON2, KEY_BUTTON3 = "Not Bound", "Left Mouse Button", "Right Mouse Button", "Middle Mouse Button"
DEFAULT, ENABLE, DISABLE, RESET, SEARCH = "Default", "Enable", "Disable", "Reset", "Search"
local function color(r, g, b)
    return { r = r, g = g, b = b, a = 1, GetRGB = function() return r, g, b end, GetRGBA = function() return r, g, b, 1 end,
        WrapTextInColorCode = function(_, text) return text end }
end
NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR, RED_FONT_COLOR = color(1, 0.82, 0), color(1, 1, 1), color(1, 0.1, 0.1)
GREEN_FONT_COLOR, GRAY_FONT_COLOR, DISABLED_FONT_COLOR = color(0.1, 1, 0.1), color(0.5, 0.5, 0.5), color(0.5, 0.5, 0.5)

UIParent = CreateFrame("Frame", "UIParent")
S[UIParent].w, S[UIParent].h = F.screenWidth, F.screenHeight
S[UIParent].points = { { point = "BOTTOMLEFT", rel = F.SCREEN, relPoint = "BOTTOMLEFT", x = 0, y = 0 } }
WorldFrame = CreateFrame("Frame", "WorldFrame")
S[WorldFrame].w, S[WorldFrame].h = F.screenWidth, F.screenHeight
S[WorldFrame].points = S[UIParent].points

GameTooltip = CreateFrame("GameTooltip", "GameTooltip", UIParent, "GameTooltipTemplate")
function GameTooltip_Hide() GameTooltip:Hide() end
function GameTooltip_SetTitle(tooltip, text, color, wrap) tooltip:SetText(text, 1, 1, 1, 1, wrap) end
function GameTooltip_AddNormalLine(tooltip, text, wrap) tooltip:AddLine(text, 1, 0.82, 0, wrap) end
function GameTooltip_AddHighlightLine(tooltip, text, wrap) tooltip:AddLine(text, 1, 1, 1, wrap) end
function GameTooltip_AddInstructionLine(tooltip, text, wrap) tooltip:AddLine(text, 0.1, 1, 0.1, wrap) end
function GameTooltip_AddErrorLine(tooltip, text, wrap) tooltip:AddLine(text, 1, 0.1, 0.1, wrap) end
function GameTooltip_AddColoredLine(tooltip, text, color, wrap) tooltip:AddLine(text, color.r, color.g, color.b, wrap) end
function GameTooltip_AddBlankLineToTooltip(tooltip) tooltip:AddLine(" ") end
function GameTooltip_SetDefaultAnchor(tooltip, parent) tooltip:SetOwner(parent, "ANCHOR_NONE") end

ColorPickerFrame = CreateFrame("Frame", "ColorPickerFrame", UIParent)
ColorPickerFrame:Hide()
-- The picker keeps what it was opened with; a test picks with F.PickColor.
function ColorPickerFrame:SetupColorPickerAndShow(info)
    F.colorPicker = info
    self.rgb, self.alpha = { info.r, info.g, info.b }, info.opacity or 1
    self:Show()
end
function ColorPickerFrame:GetColorRGB() return unpack(self.rgb or { 1, 1, 1 }) end
function ColorPickerFrame:GetColorAlpha() return self.alpha or 1 end
function F.PickColor(r, g, b, a)
    local info = F.colorPicker
    if not info then return false end
    -- as the player does it: drag in the wheel, move the opacity, press Okay
    local alpha = ColorPickerFrame.alpha
    ColorPickerFrame.rgb = { r, g, b }
    if info.swatchFunc then info.swatchFunc() end
    if a and a ~= alpha and info.hasOpacity and info.opacityFunc then
        ColorPickerFrame.alpha = a
        info.opacityFunc()
    end
    ColorPickerFrame:Hide()
    if info.swatchFunc then info.swatchFunc() end
    F.colorPicker = nil
    return true
end

Settings = {
    RegisterCanvasLayoutCategory = function(frame, name) return { name = name, frame = frame, GetID = function() return name end, ID = name } end,
    RegisterCanvasLayoutSubcategory = function(parent, frame, name) return { name = name, frame = frame, GetID = function() return name end, ID = name } end,
    RegisterAddOnCategory = function() end,
    GetCategory = function(id) return { ID = id, GetID = function() return id end } end,
    OpenToCategory = function(id) F.settingsOpened = id end,
}
function GetCursorInfo() return nil end
function ClearCursor() end
function GetMouseFocus() return F.hover end
function GetMouseFoci() return { F.hover } end
function GetScreenWidth() return F.screenWidth end
function GetScreenHeight() return F.screenHeight end
function GetPhysicalScreenSize() return F.screenWidth, F.screenHeight end

---------------------------------------------------------------------------
-- hooksecurefunc
---------------------------------------------------------------------------
function hooksecurefunc(a, b, c)
    local holder, name, hook
    if type(a) == "table" then holder, name, hook = a, b, c else holder, name, hook = _G, a, b end
    if type(hook) ~= "function" then error("hooksecurefunc: function expected", 2) end
    local original = rawget(holder, name)
    if original == nil and holder ~= _G then original = holder[name] end
    if type(original) ~= "function" then
        if original ~= nil and not IsStub(original) then error("hooksecurefunc: " .. tostring(name) .. " is not a function", 2) end
        original = function() end
    end
    rawset(holder, name, function(...)
        local n = select("#", ...)
        local args = { ... }
        local function finish(...)
            hook(unpack(args, 1, n))
            return ...
        end
        return finish(original(...))
    end)
end

---------------------------------------------------------------------------
-- Timers: queued, and run when the test says so
---------------------------------------------------------------------------
local timers = {}
F.timers = timers
local function queue(seconds, fn, repeats)
    if type(fn) ~= "function" then error("C_Timer: function expected, got " .. type(fn), 3) end
    local timer = { fn = fn, left = repeats, seconds = seconds }
    function timer:Cancel() self.cancelled = true end
    function timer:IsCancelled() return self.cancelled or false end
    timers[#timers + 1] = timer
    return timer
end
C_Timer = {
    After = function(seconds, fn) queue(seconds, fn) end,
    NewTimer = function(seconds, fn) return queue(seconds, fn) end,
    NewTicker = function(seconds, fn, iterations) return queue(seconds, fn, iterations or math.huge) end,
}
-- Runs every queued timer, and the ones those queue, a few rounds deep. A ticker runs
-- once per call. With `within`, only the timers due within that many seconds run and
-- the later ones stay queued (0: what the game would do on the next frame).
-- Returns how many ran.
function RunTimers(rounds, within)
    local ran = 0
    local later = {}
    for _ = 1, rounds or 20 do
        if #timers == 0 then break end
        local now = timers
        timers = {}
        F.timers = timers
        for _, timer in ipairs(now) do
            if timer.cancelled then
                -- dropped
            elseif within and (timer.seconds or 0) > within then
                later[#later + 1] = timer
            else
                if timer.left then
                    timer.left = timer.left - 1
                    if timer.left > 0 then later[#later + 1] = timer end
                end
                ran = ran + 1
                timer.fn(timer)
            end
        end
    end
    for _, timer in ipairs(later) do
        if not timer.cancelled then timers[#timers + 1] = timer end
    end
    return ran
end
FlushTimers = RunTimers

---------------------------------------------------------------------------
-- Mouse and keys
---------------------------------------------------------------------------
F.keys = { shift = false, ctrl = false, alt = false }
F.buttonsDown = {}
function IsShiftKeyDown() return F.keys.shift end
function IsControlKeyDown() return F.keys.ctrl end
function IsAltKeyDown() return F.keys.alt end
function IsModifierKeyDown() return F.keys.shift or F.keys.ctrl or F.keys.alt end
function IsModifiedClick() return false end
function IsMouseButtonDown(button) return F.buttonsDown[button or "LeftButton"] or false end
function GetCursorPosition() return F.mouse.x, F.mouse.y end
function F.SetKeys(shift, ctrl, alt) F.keys.shift, F.keys.ctrl, F.keys.alt = shift or false, ctrl or false, alt or false end

-- Puts the cursor on a region: `fx`, `fy` are shares of its width and height from its
-- top left corner (default the middle), `dx` pixels are added to the right.
function F.MoveMouse(region, fx, fy, dx)
    if not region then F.mouse.x, F.mouse.y = -5000, -5000 return end
    local l, b, w, h = F.Rect(region)
    local scale = region:GetEffectiveScale()
    F.mouse.x = (l + w * (fx or 0.5) + (dx or 0)) * scale
    F.mouse.y = (b + h * (1 - (fy or 0.5))) * scale
end

-- The mouse comes over a frame / leaves it. Returns false when the frame can't be
-- reached by the mouse (hidden).
function F.Enter(frame)
    F.FlushLayout()
    if not frame:IsVisible() then return false end
    if F.hover and F.hover ~= frame then F.Leave(F.hover) end
    F.hover = frame
    F.MoveMouse(frame)
    if frame.GetFontString then F.ApplyButtonFont(frame) end
    F.Fire(frame, "OnEnter", true)
    return true
end
function F.Leave(frame)
    frame = frame or F.hover
    if not frame then return end
    if F.hover == frame then F.hover = nil end
    F.mouse.x, F.mouse.y = -5000, -5000
    if frame.GetFontString then F.ApplyButtonFont(frame) end
    F.Fire(frame, "OnLeave", true)
end

-- A full click as the game does it: mouse down, mouse up, then OnClick if the frame is
-- a button registered for that mouse button. Returns false when it can't be clicked.
function F.Click(frame, button)
    button = button or "LeftButton"
    F.FlushLayout()
    if not frame:IsVisible() then return false end
    if frame.IsEnabled and not frame:IsEnabled() then return false end
    F.buttonsDown[button] = true
    F.Fire(frame, "OnMouseDown", button)
    F.buttonsDown[button] = nil
    if S[frame] then F.Fire(frame, "OnMouseUp", button, true) end
    local clicks = S[frame] and S[frame].clicks
    if clicks and frame.IsEnabled and frame:IsEnabled() and (clicks.AnyUp or clicks.AnyDown or clicks[button .. "Up"] or clicks[button .. "Down"]) then
        F.Fire(frame, "PreClick", button, false)
        F.Fire(frame, "OnClick", button, false)
        F.Fire(frame, "PostClick", button, false)
    end
    return true
end

-- Typing into an edit box, as the player does: the text is cut at the box's limit,
-- OnTextChanged says it was the user. `enter` presses Enter afterwards.
function F.Type(box, text, enter)
    local s = S[box]
    text = tostring(text)
    if s.numeric then text = text:gsub("%D", "") end
    if s.maxLetters and s.maxLetters > 0 then text = text:sub(1, s.maxLetters) end
    box:SetFocus()
    if s.text ~= text then
        s.text = text
        F.Fire(box, "OnTextChanged", true)
    end
    if enter then F.Fire(box, "OnEnterPressed") end
end

-- Dragging a slider's handle to a value.
function F.Drag(slider, value)
    F.Fire(slider, "OnMouseDown", "LeftButton")
    F.SetSliderValue(slider, value, true)
    F.Fire(slider, "OnMouseUp", "LeftButton")
end

-- One frame of the game: OnUpdate on every visible frame that has it.
function F.Update(elapsed)
    elapsed = elapsed or 0.02
    F.FlushLayout()
    local list = {}
    for _, frame in ipairs(F.frames) do
        if S[frame].scripts.OnUpdate and frame:IsVisible() then list[#list + 1] = frame end
    end
    for _, frame in ipairs(list) do
        local fn = S[frame].scripts.OnUpdate
        if fn then fn(frame, elapsed) end
    end
    F.FlushLayout()
    return #list
end

-- What a click settles into: the timers due on the next frame, a frame of the game
-- (the options library redraws its window on the next frame), and what that queued.
-- Timers with a delay stay queued until RunTimers() is called; `all` runs them too.
function F.Settle(all)
    for _ = 1, 2 do
        RunTimers(nil, 0)
        F.Update(0.02)
    end
    RunTimers(nil, not all and 0 or nil)
end

---------------------------------------------------------------------------
-- Context menus (MenuUtil): kept so a test can read and click them
---------------------------------------------------------------------------
local function element(kind, text, fn, data)
    local item = { kind = kind, text = text, fn = fn, data = data, enabled = true, children = {} }
    function item:SetEnabled(on) self.enabled = on end
    function item:SetTooltip(tip) self.tooltip = tip end
    function item:AddInitializer(init) self.initializer = init end
    function item:SetResponse(response) self.response = response end
    function item:SetTitleAndTextTooltip(title, body) self.tipTitle, self.tipText = title, body end
    function item:CreateTitle(t) return self:add(element("title", t)) end
    function item:CreateButton(t, f, d) return self:add(element("button", t, f, d)) end
    function item:CreateCheckbox(t, isSelected, setSelected, d)
        local box = self:add(element("checkbox", t, setSelected, d))
        box.isSelected = isSelected
        return box
    end
    function item:CreateRadio(t, isSelected, setSelected, d)
        local radio = self:add(element("radio", t, setSelected, d))
        radio.isSelected = isSelected
        return radio
    end
    function item:CreateDivider() return self:add(element("divider")) end
    function item:CreateSpacer() return self:add(element("spacer")) end
    function item:QueueTitle(t) return self:CreateTitle(t) end
    function item:QueueDivider() return self:CreateDivider() end
    function item:SetScrollMode() end
    function item:SetTag(tag) self.tag = tag end
    function item:add(child)
        if child.text ~= nil and type(child.text) ~= "string" then
            error("menu: text expected, got " .. type(child.text), 3)
        end
        if (child.kind == "button") and child.fn ~= nil and type(child.fn) ~= "function" then
            error("menu: function expected, got " .. type(child.fn), 3)
        end
        self.children[#self.children + 1] = child
        return child
    end
    return item
end

MenuResponse = { Open = 1, Refresh = 2, Close = 3, CloseAll = 4 }
MenuUtil = {}
function MenuUtil.CreateContextMenu(owner, generator)
    if owner ~= nil and not S[owner] then error("CreateContextMenu: owner is not a frame", 2) end
    if type(generator) ~= "function" then error("CreateContextMenu: generator expected", 2) end
    local root = element("root")
    generator(owner, root)
    F.menu = { owner = owner, root = root, items = root.children }
    return root
end
function MenuUtil.CreateButton(text, fn, data) return element("button", text, fn, data) end
function MenuUtil.CreateTitle(text) return element("title", text) end

-- The open menu's titles and its other rows (buttons, tick boxes).
function F.MenuTitles()
    local out = {}
    for _, item in ipairs(F.menu and F.menu.items or {}) do
        if item.kind == "title" then out[#out + 1] = item.text end
    end
    return out
end
function F.MenuRows()
    local out = {}
    for _, item in ipairs(F.menu and F.menu.items or {}) do
        if item.kind == "button" or item.kind == "checkbox" or item.kind == "radio" then out[#out + 1] = item end
    end
    return out
end
-- Hovers a row of the open menu: builds its tooltip into GameTooltip.
function F.MenuHover(item)
    if type(item.tooltip) ~= "function" then return false end
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    item.tooltip(GameTooltip, item)
    GameTooltip:Show()
    return true
end
-- Clicks a row of the open menu (the row itself, or its text). A button closes the
-- menu; a tick box leaves it open, as in the game.
function F.MenuClick(item)
    if type(item) == "string" then
        local wanted = item
        item = nil
        for _, row in ipairs(F.MenuRows()) do
            if F.Plain(row.text) == wanted or F.Plain(row.text):find(wanted, 1, true) == 1 then item = row break end
        end
        if not item then error("no menu row named " .. wanted, 2) end
    end
    if not item.enabled then return false end
    if item.kind == "button" then F.menu = nil end
    if item.fn then item.fn(item.data, item) end
    return true
end

---------------------------------------------------------------------------
-- StaticPopup: one dialog at a time, kept so a test can type and answer
---------------------------------------------------------------------------
StaticPopupDialogs = StaticPopupDialogs or {}
local popupFrames = {}

function StaticPopup_Show(which, text1, text2, data)
    local info = StaticPopupDialogs[which]
    if type(info) ~= "table" then error("StaticPopup_Show: no dialog named " .. tostring(which), 2) end
    local dialog = popupFrames[which]
    if not dialog then
        dialog = CreateFrame("Frame", nil, UIParent)
        dialog:Hide()
        dialog.Text = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        dialog.text = dialog.Text
        dialog.EditBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
        dialog.editBox = dialog.EditBox
        function dialog:GetEditBox() return self.EditBox end
        dialog.button1 = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.button2 = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        function dialog:GetButton1() return self.button1 end
        function dialog:GetButton2() return self.button2 end
        dialog:SetScript("OnHide", function(self)
            local current = StaticPopupDialogs[self.which]
            if current and current.OnHide then current.OnHide(self, self.data) end
            if F.popup == self then F.popup = nil end
        end)
        popupFrames[which] = dialog
    end
    if F.popup and F.popup ~= dialog then F.popup:Hide() end
    dialog.which, dialog.data, dialog.data2 = which, data, nil
    local text = tostring(info.text or "")
    if text:find("%%") then text = text:format(text1 or "", text2 or "") end
    dialog.Text:SetText(text)
    dialog.button1:SetText(info.button1 or "")
    dialog.button2:SetText(info.button2 or "")
    dialog.EditBox:SetShown(info.hasEditBox and true or false)
    dialog.EditBox:SetMaxLetters(info.maxLetters or 0)
    dialog.EditBox:SetScript("OnEnterPressed", info.EditBoxOnEnterPressed and function(box) info.EditBoxOnEnterPressed(box, dialog.data) end or nil)
    dialog.EditBox:SetScript("OnEscapePressed", info.EditBoxOnEscapePressed and function(box) info.EditBoxOnEscapePressed(box, dialog.data) end or nil)
    dialog.EditBox:SetScript("OnTextChanged", info.EditBoxOnTextChanged and function(box, user) info.EditBoxOnTextChanged(box, dialog.data) end or nil)
    F.popup = dialog
    dialog:Show()
    if info.OnShow then info.OnShow(dialog, data) end
    return dialog
end
function StaticPopup_Hide(which)
    if popupFrames[which] then popupFrames[which]:Hide() end
end
function StaticPopup_Visible(which)
    local dialog = popupFrames[which]
    if dialog and dialog:IsShown() then return "fake", dialog end
end
-- The open popup's question.
function F.PopupText() return F.popup and F.popup.Text:GetText() end
-- Types into the open popup's box; `enter` presses Enter.
function F.PopupType(text, enter)
    local dialog = F.popup
    if not dialog then error("no popup is open", 2) end
    F.Type(dialog.EditBox, text, enter)
end
-- Presses the first button (Accept) or the second (Cancel).
function F.PopupAccept()
    local dialog = F.popup
    if not dialog then error("no popup is open", 2) end
    local info = StaticPopupDialogs[dialog.which]
    local keep = info.OnAccept and info.OnAccept(dialog, dialog.data, dialog.data2)
    if not keep then dialog:Hide() end
end
function F.PopupCancel()
    local dialog = F.popup
    if not dialog then error("no popup is open", 2) end
    local info = StaticPopupDialogs[dialog.which]
    if info.OnCancel then info.OnCancel(dialog, dialog.data, "clicked") end
    dialog:Hide()
end
function F.PopupEscape()
    local dialog = F.popup
    if not dialog then error("no popup is open", 2) end
    if dialog.EditBox:IsShown() and S[dialog.EditBox].scripts.OnEscapePressed then
        F.Fire(dialog.EditBox, "OnEscapePressed")
    else
        F.PopupCancel()
    end
end
