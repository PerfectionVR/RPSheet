-- Customize > Inventory: making a magic variant of a plain suit of armor, shield or
-- weapon (Data/ItemVariants.lua). Pick the variant and the plain item; the new item
-- is named after both, counts as the plain one, and carries the variant's bonus,
-- rarity, attunement and price (Sheet/ItemVariants.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt

local picked, plain = "", "" -- the variant and the plain item chosen in the dropdowns

local function Variant() return R.ITEM_VARIANT[picked] end

-- What the two dropdowns would make, in a line or two.
local function Preview()
    local item = ns.NewVariantItem(picked, plain)
    if not item then return "A plain item in a rare metal, with a magic bonus or with a ward against one kind of damage. Pick the variant, then the item it is made of.\n" end
    return ("%s%s|r: %s%s%s. %s\n"):format(R.RARITY_COLORS[item.rarity] or "", item.name, item.rarity:lower(),
        item.attune and ", requires attunement" or "", item.cost > 0 and (", worth " .. ns.CoinText(item.cost)) or "", item.desc)
end

function Opt.VariantArgs(args, order)
    args.variantHeader = { type = "header", order = order, name = "Make a magic variant" }
    args.variantKind = {
        type = "select", order = order + 0.01, name = "Variant", width = 1.3,
        desc = "Armor and weapons that exist in a magic make of any plain kind: a magic bonus, adamantine, mithral, silver, or armor that resists one kind of damage.",
        values = function()
            local values = {}
            for _, key in ipairs(R.ITEM_VARIANTS) do values[key] = R.ITEM_VARIANT[key].title end
            return values
        end,
        sorting = R.ITEM_VARIANTS,
        get = function() return picked end,
        set = function(_, value)
            picked = value
            -- A plain item the new variant can't be made of is forgotten.
            if not (Variant() and R.VariantFits(Variant(), plain)) then plain = "" end
        end,
    }
    args.variantPlain = {
        type = "select", order = order + 0.02, name = "Made of", width = 1.3,
        desc = "The plain item it is. Only the ones this variant exists of are listed.",
        disabled = function() return not Variant() end,
        values = function()
            local values = {}
            for _, name in ipairs(Variant() and ns.VariantBases(Variant()) or {}) do values[name] = name end
            return values
        end,
        sorting = function() return Variant() and ns.VariantBases(Variant()) or {} end,
        get = function() return plain end,
        set = function(_, value) plain = value end,
    }
    args.variantAdd = {
        type = "execute", order = order + 0.03, name = "Add it",
        desc = "Puts the item in your inventory. Equip it like the plain item; what the sheet can count of its magic counts while it is equipped, and attuned when it asks for that.",
        disabled = function() return ns.NewVariantItem(picked, plain) == nil end,
        func = function()
            RPSheet:AddVariantItem(picked, plain)
            ns.RebuildOptions() -- the new item has a page
            Opt.Changed()
        end,
    }
    args.variantPreview = { type = "description", order = order + 0.04, name = Preview }
end
