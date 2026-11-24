-- The character's own features that change damage as it is taken (Actions/Damage.lua
-- applies them in order; UI/DamageReactions.lua offers the choices in the menu).
-- `how` is what the player said about the damage, all fields optional:
--   attack    true: an attack hit (Heavy Armor Master)
--   dodge     true: Uncanny Dodge against an attacker the character can see (reaction)
--   hunter    true: Superior Hunter's Defense (reaction)
--   dexSave   "pass" or "fail": a Dexterity save for half damage (Evasion)
--   fall      true: damage from falling (Bouncy, Slow Fall, landing Prone)
--   slowFall  true: Slow Fall (reaction)
--   nose      true or false: the first damage since initiative; nil asks the sheet
--   pool      true: the Delayed Reaction pool's own damage (Stagger and Sway)
--   said      the roll the damage came from, put first in the announcement
-- A reaction is spent until the player says it is back (UI/DamageReactions.lua), a
-- rest or initiative; nothing works while the character is incapacitated.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local BLADES = {}
for _, name in ipairs(R.WEAPON_DAMAGE) do BLADES[name] = true end

-- A class or subclass feature that is on.
local function Feature(sheet, name)
    local passive = ns.FeaturePassive(sheet, name)
    return passive ~= nil and passive.enabled
end
local Feat, Trait = ns.PassiveOn, ns.HasTrait

-- What the character can use against damage right now: each field is false or what
-- it comes to (true, or the number it takes off).
function RPSheet:DamageOptions()
    local sheet, state = self:Sheet(), self:State()
    local held = self:Incapacitated() ~= nil
    local reaction = not held and not state.reactionUsed
    local monk = ns.BaseView(sheet, "Monk")
    return {
        evasion = Feature(sheet, "Evasion") and not held,
        dodge = Feature(sheet, "Uncanny Dodge") and reaction,
        hunter = Feature(sheet, "Superior Hunter's Defense") and reaction,
        slowFall = Feature(sheet, "Slow Fall") and reaction and 5 * (monk and monk.level or sheet.level),
        armor = Feat(sheet, "Heavy Armor Master") and ns.HeavyArmor(sheet) and not self:Form() and self:ProficiencyBonus(),
        nose = Trait(sheet, "Nose for Trouble") and self:Level(),
        bouncy = Trait(sheet, "Bouncy"),
        stagger = Feat(sheet, "Stagger and Sway") and math.max(1, self:Mod("DEX")),
        -- the reaction features the character has at all, used or not
        reactions = Feature(sheet, "Uncanny Dodge") or Feature(sheet, "Superior Hunter's Defense") or Feature(sheet, "Slow Fall"),
    }
end

-- True when Nose for Trouble works on this damage.
local function NoseNow(self, can, how)
    if not can.nose then return false end
    if how.nose ~= nil then return how.nose end
    return self:State().noseReady == true
end

-- { flat = { { amount, why } }, half = why, none = why, resist = why, used = { ... } }
function RPSheet:DamageSteps(damageType, how)
    how = how or {}
    local can, steps = self:DamageOptions(), { flat = {}, used = {} }
    local function Flat(amount, why, key)
        steps.flat[#steps.flat + 1] = { amount, why }
        steps.used[key] = true
    end
    if NoseNow(self, can, how) then Flat(can.nose, "Nose for Trouble", "nose") end
    if can.armor and how.attack and BLADES[damageType or ""] then Flat(can.armor, "Heavy Armor Master", "armor") end
    if can.slowFall and how.fall and how.slowFall then Flat(can.slowFall, "Slow Fall", "slowFall") end
    if can.stagger and not how.pool then Flat(can.stagger, "Stagger and Sway", "stagger") end
    if how.dexSave == "pass" then
        if can.evasion then steps.none = "Evasion: a Dexterity save passed" else steps.half = "a Dexterity save passed" end
    elseif how.dexSave == "fail" and can.evasion then
        steps.half = "Evasion: a Dexterity save failed"
    elseif can.dodge and how.dodge then
        steps.half, steps.used.dodge = "Uncanny Dodge", true
    end
    if can.hunter and how.hunter and damageType then steps.resist, steps.used.hunter = "Superior Hunter's Defense", true end
    if can.bouncy and how.fall and damageType == "bludgeoning" then steps.resist = steps.resist or "Bouncy" end
    return steps
end

-- What follows once the damage is known: a reaction spent, Nose for Trouble used up,
-- a die for the Delayed Reaction pool, Superior Hunter's Defense kept for the rest
-- of the turn, Prone after a fall that hurt. Adds words to `notes`.
function RPSheet:DamageStepsTaken(steps, how, damageType, final, notes)
    local state, used = self:State(), steps.used
    how = how or {}
    if used.dodge or used.hunter or used.slowFall then state.reactionUsed = true end
    -- The first damage after initiative is past, whether the trait was used on it or not.
    state.noseReady = nil
    if used.stagger then
        state.delayedDice = (state.delayedDice or 0) + 1
        notes[#notes + 1] = ("Delayed Reaction pool now %dd6"):format(state.delayedDice)
    end
    if used.hunter then self:StartHunterDefense(damageType) end
    if how.fall and final > 0 and not state.conditions.Prone and not self:Defenses().conditionImmune.Prone then
        state.conditions.Prone = true
        notes[#notes + 1] = "lands " .. ns.Mark("Prone")
    end
end
