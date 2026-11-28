# RP Sheet

A tabletop character sheet inside World of Warcraft, for people who roleplay with dice.
You make a character with a step-by-step wizard, then click a check, a weapon, a spell or
an ability on the sheet: the addon rolls, does the sums the rules ask for, and tells your
group the result.

It follows the 2024 rules of D&D 5e (often called 5.5e) as used by the *D&D: World of
Warcraft* setting book. You need the books for the full text of features; the addon
handles the numbers and gives short summaries in its own words.

- **For whom:** players in a roleplay group or campaign that uses those rules, and DMs
  who want their players' rolls and numbers to be checkable.
- **Needs:** retail WoW (interface 12.1.5) or WoW Forever (1.60). Nothing else.
- **Optional:** [Total RP 3](https://www.curseforge.com/wow/addons/total-rp-3). With it,
  each Total RP 3 profile has its own sheet, your character's name comes from the
  profile, and stats show in its tooltips.

## Features

**Make a character**

- A creation wizard in five steps: class, origin, ability scores, alignment and
  allegiance, details. It only lets you go on when a step is complete.
- Thirteen classes with their subclasses and specializations, seventeen species (with
  lineages) and sixteen backgrounds. Point buy, standard array or scores set by hand.
- Levels 1 to 20, and more than one class from the start if you want.
- Starting gear: the ready sets of your class and background, or a closet where you
  take what you like, and starting gold.
- An example character to look at, and import and export of a whole character as one
  text string.

**Play**

- **Roll** ability checks, saving throws, skills, tools, initiative and spell attacks
  by clicking them. In retail, rolls use the game's real `/roll`, so others can verify
  them, and the total is announced, for example
  `rolls [Stealth]: 14 + 5 = 19`. WoW Forever lets an addon speak in chat only straight
  from a click, before a `/roll` result could come back, so there the sheet rolls the
  dice itself and announces at once.
- **Advantage and disadvantage** with Shift or Ctrl, or set for the next roll.
  Conditions, armor, features, feats and items that give either are applied by the
  sheet, and the two cancel out as the rules say.
- **Attack** with the weapon in hand: to hit, then damage, with critical hits, Fighting
  Styles, weapon mastery and magic bonuses counted. With no weapon in hand, an Unarmed
  Strike (1 + Strength bludgeoning); its tooltip gives the save DC for a grapple or
  shove.
- **Cast** spells from a list with slots, save DC, dice, concentration, rituals,
  higher slots and components. A Mage has a spellbook window; classes that change
  prepared spells after a long rest have a window for that.
- **Use class features** as clickable abilities with their costs, dice and uses per
  rest, and passives you switch on and off.
- **Take damage and heal** by amount and type: resistance, vulnerability, immunity,
  temporary hit points, the concentration save and dropping to 0 are handled, and so
  are your features that change damage (Evasion, Uncanny Dodge, Heavy Armor Master,
  Death Ward, Relentless Rage and more) and falling. Heal takes your own healing roll
  or rolls a healing spell someone else cast on you. Death saves, conditions and
  exhaustion are on the sheet.
- **Rest:** short and long rests, and Hit Dice to spend.
- **Companions and forms:** a Beast Master's companion, Wild Shape forms and
  Metamorphosis, each with their own numbers while they are on.
- A small **?** in front of a number shows, to you alone, how it is worked out.
- **Every window looks the same way.** A row of a list has a thin line under it and
  lights up under the mouse; a button is a filled shape; a number worth a glance is a
  tile. Plain text is only read. The sheet's pages are tabs under its top part.
  Text wraps when it doesn't fit; a switch that is off is greyed.

**Level up and multiclass**

- Levels are taken one at a time in a level dialog that shows what the level gives and
  asks for its choices: subclass, Ability Score Improvement or feat, Fighting Style,
  spells, expertise, maneuvers, Metamagic, invocations, beast forms and more.
- Going back a level undoes exactly what that level gave.
- The next level can be taken in another class; the sheet checks the scores it needs
  and works out hit points, Hit Dice, features and spell slots class by class.

**Inventory, crafting, mounts**

- Coins with change, carried gear with prices and weight against your carrying
  capacity, and magic items you equip and attune (three at most).
- An item browser: every listed item as a block that says what it is and does, with
  buttons to add, buy, equip and remove it.
- Professions on a Trade tab: gathering checks, materials, a crafting window with
  recipes, spell scrolls to scribe and read.
- A stable for mounts, vehicles and companion creatures: buy them, ride them, and see
  the mount's speed on your Speed row.

**Fight in turns**

- A **combat session** for your party or raid: one of you starts it and owns it, the
  others join from the combat window (`/sheet combat`, or the "Combat session" row of
  the sheet). Whoever fights together picks the same group, one of the game's eight
  target marks.
- **Initiative** is rolled by everyone for their own character when the owner calls
  for it, and the turns go round in that order. Someone who joins a fight that is
  running rolls too and acts when their place comes up.
- **The combat window** is your own character's place in the fight, in three parts
  that keep their place. On top is who is here, in initiative order, each with a
  health bar you click to pick them, then your own line: hit points, Armor Class, and
  a square each for your action, bonus action and reaction, green while it is free,
  with "End turn" under it. In the middle are your buttons. At the bottom is the
  fight's log, which scrolls by itself: what the session said, hits in red, misses in
  grey, healing in green. What can be clicked is a button, a tab or a bar.
- **Your target** is picked in the row of buttons above your actions, one for everyone
  else in the fight (a click on their health bar does the same). An attack roll at
  your target is settled by the session: it says whether it hits. An attack clicked
  with no one picked asks who it is for first.
- **On your turn** the buttons are what your character can do, behind tabs: its attack,
  abilities, cantrips, prepared spells and the actions everyone has. What it can't do
  right now is a greyed button that says why (action used, no slot left, not your
  turn).
- **The session window** is for whoever runs the session (`/sheet session`; it opens
  by itself when you start one). It has the same roster and log, "Next turn" or "Call
  for initiative", the attacks of the creature whose turn it is, and the tools:
  damage, healing and saving throws for whoever you pick, adding creatures, handing
  the session over and ending it.
- **The owner's game announces** for everyone: whose turn it is, each player's rolls,
  whether an attack roll hits the combatant it was aimed at, and who drops to 0.
- **What lasts a number of rounds is counted** in your own turns: a spell you cast in
  the fight that lasts an hour or less, and a feature you switch on for a time (a
  rage, Sacred Weapon, a reckless attack). The window lists each with the rounds it
  has left; when its time is up it ends by itself and the owner's game says so.
- **The owner runs the fight** from the same window: adds combatants of their own (a
  creature, or a player without the addon) with a name, Armor Class and hit points;
  rolls their attacks and saves; asks a player for a saving throw and has the result
  held against the DC; deals damage and heals, which the target's own sheet applies;
  and can hand the session to another player.
- **Creatures from a list:** the 84 creatures of the setting, from a Mechanostrider to
  the Lich King, each with its Armor Class, hit points, saves, attacks and what it
  resists. One you add knows its attacks: on its turn you click "Fel Claw" and your
  game rolls to hit against the combatant you picked and, on a hit, the damage, which
  the target takes. With only one opponent it is aimed at them without a click. The
  saves it forces work the same way, with the damage following the result.
- **The list is sorted** behind four tabs: by type (dragon, undead, fiend), by people
  (demons, naga, nerubians), by side (Burning Legion, Scourge, Scarlet Crusade,
  Dragonflights) and by challenge. A group is a button; so is each creature in it. A
  typed part of a name looks through all of them at once.
- **Alone:** you can start a session without a group, add a creature and play it
  against your own character, to try a fight out.
- Your hit points, slots and resources from **before the fight** are kept: afterwards
  you put them back or keep the outcome.

**Share with the group**

- Announcements go to Emote, Party or Raid, or to yourself only.
- Rule terms in announcements are links for everyone who has the addon: hover for what
  the term means, click for the maths behind the number.
- With Total RP 3, your stats show in your tooltip, and other RP Sheet users' stats in
  theirs.

**Customize**

- Every part of the character can be changed directly under Customize, for a DM's
  ruling or a house rule. Abilities, passives, resources, weapons, spells, items and
  mounts of your own can be built from scratch.
- Seven themes, and every colour, the font, the size and the bar texture can be
  changed. The sheet can be locked, or minimized to its title bar.
- An armoury keeps weapons of your own for all your characters.

## Install

1. Download the latest zip from the
   [Releases page](https://github.com/PerfectionVR/RPSheet/releases).
2. Extract it into `World of Warcraft\_retail_\Interface\AddOns\` (for WoW Forever:
   `World of Warcraft\_forever_\Interface\AddOns\`). You should end up with
   an `RPSheet` folder that contains `RPSheet.toc`.
3. Restart the game or `/reload`.

Use the release zip rather than "Download ZIP" on the repository page: the libraries the
addon needs are added when a release is built and are not stored in the repository.

### Building it yourself

Releases are built by the [BigWigsMods packager](https://github.com/BigWigsMods/packager)
from `.pkgmeta`. Pushing a tag such as `v1.2.3` publishes a release; a tag containing
`alpha` or `beta` is published as that type. To run a development copy straight from a
clone, copy the libraries listed under "Bundled libraries" into a `Libs` folder, or run
the packager locally.

## Getting started

### 1. The creation wizard

A few seconds after you log in on a profile that has no character yet, the wizard opens
by itself. `/sheet new` opens it at any time. **Next** stays grey until the step is
complete, and a red line above the buttons says what is missing. **Not now** closes it
without making a character; it is not offered again for that profile, but `/sheet new`
still works.

| Step | What you do |
|---|---|
| 1. Choose a class | Pick the class and the level (the hero classes, Death Knight, Demon Hunter and Evoker, are set to level 3 when picked). Pick the class skills (the rest grey out once you have enough). From level 3 pick a subclass. A specialization is optional: it has no rules of its own, but it suggests a subclass, Fighting Style, weapons and spells and pre-selects the single picks. A Fighting Style is asked for if the class has one by that level. Under "More classes" you can split the levels over further classes. |
| 2. Determine origin | Species (and size or lineage where the species has a choice), background, and the picks some species traits ask for (a skill, an origin feat). |
| 3. Determine ability scores | Point buy (27 points), the standard array, or scores set by hand. Then place the background's three points: +2 and +1, or +1 on three abilities. Sliders only reach what you can still afford. |
| 4. Choose an alignment and allegiance | Alignment is a short description of your character's outlook, picked from a list. Allegiance (Alliance, Horde or neutral) decides your common tongue and, for some species, starting renown. |
| 5. Fill in details | Starting gear: take your class's and your background's ready sets with one button each, or open the closet and take what you like, ticking what you wear and wield. Set your starting gold. If the profile already had a character, a tick box lets you carry over what you made by hand. |

Highlighted words in the wizard's summaries can be hovered for an explanation.

**Create character** makes the sheet. Choices the wizard doesn't ask about (cantrips and
spells, expertise, feats of earlier levels, maneuvers and the like) are asked straight
afterwards in the level dialog, one level at a time; they also stay available on the
Character tab of the settings.

To look around first, open the settings (`/sheet config`), go to **General** and press
**Load example character**.

### 2. The sheet window

`/sheet` or a left-click on the minimap icon shows and hides it.

**Title bar.** Drag it to move the window; drag the bottom-right corner to resize it (it
won't go narrower than its six tabs need). The buttons on the right:

| Button | What it does |
|---|---|
| Minus / plus | Minimize: the window folds up to its title bar, opens while the mouse is over it, and folds up again shortly after the mouse leaves. Click again to keep it open. |
| Cog | Opens the settings and character editor. |
| Padlock | Lock: the window can't be moved or resized, and clicks on its title bar, background and edges go through to the game. The rows stay clickable. |
| x | Hides the window. |

**Top part.** Always shown, above the tabs:

- A summary line (level, class, species, alignment).
- **Announce to:** click to switch between Emote, Party, Raid and Self only.
- **Next roll:** normal, advantage or disadvantage for the next d20. Left-click cycles;
  it goes back to normal after one roll. Right-click keeps it for every roll.
- **Cast at:** only with spell slots of more than one level. Click to cast your next
  spell with a higher slot.
- **Short rest** and **Long rest.** One click takes the rest and announces it.
- Bars for hit points, Hit Dice, class resources and your own resources; temporary HP
  and Heroic Inspiration; **Take damage** and **Heal**; death saves while you are at 0
  hit points; your spell slots.
- **Conditions** (click for a menu of tick boxes) and **Exhaustion**.
- **Combat:** Armor Class, initiative, speed (and swim, climb or fly speeds when you
  have one), proficiency bonus, passive Perception, spell save DC and spell attack,
  senses, and what you resist, are immune to or vulnerable to.
- The **weapon row:** the weapon in hand, with its to-hit and damage; with none, the
  Unarmed Strike (right-click opens the Items tab to equip a weapon).

**Tabs.** The open tab is remembered per game character.

| Tab | What is on it |
|---|---|
| Actions | Your companion (if you have one), your abilities, and your spells by level with the slots left. Mages get "Open spellbook"; classes that change prepared spells after a long rest get "Change prepared spells". |
| Checks | The six ability checks and the six saving throws. |
| Skills | Every skill (proficient ones highlighted, a `*` for expertise) and your tools. |
| Traits | Passives and traits, each a switch; languages and renown. |
| Items | "Browse items", coins, attuned items, weight carried, every item as a row; then "Browse the stable" and your mounts, vehicles and companion creatures. |
| Trade | Profession skill, "Make something", the professions you practise, gathering checks by region, archaeology fragments and gathered materials. |

### 3. Clicking

Every row has a tooltip that says what a click does. The ones worth knowing by heart:

| On | Left-click | Right-click | With a key |
|---|---|---|---|
| Any roll (check, save, skill, tool, initiative, attack, spell attack, ability) | Roll it | | **Shift**: advantage. **Ctrl**: disadvantage. |
| A button with **?** in front | Click the ? itself to see how the number is worked out. A button that does nothing else explains wherever it is clicked | | **Alt**-click anywhere on the button does the same |
| Weapon row | Attack: to hit, then damage | Swap to the next ready weapon | |
| Ability | Use it: pays its cost, rolls, announces | Take back a cost the feature lets you take back | |
| Spell | Cast it | Cast a ritual spell as a ritual, without a slot | |
| Passive | Switch it on or off | | |
| HP, resource bars, temporary HP, spell slots | +1 | -1 | **Shift**-click: reset |
| Hit Dice bar | Spend one: rolls the die and heals | Give one back | **Shift**-click: reset |
| Death saves (at 0 HP) | Roll one | Start the count over | |
| Exhaustion | +1 | -1 | |
| Inventory item | Equip it or put it away | Attune or end the attunement | **Shift**-click: use one up (a spell scroll is read) |
| Coins | Add coins | Spend coins | |
| Mount or vehicle | Get on or off | | |
| Companion creature | Call or dismiss it | It was treated well (rolls for loyalty) | **Shift**-click: it took damage |
| Minimap icon | Show or hide the sheet | Settings | **Shift**-click: lock or unlock |

A key held while clicking wins over the "Next roll" row. When a saving throw could have
advantage against some things only (being charmed, a spell), a small menu asks what the
save is against; Shift-click skips the question and rolls with advantage.

### 4. The other windows

| Window | Opened from | What it is for |
|---|---|---|
| Item browser | "Browse items" on the Items tab | A "Carried" tab and one tab per kind of item. Each item is a block with Add, Buy, Equip, Attune and Remove buttons. A search box looks through the whole open tab; long tabs show 24 blocks a page. |
| Stable | "Browse the stable" on the Items tab | The same window on mounts, vehicles and companion creatures: Add, Buy, Ride, Call, Remove. |
| Crafting | "Make something" or a profession on the Trade tab | What your professions can make, with cost, time and what is still missing; spell scrolls to scribe. |
| Spellbook | "Open spellbook" on the Actions tab (Mage) | Every spell in the book. Left-click casts, right-click prepares a spell or puts it away. |
| Prepared spells | "Change prepared spells" on the Actions tab | The same for classes that change prepared spells after a long rest. |

The item browser, the stable and the crafting window are one window showing one of the
three at a time. Each window has the same title-bar buttons as the sheet; its cog opens
the Customize page that goes with it.

### 5. The settings window

`/sheet config`, the cog on the sheet, or a right-click on the minimap icon.

| Tab | What is there |
|---|---|
| Character | An overview; **Take level**, **Back to level**, "Next level in" (another class), the choice made at each level (click one to change it), and **New character**. |
| Customize | Pages that change the character directly: Weapons, Armoury, Spells, Spellbook (Mage), Abilities, Passives, Resources, Inventory, Mounts and companions, Class and origin, More classes, Metamagic / invocations / maneuvers (when the class has them), Lineage / languages / renown, Ability scores, Proficiencies, Professions, Defense. |
| General | The name you announce as, the announce channel, the tooltip and sharing switches, lock, minimize, the minimap icon, the wizard and the example character. |
| Appearance | Theme, colours, font, size, scale, bar texture. |
| Import / Export | A character as a text string, out and in. |
| Settings profiles | Copy, reset or switch the general settings and theme. Characters are not part of these profiles. |

## Slash commands

`/rpsheet` works in place of `/sheet` everywhere.

| Command | What it does |
|---|---|
| `/sheet` | Shows or hides the sheet. |
| `/sheet config` | Opens the settings and character editor. |
| `/sheet new` | Opens the creation wizard. Finishing it replaces the character; closing it changes nothing. |
| `/sheet lock` | Locks or unlocks the sheet window. |
| `/sheet rest` or `/sheet rest long` | Takes a long rest. |
| `/sheet short` or `/sheet rest short` | Takes a short rest. |
| `/sheet undo` | Takes back the last rest, until your next roll, spell, damage or rest. |
| `/sheet tab <name>` | Opens a tab of the sheet: actions, checks, skills, traits, items, trade (a unique start of the name is enough). |
| `/sheet items` | Opens or closes the item browser. |
| `/sheet combat` | Opens or closes the combat window. |
| `/sheet session` | Opens or closes the session window, for whoever runs a combat session. |
| `/sheet level` | Opens the level dialog when a level can be taken. |
| `/sheet help` | Lists the commands. |
| `/sheet damage 14` | Takes 14 damage without a type. |
| `/sheet damage 14 fire` | Takes 14 fire damage, with your resistances, vulnerabilities and immunities applied. The types are acid, bludgeoning, cold, fire, force, lightning, necrotic, piercing, poison, psychic, radiant, slashing and thunder. |
| `/sheet damage 28 fire -5` | The same, with 5 taken off first (a ward, a reaction). |
| `/sheet damage 14 crit` | A critical hit while you are at 0 hit points: two failed death saves. |
| `/sheet heal 8` | Regains 8 hit points, up to your maximum. |

A word `/sheet` doesn't know lists the commands.

## How the rules are applied

RP Sheet follows the 2024 rules of D&D 5e (often called 5.5e) as used by the *D&D: World
of Warcraft* setting book. Where the 2014 rules differ, the sheet uses the 2024 ones:
exhaustion takes 2 from every d20 roll and 5 feet of speed per level, a long rest gives
back every Hit Die, backgrounds give the ability scores and an origin feat, every
subclass starts at level 3, weapons have a mastery, the concentration save stops at
DC 30, a healing potion is a bonus action, and an Unarmed Strike can grapple or shove
against a save DC. It doesn't offer the 2014 rules.

The thirteen World of Warcraft classes each build on a Player's Handbook class (Death
Knight and Paladin on Paladin, Demon Hunter and Hunter on Ranger, Evoker on Sorcerer,
Mage on Wizard, Priest on Cleric, Shaman on Barbarian, Warrior on Fighter).

### What the sheet does by itself

- **Numbers:** proficiency bonus, hit points, Armor Class (armor, shield, Unarmored
  Defense, magic bonuses, a form's own), initiative, speeds, saving throws, skills,
  spell save DC and spell attack, spell slots (shared slots for several spellcasting
  classes, Pact Magic beside them), class resources and carrying capacity.
- **Features:** class and subclass features arrive as abilities and passives at their
  level and are taken off again when you go back down. Their dice and bonuses follow
  your level. Species traits, the background's skills and origin feat, lineage spells,
  feats and faction perks are added the same way.
- **Rolls:** advantage and disadvantage from conditions, armor, features, feats, items
  and a loyal companion; Strength and Dexterity saves that fail without a roll while
  paralyzed, petrified, stunned or unconscious; a natural 20 doubling the damage
  dice; exhaustion on every d20 and on speed.
- **Casting:** the lowest free slot that fits (or the one set at "Cast at"), extra dice
  and other growth with a higher slot, concentration (a new spell ends the earlier
  one), the concentration save when you take damage, protective spells cast on
  yourself, and spells that can't be cast in a beast form.
- **Damage:** "Take damage" halves, doubles or ignores the amount as your defenses
  say, uses temporary hit points first, and handles 0 hit points and death saves. Your
  features that change damage are boxes to tick in its menu while you can use them
  (a reaction is spent until you say it is back, roll initiative or rest); "A fall"
  rolls falling damage from the distance.
- **Items:** equipping armor, a shield or a weapon puts it on the sheet; magic items
  count while equipped and, where they ask for it, attuned; carrying too much holds
  your speed to 5 feet.
- **Rests:** a long rest refills everything, removes one level of exhaustion and ends
  what doesn't outlast it; a short rest gives back what recharges on one.

### What stays your call, or the DM's

- **Time.** The sheet keeps no clock. Outside a combat session a spell's duration and
  a feature's minutes are ended by hand or by a rest; in a session they are counted
  in rounds. A beast form's hours and "once a turn" effects are yours to keep
  everywhere.
- **Conditions** are ticked by you. The sheet applies what they do to your own rolls and
  speed; it does not stop you from ticking one you are immune to.
- **Situations.** Advantage that depends on the target or on what you can see, cover,
  and anything else the sheet can't know: use Shift, Ctrl or the "Next roll" row.
- **Passives** that only hold some of the time (a stance, Rage, a protective spell
  someone cast on you) are switched on and off by you.
- **Other people's saves and hit points.** A spell shows its save DC and rolls its dice;
  whether the target fails is settled at the table.
- **The HP bar by hand.** Clicking the bar changes hit points without any rule; use it
  for a ruling, or to bring a dead character back.

### Switches that turn a check off

| Switch | Where | What it turns off |
|---|---|---|
| Check spell components | Customize > Spells | Needing to carry a spell's priced component, and using it up when the casting consumes it. |
| Check that you carry the tool | Customize > Professions | Needing the profession's tool among your items to make or gather something. |

Both are on by default and are kept per character.

### Combat sessions

| Rule | How the session applies it |
|---|---|
| Initiative | Each player rolls the sheet's own initiative, with its advantage, conditions and bonuses. The order is the totals from high to low and stays the same every round. A tie goes to the higher Dexterity modifier, then by name. |
| Joining a running fight | The rules have no separate rule for it: the newcomer rolls initiative like everyone and takes that place in the order. |
| A turn | One action, one bonus action, and only one spell that spends a slot. The Attack action is as many attacks as Extra Attack gives; Action Surge gives a second action. What the turn doesn't allow is refused with the reason, in the combat window and on the sheet alike. |
| Reactions | Usable on anyone's turn, once, and back at the start of your own. |
| What a feature costs | Read from how its description starts ("Bonus action: ...", "Reaction: ..."); a spell's from its casting time. A spell that takes a minute or longer, or a ritual, is not offered in a fight. |
| Durations | A round goes by for what you have running each time your own turn starts: a spell of a minute ends when your tenth turn after the casting starts, one of a round when your next turn does. Counted: spells cast during the fight that last an hour or less, and features switched on for a time. A spell you concentrate on ends your concentration; another takes its protection and later rolls with it. Something started on someone else's turn (a reaction) is counted from your next turn, so it can end up to a round early. |
| A rage | Counted for its ten minutes. At the end of a turn of yours without an attack the sheet reminds you what keeps a rage up; it can't see a save you forced, so ending it is your click. Not said from level 15, when a rage needs no upkeep. |
| Combatants the owner runs | Typed as "Gnoll 13 22 +1": name, Armor Class, hit points, initiative bonus. They have no sheet, so their d20s (initiative, attacks, saves) are rolled by the owner's addon itself and are not /roll rolls. The owner types their damage and keeps their hit points; one at 0 hit points is passed over in the order. |
| Creatures from the list | Names and numbers only: Armor Class, average hit points, initiative bonus, saving throw bonuses, resistances, immunities and vulnerabilities, each attack's bonus and damage dice, and each save it forces with its DC and damage. Their traits, spells, multiattack routines, recharges, legendary actions and the conditions their attacks cause are not in the list: those stay with whoever runs the creature. |
| Groups in the creature list | Type is the creature's own. People and side are this addon's sorting by name, for finding a creature, and have no effect on any roll; what fits nowhere is under "Others". |
| A creature's attack | d20 + its bonus against the picked combatant's Armor Class (the only opponent standing, when none is picked); a natural 20 doubles the damage dice. A player takes each damage type through their own "Take damage"; another creature from the list halves what it resists, ignores what it is immune to and doubles what it is vulnerable to. |
| A creature's turn | One action: one attack, or two for a creature that attacks more than once a turn (the list doesn't say how many, so two is this addon's number), or one save it forces, on each combatant once. Used buttons are greyed with the reason; "Another action" frees them. Not counted: bonus actions, reactions, and acting for a creature outside its turn. |
| A save a creature forces | Asked of the picked combatant; the damage is rolled once a turn, so everyone caught takes the same. On a failure the damage is dealt, on a success half where the creature's ability says so. |
| Saving throws the owner asks for | The player rolls on their own sheet, with everything it knows about that save. The owner's game compares the total with the DC; a natural 1 or 20 decides nothing by itself. |
| Damage from the owner | Goes through the target's own "Take damage": resistance, immunity, temporary hit points, wards, the save to keep concentrating and dropping to 0 all apply. Only the owner of the session you joined can do this, and only while you are in it. |
| Attack rolls | Aimed at a combatant (click their row, or target them in the game), the owner's game compares the total with their Armor Class and says hit or miss; a natural 20 hits and a natural 1 misses. Damage is taken by the target's own player with "Take damage". |

A session reaches the people in your party or raid. Alone, you can still start one to
try it.

**WoW Forever** lets an addon speak in chat only straight from a click. The owner's own
lines go out as they click; lines the owner's game makes for other players' rolls are
shown to the owner with a [Send it] link.

### Strict places and free places

| Place | How it treats the rules |
|---|---|
| Creation wizard | Strict. You can't go on until the step fits the rules: the right number of skills, all points placed, prerequisites met. |
| Level dialog | Strict. "Take level" stays grey until every choice of the level is made, exactly as many as the rules give. One pick can be exchanged where the rules allow one. |
| The sheet and the browsers | Hold to the rules in play: slots, costs, components, attunement, prices, what you can ride. |
| Customize pages | Free. Anything can be set, for a DM's ruling, a house rule or an experiment. Where a choice goes beyond the rules, the page says so in red and lets you. |

Core rules numbers follow the System Reference Document 5.2 by Wizards of the Coast,
available under the Creative Commons Attribution 4.0 licence. Sheets made with earlier
versions of the addon are converted automatically.

## Sharing and privacy

Nothing leaves the game. What other players can see is this:

| What | Who gets it | How |
|---|---|---|
| Your rolls | Whoever the game shows a `/roll` to: people nearby, or your group | In retail, the game's own `/roll`, one per die. With "Self only", and always in WoW Forever, nothing is rolled in public: the sheet rolls the dice itself. |
| Announcements | The channel at "Announce to": Emote (people nearby), Party, Raid, or only you | An ordinary chat line. If Party or Raid is chosen and you are not in one, the line is shown to you alone and says so. |
| Your stats | Your party or raid, and RP Sheet users of your own faction who hover over you or target you | Hidden addon messages. Sent: the summary line (level, class, species or lineage, alignment), Armor Class, the six ability scores, hit points and up to three resources with their current values, the weapon in hand, and your conditions and exhaustion. |
| How a number is worked out | An RP Sheet user who clicks one of your terms in chat | A hidden addon whisper back to that player, with the same breakdown your own ? shows. |

- Stats you receive are kept until you log out or reload, never saved, and shown only in
  the Total RP 3 tooltip. Everything received is treated as untrusted: numbers are
  clamped and text is stripped of colour codes and links.
- **To stop sharing:** untick "Share my stats with other RP Sheet users" on the General
  tab. Your addon then sends no stats and answers no questions about your numbers. You
  still receive what others share, and a click on another player's term then shows only
  what the rules say about it.
- **To hide the tooltip section:** untick "Show stats in Total RP 3 tooltips".
- **To keep rolls and announcements to yourself:** set "Announce to" to Self only.
- Hit Dice, spell slots, your inventory, coins and the rest of the sheet are never sent.
  An export string holds the whole character (without current hit points and resource
  values) and goes only where you paste it.
- Term links in chat are made by each player's own copy of the addon. Without the addon
  the terms are plain text in square brackets.

**Total RP 3.** With it, a sheet belongs to the Total RP 3 profile that is active, and
switching profile switches sheet. Without it, a sheet belongs to the WoW character.
"Use my Total RP 3 name" on the General tab picks which name is announced.

## Themes

Settings > Appearance.

| Preset | Look |
|---|---|
| Dark | The default: near-black, gold accents. |
| Parchment | Light: brown text on parchment, without text shadow. |
| Alliance | Dark blue and gold. |
| Horde | Dark red and orange. |
| Fel | Dark green. |
| Void | Dark purple. |
| Minimal (see-through) | A faint background without a border. |

Picking a preset copies it; every value can then be changed: background, border, accent,
text, secondary text, row highlight, the three bar colours, font, font size, window
scale, text shadow and bar texture. Fonts and bar textures that your other addons
register (LibSharedMedia) are listed too. The settings window, the creation wizard, the
level dialog and the browsers follow the theme; other addons' settings windows are left
as they are.

## Files

Each file does one job. `RPSheet.toc` lists them in load order; a file can only use what
the files above it have set up. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) explains
how the parts work together.

| Folder | What lives there |
|---|---|
| `Core/` | The addon object, small helpers, the text codec, saved-data defaults, startup and `/sheet` |
| `Data/` | Rules data, one subject per file: core numbers, classes, species, backgrounds, feats, spells and their summaries, class and subclass features, weapons, items and magic items, mounts, professions and recipes, factions, the glossary, the example character |
| `Sheet/` | The saved character and the numbers worked out from it: storage per profile, conversion of old sheets, classes and multiclassing, derived numbers, trackers, defenses, inventory, mounts, professions, the upkeep that puts features, picks and spells on the sheet, explanations, export and import |
| `Actions/` | What the character does: announcing, dice, attacks, abilities, spells, scrolls, conditions, damage, rests, death saves, gathering, trade |
| `UI/` | The sheet window: themes, the window, bar and tab widgets, rows, the sheet's sections and tabs, the item browser and its sources, the spellbook and prepared-spells windows, the dialog skin, the minimap icon |
| `Integrations/` | The Total RP 3 tooltip section, syncing with other players, term links in chat, combat sessions (`Fight*.lua`) |
| `Options/` | The settings window: one file per tab or Customize page, the level dialog in parts, assembled by `Root.lua` |
| `Wizard/` | Character creation: grants, the draft, more classes, Fighting Styles, the starting closet and gear sets, the pages, the dialog |
| `tests/` | Regression tests that run the code outside the game (not shipped) |
| `docs/` | The architecture notes and the checklist of things to check in the game (not shipped) |

To add a theme, edit `UI/Themes.lua`. To change rules numbers, edit the files in `Data/`.

## Tests

`tests/` runs the addon's code outside the game, in a fake game environment: every
file loads, every class is built and levelled from 1 to 20, and every row, button and
settings option is clicked. See [tests/README.md](tests/README.md) for what it needs
and what it can't check (nothing is drawn). Release zips leave the folder out.

## Not built yet

- **More that a turn could count:** conditions that end after a number of rounds, a
  spell someone else cast on you, what was already running when the fight started,
  "once a turn" effects, and a beast form's hours. There is no clock outside combat,
  and none is planned.
- **More for a session's owner:** creatures of your own making kept as templates,
  the core rules' creatures, a creature's traits and conditions, hiding a creature's
  hit points from the players, and a save asked of several combatants at once.
- **Movement** in a turn is not counted.
- **Combat sessions tried in game.** They are simulated with four players in
  `tests/t-sync-fight.lua`, their durations with two in `tests/t-sync-rounds.lua`, the
  owner's tools with three in `tests/t-sync-owner.lua`, a fight alone against creatures
  from the list in `tests/t-sync-solo.lua`, and clicked through for every class in
  `tests/t-test-windows-fight.lua`.
- **Playing every class in game.** The Warrior, the Mage and the Druid have been
  played; the other ten run only in the tests.
- **Syncing confirmed in game by two players.** It is simulated with two and three
  players in `tests/t-sync-*.lua`; the in-game script is in
  [docs/MANUAL-CHECKS.md](docs/MANUAL-CHECKS.md).

## State of the rules

"Fully implemented" means the sheet works out and applies by itself every number, roll,
use, condition and limit the rule gives, and shows in its own words what only the table
can settle (roleplay, the DM's rulings, what happens to other creatures). Anything not
listed in the three tables below is fully implemented.

Two things hold for everything, so they are said once here:

- **Time.** The sheet keeps no clock. Whatever lasts a while (a spell's duration,
  concentration, Rage, a beast form, Sacred Weapon, a blessing for the length of a
  quest) ends by hand or by a rest. Only a combat session counts time, in rounds, for
  what was started during it and lasts an hour or less. Concentration itself is
  tracked: a new spell ends the old one and damage asks for the save.
- **Played in game.** Only the Warrior, the Mage and the Druid have been played in
  World of Warcraft so far. The other ten classes run only in the test environment
  (`tests/`), which builds, levels and clicks all of them.

### Classes

All thirteen classes were checked: their 30 subclasses, 401 features (a core feature
two classes share is counted for each) and the 81 options of their choices.

| Class | Subclass | Caveat |
|---|---|---|
| All | multiclass | Paladin with Death Knight, and Hunter with Demon Hunter, can't be combined: by the rules each pair is one class with different subclasses. |
| All | multiclass | Weapon Mastery picks from several classes add up, which is one reading of a rule tables disagree on. |
| Monk | Mystic Brews | Bonus Proficiencies: a Monk already proficient in Performance picks another Monk skill under Customize, Proficiencies. |
| Rogue | Assassin | Assassin's Tools: the proficiencies are given, but the disguise kit and poisoner's kit themselves are added to the inventory by hand. |

### Spells

All 460 spells on the lists were checked. A spell not named here does what its summary
says when cast from the sheet, or has nothing a sheet could apply. What a spell does after
its casting (a later turn's attack or damage, the extra dice of a mark, a mishap) is
rolled from its row without a slot: a left-click while it runs, or the right-click menu.

| Spells | Caveat |
|---|---|
| Aid, Heroes' Feast, Vampiric Blood, Armor of Agathys, Heroism, Power Word Fortify, Consume Soul | Cast on someone else, the hit points they give are theirs to set. Vampiric Blood's extra 1d6 when you regain hit points is rolled by hand. Power Word Fortify's right-click offers your share of an even split; another split is set on the bar by hand. |
| Cure Wounds, Healing Word, Mass Healing Word, Mass Cure Wounds, Prayer of Healing, Heal, Regenerate, Aura of Vitality, Regrowth, Dream Breath, Dream Flight, Emerald Blossom, Prayer of Mending, Tranquility, Living Flame | Healing you receive goes through Heal, which offers your own last healing roll or rolls someone else's spell with healing dice; healing without dice of its own (Heal, the healing part of a damage spell) is typed there. |
| Beacon of Hope, Rain of Fire | Beacon of Hope's most healing possible isn't applied to healing you receive. Rain of Fire's advantage against a creature in the rain is given with Shift. |
| Gaseous Form, Tree of Life | The walking speed they take away (Gaseous Form) or hold at 10 feet (Tree of Life) is in the passive's words; the sheet shows your usual speed. |
| Conjure Minor Elementals, Enlarge/Reduce | Conjure Minor Elementals adds its dice to your melee weapon hits; for another attack at a creature within 15 feet, right-click the spell. A reduced creature's 1d4 less is rolled from the right-click and taken off by hand. |
| Shapechange, Polymorph, Animal Shapes | The shape-shift isn't put on the sheet: no form is switched on and its numbers aren't used. (Feral Prowl and Roar of Ursoc switch on one of your Wild Shape forms.) |
| Cordon of Arrows | The arrows or bolts are counted and taken though the site gives them no price: the spell plants them. |
| Find Familiar, Find Steed, Summon Aberration, Summon Beast, Summon Celestial, Summon Construct, Summon Dragon, Summon Elemental, Summon Fey, Summon Fiend, Summon Undead, Giant Insect, Animate Dead, Create Undead, Animate Objects, Simulacrum, Phantom Steed | The creature's numbers are not on the sheet; the summary names how a higher slot changes them. |

### Traits and passives

Checked: the 53 species traits and 15 lineages, 75 feats and epic boons, 13 Fighting
Styles, 35 invocations and 10 Metamagic options, 25 maneuvers, and the 92 renown perks
and blessings. Class passives are in the classes table.

| Kind | Name | Caveat |
|---|---|---|
| Feat | Poisoner | The poison doses you brew aren't counted; the Poisoned Weapon row rolls a dose's damage. |
| Feat | Boon of Irresistible Offense | The natural 20's extra damage is added to weapon rows, not to abilities that attack (Unarmed Strike, Pole Strike). |
| Feat | Piercer, Savage Attacker | Applied to weapon rows, not to abilities that attack (Pole Strike); "once per turn" is yours to keep. |
| Feat | Elemental Adept | Spells whose damage type is chosen as they are cast (Chromatic Orb, Dragon's Breath and the like) don't count their 1s as 2s. |
| Feat | Fists of Fury | Combo Strikes' +1 for each earlier hit on the creature this turn is added by hand. |
| Feat | Healer | Battle Medic (a creature spends a Hit Die with your healer's kit) is rolled by hand. |
| Feat | Stagger and Sway | The Delayed Reaction pool's own force damage doesn't add another die to the pool: read literally, the pool would never shrink. |
| Feat | Boon of Fortitude | The 40 hit points count; the Constitution modifier added to healing doesn't. |
| Unarmed | Unarmed Strike (no weapon in hand) | Features that add dice to every melee hit, and weapon feats, aren't added to it. |
| Unarmed | Unarmed Fighting (Fighting Style) | A Monk's strikes keep the Martial Arts die, even at the levels where the style's d8 with hands free is larger. |
| Invocation | Pact of the Blade | The pact weapon is a weapon of yours with "Pact weapon" ticked under Customize, Weapons; its necrotic, psychic or radiant damage is said by hand. |

## Known limits

Small gaps left in what is built. None is planned; say so if one matters to you.

- **Spells**: a weapon of your own (one not based on a listed weapon) serves as a
  spell's weapon component only once you set its worth, so that claws or a bite
  don't count.
- **Items**: an item saved before your edits were recorded is only refreshed from
  the item lists when it has no effects and an untouched note; newer ones follow the
  lists unless you changed them.
- **Mounts**: a rider's own weight counts only once it is entered under Customize >
  Mounts and companions; carrying capacities the rules don't list are worked out
  from Strength and marked as estimates.
- **Professions**: the time to build a vehicle is the usual crafting rate, since the
  rules give none.
- **Typed damage**: `/sheet damage` takes damage without the menu's boxes, so
  reactions such as Uncanny Dodge and Heavy Armor Master's reduction aren't offered;
  use the damage menu for those.
- **Death Ward**: it saves you from damage that would drop you to 0 hit points; an
  effect that kills without damage is yours to answer by switching the ward off.
- **Conditions**: disadvantage that depends on the target (Grappled) or on whether
  you can see what frightens you is asked with each roll, not tracked.

## Bundled libraries

Release zips include unmodified copies of these third-party libraries in the `Libs` folder,
downloaded from their own sources at build time. They are not covered by this project's
licence; each keeps its own:

| Library | Licence |
|---|---|
| [Ace3](https://www.wowace.com/projects/ace3): AceAddon, AceComm, AceConfig, AceConsole, AceDB, AceDBOptions, AceEvent, AceGUI | Ace3 Style BSD, see `Libs/Ace3-LICENSE.txt` |
| [LibDBIcon-1.0](https://www.wowace.com/projects/libdbicon-1-0) | Ace3 Style BSD, see `Libs/Ace3-LICENSE.txt` |
| [CallbackHandler-1.0](https://www.wowace.com/projects/callbackhandler) | BSD |
| [LibStub](https://www.wowace.com/projects/libstub) | Public domain |
| ChatThrottleLib (inside AceComm-3.0) | Public domain |
| [LibSerialize](https://github.com/rossnichols/LibSerialize) | MIT |
| [LibDeflate](https://github.com/SafeteeWoW/LibDeflate) | zlib |
| [LibSharedMedia-3.0](https://www.wowace.com/projects/libsharedmedia-3-0) | LGPL 2.1 |
| [LibDataBroker-1.1](https://github.com/tekkub/libdatabroker-1-1) | No licence stated by its author; included unmodified, as is common practice for addons |

## Licence

The addon's own code is released under the MIT licence; see [LICENSE](LICENSE). The bundled
libraries keep their own licences.

World of Warcraft is a trademark of Blizzard Entertainment. This addon is a fan project and
is not affiliated with or endorsed by Blizzard Entertainment or the Total RP 3 team.
