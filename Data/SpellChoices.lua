-- Spells a class feature lets the character choose, as pick lists for the level dialog
-- (see Data/Picks.lua for the form):
--   arcanum6 .. arcanum9  a Warlock's Mystic Arcanum: one spell of each of those levels
--   spellMastery1, 2      a Mage's Spell Mastery: a 1st and a 2nd-level spellbook spell
--   signatureSpells       a Mage's Signature Spells: two 3rd-level spellbook spells
-- A list with `follows = "spellbook"` only offers spells that are in the spellbook.
-- All are `custom`: Sheet/SpellChoices.lua puts the chosen spells on the spell list.
--
-- R.SPELL_CHOICES[key] says how a spell chosen from the list is cast:
--   feature     the feature's name, for the chat line
--   spellLevel  the level of the spells, which is also the level the free casting has
--   once        true for one casting without a slot per rest; otherwise at will
--   short       true when a short rest brings that casting back as well as a long one
--   only        true when there is no other way to cast it (no slots of that level)
--   book        true when the spell has to be in the spellbook
--   mark, note  what the spell's row and tooltip say
local _, ns = ...
local R = ns.Rules

R.SPELL_CHOICES = {}
R.SPELL_CHOICE_ORDER = {}

-- `actionOnly` leaves out spells cast with a bonus action, a reaction or over minutes.
local function Define(key, title, base, classLevel, count, how, actionOnly)
    local items, order = {}, {}
    for _, name in ipairs(R.SPELL_LISTS[base] or {}) do
        local spell = R.SPELLS[name]
        if spell and spell.level == how.spellLevel and not items[name] and (not actionOnly or (spell.time or "ACTION") == "ACTION") then
            items[name] = { desc = spell.desc, group = R.SPELL_GROUPS[R.SpellGroup(name)] }
            order[#order + 1] = name
        end
    end
    table.sort(order, R.SpellBefore)
    R.PICK_LISTS[key] = {
        title = title, base = base, custom = true,
        hideBlocked = how.book == true, follows = how.book and "spellbook" or nil,
        known = { { classLevel, count } }, items = items, order = order,
    }
    R.PICK_LIST_ORDER[#R.PICK_LIST_ORDER + 1] = key
    R.SPELL_CHOICES[key] = how
    R.SPELL_CHOICE_ORDER[#R.SPELL_CHOICE_ORDER + 1] = key
end

-- Mystic Arcanum: a spell of 6th to 9th level at Warlock levels 11, 13, 15 and 17.
for index, classLevel in ipairs({ 11, 13, 15, 17 }) do
    local spellLevel = index + 5
    Define("arcanum" .. spellLevel, ("Mystic Arcanum: %s-level spell"):format(R.ORDINALS[spellLevel]), "Warlock", classLevel, 1, {
        feature = "Mystic Arcanum", spellLevel = spellLevel, once = true, only = true, mark = "arcanum",
        note = "Mystic Arcanum: you cast it once without a spell slot. A long rest brings the casting back.",
    })
end

-- Spell Mastery, at level 18.
for spellLevel = 1, 2 do
    Define("spellMastery" .. spellLevel, ("Spell Mastery: %s-level spell from your spellbook, cast with an action"):format(R.ORDINALS[spellLevel]),
        "Wizard", 18, 1, {
            feature = "Spell Mastery", spellLevel = spellLevel, book = true, mark = "mastered",
            note = ("Spell Mastery: always prepared, and cast at %s level without a spell slot as often as you like."):format(R.ORDINALS[spellLevel]),
        }, true)
end

-- Signature Spells, at level 20.
Define("signatureSpells", "Signature Spells: 3rd-level spells from your spellbook", "Wizard", 20, 2, {
    feature = "Signature Spell", spellLevel = 3, once = true, short = true, book = true, mark = "signature",
    note = "Signature Spell: always prepared. You cast it once at 3rd level without a spell slot; a short or long rest brings that casting back. Other castings spend a slot.",
})
