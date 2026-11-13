-- Where a World of Warcraft class differs from the Player's Handbook class it uses.
-- Keyed by the class key in Classes.lua.
--   remove       base class features this class doesn't get
--   removePools  base class resources this class doesn't get
--   features     features it gets instead or in addition (same form as Features.lua)
--   pools        resources it gets; a pool with `stat` has  flat + that ability's
--                modifier  uses, never fewer than `min`
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local Passive, Ability, Spend, Dice = Kit.Passive, Kit.Ability, Kit.Spend, Kit.Dice

R.CLASS_OVERRIDES = {
    -- A Paladin whose healing touch and radiant smites become necrotic power.
    DEATHKNIGHT = {
        remove = { "Lay on Hands", "Divine Smite", "Radiant Strikes", "Restoring Touch" },
        removePools = { "Lay on Hands" },
        pools = { { name = "Death Coil Dice", flat = 1, stat = "CHA", min = 1 } },
        features = {
            Passive(1, "Undead", "Your creature type is Undead."),
            Ability(1, "Death Coil", "Bonus action, 60 feet. The target makes a Constitution save: necrotic damage equal to the roll, half on a success. An undead target can be healed by the roll instead. Each click spends one die; you can spend up to your Charisma modifier at once.",
                { Spend("Death Coil Dice"), Dice(1, 8) }),
            Passive(2, "Runic Smite", "You always have Rune Strike prepared and can cast it once per long rest without a slot."),
            Passive(11, "Runic Strikes", "Your melee weapon and unarmed hits deal 1d8 extra necrotic damage."),
            Passive(14, "Improved Death Coil", "Death Coil deals extra necrotic damage equal to your Charisma modifier, even on a successful save, and heals undead for more."),
        },
    },
    -- A Ranger with fel sight.
    DEMONHUNTER = {
        remove = { "Feral Senses" },
        features = {
            Passive(2, "Void Warrior", "In place of a Fighting Style feat you can take the Void Warrior option, which grants void cantrips."),
            Passive(18, "Improved Spectral Sight", "Truesight out to 30 feet."),
        },
    },
    -- A Barbarian who plants totems.
    SHAMAN = {
        features = {
            Passive(3, "Totems", "Bonus action: plant a totem within 10 feet that aids you and your allies. You know the Earthbind, Primal Knowledge, Tremor and Wind Rush totems."),
        },
    },
}

-- Subclasses that only these classes use, added to the shared subclass tables.
R.SUBCLASS_POOLS["Demon Hunter"] = {
    { name = "Soul Fragments", from = 3, flat = 0, stat = "WIS", min = 1 },
}

R.SUBCLASS_FEATURES["Oath of the Ebon Blade"] = {
    Passive(3, "Oath of the Ebon Blade Spells", "Your oath and the rune on your weapon give you extra spells at certain levels. They are always prepared."),
    Passive(3, "Runeforging", "After a long rest, inscribe a Blood, Frost or Unholy rune on a melee weapon you hold. The rune sets your specialization and can be changed when you gain a level."),
    Ability(3, "Runic Power", "Right after casting Rune Strike. Gain a benefit from your rune: Blood heals you by the necrotic damage dealt, Frost coats your weapon in ice, Unholy spreads disease.",
        { Spend("Channel Divinity") }),
    Passive(7, "Aura of Deathly Endurance", "You and allies in your Aura of Protection resist cold, necrotic and psychic damage."),
    Passive(15, "Runic Mastery", "Once per long rest, invoke a stronger power of the rune on your weapon."),
    Passive(20, "Aspect of the Horsemen", "Bonus action, once per long rest or by spending a 5th-level slot: for 10 minutes you take on the might of the Four Horsemen."),
}

R.SUBCLASS_FEATURES["Demon Hunter"] = {
    Passive(3, "Demon Hunter Spells", "You gain extra spells at certain levels, some shared by all demon hunters and some from your specialization. They are always prepared."),
    Passive(3, "Soul Fragments", "After a long rest you hold soul fragments equal to your Wisdom modifier. They fuel your demon hunter powers."),
    Ability(3, "Double Jump", "Cast Feather Fall or Jump without a spell slot.", { Spend("Soul Fragments") }),
    Ability(3, "Soul Cleave", "Once per turn, in place of one attack: creatures within 10 feet make a Dexterity save against the roll.",
        function(level) return { Spend("Soul Fragments"), Dice(level >= 15 and 2 or 1, 12, "WIS") } end),
    Passive(3, "Spectral Sight", "Blindsight out to 10 feet."),
    Passive(7, "Torment", "The creature marked by your Hunter's Mark has disadvantage attacking anyone but you, and once per turn your hits on it add an extra effect."),
    Ability(11, "Disrupt", "Cast Counterspell as a reaction without a slot.", { Spend("Soul Fragments", 2) }),
    Ability(11, "Warglaive Mastery", "Bonus action: cast Throw Glaive without a slot.", { Spend("Soul Fragments") }),
    Passive(11, "Illidari Knowledge", "You learn further ways to spend soul fragments."),
    Passive(15, "Soul Shatter", "Soul Cleave rolls 2d12, and when you roll initiative with no soul fragments you regain one."),
}
