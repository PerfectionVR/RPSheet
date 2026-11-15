-- Fake frame API, part 2: the frame types (Frame, Button, CheckButton, EditBox, Slider,
-- StatusBar, ScrollFrame, GameTooltip), the templates the options library builds its
-- parts from, and CreateFrame. Loaded by t-test-windows-ui.lua after the frames file.
local F = UIFAKE
local S, class, need = F.S, F.class, F.need
local Region = F.classes.Region
local Texture, FontString = F.classes.Texture, F.classes.FontString

---------------------------------------------------------------------------
-- Frame
---------------------------------------------------------------------------
local Frame = class("Frame", Region)
F.Scripts(Frame, { "OnUpdate", "OnSizeChanged", "OnEvent", "OnLoad", "OnDragStart", "OnDragStop", "OnReceiveDrag",
    "OnKeyDown", "OnKeyUp", "OnChar", "OnAttributeChanged", "OnEnable", "OnDisable",
    "OnHyperlinkEnter", "OnHyperlinkLeave", "OnHyperlinkClick", "OnGamePadButtonDown", "OnGamePadButtonUp" })

function Frame:CreateTexture(name, layer, template, sublevel)
    local texture = F.NewRegion(Texture, self, name, layer)
    if sublevel then S[texture].sublevel = sublevel end
    return texture
end
function Frame:CreateMaskTexture(name, layer) return F.NewRegion(Texture, self, name, layer) end
function Frame:CreateFontString(name, layer, template)
    local text = F.NewRegion(FontString, self, name, layer)
    if template then
        local font = _G[template]
        if not (S[font] and S[font].type == "Font") then error("CreateFontString: no font named " .. tostring(template), 2) end
        text:SetFontObject(font)
    end
    return text
end
function Frame:GetRegions() return unpack(S[self].regions) end
function Frame:GetNumRegions() return #S[self].regions end
function Frame:GetChildren() return unpack(S[self].children) end
function Frame:GetNumChildren() return #S[self].children end

function Frame:SetFrameStrata(strata) need(strata, "string", "SetFrameStrata") S[self].strata = strata:upper() end
function Frame:GetFrameStrata()
    local s = S[self]
    while s do
        if s.strata then return s.strata end
        s = s.parent and S[s.parent]
    end
    return "MEDIUM"
end
function Frame:SetFrameLevel(level) need(level, "number", "SetFrameLevel") S[self].level = level end
function Frame:GetFrameLevel()
    local s, up = S[self], 0
    while s do
        if s.level then return s.level + up end
        s = s.parent and S[s.parent]
        up = up + 1
    end
    return up
end
function Frame:SetFixedFrameStrata() end
function Frame:SetFixedFrameLevel() end
function Frame:SetToplevel(on) S[self].toplevel = on end
function Frame:IsToplevel() return S[self].toplevel or false end
function Frame:Raise() S[self].raised = (S[self].raised or 0) + 1 end
function Frame:Lower() end
function Frame:SetMovable(on) S[self].movable = on and true or false end
function Frame:IsMovable() return S[self].movable or false end
function Frame:SetResizable(on) S[self].resizable = on and true or false end
function Frame:IsResizable() return S[self].resizable or false end
function Frame:SetResizeBounds(minW, minH, maxW, maxH)
    need(minW, "number", "SetResizeBounds"); need(minH, "number", "SetResizeBounds")
    S[self].bounds = { minW, minH, maxW, maxH }
end
function Frame:GetResizeBounds() return unpack(S[self].bounds or { 0, 0, 0, 0 }) end
function Frame:SetClampedToScreen(on) S[self].clamped = on end
function Frame:IsClampedToScreen() return S[self].clamped or false end
function Frame:SetClampRectInsets() end
function Frame:StartMoving()
    if not S[self].movable then error("StartMoving: the frame is not movable", 2) end
    S[self].moving = true
end
function Frame:StartSizing(point)
    if not S[self].resizable then error("StartSizing: the frame is not resizable", 2) end
    S[self].sizing = point or true
end
function Frame:StopMovingOrSizing() S[self].moving, S[self].sizing = nil, nil end
function Frame:SetUserPlaced() end
function Frame:IsUserPlaced() return false end
function Frame:SetDontSavePosition() end
function Frame:RegisterForDrag() end
function Frame:EnableMouseWheel(on) S[self].wheel = on and true or false end
function Frame:IsMouseWheelEnabled() return S[self].wheel or false end
function Frame:EnableKeyboard(on) S[self].keyboard = on and true or false end
function Frame:IsKeyboardEnabled() return S[self].keyboard or false end
function Frame:EnableGamePadButton() end
function Frame:EnableGamePadStick() end
function Frame:SetPropagateKeyboardInput() end
function Frame:RegisterEvent(event) S[self].events = S[self].events or {}; S[self].events[event] = true end
function Frame:RegisterUnitEvent(event) self:RegisterEvent(event) end
function Frame:UnregisterEvent(event) if S[self].events then S[self].events[event] = nil end end
function Frame:UnregisterAllEvents() S[self].events = nil end
function Frame:IsEventRegistered(event) return S[self].events and S[self].events[event] or false end
function Frame:SetID(id) S[self].id = id end
function Frame:GetID() return S[self].id or 0 end
function Frame:SetAttribute(key, value) S[self].attributes = S[self].attributes or {}; S[self].attributes[key] = value end
function Frame:GetAttribute(key) return S[self].attributes and S[self].attributes[key] end
function Frame:SetHitRectInsets() end
function Frame:SetClipsChildren(on) S[self].clips = on end
function Frame:DoesClipChildren() return S[self].clips or false end
function Frame:SetHyperlinksEnabled(on) S[self].hyperlinks = on and true or false end
function Frame:GetHyperlinksEnabled() return S[self].hyperlinks or false end
function Frame:SetFlattensRenderLayers() end
function Frame:SetIsFrameBuffer() end
function Frame:GetBoundsRect() return self:GetRect() end

---------------------------------------------------------------------------
-- BackdropTemplate: the game builds a backdrop from nine pictures on the frame
---------------------------------------------------------------------------
local Backdrop = {}
local EDGES = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge" }
function Backdrop:SetBackdrop(info)
    if info ~= nil and type(info) ~= "table" then error("SetBackdrop: table expected", 2) end
    self.backdropInfo = info
    if not info then
        if self.Center then self.Center:Hide() end
        for _, key in ipairs(EDGES) do if self[key] then self[key]:Hide() end end
        return
    end
    if info.bgFile then
        if not self.Center then
            self.Center = self:CreateTexture(nil, "BACKGROUND")
            self.Center:SetAllPoints()
        end
        self.Center:SetTexture(info.bgFile)
        self.Center:Show()
    elseif self.Center then
        self.Center:Hide()
    end
    for _, key in ipairs(EDGES) do
        if info.edgeFile then
            if not self[key] then
                self[key] = self:CreateTexture(nil, "BORDER")
                local size = info.edgeSize or 16
                self[key]:SetSize(size, size)
                self[key]:SetPoint(key:find("^Top") and (key:find("Left") and "TOPLEFT" or key:find("Right") and "TOPRIGHT" or "TOP")
                    or key:find("^Bottom") and (key:find("Left") and "BOTTOMLEFT" or key:find("Right") and "BOTTOMRIGHT" or "BOTTOM")
                    or key:find("^Left") and "LEFT" or "RIGHT")
            end
            self[key]:SetTexture(info.edgeFile)
            self[key]:Show()
        elseif self[key] then
            self[key]:Hide()
        end
    end
    -- A new backdrop starts white, as in the game.
    if self.Center then self.Center:SetVertexColor(1, 1, 1, 1) end
    for _, key in ipairs(EDGES) do if self[key] then self[key]:SetVertexColor(1, 1, 1, 1) end end
end
function Backdrop:GetBackdrop() return self.backdropInfo end
function Backdrop:ApplyBackdrop() end
function Backdrop:ClearBackdrop() self:SetBackdrop(nil) end
function Backdrop:OnBackdropLoaded() end
function Backdrop:OnBackdropSizeChanged() end
function Backdrop:SetBackdropColor(r, g, b, a)
    need(r, "number", "SetBackdropColor"); need(g, "number", "SetBackdropColor"); need(b, "number", "SetBackdropColor")
    if self.Center then self.Center:SetVertexColor(r, g, b, a or 1) end
end
function Backdrop:GetBackdropColor()
    if self.Center then return self.Center:GetVertexColor() end
end
function Backdrop:SetBackdropBorderColor(r, g, b, a)
    need(r, "number", "SetBackdropBorderColor"); need(g, "number", "SetBackdropBorderColor"); need(b, "number", "SetBackdropBorderColor")
    for _, key in ipairs(EDGES) do
        if self[key] then self[key]:SetVertexColor(r, g, b, a or 1) end
    end
end
function Backdrop:GetBackdropBorderColor()
    if self.backdropInfo and self.backdropInfo.edgeFile and self.TopEdge then return self.TopEdge:GetVertexColor() end
end
BackdropTemplateMixin = Backdrop

---------------------------------------------------------------------------
-- Button
---------------------------------------------------------------------------
local Button = class("Button", Frame)
F.Scripts(Button, { "OnClick", "OnDoubleClick", "PreClick", "PostClick" })

local function stateFont(self)
    local s = S[self]
    if s.disabled then return s.disabledFont or s.normalFont end
    if F.hover == self and s.highlightFont then return s.highlightFont end
    return s.normalFont
end
local function applyFont(self)
    local s = S[self]
    local font = stateFont(self)
    if font and s.fontString then
        -- only the font object: a colour set on the text itself would be lost otherwise
        s.fontString:SetFontObject(font)
    end
end
F.ApplyButtonFont = applyFont

function Button:SetText(text)
    if text ~= nil and type(text) ~= "string" and type(text) ~= "number" then
        error("Button:SetText: text expected, got " .. type(text) .. " (" .. tostring(text) .. ")", 2)
    end
    local s = S[self]
    if not s.fontString then
        s.fontString = self:CreateFontString(nil, "ARTWORK")
        s.fontString:SetPoint("CENTER")
        if not stateFont(self) then error("Button:SetText(): Font not set", 2) end
    end
    applyFont(self)
    s.fontString:SetText(text)
end
function Button:SetFormattedText(fmt, ...) self:SetText(fmt:format(...)) end
function Button:GetText() return S[self].fontString and S[self].fontString:GetText() or nil end
function Button:GetFontString() return S[self].fontString end
function Button:SetFontString(text)
    if not (S[text] and S[text].type == "FontString") then error("SetFontString: font string expected", 2) end
    S[self].fontString = text
    applyFont(self)
end
function Button:GetTextWidth() return S[self].fontString and S[self].fontString:GetStringWidth() or 0 end
function Button:GetTextHeight() return S[self].fontString and S[self].fontString:GetStringHeight() or 0 end
function Button:SetPushedTextOffset() end

for _, state in ipairs({ "Normal", "Highlight", "Disabled" }) do
    local key = state:lower() .. "Font"
    Button["Set" .. state .. "FontObject"] = function(self, font)
        if type(font) == "string" then font = _G[font] end
        if font ~= nil and not (S[font] and S[font].type == "Font") then error("Set" .. state .. "FontObject: font object expected", 2) end
        S[self][key] = font
        applyFont(self)
    end
    Button["Get" .. state .. "FontObject"] = function(self) return S[self][key] end
end

for _, state in ipairs({ "Normal", "Pushed", "Highlight", "Disabled" }) do
    local key = state:lower() .. "Texture"
    Button["Set" .. state .. "Texture"] = function(self, file, blend)
        local s = S[self]
        if S[file] then
            s[key] = file
            return
        end
        if file ~= nil and type(file) ~= "string" and type(file) ~= "number" then
            error("Set" .. state .. "Texture: file expected, got " .. type(file), 2)
        end
        if not s[key] then
            s[key] = self:CreateTexture(nil, state == "Highlight" and "HIGHLIGHT" or "ARTWORK")
            s[key]:SetAllPoints()
        end
        s[key]:SetTexture(file)
        if blend then s[key]:SetBlendMode(blend) end
    end
    Button["Get" .. state .. "Texture"] = function(self) return S[self][key] end
    Button["Set" .. state .. "Atlas"] = function(self, atlas)
        local s = S[self]
        if not s[key] then
            s[key] = self:CreateTexture(nil, state == "Highlight" and "HIGHLIGHT" or "ARTWORK")
            s[key]:SetAllPoints()
        end
        s[key]:SetAtlas(atlas)
    end
    Button["Clear" .. state .. "Texture"] = function(self)
        if S[self][key] then S[self][key]:SetTexture(nil) end
    end
end

function Button:Enable()
    local s = S[self]
    if not s.disabled then return end
    s.disabled = false
    applyFont(self)
    F.Fire(self, "OnEnable")
end
function Button:Disable()
    local s = S[self]
    if s.disabled then return end
    s.disabled = true
    applyFont(self)
    F.Fire(self, "OnDisable")
end
function Button:SetEnabled(on) if on then self:Enable() else self:Disable() end end
function Button:IsEnabled() return not S[self].disabled end
function Button:RegisterForClicks(...)
    local set = {}
    for i = 1, select("#", ...) do set[(select(i, ...))] = true end
    S[self].clicks = set
end
function Button:RegisterForMouse() end
function Button:SetButtonState(state) S[self].buttonState = state end
function Button:GetButtonState() return S[self].disabled and "DISABLED" or S[self].buttonState or "NORMAL" end
function Button:LockHighlight() S[self].locked = true end
function Button:UnlockHighlight() S[self].locked = false end
function Button:SetMotionScriptsWhileDisabled(on) S[self].motionWhileDisabled = on end
function Button:GetMotionScriptsWhileDisabled() return S[self].motionWhileDisabled or false end
function Button:Click(button, down)
    if S[self].disabled then return end
    button = button or "LeftButton"
    F.Fire(self, "PreClick", button, down or false)
    F.Fire(self, "OnClick", button, down or false)
    F.Fire(self, "PostClick", button, down or false)
end

local CheckButton = class("CheckButton", Button)
function CheckButton:SetChecked(on) S[self].checked = on and true or false end
function CheckButton:GetChecked() return S[self].checked or false end
function CheckButton:SetCheckedTexture(file) Button.SetNormalTexture(self, file) end
function CheckButton:GetCheckedTexture() return S[self].normalTexture end
function CheckButton:SetDisabledCheckedTexture() end

---------------------------------------------------------------------------
-- EditBox
---------------------------------------------------------------------------
local EditBox = class("EditBox", Frame)
for name, method in pairs(F.FontMethods) do EditBox[name] = method end
F.Scripts(EditBox, { "OnEnterPressed", "OnEscapePressed", "OnTextChanged", "OnTextSet", "OnEditFocusGained", "OnEditFocusLost",
    "OnTabPressed", "OnSpacePressed", "OnCursorChanged", "OnInputLanguageChanged", "OnArrowPressed" })

function EditBox:SetText(text)
    if text ~= nil and type(text) ~= "string" and type(text) ~= "number" then
        error("EditBox:SetText: text expected, got " .. type(text) .. " (" .. tostring(text) .. ")", 2)
    end
    local s = S[self]
    text = text ~= nil and tostring(text) or ""
    local changed = text ~= s.text
    s.text = text
    F.Fire(self, "OnTextSet")
    if changed then F.Fire(self, "OnTextChanged", false) end
end
function EditBox:GetText() return S[self].text end
function EditBox:GetDisplayText() return S[self].text end
function EditBox:GetNumber() return tonumber(S[self].text) or 0 end
function EditBox:SetNumber(n) self:SetText(tostring(n)) end
function EditBox:GetNumLetters() return #S[self].text end
function EditBox:Insert(text) self:SetText(S[self].text .. tostring(text)) end
function EditBox:SetFocus()
    if F.focus == self then return end
    if F.focus then F.focus:ClearFocus() end
    F.focus = self
    F.Fire(self, "OnEditFocusGained")
end
function EditBox:ClearFocus()
    if F.focus ~= self then return end
    F.focus = nil
    F.Fire(self, "OnEditFocusLost")
end
function EditBox:HasFocus() return F.focus == self end
function EditBox:SetAutoFocus(on) S[self].autoFocus = on end
function EditBox:IsAutoFocus() return S[self].autoFocus or false end
function EditBox:SetMaxLetters(count) need(count, "number", "SetMaxLetters") S[self].maxLetters = count end
function EditBox:GetMaxLetters() return S[self].maxLetters or 0 end
function EditBox:SetMaxBytes(count) S[self].maxBytes = count end
function EditBox:GetMaxBytes() return S[self].maxBytes or 0 end
function EditBox:SetNumeric(on) S[self].numeric = on end
function EditBox:IsNumeric() return S[self].numeric or false end
function EditBox:SetPassword() end
function EditBox:SetMultiLine(on) S[self].multiLine = on end
function EditBox:IsMultiLine() return S[self].multiLine or false end
function EditBox:SetCursorPosition(at) S[self].cursor = at end
function EditBox:GetCursorPosition() return S[self].cursor or 0 end
function EditBox:GetUTF8CursorPosition() return S[self].cursor or 0 end
function EditBox:HighlightText(from, to) S[self].highlight = { from or 0, to or -1 } end
function EditBox:ClearHighlightText() S[self].highlight = nil end
function EditBox:GetHighlightText() return 0, 0 end
function EditBox:SetHighlightColor() end
function EditBox:SetTextInsets(l, r, t, b) S[self].insets = { l, r, t, b } end
function EditBox:GetTextInsets() return unpack(S[self].insets or { 0, 0, 0, 0 }) end
function EditBox:SetCountInvisibleLetters() end
function EditBox:SetHistoryLines() end
function EditBox:AddHistoryLine() end
function EditBox:ClearHistory() end
function EditBox:SetBlinkSpeed() end
function EditBox:SetAltArrowKeyMode() end
function EditBox:GetInputLanguage() return "ROMAN" end
function EditBox:Enable() S[self].disabled = false end
function EditBox:Disable() S[self].disabled = true end
function EditBox:SetEnabled(on) S[self].disabled = not on end
function EditBox:IsEnabled() return not S[self].disabled end

---------------------------------------------------------------------------
-- Slider, StatusBar, ScrollFrame
---------------------------------------------------------------------------
local Slider = class("Slider", Frame)
F.Scripts(Slider, { "OnValueChanged", "OnMinMaxChanged" })

local function setSliderValue(self, value, user)
    local s = S[self]
    value = math.max(s.min, math.min(s.max, value))
    if user and s.obeyStep and s.step and s.step > 0 then
        value = s.min + math.floor((value - s.min) / s.step + 0.5) * s.step
        value = math.max(s.min, math.min(s.max, value))
    end
    if value == s.value then return end
    s.value = value
    F.Fire(self, "OnValueChanged", value, user or false)
end
F.SetSliderValue = setSliderValue
function Slider:SetMinMaxValues(min, max)
    need(min, "number", "SetMinMaxValues"); need(max, "number", "SetMinMaxValues")
    local s = S[self]
    if max < min then max = min end
    if s.min == min and s.max == max then return end
    s.min, s.max = min, max
    F.Fire(self, "OnMinMaxChanged", min, max)
    setSliderValue(self, s.value)
end
function Slider:GetMinMaxValues() return S[self].min, S[self].max end
function Slider:SetValue(value)
    need(value, "number", "SetValue")
    setSliderValue(self, value)
end
function Slider:GetValue() return S[self].value end
function Slider:SetValueStep(step) need(step, "number", "SetValueStep") S[self].step = step end
function Slider:GetValueStep() return S[self].step or 0 end
function Slider:SetObeyStepOnDrag(on) S[self].obeyStep = on and true or false end
function Slider:GetObeyStepOnDrag() return S[self].obeyStep or false end
function Slider:SetStepsPerPage(n) S[self].stepsPerPage = n end
function Slider:GetStepsPerPage() return S[self].stepsPerPage or 0 end
function Slider:SetOrientation(how) need(how, "string", "SetOrientation") S[self].orientation = how:upper() end
function Slider:GetOrientation() return S[self].orientation or "VERTICAL" end
function Slider:SetThumbTexture(file)
    local s = S[self]
    if S[file] then s.thumb = file return end
    if not s.thumb then
        s.thumb = self:CreateTexture(nil, "ARTWORK")
        s.thumb:SetSize(32, 32)
        s.thumb:SetPoint("CENTER")
    end
    s.thumb:SetTexture(file)
end
function Slider:GetThumbTexture() return S[self].thumb end
function Slider:Enable() S[self].disabled = false end
function Slider:Disable() S[self].disabled = true end
function Slider:SetEnabled(on) S[self].disabled = not on end
function Slider:IsEnabled() return not S[self].disabled end
function Slider:IsDraggingThumb() return false end

local StatusBar = class("StatusBar", Frame)
F.Scripts(StatusBar, { "OnValueChanged", "OnMinMaxChanged" })
function StatusBar:SetMinMaxValues(min, max)
    need(min, "number", "SetMinMaxValues"); need(max, "number", "SetMinMaxValues")
    S[self].min, S[self].max = min, max
end
function StatusBar:GetMinMaxValues() return S[self].min, S[self].max end
function StatusBar:SetValue(value) need(value, "number", "StatusBar:SetValue") S[self].value = value end
function StatusBar:GetValue() return S[self].value end
function StatusBar:SetStatusBarTexture(file)
    local s = S[self]
    if S[file] then s.barTexture = file return end
    if file ~= nil and type(file) ~= "string" and type(file) ~= "number" then
        error("SetStatusBarTexture: file expected, got " .. type(file), 2)
    end
    if not s.barTexture then
        s.barTexture = self:CreateTexture(nil, "ARTWORK")
        s.barTexture:SetAllPoints()
    end
    s.barTexture:SetTexture(file)
end
function StatusBar:GetStatusBarTexture() return S[self].barTexture end
function StatusBar:SetStatusBarColor(r, g, b, a)
    need(r, "number", "SetStatusBarColor"); need(g, "number", "SetStatusBarColor"); need(b, "number", "SetStatusBarColor")
    S[self].barColor = { r, g, b, a or 1 }
end
function StatusBar:GetStatusBarColor() return unpack(S[self].barColor or { 1, 1, 1, 1 }) end
function StatusBar:SetOrientation() end
function StatusBar:SetReverseFill() end
function StatusBar:SetFillStyle() end
function StatusBar:SetRotatesTexture() end

local ScrollFrame = class("ScrollFrame", Frame)
F.Scripts(ScrollFrame, { "OnScrollRangeChanged", "OnVerticalScroll", "OnHorizontalScroll" })
function ScrollFrame:SetScrollChild(child)
    if not (S[child] and S[child].isFrame) then error("SetScrollChild: frame expected", 2) end
    S[self].scrollChild = child
    if S[child].parent ~= self then child:SetParent(self) end
end
function ScrollFrame:GetScrollChild() return S[self].scrollChild end
function ScrollFrame:SetVerticalScroll(value)
    need(value, "number", "SetVerticalScroll")
    if S[self].vscroll == value then return end
    S[self].vscroll = value
    F.Fire(self, "OnVerticalScroll", value)
end
function ScrollFrame:GetVerticalScroll() return S[self].vscroll or 0 end
function ScrollFrame:SetHorizontalScroll(value) need(value, "number", "SetHorizontalScroll") S[self].hscroll = value end
function ScrollFrame:GetHorizontalScroll() return S[self].hscroll or 0 end
function ScrollFrame:GetVerticalScrollRange()
    local child = S[self].scrollChild
    return child and math.max(0, child:GetHeight() - self:GetHeight()) or 0
end
function ScrollFrame:GetHorizontalScrollRange()
    local child = S[self].scrollChild
    return child and math.max(0, child:GetWidth() - self:GetWidth()) or 0
end
function ScrollFrame:UpdateScrollChildRect() end

---------------------------------------------------------------------------
-- GameTooltip: keeps the lines it is given, for the tests to read
---------------------------------------------------------------------------
local Tooltip = class("GameTooltip", Frame)
F.Scripts(Tooltip, { "OnTooltipCleared", "OnTooltipSetItem", "OnTooltipSetUnit", "OnTooltipSetSpell", "OnTooltipSetDefaultAnchor", "OnTooltipAddMoney" })
local function tipText(text, what)
    if type(text) ~= "string" and type(text) ~= "number" then
        error(("GameTooltip:%s: text expected, got %s"):format(what, type(text)), 3)
    end
    return tostring(text)
end
function Tooltip:SetOwner(owner, anchor)
    if not S[owner] then error("GameTooltip:SetOwner: frame expected, got " .. type(owner), 2) end
    local s = S[self]
    s.owner, s.anchor, s.lines = owner, anchor, {}
end
function Tooltip:GetOwner() return S[self].owner end
function Tooltip:IsOwned(frame) return S[self].owner == frame end
function Tooltip:SetAnchorType(anchor) S[self].anchor = anchor end
function Tooltip:GetAnchorType() return S[self].anchor end
function Tooltip:ClearLines() S[self].lines = {} end
function Tooltip:NumLines() return #S[self].lines end
function Tooltip:AddLine(text, r, g, b, wrap)
    local s = S[self]
    s.lines[#s.lines + 1] = { text = tipText(text, "AddLine"), r = r, g = g, b = b, wrap = wrap }
end
function Tooltip:AddDoubleLine(left, right, r, g, b)
    local s = S[self]
    s.lines[#s.lines + 1] = { text = tipText(left, "AddDoubleLine"), right = tipText(right, "AddDoubleLine"), r = r, g = g, b = b }
end
function Tooltip:SetText(text, r, g, b, a, wrap)
    local s = S[self]
    s.lines = { { text = tipText(text, "SetText"), r = r, g = g, b = b, wrap = wrap } }
    if s.owner then Region.Show(self) end
end
function Tooltip:AppendText(text) local s = S[self]; if s.lines[1] then s.lines[1].text = s.lines[1].text .. tostring(text) end end
function Tooltip:AddTexture() end
function Tooltip:AddAtlas() end
function Tooltip:SetHyperlink(link)
    need(link, "string", "SetHyperlink")
    local s = S[self]
    s.lines = { { text = "link " .. link } }
    Region.Show(self)
end
function Tooltip:SetMinimumWidth() end
function Tooltip:GetMinimumWidth() return 0 end
function Tooltip:SetPadding() end
function Tooltip:FadeOut() self:Hide() end
function Tooltip:SetUnit() end
function Tooltip:GetUnit() end
function Tooltip:GetItem() end
function Tooltip:GetSpell() end
function Tooltip:SetSpellByID(id) S[self].lines = { { text = "spell " .. tostring(id) } } end
function Tooltip:SetItemByID(id) S[self].lines = { { text = "item " .. tostring(id) } } end
function Tooltip:Show()
    local s = S[self]
    -- A tooltip with nothing in it doesn't open.
    if #s.lines == 0 then Region.Hide(self) return end
    s.shownLines = s.lines
    Region.Show(self)
end
function Tooltip:Hide()
    local s = S[self]
    s.lines, s.owner = {}, nil
    Region.Hide(self)
end
-- For the tests: the lines of an open tooltip (nil when it is closed).
function F.TooltipLines(tooltip)
    tooltip = tooltip or GameTooltip
    if not S[tooltip].shown then return nil end
    return S[tooltip].lines
end
function F.TooltipText(tooltip)
    local lines = F.TooltipLines(tooltip)
    if not lines then return nil end
    local out = {}
    for i, line in ipairs(lines) do out[i] = line.text .. (line.right and ("\t" .. line.right) or "") end
    return table.concat(out, "\n")
end

---------------------------------------------------------------------------
-- Other types: plain frames with a few methods of their own
---------------------------------------------------------------------------
local ColorSelect = class("ColorSelect", Frame)
F.Scripts(ColorSelect, { "OnColorSelect" })
function ColorSelect:SetColorRGB(r, g, b) S[self].rgb = { r, g, b }; F.Fire(self, "OnColorSelect", r, g, b) end
function ColorSelect:GetColorRGB() return unpack(S[self].rgb or { 1, 1, 1 }) end
function ColorSelect:SetColorAlpha(a) S[self].a = a end
function ColorSelect:GetColorAlpha() return S[self].a or 1 end

local Cooldown = class("Cooldown", Frame)
function Cooldown:SetCooldown() end
function Cooldown:Clear() end
local Model = class("Model", Frame)
local PlayerModel = class("PlayerModel", Model)
local MessageFrame = class("MessageFrame", Frame)
for name, method in pairs(F.FontMethods) do MessageFrame[name] = method end
function MessageFrame:AddMessage(text) S[self].messages = S[self].messages or {}; table.insert(S[self].messages, text) end
function MessageFrame:Clear() S[self].messages = {} end
local SimpleHTML = class("SimpleHTML", Frame)
for name, method in pairs(F.FontMethods) do SimpleHTML[name] = method end
function SimpleHTML:SetText(text) S[self].text = text end

---------------------------------------------------------------------------
-- Templates
---------------------------------------------------------------------------
local T = {}
F.templates = T

local function named(frame, key) -- "$parentKey" as the game's XML names pieces
    local name = S[frame].name
    return name and (name .. key) or nil
end

function T.BackdropTemplate(frame)
    for key, method in pairs(Backdrop) do frame[key] = method end
end

function T.UIPanelButtonTemplate(frame)
    S[frame].w, S[frame].h = 40, 22
    for _, key in ipairs({ "Left", "Middle", "Right" }) do
        frame[key] = frame:CreateTexture(nil, "BACKGROUND")
        frame[key]:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    end
    frame.Left:SetPoint("TOPLEFT"); frame.Left:SetPoint("BOTTOMLEFT"); frame.Left:SetWidth(12)
    frame.Right:SetPoint("TOPRIGHT"); frame.Right:SetPoint("BOTTOMRIGHT"); frame.Right:SetWidth(12)
    frame.Middle:SetPoint("TOPLEFT", frame.Left, "TOPRIGHT"); frame.Middle:SetPoint("BOTTOMRIGHT", frame.Right, "BOTTOMLEFT")
    frame.Text = frame:CreateFontString(named(frame, "Text"), "ARTWORK")
    frame.Text:SetPoint("CENTER")
    frame:SetFontString(frame.Text)
    frame:SetNormalFontObject(GameFontNormal)
    frame:SetHighlightFontObject(GameFontHighlight)
    frame:SetDisabledFontObject(GameFontDisable)
    frame:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
end

function T.UIPanelCloseButton(frame)
    S[frame].w, S[frame].h = 32, 32
    frame:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    frame:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    frame:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
end

function T.UIPanelScrollBarTemplate(frame)
    S[frame].w = 16
    frame.ThumbTexture = frame:CreateTexture(named(frame, "ThumbTexture"), "ARTWORK")
    frame.ThumbTexture:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    frame.ThumbTexture:SetSize(18, 24)
    frame.ThumbTexture:SetPoint("TOP")
    frame:SetThumbTexture(frame.ThumbTexture)
    for _, key in ipairs({ "ScrollUpButton", "ScrollDownButton" }) do
        local button = CreateFrame("Button", named(frame, key), frame)
        button:SetSize(18, 16)
        local which = key == "ScrollUpButton" and "Up" or "Down"
        button:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-Scroll" .. which .. "Button-Up")
        button:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-Scroll" .. which .. "Button-Down")
        button:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-Scroll" .. which .. "Button-Disabled")
        button:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-Scroll" .. which .. "Button-Highlight", "ADD")
        button.Normal, button.Pushed, button.Disabled, button.Highlight =
            button:GetNormalTexture(), button:GetPushedTexture(), button:GetDisabledTexture(), button:GetHighlightTexture()
        frame[key] = button
    end
    frame.ScrollUpButton:SetPoint("BOTTOM", frame, "TOP")
    frame.ScrollDownButton:SetPoint("TOP", frame, "BOTTOM")
    S[frame].min, S[frame].max, S[frame].value = 0, 0, 0
end

function T.UIPanelScrollFrameTemplate(frame)
    local bar = CreateFrame("Slider", named(frame, "ScrollBar"), frame, "UIPanelScrollBarTemplate")
    bar:SetPoint("TOPLEFT", frame, "TOPRIGHT", 6, -16)
    bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 6, 16)
    frame.ScrollBar = bar
end

function T.InputBoxTemplate(frame)
    for _, key in ipairs({ "Left", "Middle", "Right" }) do
        frame[key] = frame:CreateTexture(nil, "BACKGROUND")
        frame[key]:SetTexture("Interface\\Common\\Common-Input-Border")
    end
    frame.Left:SetSize(8, 20); frame.Left:SetPoint("LEFT", -5, 0)
    frame.Right:SetSize(8, 20); frame.Right:SetPoint("RIGHT", 0, 0)
    frame.Middle:SetPoint("LEFT", frame.Left, "RIGHT"); frame.Middle:SetPoint("RIGHT", frame.Right, "LEFT"); frame.Middle:SetHeight(20)
    frame:SetFontObject(ChatFontNormal)
end

function T.UIDropDownMenuTemplate(frame)
    S[frame].w, S[frame].h = 40, 32
    for _, key in ipairs({ "Left", "Middle", "Right" }) do
        frame[key] = frame:CreateTexture(named(frame, key), "ARTWORK")
        frame[key]:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    end
    frame.Left:SetSize(25, 64); frame.Left:SetPoint("TOPLEFT", 0, 17)
    frame.Middle:SetSize(115, 64); frame.Middle:SetPoint("LEFT", frame.Left, "RIGHT")
    frame.Right:SetSize(25, 64); frame.Right:SetPoint("LEFT", frame.Middle, "RIGHT")
    frame.Text = frame:CreateFontString(named(frame, "Text"), "ARTWORK", "GameFontHighlightSmall")
    frame.Text:SetPoint("RIGHT", frame.Right, -43, 2)
    frame.Icon = frame:CreateTexture(named(frame, "Icon"), "OVERLAY")
    frame.Icon:Hide()
    local button = CreateFrame("Button", named(frame, "Button"), frame)
    button:SetSize(24, 24)
    button:SetPoint("TOPRIGHT", frame.Right, -16, -18)
    for _, state in ipairs({ "Normal", "Pushed", "Disabled", "Highlight" }) do
        button["Set" .. state .. "Texture"](button, "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-" .. state)
        local texture = button["Get" .. state .. "Texture"](button)
        button[state .. "Texture"] = texture
        if S[button].name then rawset(_G, S[button].name .. state .. "Texture", texture) end
    end
    frame.Button = button
end

function T.OptionsListButtonTemplate(frame)
    S[frame].w, S[frame].h = 175, 18
    frame.text = frame:CreateFontString(named(frame, "Text"), "ARTWORK", "GameFontNormal")
    frame.text:SetPoint("LEFT", 8, 2)
    frame.text:SetPoint("RIGHT", -8, 2)
    frame.text:SetJustifyH("LEFT")
    frame:SetFontString(frame.text)
    frame:SetNormalFontObject(GameFontNormal)
    frame:SetHighlightFontObject(GameFontHighlight)
    frame.highlight = frame:CreateTexture(named(frame, "Highlight"), "HIGHLIGHT")
    frame.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    frame.highlight:SetBlendMode("ADD")
    frame.highlight:SetAllPoints()
    frame:SetHighlightTexture(frame.highlight)
    local toggle = CreateFrame("Button", named(frame, "Toggle"), frame)
    toggle:SetSize(14, 14)
    toggle:SetPoint("TOPRIGHT", -6, -1)
    toggle:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
    toggle:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
    toggle:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    frame.toggle = toggle
end

function T.GameTooltipTemplate(frame)
    for key, method in pairs(Backdrop) do
        if not frame[key] then frame[key] = method end
    end
    frame.NineSlice = CreateFrame("Frame", nil, frame)
    S[frame].shown = false
    S[frame].lines = {}
end
function T.DialogBorderOpaqueTemplate(frame)
    frame.Bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.Bg:SetAllPoints()
end
T.DialogBorderTemplate = T.DialogBorderOpaqueTemplate
function T.SecureHandlerBaseTemplate() end

---------------------------------------------------------------------------
-- CreateFrame
---------------------------------------------------------------------------
local TYPES = {}
for name in pairs(F.classes) do TYPES[name:upper()] = name end

function CreateFrame(kind, name, parent, template, id)
    if type(kind) ~= "string" then error("CreateFrame: frame type expected, got " .. type(kind), 2) end
    local canonical = TYPES[kind:upper()]
    local c = canonical and F.classes[canonical]
    local isFrame, up = false, c
    while up do
        if up == Frame then isFrame = true end
        up = up.__parent
    end
    if not isFrame then error("CreateFrame: unknown frame type " .. kind, 2) end
    if type(parent) == "string" then parent = rawget(_G, parent) end
    if parent ~= nil and not (S[parent] and S[parent].isFrame) then
        error("CreateFrame: parent is not a frame: " .. tostring(parent), 2)
    end
    if name ~= nil then
        need(name, "string", "CreateFrame name")
        if name:find("$parent", 1, true) then
            name = name:gsub("%$parent", (parent and S[parent].name) or "")
        end
    end
    local frame = setmetatable({}, c.__mt)
    local s = F.newState(canonical, name, parent)
    s.isFrame, s.children, s.regions, s.cw, s.ch = true, {}, {}, 0, 0
    if canonical == "Slider" or canonical == "StatusBar" then s.min, s.max, s.value = 0, 0, 0 end
    if canonical == "EditBox" then s.text, s.mouse = "", true end
    if canonical == "Button" or canonical == "CheckButton" then s.mouse, s.clicks = true, { LeftButtonUp = true } end
    if canonical == "GameTooltip" then s.lines, s.shown = {}, false end
    if id then s.id = id end
    S[frame] = s
    F.frames[#F.frames + 1] = frame
    if parent then
        local list = S[parent].children
        list[#list + 1] = frame
    end
    if name then rawset(_G, name, frame) end
    if template then
        need(template, "string", "CreateFrame template")
        for one in template:gmatch("[^,%s]+") do
            if T[one] then T[one](frame) else F.unknownTemplates[one] = true end
        end
    end
    return frame
end

function CreateFont(name)
    need(name, "string", "CreateFont")
    local existing = rawget(_G, name)
    if S[existing] and S[existing].type == "Font" then return existing end
    return F.NewFont(name)
end
