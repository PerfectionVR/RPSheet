-- Draws the settings window, the creation wizard and the level dialog in the sheet's
-- theme. All three are windows of the options library, built from parts it lends out
-- and takes back for the next window, which may be another addon's. So nothing here
-- changes a part for good: whatever is changed is remembered and put back the moment
-- the part is handed back.
--
-- This file finds the parts of an open window and does the remembering and undoing.
-- When a window is walked is in DialogSkinWalk.lua; what each kind of part looks like
-- is in the other DialogSkin files.
local _, ns = ...

local Skin = { styles = {}, failed = {} }
ns.DialogSkin = Skin

-- Counts the redraws of a window. The library fills a window from the inside out and
-- each filled group is walked (DialogSkinWalk.lua), so one redraw comes past the same
-- part up to three times: it is styled the first time only.
Skin.pass = 1

local records = {} -- part -> what to undo when it is handed back

function Skin.Theme()
    return ns.addon.db and ns.addon.db.profile.theme
end

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

-- Styles one part. A kind of part that fails once is left alone from then on: a plain
-- window is better than an error.
function Skin.Style(widget, theme)
    local kind = widget.type
    local style = kind and Skin.styles[kind]
    if not style or Skin.failed[kind] then return end
    local record = records[widget]
    if record and record.pass == Skin.pass then return end -- styled in this redraw already
    local ok, problem = pcall(style, widget, theme)
    if not ok then
        Skin.failed[kind] = problem or true
        Skin.Restore(widget)
        return
    end
    record = records[widget]
    if record then record.pass = Skin.pass end
end

-- Styles a part again that is already styled, after the library changed its state.
function Skin.Restyle(widget)
    local theme = Skin.Theme()
    local record = records[widget]
    if theme and record then
        record.pass = nil -- its state changed since it was styled
        Skin.Style(widget, theme)
    end
end

local function Then(widget, after, busy, ...)
    if not busy[1] and records[widget] then
        busy[1] = true
        pcall(after, widget)
        busy[1] = nil
    end
    return ...
end

-- Some parts redraw themselves long after the window was built (a tick that is
-- clicked, a list that is scrolled). `after` runs each time the part's own function
-- of that name has run, for as long as the part is ours; the function is put back
-- as it was when the part is handed back.
function Skin.After(widget, name, after)
    local original = widget[name]
    if type(original) ~= "function" or not Skin.First(widget, "method", name) then return end
    local own, busy = rawget(widget, name), {}
    local function wrapper(self, ...)
        return Then(self, after, busy, original(self, ...))
    end
    widget[name] = wrapper
    Skin.Undo(widget, function()
        if rawget(widget, name) == wrapper then widget[name] = own end
    end)
end

-- Styles a part, then the parts inside it. `pass` is { theme = the theme, only = the
-- kinds to style (all when missing), still = true to leave the layout as it is }.
function Skin.Walk(widget, pass, isRoot)
    if not pass.only or pass.only[widget.type] then Skin.Style(widget, pass.theme) end
    local children = widget.children
    if type(children) ~= "table" then return end
    for _, child in ipairs(children) do
        if type(child) == "table" then Skin.Walk(child, pass) end
    end
    -- Another font takes another amount of room, so the parts are set out again,
    -- innermost group first. The part the walk started at keeps its size.
    if not isRoot and not pass.still and type(widget.DoLayout) == "function" then
        pcall(widget.DoLayout, widget)
    end
end

-- For a window of our own that is built from the library's parts (the item browser):
-- styles the kinds in `only` among the parts inside `root`. They are handed back to
-- the library like any others, so they are undone in the same way.
function Skin.ApplyTo(root, theme, only)
    if type(root) ~= "table" or not theme then return end
    pcall(Skin.Walk, root, { theme = theme, only = only, still = true }, true)
end
