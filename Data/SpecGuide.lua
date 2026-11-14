-- Suggested choices for each World of Warcraft specialization. A specialization has
-- no rules of its own: it is a guide to which subclass, Fighting Style, weapons and
-- spells fit that way of playing a class. The wizards show these as suggestions and
-- pre-select the ones that are a single pick; the player can always choose otherwise.
--   subclass   the subclass to take at level 3
--   style      the Fighting Style to take, when one is suggested
--   { level, "suggestion" }  shown when the character reaches that level
local _, ns = ...
local R = ns.Rules

R.SPEC_GUIDE = {
    DEATHKNIGHT = {
        Blood = { style = "Interception", { 3, "Weapon Mastery: Greataxe, Greatsword or Maul. Fighting Style: Interception." } },
        Frost = { style = "Two-Weapon Fighting", { 3, "Weapon Mastery: Light Hammer or Scimitar. Fighting Style: Two-Weapon Fighting." } },
        Unholy = { style = "Great Weapon Fighting", { 3, "Weapon Mastery: Greataxe, Greatsword or Maul. Fighting Style: Great Weapon Fighting." } },
    },
    DEMONHUNTER = {
        Devourer = { style = "Void Warrior", { 1, "Weapon Mastery: Handaxe, Scimitar or Shortsword." }, { 2, "Fighting Style: Void Warrior, with the Chill Touch and Mind Sliver cantrips." } },
        Havoc = { style = "Two-Weapon Fighting", { 1, "Weapon Mastery: Handaxe, Scimitar or Shortsword." }, { 2, "Fighting Style: Two-Weapon Fighting." } },
        Vengeance = { style = "Interception", { 1, "Weapon Mastery: Battleaxe or Longsword." }, { 2, "Fighting Style: Interception." } },
    },
    DRUID = {
        Balance = { subclass = "Circle of the Stars",
            { 1, "Primal Order: Magician. Cantrips: Druidcraft, Starry Wisp, Wrath. Spells: Cure Wounds, Entangle, Moonfire, Thunderwave." },
            { 3, "Subclass: Circle of the Stars. Your Starry Form can look like a moonkin." } },
        Feral = { subclass = "Circle of the Moon",
            { 1, "Primal Order: Warden. Cantrips: Druidcraft, Poison Spray. Spells: Cure Wounds, Entangle, Speak with Animals, Thunderwave." },
            { 3, "Subclass: Circle of the Moon. Use a cat form for Wild Shape." } },
        Guardian = { subclass = "Circle of the Moon",
            { 1, "Primal Order: Warden. Cantrips: Druidcraft, Thorn Whip. Spells: Entangle, Healing Word, Speak with Animals, Thunderwave." },
            { 3, "Subclass: Circle of the Moon. Use a bear form for Wild Shape." } },
        Restoration = { subclass = "Circle of the Land",
            { 1, "Primal Order: Magician. Cantrips: Druidcraft, Produce Flame, Spare the Dying. Spells: Cure Wounds, Entangle, Goodberry, Healing Word." },
            { 3, "Subclass: Circle of the Land." } },
    },
    EVOKER = {
        Augmentation = { subclass = "Draconic Sorcery",
            { 3, "Cantrips: Elementalism, Light, Sorcerous Burst, Thunderclap. Take the Augmentation spells of the Evoker." }, { 6, "Elemental Affinity: fire." } },
        Devastation = { subclass = "Draconic Sorcery",
            { 3, "Cantrips: Elementalism, Light, Ray of Frost, Sorcerous Burst. Take the Devastation spells of the Evoker." }, { 6, "Elemental Affinity: cold or fire." } },
        Preservation = { subclass = "Draconic Sorcery",
            { 3, "Cantrips: Blade Ward, Elementalism, Light, Sorcerous Burst. Take the Preservation spells of the Evoker." }, { 6, "Elemental Affinity: lightning or poison." } },
    },
    HUNTER = {
        ["Beast Mastery"] = { subclass = "Beast Master", style = "Archery",
            { 1, "Spells: Ensnaring Strike, Speak with Animals. Weapon Mastery: two of Heavy Crossbow, Longbow, Musket." },
            { 2, "Fighting Style: Archery." }, { 3, "Subclass: Beast Master." } },
        Marksmanship = { subclass = "Hunter", style = "Archery",
            { 1, "Spells: Cure Wounds, Ensnaring Strike. Weapon Mastery: two of Heavy Crossbow, Longbow, Musket." },
            { 2, "Fighting Style: Archery." }, { 3, "Subclass: Hunter." } },
        Survival = { subclass = "Beast Master", style = "Great Weapon Fighting",
            { 1, "Spells: Cure Wounds, Ensnaring Strike. Weapon Mastery: two of Glaive, Halberd, Pike." },
            { 2, "Fighting Style: Great Weapon Fighting." }, { 3, "Subclass: Beast Master." } },
    },
    MAGE = {
        Arcane = { subclass = "Evoker", { 1, "Cantrips: Light, Mage Hand, Thunderclap. Spellbook: Detect Magic, Feather Fall, Mage Armor, Magic Missile, Shield, Thunderwave." }, { 3, "Subclass: Evoker." } },
        Fire = { subclass = "Evoker", { 1, "Cantrips: Light, Mage Hand, Fire Bolt. Spellbook: Burning Hands, Detect Magic, Feather Fall, Mage Armor, Shield, Thunderwave." }, { 3, "Subclass: Evoker." } },
        Frost = { subclass = "Evoker", { 1, "Cantrips: Light, Mage Hand, Ray of Frost. Spellbook: Detect Magic, Feather Fall, Frost Nova, Ice Knife, Mage Armor, Shield." }, { 3, "Subclass: Evoker." } },
    },
    MONK = {
        Brewmaster = { subclass = "Warrior of Mystic Brews", { 3, "Subclass: Warrior of Mystic Brews." } },
        Mistweaver = { subclass = "Warrior of Mercy", { 3, "Subclass: Warrior of Mercy." } },
        Windwalker = { subclass = "Warrior of the Open Hand", { 3, "Subclass: Warrior of the Open Hand." } },
    },
    PALADIN = {
        Holy = { subclass = "Oath of the Holy", style = "Blessed Warrior",
            { 1, "Spells: Cure Wounds, Shield of Faith. Weapon Mastery: one of Flail, Longsword, Morningstar, Warhammer." },
            { 2, "Fighting Style: Blessed Warrior, with the Sacred Flame and Spare the Dying cantrips." }, { 3, "Subclass: Oath of the Holy." } },
        Protection = { subclass = "Oath of Devotion",
            { 1, "Spells: Compelled Duel, Searing Smite. Weapon Mastery: one of Battleaxe, Flail, Longsword, Morningstar, Warhammer." },
            { 2, "Fighting Style: Interception or Protection." }, { 3, "Subclass: Oath of Devotion." } },
        Retribution = { subclass = "Oath of Vengeance", style = "Great Weapon Fighting",
            { 1, "Spells: Heroism, Wrathful Smite. Weapon Mastery: one of Greataxe, Greatsword, Maul." },
            { 2, "Fighting Style: Great Weapon Fighting." }, { 3, "Subclass: Oath of Vengeance." } },
    },
    PRIEST = {
        Discipline = { subclass = "Discipline Domain",
            { 1, "Divine Order: Thaumaturge. Cantrips: Guidance, Resistance, Thaumaturgy, Word of Radiance. Spells: Cure Wounds, Guiding Bolt, Sanctuary, Shield of Faith." },
            { 3, "Subclass: Discipline Domain." } },
        Holy = { subclass = "Life Domain",
            { 1, "Divine Order: Thaumaturge. Cantrips: Guidance, Light, Sacred Flame, Spare the Dying. Spells: Bless, Cure Wounds, Healing Word, Purify Food and Drink." },
            { 3, "Subclass: Life Domain." } },
        Shadow = { subclass = "Shadow Domain",
            { 1, "Divine Order: Thaumaturge. Cantrips: Mending, Resistance, Thaumaturgy, Toll the Dead. Spells: Bane, Command, Healing Word, Shadow Word: Pain." },
            { 3, "Subclass: Shadow Domain." } },
    },
    ROGUE = {
        Assassination = { subclass = "Assassin", { 1, "Weapon Mastery: Dagger and Shortbow." }, { 3, "Subclass: Assassin." }, { 5, "Use the Poison option of Cunning Strike often." } },
        Outlaw = { subclass = "Swashbuckler", { 1, "Weapon Mastery: Dagger and Rapier." }, { 3, "Subclass: Swashbuckler." } },
        Subtlety = { subclass = "Soulknife", { 1, "Weapon Mastery: Dagger and Mace." }, { 3, "Subclass: Soulknife." } },
    },
    SHAMAN = {
        Elemental = { subclass = "Path of the Elements", { 1, "Weapon Mastery: two of Battleaxe, Longsword, Mace." }, { 3, "Subclass: Path of the Elements." } },
        Enhancement = { subclass = "Path of the Spiritual Guardian", { 1, "Weapon Mastery: two of Handaxe, Light Hammer, Scimitar, Shortsword." }, { 3, "Subclass: Path of the Spiritual Guardian." } },
        Restoration = { subclass = "Path of the World Tree", { 1, "Weapon Mastery: two of Flail, Mace, Warhammer." }, { 3, "Subclass: Path of the World Tree." } },
    },
    WARLOCK = {
        Affliction = { subclass = "Great Old One Patron",
            { 1, "Invocation: Pact of the Legion. Cantrips: Eldritch Blast, Poison Spray. Spells: Hex, Witch Bolt." },
            { 2, "Invocations: Agonizing Blast, Curse of Corruption." }, { 3, "Subclass: Great Old One Patron." } },
        Demonology = { subclass = "Fiend Patron",
            { 1, "Invocation: Pact of the Legion. Cantrips: Eldritch Blast, Toll the Dead. Spells: Arms of Hadar, Hex." },
            { 2, "Invocations: Health Funnel, Repelling Blast." }, { 3, "Subclass: Fiend Patron." } },
        Destruction = { subclass = "Fiend Patron",
            { 1, "Invocation: Pact of the Legion. Cantrips: Eldritch Blast, Thunderclap. Spells: Hellish Rebuke, Hex." },
            { 2, "Invocations: Agonizing Blast, Repelling Blast." }, { 3, "Subclass: Fiend Patron." } },
    },
    WARRIOR = {
        Arms = { subclass = "Battle Master", style = "Great Weapon Fighting",
            { 1, "Fighting Style: Great Weapon Fighting. Weapon Mastery: include Greataxe, Greatsword or Maul." },
            { 3, "Subclass: Battle Master. Maneuvers to consider: Disarming Attack, Distracting Strike, Pushing Attack, Sweeping Attack, Trip Attack." } },
        Fury = { subclass = "Champion", style = "Two-Weapon Fighting",
            { 1, "Fighting Style: Two-Weapon Fighting. Weapon Mastery: include Scimitar." }, { 3, "Subclass: Champion." } },
        Protection = { subclass = "Battle Master",
            { 1, "Fighting Style: Interception or Protection. Weapon Mastery: include Battleaxe, Longsword or Morningstar." },
            { 3, "Subclass: Battle Master. Maneuvers to consider: Bait and Switch, Goading Attack, Maneuvering Attack, Parry." } },
    },
}

-- The guide for a class key and specialization, or nil.
function R.SpecGuide(classKey, spec)
    return (R.SPEC_GUIDE[classKey] or {})[spec]
end

-- Suggestions for exactly `level`, or for every level from `from` up to it.
function R.SpecSuggestions(classKey, spec, level, from)
    local lines = {}
    for _, item in ipairs(R.SpecGuide(classKey, spec) or {}) do
        if item[1] <= level and item[1] >= (from or level) then
            lines[#lines + 1] = from and ("Level %d: %s"):format(item[1], item[2]) or item[2]
        end
    end
    return lines
end
