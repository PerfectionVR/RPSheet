-- What the character's Fighting Styles do: to weapons, to Armor Class, and what the
-- feature's passive says. Every style the character has counts, whichever of its
-- classes picked it, and never twice (ns.StylesHeld in Sheet/FightingStyles.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The data of the styles the character has chosen and is entitled to.
function RPSheet:FightingStyles()
    local styles = {}
    for _, held in ipairs(ns.StylesHeld(self:Sheet())) do styles[#styles + 1] = held.style end
    return styles
end

-- What the Fighting Styles add to a weapon: attack bonus, damage bonus, and the
-- lowest a damage die can count as.
function RPSheet:WeaponStyle(weapon)
    local attack, damage, minDie = 0, 0, 1
    if not weapon.heal then
        -- A magic weapon's own bonus goes on both rolls made with it.
        attack, damage = weapon.magic or 0, weapon.magic or 0
        for _, style in ipairs(self:FightingStyles()) do
            if ns.FitsStyle(weapon, style) then
                attack, damage = attack + (style.attack or 0), damage + (style.damage or 0)
                minDie = math.max(minDie, style.minDie or 1)
            end
        end
    end
    return attack, damage, minDie
end

-- Armor Class from Fighting Styles.
function RPSheet:StyleAC()
    local total = 0
    if self:Sheet().armor ~= "NONE" then
        for _, style in ipairs(self:FightingStyles()) do total = total + (style.armoredAC or 0) end
    end
    return total
end

-- True if any chosen style changes weapon numbers, so weapons need the tick box.
function RPSheet:StyleAffectsWeapons()
    for _, style in ipairs(self:FightingStyles()) do
        if style.attack or style.damage or style.minDie then return true end
    end
    return false
end

local TO_CHOOSE = "You have a Fighting Style to choose. Pick it under Customize, %s."

-- Shows the chosen styles on the feature's passive. Two classes with the feature share
-- the one passive, which then names both picks. Called whenever class features are
-- refreshed (see Sheet/ClassFeatures.lua).
function ns.ApplyFightingStyles(sheet)
    ns.AdoptStyles(sheet)
    local slots = ns.StyleSlots(sheet)
    for slot, feature in ipairs(ns.STYLE_FEATURES) do
        local passive = ns.FeaturePassive(sheet, feature)
        if passive then
            local names, lines, seen, open = {}, {}, {}, nil
            for _, held in ipairs(slots) do
                local style = held.slot == slot and R.FIGHTING_STYLES[held.name]
                if style and not seen[held.name] then
                    seen[held.name] = true
                    names[#names + 1] = held.name
                    lines[#lines + 1] = ("%s: %s"):format(held.name, style.desc)
                elseif held.slot == slot and not style then
                    open = TO_CHOOSE:format(held.class == sheet.class and "Class and origin" or "More classes")
                end
            end
            if #names == 0 then
                passive.name = feature
                passive.desc = open or TO_CHOOSE:format("Class and origin")
            elseif #names == 1 and not open then
                passive.name, passive.desc = feature .. ": " .. names[1], R.FIGHTING_STYLES[names[1]].desc
            else
                if open then lines[#lines + 1] = open end
                passive.name, passive.desc = feature .. ": " .. table.concat(names, ", "), table.concat(lines, " ")
            end
        end
    end
end
