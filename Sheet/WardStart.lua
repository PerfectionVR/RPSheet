-- What a protective spell cast on yourself does to your hit points the moment it
-- starts (fields of an option in Data/SpellWardEffects.lua): the hit points that come
-- with a higher maximum, temporary hit points, and a maximum raised by a roll.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The ward's passive on the sheet, by spell and option.
local function WardPassive(self, spell, option)
    for _, passive in ipairs(self:Sheet().passives) do
        local _, found = R.WardOf(passive.auto)
        if found == option and (passive.auto or ""):find("^ward:" .. spell:gsub("%p", "%%%0") .. ":") then return passive end
    end
end

-- Called when the ward of `option` has just been switched on with a slot of `slot`.
-- Returns words for the announcement, or nil.
function RPSheet:WardStarted(spell, option, slot)
    local state = self:State()
    slot = math.max(slot or 0, R.SPELLS[spell] and R.SPELLS[spell].level or 0)
    if option.heal then
        -- A higher maximum brings as many hit points with it.
        local amount = option.heal(slot)
        local max = self:MaxHP()
        state.hp = math.min(max, (state.hp or max) + amount)
        return ("%d hit points more (now %d/%d)"):format(amount, state.hp, max)
    end
    if option.tempHP then
        local amount = option.tempHP(slot, self)
        state.tempHP = math.max(state.tempHP or 0, amount)
        return ("%d temporary hit points (now %d)"):format(amount, state.tempHP)
    end
    if option.rollHP then
        -- Rolled after the casting is announced; the passive holds the number rolled.
        local passive = WardPassive(self, spell, option)
        local count, sides = option.rollHP[1], option.rollHP[2]
        self:RollDice(count, sides, function(rolls)
            local total = 0
            for _, value in ipairs(rolls) do total = total + value end
            if passive then passive.effects = { ns.FeatureKit.Bonus("HP", total) } end
            local max = self:MaxHP()
            state.hp = math.min(max, (state.hp or max) + total)
            self:Announce(("%s - %s more hit points, maximum and current (now %d/%d)"):format(ns.Mark(spell),
                ns.RollText.Dice("", rolls, sides, 0):gsub("^ ", ""), state.hp, max))
            self:Refresh()
        end)
        return ("%dd%d more hit points, rolled next"):format(count, sides)
    end
end
