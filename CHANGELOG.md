# Changelog

## 0.8.1

- The Unarmed Strike row's tooltip gives the save DC for a grapple or shove
  (8 + Strength + proficiency), and its explanation shows how the DC is worked out.
- The rules were checked again against the 2024 rules (5.5e); the README says which
  edition the sheet follows and what that means where the 2014 rules differ.
- Tidying inside: helpers that several files each had a copy of are shared, and code
  nothing used is gone. Nothing changes in play.

## 0.8.0

- Loads in WoW Forever as well as retail: one download for both games.
- WoW Forever: rolls are announced. The game there lets an addon speak in chat only
  straight from a click, so the sheet rolls the dice itself and announces during the
  click instead of waiting for a `/roll` result.
- WoW Forever: a line made without a click (the Constitution save after damage) is
  shown to you with a [Send it] link; clicking it sends the line.
- WoW Forever: characters there have two-part names ("Given Family") and no realm.
  Sharing stats, chat links and the name on the sheet use the whole name, so two
  players with the same first name are kept apart.
- With no weapon equipped, the attack row is the Unarmed Strike everyone can make:
  Strength and proficiency to hit, 1 + Strength bludgeoning damage. A right-click
  opens the Items tab to equip a weapon. A feat, style or Martial Arts that improves
  the strike keeps its own row, and the attack row then says to use it.

## 0.7.1

- Take damage knows your features that change damage and offers each only while you
  can use it: Evasion (boxes for a Dexterity save passed or failed), Uncanny Dodge and
  Superior Hunter's Defense (each spends your reaction, which is back when you say so,
  roll initiative or rest; the Hunter's resistance stays as a passive for the turn),
  Heavy Armor Master (a box for an attack hit, in heavy armor), Nose for Trouble (ticked
  by itself after you roll initiative) and Stagger and Sway (the Delayed Reaction pool
  grows with each hit and has rows to take it or thin it with Purify). None works
  while you are incapacitated.
- "A fall" in the damage menu rolls 1d6 for every 10 feet (20d6 at most), lands you
  Prone, and counts Slow Fall (asked as a reaction) and Bouncy.
- Death Ward can be cast on yourself or added under Customize, Defense: the first
  time damage would drop you to 0 hit points you keep 1 and the spell ends. Relentless
  Rage rolls its Constitution save by itself when you drop to 0 while raging, and
  sets your hit points on a success; its DC goes back to 10 after a rest.
- Indomitable Might: a Strength check or save that totals less than your Strength
  score counts as the score.
- Heal opens a menu: type the amount, take your own last healing roll (cast on
  yourself), or roll a healing spell someone else cast on you, with its slot and their
  modifier.
- Class features the sheet now applies by itself:
  - The Assassin is proficient with the disguise kit and poisoner's kit, the Warrior of
    Mercy with the herbalism kit, and the Warrior of Mystic Brews with brewer's supplies.
  - A use bought back with a spell slot, a Rage use or Sorcery Points is paid when the
    feature's own use is spent: Holy Nimbus, Holy Deliverance, Avenging Angel and Aspect
    of the Horsemen (5th-level slot), Moonlight Step (2nd-level slot or higher),
    Intimidating Presence (Rage), Hurl Through Hell and Clairvoyant Combatant (pact
    slot), Dragon Wings (3 Sorcery Points), and Runic Mastery (4th-level slot while
    Aspect of the Horsemen is on).
  - Dragon Wings, Avenging Angel and Aspect of the Horsemen switch on a passive; the
    wings, Avenging Angel, Dispersion and the Dragon constellation from level 10 show
    their flying speed.
  - Rolling initiative gives back Soul Shatter's soul fragment, Archdruid's Wild Shape
    use and Perfect Focus' Focus Points.
  - Casting Hunter's Mark from the spell list switches the Hunter's Mark passive on.
  - Potent Spellcasting adds Wisdom to Cleric and Druid cantrips; a Priest's level 14
    temporary hit points are an ability. Elemental Affinity and Empowered Evocation add
    their modifier to the spell's first damage roll. Disciple of Life, Blessed Healer
    and Supreme Healing work on healing spells, Supreme Healing on Channel Divinity too.
    Infusion of Light refills Lay on Hands with a radiant spell's dice.
  - Lay on Hands asks whom it heals and how many points, and offers the conditions it
    can end. Divine Smite and Paladin's Smite ask whether the target is a fiend or an
    undead.
  - Runic Power (Blood) heals you by the Rune Strike's necrotic damage, which the sheet
    suggests; Runic Mastery (Blood) takes off the hit points it costs. With Aspect of
    the Horsemen on, both ask which rune's effect to use.
  - Wild Resurgence is an ability that turns a slot into a Wild Shape use; Nature
    Magician asks how many uses become a slot and adds it.
  - Arcane Apotheosis: with Innate Sorcery on, a Metamagic option asks whether it is
    the free one.
  - Divine Intervention can cast Wish at level 20, and then stays spent for the 2d4
    long rests rolled.
  - Memorize Spell: after a short rest a Mage can put one prepared spell away and
    prepare another in the spellbook window.
  - The Dragon constellation counts a d20 of 9 or lower as 10 on Intelligence and
    Wisdom checks and the save to keep concentrating.
  - Assassinate has an ability for its first-round damage.
- Medium Armor Master works: with Dexterity 16 or more, medium armor adds 3 from
  Dexterity to Armor Class.
- Feats with uses have bars and rows: Lucky's luck points (a click sets advantage on
  the next roll), Mage Slayer's Guarded Mind, Arathi Heritage's Lethargy Resilience
  (back after 1d4 long rests, rolled at the first), Boon of Recovery's Last Stand and
  pool of ten d10s, Boon of Fate's 2d4 (back when you roll initiative), Chef's treats.
  Charger, Fingers of Frost, Poisoner and Polearm Master get a row that rolls their
  damage; Defensive Duelist's Parry switches on Parrying, which adds your proficiency
  bonus to Armor Class until you switch it off or rest.
- Weapon attacks apply Great Weapon Master's extra damage with heavy weapons, Boon of
  Irresistible Offense on a natural 20, Savage Attacker (rolled twice, the better
  kept), Piercer (the low die rerolled, one more die on a critical hit) and Fists of
  Fury with light weapons.
- Tavern Brawler, Unarmed Fighting and the Strike of the Earth-Warder give an Unarmed
  Strike row with their damage and bonus; a Monk's own strikes take the blessing and
  the feats.
- Spells apply Elemental Adept and Clearcasting (a 1 on their damage type counts as
  2) and Healer (1s on healing dice rerolled). Boon of Spell Recall rolls its d4 and
  gives the slot back on a match. Empowered Spell and Seeking Spell reroll the spell
  you just cast.
- Invocations that cast a spell without a slot put it on your spell list and cast it
  that way: Armor of Shadows, Mask of Many Faces, Fiendish Vigor (the highest
  numbers), Gift of the Depths and Legion Summoning (once per long rest) and the
  others; Pact of the Chain and Pact of the Legion give Find Familiar. Agonizing Blast
  adds Charisma to Eldritch Blast by itself. A weapon can be ticked as your Pact of
  the Blade weapon, to attack with Charisma. Lessons of the First Ones' origin feat is
  asked for in the level dialog, and can be changed under Customize.
- Trolls have advantage on attacks while Bloodied; an Amani troll regains a Hit Die
  when it spends Heroic Inspiration, a Zandalari troll gains it on a natural 1, and a
  draenei's Heroic Presence gives it when a lineage spell is cast. Draconic Flight
  switches on a flying speed. A Mulgore or Highmountain tauren chooses the ability
  of its save DC. A mechagnome picks the two tools of Specialized Design.
- Tushui Meditation gives Heroic Inspiration after a short rest; Honored with Gilneas
  adds 2 to skinning checks. Chef's short-rest meal adds 1d8 to your next Hit Die.
- Hex, Hunter's Mark and Divine Favor are cast once: after that a click on the spell
  rolls the extra die for a hit, without a slot, and a right-click ends it.
- Spells that act again after their casting keep running on the sheet: a left-click
  rolls the next attack, bolt, burst or turn's damage with the slot it was cast with
  (Spiritual Weapon, Moonbeam, Spirit Guardians, Call Lightning, walls and clouds and
  many more), and a right-click offers every later roll: damage at the end of the
  target's next turn, healing on later turns, Vampiric Touch's half, Bigby's Hand's
  other hands, Teleport's mishap, Wish's stress, the bead of Delayed Blast Fireball.
  Damage that is yours to take (a mishap, Meld into Stone) is taken at once. A running
  spell ends by hand, with your concentration or with a rest.
- Spells cast on yourself change your numbers while they last: Armor Class (Mage
  Armor, Shield, Shield of Faith, Barkskin, Haste and others), maximum and temporary
  hit points (Aid, Heroes' Feast, Vampiric Blood, Armor of Agathys), speeds (Fly,
  Longstrider, Spider Climb, Haste and others), dice and advantage on your rolls
  (Bless, Guidance, Enhance Ability, Foresight, Holy Aura, Pass without Trace,
  Glibness), and your weapon (Shillelagh, Magic Weapon, Elemental Weapon, Crusader's
  Mantle, True Strike on the next attack). Advantage on saves against spells, poison
  or conditions comes with Circle of Power, Protection from Poison and Aura of Purity.
- Divine Smite, Rune Strike and Toll the Dead ask what the target is; Living Flame
  asks whether it burns or heals. Sorcerous Burst and Soul Reap roll their extra dice,
  Magic Missile shows each dart, Hand of Gul'dan and Throw Glaive each damage type,
  and Steel Wind Strike rolls all five attacks. Bonestorm heals you.
- Contact Other Plane rolls your own Intelligence save against 15 and the damage on a
  failure. Innervate gives back a use of Wild Shape and can give you the 4th-level
  slot. Feral Prowl and Roar of Ursoc switch on one of your Wild Shape forms, and Tree
  of Life gives its Armor Class, temporary hit points and immunities.
- Blessing of Argent Fortitude makes you immune to poison damage and to being poisoned.
- Sixteen 1st-level spells that only listed their facts (Alarm, Grease, Identify,
  Unseen Servant and others) have a summary of what they do.
- Detect Thoughts no longer asks for a copper piece: a focus stands in for it.

## 0.7.0

- Species and lineage cantrips (Sacred Flame, Mind Sliver, Arcane Pulse,
  Prestidigitation, Druidcraft and others) are on your spell list and can be cast. The
  lineage's level 3 and 5 spells move there too: once per long rest without a slot,
  and with your slots after that. They use Intelligence, Wisdom or Charisma, chosen
  with your lineage; characters made before are asked at their next level. High and
  blood elves can exchange Prestidigitation for another Wizard cantrip under Customize.
- With two classes, each keeps its own copy of a spell they both prepare, and the
  Spells pages under Customize name the class.
- Holy Nimbus, Shadowform, Divine Sense and Nature's Sanctuary switch on a passive when
  used; being incapacitated ends the last three. A rest ends these and the other
  short-lived ones (Rage, Superior Defense, Starry Form, Sacred Weapon, Vow of Enmity,
  Innate Sorcery, Reckless Attack, Dispersion). Holy Nimbus' save advantage counts only
  while it is on.
- Weapon Master's extra pick is for its own kind of weapon only and changes once per
  long rest (as do Boon of Energy Resistance's types); proficiency from feats and
  Divine or Primal Order counts for it.
- Inscription Adept: gathered herbs can pay for your feat spells' costly components.
- The "which spell are you holding?" question has a "Don't ask again" row. A
  hand-added Wizard cantrip no longer fills a Mage's cantrip exchange by itself.
- With an empty Fighting Style the Character tab shows one red line, not two.
- Changing class, subclass, species or background under Customize raises your current
  hit points when it raises your maximum. An empty Fighting Style is asked for in
  "Class and feat choices". The level dialog lists only the features that apply to
  you. Right-click a check, save, skill, tool, initiative or spell attack row to see
  how its number is worked out. The combat numbers are two to a row, so none wraps in
  the narrowest window. The coin, damage, heal and materials boxes find their text
  field however the game names it.
- Items: the Enspelled Staff is on the Makes tab; magic items no profession can make
  say why; attunement, consumable, harness and magic make can be hovered; you can't
  use or drink items while incapacitated; right-clicking an item that needs no
  attunement says what right-click does; gathering and archaeology rolls use the
  "Next roll" bonus, and gathering rows warn when your tool isn't with you.
- Sharing: a settings profile that switches sharing off tells your group, and players
  who hovered you outside a group are told too; other players' stats are forgotten
  half an hour after you last heard from them, unless they are in your group; in
  dungeon finder, raid finder and battleground groups stats are shared with the whole
  group and Party/Raid announcements go to instance chat. In chat, tools, items,
  initiative and spell attack can be hovered.
- Taking back a rest stops working after any change, a bar clicked or a slot spent
  by hand included. An attack with no weapon ready says so.
- Every piece of plain gear, pack, spellcasting focus, tool and instrument says what
  it is for: light radius, what a container holds, the DC of a tool's checks and what
  it makes, a pack's contents. The item browser's search finds them by it
  ("stabilize", "pick a lock", "holy symbol").
- Cordon of Arrows cast with a higher slot plants two more arrows or bolts for each
  level above 2nd, as many as you carry.
- A Warlock with Mystic Arcanum reads spell scrolls up to the arcanum's level without
  a check (6th at Warlock level 11, up to 9th at 17).
- A cantrip can no longer be taken twice in the level dialog, once as a class cantrip
  and once through Magic Initiate (True Strike for a Sage Mage, Guidance for an
  Acolyte Priest), whichever is picked first.
- Choosing a subclass shows what it is and its features by level, in the creation
  wizard, the level dialog and Customize. The Mage's Evoker says it is the school
  of evocation magic, not the Evoker class.
- Spells already on a character follow corrections to the built-in spells; a spell
  you changed yourself keeps what you set and offers "Use the built-in spell".
- Death Knights and Demon Hunters have their own spell lists. A cantrip you have from
  a feature or feat is no longer picked twice; Circle of the Stars gives Guidance. A
  Monk chooses its tool in the level dialog; Inscription Adept needs one of its
  three tools; your own spells can add dice per higher slot. When two classes
  prepare the same spell each has its own entry, named with its class.
- Items: a Makes tab in the item browser with every magic make of every weapon,
  armor, shield and ammunition, to add or buy; every magic item has a recipe except
  artifacts; recipes are learned per profession; potions stack; a Sell button; the
  search reads descriptions and kinds and can search every tab; items you changed
  stay yours while untouched ones follow corrections.
- A mount carrying more than it can moves 5 feet; animals can be harnessed to a
  drawn vehicle with a load.
- Play: a critical hit at 0 hit points counts as two failed death saves; saves and
  checks rolled by an ability follow the sheet's rules; Grappled and Frightened ask
  whom you attack or whether your fear is in sight; "Don't ask again" on every roll
  question, with switches under Customize > Proficiencies; while incapacitated you
  can't attack, use abilities, cast or read scrolls, and a rage ends; a right-click
  never does the left-click's job.
- "Next roll" has rows to add or subtract a die (d4 to d12) or a number for your
  next d20: Bless, Guidance, Bane, cover.
- Beast forms count Rampage, Rock, Web, Cacophony and the new Ink Cloud.
- Sharing: switched off it neither sends nor asks, and your group drops your copy;
  stats catch up after an encounter that blocked addon messages; long announcements
  are split into "(continued)" lines instead of cut.
- Rests can be taken back with `/sheet undo` or a right-click on the rest row. New
  commands: `/sheet short`, `/sheet tab <name>`, `/sheet items`, `/sheet level`.
- The saved file no longer keeps an empty sheet for every character and profile seen.
- The wizard's "carry over" no longer carries the old species' traits and background
  feat, and shows for characters whose own things are only items, coins or mounts.
- Fixes found by a random-play tester: slot rows reading "5/4" or "4/5" after
  Font of Magic, a subclass's always-prepared spell listed twice, the death save row
  staying after hit points came back, an inventory quantity of 0.
- Rules data checked against the rules site by script, and corrected:
  - Spells: Searing, Thunderous, Wrathful and Banishing Smite, Sanctuary and Serpent
    Sting show the save they force; Earthquake asks for a Dexterity save; Finger of
    Death adds 30 and Regenerate 15; Ice Storm also rolls its cold damage; Flame
    Blade, Spiritual Weapon, Mordenkainen's Sword and Conjure Fey add your
    spellcasting modifier; Blade Ward needs concentration. Spells already on a sheet
    need adding again for the new save or modifier.
  - Spell lists: Priests can prepare Blur, Levitate, Haste, Summon Undead, Dominate
    Person and Dominate Monster and learn Mind Sliver; Mages can write Create Food
    and Water, Flame Strike and Heroes' Feast into the spellbook; Command and
    Dissonant Whispers are no longer on the Warlock's own list.
  - Always-prepared spells now appear on the spell list: Hunter's Mark (Hunter,
    Demon Hunter), Speak with Animals (Druid), Guiding Bolt (Circle of the Stars),
    the chosen land's spells (Circle of the Land), Rune Strike (Death Knight) and
    Contact Other Plane (Warlock).
  - Classes, species, backgrounds, feats, weapons, armor, prices, mounts and beasts
    all matched; nothing to correct.
- 57 more magic items, among them Azeroth's Hearthstone, Judgment Armor and Crown of
  the Ogre King and seven artifacts (Ashbringer, Doomhammer, Frostmourne, the Helm of
  Domination, Shalamayne, Sulfuras, the Twin Blades of Azzinoth); food and drink,
  single bullets and needles, iron spikes and fourteen poisons in the gear list.
- Sharing with your group:
  - A character made before Total RP 3 was installed is on your profile at the first
    login with it, instead of a blank sheet and the wizard.
  - After a reload in a group you see everyone's stats again without hovering them.
  - Far fewer messages are sent: only when something others see has changed.
  - A profile without a character no longer shows an empty Stats block in tooltips.
  - Announcements with a "|" or a line break in a name, and long lines with accented
    letters, are no longer refused by chat; item and spell links are no longer
    broken when their name is also a rules term.
- `/sheet` with a word it doesn't know lists the commands; `/sheet help` lists them.
- The creation wizard is offered after combat when the first login was in combat.
- The sheet rebuilds and the level dialog opens faster for characters with many
  abilities, spells or classes.
- Fixes found by running every part of the addon in a test environment:
  - Levelling: an Epic Boon that raises a score above 20 no longer marks earlier
    improvements as needing a new choice; taking a level with the suggested subclass
    no longer leaves you short of prepared spells; hit points from a level's choice
    are added to your current hit points; a Mage without any of Scholar's skills is
    no longer asked for an expertise pick nobody can make; expertise left over from
    another class can be unticked; "Next level in" starts at your first class.
  - Spells: a scroll does everything its spell does and is only used up once the
    spell is cast; Magical Cunning restores Pact slots for a multiclass Warlock, who
    also spends the lowest slot that fits; Warding Bond ends at 0 hit points; in a
    beast form a Circle of the Moon druid casts only the circle's spells.
  - Unarmored Defense counts once: with two classes that have it, the first decides.
  - Items: money typed as "1.5 gp" is refused instead of misread; putting away a
    plain weapon no longer puts away a named one of the same kind; an item without a
    price can't be bought for nothing; deleting or selling something you wear takes
    it off; starting gear of a class or background you changed goes back.
  - Windows: the last tab or button no longer drops onto a row of its own at some
    widths; rows no longer end up on top of each other after a rebuild or resize;
    deleting an entry under Customize can no longer remove a different one; the
    minimize button works on the spellbook and prepared-spells windows.
  - New and imported characters no longer inherit the previous one's temporary hit
    points or rest marks; importing keeps the features you deleted.
- Saving throws ask what they are against when a trait, feat, blessing, item or
  companion gives you advantage against it, and roll with advantage when you pick
  it; Shift-click skips the question. Gnomish Cunning, War Caster and Eldritch Mind
  apply by themselves.
- Conditions: Unconscious also makes you Prone; exhaustion counts on death saves;
  Danger Sense stops while incapacitated; losing a concentration save ends the
  protection the spell gave.
- Magic items have prices by rarity and can be bought and sold; faction discounts
  apply. Customize > Inventory can make a magic variant of plain armor, a shield or
  a weapon (+1 to +3, adamantine, mithral, silvered, resistance).
- Spell scrolls: you can only read spells on your class's list, a spell above your
  level takes a check that can lose the scroll, and scrolls you didn't write cast
  with fixed numbers.
- Customize > Defense: one dropdown adds any protective spell someone else cast on
  you. Cordon of Arrows uses four arrows or bolts.
- Level-up: one Metamagic option or Eldritch Invocation can be exchanged per level,
  one maneuver when you learn new ones; a new Customize page sets them freely. A
  Mage can exchange one cantrip after a long rest in the spellbook window.
- Creation wizard: any number of extra classes the level allows, each with its
  specialization and Fighting Style.
- Arcane Recovery and Natural Recovery each use their own class's level; Weapon
  Mastery picks from several classes add up.
- Beast form attacks announce what a hit also does, with its DC; charges and
  follow-up bites have their own rows.
- Herbalism, mining, skinning and disenchanting need the tool among your items.
- Long lists in the item, crafting and stable windows show a page at a time (24 per
  page); search still looks through the whole tab. The sheet rebuilds less often.
- Multiclassing: take your next level in another class from the Character tab, or
  split a new character's levels over several classes in the creation wizard. The
  sheet checks the ability scores the new class needs, gives its reduced training,
  and works out hit points, Hit Dice, features, resources, Fighting Style, prepared
  spells and spell slots class by class; each spell is cast with its own class's
  ability. Customize has a "More classes" page.
- Professions can make every magic item their skill opens (over 300 more, each with
  a recipe), engineers can build powered vehicles, and you can scribe spell scrolls
  of your own spells and read them with a shift-click. Making something needs the
  tool in your inventory; "Check that you carry the tool" under Customize >
  Professions switches that off.
- Swim, Climb and Fly speeds appear next to Speed when your character has one.
- "Buying from" at the top of the item browser and the stable names the faction
  whose merchant is selling; from Honored on, prices drop.
- A loyal undead companion gives advantage on death saves, a mechanical one rolls
  1d4 off psychic damage, an aquatic one gives a swim speed. The stable has a
  "Special" tab for flying carpets, figurines and summoned steeds.
- Renown: your home faction keeps what it gained from another faction's tier when
  that score later drops.
- Spells that need a weapon in hand check your ready weapons; Gentle Repose takes its
  coins; Astral Projection and Create Undead ask how many targets.
- Resistance and Time Dilation on yourself are rolled by "Take damage". Warding Bond
  works for the caster (a damage-menu row) and for the one guarded (Customize >
  Defense).
- In a Wild Shape form you use the beast's saving throws where they are better.
- The level dialog, opened again for a level you already have, only fills in what is
  open. One cantrip can be exchanged per level (a Mage none).
- Creation wizard: choices inside a starting gear set (holy symbol, instrument,
  tools, gaming set) are picked from a dropdown.
- The settings window, tick boxes, sliders, dropdowns, typing boxes, scroll bars and
  the item browser follow the sheet's theme.
- New Trade tab for professions. Your professions follow your tool proficiencies and
  your skill follows your proficiency bonus. Roll gathering checks (herbalism,
  mining, skinning, fishing, archaeology) against the region you pick, keep what you
  gather as materials, and make listed gear and magic items in a crafting window
  that checks your tools and skill, pays with materials before coins and tells you
  how long it takes. Enchanters can disenchant; artisan cooks can lay out a feast.
- Mounts, vehicles and companion creatures: a stable to browse, add and buy them, and
  a section on the Items tab. Click a mount to ride it and your Speed row shows its
  speed; flying and swimming mounts need an Exotic Saddle and a mount must be larger
  than you. Companion creatures have a loyalty score and give their gift at 10.
- Spells that need a component with a price can only be cast while you carry it, and
  components the spell uses up are taken from your inventory; one worth more will do.
  A Reagents tab in the item browser sells them, tooltips say what you need, and
  "Check spell components" under Customize > Spells switches it off.
- Every core spell of 2nd level and higher has a short written summary in place of
  the bare line of facts.
- Magic items can set an ability score or your speed (Amulet of Health, Gauntlets of
  Ogre Power, Headband of Intellect, the Belts of Giant Strength, Boots of Striding
  and Springing), and your own items and passives can too. About fifty more magic
  items are in the browser.
- Creating a character: two buttons take your class's and your background's
  starting gear into the closet and set your gold to what is left over.
- Levelling: one Mystic Arcanum spell, and one prepared spell for classes that change
  them by level, can be exchanged per level. Classes that change prepared spells
  after a long rest have a "Change prepared spells" window on the Actions tab.
- Skilled can pick tools, Weapon Master unlocks the mastery of its weapon kind, and
  Inscription Adept gains Glyph of Warding at level 5 and Symbol at level 13.
- Your own spells and ability dice can have a damage type; force damage from them
  counts for Metamorphosis: Devourer.
- Wild Shape: attacks that hit harder after a charge or against a Bloodied target
  have a second row that rolls it, and a beast's own skill bonus is used when it
  beats yours.
- Renown: +1 for a stronghold in a faction's lands, and your home faction rises as
  the other factions of your side reach each tier. Renown with both the Explorers'
  League and the Reliquary is flagged in red.
- Casting a protective spell on yourself (Stoneskin, Protection from Energy, Fire
  Shield and more) switches on its resistance until a rest, the end of
  concentration, or you click it off. Heavenly Spirit asks which damage types you
  resist; Boon of the Night Spirit has a "Shadowy Form" passive.
- The creation wizard and the level-up window follow your sheet theme.
- The sheet's smallest width is 340, to fit its six tabs.
- Carrying more than your capacity holds your speed to 5 feet; the Speed row and
  its explanation show it.
- A found spell can be copied into the spellbook for 50 gp per spell level, paid
  from your coins (Customize > Spellbook). Spells gained by levelling stay free.
- The companion's Weapon Mastery pick can be changed once per long rest.
- An inventory item can count as a plain weapon, suit of armor or shield and have a
  magic bonus (Customize > Inventory, "Counts as"). Equipping it wears or readies it
  under its own name: magic armor and shields add their bonus to your Armor Class,
  and a magic weapon comes onto the sheet with its bonus. An item named like one of
  your own weapons readies and puts away that weapon.
- A Mage changes prepared spells in the spellbook window only after a long rest:
  the list is fixed from the first spell cast after it. Customize > Spellbook can
  still change it at any time.

## 0.6.0

Switched from the earlier simplified rules to D&D 5e (2024) as used by the
*D&D: World of Warcraft* book.

- Warrior is complete. A Battle Master picks maneuvers when levelling, from all 25
  including the setting's five; each is an ability with the right die and save DC.
  A Champion's wider critical range, advantage on initiative and Athletics, and
  Survivor's death saves are applied by the sheet. Tactical Mind, Indomitable,
  Student of War and the growing Extra Attack are in.
- The other twelve classes and their subclasses are checked against the rules,
  feature by feature. Features roll their dice, show their save DC, track their uses
  per rest and grow with level. Features that offer a choice (Divine Order, Primal
  Order, Blessed Strikes, Elemental Affinity) are picked in the level dialog, and
  features that grant advantage, training, skills or a wider critical range apply by
  themselves.
- A Warlock picks Eldritch Invocations and an Evoker picks Metamagic in the level
  dialog, the right number for the level. Invocations respect their level and the
  pact they build on; Metamagic options spend Sorcery Points when clicked.
- A Rogue, Hunter and Mage pick the skills for their expertise in the level dialog.
- The core rules' spells of every level can be added from the class spell list, up to
  the highest level you have slots for. The spells a subclass always has prepared are
  put on the spell list by themselves.
- A "Cast at" row picks a higher slot for the next spell; spells that grow with the
  slot roll the extra dice. A Warlock's spells grow with the pact slot by themselves.
- A Death Knight's spells follow the rune and are put on the spell list by themselves,
  as are a Demon Hunter's fixed spells.
- Arcane Recovery gives spent slots back by the click, and Font of Magic has two
  abilities that turn a slot into Sorcery Points and points into a slot.
- A Circle of the Moon druid has Cat Form and Bear Form. While a form is on, the sheet
  uses its Armor Class, speed, Strength and Dexterity, and the form's attacks are
  abilities: Pounce, Primal Wrath, Mangle and Frenzied Regeneration.
- Conditions change your own rolls: disadvantage on attacks and checks where the
  condition gives it, advantage while invisible, Strength and Dexterity saves that
  fail without a roll, and a speed of 0. Armor gives disadvantage on Stealth and
  costs speed without the Strength for it. Losing hit points while concentrating
  reminds you of the save and its DC.
- A Beast Master picks a pet family for its companion. The sheet has a bar for the
  companion's hit points and its strike as an ability, and from level 6 the family's
  specialization (Cunning, Ferocity or Tenacity) in place of Roving.
- A druid picks the beasts it knows as Wild Shape forms in the level dialog, from
  fifteen (wolf, panther, elk, bears, tiger, the flying forms and more). Each has a
  click to take the form, its attacks as abilities, and its numbers on the sheet
  while the form is on.
- Every class after the Warrior was checked a second time against the rules. Fixed:
  dice, half damage on a save and riders of some forty of the setting's spells; an
  Evoker's prepared spells; a Demon Hunter's soul fragments at levels 13 and 17;
  Improved Death Coil; a Monk's Martial Arts die on monk weapons; Divine Smite
  growing with the slot; the +1 minimum of Aura of Protection.
- The skills of the Skilled and Skill Expert feats are chosen on the Character tab.
- The Combat section lists your senses and the damage types you resist.
- Ritual spells can be cast without a slot with a right-click. Taking damage while
  concentrating rolls the Constitution save and ends the spell on a failure.
- Tool proficiencies: the tools your class and background name are on the sheet, others
  are ticked under Customize, and each has a check to click.
- Spells with several rays, beams or shards roll every attack in one click, with more
  of them for a higher slot or level.
- A spell's tooltip says when it is a bonus action, a reaction or a long casting, and
  when it needs a component with a price.
- Rage adds its damage, and Reckless Attack its advantage, to Strength attacks only.
- Unarmored Movement, Fast Movement, Roving and Martial Arts stop counting in the
  armor the rules name; the passive's tooltip says so.
- A Warlock can take Agonizing Blast, Eldritch Spear, Repelling Blast and Lessons of
  the First Ones more than once. Unticking a pick also drops what builds on it.
- Overchannel keeps count of its uses and rolls the growing damage for the slot level.
- A Death Knight's undead steed has its Ghostly Stride.
- A Mage has a spellbook. Spells are written in and removed under Customize,
  Spellbook. "Open spellbook" on the sheet shows the whole book: left-click casts,
  right-click prepares a spell or puts it away, up to the number the level allows. A
  ritual can be cast straight from the book without being prepared.
- Making a character and taking a level now ask for spells: the cantrips of a
  spellcasting class, and for a Mage the spells to write into the spellbook.
- Wherever spells are listed to choose from, the core spells and the spells of
  Azeroth are shown apart: in the level dialog, the spellbook and the dropdowns.
- Spells are listed per spell level, in the level dialog, the spellbook and on the
  sheet, and each level's line shows the spell slots left of that level.
- Concentration ends by itself at 0 hit points and when you become incapacitated,
  paralyzed, petrified, stunned or unconscious.
- In a Wild Shape form spells can't be cast, except a Circle of the Moon druid's
  circle spells and, from level 18, spells without a priced component. The form ends
  at 0 hit points and when incapacitated. The Armor Class row says when it shows the
  form's own.
- Inventory: track your coins (add, spend, get change), carry and buy gear with
  prices and weights, see your load against your carrying capacity, and equip and
  attune magic items (three at most) whose bonuses are applied. Weapons can have a
  magic bonus, and the creation wizard asks for starting gold.
- An item browser replaces the dropdowns for adding items: a window of its own with
  a tab for what you carry and one per kind of item, a search box, and every item
  as a block that says what it is and does, with Add, Buy, Equip and Remove buttons.
  Open it with "Browse items" on the sheet's Items tab or under Customize > Inventory.
- The sheet window can be minimized with the new button in its title bar (or under
  General): it shows only the title bar, opens while the mouse is over it and folds
  up again when the mouse leaves. It also can't be made narrower than 300 any more,
  so rows and tabs don't wrap.
- The sheet is split into a top part and tabs, so it no longer grows past the
  screen. Hit points, rests, conditions, the combat numbers and your weapon are
  always shown; Actions (abilities, spells, companion), Checks (ability checks and
  saving throws), Skills (with tools), Traits (passives, languages, renown) and
  Items (coins and inventory) are tabs. The open tab is remembered.
- The creation wizard has a starting closet in place of the single main weapon. It
  opens as the item browser: every weapon, suit of armor and piece of gear is a
  block that says what it does, with Take, Put back and Equip buttons. Take as many
  things as you like, more than one of each too; everything taken goes into the
  inventory.
- Equipping armor, a shield or a basic weapon in the inventory now does something:
  the armor counts for your Armor Class (one suit at a time), the shield is raised,
  and the weapon joins the ones on the weapon row. Putting it away takes it off the
  sheet without losing its settings. The Defense page keeps the items in step.
- "Take damage" and "Heal" under the HP bar (and `/sheet damage 14 fire`,
  `/sheet heal 8`): the sheet halves damage you resist, doubles damage you are
  vulnerable to, ignores damage you are immune to, uses temporary hit points first,
  rolls your concentration save and handles dropping to 0. The Combat section lists
  immunities, vulnerabilities and conditions you can't be put under.
- Each faction shows its own renown perks next to the general ones, and the sheet
  adds the ones it can use while your renown is high enough.
- An Armoury: save any weapon to keep it for all your characters, add a copy to
  another character, and rename, delete or share stored weapons as a text string.
- Importing a sheet no longer turns a Blowgun's 1 damage into 1d2.
- A Beast Master of level 11 can roll both of the companion's strikes in one click. A
  swarm form no longer gets Wild Shape's temporary hit points.
- Feats ask for their own choices and apply them: Magic Initiate's list, ability and
  spells (the 1st-level spell is always prepared with one free casting per long
  rest), the skill of Keen Mind and Observant, Elemental Adept's damage type,
  Crafter's tools, Musician's instruments, the spells of Fey-Touched, Shadow-Touched
  and Ritual Caster, and the picks of the Boons of Skill and Energy Resistance.
- Priests, Druids, Evokers, Paladins, Hunters, Warlocks, Death Knights and Demon
  Hunters choose their prepared spells in the level dialog when they are made and
  each time they level. Spells you had already added by hand count as your picks.
- Casting with a higher spell slot covers everything it can change: extra targets,
  longer durations, bigger areas and fixed amounts are stated in the announcement
  and tooltip, and second dice parts (such as Ice Knife's burst) and fixed bonuses
  (False Life, Magic Missile, Disintegrate) are rolled.
- Psychic Veil and Rend Mind spend Psionic Energy Dice by themselves once their free
  use is gone. The Companion section shows the pet's Armor Class, speed and darkvision.
- Wild Shape: druids can learn any of 90 beasts, grouped by challenge rating, with the
  bigger ones for the Circle of the Moon. A beast form also gives the beast's
  Constitution for checks and saves and its darkvision or blindsight; your hit points
  stay your own.
- Beast Masters get a Companion section: the pet's own ability checks and saving
  throws, and a strike that rolls the charge damage and calls out prone, grapple and
  the family's weapon mastery when it is one of your mastery picks.
- Warlocks choose their Mystic Arcanum spells, and Mages their Spell Mastery and
  Signature Spells, when they level. The chosen spells sit on the spell list and are
  cast without a spell slot: once per rest, or at will for mastered spells.
- Font of Magic can make spell slots above your usual number; they last until a long
  rest.
- Casting Metamorphosis asks which benefit you take and applies it: low force damage
  dice count as 3 (Devourer), 1d6 more fire damage on melee hits (Havoc), or +2 Armor
  Class and 5 hit points (Vengeance). It shows as a passive you switch off when the
  spell ends; a rest ends it too.
- Tactical Mind, Psi-Bolstered Knack and Homing Strikes let you take the use or die
  back with one click when the roll still fails or misses: a link in chat, or a
  right-click on the ability. Psychic Whispers is free the first time after each long
  rest.
- Battle Masters choose their Student of War artisan's tools in the level dialog; the
  sheet grants the proficiency.
- Curse of Agony's die grows: after casting, click the spell again each time the
  target fails its save (no slot is spent), and right-click to end it.
- A beast form that would run out during a rest ends when you take it: on a short
  rest below level 4, on a long rest below level 18.
- Arcane Pulse no longer grows with level.
- Rule terms in announcements are links for anyone with the addon: hover [Vex],
  [Poisoned], a weapon, spell or skill to see what it is, and click to see the
  maths behind it. Clicking another player's term asks their addon. Without the
  addon the terms are plain text in square brackets.
- A "Next roll" row switches between normal, advantage and disadvantage, for one
  roll or for every roll.
- A small [?] in front of the numbers on the sheet shows, to you alone, how each is
  worked out: weapon, Armor Class, checks, saves, skills, initiative, spells.
- All 38 basic weapons with their damage, properties and mastery. The creation
  wizard offers the ones your class is proficient with as your main weapon; any can
  be added under Customize, next to weapons of your own. Versatile weapons can be
  held in two hands, damage is announced with its type, and Fighting Styles apply
  to the weapons they fit by themselves.
- Specialization suggestions: the creation wizard and the level dialog show what
  your specialization suggests at each level (subclass, Fighting Style, weapons,
  spells) and pre-select the single picks.
- The wizards follow the rules; the Customize pages don't hold you to them and flag
  in red where a choice goes beyond what the rules allow.
- The setting's own spells for every class (69 of them, from Rune Strike to Tree of
  Life) can be added from the spell list, at any level you have slots for. A Death
  Knight's and Demon Hunter's subclass spells are added as always prepared.
- Numbers checked against the rules: Darkflight, Azerite Surge, Devouring Plague and
  Holy Bolt now roll and track what they should; Haranir learn Entangle and Spike
  Growth; the setting's feats and the class-only Fighting Styles are included.
- Species traits work: Skillful and Keen Senses ask for a skill and Versatile for an
  origin feat (in the wizard and under Customize); traits with uses, such as
  Adrenaline Rush, Stonecunning and Relentless Endurance, are clickable with a bar;
  Troll Healing, Inner Peace and Quiet Contemplation change what hit dice heal.
- Choices follow the rules' limits: feat prerequisites, how many weapon masteries a
  class can use, cantrips known and spells prepared, spell levels you have slots for,
  armor and shield training, the level a hero class starts at, and a subclass and
  Fighting Style being part of the level that grants them. Casting a concentration
  spell marks you as concentrating and ends the earlier one.
- Fighting Style is a choice with working effects: Archery, Dueling, Thrown Weapon
  Fighting and Great Weapon Fighting change your weapon rolls, Defense your Armor
  Class. It is asked in the creation wizard and when a level grants it.
- Weapon Mastery: each weapon can have a mastery, shown on its row and called out
  when you attack, with the Topple save DC and Graze damage worked out.
- Conditions and exhaustion on the sheet. Conditions are picked from a menu and
  announced; exhaustion lowers d20 rolls and speed by itself. Both are shared with
  other RP Sheet users.
- Feats can be picked from a list when levelling: 41 general feats, the 10 origin
  feats and 12 Epic Boons, each with a summary. The ones that change numbers do so
  by themselves.
- Common cantrips and 1st-level spells for your class can be added from a list with
  their dice and saves filled in. Cantrip dice grow with level.
- A lineage's level 3 and level 5 spells are clickable, with one use per long rest.
- The settings, creation wizard and level dialog have a solid background in the
  theme's colour.
- Settings are simpler: the Character tab is an overview with the creation wizard and
  levelling, and every page that edits the character directly sits under one
  Customize tab.
- Slider handles move in steps, and sliders only reach the values they may take.
- Levelling is done one level at a time. "Take level" opens a dialog that shows what
  the level gives and asks for its choices: an Ability Score Improvement or a feat,
  an Epic Boon at level 19, a subclass at level 3. "Back to level" undoes exactly
  what the last level gave. Choices are stored per level and can be changed later
  on the Character tab.
- Features with a set number of uses per rest (Divine Intervention, Tireless, Stroke of
  Luck and others) are clickable and have their own bar that refills on a rest.
- Languages grey out once you have picked as many as you are allowed.
- Shared stats: long summaries are no longer cut short, and Hit Dice no longer take
  the place of a class resource in the tooltip.
- Character creation wizard: class, origin, ability scores, alignment and details.
  Offered automatically for a profile without a character; `/sheet new` reopens it.
- Thirteen classes, seventeen species and sixteen backgrounds to choose from.
- Levels 1 to 20: proficiency bonus, hit points, spell slots and class resources.
- Saving throws, initiative, spell save DC and spell attack on the sheet.
- Skill proficiency and expertise.
- Any number of custom resources; abilities are now lists of steps (spend, roll, dice,
  switch a passive).
- Passive effects can use character level and proficiency bonus, and can target saving
  throws, initiative, speed and spell numbers.
- Long rest button and `/sheet rest`.
- Advantage and disadvantage: Shift-click or Ctrl-click any roll.
- Short rests, hit dice, temporary HP, Heroic Inspiration and death saves.
- Core class features added automatically by class and level, with dice and bonuses
  that follow the level.
- Subclass features for all 28 subclasses, the Death Knight, Demon Hunter and Shaman
  class changes, and ability score improvements when levelling.
- A spell list: enter your spells and cast them from the sheet.
- Renown as a list per faction, and a limit on how many languages can be picked.
- Lineages for elves, draenei, tauren and trolls; allegiance, languages and renown.
- Hover explanations for abilities, skills, feats and traits.
- Import and export: a character as one text string, in the "Import / Export" tab.
- Fonts and bar textures from other addons can be used in themes (LibSharedMedia).
- "Settings profiles" tab to copy or reset the general settings and theme.
- Code reorganised into small single-purpose files.
- Sheets from earlier versions are converted automatically.


## 0.6.0-beta1

First public beta.

- Character sheet window with HP, resource and counter bars, AC, stats, skills, weapons,
  abilities and passives.
- Click to roll with the game's real `/roll`, announced to Emote, Party, Raid or yourself.
- In-game character editor: 27-point buy, race size, armor, shield, class resource,
  weapons, abilities and passives.
- Passives with working effects on AC, HP, resource, attack, damage, healing and skills.
- One sheet per Total RP 3 profile.
- Stats section in Total RP 3 tooltips, synced between RP Sheet users.
- Themes, minimap icon and lockable window.

Known gaps: syncing between two players and Total RP 3 profile switching have had little
testing. Please report problems on the GitHub issues page.
