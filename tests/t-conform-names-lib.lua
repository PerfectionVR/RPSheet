-- Where the addon names or splits a feature differently from the rules site on
-- purpose, each with its reason, for t-conform-classes.lua. Nothing here hides a wrong
-- number: a merged feature still has to be on the sheet, new or changed at the level
-- it arrives, and a helper entry has to belong to a feature the site gives at that level.
-- Keys are "<class key, core class or subclass>/<name>", with "@<level>" for one level.
Names = {}

-- Features the sheet doesn't list as entries because another part of the addon is
-- the feature. Each has its own comparison in the t-conform-*-lib.lua files.
Names.STRUCTURE = {
    ["Ability Score Improvement"] = "the level dialog asks for it: compared as 'improvement or boon'",
    ["Epic Boon"] = "the level dialog asks for it: compared as 'improvement or boon'",
    ["Spellcasting"] = "the class's caster kind and ability, its slots, cantrips and prepared spells are compared",
    ["Unarmored Defense"] = "the class's `unarmored` ability works out the Armor Class: compared as 'Unarmored Defense'",
    ["Metamagic Options"] = "the site's list of options: compared as the metamagic list",
    ["Eldritch Invocation Options"] = "the site's list of options: compared as the invocation list",
    ["Maneuver Options"] = "the site's list of options: compared as the maneuver list",
}

-- The subclass a class is compared with, where the first one changes the class's own
-- features: a Beast Master has Pet Specialization in place of Roving (see Names.Custom).
Names.CLASS_WITH = { HUNTER = "Hunter" }

-- Expertise picks a feature gives, from the features' text.
Names.EXPERTISE = { ["Expertise"] = 2, ["Deft Explorer"] = 1, ["Scholar"] = 1 }

-- A site feature that is part of another entry on the sheet:
--   to       the entry it is part of, which must be new or change at that level
--   counted  the comparison that covers it, for a feature that only raises a number
local function To(entry, why) return { to = entry, why = why } end
local function Counted(comparison, why) return { counted = comparison, why = why } end
Names.MERGED = {
    ["Paladin/Channel Divinity"] = To("Divine Sense", "the uses are a bar; the entry is what a use does at this level"),
    ["Cleric/Channel Divinity"] = To("Divine Spark", "the uses are a bar; the entries are its two effects, Divine Spark and Turn Undead"),
    ["Ranger/Favored Enemy"] = To("Hunter's Mark", "the feature is free castings of Hunter's Mark: the entry is named for what the click does, its bar keeps the site's name"),
    ["Sorcerer/Metamagic@10"] = Counted("Metamagic options", "two more options: the pick limit"),
    ["Sorcerer/Metamagic@17"] = Counted("Metamagic options", "two more options: the pick limit"),
    ["Warlock/Mystic Arcanum@13"] = Counted("Mystic Arcanum spell levels", "one more spell to choose: its pick list"),
    ["Warlock/Mystic Arcanum@15"] = Counted("Mystic Arcanum spell levels", "one more spell to choose: its pick list"),
    ["Warlock/Mystic Arcanum@17"] = Counted("Mystic Arcanum spell levels", "one more spell to choose: its pick list"),
    ["Rogue/Improved Cunning Strike"] = To("Cunning Strike", "one rule (two effects per Sneak Attack): the Cunning Strike entry says it from level 11"),
    ["Rogue/Devious Strikes"] = To("Cunning Strike: Daze", "three more Cunning Strike options, each an ability named like the earlier ones"),
    ["Fighter/Two Extra Attacks"] = To("Extra Attack", "one entry that says how many attacks the level gives"),
    ["Fighter/Three Extra Attacks"] = To("Extra Attack", "one entry that says how many attacks the level gives"),
    ["Champion/Superior Critical"] = To("Improved Critical", "one entry and one bonus that widens the critical range at level 15"),
    ["Soulknife/Psychic Blades"] = To("Psychic Blade", "the entry is one blade's attack, so it is named in the singular"),
    ["Soulknife/Soul Blades"] = To("Homing Strikes", "two powers, each an ability under its own name"),
}

-- An entry of the sheet that the site doesn't list by name:
--   of     the site feature of the same level it is part of
--   spell  the always-prepared spell of the same level it goes with
local function Of(feature, why) return { of = feature, why = why } end
local SWITCH = "the passive an ability switches on, so the sheet can apply its numbers"
local PART = "a named part of the feature, made an ability so it can be clicked"
local FORMS = "the setting's ready-made cat and bear forms for a Moon druid (the book's Feral pages, not in the class data)"
Names.EXTRA = {
    ["DEATHKNIGHT/Undead"] = Of("Death Coil", "Death Coil's first sentence makes the character Undead: shown as a line of its own"),
    ["Barbarian/Raging"] = Of("Rage", SWITCH),
    ["Barbarian/Reckless"] = Of("Reckless Attack", SWITCH),
    ["Cleric/Turn Undead"] = Of("Channel Divinity", "the second Channel Divinity effect"),
    ["Ranger/Hunter's Mark: damage"] = Of("Favored Enemy", "the spell's extra damage die, clicked on a hit"),
    ["Monk/Unarmed Strike"] = Of("Martial Arts", "the attack Martial Arts gives, as something to click"),
    ["Monk/Flurry of Blows"] = Of("Monk's Focus", PART),
    ["Monk/Patient Defense"] = Of("Monk's Focus", PART),
    ["Monk/Step of the Wind"] = Of("Monk's Focus", PART),
    ["Paladin/Divine Smite"] = Of("Paladin's Smite", "the spell cast with a slot; the feature's own entry is the free casting"),
    ["Demon Hunter/Double Jump"] = Of("Soul Fragments", PART),
    ["Demon Hunter/Soul Cleave"] = Of("Soul Fragments", PART),
    ["Demon Hunter/Disrupt"] = Of("Illidari Knowledge", PART),
    ["Demon Hunter/Warglaive Mastery"] = Of("Illidari Knowledge", PART),
    ["Demon Hunter/Metamorphosis: Devourer"] = { spell = "metamorphosis", why = "the spell's three benefits, each a switch" },
    ["Demon Hunter/Metamorphosis: Havoc"] = { spell = "metamorphosis", why = "the spell's three benefits, each a switch" },
    ["Demon Hunter/Metamorphosis: Vengeance"] = { spell = "metamorphosis", why = "the spell's three benefits, each a switch" },
    ["Circle of the Moon/Bear Form"] = Of("Circle Forms", FORMS),
    ["Circle of the Moon/Bear Form active"] = Of("Circle Forms", FORMS),
    ["Circle of the Moon/Cat Form"] = Of("Circle Forms", FORMS),
    ["Circle of the Moon/Cat Form active"] = Of("Circle Forms", FORMS),
    ["Circle of the Moon/Frenzied Regeneration"] = Of("Circle Forms", FORMS),
    ["Circle of the Moon/Leave form"] = Of("Circle Forms", FORMS),
    ["Circle of the Moon/Mangle"] = Of("Circle Forms", FORMS),
    ["Circle of the Moon/Pounce"] = Of("Circle Forms", FORMS),
    ["Circle of the Moon/Pounce: with advantage"] = Of("Circle Forms", FORMS),
    ["Circle of the Moon/Primal Wrath"] = Of("Circle Forms", FORMS),
    ["Circle of the Stars/Archer"] = Of("Starry Form", PART),
    ["Circle of the Stars/Chalice"] = Of("Starry Form", PART),
    ["Circle of the Stars/Dragon"] = Of("Starry Form", PART),
    ["Draconic Sorcery/Draconic Scales"] = Of("Draconic Resilience", "its Armor Class half, a passive to switch off in armor"),
    ["Beast Master/Beast's Strike"] = Of("Primal Companion", "the companion's attack"),
    ["Beast Master/Beast's Strike: charge"] = Of("Primal Companion", "the land beast's charge"),
    ["Warrior of Mystic Brews/Redirect Attack"] = Of("Tipsy Sway", PART),
    ["Discipline Domain/Holy Bolt: extra bolt"] = Of("Ultimate Penitence", "the extra bolts a spell slot adds"),
    ["Shadow Domain/Dispersed"] = Of("Dispersion", SWITCH),
    ["Soulknife/Psychic Blade (bonus action)"] = Of("Psychic Blades", "the second blade"),
    ["Soulknife/Psi-Bolstered Knack"] = Of("Psionic Power", PART),
    ["Soulknife/Psychic Whispers"] = Of("Psionic Power", PART),
    ["Soulknife/Psychic Teleportation"] = Of("Soul Blades", PART),
    ["Swashbuckler/Cunning Strike: Goad"] = Of("Panache", "its Cunning Strike option, named like the others"),
    ["Swashbuckler/Cunning Strike: Awe"] = Of("Panache", "its Cunning Strike option, named like the others"),
    ["Swashbuckler/Cunning Strike: Invigorate"] = Of("Dashing Strikes", "its Cunning Strike option, named like the others"),
    ["Swashbuckler/Cunning Strike: Parrying Stance"] = Of("Dashing Strikes", "its Cunning Strike option, named like the others"),
    ["Path of the Spiritual Guardian/Spirit Strike"] = Of("Spiritual Protectors", "its Strike option's damage"),
    ["Rogue/Cunning Strike: Knock Out"] = Of("Devious Strikes", PART),
    ["Rogue/Cunning Strike: Obscure"] = Of("Devious Strikes", PART),
}

-- Differences left as they are, by the id the comparison prints.
Names.ALLOW = {
    ["HUNTER L6 site feature Pet Specialization"] = "only a Beast Master gets it, in place of Roving, so it is with that subclass's features and depends on the pet family chosen: checked in Names.Custom",
    ["MONK class tools"] = "a Monk chooses one kind of artisan's tools or a musical instrument: the addon has no list for that choice, the tool is ticked by hand (Data/Tools.lua says so)",
    ["DRUID L2 prepared spell find familiar in text only"] = "Wild Companion casts Find Familiar with a Wild Shape use or a slot; its text doesn't make the spell always prepared (the site's spell index files it so), and the ability is the casting",
}

-- Hit points a level's sheet has on top of the hit dice (Constitution is 10), each a
-- rule of its own.
function Names.ExtraHP(sheet, level)
    -- Draconic Resilience: 3 more at level 3 and 1 more each level after
    if sheet.subclass == "Draconic Sorcery" and level >= 3 then return level end
    -- Primal Champion: Constitution +4 at level 20, so +2 hit points a level
    if R.CLASSES[sheet.class].base == "Barbarian" and level == 20 then return 2 * level end
    return 0
end

-- The spell levels a Warlock chooses a Mystic Arcanum spell for, as "6,7".
function Names.Arcanum(sheet, level)
    local levels = {}
    for spellLevel = 6, 9 do
        if ns.SheetPickLimit(sheet, "arcanum" .. spellLevel) == 1 then levels[#levels + 1] = spellLevel end
    end
    return table.concat(levels, ",")
end

-- Fighting Style picks that come from a subclass, not from the class's own feature.
function Names.SubclassStyles(sheet)
    local count = 0
    for _, slot in ipairs(ns.StyleSlots(sheet)) do if slot.slot == 2 then count = count + 1 end end
    return count
end

-- Comparisons that need a choice made first.
function Names.Custom(C)
    -- A Beast Master Hunter: no Roving, and from level 6 the Pet Specialization of the
    -- chosen family; any other Hunter keeps Roving.
    local function Has(sheet, name)
        for _, list in ipairs({ sheet.abilities, sheet.passives }) do
            for _, entry in ipairs(list) do if entry.name == name then return true end end
        end
        return false
    end
    local seen = {}
    for _, family in ipairs(R.PET_FAMILY_ORDER) do
        local spec = R.PET_SPECS[R.PET_FAMILIES[family].spec]
        if not seen[spec] then
            seen[spec] = true
            for _, level in ipairs({ 5, 6 }) do
                local sheet = C.Build("HUNTER", "Beast Master", "Beast Mastery", level)
                sheet.featureOptions[R.PET_FEATURE] = family
                ns.ApplyGrants(sheet) -- again, with the family chosen
                sheet = C.Use(sheet)
                C.Same(("HUNTER/Beast Master L%d Pet Specialization: %s"):format(level, spec), tostring(Has(sheet, "Pet Specialization: " .. spec)), tostring(level == 6))
                C.Same(("HUNTER/Beast Master L%d Roving"):format(level), tostring(Has(sheet, "Roving")), "false")
            end
        end
    end
    C.Same("HUNTER/Beast Master pet specializations", (seen.Cunning and 1 or 0) + (seen.Ferocity and 1 or 0) + (seen.Tenacity and 1 or 0), 3)
end
