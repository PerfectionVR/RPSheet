-- What class features do to the dice an ability rolls (Actions/Abilities.lua):
-- Supreme Healing counts Channel Divinity healing dice at their highest, Wish through
-- Divine Intervention sets how long it stays spent, and the sheet remembers the
-- necrotic damage of a Rune Strike for Runic Power (Actions/RuneFlows.lua).
local _, ns = ...
local RPSheet = ns.addon

-- Abilities whose healing dice can be damage instead: the rule only touches healing,
-- so the highest result is named, not applied.
local HEAL_OR_HARM = { ["Divine Spark"] = true }

local function Sum(rolls, mod)
    local total = mod or 0
    for _, roll in ipairs(rolls) do total = total + roll end
    return total
end

local function SpendsChannel(ability)
    for _, step in ipairs(ability.actions) do
        if step.type == "SPEND" and step.resource == "Channel Divinity" then return true end
    end
    return false
end

-- True if the character has the feature: a passive of that name that a rule put on
-- the sheet (a class, a subclass, a pick), not one added by hand.
function ns.HasFeature(sheet, name)
    for _, passive in ipairs(sheet.passives or {}) do
        if passive.name == name and (passive.auto or "") ~= "" then return true end
    end
    return false
end

-- Called with the rolled dice of a DICE step, before they are applied; may change
-- them. Returns a note for the announcement, or nil.
function RPSheet:AbilityDiceFeatures(ability, action, rolls, mod)
    local notes = {}
    local healing = action.dice == "HEALING" or action.dice == "SELFHEAL"
    if healing and #rolls > 0 and ns.HasFeature(self:Sheet(), "Supreme Healing") and SpendsChannel(ability) then
        if HEAL_OR_HARM[ability.name] then
            notes[#notes + 1] = ("Supreme Healing: heals %d"):format(action.sides * #rolls + mod)
        else
            for index in ipairs(rolls) do rolls[index] = action.sides end
            notes[#notes + 1] = "Supreme Healing: every die at its highest"
        end
    end
    if ability.lockRests then notes[#notes + 1] = self:LockIntervention(rolls) end
    if ability.name == "Runic Smite" then self.runeStrikeDamage = Sum(rolls, mod) end
    return #notes > 0 and table.concat(notes, "; ") or nil
end

-- The same for the dice of a spell, before they are applied (Actions/Spells.lua).
-- `slot` is the slot it was cast with, if any.
function RPSheet:SpellDiceFeatures(spell, slot, rolls, mod)
    local sheet, notes = self:Sheet(), {}
    local kind = spell.dice
    if kind == "HEALING" or kind == "SELFHEAL" then
        -- Supreme Healing: no dice rolled for a spell's healing, each counts its highest.
        if ns.HasFeature(sheet, "Supreme Healing") and #rolls > 0 then
            for index in ipairs(rolls) do rolls[index] = spell.sides end
            notes[#notes + 1] = "Supreme Healing: every die at its highest"
        end
        -- Blessed Healer: healing someone else with a slot heals you too.
        if kind == "HEALING" and slot and ns.HasFeature(sheet, "Blessed Healer") then
            local state, max, gain = self:State(), self:MaxHP(), 2 + slot.level
            if (state.hp or max) > 0 then
                state.hp = math.min(max, (state.hp or max) + gain)
                notes[#notes + 1] = ("Blessed Healer: you regain %d, now %d/%d HP"):format(gain, state.hp, max)
            end
        end
    elseif kind == "DAMAGE" or kind == "DRAIN" then
        -- Infusion of Light: the radiant dice rolled go back into the Lay on Hands pool.
        local pool = ns.SpellDamageType(spell) == "radiant" and ns.HasFeature(sheet, "Infusion of Light") and self:FindTracker("Lay on Hands")
        if pool and #rolls > 0 then
            local before = pool.get()
            pool.set(before + Sum(rolls))
            notes[#notes + 1] = ("Infusion of Light: Lay on Hands +%d, now %d"):format(pool.get() - before, pool.get())
        end
        if spell.name == "Rune Strike" then self.runeStrikeDamage = Sum(rolls, mod) end
    end
    return #notes > 0 and table.concat(notes, "; ") or nil
end
