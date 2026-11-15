-- Shows how a number on the sheet is worked out, as a line only the player sees.
-- e.g. "Rapier, to hit +5: Dexterity +3, proficiency +2."
-- Each Explain function mirrors the calculation next to it in Sheet/Derived.lua,
-- Sheet/Combat.lua or Actions/Weapons.lua: change them together.
-- This file: what the explanations share (Sheet/Explain*.lua).
local _, ns = ...
local R = ns.Rules
local Util = ns.Util

-- Explanations are printed for the player, or collected when another player asked
-- (see RPSheet:ExplainTerm).
local function Out(self, text)
    if self.explainCapture then
        self.explainCapture[#self.explainCapture + 1] = text
    else
        self:Print(text)
    end
end

-- A list of { label, value } that add up to a total.
local function Add(parts, label, value)
    if value and value ~= 0 then parts[#parts + 1] = { label, value } end
end

-- What switched-on passives and exhaustion add to `target` (see RPSheet:Bonus).
local D20_TARGETS = { ATTACK = true, SPELLATK = true, SAVES = true, CHECKS = true, INIT = true }
local function AddBonuses(self, parts, target)
    local exhaustion = self:State().exhaustion or 0
    if D20_TARGETS[target] then
        Add(parts, "exhaustion", -R.EXHAUSTION_D20 * exhaustion)
    elseif target == "SPEED" then
        Add(parts, "exhaustion", -R.EXHAUSTION_SPEED * exhaustion)
    end
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and passive.name ~= "" and not self:PassiveBlocked(passive) then
            for _, effect in ipairs(passive.effects) do
                if effect.target == target and ns.EffectMode(effect) == "" then Add(parts, passive.name, self:EffectValue(effect)) end
            end
        end
    end
    for _, item in ipairs(self:Sheet().items or {}) do
        if self:ItemActive(item) then
            for _, effect in ipairs(item.effects) do
                if effect.target == target and ns.EffectMode(effect) == "" then Add(parts, item.name, self:EffectValue(effect)) end
            end
        end
    end
end

-- "Dexterity +3, proficiency +2", or "nothing added" for an empty list.
local function Join(parts)
    local texts = {}
    for _, part in ipairs(parts) do texts[#texts + 1] = ("%s %s"):format(part[1], Util.Signed(part[2])) end
    return #texts > 0 and table.concat(texts, ", ") or "nothing added"
end

local function Total(parts)
    local total = 0
    for _, part in ipairs(parts) do total = total + part[2] end
    return total
end

-- The ability modifier always shows, even at +0. A score that an item holds up says
-- so: "Strength (19 from Gauntlets of Ogre Power)".
local function Ability(self, parts, stat)
    local label = R.STAT_NAMES[stat] or "no ability"
    local from, score
    if R.STAT_NAMES[stat] then from, score = self:ScoreSetBy(stat) end
    if from then label = ("%s (%d from %s)"):format(label, score, from) end
    parts[#parts + 1] = { label, self:Mod(stat) }
end

local function Show(self, what, parts, prefix)
    Out(self, ("%s %s%s|r: %s%s."):format(what, "|cffffd100", Util.Signed(Total(parts)), prefix or "", Join(parts)))
end

ns.ExplainKit = { Out = Out, Add = Add, AddBonuses = AddBonuses, Join = Join, Total = Total, Ability = Ability, Show = Show }
