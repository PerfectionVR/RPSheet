-- The passives that stand for a protective spell running on the character (data in
-- Data/SpellWards.lua). One is made when the spell is cast on yourself from the sheet
-- (Sheet/WardCasting.lua) and marked auto = "ward:<spell>:<option>". It carries the
-- spell's resistances and immunities, so they show on the sheet and "Take damage"
-- applies them. It goes when a rest outlasts the spell, when concentration ends for a
-- spell that needs it, or when the player clicks it off. Protection someone else casts
-- on you is put there under Customize, Defense (Options/WardSwitches.lua): such a
-- passive is marked byOther, and the caster's concentration is not yours to end. An
-- option that is only ever cast by someone else (byHand) stays when it is off.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local FIELDS = { "resist", "immune", "conditionImmune" }
-- What else an option can put on its passive: rolls it gives advantage, disadvantage or
-- a die on (Actions/SpellRollBonus.lua), and flags for Armor Class and weapons
-- (Sheet/SpellAC.lua, Sheet/SpellWeapons.lua).
-- oneRoll: the passive switches off after the first roll it gives advantage on.
local MORE = { "advantage", "disadvantage", "rollDie", "minRoll", "oneRoll" }

-- "resistance to fire damage; can't be Prone": what an option gives, in words.
function ns.WardText(option)
    if option.text then return option.text end -- more than a list can say
    local parts = {}
    if option.immune then parts[#parts + 1] = "immunity to " .. R.DamageList(option.immune) .. (#option.immune < #R.DAMAGE_TYPES - 4 and " damage" or "") end
    if option.resist then parts[#parts + 1] = "resistance to " .. R.DamageList(option.resist) .. (#option.resist < #R.DAMAGE_TYPES - 4 and " damage" or "") end
    if option.conditionImmune then parts[#parts + 1] = "can't be " .. table.concat(option.conditionImmune, " or ") end
    if option.roll then
        local dice = ("%dd%d"):format(option.roll[1], option.roll[2])
        if option.once then
            parts[#parts + 1] = dice .. " off the damage you take next"
        else
            parts[#parts + 1] = ("%s off %s%s"):format(dice, option.reduce and (R.DamageList(option.reduce) .. " damage") or "any damage",
                option.perTurn and ", once a turn" or "")
        end
    end
    return table.concat(parts, "; ")
end

-- What the passive of an option with dice says about how they are used.
function ns.WardRollNote(option)
    if not option.roll then return "" end
    local note = "\"Take damage\" rolls it for you. "
    if option.owed then
        note = note .. ("After that you lose 1d%d hit points at the end of each of your next %d turns: \"Take damage\" has a row for it. "):format(option.roll[2], option.owed)
    end
    return note
end

-- Writes what the data says onto a ward's passive.
local function Fill(passive, ward, option, spell)
    passive.name = option.label and ("%s (%s)"):format(spell, option.label) or (spell .. " (spell)")
    local ends = ward.hours >= 8 and "A rest doesn't end it unless it is as long as the spell. " or "A rest ends it. "
    if ward.conc then ends = passive.byOther and "It ends with its caster's concentration, which the sheet can't see. " or "It ends with your concentration. " end
    passive.desc = option.desc or ("On while %s protects you: %s. %s%sClick to switch it off when the spell ends."):format(spell, ns.WardText(option),
        ns.WardRollNote(option), ends)
    -- What it adds can follow the slot it was cast with (Data/SpellWardEffects.lua).
    local slot = math.max(passive.slot or 0, R.SPELLS[spell] and R.SPELLS[spell].level or 0)
    local effects = option.effectsAt and option.effectsAt(slot) or option.effects
    passive.effects = effects and CopyTable(effects) or (type(passive.effects) == "table" and passive.effects or {})
    for _, field in ipairs(FIELDS) do
        passive[field] = option[field] and CopyTable(option[field]) or nil
    end
    local strike = option.strikeAt and option.strikeAt(slot) or option.strike
    passive.strike = strike and CopyTable(strike) or nil
    for _, field in ipairs(MORE) do
        local value = option[field]
        passive[field] = type(value) == "table" and CopyTable(value) or value
    end
    local flags = option.flagsAt and option.flagsAt(slot) or option.flags
    passive.flags = flags and CopyTable(flags) or nil
end

-- Switches on the ward of a spell's option, in place of any other option of that spell.
-- `byOther` is true when someone else cast it on the character; `slot` is the level
-- of the slot it was cast with.
function RPSheet:StartWard(spell, index, byOther, slot)
    local ward, option = R.WardOf(R.WardKey(spell, index))
    if not ward then return end
    local passives, key, found = self:Sheet().passives, R.WardKey(spell, index), nil
    for at = #passives, 1, -1 do
        local auto = passives[at].auto or ""
        local _, other, otherSpell = R.WardOf(auto)
        if auto == key then
            found = passives[at]
        elseif otherSpell == spell and not other.byHand and not option.byHand then
            -- The two sides of a bond are different things and stay side by side.
            table.remove(passives, at)
        end
    end
    if not found then
        found = { auto = key }
        passives[#passives + 1] = found
    end
    found.enabled = true
    found.byOther = byOther and true or nil
    found.owed = nil -- a new casting owes nothing yet (Actions/WardDamage.lua)
    found.slot = slot -- the slot it was cast with, when what it gives follows that
    Fill(found, ward, option, spell)
    return option
end

-- Ends wards: those of spells lasting `hours` or less (a rest of that length), those
-- that need concentration (`concentration` true), or with neither given all of them.
-- Returns the names of the ones that were on.
function RPSheet:EndWards(hours, concentration)
    local passives, ended = self:Sheet().passives, {}
    for at = #passives, 1, -1 do
        local ward, option = R.WardOf(passives[at].auto)
        -- Someone else's spell doesn't hang on this character's concentration.
        local own = ward and ward.conc and not passives[at].byOther
        if ward and ((not hours and not concentration) or (hours and ward.hours <= hours) or (concentration and own)) then
            if passives[at].enabled then ended[#ended + 1] = passives[at].name end
            -- Protection put there by hand is switched off and stays for the next time.
            if option.byHand then passives[at].enabled = false else table.remove(passives, at) end
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
            if ward and (passive.enabled or option.byHand) then
                Fill(passive, ward, option, spell)
            else
                table.remove(sheet.passives, at)
            end
        end
    end
    ns.ApplyDefenseSwitches(sheet)
end
