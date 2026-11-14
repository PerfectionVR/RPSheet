-- The spells picked for a class feature in the level dialog (lists in
-- Data/SpellChoices.lua): Mystic Arcanum, Spell Mastery, Signature Spells.
-- sheet.picks[<list>][<name>] = true. Each is put on the spell list marked
-- auto = "chosen:<name>" and as not counting against the spells prepared.
-- Casting them is in Actions/SpellChoices.lua.
local _, ns = ...
local R = ns.Rules

local PREFIX = "chosen:"

-- A list that follows the spellbook only offers the spells written in it. `sheet` may
-- be the level dialog's stand-in, whose picks are the ones being made.
for _, key in ipairs(R.SPELL_CHOICE_ORDER) do
    if R.SPELL_CHOICES[key].book then
        R.PICK_LISTS[key].blocked = function(sheet, name)
            if not ns.InSpellbook(sheet, name) then return "not in your spellbook" end
        end
    end
end

-- How a spell of the character is cast if it was chosen for a feature the character
-- has (an entry of R.SPELL_CHOICES), or nil for any other spell.
function ns.SpellChoice(sheet, name)
    if type(sheet.picks) ~= "table" then return end
    for _, key in ipairs(R.SPELL_CHOICE_ORDER) do
        local picks = sheet.picks[key]
        if type(picks) == "table" and picks[name] == true and R.PICK_LISTS[key].items[name]
            and ns.PickLimit(key, sheet.class, sheet.level, sheet.subclass) > 0 then
            local how = R.SPELL_CHOICES[key]
            -- A spell that left the spellbook since is no longer mastered.
            if not how.book or ns.InSpellbook(sheet, name) then return how end
        end
    end
end

-- Sheet upkeep (see Sheet/ClassFeatures.lua): drops the picks that stopped being
-- valid, so the level dialog asks for them again, and keeps the spell list in step.
function ns.ApplySpellChoices(sheet)
    local wanted = {}
    for _, key in ipairs(R.SPELL_CHOICE_ORDER) do
        local picks, how = sheet.picks[key], R.SPELL_CHOICES[key]
        if type(picks) == "table" and ns.PickLimit(key, sheet.class, sheet.level, sheet.subclass) > 0 then
            for name in pairs(picks) do
                local auto = PREFIX .. name
                -- Gone from the spellbook, or deleted from the spell list by the player.
                if not R.PICK_LISTS[key].items[name] or (how.book and not ns.InSpellbook(sheet, name)) or sheet.dismissed[auto] then
                    picks[name] = nil
                    sheet.dismissed[auto] = nil
                else
                    wanted[name] = true
                end
            end
        end
    end

    local have = {}
    for index = #sheet.spells, 1, -1 do
        local spell = sheet.spells[index]
        local auto = spell.auto or ""
        local chosen = auto:match("^" .. PREFIX .. "(.+)$")
        if chosen then
            -- Put there by an earlier pick: it stays only while it is still picked.
            if wanted[chosen] and not have[chosen] then have[chosen] = true else table.remove(sheet.spells, index) end
        elseif wanted[spell.name] and R.SPELLS[spell.name].level == spell.level then
            -- Prepared by hand before it was chosen: from now on it is always prepared.
            if auto == "" then spell.auto, spell.free = PREFIX .. spell.name, true end
            have[spell.name] = true
        end
    end

    local names = {}
    for name in pairs(wanted) do
        if not have[name] then names[#names + 1] = name end
    end
    table.sort(names, R.SpellBefore)
    for _, name in ipairs(names) do
        local spell = CopyTable(R.SPELLS[name])
        spell.free, spell.auto = true, PREFIX .. name
        sheet.spells[#sheet.spells + 1] = spell
    end
end
