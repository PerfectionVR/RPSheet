-- The creatures of Azeroth a combat session's owner can put into a fight, as bare
-- facts: names and numbers, no descriptions. Read by Data/Creatures.lua.
--
-- One creature per line:
--   name | size | kind | challenge | Armor Class | hit points | initiative bonus |
--   STR,DEX,CON,INT,WIS,CHA | saving throw bonuses | resistances | immunities |
--   vulnerabilities | conditions it can't have | M3 = its action is three attacks (nothing: one) |
--   attacks: name~m, r or mr (melee, ranged, either)~to hit~damage ; ... |
--   saves it forces: name~ability~DC~damage on a failure~flags ; ...
--   flags of a save it forces: h = half on a success; r5 = used, it comes back on a
--   5 or 6 on a d6 at the start of its turn; d2 = twice a day; b = a bonus action;
--   e = a reaction; l = a legendary action; w = used along with its attacks;
--   x1 = takes the place of one of its attacks
local _, ns = ...

ns.Rules.CREATURE_DATA = [[
Abomination|H|construct|12|14|168|5|21,13,18,8,12,10|||lightning,poison||charmed,exhaustion,frightened,paralyzed,petrified,poisoned|M3|Cleaver~m~9~3d10+5 slashing+2d6 necrotic;Crush~m~9~3d10+5 bludgeoning;Throw Flesh~r~9~2d8+5 bludgeoning+2d6 necrotic|Reeking Corpse~CON~16~4d6 poison~t;Consume Life~CON~16~2d10 necrotic~b
Aku'mai|H|aberration|8|14|149|6|19,16,20,6,10,13|wis+3,cha+4|necrotic,poison,psychic|||blinded,charmed,deafened,frightened,stunned,unconscious|M3|Bite~m~7~1d10+4 piercing|Caustic Bile~DEX~16~2d8 acid+1d8 acid~hr5;Quake Cavern~DEX~16~2d8 bludgeoning~hl
Alleria Windrunner|M|humanoid(elf)|21|19|433|20|17,23,19,16,22,18|dex+13,int+10,wis+13,cha+11|necrotic,poison,radiant||||M4|Void Dagger~mr~13~2d4+6 piercing+4d6 necrotic;Windrunner's Bow~r~13~2d8+6 piercing+3d10 necrotic|Whispers of the Void~INT~21~3d6 psychic~t;Grasp of Emptiness~INT~21~10d10 psychic~hr5
Alzzin the Wildshaper|M|fiend(satyr)|13|18|204|12|14,24,18,9,8,22|str+7,wis+4,cha+11|necrotic|poison||frightened,poisoned|M2|Fel Claw~m~12~1d8+7 slashing+2d6 fire|Enervation~CON~19~4d8 necrotic~x1;Wither~CON~19~3d8 necrotic~x1;Fel Inferno~CON~19~3d6 fire~hl
Ancient of War|H|plant|14|18|200|7|26,14,22,12,18,11|wis+9|bludgeoning,piercing||fire||M3|Slam~m~13~4d12+8 bludgeoning;Hurl Lightning~r~9~6d10+4 lightning|Nature's Fury~DEX~17~5d10 piercing+10d10 lightning~hr5
Anduin Wrynn|M|humanoid(cleric,human)|20|18|348|15|20,16,18,17,21,19|dex+9,con+10,wis+11,cha+10|radiant||||M4|Shalamayne~m~14~2d10+8 slashing+2d12 force;Holy Fire~r~11~3d10 fire+3d10 radiant|Radiant Volley~DEX~19~7d12 radiant~hr5
Anub'arak|H|undead|22|24|216|11|26,18,24,16,8,24|wis+6|acid,bludgeoning,cold,piercing,slashing|necrotic,poison||charmed,exhaustion,poisoned,unconscious|M2|Icy Claw~m~15~2d12+8 slashing+2d12 cold;Crypt Bolt~r~14~2d12+7 cold+2d12 necrotic|Earth Spike~DEX~22~8d6 piercing~l
Arcanist Doan|M|humanoid(human,wizard)|10|15|165|6|9,14,16,21,16,11|dex+6,int+9,wis+7|||||M3|Arcane Explosion~mr~9~3d8+5 force|Detonate~DEX~17~7d10 fire~hr5
Baron Ashbury|M|undead|4|16|82|4|15,14,16,10,13,15||necrotic|poison||exhaustion,poisoned|M2|Pain Blast~mr~4~1d10+2 psychic|Asphyxiate~CON~13~4d8 necrotic~hr6;Wracking Pain~WIS~13~1d8 psychic~l
Baron Silverlaine|M|undead|5|12|54|5|1,14,11,10,10,14|wis+3|acid,bludgeoning,cold,fire,lightning,piercing,slashing,thunder|necrotic,poison||charmed,exhaustion,grappled,paralyzed,petrified,poisoned,prone,restrained,unconscious||Object Slam~mr~5~2d4+2 bludgeoning|Telekinetic Thrust~STR~13~2d6+2 force~w;Cursed Veil~CON~13~2d6 necrotic~l;Odo's Blinding Shadows~CON~13~2d6 necrotic~l;Rethilgore's Soul Drain~CHA~13~2d6 necrotic~l
Black Dragonflight Dragon|HG|dragon|22|21|351|16|29,14,27,18,18,25|dex+9,wis+11|fire||||M3|Rend~m~16~7d6+9 piercing|Magma Breath~DEX~23~10d6 fire+10d6 bludgeoning~hr5;Pyroclastic Eruption~DEX~22~3d6 fire+3d6 bludgeoning~hl
Black Dragonflight Drake|L|dragon|16|19|275|12|26,14,24,15,15,22|dex+7,wis+7|fire||||M3|Rend~m~13~7d6+8 piercing|Magma Breath~DEX~20~10d6 fire+10d6 bludgeoning~hr5
Black Dragonflight Whelp|M|dragon|9|16|165|6|19,14,17,11,11,15|dex+6,wis+4|fire||||M3|Rend~m~8~4d6+4 piercing|Magma Breath~DEX~15~6d8 fire+6d8 bludgeoning~hr5
Bloodmage Thalnos|M|undead|9|15|153|3|16,8,18,20,14,8|dex+3,wis+6||cold,necrotic,poison||charmed,exhaustion,frightened,paralyzed,poisoned|M3|Shadow Bolt~mr~9~3d10+5 necrotic|Spirit Gale~DEX~17~6d8 necrotic~hr5
Blue Dragonflight Dragon|HG|dragon|20|21|296|14|29,14,27,25,18,18|dex+8,wis+10|cold||||M3|Rend~m~15~5d6+9 piercing|Spellfreeze Breath~CON~22~17d6 cold~hr5
Blue Dragonflight Drake|L|dragon|13|19|187|12|26,14,24,22,15,15|dex+7,wis+7|cold||||M3|Rend~m~13~7d6+8 piercing|Spellfreeze Breath~CON~20~17d6 cold~hr5
Blue Dragonflight Whelp|M|dragon|7|16|120|5|19,14,17,15,11,11|dex+5,wis+3|cold||||M3|Rend~m~7~4d6+4 piercing|Spellfreeze Breath~CON~14~9d6 cold~hr5
Bronze Dragonflight Dragon|HG|dragon|23|22|370|16|29,14,27,18,25,18|dex+9,wis+14|fire||||M3|Rend~m~16~9d6+9 piercing|Superheated Sand Breath~DEX~23~11d6 fire+11d6 slashing~hr5;Sands of Time~DEX~22~6d4 slashing~hl
Bronze Dragonflight Drake|L|dragon|17|20|275|14|26,14,24,15,22,15|dex+8,wis+12|fire||||M3|Rend~m~14~9d6+8 piercing|Superheated Sand Breath~DEX~21~11d6 fire+11d6 slashing~hr5
Bronze Dragonflight Whelp|M|dragon|10|17|172|6|19,14,17,11,15,11|dex+6,wis+6|fire||||M3|Rend~m~8~6d6+4 piercing|Superheated Sand Breath~DEX~15~7d6 fire+7d6 slashing~hr5
Captain Greenskin|S|humanoid(goblinoid)|5|16|66|6|13,16,14,9,12,16|dex+6,con+5|||||M3|Poisoned Harpoon~m~6~1d8+3 piercing+2d6 poison;Pistol~r~6~2d10+4 piercing|
Cho'Rush the Observer|L|giant(ogre)|9|11|133|2|19,7,18,11,24,9|str+8,dex+2,con+8|||||M2|Lightning Staff~mr~11~3d10 lightning|
Commander Springvale|M|undead|5|18|66|6|1,11,12,11,12,16||acid,bludgeoning,cold,fire,lightning,piercing,slashing,thunder|necrotic,poison||exhaustion,frightened,grappled,poisoned,restrained|M2|Malefic Strike~m~6~2d6+3 slashing|Shield of the Perfidious~DEX~14~4d10 necrotic~hr5
Doomguard|L|fiend(demon)|11|16|180|5|20,13,18,12,12,16|str+9,dex+5|cold,fire,lightning|poison||poisoned|M3|Fel Claw~m~9~4d6+5 slashing+3d6 fire;Gore~m~9~6d6+5 piercing|War Stomp~STR~17~9d8 thunder~h
Edwin VanCleef|M|humanoid(human)|5|16|93|7|11,19,12,16,16,15|con+4,int+6|poison||||M3|Scimitar~m~7~1d6+4 slashing|Scimitar~CON~15~~
Fel Imp|T|fiend(demon)|1|13|21|3|6,17,13,11,12,14||cold|fire,poison||poisoned|M2|Fel Firebolt~r~4~2d6 fire|
Felguard|M|fiend(demon)|4|17|60|2|16,14,17,8,10,11||cold,fire,lightning|poison||poisoned|M2|Fel Battleaxe~m~5~2d8+3 slashing+2d6 fire;Fel Javelin~mr~5~2d6+3 piercing+2d6 fire|
Felhound|M|fiend(demon)|5|15|84|3|16,17,14,4,14,8|dex+6|cold,fire,lightning|poison||poisoned|M2|Bite~m~6~3d6+3 piercing;Grappling Tentacles~m~6~2d8+3 bludgeoning|Drink Magic~CON~13~3d6 necrotic~b
Felsworn Satyr|M|fiend|4|15|78|2|16,15,14,12,13,15||||||M2|Claw~m~5~2d6+3 slashing+1d6 fire;Fel Firebolt~r~4~2d12 fire|
Foreman Rhahk'Zor|L|giant(ogre)|3|13|76|3|19,12,18,5,7,7|str+6,wis+0||||||Fist~m~6~2d6+4 bludgeoning|Hurl Foe~DEX~14~1d4 bludgeoning~h;Whirlwind Maul~DEX~14~1d12+4 bludgeoning~r5
Furbolg Totemic|M|humanoid|4|13|71|1|14,12,15,12,15,11|con+4,wis+4|||||M2|Quarterstaff~m~4~1d8+2 bludgeoning+1d10 lightning|
Furbolg Ursa|L|giant|5|13|110|1|18,12,17,10,11,12|str+7,con+6|||||M3|Javelin~mr~7~2d6+4 piercing;Mace~m~7~2d6+4 bludgeoning|Thunder Stomp~CON~14~2d6 thunder~b
Gelihast|M|humanoid(murloc)|5|15|78|7|11,18,14,7,7,12|str+3,con+5,wis+1|||||M4|Scimitar~m~7~1d6+4 slashing|Sticky Net~DEX~15~~x2
Ghamoo-Ra|H|beast|7|17|126|6|19,16,18,5,7,3|str+7,con+7|||||M3|Bite~m~7~2d10+4 piercing;Claw~m~7~1d8+4 slashing;Headbutt~m~7~1d10+4 bludgeoning~l|Shell Spin~DEX~14~6d6 bludgeoning~hr5
Gilnid|M|humanoid(goblinoid)|4|15|90|4|18,14,16,19,7,7|con+5,int+6,wis+0|||||M2|Searing Mace~m~6~1d6+4 bludgeoning+1d6 fire|
Green Dragonflight Dragon|HG|dragon|19|21|222|14|29,14,27,18,25,18|dex+8,wis+13|acid,poison||||M3|Rend~m~15~5d6+9 piercing|Emerald Gas Breath~CON~22~7d6 acid+7d6 poison~hr5;Dream Banishment~CHA~21~3d6 force~l
Green Dragonflight Drake|L|dragon|12|19|225|10|26,14,24,15,22,15|dex+6,wis+10|acid,poison||||M3|Rend~m~12~5d6+8 piercing|Emerald Gas Breath~CON~19~7d6 acid+7d6 poison~hr5
Green Dragonflight Whelp|M|dragon|6|16|127|5|19,14,17,11,15,11|dex+5,wis+5|acid,poison||||M3|Rend~m~7~3d6+4 piercing|Emerald Gas Breath~CON~14~4d6 acid+4d6 poison~hr5
Hadronox|G|monstrosity|18|20|232|9|26,16,21,3,12,9|int+2,wis+7|acid,bludgeoning,cold,fire,lightning,piercing,slashing,thunder|necrotic,poison||charmed,exhaustion,frightened|M2|Bite~m~14~2d10+8 piercing+2d6 poison|Leech Poison~CON~19~~r5;Web Grab~STR~19~3d6 force~w
High Inquisitor Sally Whitemane|M|humanoid(human)|13|16|130|9|9,18,14,18,20,18|dex+9,con+7,wis+10|bludgeoning,piercing,poison,slashing|||stunned|M2|Holy Staff~mr~10~4d10+5 radiant|Spirit Guardians~WIS~18~4d8 radiant~ht
Houndmaster Loksey|M|humanoid(human)|9|16|170|8|20,18,18,9,20,11||||||M2|Handaxe~mr~9~1d6+5 slashing+4d6 slashing|
Illidan Stormrage|L|fiend|24|20|430|14|19,24,20,16,24,18|dex+14,wis+14|fire,necrotic,psychic|||charmed,frightened|M3|Flame Crash~mr~14~4d10 fire;Warglaive~m~14~2d10+7 slashing+3d12 force|Aura of Dread~CON~22~3d12 necrotic~t;Shadow Blast~DEX~22~8d6 necrotic~hx1;Agonizing Flames~DEX~22~6d10 fire+1d12 fire~hl;Draw Soul~CON~22~10d8 force~l
Illyanna Ravenoak|M|undead|11|18|127|10|17,22,16,6,16,3|con+7,wis+7|bludgeoning,cold,piercing,slashing|necrotic,poison||exhaustion,frightened,poisoned|M3|Scimitar~m~10~1d6+6 slashing+2d4 necrotic;Longbow~r~10~1d8+6 piercing+2d4 necrotic|Explosive Trap~DEX~15~3d8 fire~hl
Immol'thar|G|fiend(demon)|16|17|192|7|24,14,24,5,20,3|dex+7,cha+1|bludgeoning,cold,fire,lightning,piercing,slashing|poison||exhaustion,frightened,poisoned|M2|Bite~m~12~2d10+7 piercing+1d8 poison|Stomp~STR~20~3d12 bludgeoning~hw;Fel Rush~DEX~20~2d10 bludgeoning+2d6 fire~hl;Withering Gaze~CON~18~2d10 necrotic~l
Infernal|H|construct|12|18|195|4|24,10,20,3,8,5||cold,lightning|fire,poison,psychic||charmed,exhaustion,frightened,paralyzed,poisoned|M2|Slam~m~11~2d8+7 bludgeoning+2d8 fire|Death Burst~DEX~17~3d6 bludgeoning+3d6 fire~ht;Lob Felfire~DEX~19~4d6 fire+4d6 psychic~hr5
Jaina Proudmoore|M|humanoid(human,wizard)|22|17|450|11|12,18,19,25,20,17|dex+11,con+11,int+14,wis+12|fire|cold,psychic||charmed|M3|Staff of Antonidas~m~14~2d6+7 force+4d8 cold;Ice Shard~r~14~2d6+7 piercing+4d6 cold|Ice Prison~DEX~22~~x1;Shattering Lance~DEX~22~8d8 cold~r5;Frost Nova~CON~22~4d6 cold~hl
King Gordok|L|giant(ogre)|15|16|189|6|24,13,20,8,18,9|str+12,con+10|||||M2|Barbarous Blade~m~12~4d6+7 slashing;Boulder~r~12~2d12+7 bludgeoning|Barbarous Blade~CON~20~~;War Stomp~STR~20~4d12 bludgeoning~hl
Krik'thir the Gatewatcher|H|undead|17|20|231|14|14,26,19,12,22,11|con+10,int+7||necrotic,poison|fire|exhaustion,poisoned|M3|Bite~m~14~1d10+8 piercing+2d10 poison;Claw~m~14~2d10+8 slashing|Mind Web~INT~20~5d10 psychic~hx1;Curse of Fatigue~CON~20~4d6 necrotic~l
Lady Sarevess|M|aberration(naga)|8|16|135|6|9,16,17,19,15,17|dex+6,wis+5|cold,psychic|poison||exhaustion,frightened,grappled,paralyzed,poisoned,restrained,stunned|M3|Lightning Blast~mr~7~4d6 lightning|Frost Nova~CON~15~3d6 cold~er5
Lich King Arthas|L|undead|25|20|500|18|24,14,25,20,20,24|dex+10,wis+13|poison,psychic|cold,necrotic||charmed,exhaustion,frightened,paralyzed,petrified,stunned|M2|Frostmourne~m~18~2d6+10 slashing+2d12 cold;Ice Burst~mr~15~9d8 cold|Frostmourne~CON~23~6d6 force~;Remorseless Winter~CON~23~7d6 cold~hl
Lord Godfrey|M|undead|6|16|104|6|16,17,14,18,14,8|con+5,wis+5||necrotic,poison||charmed,exhaustion,poisoned|M2|Bladed Pistol~m~6~2d10+3 necrotic;Cursed Bullet~r~6~2d10+3 necrotic|Pistol Barrage~DEX~14~8d6 necrotic~hr5
Lord Walden|M|undead|6|16|97|6|16,17,14,18,14,8|con+5,wis+5|cold|necrotic,poison||charmed,exhaustion,poisoned|M2|Ice Shard~mr~7~2d10 cold|Alchemical Vials~CON~15~2d6 poison~h
Mechanostrider|L|construct|1/2|13|34|2|14,15,16,2,9,6|||poison||exhaustion,poisoned||Peck~m~4~2d4+2 piercing|
Moonkin|L|fey|11|17|153|5|20,13,16,15,22,14|wis+10|||||M3|Moonlit Claw~m~9~2d12+5 slashing+2d6 radiant|Elune's Light~CON~18~2d8 radiant~ed2
Murloc Forager|M|humanoid|1|13|32|2|12,14,14,11,16,10|dex+4,wis+5|cold||||M2|Jagged Blade~m~4~1d6+2 slashing|Cold Burst~STR~13~2d4+3 cold~
Murloc Oracle|M|humanoid|3|15|54|3|10,16,11,14,16,12|int+4,wis+5||lightning|||M2|Coral Staff~m~5~1d6+3 piercing+1d6 lightning;Hurl Lightning~r~5~2d6+3 lightning|Lightning Rebuke~DEX~13~2d6 lightning~e
N'raqi Faceless General|H|aberration|21|21|325|9|26,15,23,27,25,19|str+15,int+15,wis+14|psychic|||charmed,exhaustion,frightened|M2|Pincer~m~15~2d6+8 slashing+4d8 psychic|Mind Blast~INT~23~6d6+8 psychic~hr4w;Draining Whispers~CON~23~~l
N'raqi Faceless One|L|aberration|15|16|209|6|24,12,19,25,23,18|str+12,int+12|psychic||||M3|Massive Arm~m~12~3d10+7 bludgeoning;Tentacle~m~12~4d10+7 psychic|Mind Snare~INT~20~4d12 psychic~br4
Naga Myrmidon|L|aberration|5|18|112|6|19,16,15,12,15,10|str+7|cold||||M3|Ocean Blade~m~7~2d8+4 slashing;Trident~mr~7~2d8+4 piercing|
Naga Sea Witch|M|aberration|7|14|136|3|10,10,14,18,16,14||cold||||M3|Lightning Blast~mr~7~5d6 lightning|Watery Rebuke~STR~15~4d6 cold~e
Naga Siren|M|aberration|9|15|123|7|10,16,14,14,12,20|dex+7,wis+5,cha+9|cold||||M3|Frostbolt~mr~9~4d6+5 cold|
Nerubian Crypt Fiend|L|undead|13|17|187|7|12,24,16,12,20,10|||necrotic,poison||exhaustion,frightened,poisoned|M3|Claw~m~12~4d10+7 slashing+2d6 necrotic|Necrotic Web~DEX~20~2d10 necrotic~x1
Nerubian Venomancer|L|aberration|14|18|209|7|14,24,18,12,22,11|||poison|fire|poisoned|M3|Venomous Claw~m~12~2d12+7 slashing+2d10 poison|Web Burst~DEX~20~6d12 poison~r5
Nerubian Warrior|L|aberration|11|17|199|7|12,24,18,10,16,10|||acid,poison|fire|poisoned|M3|Bite~m~11~3d10+7 piercing+2d10 poison;Claw~m~11~3d10+7 slashing|Web Strand~DEX~19~2d10 bludgeoning+2d8 acid~x1
Pandarian Dragon Turtle|L|beast|1/2|17|30|1|16,12,15,2,12,9|||||||Bite~m~5~1d8+3 piercing|
Pit Lord|H|fiend(demon)|20|20|362|13|26,12,26,22,18,24|dex+7,wis+10|cold,fire,lightning|poison||poisoned|M3|Fel Warglaive~m~14~3d10+8 slashing+3d8 fire|Fear Aura~WIS~21~~t;Rain of Felfire~DEX~21~8d6 fire+8d6 psychic~h;Trampling Charge~STR~22~8d6+8 bludgeoning~br5
Prince Tortheldrin|M|humanoid(elf)|15|17|178|9|9,18,19,20,9,16|str+4,dex+9,wis+4,cha+8|fire,poison|||grappled,paralyzed,restrained|M3|Warglaive~m~9~1d6+4 slashing+3d6 fire|Arcane Blast~STR~18~8d6 force~w
Pustulant Monstrosity|L|undead|2|9|57|-1|19,8,19,3,8,5|||poison||exhaustion,poisoned||Slam~m~6~1d8+4 bludgeoning|Spit Plague~DEX~14~1d6 poison~
Quilboar Thornweaver|M|humanoid|7|17|104|4|13,18,14,15,19,11|wis+7|||||M3|Thorn Staff~m~7~2d8+4 piercing;Quill Spray~r~7~2d8+4 piercing|
Ragnaros|G|elemental|23|20|296|18|26,19,27,15,16,23|dex+11,con+15,wis+10||fire,poison||blinded,charmed,deafened,exhaustion,frightened,grappled,paralyzed,poisoned,prone,restrained,stunned,unconscious|M2|Sulfuras Smash~m~15~4d6+8 force+4d6 fire;Elemental Fire~r~15~4d6+8 fire|Sulfuras Smash~DEX~23~4d6 fire~;Magma Blast~DEX~23~12d6 fire~hr4;Wrath of Ragnaros~DEX~23~2d10 force+2d10 fire~hl
Red Dragonflight Dragon|HG|dragon|21|21|296|16|29,14,27,18,18,25|dex+9,wis+11|fire||||M3|Rend~m~16~6d6+9 piercing|Razing Fire Breath~DEX~23~20d6 fire~hr5;Bellowing Roar~CON~23~5d8 thunder~hl
Red Dragonflight Drake|L|dragon|15|19|250|12|26,14,24,15,15,22|dex+7,wis+7|fire||||M3|Rend~m~13~7d6+8 piercing|Razing Fire Breath~DEX~20~20d6 fire~hr5
Red Dragonflight Whelp|M|dragon|8|16|135|5|19,14,17,11,11,15|dex+5,wis+3|fire||||M3|Rend~m~7~5d6+4 piercing|Razing Fire Breath~DEX~14~12d6 fire~hr5
Scarlet Champion Herod|M|humanoid(human)|18|17|209|10|20,18,20,7,9,11|str+11,con+11|||||M3|Greataxe~m~11~2d12+5 slashing+4d6 force|Ravager's Cleave~DEX~19~4d12 slashing+4d6 force~hl
Scarlet Commander Mograine|M|humanoid(human)|13|20|221|6|20,13,18,16,12,20|str+10,con+9,wis+6|poison,radiant||||M2|Crusader Strike~mr~10~1d8+5 bludgeoning+6d8 radiant|
Shadowstalker Satyr|M|fiend|2|15|55|5|12,17,13,11,13,14|dex+5|||||M2|Fel Blade~mr~5~1d6+3 piercing+1d4 necrotic|
Shivarra|L|fiend(demon)|16|17|199|10|18,20,20,16,20,20|wis+10,cha+10|cold,fire,lightning|poison||poisoned|M6|Fel Blade~m~10~2d10+5 slashing+2d6 fire|
Sneed's Shredder|L|construct|4|16|93|4|19,14,17,1,10,1|str+6,wis+2||poison,psychic||exhaustion,frightened,poisoned,stunned|M2|Steamsaw~m~6~1d10+4 slashing|Terrify~WIS~13~~r5w
Springvale's Specter|M|undead|1|12|13|2|1,14,11,10,10,14||acid,bludgeoning,cold,fire,lightning,piercing,slashing,thunder|necrotic,poison||charmed,exhaustion,grappled,paralyzed,petrified,poisoned,prone,restrained,unconscious||Life Drain~m~4~2d6 necrotic|Screams of the Past~CON~12~2d6 psychic~
Sylvanas Windrunner|M|undead|23|20|475|21|18,24,21,19,24,20|dex+14,con+12|cold,necrotic,psychic|||charmed,frightened|M3|Shadow Dagger~mr~14~2d4+7 piercing+4d8 necrotic;Windrunner's Bow~r~14~2d8+7 piercing+4d6 necrotic|Banshee Wail~CON~22~~r6;Veil of Darkness~CON~22~3d6 psychic~l
Thrall|M|humanoid(barbarian,orc)|22|19|475|17|22,16,20,18,22,20|dex+10|cold,fire,lightning||||M3|Dra'gora~m~13~2d10+6 slashing+4d8 chosen;Lava Burst~r~13~9d6 fire|Chain Lightning~DEX~21~8d8 lightning~r4;Spirit Wolf Strike~DEX~21~8d8 force~hl
Twilight Lord Kelris|M|humanoid(orc)|7|16|120|6|13,16,17,9,14,20|dex+6,con+6,wis+5|psychic||||M3|Mind Blast~mr~8~2d10+5 psychic|
Voidcaller|M|fiend|3|16|49|1|17,12,13,14,12,19|wis+3|poison|necrotic||exhaustion,poisoned|M2|Void Burst~mr~6~1d6+4 force|
Voidwalker|M|fiend|1|16|38|0|19,11,13,8,12,14||poison|necrotic||exhaustion,poisoned||Consuming Shadows~m~6~1d4+4 necrotic|
]]
