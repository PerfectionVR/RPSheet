-- The choices made for the feats on the sheet (what each feat asks is in
-- Data/FeatChoices.lua). Every feat the character has is an "instance" with an id of
-- its own, so the same feat taken twice keeps its choices apart:
--   sheet.featChoices[<id>] = { feat = <feat name>, picks = { [<choice key>] = { [<slot>] = <value> } } }
-- The id is the passive's `auto` key ("level:4", "trait:Versatile"), or "own:<name>"
-- for a feat without one (the background's). The choosing happens in the level dialog
-- (Options/FeatChoices.lua); what a pick does is in Sheet/FeatGrants.lua.
local _, ns = ...
local R = ns.Rules

local NONE = {}

-- The feat a passive's name stands for, and the choice its name settles:
-- "Magic Initiate (Cleric)" is Magic Initiate with the Cleric list.
function ns.FeatByName(name)
    local feat = R.FEATS[name]
    if feat then return feat end
    local base, value = (name or ""):match("^(.-) %((.+)%)$")
    feat = base and R.FEATS[base]
    if feat and feat.named then return feat, { [feat.named] = value } end
end

local function Asks(feat)
    return feat ~= nil and (feat.choices ~= nil or feat.spells ~= nil or feat.allSkills == true)
end

-- The feats on the sheet that ask or give something here, as
-- { id =, name =, feat =, fixed =, passive = }. `override` = { id =, name = } stands in
-- for the feat of one level while the level dialog is deciding it.
function ns.FeatInstances(sheet, override)
    local list, plain, replaced = {}, {}, false
    for _, passive in ipairs(sheet.passives or NONE) do
        local auto, name, id = passive.auto or "", passive.name or "", nil
        if auto == "" then
            plain[name] = (plain[name] or 0) + 1
            id = plain[name] == 1 and ("own:" .. name) or ("own:%s:%d"):format(name, plain[name])
        elseif auto:find("^level:") or auto:find("^trait:") then
            id = auto
            if override and override.id == auto then name, replaced = override.name, true end
        end
        local feat, fixed = ns.FeatByName(name)
        if id and Asks(feat) then
            list[#list + 1] = { id = id, name = feat.name, feat = feat, fixed = fixed, passive = passive }
        end
    end
    if override and not replaced then
        local feat, fixed = ns.FeatByName(override.name)
        if Asks(feat) then list[#list + 1] = { id = override.id, name = feat.name, feat = feat, fixed = fixed } end
    end
    return list
end

function ns.FeatChoiceCount(choice, level)
    local count = choice.count or 1
    if type(count) == "function" then count = count(level or 1) end
    return count
end

local function Options(choice, picks)
    local from = choice.from
    if type(from) == "function" then from = from(picks) end
    return from or NONE
end

-- The picks stored for one choice of an instance; an empty table if there are none.
local function Picked(store, instance, choice)
    local entry = store[instance.id]
    local picks = type(entry) == "table" and entry.feat == instance.name and type(entry.picks) == "table" and entry.picks or NONE
    return type(picks[choice.key]) == "table" and picks[choice.key] or NONE
end

-- Calls visit(value, choice) for every pick of `kind` made for an instance.
function ns.EachFeatPick(store, instance, kind, visit)
    for _, choice in ipairs(instance.feat.choices or NONE) do
        if choice.kind == kind then
            for _, value in pairs(Picked(store or NONE, instance, choice)) do visit(value, choice) end
        end
    end
end

-- Brings a store in line with the feats the character has: an entry per instance,
-- nothing for feats that are gone, and no pick the rules don't allow (any more).
function ns.NormalizeFeatChoices(store, instances, level)
    local live, taken = {}, {}
    for _, instance in ipairs(instances) do
        live[instance.id] = true
        local entry = store[instance.id]
        if type(entry) ~= "table" or entry.feat ~= instance.name or type(entry.picks) ~= "table" then
            entry = { feat = instance.name, picks = {} }
            store[instance.id] = entry
        end
        local known = {}
        for _, choice in ipairs(instance.feat.choices or NONE) do
            known[choice.key] = true
            local picked = entry.picks[choice.key]
            if type(picked) ~= "table" then
                picked = {}
                entry.picks[choice.key] = picked
            end
            local fixed = instance.fixed and instance.fixed[choice.key]
            if fixed then
                wipe(picked)
                picked[1] = fixed
            end
            local allowed, seen = {}, {}
            for _, value in ipairs(Options(choice, entry.picks)) do allowed[value] = true end
            -- What the same feat picked before can't be picked again where it has to differ.
            local others = choice.distinct and (taken[instance.name .. ":" .. choice.key] or {}) or NONE
            local count = ns.FeatChoiceCount(choice, level)
            for slot, value in pairs(picked) do
                if type(slot) ~= "number" or slot < 1 or slot > count or not allowed[value] or seen[value] or (others[value] and not fixed) then
                    picked[slot] = nil
                else
                    seen[value] = true
                end
            end
            if choice.distinct then
                for value in pairs(seen) do others[value] = true end
                taken[instance.name .. ":" .. choice.key] = others
            end
        end
        for key in pairs(entry.picks) do
            if not known[key] then entry.picks[key] = nil end
        end
    end
    for id in pairs(store) do
        if not live[id] then store[id] = nil end
    end
end

-- One entry per pick still to be shown in the dialog: { instance =, choice =, index =,
-- count =, picked = }. A choice the feat's name settles isn't asked. The store has
-- to be normalized.
function ns.FeatChoiceSlots(store, instances, level)
    local slots = {}
    for _, instance in ipairs(instances) do
        for _, choice in ipairs(instance.feat.choices or NONE) do
            if not (instance.fixed and instance.fixed[choice.key]) then
                local count = ns.FeatChoiceCount(choice, level)
                for index = 1, count do
                    slots[#slots + 1] = { instance = instance, choice = choice, index = index, count = count,
                        picked = store[instance.id].picks[choice.key] }
                end
            end
        end
    end
    return slots
end

-- True if `value` can't go in a slot: it is picked elsewhere, or would give nothing.
local function Blocked(sheet, store, instances, slot, value)
    local choice = slot.choice
    for _, other in ipairs(instances) do
        for _, each in ipairs(other.feat.choices or NONE) do
            local picked = Picked(store, other, each)
            for index, chosen in pairs(picked) do
                if chosen == value and not (picked == slot.picked and index == slot.index) then
                    if picked == slot.picked then return true end
                    if choice.distinct and other.name == slot.instance.name and each.key == choice.key then return true end
                    -- One spell or tool isn't gained twice; a skill is (proficiency, then expertise).
                    if (choice.kind == "spell" or choice.kind == "tool") and each.kind == choice.kind then return true end
                end
            end
        end
        if choice.kind == "spell" then
            for _, given in ipairs(other.feat.spells or NONE) do
                if given.name == value then return true end
            end
        end
    end
    if choice.kind == "tool" then
        return ns.ToolGranted(sheet, value) ~= nil or ns.ToolPicked(sheet, value)
    elseif choice.kind == "skill" then
        -- Already expertise without this feat's help.
        return (sheet.skills[value] or 0) - ((sheet.featGranted or NONE)[value] or 0) >= 2
    end
    return false
end

-- The options a slot's dropdown offers, in the order of the data.
function ns.FeatChoiceValues(sheet, store, instances, slot)
    local values = {}
    for _, value in ipairs(Options(slot.choice, store[slot.instance.id].picks)) do
        if not Blocked(sheet, store, instances, slot, value) then values[#values + 1] = value end
    end
    return values
end

-- How many picks are made and how many the feats ask for, and a line about the
-- first one that is still open (nil when all are made).
function ns.FeatChoiceProgress(store, instances, level)
    local made, total, open = 0, 0, nil
    for _, instance in ipairs(instances) do
        for _, choice in ipairs(instance.feat.choices or NONE) do
            if not (instance.fixed and instance.fixed[choice.key]) then
                local count, picked, chosen = ns.FeatChoiceCount(choice, level), Picked(store, instance, choice), 0
                for index = 1, count do
                    if picked[index] ~= nil then chosen = chosen + 1 end
                end
                made, total = made + chosen, total + count
                if chosen < count and not open then
                    open = ("%s has a choice to make: %s (%d of %d chosen)."):format(instance.name, choice.title:lower(), chosen, count)
                end
            end
        end
    end
    return made, total, open
end

-- True if a feat on the sheet asks for anything.
function ns.HasFeatChoices(sheet)
    local _, total = ns.FeatChoiceProgress(NONE, ns.FeatInstances(sheet), sheet.level)
    return total > 0
end

-- True if a choice of a feat on the sheet hasn't been made.
function ns.OpenFeatChoices(sheet)
    local made, total = ns.FeatChoiceProgress(sheet.featChoices or NONE, ns.FeatInstances(sheet), sheet.level)
    return made ~= total
end

-- A safe copy of choices that came from outside (an import string).
function ns.CleanFeatChoices(source)
    local clean = {}
    if type(source) ~= "table" then return clean end
    for id, entry in pairs(source) do
        if type(id) == "string" and #id <= 80 and not id:find("[|%c]") and type(entry) == "table"
            and type(entry.feat) == "string" and R.FEATS[entry.feat] and type(entry.picks) == "table" then
            local copy = { feat = entry.feat, picks = {} }
            for _, choice in ipairs(R.FEATS[entry.feat].choices or NONE) do
                local picked = {}
                for slot = 1, 6 do
                    local value = type(entry.picks[choice.key]) == "table" and entry.picks[choice.key][slot]
                    if type(value) == "string" and #value <= 60 then picked[slot] = value end
                end
                copy.picks[choice.key] = picked
            end
            clean[id] = copy
        end
    end
    return clean
end
