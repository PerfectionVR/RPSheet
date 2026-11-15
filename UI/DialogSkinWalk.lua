-- When the dialog skin walks a window (see DialogSkin.lua). Only windows the options
-- library opened under one of our own names are ever walked, starting at that window
-- or at a group inside it: a part of another addon's window is never reached.
local ADDON, ns = ...
local Skin = ns.DialogSkin
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local OURS = { [ADDON] = true, [ADDON .. "Wizard"] = true, [ADDON .. "Level"] = true }

function Skin.Apply(dialog)
    local root = AceConfigDialog.OpenFrames[dialog]
    local theme = Skin.Theme()
    if type(root) ~= "table" or not theme then return end
    pcall(Skin.Walk, root, { theme = theme }, true) -- never an error into the library
    Skin.pass = Skin.pass + 1 -- this redraw is done: the next one styles every part again
end

-- The library rebuilds a window's contents through Open, both when it is first shown
-- and after every change, and has finished building when Open returns. Settings shown
-- inside the game's own options panel are given a container and are left alone.
hooksecurefunc(AceConfigDialog, "Open", function(_, dialog, container)
    if OURS[dialog] and type(container) ~= "table" then Skin.Apply(dialog) end
end)

-- Picking a tab or an entry of the tree on the left fills that group again without
-- going through Open. Every such filling goes through FeedGroup, with the group as
-- the container and the window it stands in as the root frame.
hooksecurefunc(AceConfigDialog, "FeedGroup", function(_, dialog, _, container, rootframe, _, isRoot)
    if isRoot or not OURS[dialog] or type(container) ~= "table" then return end
    if rootframe == nil or rootframe ~= AceConfigDialog.OpenFrames[dialog] then return end
    local theme = Skin.Theme()
    if theme then pcall(Skin.Walk, container, { theme = theme }, true) end
end)

-- After a theme change: the open windows take the new look straight away.
function ns.SkinOpenDialogs()
    Skin.pass = Skin.pass + 1 -- another theme: every part is styled again
    for dialog in pairs(OURS) do
        if AceConfigDialog.OpenFrames[dialog] then
            ns.AddDialogBacking(dialog)
            Skin.Apply(dialog)
        end
    end
end
