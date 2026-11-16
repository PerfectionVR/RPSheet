-- The spells of the evocation school, by name, for Empowered Evocation (Actions/SpellFeatures.lua).
-- Taken from the rules site's spell lists of the core rules and the setting.
local _, ns = ...
local R = ns.Rules

R.EVOCATION = {}
for name in ([[
Arcane Pulse|Azure Strike|Azure Sweep|Chains of Ice|Chaos Nova|Collapsing Star|Combustion|Consecration|
Emberstorm|Eruption|Explosive Trap|Eye Beam|Fiery Brand|Flurry|Freezing Trap|Frost Nova|Frostscythe|
Guided Prayer|Holy Nova|Infernal Strike|Lay Waste|Living Flame|Moonfire|Rain of Fire|Remorseless Winter|
Rune Strike|Shattering Star|Sigil of Flame|Starfall|Throw Glaive|Upheaval|Wrath|
Acid Splash|Bigby's Hand|Blade Barrier|Blinding Smite|Burning Hands|Chain Lightning|Chromatic Orb|
Cone of Cold|Continual Flame|Crusader's Mantle|Darkness|Daylight|Delayed Blast Fireball|Destructive Wave|
Divine Smite|Divine Word|Eldritch Blast|Faerie Fire|Fire Bolt|Fire Shield|Fire Storm|Fireball|Flame Blade|
Flame Strike|Flaming Sphere|Forcecage|Fount of Moonlight|Guiding Bolt|Gust of Wind|Hellish Rebuke|
Ice Storm|Jallarzi's Storm of Radiance|Leomund's Tiny Hut|Light|Lightning Bolt|Magic Missile|
Melf's Acid Arrow|Meteor Swarm|Moonbeam|Mordenkainen's Sword|Otiluke's Freezing Sphere|Prismatic Spray|
Ray of Frost|Sacred Flame|Scorching Ray|Searing Smite|Shatter|Shocking Grasp|Sorcerous Burst|
Spiritual Weapon|Starry Wisp|Sunbeam|Sunburst|Thunderclap|Thunderous Smite|Thunderwave|Vitriolic Sphere|
Wall of Fire|Wall of Force|Wall of Ice|Wall of Stone|Wind Wall|Witch Bolt|Word of Radiance]]):gmatch("[^|\n]+") do
    R.EVOCATION[name] = true
end
