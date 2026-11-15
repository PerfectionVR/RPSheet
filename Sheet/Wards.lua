-- The passives that stand for a protective spell running on the character (data in
-- Data/SpellWards.lua). One is made when the spell is cast on yourself from the sheet
-- (Sheet/WardCasting.lua) and marked auto = "ward:<spell>:<option>". It carries the
-- spell's resistances and immunities, so they show on the sheet and "Take damage"
-- applies them. It goes when a rest outlasts the spell, when concentration ends for a
-- spell that needs it, or when the player clicks it off.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local FIELDS = { "resist", "immune", "conditionImmune" }

-- "resistance to fire damage; can't be Prone": what an option gives, in words.
function ns.WardText(option)
    local parts = {}
    if option.immune then parts[#parts + 1] = "immunity to " .. R.DamageList(option.immune) .. (#option.immune < #R.DAMAGE_TYPES - 4 and " damage" or "") end
    if option.resist then parts[#parts + 1] = "resistance to " .. R.DamageList(option.resist) .. (#option.resist < #R.DAMAGE_TYPES - 4 and " damage" or "") end
    if option.conditionImmune then parts[#parts + 1] = "can't be " .. table.concat(option.conditionImmune, " or ") end
    return table.concat(parts, "; ")
end

-- Writes what the data says onto a ward's passive.
local function Fill(passive, ward, option, spell)
    passive.name = option.label and ("%s (%s)"):format(spell, option.label) or (spell .. " (spell)")
    passive.desc = ("On while %s protects you: %s. %sClick to switch it off when the spell ends."):format(spell, ns.WardText(option),
        ward.conc and "It ends with your concentration. " or (ward.hours >= 8 and "A rest doesn't end it unless it is as long as the spell. " or "A rest ends it. "))
    passive.effects = type(passive.effects) == "table" and passive.effects or {}
    for _, field in ipairs(FIELDS) do
        passive[field] = option[field] and CopyTable(option[field]) or nil
    end
end

-- Switches on the ward of a spell's option, in place of any other option of that spell.
function RPSheet:StartWard(spell, index)
    local ward, option = R.WardOf(R.WardKey(spell, index))
    if not ward then return end
    local passives, key, found = self:Sheet().passives, R.WardKey(spell, index), nil
    for at = #passives, 1, -1 do
        local auto = passives[at].auto or ""
        if auto == key then
            found = passives[at]
        elseif select(3, R.WardOf(auto)) == spell then
            table.remove(passives, at)
        end
    end
    if not found then
        found = { auto = key }
        passives[#passives + 1] = found
    end
    found.enabled = true
    Fill(found, ward, option, spell)
    return option
end

-- Ends wards: those of spells lasting `hours` or less (a rest of that length), those
-- that need concentration (`concentration` true), or with neither given all of them.
-- Returns the names of the ones that were on.
function RPSheet:EndWards(hours, concentration)
    local passives, ended = self:Sheet().passives, {}
    for at = #passives, 1, -1 do
        local ward = R.WardOf(passives[at].auto)
        if ward and ((not hours and not concentration) or (hours and ward.hours <= hours) or (concentration and ward.conc)) then
            if passives[at].enabled then ended[#ended + 1] = passives[at].name end
            table.remove(passives, at)
        end
    end
    return ended
end

-- The same after concentration has ended, with a line for the player and the sheet redrawn.
function RPSheet:EndConcentrationWards()
    local ended = self:EndWards(nil, true)
    if #ended > 0 then
        self:Print(("No longer on, with your concentration: %s."):format(table.concat(ended, ", ")))
        self:PopulateSoon()
    end
end

-- Sheet upkeep, called from ns.ApplyClassFeatures: a ward keeps to its data, one that
-- was clicked off or that the data no longer knows is cleared away.
function ns.ApplyWards(sheet)
    for at = #sheet.passives, 1, -1 do
        local passive = sheet.passives[at]
        if (passive.auto or ""):find("^ward:") then
            local ward, option, spell = R.WardOf(passive.auto)
            if ward and passive.enabled then
                Fill(passive, ward, option, spell)
            else
                table.remove(sheet.passives, at)
            end
        end
    end
    ns.ApplyDefenseSwitches(sheet)
end
