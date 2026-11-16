-- An Unarmed Strike row for a character whose punches are better than the usual
-- 1 + Strength: Tavern Brawler (1d4, 1s rerolled), the Unarmed Fighting style (1d6,
-- or 1d8 with no weapon or shield in hand: a row of its own), the Strike of the
-- Earth-Warder blessing (+1 to hit and damage), Fists of Fury (a 1 counts as a 2).
-- A Monk has its own row from Martial Arts; these are added to that one instead.
-- The ability is marked auto = "unarmed:<name>".
local _, ns = ...
local Kit = ns.FeatureKit

local PREFIX = "unarmed:"
local NONE = {}

local function HasPassive(sheet, name)
    for _, passive in ipairs(sheet.passives or NONE) do
        if passive.name == name and passive.enabled then return true end
    end
    return false
end

local function HasStyle(sheet, name)
    for _, held in ipairs(ns.StylesHeld(sheet)) do
        if held.name == name then return true end
    end
    return HasPassive(sheet, name)
end

-- The rows the character gets: { name, sides or 0, desc }.
local function Rows(sheet, brawler, fighting)
    local rows = {}
    if fighting then
        rows[1] = { "Unarmed Strike", 6, "1d6 + Strength bludgeoning (Unarmed Fighting). Use the hands-free row when you hold no weapon or shield." }
        rows[2] = { "Unarmed Strike, hands free", 8, "1d8 + Strength bludgeoning (Unarmed Fighting), when you hold no weapon or shield as you attack." }
    elseif brawler then
        rows[1] = { "Unarmed Strike", 4, "1d4 + Strength bludgeoning (Tavern Brawler). Once per turn a hit as part of the Attack action can also push the target 5 feet." }
    else
        rows[1] = { "Unarmed Strike", 0, "A punch, kick or headbutt: 1 + Strength bludgeoning." }
    end
    return rows
end

-- Sets what the feats and the blessing add on a strike's steps: `flat` is the damage
-- added before the blessing's. It sets rather than adds, so it can run again on the
-- same steps.
local function Tune(actions, flat, earth, brawler, fury)
    for _, action in ipairs(actions) do
        if action.type == "ROLL" and action.kind == "ATTACK" then action.rollFlat = earth and 1 or 0 end
        if action.type == "DICE" then
            action.flat = flat + (earth and 1 or 0)
            action.reroll, action.rerollFrom = brawler and 1 or 0, brawler and "Tavern Brawler" or ""
            action.lowest, action.lowestFrom = fury and 2 or 0, fury and "Fists of Fury" or ""
            action.damage = "bludgeoning"
        end
    end
end

-- Sheet upkeep, after the feats and blessings are on the sheet.
function ns.ApplyUnarmedStrike(sheet)
    local brawler, fighting = HasPassive(sheet, "Tavern Brawler"), HasStyle(sheet, "Unarmed Fighting")
    local earth, fury = HasPassive(sheet, "Strike of the Earth-Warder"), HasPassive(sheet, "Fists of Fury")
    local monk = ns.HasFeature(sheet, "Martial Arts")
    local wanted = {}
    if not monk and (brawler or fighting or earth or fury) then
        for _, row in ipairs(Rows(sheet, brawler, fighting)) do
            if not sheet.dismissed[PREFIX .. row[1]] then wanted[PREFIX .. row[1]] = row end
        end
    end
    for index = #sheet.abilities, 1, -1 do
        local ability = sheet.abilities[index]
        local auto = ability.auto or ""
        if auto:find("^" .. PREFIX) and not wanted[auto] then table.remove(sheet.abilities, index) end
        -- A Monk's own strikes take the blessing and the feats.
        if monk and auto:find("^class:") and (ability.name == "Unarmed Strike" or ability.name == "Flurry of Blows") then
            Tune(ability.actions or NONE, 0, earth, brawler, fury)
        end
    end
    for key, row in pairs(wanted) do
        local ability
        for _, each in ipairs(sheet.abilities) do
            if each.auto == key then ability = each end
        end
        if not ability then
            ability = { name = row[1], auto = key }
            sheet.abilities[#sheet.abilities + 1] = ability
        end
        -- Without a die it is a plain 1 + Strength.
        ability.actions = { Kit.Roll("ATTACK", "STR"), Kit.Dice(row[2] > 0 and 1 or 0, math.max(row[2], 4), "STR") }
        Tune(ability.actions, row[2] > 0 and 0 or 1, earth, brawler, fury)
        local extra = {}
        if earth then extra[#extra + 1] = "+1 to hit and damage (Strike of the Earth-Warder)" end
        if brawler then extra[#extra + 1] = "1s on the damage die are rerolled (Tavern Brawler)" end
        if fury then extra[#extra + 1] = "a 1 on the damage die counts as 2 (Fists of Fury)" end
        ability.desc = row[3] .. (#extra > 0 and (" With " .. table.concat(extra, "; ") .. ".") or "")
    end
end

