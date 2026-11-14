-- Where a World of Warcraft class differs from the Player's Handbook class it uses.
-- Keyed by the class key in Classes.lua.
--   remove       base class features this class doesn't get
--   removePools  base class resources this class doesn't get
--   features     features it gets instead or in addition (same form as Features.lua)
--   A feature can carry bySpec = { [specialization] = description } to read
--   differently once the specialization is chosen.
--   pools        resources it gets; a pool with `stat` has  flat + that ability's
--                modifier  uses, never fewer than `min`
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local Passive, Ability, Limited, Spend, Dice = Kit.Passive, Kit.Ability, Kit.Limited, Kit.Spend, Kit.Dice
-- (Kit.DC and Kit.Mod are used for save DCs in descriptions.)

R.CLASS_OVERRIDES = {
    -- A Paladin whose healing touch and radiant smites become necrotic power.
    DEATHKNIGHT = {
        remove = { "Lay on Hands", "Paladin's Smite", "Divine Smite", "Radiant Strikes", "Restoring Touch" },
        removePools = { "Lay on Hands" },
        pools = { { name = "Death Coil Dice", flat = 1, stat = "CHA", min = 1 } },
        features = {
            Passive(1, "Undead", "Your creature type is Undead."),
            Ability(1, "Death Coil", function(level, sheet)
                return ("Bonus action, 60 feet. The target makes a Constitution save, DC %d: necrotic damage equal to the roll, half on a success. An undead target can be healed by the roll instead%s. Each click spends one die; you can spend up to your Charisma modifier at once."):format(
                    Kit.DC(sheet, "CHA"), level >= 14 and ", and then regains your level more" or "")
            end, function(level, sheet)
                return { Spend("Death Coil Dice"), Dice(1, 8) }
            end),
            Ability(14, "Improved Death Coil", "Once for each use of Death Coil, however many dice you spent: this much more damage. When it heals an undead, add your level instead.",
                function(_, sheet) return { Dice(0, 4, "", "DAMAGE", math.max(1, Kit.Mod(sheet, "CHA"))) } end),
            Limited(2, "Runic Smite", "You always have Rune Strike prepared. Once per long rest you can cast it without a slot: this is that casting.", 1, { Dice(2, 8) }),
            Passive(11, "Runic Strikes", "Your melee weapon and unarmed hits deal 1d8 extra necrotic damage. The sheet rolls it with every melee attack.",
                nil, { strike = { sides = 8, damage = "necrotic" } }),
            Passive(14, "Improved Death Coil", "Death Coil deals extra necrotic damage equal to your Charisma modifier (at least 1), even on a successful save, and an undead you heal with it regains your level more."),
        },
    },
    -- A Ranger with fel sight.
    DEMONHUNTER = {
        remove = { "Feral Senses" },
        features = {
            Passive(18, "Improved Spectral Sight", "Truesight out to 30 feet. This takes the place of Feral Senses."),
        },
    },
    -- A Barbarian who plants totems.
    SHAMAN = {
        features = {
            Passive(3, "Totems", "Bonus action: plant a totem within 10 feet (AC 10, 1 hit point). It lasts a minute or until you plant another, and pulses out to 30 feet at the end of each of your turns. Each totem is an ability."),
            Ability(3, "Earthbind Totem", "Totem. Each enemy within 30 feet has its speed reduced by 10 feet until the end of your next turn.", {}),
            Ability(3, "Tremor Totem", "Totem. Each ally within 30 feet can't be charmed or frightened until the end of your next turn.", {}),
            Ability(3, "Wind Rush Totem", "Totem. Each ally within 30 feet gains 10 feet of speed until the end of your next turn.", {}),
            Limited(3, "Primal Knowledge Totem", "Totem. Allies within 30 feet can make Acrobatics, Intimidation, Perception, Stealth and Survival checks as Strength checks until the end of your next turn. Once per long rest; spending a Rage use gives it back.", 1),
        },
    },
}

-- Subclasses that only these classes use, added to the shared subclass tables.
R.SUBCLASS_POOLS["Demon Hunter"] = {
    { name = "Soul Fragments", from = 3, flat = 0, stat = "WIS", min = 1, levelBonus = { { 13, 1 }, { 17, 2 } } },
}

-- A Death Knight's rune is its specialization: Blood, Frost or Unholy. Features marked
-- with `spec` appear only with that rune.
local EBON_ALL = { { 3, "Death Grip" }, { 5, "Death and Decay" }, { 9, "Summon Undead" }, { 13, "Freedom of Movement" }, { 17, "Circle of Power" } }
local EBON_RUNE = {
    Blood = { "Vampiric Blood", "Spiritual Weapon", "Leeching Strike", "Evard's Black Tentacles", "Bonestorm" },
    Frost = { "Chains of Ice", "Frostscythe", "Remorseless Winter", "Ice Storm", "Cone of Cold" },
    Unholy = { "Scourge Strike", "Ray of Enfeeblement", "Bestow Curse", "Blight", "Contagion" },
}

R.SUBCLASS_FEATURES["Oath of the Ebon Blade"] = {
    Passive(3, "Oath of the Ebon Blade Spells", function(level, sheet)
        local known = {}
        for index, step in ipairs(EBON_ALL) do
            if level >= step[1] then
                known[#known + 1] = step[2]
                if EBON_RUNE[sheet.spec] then known[#known + 1] = EBON_RUNE[sheet.spec][index] end
            end
        end
        return "Always prepared, and not counted against the number you can prepare: " .. table.concat(known, ", ")
            .. (EBON_RUNE[sheet.spec] and "." or ". Choosing a rune (your specialization) adds more.")
            .. " They are on your spell list already."
    end, nil, { prepared = function(sheet)
        local steps = {}
        for index, step in ipairs(EBON_ALL) do
            local names = step[2]
            if EBON_RUNE[sheet.spec] then names = names .. ", " .. EBON_RUNE[sheet.spec][index] end
            steps[index] = { step[1], names }
        end
        return steps
    end }),
    Passive(3, "Runeforging", function(_, sheet)
        local rune = {
            Blood = "Blood: you gain temporary hit points equal to your Charisma modifier plus your level after a long rest, and whenever you reduce an enemy to 0 hit points.",
            Frost = "Frost: your damage ignores resistance to cold, and the extra attack of a light weapon deals 1d4 more cold damage.",
            Unholy = "Unholy: your damage ignores resistance to necrotic, and with a heavy weapon the first creature you hit each turn takes extra necrotic damage equal to your Charisma modifier.",
        }
        return "After a long rest you inscribe a rune on a melee weapon you hold; it can be changed when you gain a level. The rune is your specialization. "
            .. (rune[sheet.spec] or "Choose Blood, Frost or Unholy as your specialization under Customize.")
    end),
    Ability(3, "Blood Rune", "Temporary hit points from your rune: after a long rest, and whenever you reduce an enemy to 0 hit points.",
        function(level) return { Dice(0, 4, "CHA", "TEMPHP", level) } end),
    Ability(3, "Frost Rune", "Extra cold damage when the extra attack of a light weapon hits.", { Dice(1, 4) }),
    Ability(3, "Unholy Rune", "Extra necrotic damage on the first creature you hit each turn with a heavy weapon.",
        function(_, sheet) return { Dice(0, 4, "", "DAMAGE", math.max(1, Kit.Mod(sheet, "CHA"))) } end),
    Ability(3, "Runic Power", function(_, sheet)
        local rune = {
            Blood = "You regain hit points equal to the necrotic damage your Rune Strike dealt: raise your HP by hand.",
            Frost = "The target and each enemy within 10 feet of it take the roll as cold damage.",
            Unholy = "The target is cursed until the end of your next turn: it subtracts the roll from its next saving throw.",
        }
        return "Right after you cast Rune Strike. " .. (rune[sheet.spec] or "Its effect depends on your rune.")
    end, function(_, sheet)
        local steps = { Spend("Channel Divinity") }
        if sheet.spec == "Frost" then steps[2] = Dice(2, 6) end
        if sheet.spec == "Unholy" then steps[2] = Dice(1, 6, "", "OTHER") end
        return steps
    end),
    Passive(7, "Aura of Deathly Endurance", "You and allies in your Aura of Protection resist cold, necrotic and psychic damage."),
    Limited(15, "Runic Mastery", function(_, sheet)
        local rune = {
            Blood = "Reaction when a creature within 10 feet of you is hit: reduce the damage by the amount shown (your level). You then lose that many hit points.",
            Frost = ("In place of one attack: frost in a 30-foot cone. The roll as cold damage, half on a successful Dexterity save, DC %d."):format(Kit.DC(sheet, "CHA")),
            Unholy = "When you cast Summon Undead it needs no concentration and lasts 1 minute; the spirit gains temporary hit points equal to your level plus Charisma modifier and deals extra necrotic damage once per turn.",
        }
        return "Once per long rest. " .. (rune[sheet.spec] or "Its effect depends on your rune.")
    end, 1, function(_, sheet)
        if sheet.spec == "Blood" then return { Dice(0, 4, "LEVEL", "OTHER") } end
        if sheet.spec == "Frost" then return { Dice(8, 6) } end
        return {}
    end),
    Limited(20, "Aspect of the Horsemen", "Bonus action, for 10 minutes: you can restore Runic Mastery by spending a 4th-level slot, and Runic Power and Runic Mastery can use any rune's effect. Once per long rest, or again by spending a 5th-level slot.", 1),
}
-- The rune abilities belong to one specialization each.
for _, feature in ipairs(R.SUBCLASS_FEATURES["Oath of the Ebon Blade"]) do
    local rune = feature.name:match("^(%a+) Rune$")
    if rune then feature.spec = rune end
end

-- A Demon Hunter's always-prepared spells: one for everyone at each step, plus the set
-- of the specialization.
local DH_ALL = { { 3, "Throw Glaive" }, { 5, "Sigil of Flame" }, { 9, "Metamorphosis" }, { 13, "Chaos Nova" }, { 17, "Destructive Wave" } }
local DH_SET = {
    Devourer = { "Consume Soul", "Misty Step", "Soul Reap", "Collapsing Star", "Steel Wind Strike" },
    Havoc = { "Fel Rush", "Eye Beam", "Blink", "Fire Shield", "Conjure Volley" },
    Vengeance = { "Infernal Strike", "Fiery Brand", "Demon Spikes", "Banishment", "Sigil of Chains" },
}

R.SUBCLASS_FEATURES["Demon Hunter"] = {
        Passive(3, "Demon Hunter Spells", function(level, sheet)
            local known = {}
            for index, step in ipairs(DH_ALL) do
                if level >= step[1] then
                    known[#known + 1] = step[2]
                    if DH_SET[sheet.spec] then known[#known + 1] = DH_SET[sheet.spec][index] end
                end
            end
            return "Always prepared, and not counted against the number you can prepare: " .. table.concat(known, ", ")
                .. (DH_SET[sheet.spec] and "." or ". Choosing a specialization adds its set of spells.")
                .. " They are on your spell list already."
        end, nil, { prepared = function(sheet)
            local steps = {}
            for index, step in ipairs(DH_ALL) do
                local names = step[2]
                if DH_SET[sheet.spec] then names = names .. ", " .. DH_SET[sheet.spec][index] end
                steps[index] = { step[1], names }
            end
            return steps
        end }),
        Passive(3, "Soul Fragments", function(_, sheet)
            return ("After a long rest you hold soul fragments equal to your Wisdom modifier (at least one), one more from level 13 and two more from level 17. They fuel your demon hunter powers. Reaction when an enemy you can see within 30 feet dies: regain a spent fragment; raise the bar by hand. Saves against your powers use DC %d."):format(Kit.DC(sheet, "WIS"))
        end),
        Ability(3, "Double Jump", "Cast Feather Fall or Jump without a spell slot.", { Spend("Soul Fragments") }),
        Ability(3, "Soul Cleave", function(_, sheet)
            return ("Once per turn, in place of one attack: creatures within 10 feet make a Dexterity save, DC %d, or take the roll as psychic damage. You regain hit points equal to your Wisdom modifier."):format(Kit.DC(sheet, "WIS"))
        end, function(level) return { Spend("Soul Fragments"), Dice(level >= 15 and 2 or 1, 12, "WIS"), Dice(0, 4, "WIS", "SELFHEAL") } end),
        Passive(3, "Spectral Sight", "Blindsight out to 10 feet."),
        Passive(7, "Torment", "The creature marked by your Hunter's Mark has disadvantage attacking anyone but you. Once per turn when you hit it, choose Aura of Pain (it subtracts 1d4 from its next saving throw before the end of your next turn) or Chaos Strike."),
        Ability(7, "Chaos Strike", "Torment option. Once per turn when you hit the creature under your Hunter's Mark: extra fire damage.", { Dice(1, 8) }),
        Ability(11, "Disrupt", "Cast Counterspell as a reaction without a slot.", { Spend("Soul Fragments", 2) }),
        Ability(11, "Warglaive Mastery", "Bonus action: cast Throw Glaive without a slot.", { Spend("Soul Fragments") }),
        Passive(11, "Illidari Knowledge", "You gain Disrupt and Warglaive Mastery as new ways to spend soul fragments."),
        Passive(15, "Soul Shatter", "Soul Cleave rolls 2d12. When you roll initiative with no soul fragments you regain one: raise the bar by hand."),
}
