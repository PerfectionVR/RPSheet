-- The choices a feat contains, on top of the ability it raises: a damage type, a
-- skill, tools, spells. They are asked for in the level dialog and applied by
-- Sheet/FeatChoices.lua, Sheet/FeatGrants.lua and Sheet/FeatSpells.lua.
--
-- R.FEATS[name].choices = { {
--     key       what the pick is stored under
--     title     what the dialog calls one pick ("Cantrip")
--     count     how many picks: a number (1 if left out) or a function of the level
--     from      the options: a list, or a function of the picks made so far for this
--               feat ({ [key] = { [slot] = value } }), for a choice that follows another
--     kind      what a pick does: "skill" (proficiency, or expertise if already
--               proficient), "tool" (proficiency), "spell" (always prepared); without
--               it the pick is only shown in the feat's text
--     once      a "spell" that is also cast once per long rest without a slot
--     distinct  true when the feat taken again must pick something else here
--     text      wording for the feat's text, with %s for the picks
--     desc      tooltip in the dialog
-- }, ... }
-- Other fields a feat gets here:
--   named      the choice a name in brackets settles: "Magic Initiate (Cleric)"
--   spells     spells it always gives: { { name =, once = }, ... }
--   castStat   the ability its spells use: "raised" (the one the feat raises) or the
--              key of the choice that names it
--   allSkills  true if it makes every skill proficient
local _, ns = ...
local R = ns.Rules

local MIND = { R.STAT_NAMES.INT, R.STAT_NAMES.WIS, R.STAT_NAMES.CHA }

-- The names in `names` that are spells of `level` in the data, sorted.
local function Spells(names, level)
    local found, seen = {}, {}
    for _, name in ipairs(names or {}) do
        local spell = R.SPELLS[name]
        if spell and spell.level == level and not seen[name] then
            seen[name] = true
            found[#found + 1] = name
        end
    end
    table.sort(found)
    return found
end

local function Give(name, fields)
    local feat = R.FEATS[name]
    if not feat then return end
    for key, value in pairs(fields) do feat[key] = value end
end

---------------------------------------------------------------------------
-- Spells
---------------------------------------------------------------------------
local CLASS_SPELLS = {}
for _, class in ipairs({ "Cleric", "Druid", "Wizard" }) do
    CLASS_SPELLS[class] = { [0] = Spells(R.SPELL_LISTS[class], 0), [1] = Spells(R.SPELL_LISTS[class], 1) }
end
-- The spells of a level on the list picked for the feat.
local function OfList(level)
    return function(picks)
        local list = CLASS_SPELLS[picks.list and picks.list[1] or ""]
        return list and list[level] or {}
    end
end

local ONCE = "Always prepared. You cast it once per long rest without a spell slot, and with your slots as often as they allow."

Give("Magic Initiate", {
    named = "list", castStat = "ability",
    choices = {
        { key = "list", title = "Spell list", from = { "Cleric", "Druid", "Wizard" }, distinct = true,
            desc = "The class list this feat's spells come from. Taking the feat again needs another list." },
        { key = "ability", title = "Spellcasting ability", from = MIND,
            desc = "The ability this feat's spells use for their attack rolls and save DC." },
        { key = "cantrips", title = "Cantrip", count = 2, kind = "spell", from = OfList(0),
            desc = "A cantrip from the list. When you gain a level you may swap one of this feat's spells for another." },
        { key = "spell", title = "1st-level spell", kind = "spell", once = true, from = OfList(1), desc = ONCE },
    },
})

-- 1st-level spells by school, for the feats that offer two schools.
local DIVINATION_ENCHANTMENT = Spells({
    "Animal Friendship", "Bane", "Bless", "Charm Person", "Command", "Compelled Duel", "Comprehend Languages",
    "Detect Evil and Good", "Detect Magic", "Detect Poison and Disease", "Dissonant Whispers", "Heroism", "Hex",
    "Hunter's Mark", "Identify", "Sleep", "Speak with Animals", "Tasha's Hideous Laughter",
}, 1)
local ILLUSION_NECROMANCY = Spells({
    "Color Spray", "Disguise Self", "False Life", "Illusory Script", "Inflict Wounds", "Ray of Sickness", "Silent Image",
    "Wrathful Smite", "Consume Soul", "Entropic Embrace", "Scourge Strike", "Shadow Word: Pain", "Vampiric Blood",
}, 1)
local RITUALS = Spells({
    "Alarm", "Comprehend Languages", "Detect Magic", "Detect Poison and Disease", "Find Familiar", "Identify",
    "Illusory Script", "Purify Food and Drink", "Speak with Animals", "Tenser's Floating Disk", "Unseen Servant",
}, 1)

Give("Fey-Touched", {
    castStat = "raised", spells = { { name = "Misty Step", once = true } },
    choices = { { key = "spell", title = "1st-level divination or enchantment spell", kind = "spell", once = true, from = DIVINATION_ENCHANTMENT, desc = ONCE } },
})
Give("Shadow-Touched", {
    castStat = "raised", spells = { { name = "Invisibility", once = true } },
    choices = { { key = "spell", title = "1st-level illusion or necromancy spell", kind = "spell", once = true, from = ILLUSION_NECROMANCY, desc = ONCE } },
})
Give("Ritual Caster", {
    castStat = "raised",
    choices = { {
        key = "rituals", title = "Ritual spell", kind = "spell", from = RITUALS,
        -- As many as the proficiency bonus.
        count = function(level) return math.ceil(level / 4) + 1 end,
        desc = "A 1st-level ritual spell, always prepared. You have as many as your proficiency bonus.",
    } },
})
Give("Telekinetic", { castStat = "raised", spells = { { name = "Mage Hand" } } })
Give("Telepathic", { castStat = "raised", spells = { { name = "Detect Thoughts", once = true } } })
Give("Inscription Adept", { castStat = "raised", spells = { { name = "Illusory Script", once = true } } })

---------------------------------------------------------------------------
-- Skills and tools
---------------------------------------------------------------------------
local SKILL = "Proficiency in the skill, or expertise if you are proficient in it already."

Give("Keen Mind", {
    choices = { { key = "skill", title = "Skill", kind = "skill", desc = SKILL, from = { "Arcana", "History", "Investigation", "Nature", "Religion" } } },
})
Give("Observant", {
    choices = { { key = "skill", title = "Skill", kind = "skill", desc = SKILL, from = { "Insight", "Investigation", "Perception" } } },
})

local ALL_SKILLS = {}
for _, skill in ipairs(R.SKILLS) do ALL_SKILLS[#ALL_SKILLS + 1] = skill.name end
Give("Boon of Skill", {
    allSkills = true,
    choices = { { key = "expertise", title = "Expertise", kind = "skill", from = ALL_SKILLS, desc = "Expertise in one skill you don't have it in yet." } },
})

local INSTRUMENTS = {}
for _, name in ipairs(R.TOOL_ORDER) do
    if R.TOOLS[name].kind == "INS" then INSTRUMENTS[#INSTRUMENTS + 1] = name end
end
Give("Musician", {
    choices = { { key = "instruments", title = "Instrument", count = 3, kind = "tool", from = INSTRUMENTS, desc = "Proficiency with this instrument." } },
})
Give("Crafter", {
    choices = { {
        key = "tools", title = "Artisan's tools", count = 3, kind = "tool", desc = "Proficiency with this kind of artisan's tools.",
        from = { "Carpenter's Tools", "Leatherworker's Tools", "Mason's Tools", "Potter's Tools", "Smith's Tools", "Tinker's Tools", "Weaver's Tools", "Woodcarver's Tools" },
    } },
})

---------------------------------------------------------------------------
-- Choices that are only shown
---------------------------------------------------------------------------
Give("Elemental Adept", {
    choices = { { key = "damage", title = "Damage type", from = { "Acid", "Cold", "Fire", "Lightning", "Thunder" }, distinct = true,
        desc = "The damage type this feat is for. Taking the feat again needs another type." } },
})
Give("Boon of Energy Resistance", {
    choices = { {
        key = "resist", title = "Resistance", count = 2, text = "Resistance to %s damage",
        from = { "Acid", "Cold", "Fire", "Lightning", "Necrotic", "Poison", "Psychic", "Radiant", "Thunder" },
        desc = "A damage type you resist. Both can be changed after a long rest.",
    } },
})

local MASTERY_WEAPONS = {}
for _, name in ipairs(R.WEAPON_ORDER) do
    if R.WEAPONS[name].mastery then MASTERY_WEAPONS[#MASTERY_WEAPONS + 1] = name end
end
Give("Weapon Master", {
    choices = { { key = "weapon", title = "Weapon kind", from = MASTERY_WEAPONS,
        desc = "The kind of weapon whose mastery property you can use. It has to be one you are proficient with, and can be changed after a long rest." } },
})
