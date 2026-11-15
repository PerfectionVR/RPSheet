-- Advantage on saving throws that the sheet can't simply switch on, because it depends
-- on what the save is against (being charmed, a spell) or covers only some abilities.
-- Each entry names what gives it, as it is called on the sheet: a species trait, a
-- feat or blessing among the passives, a magic item, an invocation, or the gift of a
-- loyal companion ("<Family> companion").
--   about          what the save must be against; the sheet asks when a save is rolled
--   saves          the abilities it covers; every one when left out
--   concentration  true: only the save to keep a spell, which the sheet rolls itself
-- An entry with neither `about` nor `concentration` always counts.
local _, ns = ...
local R = ns.Rules

local CHARMED, FRIGHTENED, POISONED = "being Charmed", "being Frightened", "being Poisoned"
local SPELL, MAGIC = "a spell", "a spell or other magic"

R.SAVE_ADVANTAGES = {
    -- Species traits
    { from = "Gnomish Cunning", saves = { "INT", "WIS", "CHA" } },
    { from = "Dwarven Resilience", about = { POISONED } },
    { from = "Earthen Resilience", about = { POISONED } },
    { from = "Fey Ancestry", about = { CHARMED } },
    { from = "Will of the Forsaken", about = { CHARMED, FRIGHTENED } },
    { from = "Mechanical Nature", about = { "being Paralyzed", POISONED } },
    -- Feats and invocations
    { from = "Arathi Heritage", about = { CHARMED } },
    { from = "War Caster", concentration = true },
    { from = "Eldritch Mind", concentration = true },
    -- Companion creatures
    { from = "Dragonkin companion", about = { FRIGHTENED } },
    { from = "Elemental companion", about = { "Exhaustion" } },
    -- Renown blessings
    { from = "Blessing of Argent Will", about = { "being Charmed by a fiend or an undead" } },
    { from = "Wildguard Blessing", about = { SPELL } },
    -- Magic items, while they are worn or held (and attuned where they need it)
    { from = "Mantle of Spell Resistance", about = { SPELL } },
    { from = "Ring of Spell Turning", about = { SPELL } },
    { from = "Staff of the Magi", about = { SPELL } },
    { from = "Holy Avenger", about = { MAGIC } },
    { from = "Spellguard Shield", about = { MAGIC } },
    { from = "Necklace of Adaptation", about = { POISONED } },
    { from = "Periapt of Health", about = { POISONED } },
}
