-- A fake game UI that windows can really be built in: frames whose anchors and sizes
-- are worked out, so layouts run; a tooltip, context menus and popups a test can read
-- and click; timers a test runs; and on top of it the REAL AceGUI-3.0, AceConfig-3.0
-- and AceConfigDialog-3.0 with all their widgets.
--
-- Use: dofile(ARG3 .. "/env.lua"), then dofile(ARG3 .. "/t-test-windows-ui.lua"), then
-- LoadAddon(). It must come before LoadAddon: the addon's files keep the libraries they
-- find while loading. t-test-windows-base.lua does all of this and adds test helpers.
--
-- What a test steers (all in the UIFAKE table, F below):
--   F.Enter(frame) / F.Leave(frame) / F.Click(frame, "RightButton")   the mouse
--   F.MoveMouse(region, fx, fy, dx)   the cursor alone (GetCursorPosition, IsMouseOver)
--   F.SetKeys(shift, ctrl, alt)       the modifier keys
--   F.Type(editBox, text, enter) / F.Drag(slider, value)
--   F.Update(elapsed)                 one frame: OnUpdate on every visible frame
--   RunTimers()                       runs what C_Timer queued;  F.Settle() does both
--   F.TooltipLines() / F.TooltipText()             what GameTooltip shows
--   F.menu, F.MenuTitles(), F.MenuRows(), F.MenuClick(row or text), F.MenuHover(row)
--   F.popup, F.PopupText(), F.PopupType(text, enter), F.PopupAccept(), F.PopupCancel()
--   F.PickColor(r, g, b, a)           answers the colour picker
--   F.Fire(frame, "OnSizeChanged", ...)            any script by hand
--   F.unknownTemplates                frame templates that were asked for but aren't faked
local HERE = ARG3
dofile(HERE .. "/t-test-windows-ui-frames.lua")
dofile(HERE .. "/t-test-windows-ui-widgets.lua")
dofile(HERE .. "/t-test-windows-ui-game.lua")
local F = UIFAKE

-- The libraries are downloaded at release time, so they may not be in the checkout:
-- then the copies named in tests/local.cfg (ACE_LIBS) are read, never written.
local function exists(path)
    local file = io.open(path, "r")
    if file then file:close() return true end
    return false
end
local ROOTS = { ARG1 .. "/Libs" }
for path in tostring(rawget(_G, "ACE_LIBS") or ""):gmatch("[^;]+") do ROOTS[#ROOTS + 1] = path end
local root
for _, candidate in ipairs(ROOTS) do
    if exists(candidate .. "/AceGUI-3.0/AceGUI-3.0.lua") and exists(candidate .. "/AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua") then
        root = candidate
        break
    end
end
if not root then error("t-test-windows-ui: no copy of AceGUI-3.0 and AceConfig-3.0 found") end
F.libRoot = root

-- env.lua registered thin stand-ins under these names; the real ones replace them.
for _, name in ipairs({ "AceGUI-3.0", "AceConfigDialog-3.0", "AceConfig-3.0" }) do
    LibStub.libs[name], LibStub.minors[name] = nil, nil
end
OPENED = nil

local function load(path)
    local chunk, problem = loadfile(root .. "/" .. path)
    if not chunk then error(problem) end
    chunk(path, {})
end

load("AceGUI-3.0/AceGUI-3.0.lua")
-- The order of AceGUI-3.0.xml.
for _, name in ipairs({
    "AceGUIContainer-BlizOptionsGroup", "AceGUIContainer-DropDownGroup", "AceGUIContainer-Frame", "AceGUIContainer-InlineGroup",
    "AceGUIContainer-ScrollFrame", "AceGUIContainer-SimpleGroup", "AceGUIContainer-TabGroup", "AceGUIContainer-TreeGroup",
    "AceGUIContainer-Window", "AceGUIWidget-Button", "AceGUIWidget-CheckBox", "AceGUIWidget-ColorPicker", "AceGUIWidget-DropDown",
    "AceGUIWidget-DropDown-Items", "AceGUIWidget-EditBox", "AceGUIWidget-Heading", "AceGUIWidget-Icon", "AceGUIWidget-InteractiveLabel",
    "AceGUIWidget-Keybinding", "AceGUIWidget-Label", "AceGUIWidget-MultiLineEditBox", "AceGUIWidget-Slider",
}) do
    load("AceGUI-3.0/widgets/" .. name .. ".lua")
end
if exists(root .. "/AceConfig-3.0/AceConfigCmd-3.0/AceConfigCmd-3.0.lua") then
    load("AceConfig-3.0/AceConfigCmd-3.0/AceConfigCmd-3.0.lua")
end
load("AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua")
load("AceConfig-3.0/AceConfig-3.0.lua")

F.AceGUI = LibStub("AceGUI-3.0")
F.AceConfigDialog = LibStub("AceConfigDialog-3.0")
