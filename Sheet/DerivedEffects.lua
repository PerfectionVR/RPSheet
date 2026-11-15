-- Numbers worked out from the saved sheet: what passives and items add to a number.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util

-- flat + times x source, where the source is an ability modifier, the level or the
-- proficiency bonus (see Rules.AMOUNT_SOURCES).
function RPSheet:Amount(flat, source, times)
    local value
    if source == "LEVEL" then
        value = self:Level()
    elseif source == "PROF" then
        value = self:ProficiencyBonus()
    else
        value = self:Mod(source)
    end
    return (flat or 0) + (times or 1) * value
end

function RPSheet:EffectValue(effect)
    return self:Amount(effect.flat, effect.stat, effect.times)
end

-- Total of every switched-on passive effect aimed at `target` (see Rules.EFFECT_TARGETS).
-- Exhaustion weighs on every d20 roll and on speed.
local D20_TARGETS = { ATTACK = true, SPELLATK = true, SAVES = true, CHECKS = true, INIT = true }

function RPSheet:Bonus(target)
    local total = 0
    local exhaustion = self:State().exhaustion or 0
    if D20_TARGETS[target] then
        total = -R.EXHAUSTION_D20 * exhaustion
    elseif target == "SPEED" then
        total = -R.EXHAUSTION_SPEED * exhaustion
    end
    for _, passive in ipairs(self:Sheet().passives) do
        -- A passive that armor stops adds nothing (see Sheet/Limits.lua).
        if passive.enabled and passive.name ~= "" and not self:PassiveBlocked(passive) then
            for _, effect in ipairs(passive.effects) do
                -- Only effects that add; setting and multiplying is in Sheet/SetEffects.lua.
                if effect.target == target and ns.EffectMode(effect) == "" then
                    total = total + self:EffectValue(effect)
                end
            end
        end
    end
    -- Magic items that are equipped, and attuned where needed (Sheet/Inventory.lua).
    return total + self:ItemBonus(target)
end

-- e.g. "+3 +2x DEX to Armor Class (now +9)"
function RPSheet:EffectText(effect)
    -- An effect that sets or multiplies says the number it leads to.
    local mode, name = ns.EffectMode(effect), R.EFFECT_TARGETS[effect.target] or effect.target
    if mode == "MIN" then return ("%s set to %d, if that is higher"):format(name, effect.flat) end
    if mode == "TIMES" then return ("%s multiplied by %d"):format(name, ns.EffectTimes(effect)) end
    local parts = {}
    if effect.flat ~= 0 then parts[#parts + 1] = Util.Signed(effect.flat) end
    if R.AMOUNT_SOURCES[effect.stat] and effect.stat ~= "" then
        parts[#parts + 1] = "+" .. (effect.times > 1 and (effect.times .. "x ") or "") .. (R.AMOUNT_SHORT[effect.stat] or effect.stat)
    end
    if #parts == 0 then parts[1] = "+0" end
    return ("%s to %s (now %s)"):format(
        table.concat(parts, " "), R.EFFECT_TARGETS[effect.target] or effect.target, Util.Signed(self:EffectValue(effect)))
end
