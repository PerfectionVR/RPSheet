-- Subclass features of the Priest (Cleric). See SubclassFeatures.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus
local AlwaysPrepared = ns.SubclassKit.AlwaysPrepared
local F = R.SUBCLASS_FEATURES

F["Discipline Domain"] = {
    AlwaysPrepared("Discipline", { { 3, "Arcane Vigor, Guiding Bolt, Magic Weapon, Shield of Faith" }, { 5, "Prayer of Mending, Protection from Energy" }, { 7, "Guardian of Faith, Stoneskin" }, { 9, "Circle of Power, Destructive Wave" } }),
    Passive(3, "Atonement", "Creatures you heal with a spell of level 1 or higher are blessed until the end of your next turn. When you then damage a creature with a slotted spell, each blessed creature regains hit points equal to that slot's level."),
    Ability(3, "Holy Bolt", function(level)
        return "Bonus action. A ranged spell attack against a creature within 60 feet: radiant damage on a hit, and a creature you choose within 60 feet is healed by the second roll."
            .. (level >= 17 and " You can teleport 30 feet first, and spend a spell slot to hurl as many more bolts as its level: use Holy Bolt: extra bolt for each, and take the slot off by hand." or "")
    end, { Spend("Channel Divinity"), Roll("SPELL", "WIS"), Dice(2, 10, "WIS"), Dice(1, 10, "WIS", "HEALING") }),
    Ability(17, "Holy Bolt: extra bolt", "One of the extra bolts a spell slot adds to Holy Bolt. It costs no Channel Divinity.",
        { Roll("SPELL", "WIS"), Dice(2, 10, "WIS"), Dice(1, 10, "WIS", "HEALING") }),
    Ability(6, "Luminous Barrier", "Bonus action. Each creature blessed by your Atonement gains temporary hit points equal to the amount shown (your level + Wisdom modifier), and resists all damage while it has them.",
        function(level) return { Spend("Channel Divinity"), Dice(0, 4, "WIS", "OTHER", level) } end),
    Passive(17, "Ultimate Penitence", "Holy Bolt lets you teleport up to 30 feet first, and you can spend a spell slot to fire additional bolts."),
}
F["Life Domain"] = {
    AlwaysPrepared("Life Domain", { { 3, "Aid, Bless, Cure Wounds, Lesser Restoration" }, { 5, "Mass Healing Word, Revivify" }, { 7, "Aura of Life, Death Ward" }, { 9, "Greater Restoration, Mass Cure Wounds" } }),
    Passive(3, "Disciple of Life", "A slotted spell that heals a creature heals 2 + the slot's level more on the turn you cast it."),
    Ability(3, "Preserve Life", "Magic action. Restore the hit points shown (five times your level), divided among Bloodied creatures within 30 feet, up to half their maximum each.",
        function(level) return { Spend("Channel Divinity"), Dice(0, 4, "", "HEALING", 5 * level) } end),
    Passive(6, "Blessed Healer", "When a slotted spell of yours heals others, you regain 2 + the slot's level yourself."),
    Passive(17, "Supreme Healing", "When you would roll dice to heal with a spell or Channel Divinity, use the highest possible result instead."),
}
F["Shadow Domain"] = {
    AlwaysPrepared("Shadow", { { 3, "Crown of Madness, Dissonant Whispers, Mind Spike, Shadow Word: Pain" }, { 5, "Summon Undead, Vampiric Touch" }, { 7, "Evard's Black Tentacles, Psychic Horror" }, { 9, "Dominate Person, Void Eruption" } }),
    Limited(3, "Devouring Plague", "When a creature you can see within 30 feet fails a saving throw: it takes the roll as necrotic damage and you regain the same amount. Uses equal to your Wisdom modifier per long rest.",
        { stat = "WIS" }, { Dice(1, 10, "", "DRAIN") }),
    Ability(3, "Shadowform", "Bonus action. For 1 minute you take a shadowy form: Hide as a bonus action in dim light or darkness, and add 1d6 to one damage roll of a slotted spell that deals psychic or necrotic damage. It ends early if you dismiss it, are incapacitated, or deal radiant damage with a spell. Switches Shadowform active on.",
        { Spend("Channel Divinity"), SwitchOn("Shadowform active") }),
    Passive(3, "Shadowform active", "Switch on while you are in Shadowform (1 minute). Being incapacitated or a rest switches it off; switch it off yourself when you dismiss it or deal radiant damage with a spell.", nil, true),
    Ability(3, "Void Empowerment", "In Shadowform: the extra damage for a slotted spell that deals psychic or necrotic damage.", { Dice(1, 6) }),
    Limited(6, "Dispersion", "Reaction when an attack hits you: until the end of your next turn you resist all damage, fly 40 feet, and can't act. Afterwards you can spend up to half your Hit Dice to heal. Once per short or long rest. Switches Dispersed on.", 1, { SwitchOn("Dispersed") }, "ALL"),
    Passive(6, "Dispersed", "Switch on after Dispersion, until the end of your next turn: you resist all damage.", nil,
        { startsOff = true, resist = R.AllDamage() }),
    Passive(17, "Vampiric Embrace", "While in Shadowform, whenever you roll the d6 of extra spell damage, a creature within 30 feet regains that many hit points."),
}
