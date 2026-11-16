-- Feat picks that change when a long rest is finished (a choice marked `rest` in
-- Data/FeatChoices.lua: Weapon Master's kind of weapon, Boon of Energy Resistance's
-- damage types). Like the Weapon Mastery pick of a companion (Sheet/Pet.lua), each is
-- changed once after a rest and then stays until the next one. The sheet keeps what
-- each was when the last long rest ended:
--   state.restPicks[<instance id>/<feat>/<choice key>] = { at = { [slot] = <the pick then> },
--                                                          changed = true once changed }
-- A long rest takes a new note (Actions/Rest.lua). The level dialog, where the picks
-- are made, refuses a second change (ns.FeatChoiceProgress).
local _, ns = ...
local RPSheet = ns.addon

local NONE = {}

-- The picks of one choice: { [slot] = value }.
local function Picks(store, instance, choice)
    local entry = store[instance.id]
    local picks = type(entry) == "table" and entry.feat == instance.name and type(entry.picks) == "table" and entry.picks[choice.key]
    return type(picks) == "table" and picks or NONE
end

-- True when a pick that was made in `before` is another one in `after`. Filling a slot
-- that was still empty is making the pick, not changing it, and a slot emptied (a pick
-- that stopped being allowed) is only asked for again.
local function Changed(before, after)
    for slot, value in pairs(before) do
        if after[slot] ~= nil and after[slot] ~= value then return true end
    end
    return false
end

-- Visits every rest choice of the character's feats with its key in state.restPicks.
local function EachRestChoice(instances, visit)
    for _, instance in ipairs(instances) do
        for _, choice in ipairs(instance.feat.choices or NONE) do
            if choice.rest then visit(instance, choice, ("%s/%s/%s"):format(instance.id, instance.name, choice.key)) end
        end
    end
end

-- The notes, made for the active character's saved picks where there are none yet.
local function Notes(instances)
    local state, sheet = RPSheet:State(), RPSheet:Sheet()
    if type(state.restPicks) ~= "table" then state.restPicks = {} end
    local notes = state.restPicks
    EachRestChoice(instances, function(instance, choice, key)
        local now = Picks(sheet.featChoices or NONE, instance, choice)
        local note = notes[key]
        if type(note) ~= "table" or type(note.at) ~= "table" then
            notes[key] = { at = CopyTable(now) }
        else
            if Changed(note.at, now) then note.changed = true end
            -- A pick made for the first time is what a change is measured from.
            for slot, value in pairs(now) do
                if note.at[slot] == nil then note.at[slot] = value end
            end
        end
    end)
    return notes
end

-- Sheet upkeep, after the feat picks were put on the sheet: notes a change.
function ns.NoteRestPicks(sheet)
    if not RPSheet.db or sheet ~= RPSheet:Sheet() then return end -- (a stand-in, or another character)
    Notes(ns.FeatInstances(sheet))
end

-- A long rest: what the picks are now is what they are changed from next.
function ns.ResetRestPicks()
    RPSheet:State().restPicks = nil
    Notes(ns.FeatInstances(RPSheet:Sheet()))
end

-- Why the picks in `store` (the level dialog's) can't be kept, or nil: a rest choice
-- that differs from the saved one, when it was changed since the last long rest.
function ns.RestPickProblem(store, instances)
    if not RPSheet.db or store == RPSheet:Sheet().featChoices then return end
    local notes, saved, problem = Notes(instances), RPSheet:Sheet().featChoices or NONE, nil
    EachRestChoice(instances, function(instance, choice, key)
        if not problem and notes[key].changed and Changed(Picks(saved, instance, choice), Picks(store, instance, choice)) then
            problem = ("You changed %s's %s since your last long rest: it can change again when you finish the next one."):format(instance.name, choice.title:lower())
        end
    end)
    return problem
end
