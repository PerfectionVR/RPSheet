-- The dialog skin over the real parts of the options library. With the settings
-- window, the creation wizard, the level dialog and the item browser open, every
-- theme preset is applied; while a window is skinned its texts must carry the theme's
-- font and colours. Every part the library takes back must then be as it was handed
-- out: its fonts, colours, transparency, pictures, anchors and its own functions are
-- noted when the library lends it and compared when it is given back. What differs
-- without the skin as well (a label's text, say) is learned in a first run with the
-- skin switched off and is not held against it. Skin.failed must stay empty.
dofile(ARG3 .. "/t-test-windows-base.lua")
dofile(ARG3 .. "/t-test-windows-dialog.lua")

-- every font name its own file, so a text's font tells which theme styled it
local LSM = LibStub("LibSharedMedia-3.0")
LSM.Fetch = function(_, kind, name) return ("Media\\%s\\%s"):format(tostring(kind), tostring(name)) end
Start()

local MAIN, WIZARD, LEVEL = "RPSheet", "RPSheetWizard", "RPSheetLevel"
local D = Dialog
local S = F.S
local stats = { lent = 0, back = 0, compared = 0, styled = 0, themes = 0, natural = 0, ownShown = 0 }
local function Check(what, ok) if not ok then Problem(what) end end

---------------------------------------------------------------------------
-- What a part looks like
---------------------------------------------------------------------------
local function Num(value) return type(value) == "number" and ("%.3f"):format(value) or tostring(value) end
local function List(...)
    local out = {}
    for index = 1, select("#", ...) do out[index] = Num((select(index, ...))) end
    return table.concat(out, ",")
end
local function FontName(font) return font and (font:GetName() or tostring(font)) or "none" end

-- The regions of a part: its named fields, and what hangs on those frames, down to
-- (not into) the frames of the parts inside it. Each with a path that names it.
local function Regions(widget)
    local list, seen = {}, {}
    local function Add(object, path)
        if seen[object] or not S[object] then return end
        seen[object] = true
        list[#list + 1] = { object = object, path = path }
        if S[object].isFrame then
            for index, region in ipairs({ object:GetRegions() }) do Add(region, path .. "/r" .. index) end
            for index, child in ipairs({ object:GetChildren() }) do
                local other = rawget(child, "obj")
                if not (other and other ~= widget and type(other) == "table" and other.type and other.frame == child) then
                    Add(child, path .. "/c" .. index)
                end
            end
        end
    end
    local names = {}
    for key, value in pairs(widget) do
        if type(key) == "string" and type(value) == "table" and S[value] then names[#names + 1] = key end
    end
    table.sort(names)
    for _, key in ipairs(names) do Add(widget[key], key) end
    -- lists of frames: the tabs of a tab group, the lines of a tree
    for _, key in ipairs({ "tabs", "buttons" }) do
        if type(widget[key]) == "table" then
            for index, frame in ipairs(widget[key]) do
                if type(frame) == "table" and S[frame] then Add(frame, key .. index) end
            end
        end
    end
    return list
end

-- The panel put behind our own windows (UI/DialogBacking.lua) is the addon's own
-- picture on a borrowed frame: it must be hidden when the frame is given back, and
-- what colour it has then is nobody's concern.
local backing = {}
do
    local make = UIParent.CreateTexture
    rawset(UIParent, "CreateTexture", function(...)
        local texture = make(...)
        backing[texture] = true
        return texture
    end)
end

local METHODS = { "OnRelease", "SetDisabled", "BuildTabs", "RefreshTree", "SetText", "SetLabel" }

-- Everything the skin may touch on a part, as text by name.
local function Snapshot(widget)
    local shot = {}
    for _, name in ipairs(METHODS) do shot["method " .. name] = tostring(rawget(widget, name)) end
    for _, entry in ipairs(Regions(widget)) do
        local object, path = entry.object, entry.path
        local kind = S[object].type
        if backing[object] then
            -- looked at when the windows are closed (it hides a moment after the frame)
        elseif Skin.IsOurs(object) then
            shot[path .. " ours shown"] = tostring(object:IsShown())
        else
            shot[path .. " alpha"] = Num(object:GetAlpha())
            if kind == "FontString" or kind == "EditBox" then
                shot[path .. " font"] = List(object:GetFont())
                shot[path .. " fontObject"] = FontName(object:GetFontObject())
                shot[path .. " textColor"] = List(object:GetTextColor())
                shot[path .. " shadow"] = List(object:GetShadowColor()) .. " at " .. List(object:GetShadowOffset())
            end
            if kind == "FontString" then
                shot[path .. " text"] = tostring(object:GetText())
                local points = {}
                for index = 1, object:GetNumPoints() do
                    local point, rel, relPoint, x, y = object:GetPoint(index)
                    points[index] = ("%s>%s.%s %s %s"):format(point, rel and (S[rel].name or S[rel].type) or "screen", relPoint, Num(x), Num(y))
                end
                shot[path .. " points"] = table.concat(points, "; ")
            end
            if kind == "Texture" then
                local s = S[object]
                shot[path .. " picture"] = tostring(s.file) .. "|" .. tostring(s.atlas) .. "|" .. (s.color and List(unpack(s.color)) or "no colour")
                shot[path .. " tint"] = List(object:GetVertexColor())
                shot[path .. " blend"] = object:GetBlendMode()
                shot[path .. " grey"] = tostring(object:IsDesaturated())
            end
            if S[object].isFrame and object.GetBackdropColor then
                shot[path .. " backdrop"] = List(object:GetBackdropColor()) .. " edge " .. List(object:GetBackdropBorderColor())
            end
            if object.GetNormalFontObject then
                shot[path .. " stateFonts"] = FontName(object:GetNormalFontObject()) .. "/" .. FontName(object:GetHighlightFontObject()) .. "/" .. FontName(object:GetDisabledFontObject())
            end
        end
    end
    return shot
end

---------------------------------------------------------------------------
-- Watching what the library lends and takes back
---------------------------------------------------------------------------
local lent = {}          -- part -> how it looked when it was lent
local natural = {}       -- "type|what" that differs without the skin too
local learning = true
local watching = true    -- off for the last part, which walks the windows another way
local theme = "none"
local reported = {}

local sequence = {}      -- every part given back, in order: { kind, how it looked }
local realCreate, realRelease = AceGUI.Create, AceGUI.Release
function AceGUI:Create(kind)
    local widget = realCreate(self, kind)
    lent[widget] = Snapshot(widget)
    stats.lent = stats.lent + 1
    return widget
end
function AceGUI:Release(widget)
    local before = lent[widget]
    local kind = widget.type
    realRelease(self, widget)
    if not watching then lent[widget] = nil return end
    if not before then return end
    lent[widget] = nil
    stats.back = stats.back + 1
    local after = Snapshot(widget)
    sequence[#sequence + 1] = { kind = kind, shot = after }
    for what, was in pairs(before) do
        local now = after[what]
        if what:find(" ours shown$") then
            if now == "true" then
                local key = kind .. "|" .. what
                if not reported[key] then
                    reported[key] = true
                    Problem(("theme %s: a picture of the skin stays on a %s after it is given back (%s)"):format(theme, tostring(kind), what))
                end
            end
        elseif now ~= was then
            local key = tostring(kind) .. "|" .. what
            if learning then
                if not natural[key] then natural[key] = true; stats.natural = stats.natural + 1 end
            elseif not natural[key] and not reported[key] then
                reported[key] = true
                Problem(("theme %s: a %s is given back changed: %s was [%s], is [%s]"):format(theme, tostring(kind), what, was, tostring(now)))
            end
        end
        stats.compared = stats.compared + 1
    end
    -- pictures of the skin made while it was lent must be hidden again
    for what, now in pairs(after) do
        if before[what] == nil and what:find(" ours shown$") and now == "true" then
            local key = tostring(kind) .. "|" .. what
            if not reported[key] then
                reported[key] = true
                Problem(("theme %s: a picture of the skin stays on a %s after it is given back (%s)"):format(theme, tostring(kind), what))
            end
        end
    end
end

---------------------------------------------------------------------------
-- While a window is skinned
---------------------------------------------------------------------------
local function Near(a, b) return math.abs(a - b) < 0.005 end
local function SameColor(r, g, b, color) return Near(r, color[1]) and Near(g, color[2]) and Near(b, color[3]) end

-- The texts of an open, skinned window carry the theme's font; plain texts its colours.
local function CheckSkinned(app, where)
    local root = D.Root(app)
    if not root then return end
    local current = RPSheet.db.profile.theme
    local font = ns.ThemeFont(current)
    local texts, ours = 0, 0
    for _, widget in ipairs(Parts(root)) do
        local kind = widget.type
        if Skin.styles[kind] then
            stats.styled = stats.styled + 1
            for _, key in ipairs({ "label", "text", "titletext" }) do
                local region = widget[key]
                if type(region) == "table" and S[region] and S[region].type == "FontString" and region:IsShown() and (region:GetText() or "") ~= "" then
                    texts = texts + 1
                    local file = region:GetFont()
                    if file ~= font and not (kind == "Button" or kind == "Dropdown" and key == "text") then
                        Problem(("%s: the %s of a %s has the font %s, not the theme's %s"):format(where, key, kind, tostring(file), font))
                    end
                end
            end
            if (kind == "Label" or kind == "InteractiveLabel" or kind == "RPSheetTermLabel") and not widget.disabled and widget.label:GetText() then
                local r, g, b = widget.label:GetTextColor()
                if not SameColor(r, g, b, current.text) then
                    Problem(("%s: a label's text is %s, not the theme's text colour %s"):format(where, List(r, g, b), List(unpack(current.text, 1, 3))))
                end
            end
            if kind == "Heading" and (widget.label:GetText() or "") ~= "" then
                local r, g, b = widget.label:GetTextColor()
                if not SameColor(r, g, b, current.accent) then Problem(where .. ": a heading isn't in the accent colour") end
            end
            if kind == "Button" then
                local r, g, b = widget.frame:GetFontString():GetTextColor()
                local wanted = widget.disabled and current.muted or current.accent
                if not SameColor(r, g, b, wanted) then
                    Problem(("%s: a button's text is %s, not %s"):format(where, List(r, g, b), List(unpack(wanted, 1, 3))))
                end
                if widget.frame:GetFontString():GetFont() ~= font then Problem(where .. ": a button's text isn't in the theme's font") end
            end
        end
        for _, entry in ipairs(Regions(widget)) do
            if Skin.IsOurs(entry.object) and entry.object:IsShown() then ours = ours + 1 end
        end
    end
    stats.ownShown = stats.ownShown + ours
    Check(where .. ": no text of the window was looked at", texts > 0)
    Check(where .. ": the skin drew nothing of its own", ours > 0)
    -- no colour code of the default look is left in a text on a light theme
    local bg = current.bg
    if 0.299 * bg[1] + 0.587 * bg[2] + 0.114 * bg[3] > 0.5 then
        for _, widget in ipairs(Parts(root)) do
            local text = PartText(widget)
            if Skin.styles[widget.type] and (text:find(Opt.RED, 1, true) or text:find(Opt.GREEN, 1, true) or text:find(Opt.GOLD, 1, true)) then
                Problem(where .. ": a text keeps a colour made for a dark window: " .. F.Plain(text):sub(1, 50))
                break
            end
        end
    end
    for kind, why in pairs(Skin.failed) do
        Problem(("%s: the skin gave up on %s: %s"):format(where, tostring(kind), tostring(why)))
        Skin.failed[kind] = nil
    end
    CheckHidden(where)
end

---------------------------------------------------------------------------
-- The same walk through the windows, with or without the skin
---------------------------------------------------------------------------
local PAGES = {
    { "character" }, { "customize", "weapons" }, { "customize", "spells" }, { "customize", "spells", "item1" }, { "customize", "abilities", "item1" },
    { "customize", "passives", "item1" }, { "customize", "items" }, { "customize", "origin" }, { "customize", "scores" }, { "customize", "proficiencies" },
    { "customize", "professions" }, { "customize", "defense" }, { "general" }, { "appearance" }, { "transfer" }, { "profiles" },
}

-- Things a player does on a page that make the library redraw parts: a dropdown's
-- list opened and shut, a tick box ticked and unticked, the tree scrolled.
local function Fiddle(app, where)
    local opened, ticked = false, false
    for _, control in ipairs(D.Controls(app)) do
        if not opened and control.type == "Dropdown" and not control.disabled then
            opened = true
            Try(where .. " open list", F.Click, control.button_cover)
            F.Settle()
            if control.open then
                for _, item in control.pullout:IterateItems() do
                    Try(where .. " hover line", F.Enter, item.frame)
                    Try(where .. " leave line", F.Leave, item.frame)
                    break
                end
                control.pullout:Close()
            end
        elseif not ticked and control.type == "CheckBox" and not control.disabled then
            ticked = true
            local option = control:GetUserData("option")
            local value = control:GetUserData("value")
            Try(where .. " tick", F.Click, control.frame)
            D.After(where .. " tick")
            local again = D.Control(app, option, value)
            if again then Try(where .. " untick", F.Click, again.frame) D.After(where .. " untick") end
        end
    end
    for _, part in ipairs(D.Root(app) and Parts(D.Root(app)) or {}) do
        if part.type == "TreeGroup" and part.scrollbar:IsShown() then
            local _, high = part.scrollbar:GetMinMaxValues()
            Try(where .. " scroll tree", F.Drag, part.scrollbar, high)
            Try(where .. " scroll tree back", F.Drag, part.scrollbar, 0)
            F.Settle()
        end
    end
end

-- `presets` are applied in turn while the windows are open (none: the walk alone).
local function Scenario(label, presets, skinned)
    local at = 0
    local function NextTheme(where, app)
        if #presets == 0 then return end
        at = at % #presets + 1
        theme = presets[at]
        Try(where .. " theme " .. theme, function() RPSheet:LoadThemePreset(theme) end)
        F.Settle()
        stats.themes = stats.themes + 1
        if skinned and app then CheckSkinned(app, ("%s theme %s"):format(where, theme)) end
    end
    Use(NewCharacter("PALADIN", nil, nil, 9, 2))
    for _, name in ipairs({ "Longsword", "Shield", "Chain Mail", "Rope" }) do RPSheet:SetEquipped(RPSheet:AddItem(name, 1), true) end
    RPSheet:Sheet().renown[R.ALL_FACTIONS[1]] = 12
    ns.RebuildOptions()
    RPSheet:SheetChanged()
    F.Settle(true)

    -- the settings window: each page, with a theme applied on it
    Try(label .. " open settings", function() AceConfigDialog:Open(MAIN) F.Settle() end)
    for _, path in ipairs(PAGES) do
        local where = label .. " " .. table.concat(path, "/")
        Try(where, D.Open, MAIN, path)
        if skinned then CheckSkinned(MAIN, where) end
        NextTheme(where, MAIN)
        Try(where .. " fiddle", Fiddle, MAIN, where)
        if skinned then CheckSkinned(MAIN, where .. " after fiddling") end
    end
    -- every preset on one page that has every kind of control
    Try(label .. " origin", D.Open, MAIN, { "customize", "origin" })
    for _ = 1, #presets do NextTheme(label .. " customize/origin", MAIN) end
    -- the item browser beside it
    Try(label .. " item browser", function()
        RPSheet:ToggleItemBrowser()
        F.Settle()
        for _ = 1, math.max(1, #presets) do
            NextTheme(label .. " item browser")
            for _, part in ipairs(RPSheet.itemBody.children) do
                if part.type == "RPSheetTab" and part.text:GetText() == "Armor" then F.Click(part.frame) break end
            end
            F.Settle()
        end
        RPSheet.itemWindow:Hide()
        RPSheet.itemBody:ReleaseChildren()
    end)
    Try(label .. " close settings", function() AceConfigDialog:Close(MAIN) F.Settle() end)

    -- the wizard: its first steps
    Try(label .. " wizard", function()
        RPSheet:SlashCommand("new")
        F.Settle()
        if skinned then CheckSkinned(WIZARD, label .. " wizard step 1") end
        NextTheme(label .. " wizard step 1", WIZARD)
        D.Set(WIZARD, "class", "MAGE", label .. " wizard class")
        D.Set(WIZARD, "level", 5, label .. " wizard level")
        Fiddle(WIZARD, label .. " wizard")
        if skinned then CheckSkinned(WIZARD, label .. " wizard class chosen") end
        for _ = 1, #presets do NextTheme(label .. " wizard", WIZARD) end
        D.Press(WIZARD, "skip", label .. " wizard Not now")
        F.Settle()
        W.draft = nil
        if D.Shown(WIZARD) then AceConfigDialog:Close(WIZARD) F.Settle() end
    end)

    -- the level dialog: the next level
    Try(label .. " level dialog", function()
        ns.OpenLevelDialog()
        F.Settle()
        if skinned then CheckSkinned(LEVEL, label .. " level dialog") end
        for _ = 1, math.max(1, #presets) do NextTheme(label .. " level dialog", LEVEL) end
        Fiddle(LEVEL, label .. " level dialog")
        if skinned then CheckSkinned(LEVEL, label .. " level dialog after fiddling") end
        ns.LevelDialog.draft = nil
        AceConfigDialog:Close(LEVEL)
        F.Settle()
    end)
    AceConfigDialog:CloseAll()
    F.Settle()
    Check(label .. ": windows are still open", next(AceConfigDialog.OpenFrames) == nil)
    for texture in pairs(backing) do
        if texture:IsVisible() then Problem(label .. ": the panel behind a window is still shown after the window closed") break end
    end
    CheckHidden(label)
end

---------------------------------------------------------------------------
-- 1. Without the skin: what changes on a part anyway
---------------------------------------------------------------------------
-- The same walk gives the same parts back in the same order. So a walk with the skin
-- can be laid beside one without it, part by part: whatever differs, the skin left
-- behind. What differs between two walks without the skin (a part that keeps
-- something from an earlier use) is left out.
local function Compare(first, second, unstable, label)
    local differences = 0
    if #first ~= #second then
        Problem(("%s: %d parts were given back, %d in the walk it is compared with"):format(label, #second, #first))
        return 0
    end
    for index, one in ipairs(first) do
        local other = second[index]
        if one.kind ~= other.kind then
            Problem(("%s: part %d given back is a %s, not a %s as in the walk it is compared with"):format(label, index, tostring(other.kind), tostring(one.kind)))
            return differences
        end
        for what, was in pairs(one.shot) do
            local now = other.shot[what]
            if now ~= was and not what:find(" ours shown$") then
                local key = tostring(one.kind) .. "|" .. what
                if label == nil then
                    unstable[key] = true
                elseif not unstable[key] then
                    differences = differences + 1
                    if not reported["seq" .. key] then
                        reported["seq" .. key] = true
                        Problem(("%s: a %s is given back different from a walk without the skin: %s is [%s], without the skin [%s]"):format(label, tostring(one.kind), what, tostring(now), was))
                    end
                end
            end
        end
    end
    return differences
end

local realStyle, realRestyle = Skin.Style, Skin.Restyle
Skin.Style, Skin.Restyle = function() end, function() end
Scenario("no skin", ns.THEME_ORDER, false)
sequence = {}
Scenario("no skin again", ns.THEME_ORDER, false)
local plainOne = sequence
sequence = {}
Scenario("no skin a third time", ns.THEME_ORDER, false)
local plainTwo = sequence
sequence = {}
Skin.Style, Skin.Restyle = realStyle, realRestyle
Check("without the skin no part came back", stats.back > 200)
local learned = stats.natural
local unstable = {}
Compare(plainOne, plainTwo, unstable, nil)
local unstableCount = 0
for _ in pairs(unstable) do unstableCount = unstableCount + 1 end

---------------------------------------------------------------------------
-- 2. With the skin: every preset, and nothing else may differ
---------------------------------------------------------------------------
learning = false
Scenario("skinned", ns.THEME_ORDER, true)
local skinnedOne = sequence
sequence = {}
Compare(plainTwo, skinnedOne, unstable, "skinned walk")
Scenario("skinned again", ns.THEME_ORDER, true)
Compare(plainTwo, sequence, unstable, "second skinned walk")
sequence = {}
-- each preset alone, from first opening to closing
for _, key in ipairs(ns.THEME_ORDER) do
    theme = key
    RPSheet:LoadThemePreset(key)
    Scenario("skinned " .. key, {}, true)
end
---------------------------------------------------------------------------
-- 3. Styled once in a redraw looks the same as styled every time it is walked
---------------------------------------------------------------------------
-- The skin walks a window group by group and styles a part only the first time it
-- comes past it in one redraw. Every page must look exactly as it does when every
-- walk styles every part again.
local function LookOf(app)
    local list = {}
    for _, widget in ipairs(Parts(D.Root(app))) do list[#list + 1] = { kind = widget.type, shot = Snapshot(widget) } end
    return list
end
local samePages = 0
watching = false
Try("styled once or every time", function()
    Use(NewCharacter("PALADIN", nil, nil, 9, 2))
    for _, key in ipairs({ "DARK", "PARCHMENT", "MINIMAL" }) do
        theme = key
        RPSheet:LoadThemePreset(key)
        AceConfigDialog:Open(MAIN)
        F.Settle()
        for _, path in ipairs(PAGES) do
            local where = ("theme %s page %s"):format(key, table.concat(path, "/"))
            -- every walk styles: each call counts as a redraw of its own
            Skin.Style = function(widget, current)
                Skin.pass = Skin.pass + 1
                return realStyle(widget, current)
            end
            D.Open(MAIN, path)
            Fiddle(MAIN, where)
            REGISTRY:NotifyChange(MAIN)
            F.Settle()
            local every = LookOf(MAIN)
            Skin.Style = realStyle
            AceConfigDialog:Close(MAIN)
            F.Settle()
            AceConfigDialog:Open(MAIN)
            F.Settle()
            D.Open(MAIN, path)
            Fiddle(MAIN, where)
            REGISTRY:NotifyChange(MAIN)
            F.Settle()
            local once = LookOf(MAIN)
            samePages = samePages + 1
            if #every ~= #once then
                Problem(("%s: %d parts when styled once, %d when styled every time"):format(where, #once, #every))
            else
                for index, one in ipairs(every) do
                    local other = once[index]
                    if one.kind == other.kind then
                        for what, was in pairs(one.shot) do
                            if other.shot[what] ~= was and not what:find("^method ") then
                                local id = "once" .. tostring(one.kind) .. what
                                if not reported[id] then
                                    reported[id] = true
                                    Problem(("%s: a %s looks different when it is styled only once in a redraw: %s is [%s], styled every time [%s]"):format(
                                        where, tostring(one.kind), what, tostring(other.shot[what]), was))
                                end
                            end
                        end
                    end
                end
            end
        end
        AceConfigDialog:Close(MAIN)
        F.Settle()
    end
end)
Skin.Style = realStyle

for kind, why in pairs(Skin.failed) do Problem(("the skin gave up on %s: %s"):format(tostring(kind), tostring(why))) end
local left = 0
for _ in pairs(lent) do left = left + 1 end
RPSheet:LoadThemePreset("DARK")

SmokeChecks("after the skin tests")
Finish("skin", ("%d presets; %d parts lent and %d taken back, %d of their properties compared (%d kinds differ between lending and return without the skin too, %d between two walks without it; %d parts still in use at the end); %d skinned parts looked at, %d theme changes with a window open; %d pages look the same styled once or at every walk"):format(
    #ns.THEME_ORDER, stats.lent, stats.back, stats.compared, learned, unstableCount, left, stats.styled, stats.themes, samePages))
