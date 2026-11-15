-- What the item browser lists and what its search finds (UI/ItemBrowser.lua has the
-- window and what a source is). The search looks at a block's name, at the words
-- after its title and at what the block says: an item's description, its kind, a
-- weapon's properties, a magic item's rarity and attunement. So "healing", "fire",
-- "finesse", "martial" and "attunement" all find things. Several words must all be
-- found. It goes over the whole tab, or over every tab of the source at once.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI

local Search = {}
UI.ItemSearch = Search

-- Stands for "every tab" where a tab is asked for (the page kept by UI/ItemPages.lua).
Search.ALL = { name = "Everything" }

-- The entries of one tab of a source.
function Search.TabEntries(self, source, tab)
    if tab == source.first then return source.own(self) end
    if source.list then return source.list(self, tab) end
    local entries = {}
    for _, name in ipairs(source.names and source.names(tab.kind) or R.ITEM_NAMES[tab.kind] or {}) do
        entries[#entries + 1] = { name = name, item = source.find(self, name) }
    end
    return entries
end

-- The tabs of a source after the first, as they are now.
function Search.Tabs(self, source)
    return type(source.kinds) == "function" and source.kinds(self) or source.kinds
end

-- The entries of every tab, one after the other. Each says which tab it is from
-- (entry.fromTab), since its buttons depend on that. A first tab that only repeats
-- what the other tabs list (source.ownListed) is left out.
function Search.AllEntries(self, source)
    local entries = {}
    local function Take(tab)
        for _, entry in ipairs(Search.TabEntries(self, source, tab)) do
            entry.fromTab = tab
            entries[#entries + 1] = entry
        end
    end
    if not source.ownListed then Take(source.first) end
    for _, tab in ipairs(Search.Tabs(self, source)) do Take(tab) end
    return entries
end

-- Colour codes are not words.
local function Plain(text)
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")):lower()
end

-- Everything about an entry the search looks at, in small letters. A source can say
-- it more cheaply than by building the block (source.words).
local function Haystack(self, source, entry)
    local parts = { entry.name, table.concat(source.marks(self, entry), " ") }
    if source.words then
        parts[#parts + 1] = source.words(self, entry)
    else
        local lines = source.lines and source.lines(self, entry) or UI.ItemLines(self, entry.name, entry.item, source.class(self))
        parts[#parts + 1] = table.concat(lines, "\n")
    end
    return Plain(table.concat(parts, "\n"))
end

-- True when every word of `search` (small letters) is found in the entry. The name
-- is tried first: most searches are for one, and the rest is only built when needed.
function Search.Matches(self, source, entry, search)
    if search == "" then return true end
    local name, hay = entry.name:lower(), nil
    for word in search:gmatch("%S+") do
        if not name:find(word, 1, true) then
            hay = hay or Haystack(self, source, entry)
            if not hay:find(word, 1, true) then return false end
        end
    end
    return true
end

-- The entries to show: of the open tab or of every tab, the ones the search finds.
function Search.Find(self, source, tab, search, everywhere)
    local entries = everywhere and Search.AllEntries(self, source) or Search.TabEntries(self, source, tab)
    if search == "" then return entries end
    local matching = {}
    for _, entry in ipairs(entries) do
        if Search.Matches(self, source, entry, search) then matching[#matching + 1] = entry end
    end
    return matching
end
