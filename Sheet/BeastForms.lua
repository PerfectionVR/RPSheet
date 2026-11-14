-- Puts the beasts a druid knows as Wild Shape forms on the sheet (data in
-- Data/Beasts.lua, chosen as the "forms" pick list). Each known beast gets:
--   * an ability "Wild Shape: <Beast>" that spends a use and switches the form on,
--   * a passive "<Beast> form" that is on while the form lasts,
--   * an ability for each of its attacks,
-- and there is one ability to leave any form. All are marked auto = "form:...".
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit

local PREFIX = "form:"

local function Find(list, auto)
    for _, entry in ipairs(list) do
        if entry.auto == auto then return entry end
    end
end

-- The entry with that key, made if it isn't there yet.
local function Entry(list, auto, name, fresh)
    local entry = Find(list, auto)
    if not entry then
        entry = fresh or {}
        entry.auto = auto
        list[#list + 1] = entry
    end
    entry.name = name
    return entry
end

function ns.ApplyBeastForms(sheet)
    local wanted, known = {}, {}
    if ns.PickLimit("forms", sheet.class, sheet.level) > 0 then
        for name in pairs(sheet.picks.forms or {}) do
            if R.BEASTS[name] then known[#known + 1] = name end
        end
    end
    table.sort(known)
    local moon = sheet.subclass == "Circle of the Moon"

    for _, name in ipairs(known) do
        local beast, passiveName = R.BEASTS[name], R.BeastFormPassive(name)
        local useKey, onKey = PREFIX .. name .. ":use", PREFIX .. name .. ":on"
        if not sheet.dismissed[useKey] then
            wanted[useKey] = true
            local use = Entry(sheet.abilities, useKey, "Wild Shape: " .. name)
            use.desc = ("Bonus action. You become a %s for %d hours, keeping your hit points and gaining temporary hit points equal to %s. %s The sheet uses the beast's numbers while the form is on."):format(
                name:lower(), math.floor(sheet.level / 2), moon and "three times your level" or "your level", beast.desc)
            use.actions = { Kit.Spend("Wild Shape"), Kit.Dice(0, 4, "", "TEMPHP", sheet.level * (moon and 3 or 1)), Kit.SwitchOn(passiveName) }
        end
        -- The passive is what the form hangs on, so it is always there.
        wanted[onKey] = true
        local on = Entry(sheet.passives, onKey, passiveName, { enabled = false })
        on.desc = ("Switched on while you are a %s. %s"):format(name:lower(), beast.desc)
        on.effects = (moon and sheet.level >= 6) and { Kit.Bonus("SAVE:CON", 0, "WIS") } or {}
        for index, attack in ipairs(beast.attacks) do
            local key = ("%s%s:attack%d"):format(PREFIX, name, index)
            if not sheet.dismissed[key] then
                wanted[key] = true
                local ability = Entry(sheet.abilities, key, ("%s: %s"):format(name, attack[1]))
                local note, plus = attack[7] and (" " .. attack[7]) or "", attack.plus
                ability.actions = {}
                if attack[2] then
                    local kind = attack.ranged and ("A ranged attack (%s feet)"):format(attack.ranged)
                        or attack.reach and ("A melee attack with a reach of %d feet"):format(attack.reach) or "A melee attack"
                    ability.desc = ("%s form. %s, %s damage%s.%s"):format(name, kind, attack[6],
                        plus and (" plus %dd%d %s, rolled second"):format(plus[1], plus[2], plus[3]) or "", note)
                    local roll = Kit.Roll("ATTACK", "", false)
                    roll.rollFlat = attack[2] -- the beast's own attack bonus
                    ability.actions[1] = roll
                else
                    -- No attack roll: the target saves, or it simply happens.
                    ability.desc = ("%s form.%s%s"):format(name, note, attack[3] > 0 and (" The damage is %s."):format(attack[6]) or "")
                end
                if attack[3] > 0 or attack[5] ~= 0 then
                    ability.actions[#ability.actions + 1] = Kit.Dice(attack[3], attack[4], "", "DAMAGE", attack[5])
                end
                if plus then ability.actions[#ability.actions + 1] = Kit.Dice(plus[1], plus[2], "", "DAMAGE", 0) end
            end
        end
    end

    local leaveKey = PREFIX .. "leave"
    if #known > 0 and not sheet.dismissed[leaveKey] then
        wanted[leaveKey] = true
        local leave = Entry(sheet.abilities, leaveKey, "Leave beast form")
        leave.desc = "Bonus action. You return to your own shape. The form also ends when you are incapacitated or use Wild Shape again."
        leave.actions = {}
        for _, name in ipairs(known) do leave.actions[#leave.actions + 1] = Kit.SwitchOff(R.BeastFormPassive(name)) end
    end

    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for index = #list, 1, -1 do
            local auto = list[index].auto or ""
            if auto:find("^" .. PREFIX) and not wanted[auto] then table.remove(list, index) end
        end
    end
end
