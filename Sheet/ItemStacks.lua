-- Which carried items share an entry. Plain gear of one name always does. A magic
-- item is an entry of its own, since each is equipped and attuned by itself, except
-- the ones that are used up and need no attunement (potions, dusts, magic
-- ammunition): identical ones stack, so two bought potions are one line of two. One
-- the player changed, attuned to or wrote (a scroll) stays apart.
local _, ns = ...
local R = ns.Rules

local NONE = {}

-- True for a listed magic item whose copies stack.
function ns.MagicStacks(name)
    local known = R.ITEMS[name]
    return known ~= nil and known.rarity ~= nil and R.CONSUMABLES[name] == true and not known.attune
end

-- True when the entry is still what the catalogue (or its make) says, as far as
-- can be told. An entry made since edits are recorded says so itself (item.edited);
-- an older one is compared with the catalogue.
function ns.ItemUntouched(item)
    if item.edited or item.attuned or item.scribed then return false end
    if item.tracked then return true end
    local known = R.ITEMS[item.name]
    return known ~= nil and item.desc == (known.desc or "") and item.cost == (known.cost or 0) and item.weight == (known.weight or 0)
        and item.rarity == (known.rarity or "") and #item.effects == #(known.effects or NONE)
end

-- The entry another one of `name` goes onto, or nil when it gets an entry of its
-- own. `variant` is the make of a magic piece of ammunition (Data/ItemVariants.lua).
function ns.StackFor(items, name, variant)
    local magic = ns.MagicStacks(name) or (variant ~= nil and variant.stacks == true)
    for _, item in ipairs(items) do
        if item.name == name and (item.variant or "") == (variant and variant.key or "") then
            if not item.magic and not variant then return item end
            if magic and item.magic and ns.ItemUntouched(item) then return item end
        end
    end
end

-- Puts untouched copies of a stacking magic item that are separate entries (from
-- before they stacked) together in the first of them. Part of the items' upkeep.
function ns.MergeStacks(sheet)
    local first, joined = {}, {}
    for _, item in ipairs(sheet.items) do
        local variant = R.ITEM_VARIANT[item.variant or ""]
        local stacks = item.magic and item.name ~= "" and (variant and variant.stacks or (not variant and ns.MagicStacks(item.name)))
        if stacks and ns.ItemUntouched(item) then
            local key = item.name .. "\n" .. (item.variant or "")
            local keep = first[key]
            if keep then
                keep.qty, keep.equipped = math.min(9999, keep.qty + item.qty), keep.equipped or item.equipped
                joined[item] = true
            else
                first[key] = item
            end
        end
    end
    for index = #sheet.items, 1, -1 do
        if joined[sheet.items[index]] then table.remove(sheet.items, index) end
    end
end
