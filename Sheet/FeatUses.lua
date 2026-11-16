-- Puts what feats give to click on the sheet (data in Data/FeatUses.lua): an ability
-- marked auto = "featuse:<name>" for each entry while a passive named like the feat is
-- on the sheet, a bar for its uses, and the passive it switches on, marked
-- "featuse:<name>:on".
-- Uses that come back on initiative or only after several long rests are handled
-- here too; Actions/Rest.lua and Actions/Dice.lua call in.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local PREFIX = "featuse:"
local NONE = {}

-- The entries of the feats the character has, as { entry, ... }, in the data's order
-- of feats by name.
local function Entries(sheet)
    local owned, list = {}, {}
    for _, passive in ipairs(sheet.passives or NONE) do
        if R.FEAT_USES[passive.name or ""] then owned[passive.name] = true end
    end
    local names = {}
    for name in pairs(owned) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do
        for _, entry in ipairs(R.FEAT_USES[name]) do list[#list + 1] = entry end
    end
    return list
end

-- Bars for the uses, in the same form as class `pools`.
function ns.FeatPools(sheet)
    local pools = {}
    for _, entry in ipairs(Entries(sheet)) do
        if entry.uses and not sheet.dismissed[PREFIX .. entry.name] then
            local pool = { name = entry.name, from = 1, short = entry.short }
            if entry.uses == "PROF" then pool.prof = true else pool.steps = { { 1, entry.uses } } end
            pools[#pools + 1] = pool
        end
    end
    return pools
end

local function FindAuto(list, key)
    for index, item in ipairs(list) do
        if item.auto == key then return item, index end
    end
end

-- Sheet upkeep: the abilities and passives of the feats the character has, and none
-- of those it no longer has.
function ns.ApplyFeatUses(sheet)
    local wanted, keep = {}, {}
    for _, entry in ipairs(Entries(sheet)) do
        local key = PREFIX .. entry.name
        if not sheet.dismissed[key] then
            wanted[key], keep[key] = entry, true
            if entry.passive then keep[key .. ":on"] = true end
        end
    end
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for index = #list, 1, -1 do
            local auto = list[index].auto or ""
            if auto:find("^" .. PREFIX) and not keep[auto] then table.remove(list, index) end
        end
    end
    for key, entry in pairs(wanted) do
        local ability = FindAuto(sheet.abilities, key)
        if not ability then
            ability = { name = entry.name, auto = key }
            sheet.abilities[#sheet.abilities + 1] = ability
        end
        local actions = entry.actions
        if type(actions) == "function" then actions = actions(sheet.characterLevel or sheet.level or 1) end
        ability.actions = CopyTable(actions or NONE)
        if entry.uses then table.insert(ability.actions, 1, ns.FeatureKit.Spend(entry.name)) end
        ability.desc = type(entry.desc) == "function" and entry.desc(sheet) or entry.desc
        if entry.passive then
            local passive = FindAuto(sheet.passives, key .. ":on")
            if not passive then
                passive = { auto = key .. ":on", enabled = false }
                sheet.passives[#sheet.passives + 1] = passive
            end
            passive.name, passive.desc = entry.passive.name, entry.passive.desc
            passive.effects = CopyTable(entry.passive.effects or NONE)
        end
    end
end

---------------------------------------------------------------------------
-- Uses that come back in their own way
---------------------------------------------------------------------------
-- Rolling initiative gives back the uses that say so (Boon of Fate).
function RPSheet:RegainOnInitiative()
    for _, entry in ipairs(Entries(self:Sheet())) do
        local tracker = entry.initiative and self:FindTracker(entry.name)
        if tracker and tracker.get() < tracker.max then
            tracker.set(tracker.max)
            self:Print(("Rolling initiative gives you back %s."):format(entry.name))
        end
    end
end

-- The names of the uses that wait several long rests and are spent now, taken before
-- a long rest refills every bar.
function RPSheet:WaitingUses()
    local spent = {}
    for _, entry in ipairs(Entries(self:Sheet())) do
        local tracker = entry.waitRests and self:FindTracker(entry.name)
        if tracker and tracker.get() < tracker.max then spent[#spent + 1] = entry end
    end
    return spent
end

-- After the long rest: a use that waits takes its die's roll in long rests to come
-- back (state.restWait[<name>] = rests still to go). The first rest rolls the die and
-- counts as one of them.
function RPSheet:HoldWaitingUses(spent)
    local state = self:State()
    if type(state.restWait) ~= "table" then state.restWait = {} end
    for _, entry in ipairs(spent) do
        local name, tracker = entry.name, self:FindTracker(entry.name)
        local function Hold(left)
            if left > 0 then
                state.restWait[name] = left
                if tracker then tracker.set(0) end
                self:Print(("%s comes back after %d more long %s."):format(name, left, left == 1 and "rest" or "rests"))
            else
                state.restWait[name] = nil
            end
            self:PopulateSoon()
        end
        if type(state.restWait[name]) == "number" then
            Hold(state.restWait[name] - 1)
        else
            self:Roll(entry.waitRests, function(rests)
                self:Announce(("rolls 1d%d for %s: %d long %s"):format(entry.waitRests, ns.Mark(name), rests, rests == 1 and "rest" or "rests"))
                Hold(rests - 1)
            end)
        end
    end
end
