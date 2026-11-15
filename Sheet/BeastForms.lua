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

-- What the second row of an attack says about when to use it (Data/Beasts.lua: alt).
local SITUATIONS = {
    ["charge"] = "Use this row when you moved 20 feet straight at the target just before the hit: it rolls that damage.",
    ["Bloodied target"] = "Use this row against a Bloodied target: it rolls the larger die.",
    ["while Bloodied"] = "Use this row while you are Bloodied: it rolls the smaller damage.",
}

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
    sheet = ns.ListView(sheet, "forms") -- the forms go by the level in the class that has them
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
            -- A swarm can't gain temporary hit points, so that form gives none.
            local swarm = name:find("^Swarm of") ~= nil
            use.desc = ("Bonus action. You become a %s for %d hours, keeping your hit points%s. %s The sheet uses the beast's numbers while the form is on."):format(
                name:lower(), math.floor(sheet.level / 2),
                swarm and "" or (" and gaining temporary hit points equal to " .. (moon and "three times your level" or "your level")), beast.desc)
            use.actions = { Kit.Spend("Wild Shape") }
            if not swarm then use.actions[2] = Kit.Dice(0, 4, "", "TEMPHP", sheet.level * (moon and 3 or 1)) end
            use.actions[#use.actions + 1] = Kit.SwitchOn(passiveName)
        end
        -- The passive is what the form hangs on, so it is always there.
        wanted[onKey] = true
        local on = Entry(sheet.passives, onKey, passiveName, { enabled = false })
        on.desc = ("Switched on while you are a %s. %s"):format(name:lower(), beast.desc)
        on.effects = (moon and sheet.level >= 6) and { Kit.Bonus("SAVE:CON", 0, "WIS") } or {}
        -- An attack whose damage changes in a situation (a charge, a Bloodied target)
        -- gets a second row that rolls it that way: `alt` is then the attack's alt.
        local rows = {}
        for index, attack in ipairs(beast.attacks) do
            rows[#rows + 1] = { attack, ("%s%s:attack%d"):format(PREFIX, name, index), ("%s: %s"):format(name, attack[1]) }
            if attack.alt then
                rows[#rows + 1] = { attack, ("%s%s:attack%d:alt"):format(PREFIX, name, index),
                    ("%s: %s (%s)"):format(name, attack[1], attack.alt[1]), attack.alt }
            end
        end
        for _, row in ipairs(rows) do
            local attack, key, alt = row[1], row[2], row[4]
            if not sheet.dismissed[key] then
                wanted[key] = true
                local ability = Entry(sheet.abilities, key, row[3])
                local note, plus = attack[7] and (" " .. attack[7]) or "", attack.plus
                if alt then note = note .. " " .. SITUATIONS[alt[1]] end
                -- The dice of this row: the usual ones, or the situation's in their place.
                local count, sides, flat = attack[3], attack[4], attack[5]
                if alt and not alt.extra then count, sides, flat = alt[2], alt[3], alt[4] end
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
                if count > 0 or flat ~= 0 then
                    ability.actions[#ability.actions + 1] = Kit.Dice(count, sides, "", "DAMAGE", flat)
                end
                if alt and alt.extra then ability.actions[#ability.actions + 1] = Kit.Dice(alt[2], alt[3], "", "DAMAGE", 0) end
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
