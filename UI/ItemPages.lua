-- Pages for the item browser (UI/ItemBrowser.lua). A tab can list several hundred
-- blocks, and every block is a handful of widgets that are made again after each click,
-- so only one page of them is built at a time.
local _, ns = ...
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")

local PAGE = 24 -- blocks on a page: twelve rows of two

local Pages = {}
UI.ItemPages = Pages

local page = 1
local seenSource, seenTab, seenSearch -- what the page number belongs to

-- The first and last entry to show out of `total`. Goes back to the first page when
-- the source, the tab or the search is another than last time; otherwise the page is
-- kept, so a block's button leaves the list where it was.
function Pages.Range(total, source, tab, search)
    if source ~= seenSource or tab ~= seenTab or search ~= seenSearch then
        seenSource, seenTab, seenSearch, page = source, tab, search, 1
    end
    -- The list may have become shorter since the page was chosen.
    page = math.max(1, math.min(page, math.ceil(total / PAGE)))
    local first = (page - 1) * PAGE + 1
    return first, math.min(total, first + PAGE - 1)
end

-- One page back (-1) or on (1). The next Range keeps it within what there is.
function Pages.Turn(step)
    page = page + step
end

-- The "previous / next" row, saying which entries are shown. Nothing when they all fit
-- on one page. `turn(step)` is called by the buttons.
function Pages.AddControls(body, first, last, total, turn)
    if total <= PAGE then return end
    UI.AddItemButton(body, 0.25, "Previous", first > 1, function() turn(-1) end)
    local label = UI.AddLabel(body, 0.5, ("Showing %s%d-%d|r of %s%d|r"):format(UI.ACCENT, first, last, UI.ACCENT, total))
    label:SetJustifyH("CENTER")
    UI.AddItemButton(body, 0.25, "Next", last < total, function() turn(1) end)
end
