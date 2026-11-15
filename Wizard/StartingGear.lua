-- The two shortcuts above the starting closet: take the fixed set of gear the class
-- offers, or the background's (Data/StartingGear.lua). A set's items go into the closet
-- and the starting gold becomes what is left over with it. The closet stays free for
-- picking by hand. draft.gear[half] remembers what a button put there, so taking a set
-- again (after another class was chosen, say) swaps it instead of piling up. What a set
-- leaves to choose is picked in Wizard/GearChoices.lua and kept in the same record.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard

local HALVES = { class = "class", background = "background" }

-- The set a half offers the draft right now and what identifies it, or nil.
local function Offered(half)
    local draft = W.draft
    if half == "class" then
        local class = R.CLASSES[draft.class]
        local sets = class and R.CLASS_GEAR[class.base]
        local index = sets and sets[draft.gearSet or 1] and (draft.gearSet or 1) or 1
        return sets and sets[index], draft.class .. ":" .. index
    end
    return R.BACKGROUND_GEAR[draft.background], draft.background
end

-- What was taken for a half, if it is still the set on offer.
local function Taken(half)
    local record = W.draft.gear and W.draft.gear[half]
    local _, key = Offered(half)
    return record and record.key == key and record or nil
end

-- The record of a half's set that was taken and the set itself, or nil.
function W.GearTaken(half)
    local record = Taken(half)
    if record then return record, (Offered(half)) end
end

-- Gold to start with: what is left over with a set that was taken, and for a half
-- whose set wasn't, the gold it gives instead.
local function GoldParts()
    local class = R.CLASSES[W.draft.class]
    local fromClass, fromBackground = Taken("class"), Taken("background")
    return fromClass and fromClass.gold or (class and R.START_GOLD[class.base] or 0),
        fromBackground and fromBackground.gold or R.BACKGROUND_GOLD
end

local function GoldLine()
    local class, background = GoldParts()
    W.draft.gold = class + background
    return ("Your starting gold is now %s%d gp|r: %d gp %s and %d gp %s."):format(Opt.GOLD, class + background,
        class, Taken("class") and "left over with your class's gear" or "from your class in place of its gear",
        background, Taken("background") and "left over with your background's gear" or "from your background in place of its gear")
end

-- Puts back what a half's button took earlier.
local function PutBack(half)
    local record = W.draft.gear[half]
    if not record then return end
    for name, count in pairs(record.items) do W.TakeItem(name, -count) end
    for _, name in pairs(record.picks or {}) do W.TakeItem(name, -1) end -- what was chosen with it
    W.draft.gear[half] = nil
end

-- Puts back a set that is no longer the one on offer, because another class,
-- background or set was chosen since: its gear is not this character's, and that half
-- then gives its gold in place of gear. True when something went back.
function W.DropStaleGear()
    local draft, dropped = W.draft, false
    for half in pairs(HALVES) do
        if draft.gear and draft.gear[half] and not Taken(half) then
            PutBack(half)
            dropped = true
        end
    end
    if dropped then
        draft.gearNote = "The starting gear you took earlier went back with the choice it belonged to. " .. GoldLine()
        W.ClosetChanged()
    end
    return dropped
end

-- Takes the set a half offers: its items into the closet, armor and shield put on.
function W.TakeGear(half)
    local draft = W.draft
    draft.gear = draft.gear or {}
    W.DropStaleGear() -- or the other half's old set would stay next to its full gold
    local set, key = Offered(half)
    if not set then return end
    PutBack(half)
    local list, items = R.GearList(set), {}
    for _, entry in ipairs(list) do
        W.TakeItem(entry.name, entry.count)
        items[entry.name] = entry.count
        if R.ARMOR_ITEMS[entry.name] or entry.name == R.SHIELD_ITEM then W.WearItem(entry.name, true) end
    end
    draft.gear[half] = { key = key, items = items, gold = set.gold, picks = {} }
    local lines = { ("%sAdded from your %s:|r %s, and %d gp."):format(Opt.GREEN, HALVES[half], R.GearText(list), set.gold) }
    if set.note then lines[#lines + 1] = set.note end
    lines[#lines + 1] = GoldLine()
    lines[#lines + 1] = "Armor and a shield are put on; open the closet to ready your weapons."
    draft.gearNote = table.concat(lines, "\n")
    W.ClosetChanged()
end

-- "Put everything back" emptied the closet: the sets are gone with it, so the gold
-- goes back to what class and background give in place of gear.
function W.GearCleared()
    local draft = W.draft
    if not draft.gear or next(draft.gear) == nil then return end
    draft.gear = {}
    draft.gearNote = "The starting gear went back with everything else. " .. GoldLine()
end

-- What a button would add, for its tooltip.
local function Preview(half)
    local set = Offered(half)
    if not set then return ("Choose a %s first."):format(HALVES[half]) end
    local text = ("Puts in the closet: %s. Sets your gold to the %d gp left over with it, next to what the other half gives."):format(
        R.GearText(R.GearList(set)), set.gold)
    local open = W.GearChoiceText(set)
    if open then text = text .. ("\n\nYou then choose %s, which goes in with it."):format(open) end
    return text .. "\n\nWhat you already took by hand stays. Taking the set again after a change swaps the old set for the new one."
end

local function Button(half, order)
    return {
        type = "execute", order = order, width = 1.5, desc = function() return Preview(half) end,
        name = function() return Taken(half) and ("Took my %s's starting gear"):format(HALVES[half]) or ("Take my %s's starting gear"):format(HALVES[half]) end,
        disabled = function() return Offered(half) == nil or Taken(half) ~= nil end,
        func = function() W.TakeGear(half) end,
    }
end

-- Adds the shortcuts to the options of the wizard's last page, above the closet button.
function W.AddGearArgs(args)
    args.gearHelp = {
        type = "description", order = 2.11, fontSize = "medium",
        name = "Your class and your background each offer a ready set of gear with some gold left over. Take either or both here, or skip them, keep the gold they give instead, and pick everything yourself.\n",
    }
    args.gearSet = {
        type = "select", order = 2.12, width = 1.8, name = "Which set from your class",
        desc = "Your class offers more than one set of gear. Choose one, then take it.",
        hidden = function()
            local class = R.CLASSES[W.draft.class]
            return not (class and R.CLASS_GEAR[class.base] and #R.CLASS_GEAR[class.base] > 1)
        end,
        values = function()
            local values, class = {}, R.CLASSES[W.draft.class]
            for index, set in ipairs(class and R.CLASS_GEAR[class.base] or {}) do values[index] = set.label or ("Set " .. index) end
            return values
        end,
        get = function() return W.draft.gearSet or 1 end,
        set = function(_, value)
            W.draft.gearSet = value
            W.DropStaleGear() -- the other set, if it was taken, goes back
        end,
    }
    args.takeClassGear = Button("class", 2.13)
    args.takeBackgroundGear = Button("background", 2.14)
    args.gearNote = {
        type = "description", order = 2.15, fontSize = "medium",
        hidden = function() return (W.draft.gearNote or "") == "" end,
        name = function() return (W.draft.gearNote or "") .. W.GearOpenNote() .. "\n" end,
    }
    W.AddGearChoiceArgs(args) -- what the taken sets leave to choose (Wizard/GearChoices.lua)
end
