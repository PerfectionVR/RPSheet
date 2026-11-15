-- Draws the creation wizard and the level dialog in the sheet's theme. Both are windows
-- of the options library, built from parts it lends out and takes back for the next
-- window, which may be another addon's. So nothing here changes a part for good:
-- whatever is changed is remembered and put back the moment the part is handed back.
--
-- This file finds the parts of an open window and does the remembering and undoing.
-- What each kind of part looks like is in DialogSkinWidgets.lua (controls),
-- DialogSkinButton.lua (buttons) and DialogSkinFrame.lua (the window itself).
local ADDON, ns = ...
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local Skin = { styles = {}, failed = {} }
ns.DialogSkin = Skin

-- Only these two. The settings window swaps pages without being reopened, so its
-- parts could not be caught reliably.
local OURS = { [ADDON .. "Wizard"] = true, [ADDON .. "Level"] = true }

local records = {} -- part -> what to undo when it is handed back

-- The library calls a part's OnRelease when it takes the part back; ours runs first.
local function Track(widget)
    local record = { undo = {}, seen = {}, original = rawget(widget, "OnRelease") }
    records[widget] = record
    widget.OnRelease = function(self, ...)
        local original = record.original
        Skin.Restore(self)
        if original then return original(self, ...) end
    end
    return record
end

-- Puts back everything that was changed on a part, newest change first.
function Skin.Restore(widget)
    local record = records[widget]
    if not record then return end
    records[widget] = nil
    widget.OnRelease = record.original
    for index = #record.undo, 1, -1 do
        pcall(record.undo[index]) -- one failed undo must not stop the others
    end
end

-- True the first time a thing on a part is touched: the moment to note how it was.
function Skin.First(widget, kind, key)
    local record = records[widget] or Track(widget)
    local seen = record.seen[kind]
    if not seen then
        seen = {}
        record.seen[kind] = seen
    end
    if seen[key] then return false end
    seen[key] = true
    return true
end

function Skin.Undo(widget, undo)
    local record = records[widget] or Track(widget)
    record.undo[#record.undo + 1] = undo
end

-- Styles a part, then the parts inside it. A kind of part that fails once is left
-- alone from then on: a plain window is better than an error.
local function Walk(widget, theme, isRoot)
    local kind = widget.type
    local style = kind and Skin.styles[kind]
    if style and not Skin.failed[kind] then
        local ok, problem = pcall(style, widget, theme)
        if not ok then
            Skin.failed[kind] = problem or true
            Skin.Restore(widget)
        end
    end
    local children = widget.children
    if type(children) ~= "table" then return end
    for _, child in ipairs(children) do
        if type(child) == "table" then Walk(child, theme) end
    end
    -- Another font takes another amount of room, so the parts are set out again,
    -- innermost group first. The window itself keeps its size.
    if not isRoot and type(widget.DoLayout) == "function" then
        pcall(widget.DoLayout, widget)
    end
end

function Skin.Apply(dialog)
    local root = AceConfigDialog.OpenFrames[dialog]
    local theme = ns.addon.db and ns.addon.db.profile.theme
    if type(root) ~= "table" or not theme then return end
    Walk(root, theme, true)
end

-- The library rebuilds a window's contents through Open, both when it is first shown
-- and after every change, and has finished building when Open returns.
hooksecurefunc(AceConfigDialog, "Open", function(_, dialog, container)
    if OURS[dialog] and type(container) ~= "table" then Skin.Apply(dialog) end
end)

-- After a theme change: the open windows take the new look straight away.
function ns.SkinOpenDialogs()
    for dialog in pairs(OURS) do
        if AceConfigDialog.OpenFrames[dialog] then
            ns.AddDialogBacking(dialog)
            Skin.Apply(dialog)
        end
    end
end
