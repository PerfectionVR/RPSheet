-- The starting closet on the wizard's last page: drawers of plain gear to take as
-- many things from as you like, which of them you wear and wield, and turning the
-- picks into the new character's inventory.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard

local GOLD, RED = Opt.GOLD, Opt.RED
local drawer = R.CLOSET_KINDS[1] -- the drawer that is open

local function Untrained(text)
    return (" %s(%s)|r"):format(RED, text)
end

-- "Longsword - 1d8 slashing, versatile (1d10), 15 gp"
local function Label(name)
    local known, class = R.ITEMS[name], W.draft.class
    local text = R.ItemSummary(known.cost, known.weight)
    local armor = R.ARMOR_ITEMS[name]
    if R.WEAPONS[name] then
        text = R.WeaponSummary(name) .. ", " .. ns.CoinText(known.cost)
        if not ns.WeaponProficient(class, name) then text = text .. Untrained("not proficient") end
    elseif armor then
        local kind = ns.ArmorKind(armor)
        text = ("AC %d, %s, %s"):format(R.ARMOR[armor].ac, kind, text)
        if not ns.ArmorTraining(class)[kind] then text = text .. Untrained("not trained") end
    elseif name == R.SHIELD_ITEM then
        text = ("+%d AC, %s"):format(R.SHIELD_AC, text)
        if not ns.ArmorTraining(class).shield then text = text .. Untrained("not trained") end
    end
    return text ~= "" and ("%s - %s"):format(name, text) or name
end

-- The picked names of one drawer, in its order.
local function Picked(kind)
    local names = {}
    for _, name in ipairs(R.ITEM_NAMES[kind]) do
        if W.draft.closet[name] then names[#names + 1] = name end
    end
    return names
end

-- What was taken so far, with its worth and weight.
local function Taken()
    local draft, lines, cost, weight = W.draft, {}, 0, 0
    for _, kind in ipairs(R.CLOSET_KINDS) do
        local names = Picked(kind)
        for _, name in ipairs(names) do
            cost, weight = cost + R.ITEMS[name].cost, weight + R.ITEMS[name].weight
        end
        if #names > 0 then lines[#lines + 1] = ("%s%s|r: %s"):format(GOLD, kind, table.concat(names, ", ")) end
    end
    if #lines == 0 then return "Nothing taken yet.\n" end
    local capacity = ((draft.base.STR or 10) + (draft.bonus.STR or 0)) * (R.CARRY_PER_STRENGTH[draft.size] or R.CARRY_PER_STRENGTH.M)
    lines[#lines + 1] = ("Worth %s%s|r, weighing %s%s lb.|r of the %d lb. you can carry."):format(
        GOLD, ns.CoinText(cost), weight > capacity and RED or GOLD, weight, capacity)
    return table.concat(lines, "\n") .. "\n"
end

-- The taken things that can be worn or wielded, in closet order.
local function Wearable()
    local names = {}
    for _, kind in ipairs(R.CLOSET_KINDS) do
        for _, name in ipairs(Picked(kind)) do
            if ns.ItemSlot({ name = name }) then names[#names + 1] = name end
        end
    end
    return names
end

-- Adds the closet to the options of the wizard's last page.
function W.AddClosetArgs(args)
    args.closetHeader = { type = "header", order = 2, name = "Starting gear" }
    args.closetHelp = {
        type = "description", order = 2.1, fontSize = "medium",
        name = "Take what your character owns at the start: open a drawer and tick as many things as you like. Everything you take goes into your inventory, where more can be added or bought later.\n",
    }
    args.drawer = {
        type = "select", order = 2.2, name = "Drawer",
        values = function() return (Opt.ListMap(R.CLOSET_KINDS)) end,
        sorting = R.CLOSET_KINDS,
        get = function() return drawer end,
        set = function(_, value) drawer = value end,
    }
    args.empty = {
        type = "execute", order = 2.3, name = "Put everything back",
        disabled = function() return next(W.draft.closet) == nil end,
        func = function() W.draft.closet, W.draft.worn = {}, {} end,
    }
    args.closet = {
        type = "multiselect", order = 2.4, width = "double",
        name = function() return drawer end,
        desc = "Tick it to take it. Weapons and armor your class has no training with are marked: you can own them, but using them works against you.",
        values = function()
            local values = {}
            for _, name in ipairs(R.ITEM_NAMES[drawer]) do values[name] = Label(name) end
            return values
        end,
        get = function(_, name) return W.draft.closet[name] == true end,
        set = function(_, name, taken)
            W.draft.closet[name] = taken or nil
            if not taken then W.draft.worn[name] = nil end
        end,
    }
    args.taken = { type = "description", order = 2.5, fontSize = "medium", name = Taken }
    args.wornHeader = { type = "header", order = 3, name = "Worn and wielded" }
    args.wornHelp = {
        type = "description", order = 3.1, fontSize = "medium",
        name = function()
            if #Wearable() == 0 then return "Take a weapon, armor or a shield from the closet to equip it here.\n" end
            return "Tick what you have on and at hand. Armor and a shield count for your Armor Class, and ticked weapons are the ones on your sheet. The rest stays in your pack; you equip and put away from the sheet's Inventory at any time.\n"
        end,
    }
    args.worn = {
        type = "multiselect", order = 3.2, name = "Equipped",
        hidden = function() return #Wearable() == 0 end,
        values = function() return (Opt.ListMap(Wearable())) end,
        get = function(_, name) return W.draft.worn[name] == true end,
        set = function(_, name, on)
            -- One suit of armor at a time.
            if on and R.ARMOR_ITEMS[name] then
                for other in pairs(R.ARMOR_ITEMS) do W.draft.worn[other] = nil end
            end
            W.draft.worn[name] = on or nil
        end,
    }
end

-- Puts the closet's picks in the new sheet's inventory and equips the ticked ones.
function W.FillInventory(sheet)
    local draft = W.draft
    local function Modifier(stat)
        return math.floor(((draft.base[stat] or 10) + (draft.bonus[stat] or 0) - 10) / 2)
    end
    -- A class with Weapon Mastery sets the mastery of as many weapons as it may.
    local limit = ns.FeatureKit.AtLevel(draft.level, R.MASTERY_LIMITS[R.CLASSES[draft.class].base] or {}) or 0
    local function CanMaster()
        local used = 0
        for _, weapon in ipairs(sheet.weapons) do
            if weapon.mastery ~= "" then used = used + 1 end
        end
        return used < limit
    end
    ns.MatchWorn(sheet) -- carried-over armor isn't on the new character yet
    for _, kind in ipairs(R.CLOSET_KINDS) do
        for _, name in ipairs(Picked(kind)) do
            local item
            for _, other in ipairs(sheet.items) do
                if other.name == name and not other.magic then item = other end
            end
            if item then
                item.qty = item.qty + 1
            else
                item = ns.NewItem(name)
                sheet.items[#sheet.items + 1] = item
            end
            if draft.worn[name] then ns.EquipItem(sheet, item, true, Modifier, CanMaster) end
        end
    end
end
