-- Upkeep of the carried items when a sheet is loaded or imported (called from
-- ns.NormalizeInventory, Sheet/Inventory.lua): an item taken from the catalogue long
-- ago picks up what the catalogue has learned about it since, and spell scrolls
-- written before scrolls knew their writer are marked as the character's own.
--
-- Earlier versions of the catalogue are not kept, so there is no telling for sure
-- whether an item differs from it because the catalogue moved on or because the
-- player changed it. The rule is therefore a careful one: only an item that has no
-- effects at all, and a note that is empty or still the catalogue's own, is brought
-- up to date. Anything else is taken as edited and left alone, except that a missing
-- price, weight or rarity is filled in, since "none" was never a choice there.
local _, ns = ...
local R = ns.Rules

local function Refresh(item, known)
    if item.cost == 0 then item.cost = known.cost or 0 end
    if item.weight == 0 then item.weight = known.weight or 0 end
    if item.rarity == "" then item.rarity = known.rarity end
    item.magic = true
    if #item.effects > 0 or not (item.desc == "" or item.desc == (known.desc or "")) then return end
    item.desc = known.desc or ""
    item.attune = item.attune or known.attune == true
    if item.limit == "" then item.limit = known.limit or "" end
    for _, effect in ipairs(known.effects or {}) do
        item.effects[#item.effects + 1] = CopyTable(effect)
    end
end

-- A scroll from before item.scribed existed: the sheet only made scrolls by
-- scribing, and those said so in their note and had no price. It gets its price
-- with the mark, so this happens once and a later change by the player stays.
local function OldScroll(item)
    local name, level = ns.ScrollSpell(item)
    if not name or item.scribed or item.cost > 0 or not item.desc:find("written by you", 1, true) then return end
    item.scribed, item.cost = true, R.ScrollValue(level)
end

function ns.RefreshItems(sheet)
    for _, item in ipairs(sheet.items) do
        local known = R.ITEMS[item.name]
        if known and known.rarity then Refresh(item, known) end
        OldScroll(item)
    end
end
