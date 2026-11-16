-- Feats that change dice once they are rolled: rerolling low dice (Healer, Tavern
-- Brawler), counting a 1 as a 2 (Elemental Adept, Clearcasting, Fists of Fury). A
-- reroll must be kept, so the sheet always takes it. Used by spells
-- (Actions/Spells.lua), weapon attacks (Sheet/WeaponFeats.lua) and abilities whose
-- dice say so (`reroll`, `lowest` on a DICE step).
local _, ns = ...
local RPSheet = ns.addon

local NONE = {}

-- Rerolls every die showing `upTo` or less once, then raises the dice below `lowest`.
-- Changes `rolls` in place and calls done(notes), notes being a list of short texts.
function RPSheet:AdjustRolls(rolls, sides, upTo, lowest, from, done)
    local notes, at = {}, 0
    local function Raise()
        local raised = 0
        for index, roll in ipairs(rolls) do
            if lowest and roll < lowest then rolls[index], raised = lowest, raised + 1 end
        end
        if raised > 0 then notes[#notes + 1] = ("%d low %s counted as %d, %s"):format(raised, raised == 1 and "die" or "dice", lowest, from.lowest or "") end
        done(notes)
    end
    local function Next()
        at = at + 1
        if at > #rolls then return Raise() end
        if not upTo or rolls[at] > upTo then return Next() end
        local old = rolls[at]
        self:Roll(sides, function(value)
            rolls[at] = value
            notes[#notes + 1] = ("a %d rerolled as %d, %s"):format(old, value, from.reroll or "")
            Next()
        end)
    end
    Next()
end

-- The damage types the character's Elemental Adept feats were taken for, lower case.
local function AdeptTypes(sheet)
    local types = {}
    for _, instance in ipairs(ns.FeatInstances(sheet)) do
        ns.EachFeatPick(sheet.featChoices, instance, "adept", function(value) types[tostring(value):lower()] = true end)
    end
    return types
end

-- For a spell's dice of this kind ("DAMAGE", "HEALING", ...) and damage type: what
-- is rerolled, what counts as at least 2, and the feats' names for the notes.
function RPSheet:SpellDiceRules(kind, damage)
    local upTo, lowest, from = nil, nil, {}
    if (kind == "HEALING" or kind == "SELFHEAL") and self:HasPassive("Healer") then
        upTo, from.reroll = 1, "Healer"
    end
    if kind == "DAMAGE" and damage then
        if AdeptTypes(self:Sheet())[damage] then lowest, from.lowest = 2, "Elemental Adept" end
        if damage == "force" and self:HasPassive("Clearcasting") then lowest, from.lowest = 2, "Clearcasting" end
    end
    return upTo, lowest, from
end

-- What a weapon attack's damage dice get: Fists of Fury counts a 1 as a 2 with a light
-- weapon; with `unarmed`, Tavern Brawler rerolls 1s as well.
function RPSheet:StrikeDiceRules(light, unarmed)
    local upTo, lowest, from = nil, nil, {}
    if unarmed and self:HasPassive("Tavern Brawler") then upTo, from.reroll = 1, "Tavern Brawler" end
    if (light or unarmed) and self:HasPassive("Fists of Fury") then lowest, from.lowest = 2, "Fists of Fury" end
    return upTo, lowest, from
end

-- The notes joined for an announcement: " [a 1 rerolled as 5, Healer]", or "".
function ns.DiceNotes(notes)
    if #(notes or NONE) == 0 then return "" end
    return " [" .. table.concat(notes, "; ") .. "]"
end
