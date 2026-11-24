-- How long a spell lasts, for the ones that last an hour or less: in rounds of six
-- seconds (ten to the minute). A combat session counts them down in the caster's own
-- turns (Integrations/FightTimers.lua); outside a session nothing counts, and the time
-- is the player's to keep. Spells that are over at once, and those that outlast an
-- hour, have no entry: a rest ends the latter (Sheet/Wards.lua, Actions/SpellLater.lua).
-- Kept by the spell's name, not on the spell: a sheet holds its own copy of each spell.
--   R.SPELL_ROUNDS[<spell>] = 1, 6, 10 (a minute), 100 (ten minutes) or 600 (an hour)
local _, ns = ...
local R = ns.Rules

local ROUNDS = {
    [1] = "Arcane Pulse|Azure Strike|Divine Shield|Guiding Bolt|Message|Moonfire|Roar of Ursoc|Shield|Sigil of Chains|Starfall|Teleportation Circle",
    [6] = "Tsunami",
    [10] = "Animate Objects|Apotheosis|Aura of Vitality|Azure Sweep|Bane|Banishing Smite|Banishment|Beacon of Hope|Bestow Curse|Bigby's Hand|Blade Ward|Bless|Blinding Smite|Blindness/Deafness|Blink|Blistering Scales|Blur|Breath of Eons|Calm Emotions|Cloud of Daggers|Combustion|Commune|Commune with Nature|Compelled Duel|Compulsion|Confusion|Consecration|Contact Other Plane|Crown of Madness|Crusader's Mantle|Curse of Agony|Dancing Lights|Delayed Blast Fireball|Demon Spikes|Detect Thoughts|Dispel Evil and Good|Divine Favor|Dominate Beast|Dominate Person|Dragon's Breath|Dream Flight|Earthquake|Emerald Blossom|Enlarge/Reduce|Ensnaring Strike|Entangle|Enthrall|Entropic Embrace|Evard's Black Tentacles|Explosive Trap|Eye Beam|Eyebite|Faerie Fire|Fear|Feather Fall|Feral Prowl|Fiery Brand|Flaming Sphere|Flesh to Stone|Freezing Trap|Friends|Gate|Globe of Invulnerability|Grasping Vine|Grease|Greater Invisibility|Guidance|Gust of Wind|Hand of Gul'dan|Haste|Heat Metal|Heroism|Hold Monster|Hold Person|Holy Aura|Hunger of Hadar|Hypnotic Pattern|Incendiary Cloud|Jallarzi's Storm of Radiance|Jump|Mage Hand|Metamorphosis|Minor Illusion|Mirror Image|Modify Memory|Moonbeam|Mordenkainen's Sword|Otiluke's Resilient Sphere|Otto's Irresistible Dance|Phantasmal Force|Phantasmal Killer|Prayer of Mending|Rain of Fire|Ray of Enfeeblement|Regrowth|Resistance|Reverse Gravity|Sanctuary|Scourge Strike|Searing Smite|Serpent Sting|Shadow Word: Pain|Shillelagh|Shining Smite|Sleep|Sleet Storm|Slow|Spiritual Weapon|Stinking Cloud|Storm of Vengeance|Sunbeam|Swift Quiver|Tasha's Hideous Laughter|Thaumaturgy|Tranquility|Transport via Plants|Tree Stride|Tree of Life|Vampiric Blood|Vampiric Touch|Void Eruption|Wall of Fire|Weird|Wind Wall|Witch Bolt|Wrathful Smite|Yolande's Regal Presence",
    [100] = "Arcane Gate|Aura of Life|Aura of Purity|Blade Barrier|Call Lightning|Circle of Power|Clairvoyance|Cloudkill|Conjure Animals|Conjure Celestial|Conjure Elemental|Conjure Fey|Conjure Minor Elementals|Conjure Woodland Beings|Control Water|Darkness|Detect Evil and Good|Detect Magic|Detect Poison and Disease|Expeditious Retreat|Fire Shield|Flame Blade|Fly|Fount of Moonlight|Giant Insect|Insect Plague|Levitate|Locate Object|Major Image|Maze|Prismatic Wall|Produce Flame|Protection from Evil and Good|Scrying|Shield of Faith|Silence|Silent Image|Speak with Animals|Speak with Dead|Speak with Plants|Spike Growth|Spirit Guardians|Tasha's Bubbling Cauldron|Telekinesis|Wall of Force|Wall of Ice|Wall of Stone|Wall of Thorns|Zone of Truth",
    [600] = "Alter Self|Antilife Shell|Antimagic Field|Arcane Eye|Armor of Agathys|Barkskin|Beast Sense|Charm Monster|Charm Person|Comprehend Languages|Daylight|Demiplane|Disguise Self|Dominate Monster|Elemental Weapon|Enhance Ability|Feign Death|Fog Cloud|Forcecage|Freedom of Movement|Gaseous Form|Glibness|Hex|Hunter's Mark|Invisibility|Light|Locate Creature|Longstrider|Magic Circle|Magic Weapon|Mass Polymorph|Mind Spike|Mislead|Pass without Trace|Passwall|Phantom Steed|Polymorph|Prestidigitation|Protection from Energy|Protection from Poison|Rary's Telepathic Bond|Regenerate|Rope Trick|See Invisibility|Shapechange|Spider Climb|Stoneskin|Summon Aberration|Summon Beast|Summon Celestial|Summon Construct|Summon Dragon|Summon Elemental|Summon Fey|Summon Fiend|Summon Undead|Tenser's Floating Disk|Tongues|True Polymorph|True Seeing|Unseen Servant|Warding Bond|Water Walk|Web",
}

R.SPELL_ROUNDS = {}
for rounds, names in pairs(ROUNDS) do
    for name in names:gmatch("[^|]+") do
        if R.SPELLS[name] then R.SPELL_ROUNDS[name] = rounds end
    end
end

-- "10 rounds (1 minute)": a number of rounds in words.
function R.RoundsText(rounds)
    local text = rounds == 1 and "1 round" or (rounds .. " rounds")
    if rounds >= 600 and rounds % 600 == 0 then
        return ("%s (%d %s)"):format(text, rounds / 600, rounds == 600 and "hour" or "hours")
    elseif rounds >= 10 and rounds % 10 == 0 then
        return ("%s (%d %s)"):format(text, rounds / 10, rounds == 10 and "minute" or "minutes")
    end
    return text
end
