-- What a spell's dice depend on beyond the slot (Actions/SpellDiceExtras.lua):
--   R.SPELL_VARIANTS   the casting asks first what the target is, or which option:
--                      more = dice added, sides = another die, or a roll of another
--                      kind (kind, count, sides, dice)
--   R.EXPLODING_SPELLS a die at its highest adds another of the same, as many times as
--                      the spellcasting modifier
--   R.SPELL_DICE_SPLIT dice that are of two damage types, or darts that can each go
--                      elsewhere, are told apart in the announcement
local _, ns = ...
local R = ns.Rules

R.SPELL_VARIANTS = {
    ["Divine Smite"] = { title = "Divine Smite: what did you hit?",
        { label = "A fiend or an undead", more = 1 }, { label = "Another creature" } },
    ["Rune Strike"] = { title = "Rune Strike: what did you hit?",
        { label = "A celestial", more = 1 }, { label = "Another creature" } },
    ["Toll the Dead"] = { title = "Toll the Dead: is the target missing hit points?",
        { label = "Yes: d12s", sides = 12 }, { label = "No: d8s" } },
    ["Living Flame"] = { title = "Living Flame: which flames?",
        { label = "Searing Flames: a spell attack for fire damage" },
        { label = "Healing Flames: healing, with no attack roll", kind = "NONE", count = 2, sides = 6, dice = "HEALING" } },
}

R.EXPLODING_SPELLS = { ["Sorcerous Burst"] = true, ["Soul Reap"] = true }

-- { first = dice of the first type (doubled on a critical hit), or half = true,
--   names = { first type, second type } }, or darts = 1: each die plus that.
R.SPELL_DICE_SPLIT = {
    ["Hand of Gul'dan"] = { half = true, names = { "fire", "necrotic" } },
    ["Throw Glaive"] = { first = 1, names = { "slashing", "fire" } },
    ["Magic Missile"] = { darts = 1 },
}

-- Steel Wind Strike attacks up to five creatures, each with its own roll.
if R.SPELLS["Steel Wind Strike"] then R.SPELLS["Steel Wind Strike"].hits = 5 end
