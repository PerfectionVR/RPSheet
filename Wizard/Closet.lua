-- The starting closet on the wizard's last page: what was taken so far, the button
-- that opens the closet (the item browser, Wizard/ClosetBrowser.lua), which of the
-- taken things are worn and wielded, and turning the picks into the new character's
-- inventory. draft.closet is item name -> how many; draft.worn is item name -> true.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard

local GOLD, RED = Opt.GOLD, Opt.RED

-- The taken names of one kind of item, in its order.
function W.Taken(kind)
    local names = {}
    for _, name in ipairs(R.ITEM_NAMES[kind]) do
        if (W.draft.closet[name] or 0) > 0 then names[#names + 1] = name end
    end
    return names
end

-- Worth in copper and weight in pounds of everything taken, and what can be carried.
function W.ClosetTotals()
    local draft, cost, weight = W.draft, 0, 0
    for name, count in pairs(draft.closet) do
        cost, weight = cost + R.ITEMS[name].cost * count, weight + R.ITEMS[name].weight * count
    end
    local capacity = ((draft.base.STR or 10) + (draft.bonus.STR or 0)) * (R.CARRY_PER_STRENGTH[draft.size] or R.CARRY_PER_STRENGTH.M)
    return cost, weight, capacity
end

-- Takes one more of an item (`change` 1) or puts one back (-1).
function W.TakeItem(name, change)
    local closet = W.draft.closet
    local count = math.max(0, (closet[name] or 0) + change)
    closet[name] = count > 0 and count or nil
    if count == 0 then W.draft.worn[name] = nil end
end

-- Equips a taken item or puts it away. One suit of armor at a time.
function W.WearItem(name, on)
    local worn = W.draft.worn
    if on and R.ARMOR_ITEMS[name] then
        for other in pairs(R.ARMOR_ITEMS) do worn[other] = nil end
    end
    worn[name] = on or nil
end

-- What was taken so far, by kind, with its worth and weight.
local function Summary()
    local lines = {}
    for _, kind in ipairs(R.CLOSET_KINDS) do
        local parts = {}
        for _, name in ipairs(W.Taken(kind)) do
            local count = W.draft.closet[name]
            parts[#parts + 1] = (count > 1 and ("%s x%d"):format(name, count) or name) .. (W.draft.worn[name] and " (equipped)" or "")
        end
        if #parts > 0 then lines[#lines + 1] = ("%s%s|r: %s"):format(GOLD, kind, table.concat(parts, ", ")) end
    end
    if #lines == 0 then return "Nothing taken yet.\n" end
    local cost, weight, capacity = W.ClosetTotals()
    lines[#lines + 1] = ("Worth %s%s|r, weighing %s%s lb.|r of the %d lb. you can carry."):format(
        GOLD, ns.CoinText(cost), weight > capacity and RED or GOLD, weight, capacity)
    return table.concat(lines, "\n") .. "\n"
end

-- Adds the closet to the options of the wizard's last page.
function W.AddClosetArgs(args)
    args.closetHeader = { type = "header", order = 2, name = "Starting gear" }
    args.closetHelp = {
        type = "description", order = 2.1, fontSize = "medium",
        name = "Take what your character owns at the start. The closet shows every weapon, suit of armor and piece of gear as a block with what it does; take as many as you like and equip what you have on and at hand. Everything taken goes into your inventory.\n",
    }
    W.AddGearArgs(args) -- the ready sets of a class and a background (Wizard/StartingGear.lua)
    args.openCloset = {
        type = "execute", order = 2.2, name = "Open the closet", width = "double",
        func = function() W.OpenCloset() end,
    }
    args.empty = {
        type = "execute", order = 2.3, name = "Put everything back",
        disabled = function() return next(W.draft.closet) == nil end,
        func = function()
            W.draft.closet, W.draft.worn = {}, {}
            W.GearCleared() -- a class's or background's set went back too (Wizard/StartingGear.lua)
            W.ClosetChanged()
        end,
    }
    args.taken = { type = "description", order = 2.5, fontSize = "medium", name = Summary }
end

-- Puts the closet's picks in the new sheet's inventory and equips the worn ones.
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
        for _, name in ipairs(W.Taken(kind)) do
            local item
            for _, other in ipairs(sheet.items) do
                if other.name == name and not other.magic then item = other end
            end
            if item then
                item.qty = item.qty + draft.closet[name]
            else
                item = ns.NewItem(name)
                item.qty = draft.closet[name]
                sheet.items[#sheet.items + 1] = item
            end
            if draft.worn[name] then ns.EquipItem(sheet, item, true, Modifier, CanMaster) end
        end
    end
end
