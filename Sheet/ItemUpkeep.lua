-- Upkeep of the carried items when a sheet is loaded or imported (called from
-- ns.NormalizeInventory, Sheet/Inventory.lua): an item taken from the catalogue picks
-- up what the catalogue has learned about it since, and spell scrolls written before
-- scrolls knew their writer are marked as the character's own.
--
-- An entry records whether the player changed it under Customize (item.edited). One
-- that was made since that is recorded (item.tracked) and was not changed is wholly
-- the catalogue's: effects, note, rarity, attunement, price and weight follow it. One
-- the player changed is left alone.
--
-- Entries from before the record can't say whether they differ from the catalogue
-- because it moved on or because the player changed them, so the rule for them stays
-- a careful one: only an item with no effects at all, and a note that is empty or
-- still the catalogue's own, is brought up to date; anything else is taken as edited,
-- except that a missing price, weight or rarity is filled in, since "none" was never
-- a choice there. An old entry that has come to match the catalogue in everything is
-- as good as new, and is tracked from then on.
local _, ns = ...
local R = ns.Rules

-- Tracked and unchanged: everything the catalogue says, except how many there are
-- and whether it is worn and attuned.
local function Full(item, known)
    item.desc, item.cost, item.weight = known.desc or "", known.cost or 0, known.weight or 0
    item.magic, item.rarity = known.rarity ~= nil, known.rarity or ""
    item.attune, item.limit = known.attune == true, known.limit or ""
    if not item.attune then item.attuned = false end
    item.effects = {}
    for _, effect in ipairs(known.effects or {}) do
        item.effects[#item.effects + 1] = CopyTable(effect)
    end
end

-- From before edits were recorded: the careful rule, for magic items as before.
local function Careful(item, known)
    if not known.rarity then return end
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

-- True when an old entry says exactly what the catalogue says.
local function Matches(item, known)
    if item.desc ~= (known.desc or "") or item.cost ~= (known.cost or 0) or item.weight ~= (known.weight or 0) then return false end
    if item.rarity ~= (known.rarity or "") or item.magic ~= (known.rarity ~= nil) then return false end
    if item.attune ~= (known.attune == true) or item.limit ~= (known.limit or "") then return false end
    local effects = known.effects or {}
    if #item.effects ~= #effects then return false end
    for index, effect in ipairs(effects) do
        local own = item.effects[index]
        if own.target ~= effect.target or own.flat ~= (effect.flat or 0) or (own.stat or "") ~= (effect.stat or "")
            or (own.mode or "") ~= (effect.mode or "") or own.times ~= (effect.times or 1) then return false end
    end
    return true
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
        local made = item.variant ~= "" -- a magic make goes by its make, not by a listed item of its name
        local known = not made and R.ITEMS[item.name] or nil
        if item.edited then
            -- the player's own from here on
        elseif made then
            if item.tracked then ns.RefreshVariantItem(item) end
        elseif known and item.tracked then
            Full(item, known)
        elseif known then
            Careful(item, known)
            item.tracked = Matches(item, known)
        end
        OldScroll(item)
    end
    ns.MergeStacks(sheet) -- used-up magic items that were bought one entry each (Sheet/ItemStacks.lua)
end
