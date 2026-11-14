# RP Sheet

A small tabletop character sheet for World of Warcraft roleplay. Build a character with a
27-point buy, then click a stat, skill, weapon or ability to roll and announce the result.

Built for retail WoW (interface 12.1.5). Works on its own, and integrates with
[Total RP 3](https://www.curseforge.com/wow/addons/total-rp-3) when it is installed.

## Features

- **Character sheet window** with HP, class resource and counter bars, AC, stats, skills,
  weapons, abilities and passives.
- **Click to roll.** Rolls use the game's real `/roll`, so everyone nearby or in your group
  can verify them. The addon then announces the total, for example
  `attacks with Rapier - d20 + DEX: 14 + 3 = 17, damage 1d4 + 3: 2 + 3 = 5`.
- **In-game character editor** (`/sheet config`): point buy, race size, armor, shield,
  class resource, weapons, abilities and passives. No file editing.
- **Passives with working effects.** Each passive can add flat numbers or stat modifiers to
  AC, HP, resource, attack, damage, healing or skills, and can be switched on and off.
- **One sheet per Total RP 3 profile.** Switch TRP3 profile and the sheet switches with it.
- **Stats in the TRP3 tooltip**, below the OOC block: your own, and those of other RP Sheet
  users, which are synced automatically.
- **Import and export:** share a whole character as one text string.
- **Themes:** seven presets plus custom colours, size and scale, and any font or bar texture
  your other addons provide.
- **Minimap icon**, lockable window, and announce to Emote, Party, Raid or yourself only.

## Install

1. Download the latest zip from the
   [Releases page](https://github.com/PerfectionVR/RPSheet/releases).
2. Extract it into `World of Warcraft\_retail_\Interface\AddOns\`. You should end up with
   an `RPSheet` folder that contains `RPSheet.toc`.
3. Restart the game or `/reload`.

Use the release zip rather than "Download ZIP" on the repository page: the libraries the
addon needs are added when a release is built and are not stored in the repository.

### Building it yourself

Releases are built by the [BigWigsMods packager](https://github.com/BigWigsMods/packager)
from `.pkgmeta`. Pushing a tag such as `v0.6.0` publishes a release; a tag containing
`alpha` or `beta` is published as that type. To run a development copy straight from a
clone, copy the libraries listed under "Bundled libraries" into a `Libs` folder, or run
the packager locally.

## Usage

| Action | How |
|---|---|
| Show or hide the sheet | `/sheet`, or left-click the minimap icon |
| Edit your character and settings | `/sheet config`, the gear icon, or right-click the minimap icon |
| Lock or unlock the window | `/sheet lock`, the padlock icon, or shift-click the minimap icon |
| Roll a stat or skill check | Click it |
| Attack | Click the Attack row; right-click it to swap weapon |
| Use an ability | Click it (spends its cost, rolls, announces) |
| Change HP, resource or counter | Left-click +1, right-click -1, shift-click reset |
| Switch a passive on or off | Click it |

The first time a profile has no character, a creation wizard walks through class, origin,
ability scores, alignment and details; `/sheet new` reopens it. Levels are taken, and
undone, one at a time on the Character tab, each with its own dialog and choices. Anything
else can be changed directly under the Customize tab. The General tab also has a "Load example character" button that
fills in a finished sheet to learn from, and `/sheet rest` takes a long rest.

## Rules implemented

RP Sheet follows D&D 5e (2024 rules) as used by the *D&D: World of Warcraft* setting book.
You need the books for the full text of features; the addon handles the numbers.

- **Classes:** the thirteen World of Warcraft classes, each using its Player's Handbook
  class (Death Knight and Paladin use Paladin, Demon Hunter and Hunter use Ranger, Evoker
  uses Sorcerer, Mage uses Wizard, Priest uses Cleric, Shaman uses Barbarian, Warrior uses
  Fighter). Class sets hit die, saving throws, skill choices and spellcasting ability.
- **Origin:** seventeen species (size, speed, darkvision, traits listed as passives) and the
  sixteen Player's Handbook backgrounds (two skills, an origin feat, ability score increases).
- **Ability scores:** point buy, standard array or manual, plus +2/+1 or +1/+1/+1 from the
  background.
- **Level 1 to 20:** proficiency bonus, hit points (maximum die at level 1, average after),
  spell slots for full, half and pact casters, and class resources such as Rage, Focus
  Points, Lay on Hands and Channel Divinity.
- **Armor Class:** the standard armor table, shields, and Unarmored Defense.
- **Class features:** each class's core features arrive as ready-made abilities and
  passives when you reach their level. Subclass features do the same when
  you pick a subclass.
- **Spells:** enter the spells you know; casting one spends a slot and rolls its attack or
  dice. No spell text is built in.
- **Play:** advantage and disadvantage (Shift-click or Ctrl-click a roll), short and long
  rests, hit dice, temporary HP, Heroic Inspiration and death saves.
- **Origin extras:** lineages, allegiance, languages and faction renown.
- **Rolls:** ability checks, saving throws, skills with proficiency or expertise,
  initiative, weapon attacks (a natural 20 doubles the damage dice) and spell attacks.
- **Effects:** passives add flat numbers, ability modifiers, level or proficiency bonus to
  any of those numbers. Abilities are lists of steps (spend a resource, roll to hit, roll
  dice, switch a passive), so custom features and feats can be built freely.

Species traits, origin feats and class features that only describe behaviour are listed by
name as reminders; the addon does not reproduce the books' text. The rules data lives in
the `Data` folder. Sheets made with earlier versions are converted automatically.

Core rules numbers follow the System Reference Document 5.2 by Wizards of the Coast,
available under the Creative Commons Attribution 4.0 licence.

## Syncing with other players

Players who both run RP Sheet see each other's stats in the Total RP 3 tooltip.

- Hovering or targeting a player asks them for their stats with a hidden addon whisper.
- Your own changes are pushed to your party or raid.
- Sent: HP, AC, resource, counter, the six stats and the equipped weapon.
- Cross-faction only works inside a group. Received stats are kept for the session only.
- Sharing can be switched off in the settings.

## Files

Each file does one job. `RPSheet.toc` lists them in load order.

| Folder | What lives there |
|---|---|
| `Core/` | The addon object, small helpers, saved-data defaults, startup and `/sheet` |
| `Data/` | Rules data, one file each: core rules, classes, species, backgrounds, effects, the example character |
| `Sheet/` | The character sheet: storage per profile, conversion of old sheets, derived numbers, trackers (HP, resources, slots), summary |
| `Actions/` | What the character does: announcing, dice, weapon attacks, abilities |
| `UI/` | The sheet window: themes, window and bar widgets, rows, window lifecycle, contents, minimap icon |
| `Options/` | Settings and character editor, one file per tab, assembled by `Root.lua` |
| `Wizard/` | Character creation: grants, the draft, the pages, the dialog |
| `Integrations/` | Total RP 3 tooltip section and syncing with other players |

To add a theme, edit `UI/Themes.lua`. To change rules numbers, edit the files in `Data/`.

## Not built yet

What the rules have that the addon doesn't, kept here to track the remaining work.

**Classes**

All thirteen classes and their subclasses have been checked against the rules, feature
by feature. The Warrior, the Mage and the Druid have been played in game so far; the
other ten still need that.

- [x] Warrior, with Battle Master, Champion and all 25 maneuvers
- [x] Rogue, Monk (with the brews of the Warrior of Mystic Brews), Hunter, Demon Hunter
- [x] Paladin, Death Knight, Shaman (with totems and the Path of the Elements), Druid, Priest
- [x] Mage, Warlock (with all Eldritch Invocations, the setting's own included) and
      Evoker (with Metamagic)
- [x] A second check of the twelve classes after the Warrior against the rules, by
      one reviewer per class; what they found is fixed. The Warrior was checked the
      same way afterwards
- [ ] An in-game play-through of the ten classes other than the Warrior, Mage and Druid
- [x] Path of the Berserker (Shaman) and the War Domain (Priest), which the rules also list
- [x] Invocations that can be taken more than once; a Death Knight's undead steed
- [x] Rage and Reckless Attack only for Strength attacks; speed features and Martial
      Arts that stop in the armor the rules name
- [x] Curse of Agony (Warlock): the die grows after each failed save. Click the spell
      again for each one; right-click ends it
- [x] Metamorphosis (Demon Hunter): casting it asks which of the three benefits you
      take and applies it, as a passive you switch off when the spell ends
- [ ] Metamorphosis: the benefit ending by itself after its minute, and force damage
      from spells typed in by hand or from custom abilities counted for Devourer
- [x] Tactical Mind (Warrior), Psi-Bolstered Knack and Homing Strikes (Rogue): one
      click takes the use or die back when the roll still failed; Psychic Whispers is
      free the first time after a long rest
- [x] Rend Mind and Psychic Veil (Rogue): once the free use is gone, the sheet spends
      the dice a further use costs
- [x] Student of War (Warrior): the artisan's tools are chosen in the level dialog
- [x] Hunter pets: the 48 pet families, the companion's hit points and strike, and Pet
      Specialization at level 6 in place of Roving
- [x] The companion's own checks and saves; its strike rolls the charge die, names
      prone or grapple, and uses the family's mastery when it is one of your picks
- [x] The companion's Armor Class, speed and darkvision on the sheet
- [ ] The companion's second strike at level 11 in one click; changing its mastery
      pick only after a long rest
- [x] Cat Form and Bear Form for the Circle of the Moon: the sheet takes the form's
      Armor Class, speed, Strength and Dexterity while it is on
- [x] Fifteen beasts as Wild Shape forms a druid picks from when levelling, with their
      Armor Class, speed, Strength, Dexterity and attacks
- [x] A beast form stops spellcasting, and ends at 0 hit points, when incapacitated,
      and on a rest that outlasts it (a short rest below level 4, a long rest below
      level 18)
- [ ] Timing a beast form. It lasts half your level in hours, but the sheet keeps no
      clock, so it can't tell when you shifted. A rest therefore assumes you were in
      the form from its start, and counts a form that lasts exactly as long as the
      rest as run out. If you shift partway through a rest, switch the form back on
      afterwards. Outside rests the form never runs out by itself: switch it off when
      its hours are up
- [x] Ninety beasts as Wild Shape forms, grouped by challenge rating, the larger ones
      for the Circle of the Moon; a form's own Constitution and senses
- [ ] Beast attacks: damage that depends on the situation (a charge, a bloodied
      target) is described, not rolled; a swarm still gets Wild Shape's temporary
      hit points; a beast's own skill bonuses where they beat the character's
- [x] Always-prepared subclass spells added to the spell list by themselves
- [x] A Death Knight's spells, following the rune, and a Demon Hunter's fixed spells
      added by themselves
- [x] A Demon Hunter's set of spells, following the specialization
- [x] Expertise picks in the level dialog (Rogue, Hunter, Mage's Scholar)
- [x] Arcane Recovery, Font of Magic and Magical Cunning change spell slots by the click
- [x] Slots made with Font of Magic go above the usual number of slots, until a long rest
- [x] A Warlock's Mystic Arcanum spells and a Mage's Spell Mastery and Signature Spells
      chosen in the level dialog and cast without a slot as the rules allow
- [ ] Mystic Arcanum: swapping only one spell per level
- [ ] Multiclassing

**Spells**

- [x] Core-rule spells of every level, with level, save or attack, dice and concentration
- [ ] Hand-written summaries for the core spells above 1st level (theirs are put
      together from the spell's facts)
- [x] Extra dice when a spell is cast with a higher slot, chosen with the "Cast at" row
- [x] Spells that grow in another way with the slot: more targets, longer durations
      and fixed amounts are stated, second dice parts and fixed bonuses are rolled
- [ ] The starting number of targets of the twenty plain "one more target per slot
      level" spells read against the rules once more
- [x] Spells that make several attacks roll them all in one click (Scorching Ray,
      Eldritch Blast, Flurry, Azure Strike)
- [x] Ritual casting: right-click a ritual spell to cast it without a slot
- [x] Casting times, and components with a price, shown on each spell
- [x] A Mage's spellbook: a page under Customize to write spells in and take them
      out, and a spellbook window on the sheet to cast from and to prepare spells
- [x] Spells chosen when a character is made and when it levels: the cantrips of
      every spellcasting class, and a Mage's spellbook spells (six, and two per level)
- [x] The prepared spells of the other classes chosen the same way, exactly as many
      as the class prepares; spells added by hand before count as picks
- [ ] How often prepared spells may be swapped (any after a long rest, one per long
      rest, or one per level, by class)
- [ ] Copying spells into the book for gold and time; preparing only after a long rest
- [ ] Tracking the gold and the components themselves

**Character**

- [x] Tool proficiencies: granted by class and background or ticked by hand, with a
      check to click for each
- [ ] The professions and crafting rules
- [ ] An armoury for weapons of your own, kept between characters
- [x] Armor's disadvantage on Stealth, and the speed heavy armor costs without the
      Strength for it
- [ ] Equipment, currency and magic items
- [ ] Mounts, vehicles and companion creatures
- [x] Senses and damage resistances shown on the sheet, gathered from the species, the
      beast form and the passives switched on
- [ ] Immunities and vulnerabilities, and resistances halving damage by themselves
- [x] The perks every faction gives at each renown tier, shown with the score
- [ ] Each faction's own renown perks
- [x] The skills a feat lets you choose (Skilled, Skill Expert), picked on the Character tab
- [x] The choices inside a feat, asked for where the feat is taken: Magic Initiate's
      list, ability and spells, the skill of Keen Mind and Observant, Elemental
      Adept's damage type, Crafter's tools, Musician's instruments, the spells of
      Fey-Touched, Shadow-Touched and Ritual Caster, the Boons of Skill and Energy
      Resistance
- [ ] Skilled's tools in place of skills; Weapon Master unlocking a mastery;
      Inscription Adept's higher spells

**Play**

- [x] Conditions changing your own rolls and speed by themselves
- [x] The concentration save rolled when you take damage; a failure ends the spell
- [ ] Conditions that end by themselves
- [ ] Initiative order and turn tracking
- [ ] A view for the DM of the whole party

**Addon**

- [ ] Syncing tested between two players
- [ ] Languages other than English
- [ ] The creation wizard and level dialog drawn in the sheet's theme (they have a
      themed background only)

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
