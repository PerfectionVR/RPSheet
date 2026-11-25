# How RP Sheet is put together

For someone about to change the code. It describes the addon as it is, names the real
files and functions, and leaves out what you can read in a file's own header comment.
Every file starts with a comment that says what it is for; read that first.

RP Sheet is an Ace3 addon without a build step: about 390 small Lua files, loaded by the
game in the order `RPSheet.toc` lists them.

## 1. Load order

The game runs each file once, top to bottom of `RPSheet.toc`. A file can only use, **at
load time**, what the files above it have set up. Inside a function that runs later (a
click, an event) everything exists, so most cross-references are free; the order matters
for what a file does while it loads: creating a shared table, adding to one, registering
a widget, wrapping a function.

```
Libs                 LibStub, Ace3, LibSerialize, LibDeflate, LibSharedMedia,
                     LibDataBroker, LibDBIcon
Core\Addon.lua       ns.addon
Core\Util.lua        ns.Util
Core\Game.lua        ns.Game: everything that differs between retail and WoW Forever
Core\Codec.lua       ns.Codec
Data\*.lua           ns.Rules, ns.FeatureKit, ns.Glossary, ns.ExampleCharacter
UI\Themes.lua        ns.Themes          (before Defaults: the default theme is a copy)
Core\Defaults.lua    ns.defaults, ns.NewSheet
Sheet\*.lua          the saved character and its numbers; ns.Levels
Actions\*.lua        what the character does; ns.RollText
UI\*.lua             widgets, ns.DialogSkin, ns.UI, the sheet, the browsers
Integrations\*.lua   Total RP 3 tooltip, ns.Sync (sharing stats), chat links
Options\Common.lua   ns.Opt
Wizard\*.lua         ns.Wizard, the wizard's pages and dialog
Options\*.lua        tabs, Customize pages, ns.LevelDialog, then Root.lua: ns.options
Core\Slash.lua       what each word after /sheet does (RPSheet:SlashCommand)
Core\Startup.lua     OnInitialize, OnEnable; registers /sheet and /rpsheet
                     (last: everything exists)
```

Where the order inside a group matters:

| Rule | Why |
|---|---|
| `Data\Rules.lua` first in Data | It creates `ns.Rules`; every other data file adds to it. |
| `Data\Effects.lua` before the lists that use templates | It creates `R.TEMPLATES`; `Data\EffectModes.lua`, `Data\Items.lua`, `Data\Mounts.lua` add templates and effect targets to it. |
| `Data\FeatureKit.lua` before `Features.lua`, `SubclassFeatures.lua`, `Subclass*.lua`, `ClassOverrides.lua`, `FactionPerks*.lua` | They build their entries with the kit at load time. |
| `Data\Picks.lua` before `BeastPicks`, `SpellPicks`, `PreparedPicks`, `SpellChoices`, `ToolPicks` | It creates `R.PICK_LISTS` and `R.PICK_LIST_ORDER`; the others append their lists. |
| `Data\Spells.lua` before the other spell files | It creates `R.SPELLS` and `R.DefineSpell`; the later spell files add entries or set fields on the ones that exist. `R.SPELL_LISTS` (who can pick what) starts there too. |
| `Data\Items.lua` before `Gear`, `GearArms`, `MagicItems*` | It defines `R.AddGear` and `R.AddMagicItem`. |
| `Sheet\Levels.lua` before `Sheet\LevelUp.lua` and the Options files | It creates `ns.Levels`, which they read into a local at load time. |
| A wrapped function's file before the file that wraps it | See section 9. `Sheet\PassCache.lua` is the last Sheet file for that reason; `Actions\RestUndo.lua` and `Actions\BeastUses.lua` come after `Actions\Rest.lua`. |
| `UI\WindowMinimize.lua` before `UI\Window.lua` | The window's constructor calls `ns.AttachMinimize`. |
| `UI\DialogSkin.lua` before the other `DialogSkin*.lua` | It creates `ns.DialogSkin`; each other file adds a style for one kind of part. |
| `UI\Rows.lua` before every `UI\Sheet*.lua`, section and browser file | It creates `ns.UI`. |
| `UI\Sheet*.lua` sections before `UI\SheetContent.lua` | `SheetContent.lua` puts the section functions in its `TOP` and `TABS` tables at load time. |
| `UI\ItemPages.lua` before `UI\ItemBrowser.lua`; `UI\ScribeTab.lua` before `UI\CraftBrowser.lua` | Read into locals at load time. |
| `Integrations\SyncPayload.lua` first of the Sync files, `Sync.lua` last | SyncPayload creates `ns.Sync` (`S`); SyncSend, SyncReceive and SyncTerms add to it; Sync.lua switches it on. |
| `Options\Common.lua` before the Wizard and every Options file | It creates `ns.Opt`. The wizard's pages use its dropdown lists. |
| `Wizard\Draft.lua` before the other wizard files that use `W` | It creates `ns.Wizard`. (`Wizard\Grants.lua` comes first and doesn't need it.) |
| `Options\Character.lua` before `Options\Multiclass.lua` | Multiclass adds to and changes `Opt.tabs.character.args`. |
| `Options\Defense.lua` before `DefensePicks.lua` and `WardSwitches.lua` | They add to `Opt.custom.defense.args`. |
| `Options\LevelDialogState.lua` first of the level dialog files, `LevelDialog.lua` last | State creates `ns.LevelDialog` and its `args`; the parts fill `args`; `LevelDialog.lua` registers the finished table. |
| `Options\SpellPage.lua` and `Options\SpellListTop.lua` before `Options\Spells.lua` | Spells.lua puts `Opt.SpellPage` and `Opt.SpellListTop` in its `Opt.lists.spells` entry at load time. |
| `Options\Root.lua` after every tab and page | It copies `Opt.tabs`, `Opt.custom` and `Opt.lists` into `ns.options`. |
| `Core\Slash.lua` just before `Core\Startup.lua` | Its words call into everything; Startup registers `RPSheet:SlashCommand` for `/sheet`. |

`tests/toccheck.py` and the commit script check that every file is listed and every
listed file exists; nothing checks the order itself except loading the addon
(`tests/load.lua`).

## 2. The shared tables

Every file starts with `local ADDON, ns = ...`. `ns` is the addon's private table; no
globals are created except the saved variable `RPSheetDB`.

| Table | Made in | What it holds |
|---|---|---|
| `ns.addon` (`RPSheet`) | `Core/Addon.lua` | The AceAddon object (AceConsole, AceEvent, AceComm mixed in). Everything about the active character is a method on it: `RPSheet:AC()`, `RPSheet:CastSpell()`, `RPSheet:Populate()`. Runtime state hangs on it too: `db`, `sheetKey`, `window`, `body`, `rollMode`, `castLevel`, `busy`. |
| `ns.Rules` (`R`) | `Data/Rules.lua` | Rules data. Nothing in it belongs to one character. Tables in capitals (`R.CLASSES`, `R.SPELLS`, `R.ITEMS`, `R.TEMPLATES`), a few functions that read them (`R.SpecGuide`, `R.WardOf`, `R.Pet`). |
| `ns.FeatureKit` (`Kit`) | `Data/FeatureKit.lua` | Shorthand for writing features as data: `Kit.Passive`, `Kit.Ability`, `Kit.Limited`, `Kit.Choice`, the step builders (`Kit.Spend`, `Kit.Dice`, `Kit.Roll`, `Kit.Bonus`) and `Kit.AtLevel`. |
| `ns.Levels` | `Sheet/Levels.lua` | The choice kept for each level (`sheet.levels[slot]`): `Levels.Kind`, `Levels.Record`, `Levels.Problem`, `Levels.Pending`, `Levels.Recompute`. |
| `ns.UI` | `UI/Rows.lua` | Row helpers (`UI.AddLabel`, `UI.AddHeading`, `UI.AddBar`, `UI.SetOut`), the theme's colour codes, and one function per section of the sheet (`UI.HeaderSection`, `UI.SpellSection`, ...). |
| `ns.DialogSkin` (`Skin`) | `UI/DialogSkin.lua` | The skin for windows built by the options library; see section 11. |
| `ns.Opt` | `Options/Common.lua` | `Opt.tabs`, `Opt.custom`, `Opt.lists`, `Opt.rebuilders` (collected by `Options/Root.lua`), dropdown lists, and helpers such as `Opt.With`, `Opt.Bounded`, `Opt.Changed`, `Opt.Regrant`. |
| `ns.Wizard` (`W`) | `Wizard/Draft.lua` | `W.draft` (the character being made), `W.STEPS`, `W.StepProblem`, `W.Finish`, `W.pages`. |
| `ns.LevelDialog` (`L`) | `Options/LevelDialogState.lua` | `L.draft` (the level being decided), `L.args`, `L.Like`, `L.Problem`, `L.Finish`. |
| `ns.Sync` (`S`) | `Integrations/SyncPayload.lua` | Sharing stats with other players (section 12): `S.PREFIX`, `S.Sharing`, `S.StatMessage`, `S.Sanitize`, `S.handlers` (one per message kind), `S.AskGroup`, `S.QueryUnit`. |
| `ns.Util`, `ns.Codec` | `Core/` | Small helpers; packing data into text (`"print"` for export strings, `"addon"` for the hidden channel). |
| `ns.Glossary`, `ns.Themes`, `ns.defaults`, `ns.options`, `ns.RollText` | `Data/Glossary.lua`, `UI/Themes.lua`, `Core/Defaults.lua`, `Options/Root.lua`, `Actions/Dice.lua` | Hover explanations; theme presets; the saved-data shape; the settings tree; the wording of roll results. |

Plain functions on `ns` take a sheet and know nothing of the window: `ns.ClassLevel(sheet,
key)`, `ns.ApplyClassFeatures(sheet)`, `ns.PickLimit(...)`. Methods on `RPSheet` work on
the active character. Keep to that split: the upkeep and the level dialog call the `ns`
functions on stand-ins and drafts that are not the active sheet.

## 3. Saved data

One saved variable, `RPSheetDB`, through AceDB (`Core/Defaults.lua` has the whole shape
with a comment per field).

```
RPSheetDB
  profile   settings shared by all characters: channel, useTRP3, tooltip, share, locked,
            minimized, minimap, themePreset, theme, and the size and place of each
            window: window (the sheet, 340 x 560 at first; 340 is as narrow as it
            goes), itemWindow (560 x 520), spellbookWindow and preparedWindow (340 x 420).
            The place is added when a window is first moved.
  char      per WoW character: name, shown, sheetTab
  global
    weaponStore            the armoury, for every character on the account
    sheets[<key>]          one per Total RP 3 profile ("trp3:<id>"), or per WoW
                           character without it ("char:<Name-Realm>")
      created, weapon, hp, tempHP, inspiration, deathPass, deathFail, conditions,
      exhaustion, res, pool, slots, pactSlots, hitDiceMore, freeUsed, spellUsed, ...
                           <- play state: what changes during a session
      sheet                <- the character: what is exported, imported and levelled
        class, subclass, spec, level, classes, species, background, base, bonus, asi,
        skills, saves, armor, shield, weapons, abilities, passives, spells, resources,
        items, coins, mounts, levels, picks, featChoices, ...
```

- **`RPSheet:State()`** is `db.global.sheets[self.sheetKey]`; **`RPSheet:Sheet()`** is
  its `.sheet` (`Sheet/Storage.lua`). `RPSheet:UpdateSheetKey()` picks the key at login
  and when Total RP 3 switches profile, moves an old per-character sheet to the profile,
  and runs the upkeep.
- **Play state** is not exported and is reset by `RPSheet:ReplaceSheet(sheet)`, which is
  how the wizard, the import and the example character put a new character in place.
- **Lists** (`weapons`, `abilities`, `passives`, `spells`, `resources`, `items`,
  `mounts`) hold entries shaped by `R.TEMPLATES` (`Data/Effects.lua`, `Data/Items.lua`,
  `Data/Mounts.lua`). An entry the addon put there carries `auto = "<kind>:<name>"`
  (`"class:passive:Rage"`, `"subclass:..."`, `"pick:<list>:<name>"`, `"level:<n>"`,
  `"prepared:<name>"`, `"ward:..."`, `"defense:..."`); an entry the player made has an
  empty `auto`. Deleting an `auto` entry in the editor records its key in
  `sheet.dismissed` so it stays gone (`ns.DismissAuto`).
- **`ns.NormalizeState(state)`** (`Sheet/Migration.lua`) runs on every load, switch and
  replace: converts a version 1 sheet, fills in every default field, turns each list
  into a clean array with every template field, and drops choices that name something
  the rules data no longer has. A new field on the sheet therefore needs a default in
  `Core/Defaults.lua`; a new field on a list entry goes in the template.
- **`Sheet/Transfer.lua`** exports with `RPSheet:ExportSheet()` (prefix `!RPS1!`, packed
  by `ns.Codec`) and imports with `RPSheet:DecodeSheet(text)`. Import trusts nothing: a
  fresh sheet is built field by field, keeping known fields of the right type, text
  stripped of escapes, numbers clamped (`LIMITS`). A new sheet field that must survive
  an export needs handling there.

## 4. The upkeep pass

Much of what is on a sheet is derived from choices: features from class and level,
abilities from picks, spells from a subclass. That is not worked out on the fly; it is
written onto the sheet's lists by an upkeep pass, and refreshed whenever the choices
may have changed. The pass is idempotent: running it twice changes nothing.

```
ns.ApplyGrants(sheet)                         Wizard/Grants.lua
  allegiance's language, class (saves, skills), species (traits), background
  ns.ApplyClassFeatures(sheet)                Sheet/ClassFeatures.lua
    remove class: and subclass: entries the character no longer has
    reset sheet.featureScores
    add or refresh every feature of every class view (Apply)
    ns.ApplyFightingStyles                    Sheet/StyleEffects.lua
    ns.ApplyManeuvers                         Sheet/Maneuvers.lua
    ns.ApplyPicks                             Sheet/Picks.lua
    ns.ApplyBeastForms                        Sheet/BeastForms.lua
    ns.ApplyToolPicks                         Sheet/ToolPicks.lua
    ns.ApplyFeatureSkills                     Sheet/Maneuvers.lua
    ns.ApplyFeatSkills                        Sheet/Expertise.lua
    ns.ApplyFeatChoices                       Sheet/FeatGrants.lua   (before expertise)
    ns.ApplyFeatTools                         Sheet/FeatTools.lua
    ns.ApplyExpertise                         Sheet/Expertise.lua
    ns.ApplySpellPicks                        Sheet/SpellPicks.lua
    ns.ApplyPreparedPicks                     Sheet/PreparedPicks.lua (before the next)
    ns.ApplyPreparedSpells                    Sheet/PreparedSpells.lua
      ns.RefreshListedSpells                  Sheet/SpellRefresh.lua  (saved copies follow the spell data)
    ns.ApplySpellbook                         Sheet/Spellbook.lua
    ns.ApplySpellChoices                      Sheet/SpellChoices.lua  (after the book)
    ns.ApplyFeatSpells                        Sheet/FeatSpells.lua    (last of spells)
    ns.ApplyWards                             Sheet/Wards.lua
      ns.ApplyDefenseSwitches                 Sheet/DefensePicks.lua
    ns.ApplyRenownPerks                       Sheet/RenownPerks.lua
  ns.ApplyLineageSpells(sheet)                Sheet/LineageSpells.lua
  ns.ApplyTraits(sheet)                       Sheet/Traits.lua
  ns.ApplyFeatChoices(sheet)                  once more, for a feat a trait added
  ns.ApplyFeatSpells(sheet)
```

The order inside `ns.ApplyClassFeatures` is deliberate and commented line by line there:
a later step reads what an earlier one wrote.

Who runs it:

| Caller | When |
|---|---|
| `RPSheet:UpdateSheetKey` (`Sheet/Storage.lua`) | Login and profile switch, so a sheet follows a new version of the addon. |
| `RPSheet:ReplaceSheet` | Wizard, import, example. |
| `Opt.Regrant(change)` (`Options/Common.lua`) | A Customize page changed class, subclass, species, background, lineage or allegiance. Given the change as a function, it makes it and raises the current hit points by what the maximum gained (`RPSheet:KeepHPGain`, as taking a level does). |
| `RPSheet:SetLevel` (`Sheet/LevelUp.lua`) and the level dialog's confirm (`Options/LevelDialogApply.lua`), both through `ns.ApplyGrants` | A level was taken, undone, or its choice changed. |
| `ns.OpenLevelDialog` | Before the dialog reads what is picked. |

After the pass, call `ns.NormalizeState(RPSheet:State())` (new entries get their full
shape), then `RPSheet:SheetChanged()` (`ClampState` + `Populate`), and
`ns.RebuildOptions()` if list pages under Customize may have gained or lost entries.
`Opt.Regrant()` does all of that.

## 5. How a number is worked out, and explained

Numbers are never stored; they are worked out from the sheet each time
(`Sheet/Derived.lua`, `Sheet/Combat.lua`, `Sheet/Trackers.lua`).

```
RPSheet:SkillMod(skill)
  = RPSheet:Mod(stat)                       ability modifier (Score -> ScoreMod)
  + rank x RPSheet:ProficiencyBonus()
  + RPSheet:Bonus("SKILL:<name>") + Bonus("SKILLS") + Bonus("CHECKS")
  (or the beast form's own bonus, when higher)

RPSheet:Bonus(target)                       Sheet/DerivedEffects.lua
  = exhaustion, for d20 targets and SPEED
  + every effect aimed at `target` of every passive that is enabled,
    named, and not stopped by armor (RPSheet:PassiveBlocked)
  + RPSheet:ItemBonus(target)               items equipped, and attuned where needed
                                            (RPSheet:ItemActive, Sheet/Inventory.lua)
```

While the sheet window's rows are being made (`RPSheet:Populate`), `Sheet/PassCache.lua`
keeps the answers of `RPSheet:Bonus`, `:EffectFloor` and `:Form`, which each walk every
passive and item: one rebuild asks for the same numbers again and again. The pass is
closed before anything else runs, so an answer never outlives a change; outside a pass
the three work as before. (`ns.checkPass`, set by the tests, checks every kept answer.)

An **effect** is `{ target, flat, stat, times, mode }`. Its value is
`flat + times x source` (`RPSheet:Amount`), where the source is an ability modifier,
`LEVEL` or `PROF`. Targets are the keys of `R.EFFECT_TARGETS` (`AC`, `HP`, `ATTACK`,
`SAVE:DEX`, `SKILL:Stealth`, ...).

`mode` (`Data/EffectModes.lua`, read through `ns.EffectMode(effect)`):

| Mode | Meaning | Where it is counted |
|---|---|---|
| `""` | Adds. | `RPSheet:Bonus` |
| `MIN` | Sets the number to at least `flat`. Always the mode of a `SCORE:<stat>` target. | `RPSheet:EffectFloor` (`Sheet/SetEffects.lua`), used by `RPSheet:Score` and `RPSheet:BaseSpeed` |
| `TIMES` | Multiplies the walking speed; the largest multiplier counts. | `RPSheet:EffectMultiplier`, used by `RPSheet:Speed` |
| `WALK` | A swim, climb or fly speed equal to the walking speed. | `Sheet/MoveSpeeds.lua` |

Besides effects, a passive entry can carry `advantage` (roll labels), `flags`,
`limit`, `strike`, `resist` / `immune` / `vulnerable` / `conditionImmune`; these are
read by `RPSheet:HasAdvantage`, `RPSheet:FeatureFlag`, `Sheet/Limits.lua`,
`RPSheet:StrikeDice` and `RPSheet:Defenses` (`Sheet/Defenses.lua`).

**Explaining.** `Sheet/Explain.lua` has one `Explain...` method per number
(`ExplainAC`, `ExplainSave`, `ExplainWeapon`, ...). Each mirrors the calculation next to
it by hand, as a list of labelled parts: **when you change a calculation, change its
explanation too**. `UI.AddLabel`'s `explain` argument is that method; it gives the row's
button a `?` part in front. A row that rolls a d20 is made with `UI.AddRollLabel` (checks, saves,
skills, tools, initiative, spell attack): there a right-click explains as well, and its
tooltip says so. `RPSheet:ExplainTerm(term)` captures the same text for another player
who clicked a term in chat.

## 6. How a roll travels

```
click on a row                              UI/Rows.lua: ClickLabel -> onClick(button)
  ns.RollMode()                             Actions/Dice.lua: Shift -> "ADV", Ctrl -> "DIS",
                                            else RPSheet.rollMode (the "Next roll" row)
  RPSheet:RollCheck(label, mod, mode)       or :Attack, :CastSpell, :UseAbility, ...
    RPSheet:AutoFail(label)                 a save that fails without a roll
    RPSheet:AskRoll(label, mode, also, go)  Actions/RollQuestions.lua: may open a menu
                                            (what a save is against, whom a Grappled
                                            character attacks, ...) and calls go(answers);
                                            asked before anything is spent
    RPSheet:ResolveMode(label, mode, also,  Sheet/RollModes.lua: adds advantage and
                        nil, answers)       disadvantage from features, conditions, armor
                                            and the answers; both together cancel out
    RPSheet:RollTest(mode, callback)        Actions/NextRollBonus.lua: RollD20, then the
                                            die or number of the "Next roll" bonus rows
    RPSheet:RollD20(mode, callback)         two dice for ADV / DIS; uses up "Next roll"
      RPSheet:Roll(sides, callback)         "Self only": math.random, callback at once
        RandomRoll(1, sides)                otherwise the game's /roll, and `pending` is set
          ... the game prints "<name> rolls <n> (1-<sides>)" ...
        RPSheet:CHAT_MSG_SYSTEM             ns.Game.ParseRoll reads the line, ns.Game.IsPlayer
                                            checks it is this player's (and these sides),
                                            then the callback
    ns.RollText.Check / .Dice               the wording
    RPSheet:Announce(text)                  Actions/Announce.lua: SendChatMessage on the
                                            channel, or printed when it can't be used;
                                            a line the game refuses (Forever: chat only
                                            from a click) is printed with a [Send it]
                                            link (Actions/AnnounceHeld.lua)
... on every client with the addon ...
  chat filter (Integrations/ChatLinks.lua)  turns [terms] into addon links
```

Things to know:

- **One die per `/roll`.** `RPSheet:RollDice(count, sides, callback)` chains `Roll`
  calls; an attack is a d20, then each damage die.
- **Only one roll waits at a time.** `Roll` ignores a second request while one is
  `pending`. Multi-step actions set `self.busy` and check `self.busy or
  self:IsRolling()` before they start. If no result is read within 3 seconds the roll
  is dropped, `busy` is cleared and the player is told.
- **Labels are the interface.** A roll is known by its label on the sheet: `"attack"`,
  `"spell attack"`, `"initiative"`, a skill's or tool's name, `"STR check"`,
  `"DEX save"`. `advantage` lists on passives, `ResolveMode`, `ExplainTerm` and the
  chat links all go by these strings.
- **Terms.** `ns.Mark(term)` wraps a term in square brackets when announcing. The
  filter links it when `ns.TermInfo(term)` knows it, or when the line reads like one
  of ours.
- **Abilities** (`Actions/Abilities.lua`) are lists of steps (`R.ACTIONS`): costs are
  collected first, then the rolls run one after another, then resources and passives
  change and one line is announced. A beast form's action that recharges or comes once
  a day is counted in `Actions/BeastUses.lua` (`state.beastUsed`): a used one is
  refused, and a right-click on a recharging row rolls its d6.
- **The "Next roll" rows** (`Actions/NextRollBonus.lua`, `UI/SheetNextRoll.lua`) hold
  a die added or taken off (Bless, Bane) and a number for the next d20, on `RPSheet`
  (`rollBonusDie`, `rollBonusFlat`, `rollBonusLocked`); `RPSheet:RollTest` rolls them
  after the d20 and uses them up, unless they are kept.

## 7. Class views and multiclassing

The first class lives where it always did: `sheet.class`, `sheet.subclass`,
`sheet.spec`, and `sheet.level` is the **whole character's** level. Classes taken later
are in `sheet.classes[<key>] = { level, subclass, spec, skill, fightingStyle, ... }`
(`Sheet/Classes.lua`). The first class's own level is what the others leave.

Most upkeep code reads `sheet.class`, `sheet.subclass` and `sheet.level`. Rather than
rewrite it, `ns.ClassView(sheet, key)` (`Sheet/ClassViews.lua`) returns a proxy that
answers those three for one class and passes every other field through to the sheet,
reads and writes alike:

```
view.class, view.level, view.subclass, view.spec   of that class
view.characterLevel, view.viewOf                   the whole character
anything else                                      sheet[field]
```

`ns.ClassViews(sheet)` gives one view per class, or `{ sheet }` itself for a character
of one class, so single-class characters run exactly the old code path. Code that must
count each class separately loops over the views (`EachFeature` in
`Sheet/ClassFeatures.lua`, `ns.SheetSlots` in `Sheet/MulticlassSlots.lua`,
`ns.DiceHitPoints` in `Sheet/ClassHitDice.lua`). Helpers: `ns.BaseView(sheet, "Druid")`,
`ns.SubclassLevel(sheet, name)`, `ns.HasSubclass`, `ns.ListView(sheet, pickListKey)`.

Two consequences worth remembering:

- In a feature written as data, "level" is the class's level. For a view, `Apply`
  writes the number out (`ClassLevels`), because the sheet's own `RPSheet:Amount` only
  knows the character's level.
- Choices are kept per level in `sheet.levels[slot]`. A slot is the level itself for
  the first class and `100 x place in R.CLASS_ORDER + level` for a later class
  (`Sheet/ClassSlots.lua`: `ns.LevelSlot`, `ns.SlotClass`, `ns.LevelSlots`).

`ns.SheetWith(sheet, key, level, subclass)` is the character as it would be with that
many levels in a class; the level dialog asks its questions of that.

## 8. Pick lists and the level dialog

A **pick list** is "choose N of these": Metamagic, Eldritch Invocations, Wild Shape
forms, cantrips, spellbook spells, prepared spells, Mystic Arcanum, a feature's tools.
All are entries of `R.PICK_LISTS` (form in `Data/Picks.lua`), in the order of
`R.PICK_LIST_ORDER`. The picks are saved as `sheet.picks[<list>][<name>] = true`.

| Part | Where |
|---|---|
| How many | `ns.PickLimit(key, class, level, subclass)`; for the whole character `ns.SheetPickLimit` |
| Why not this one | `ns.PickBlocked` (level, a pick it builds on, a list's own `blocked`) |
| How many may be exchanged per level | `swaps` on the list, counted in `Sheet/PickSwaps.lua` |
| Putting picks on the sheet | `ns.ApplyPicks` for plain lists (an ability when it has a cost or dice, else a passive, `auto = "pick:<list>:<name>"`); `custom` lists have their own `Apply...` in the upkeep pass |

Maneuvers (`Data/Maneuvers.lua`, `Sheet/Maneuvers.lua`), expertise, feat choices and
feature options work the same way with their own fields.

**The level dialog** is one AceConfig options table registered as `"RPSheetLevel"`,
built from parts:

```
Options/LevelDialogState.lua      L.draft, L.Like(), L.SubclassAfter(), L.StyleSlot()
Options/LevelDialogCounts.lua     limits and counts for every kind of choice
Options/LevelDialogSwaps.lua      which earlier picks may be exchanged
Options/LevelDialogManeuvers.lua  the same for maneuvers
Options/LevelDialogCheck.lua      L.Problem(): the first thing still missing, or nil
Options/LevelDialogGains.lua      what the level gives (text): ns.FeaturesGainedFor lists
                                  only what applies (specialization, options, `when`)
Options/LevelDialogClass.lua      subclass, Fighting Style, a new class's skill
Options/LevelDialogStyles.lua     Fighting Styles left empty, asked again with the choices
Options/LevelDialogFeat.lua       improvement or feat;  Options/FeatChoices.lua: its choices
Options/LevelDialogPoints.lua     the ability score points
Options/LevelDialogSkills.lua     expertise, feature skills
Options/LevelDialogPicks.lua      one group of tick boxes per pick list
Options/LevelDialogApply.lua      the red line, Take level / Save choice, L.Finish()
Options/LevelDialog.lua           registers it; ns.OpenLevelDialog(level, reopen, classKey)
```

`ns.OpenLevelDialog` copies everything choosable from the sheet into `L.draft`. The
controls edit the draft only. `L.Problem()` keeps the confirm button disabled until
every count is exact. Confirm writes the draft to the sheet, calls `RPSheet:SetLevel`
when a level is being taken, runs the upkeep, and `L.Finish` opens the next dialog or
returns to the settings. Nothing reaches the sheet if the dialog is closed.

The creation wizard works the same way with `W.draft`, `W.StepProblem()` and
`W.Finish()` (`Wizard/Draft.lua`), registered as `"RPSheetWizard"`. It doesn't ask for
level choices itself: after `W.Finish` it opens the level dialog for whatever
`ns.Levels.Pending(sheet)` and `ns.OpenClassChoices(sheet)` report.

**Strict and free.** The wizard and the level dialog refuse. The Customize pages
(`Opt.custom`, `Opt.lists`) write straight to the sheet and only say in red what goes
beyond the rules. When you add a rule, enforce it in the dialog's `Problem` function
and warn about it on the Customize page.

## 9. Functions extended by wrapping

A few methods are extended by a later file that keeps the earlier version in a local
and replaces the method. The later file must load after the earlier one, and two
wrappers of one method run in reverse load order.

| Method | Defined in | Wrapped by (in load order) | What the wrapper adds |
|---|---|---|---|
| `RPSheet:SpellBenefits`, `:AskBenefit`, `:TakeBenefit` | `Sheet/Metamorphosis.lua` | `Sheet/WardCasting.lua`, then `Sheet/ComponentTargets.lua` | Protective spells ("who is it for?"), then spells that need components per target ("how many?"). Each handles its own kind of pick and passes the rest down. |
| `RPSheet:PassiveSwitchedOn` | `Sheet/Metamorphosis.lua` | `Sheet/DefensePicks.lua` | Asks for the damage types of a passive that lets you choose them. |
| `RPSheet:EffectText` | `Sheet/DerivedEffects.lua` | `Sheet/SetEffects.lua` | The wording of a `WALK` effect. |
| `RPSheet:Bonus`, `:EffectFloor`, `:Form` | `Sheet/DerivedEffects.lua`, `Sheet/SetEffects.lua`, `Sheet/Forms.lua` | `Sheet/PassCache.lua` | Keeps the answers while the sheet's rows are being made (section 5). |
| `RPSheet:LongRest`, `:ShortRest` | `Actions/Rest.lua` | `Actions/RestUndo.lua`, then `Actions/BeastUses.lua` | RestUndo keeps the play state from before the rest in memory, for `/sheet undo` or a right-click on the rest's row, until the next announcement (`ns.RestUndoExpire`, called by `RPSheet:Announce`) or a change to the character. BeastUses gives back a beast form's used actions. |
| `UI.HeaderSection` | `UI/SheetHeader.lua` | `UI/SheetNextRoll.lua` | The "Next roll" rows below the top part. |
| `RPSheet:SpellDC`, `:SpellAttack` | `Sheet/Derived.lua` | `Actions/Scrolls.lua` | A found scroll's fixed numbers. |
| `RPSheet:TakeDamage` | `Actions/Damage.lua` | `Actions/WardDamage.lua` | Rolls the dice a protective spell takes off the damage first. |
| `RPSheet:LongRest`, `:ShortRest`, `:RollCheck`, `ns.ApplyWards` | `Actions/Rest.lua`, `Actions/Dice.lua`, `Sheet/Wards.lua` | `Actions/ReactionState.lua` (before RestUndo) | Gives the reaction back with a rest or initiative; readies Nose for Trouble; Superior Hunter's Defense's resistance. |
| `RPSheet:DamageExtras` | `Actions/WardDamage.lua` | `Actions/StaggerSway.lua` | Stagger and Sway's reduction and its Delayed Reaction pool. |
| `RPSheet:CastSpell`, `:UseAbility`, `:ApplyDice` | `Actions/Spells.lua`, `Actions/Abilities.lua`, `Actions/Dice.lua` | `Actions/HealReceived.lua`, `Actions/SpellLater.lua`, `Actions/SpellDiceExtras.lua`, `Actions/SpellAfterCast.lua` | Remembers your last healing roll for Heal; a running spell's click rolls its later roll instead of a new casting; a variant spell asks what it hit; what a spell does once it is announced (shape-shifts, Innervate, Contact Other Plane). |
| `RPSheet:SpellText`, `:SpellLaterQuiet` | `Actions/Spells.lua`, `Actions/SpellLater.lua` | `Actions/SpellAfterCast.lua` | Rows and dice of spells whose rolls come after the casting. |
| `RPSheet:EndWards` | `Sheet/Wards.lua` | `Actions/SpellLater.lua` | A running spell ends with the wards that end with it. |
| `RPSheet:ResolveMode`, `:RollTest`, `:DisadvantageFrom` | `Sheet/RollModes.lua`, `Actions/NextRollBonus.lua` | `Actions/SpellRollBonus.lua` | Bless, Guidance, Glibness, one-roll advantage and a reduced creature's disadvantage. |
| `RPSheet:AC`, `:ExplainAC` | `Sheet/DerivedDefense.lua`, `Sheet/ExplainDefense.lua` | `Sheet/SpellAC.lua` | Mage Armor's base 13 and Barkskin's floor of 17. |
| `RPSheet:WeaponStat`, `:WeaponDice`, `:WeaponStyle`, `:StrikeDice` | `Sheet/Armoury.lua`, `Sheet/StyleEffects.lua`, `Sheet/Combat.lua` | `Sheet/SpellWeapons.lua` (loads just before PassCache) | Shillelagh, Magic Weapon, Elemental Weapon, True Strike and the other weapon spells. |
| `RPSheet:ApplyDice` | `Actions/Dice.lua` | `Actions/FeatureDice.lua` (which also holds `ns.HasFeature`) | Class features that count healing dice at their highest or refill a pool from a spell's dice. |
| `L.Problem` | `Options/LevelDialogCheck.lua` | `Options/LineageAbility.lua`, `Options/LevelDialogLessons.lua` | Holds the level dialog until the species ability or Lessons of the First Ones' feat is chosen. |
| `RPSheet:SpellWasCast` | `Actions/Spells.lua` (empty: a hook) | `Integrations/FightTimers.lua` | In a combat session a spell's rounds start being counted. |
| `RPSheet:Attack`, `:UnarmedAttack`, `:UseAbility`, `:CastSpell`, `:Announce`, `:QueueBroadcast`, `ns.RollText.Check` | their own files | `Integrations/FightGate.lua` (loads last of all of them) | Combat sessions: the turn's limits, the line sent to the session's owner, hit points followed. `Integrations/FightLog.lua` wraps `:Announce` once more (the owner's lines into the fight's log) and `:EnableFight` (the chat events a player's log listens to). |

`tests/dupfuncs.py` lists every function defined twice; its output should be exactly
these. Other places where behaviour is added to something that exists:

- `Options/Multiclass.lua` adds "Next level in" to, and replaces `levelUp.name` of,
  the Character tab made in `Options/Character.lua`.
- `UI/DialogBacking.lua` and `UI/DialogSkinWalk.lua` use `hooksecurefunc` on
  `AceConfigDialog.Open` and `.FeedGroup`.
- `ns.DialogSkin.After(widget, name, fn)` wraps a method of one widget instance and
  undoes it on release.
- `Integrations/TRP3Tooltip.lua` replaces `AddSpace` and `Build` on Total RP 3's
  tooltip builder prototype, in memory.
- `Integrations/ChatLinks.lua` adds chat filters, hooks `OnHyperlinkEnter` / `Leave`
  on the chat frames and `SetItemRef`.

Prefer a new function and a call to it over a new wrapper; wrap only when the caller
can't know about the new case.

## 10. Windows

**The sheet and its companions** are AceGUI trees of our own widgets:

| Widget | File | Notes |
|---|---|---|
| `RPSheetWindow` | `UI/Window.lua`, `UI/WindowMinimize.lua` | Title bar with lock, cog, minimize and close; resize grip; `SetTheme`, `SetLocked`, `SetMinimized`; size and place kept in a status table. Fires `OnLockClick`, `OnMinimizeClick`, `OnEditClick`. |
| `RPSheetBar` | `UI/Bar.lua` | A filled bar with text. |
| `RPSheetTab` | `UI/Tab.lua` | One tab of a strip. |
| `RPSheetTermLabel` | `UI/TermLabel.lua` | A label whose glossary terms can be hovered (`ns.Term`). |
| `RPSheetSlider` | `UI/Slider.lua` | The stock slider whose handle moves in steps (`ns.SnapSliders`). |

`RPSheet:Populate()` (`UI/SheetContent.lua`) releases every row and builds them again:
the `TOP` sections, the tab strip, the sections of the open tab. `RPSheet:Refresh()`
only updates text that changes during play (bars, labels kept on `self`). A hidden
window isn't rebuilt (`populateSkipped`); it catches up when shown. From a row's own
click use `RPSheet:PopulateSoon()`: the row is part of what gets released.
`Populate` also refills the open spellbook, prepared-spells and browser windows.

Never name a field on a widget `base`, `frame`, `type`, `content` or `userdata`: AceGUI
owns those. Per-row data goes through `widget:SetUserData`.

The window can't be narrower than 340 (`UI/Window.lua`). Rows a third of the width wide
(checks, saves, bars) must fit on one line there with room to spare;
`tests/t-test-windows-frame.lua` checks it with estimated text widths. The combat
numbers are two to a row for that reason.

**The game's popups** (`StaticPopup_Show` with an edit box) ask for coins, an amount of
damage or healing, and a worth of materials. Their box is found by
`ns.PopupEditBox(dialog)` (`Actions/PopupBox.lua`), which tries every way the game has
offered (a `GetEditBox` method, the `EditBox` and `editBox` keys, the global name) and
then looks among the popup's children.

**Windows built from a source.** The item browser (`UI/ItemBrowser.lua`) is one window
that shows blocks with buttons, and knows nothing about items. What it lists comes from
a *source* table; the header comment of `UI/ItemBrowser.lua` documents every field
(`title`, `first`, `kinds`, `own`, `list`, `find`, `marks`, `lines`, `notes`,
`buttons`, `standing`, `top`, `class`, `empty`, `gone`, `names`, `options`, `words`,
`ownListed`).

| Source | File | Opened by |
|---|---|---|
| `SHEET` (inventory) | `UI/ItemBrowserSheet.lua` | `RPSheet:ToggleItemBrowser()` |
| `STABLE` | `UI/MountBrowser.lua` | `RPSheet:ToggleMountBrowser()` |
| `CRAFT` (+ the Scrolls tab, `UI/ScribeTab.lua`) | `UI/CraftBrowser.lua` | `RPSheet:ShowCrafting(profession)` |
| `CLOSET` (wizard) | `Wizard/ClosetBrowser.lua` | `W.OpenCloset()` |

There is one window: showing another source replaces what it shows.
`RPSheet:ShowItemBrowser(source)` toggles, `RPSheet:OpenItemBrowser(source, tab)` never
closes. Only one page of 24 blocks is built (`UI/ItemPages.lua`); the search
(`UI/ItemBrowserSearch.lua`) runs first, over the whole tab or, with "Search
everything", over every tab of the source, and looks at a block's name, marks and
words. A new browser is a new source table, not a new window. The inventory's Makes
tab (`UI/ItemMakes.lua`) lists every magic make of every plain item it exists of
(`Data/ItemVariants.lua`, `Data/ItemVariantsNamed.lua`).

**The settings, the wizard and the level dialog** are AceConfig options tables shown by
AceConfigDialog under three names: `"RPSheet"`, `"RPSheetWizard"`, `"RPSheetLevel"`. Only
one is open at a time: opening one closes the settings window, on the next frame
(`C_Timer.After(0, ...)`), because the library redraws a window right after one of its
buttons was pressed.

## 11. The dialog skin and its restore rule

AceConfigDialog builds its windows from pooled AceGUI widgets that it hands out and
takes back. The next addon to open a settings window gets the same widget objects. So
the rule is:

> **Nothing the skin changes on a widget may outlive the widget's release.**

`UI/DialogSkin.lua` enforces it:

```
Skin.First(widget, kind, key)   true the first time a thing is touched: note how it was
Skin.Undo(widget, fn)           remember how to put it back
Track(widget)                   wraps the widget's OnRelease so Skin.Restore runs first
Skin.Restore(widget)            runs every undo, newest first, each in a pcall
Skin.Style(widget, theme)       calls Skin.styles[widget.type] in a pcall; a kind that
                                fails once is left stock from then on
Skin.After(widget, name, fn)    re-style after the widget's own method ran (a tick
                                clicked, a list scrolled); undone on release
Skin.Walk(widget, pass, isRoot) style a widget, then its children, then lay it out
```

When it runs (`UI/DialogSkinWalk.lua`): after `AceConfigDialog:Open` for one of our
three names (not when the options are shown inside the game's own panel), after
`FeedGroup` for a group inside one of our windows, and from `ns.SkinOpenDialogs()` on a
theme change. Another addon's window is never walked. `Skin.ApplyTo(root, theme, only)`
styles the library widgets inside a window of our own (the item browser's blocks,
buttons and search box).

What each kind of part looks like is one file each: `DialogSkinFrame`, `Button`,
`Check`, `Slider`, `Dropdown`, `Edit`, `Tabs`, `Tree`, `Text`, `Widgets`, with shared
tools in `DialogSkinTools` and `DialogSkinParts`. `UI/DialogBacking.lua` puts the
nearly solid panel behind our windows and hides it when the frame closes.

When you add a style: change things only through helpers that record an undo, never
set a field on the widget that you don't restore, and run
`bash tests/run-all.sh windows` (`t-test-windows-skin.lua` checks that a released
widget is as it was). Then do section J of [MANUAL-CHECKS.md](MANUAL-CHECKS.md).

## 12. Talking to other players

`ns.Sync` (`S`), over AceComm with the prefix `S.PREFIX` = `RPSheet4` (bump the number
when the data changes shape). Four files and a switch:

| File | What it does |
|---|---|
| `Integrations/SyncPayload.lua` | Creates `ns.Sync`. `S.Sharing()` (the `share` setting), `S.StatMessage()` (our stats, packed and stamped), `S.Sanitize` / `S.Text` / `S.Num` / `S.Stamp` for what comes in. |
| `Integrations/SyncSend.lua` | `RPSheet:SendStats`, `RPSheet:QueueBroadcast` / `:BroadcastToGroup`, `S.AskGroup`, `S.QueryUnit`, `RPSheet:SetSharing`; holds what can't be sent while the game blocks addon messages and sends it once it can again. |
| `Integrations/SyncReceive.lua` | `S.handlers` (one per kind), `RPSheet:OnCommReceived`, the session's `cache` of other players' stats (`RPSheet:GetCachedStats`), `S.Forget`. |
| `Integrations/SyncTerms.lua` | The question about a term clicked in chat, and its answer. |
| `Integrations/Sync.lua` | `RPSheet:EnableSync()` at login: the comm prefix, the mouseover, target and group events, a first broadcast and a question to the group. |

Messages are packed by `ns.Codec.Pack("addon", kind, ...)`:

| Kind | Sent | Meaning |
|---|---|---|
| `Q` | Whisper, on mouseover or target of a player of the same faction, at most once per 30 s per player; to the group after a login or reload inside one (`S.AskGroup`) | "Send me your stats." |
| `D` | Whisper in answer to `Q` (at most once per 5 s per asker); `PARTY` or `RAID` about 2 s after a change (`RPSheet:QueueBroadcast`, called by `Refresh`), and only when what others see changed | `RPSheet:GetStatData()` (`Sheet/Summary.lua`), then a stamp. |
| `C` | To the group, when "Share my stats" is switched off (`RPSheet:SetSharing(false)`) | "Drop what you have of me." Carries a stamp. |
| `E` | Whisper, when a player clicks another's term in chat | "Explain this term." |
| `X` | Whisper in answer to `E` | `RPSheet:ExplainTerm(term)` as plain text. |

**The stamp.** A whisper and a group message can overtake each other, so `D` and `C`
carry a number that only grows (`S.NextStamp()`, from the server's clock, so also over
a reload); the same stats keep the same stamp. The receiver keeps the newest stamp per
player and ignores anything older. It travels after the data, where a version without
stamps never looks, and a message without one counts as new.

Everything received goes through `S.Sanitize` / `S.Text` / `S.Num` and a size limit
(`S.MAX_MESSAGE`): never trust it. With `share` off nothing is sent, asked or taken
in. Received stats live in the local `cache` for the session and are shown by
`Integrations/TRP3Tooltip.lua`.

**`/sheet`** (`Core/Slash.lua`): no word toggles the window; `config`, `new`, `level`,
`tab <name>`, `items`, `lock`, `rest`, `short`, `undo`, `damage <n> [type] [crit]`,
`heal <n>`. Anything else prints the list.

## 13. How to add things

**A class feature.** Add an entry to the class's list in `Data/Features.lua`
(`R.FEATURES[<Player's Handbook class>]`), `Data/Subclass<Class>.lua`
(`R.SUBCLASS_FEATURES[<subclass>]`) or `Data/ClassOverrides.lua`, using the kit:

```lua
Passive(5, "Name", "Short summary in our own words.", { Bonus("AC", 1) })
Ability(3, "Name", "Summary.", { Spend("Rage"), Roll("ATTACK", "STR"), Dice(1, 8, "STR") })
Limited(7, "Name", "Summary.", uses, actions, short)   -- gets its own bar
```

`desc`, `effects` and `actions` may be functions of `(level, sheet)`. The header of
`Kit.Passive` lists what `extra` can carry (`advantage`, `skills`, `saves`, `limit`,
`resist`, `spec`, `when`, ...). Nothing else is needed: `ns.ApplyClassFeatures` puts
it on every sheet that has reached the level, and takes it off below. Use
`Kit.Choice` / `Kit.Option` for a feature with options; the level dialog asks for it.

**A spell.** `R.DefineSpell(name, level, how, dice, desc, extra)` in `Data/Spells.lua`
or `Data/SpellsAzeroth.lua`, or a line in the table of `Data/SpellsCore.lua` (its last column names the classes); a
spell defined by hand is put on `R.SPELL_LISTS` in `Data/Spells.lua`. Then, as needed: casting time and priced component
(`Data/SpellDetails.lua`), damage type (`Data/SpellDamage.lua`), what a higher slot
does (`Data/SlotGrowth.lua`), a written summary (`Data/SpellSummaries<level>.lua`),
components per target or of a special kind (`Data/SpellComponents.lua`,
`Data/SpellComponentKinds.lua`), protection it gives (`Data/SpellWards.lua`).
Ask `R.ClassSpellList(classKey)` / `R.OnClassSpellList(classKey, name)`
(`Data/SpellLists.lua`) for a class's spells, not `R.SPELL_LISTS` itself: a Death
Knight and a Demon Hunter leave out part of their core class's list.

**Correcting a spell.** A spell on a sheet is a copy of its entry, and
`ns.RefreshListedSpells` brings the copies up to date on every upkeep: fully for a copy
the player never changed, and only in the fields the Customize page can't change for one
they did (`spell.edited`, set by that page's controls). Copies saved before that mark
existed are compared once with every value the entry ever had, so **when you change a
fact or the summary of a listed spell, add the old value to `Data/SpellFormer.lua`
(`Was`) or `Data/SpellFormerText.lua` (`Read`)**; `tests/t-test-levelling-savedspells.lua`
checks that each former value is brought up to date.

**An item.** Plain gear: add `Name|price in copper|weight` to the right
`R.AddGear(kind, ...)` call in `Data/Gear.lua` or `Data/GearArms.lua`. A magic item:
`R.AddMagicItem(name, rarity, desc, effects, extra)` in one of the `Data/MagicItems*.lua`
files; `effects` are passive effects that count while it is equipped (and attuned, with
`extra.attune`). The item browser and prices (`Data/MagicItemPrices.lua`) pick it up
from the catalogue. It also needs a recipe (`Data/RecipesMagic.lua`,
`Data/RecipesFinds.lua`) or a line in `R.NOT_MADE` saying why nobody makes it:
`tests/t-test-items-recipes.lua` fails otherwise. One that exists of any plain weapon
or suit of armor of a kind also gets a make in `Data/ItemVariantsNamed.lua`.

A carried entry (`R.TEMPLATES.item`) is `tracked` when it was made since edits are
recorded and `edited` once a Customize setter changed it. The upkeep
(`Sheet/ItemUpkeep.lua`) rewrites a tracked, unedited entry from the catalogue on every
load, so a correction to an item's data reaches the characters that carry it; an
edited one is never touched, and an untracked one (saved before the marks) keeps the
old careful rule. Code that changes a catalogue item's entry on purpose must set
`edited`, or the next load undoes it.

**A Customize page.** A new file in `Options/`, listed in `RPSheet.toc` before
`Options\Root.lua`:

```lua
local _, ns = ...
local Opt = ns.Opt
Opt.custom.myPage = {
    type = "group", order = 9.7, name = "My page",
    args = {
        thing = Opt.With({ type = "toggle", order = 1, name = "Thing" }, Opt.Sheet, "thing"),
    },
}
```

`Opt.With` binds a control to a field and calls `Opt.Changed()` on set. For a list of
entries use `Opt.lists.<sheet field> = { order, title, noun, template, build, help,
extra }`; `Root.lua` gives it Add and Delete. Rows that depend on the sheet are
rebuilt by a function added to `Opt.rebuilders`. A top-level tab goes in `Opt.tabs`.
Customize pages are free: warn in red (`Opt.RED`), don't refuse.

**A section or tab of the sheet.** Write `function UI.MySection(self, body)` in a
`UI/Sheet*.lua` file loaded before `UI/SheetContent.lua`, and add it to `TOP` or to a
tab's entry in `TABS` there. Use `UI.AddHeading` and `UI.AddLabel(parent, relWidth,
text, onClick, tipTitle, tipBody, explain)`.

**A saved field.** Default in `Core/Defaults.lua` (the sheet) or the template (a list
entry); nil-guard it where older sheets are read before `NormalizeState` has run;
handle it in `Sheet/Transfer.lua` if it must survive export and import; reset it in
`RPSheet:ReplaceSheet` if it is play state.

**A test.** `tests/t-test-<group>-<what>.lua`, where the group is `play`, `levelling`,
`items` or `windows`; start with the group's shared file, as its neighbours do
(`dofile(ARG3 .. "/t-test-<group>-lib.lua")`; `-base.lua` for windows), and copy
the shape of a neighbour: build a character on a fresh sheet, call what the interface
would call, compare with what the rules say, print `PROBLEM: ...` for a difference, and
end with `Summary("<script name>")` (`run-all.sh` looks for "0 problems" in the last line).
`bash tests/run.sh <script>` runs one; `bash tests/run-all.sh <filter>` a group. A
global that was never assigned reads as a stand-in, not nil: start flags at `false`.
See [tests/README.md](../tests/README.md).

## 14. House rules for the code

- Small single-purpose files, a header comment that says what the file is for, comments
  that explain why.
- Text the player sees never names the books or copies their wording; summaries are
  short and in our own words. English only.
- Rule numbers come from the rules data, not from memory, and live in `Data/`.
- The wizard and the level dialog enforce the rules' limits; Customize only warns.
- Game terms in in-game text are hoverable where the neighbouring code does that.
- Anything from another player or a pasted string is untrusted.
- Calls into Total RP 3 and into the game's newer APIs are guarded (`pcall`, existence
  checks, `issecretvalue`): a missing API must degrade, not error.

## Added with the last fixes before 0.7.0

- `Data/Lasting.lua` lists the passives a feature switches on for a while (Rage,
  Shadowform, Divine Sense, Holy Nimbus, Sacred Weapon and others): which end when you
  are incapacitated (`Actions/Incapacitated.lua`) and that every one ends with a rest.
- `Sheet/LineageCasting.lua` keeps the spellcasting ability chosen for a species or
  lineage (`sheet.lineageStat`) and an elf's exchanged cantrip; `Sheet/LineageSpells.lua`
  puts the species' cantrips and its level 3 and 5 spells on the spell list
  (`auto = "species:<name>"`). `Options/LineageAbility.lua` asks for the ability in the
  level dialog by wrapping `L.Problem` and the confirm function, so it loads after
  `Options/LevelDialogApply.lua` and before `Options/LevelDialog.lua`.
- `Sheet/FeatRestPicks.lua` holds feat choices marked `rest` (Weapon Master, Boon of
  Energy Resistance) to one change per long rest (`state.restPicks`).
- `Sheet/HerbComponents.lua` lets Inscription Adept pay a feat spell's priced component
  with gathered herbs.
- `Integrations/SyncSwitch.lua` reacts to the share switch and to settings-profile
  changes; `Integrations/ChatTerms.lua` is the term lookup for chat links (tools and
  items included). Sync uses the instance channel in dungeon finder, raid finder and
  battleground groups (`S.GroupChannel`), and forgets other players' stats after half
  an hour unless they are in the group.

## Added in 0.7.1

- **Damage as it is taken.** `Actions/DamageSteps.lua` puts the character's damage
  features in order (flat reductions, then halving or none, then resistance once, then
  vulnerability); `UI/DamageReactions.lua` shows their boxes in the damage menu and
  passes what was ticked as `how`, the last argument of `RPSheet:TakeDamage`.
  `Actions/DamageZero.lua` handles dropping to 0 (Death Ward from
  `Data/SpellWardDeath.lua`, Relentless Rage), `Actions/Falling.lua` the "A fall" row,
  `Actions/ReactionState.lua` `state.reactionUsed`, and `Actions/ScoreFloor.lua`
  Indomitable Might's note. `UI/HealMenu.lua` and `Actions/HealReceived.lua` are the Heal
  menu.
- **Spells after their casting.** `Data/SpellLater*.lua` describe what a spell rolls
  later; `Actions/SpellLater.lua` keeps `state.spellLater` (which run, from which slot)
  and `Actions/SpellLaterRoll.lua` / `SpellLaterMenu.lua` roll them from the row or its
  right-click. `Data/SpellVariants.lua` and `Actions/SpellDiceExtras.lua` ask what a
  spell hit and roll exploding dice and split damage.
- **Spells on yourself.** `Data/SpellWardEffects.lua`, `SpellWardBoons.lua` and
  `SpellWardWeapons.lua` extend the protective-spell passives with Armor Class, speed,
  hit points, roll bonuses and weapon changes; `Sheet/WardStart.lua` applies the hit
  points when the passive starts.
- **Class feature flows.** `Actions/AbilityFlows.lua` dispatches `ns.ABILITY_FLOWS[name]`
  (Paladin, Druid, Sorcerer, Death Knight rune and Divine Intervention flows in their own
  files); `Actions/SpellFeatures.lua` and `Actions/FeatureDice.lua` add class bonuses to
  spell and ability dice; `Actions/Initiative.lua` gives uses back on initiative;
  `Sheet/D20Floor.lua` the Dragon constellation; `Sheet/MemorizeSpell.lua`. A feature
  may carry `tools = {...}` (Data/FeatureKit.lua), counted by `ns.ToolGranted`.
- **Feats and traits.** `Data/FeatUses.lua` / `Sheet/FeatUses.lua` give feats bars and
  rows (`auto = "featuse:<name>"`); `Sheet/DiceFeats.lua` rerolls and raises low dice
  (`reroll` / `lowest` on DICE steps); `Sheet/WeaponFeats.lua`, `Sheet/UnarmedStrike.lua`,
  `Actions/SpellFeats.lua` (Spell Recall, the Metamagic REROLL step),
  `Actions/Inspiration.lua`, `Sheet/FeatRules.lua` (Medium Armor Master's Dexterity cap).
  Invocation spells: `Data/InvocationSpells.lua`, `Sheet/InvocationSpells.lua`
  (`auto = "invocation:<name>"`); Lessons of the First Ones: `Sheet/LessonFeats.lua`.

## Added in 0.9.0: combat sessions

`ns.Fight` (`Integrations/Fight*.lua`, `UI/FightWindow*.lua`). One client owns a
session; its copy is the truth.

- **State.** `F.session = { id, owner, phase = LOBBY | ROLL | RUN, round, turn, order,
  members = { [player key] = { name, mark, init, dex, ac, hp, max } } }`. Player keys
  come from `ns.Game.UnitKey`, so both games work.
- **Messages** (`FightSend.lua`), on the group channel with the prefix `F.PREFIX`.
  Players ask: `J` join, `L` leave, `M` group mark, `R` initiative total, `A` a line
  their sheet made (with an attack roll's numbers and target), `T` end turn, `H` hit
  points and Armor Class, `Q` send the session. The owner sends `S`, the whole
  session, after every change, and `E` at the end. `F.Request` handles the owner's own
  requests on the spot. Everything received goes through `F.CleanSession` /
  `F.CleanMember`.
- **Owner** (`FightOwner.lua`): applies requests, sorts the order (total, Dexterity
  modifier, key), advances the turn, and announces through `RPSheet:Announce(text,
  speaker)`. The session survives the owner's reload in `db.char.fightOwned`.
- **Player** (`FightPlayer.lua`): `F.Applied(before)` compares a new copy with what was
  known and starts what changed (the call for initiative, `F.TurnStarts`).
- **The turn** (`FightTurn.lua`): `F.used`, `F.Why(cost, slot)`, `F.Charge`. Costs are
  ACTION, ATTACK, BONUS, REACTION, LONG and FREE; an ability's is read from the start
  of its description, a spell's is its `time`.
- **The gate** (`FightGate.lua`): the wrapped click functions ask `F.Why` first and
  remember what was let through; the wrapped `Announce` charges it when the line is
  made, and sends the line to the owner instead of to chat. `ns.RollText.Check` is
  wrapped to keep the last d20 test's numbers for that message.
- **Snapshot** (`FightSnapshot.lua`): the play state without `state.sheet`, in
  `db.char.fightSnapshot`, kept at joining.
- **Window** (`UI/FightWindow.lua`, `FightWindowTurn.lua`): filled from `F.session` and
  `F.Actions()` (`FightActions.lua`); `F.Changed()` refills it once a frame.
- **Tests:** `tests/t-sync-fight.lua` (four clients), `tests/t-test-windows-fight.lua`.

## Added in 0.10.0: durations in rounds

`Integrations/FightTimers.lua`, `UI/FightWindowRunning.lua`, `Data/SpellDurations.lua`.
There is still no clock: only a running session counts, in the character's own turns.

- **Data.** `R.SPELL_ROUNDS[<spell name>]` (1, 6, 10, 100 or 600) for spells of an hour
  or less, made from `tests/data/site-spells.txt` and held to it by
  `tests/t-conform-spells.lua`. It is a table by name because a sheet keeps its own
  copies of spells, which the export codec doesn't carry new fields for.
  `R.LASTING[<passive>]` gained `rounds`, `toEnd` and `upkeep`.
- **State.** `state.fightTimers = { { kind = CONC | SPELL | PASSIVE, name, left, total,
  toEnd, fresh, shown } }` and `state.fightTicked = "<session id>:<round>"`, so a reload
  on your own turn doesn't count the turn twice.
- **Starting.** `RPSheet:SpellWasCast(spell, concentrating)`, an empty hook at the end
  of a casting in `Actions/Spells.lua`, is wrapped to start a spell's timer. Features
  are found, not hooked: `F.SyncTimers()` starts one for every switched-on passive of
  `R.LASTING` with `rounds`, and drops timers whose thing ended some other way.
- **Counting.** `F.TickTurnStart()` (from `F.TurnStarts`) takes a round off each and
  ends what reached 0; `F.TurnEnds()` (from `F.Applied`, when the turn that was this
  character's moved on) ends the `toEnd` ones and gives the rage and owed-hit-point
  reminders. Ending goes through `RPSheet:EndConcentration` or `:Announce`, so the
  line reaches the owner like any other.
- **After.** `F.DropTimers()` when the session ends for this client.
- **Tests:** `tests/t-sync-rounds.lua`; the window test ends everything listed.

## Added in 0.11.0: the owner's tools

`Integrations/FightCreatures.lua`, `Integrations/FightOwnerTools.lua`,
`UI/FightWindowOwner.lua`, `UI/FightAsk.lua`. The prefix became `RPSheetF2`.

- **Combatants the owner runs** are members with `npc = true` under the key
  `npc:<n>`; `member.dex` is the initiative bonus. They reuse the players' handlers
  with their key as the sender: `F.owner.R` (initiative), `F.owner.A` (an attack line
  with `attack`, `total`, `die`), `F.owner.L` (removal). Their d20s are `math.random`
  on the owner's client. `Advance` passes over one at 0 hit points. `F.owner.J`
  strips `npc` from what a player sends.
- **Shared by the owner files:** `F.Say`, `F.Before`, `F.Rebroadcast(before)`.
- **Owner to one player** (`to` names the player key; the owner's own character is told
  without a message): `V { stat, dc }` sets `F.owedSave`, and the wrapped `Announce`
  (`FightGate.lua`) adds `save = dc` to the line of a matching save, which `F.owner.A`
  turns into "succeeds/fails against DC n". `D { amount, type }` or `{ amount, heal }`
  calls `RPSheet:TakeDamage` or `:Heal`. Both are only taken from `session.owner`
  while `F.Mine()`.
- **Handing over:** the owner sends the session (`S`) and then `O { id, to }`. Every
  client sets `session.owner = to`; the new owner's client calls `F.Rebroadcast()`,
  which also stores `db.char.fightOwned`.
- **Text input:** `ns.AskFightText(prompt, default, go)`, a StaticPopup with an edit box.
- **Tests:** `tests/t-sync-owner.lua` (three clients, including a forged `D`); the
  window test types into every box.

## Added in 0.14.0: buttons in every window

`UI/FightParts.lua` became `UI/Parts.lua` and loads right after `UI/Rows.lua`.

- **Rule of every window:** what can be clicked is an `RPSheetButton`, an `RPSheetTab`
  or an `RPSheetBar`. `UI.AddLabel` keeps its arguments, and makes an
  `InteractiveLabel` only when it is given nothing to do; with `onClick` or `explain`
  it hands over to `UI.AddRowButton` (`UI/Parts.lua`) and returns the button, which
  has `SetText` and `GetText` like the label had. So a section never chooses: give a
  row something to do and it is a button. The window tests' walker
  (`tests/t-test-windows-walk.lua`, `CheckNoClickableText`) fails on text with a click.
- **`RPSheetButton`** (version 2): the text wraps and the button takes the height it
  needs (`Fit`, on `SetText`, `OnWidthSet`, `SetMark`, `SetStyle`). A fourth look,
  "row": text in the text colour, for rows that colour parts of their own text.
  `SetMark(true)` shows a "?" part on the left, a button inside the button that fires
  `OnMarkClick`. `SetDisabled(true)` takes no click at all (the item browser's
  buttons); the "off" look alone still does, to say why.
- **Explaining:** the "?" part calls `explain`; so does Alt with a click, and the
  whole button when the row has no `onClick`. `UI.AddRollLabel` is unchanged: a
  right-click explains too. `UI.SetText` no longer adds a mark to the text.
- **`UI.AddLabel`'s eighth argument** is a look for the button ("off" for a passive
  that is switched off).
- **Tab strips:** the sheet (`UI/SheetTabs.lua`) and the item browser
  (`UI/ItemBrowserParts.lua`) use `UI.AddTabStrip` like the combat window. With `open`
  nil no tab is the open one (the browser while it searches every tab).
- **`UI.AddItemButton`** makes an `RPSheetButton`; AceGUI's own `Button` is no longer
  made by the addon's windows (the dialogs of AceConfig still have theirs, skinned).

## Added in 0.13.0: the combat window's layout

`UI/Button.lua`, `UI/Parts.lua` (then `UI/FightParts.lua`), `UI/FightWindowRoster.lua`,
`Integrations/FightLog.lua`, `Data/CreatureGroups.lua`; `UI/FightWindowTurn.lua`,
`UI/FightWindowOwner.lua`, `UI/FightWindowCreatures.lua` and `UI/FightWindow.lua`
rewritten.

- **Rule of the window:** what can be clicked is an `RPSheetButton`, an `RPSheetTab`
  or an `RPSheetBar`; an `InteractiveLabel` there never has a click. The window test
  holds every state to it (`CheckClickable`).
- **`RPSheetButton`** (`UI/Button.lua`): a box with an edge, looks "on", "off" (greyed,
  a click may say why) and "picked". `UI.AddButton(parent, relWidth, text, onClick,
  tipTitle, tipBody, look)`, `UI.AddTabStrip(parent, tabs, open, pick)`, `UI.Pip`,
  `UI.HealthColor` are in `UI/Parts.lua`.
- **Order of the window** (`RPSheet:PopulateFight`): headline, an owed save or
  initiative roll, `UI.AddFightRoster` (a label and a health bar per combatant; the
  bar picks `F.target`), `UI.AddFightLog`, `UI.AddFightRunning`, `UI.AddFightStatus`,
  `UI.AddFightTurn` (the button that moves the turn on, the tab strip, the open tab).
- **Tabs:** one per `section` of `F.Actions()`, "Session" for the owner
  (`UI.AddFightOwner`) and "You". `F.tab` is the player's choice; it is dropped when
  the session's phase or turn changes, and then the owner's tab opens on the turn of
  a combatant they run and outside the turns, the first action tab otherwise.
- **The log** (`Integrations/FightLog.lua`): `F.Log(text)`, `F.LogLines()`,
  `F.LogText(line)` (colour by outcome, marks as icons). The owner's client logs in a
  wrap of `RPSheet:Announce` (every line with a speaker while it owns a session); a
  player's client logs the owner's lines from the chat events registered in a wrap of
  `RPSheet:EnableFight`. Kept in memory, emptied when the session's id changes.
- **Creature groups** (`Data/CreatureGroups.lua`): `R.CREATURE_GROUPINGS`,
  `R.CreatureGroups(key)` for `kind`, `people`, `side`, `challenge`. People and side
  are lists by name in that file; a dragonflight is told by its name. The picker
  keeps `F.pickBy`, `F.pickGroup`, `F.pickFilter`.
- **Aim:** `F.CreatureTarget(key)` is `F.target`, or the only other combatant above 0
  hit points.
- **Tests:** the window test opens every tab in every state; `tests/t-sync-solo.lua`
  holds each grouping to all 84 creatures; `tests/t-sync-owner.lua` the log on both
  sides. `tests/runlua.py` falls back to the Python module `lupa` (LuaJIT) when
  `LUA_DLL` is not set, and `tests/env.lua` has `strlenutf8`.

## Added in 0.12.0: creature templates

`Data/CreatureList.lua` (the facts, one creature per line), `Data/Creatures.lua` (the
parser), `Integrations/FightStatBlocks.lua`, `UI/FightWindowCreatures.lua`.

- **Data.** `tests/data/site-creatures.txt` is the site's bestiary of the setting's
  book reduced to names and numbers by a script in the site's page, and checked
  against the page by a checksum per line; `Data/CreatureList.lua` is that file's
  lines. `R.CREATURES[name]`, `R.CREATURE_ORDER`, `R.FindCreature`,
  `R.DamagePartsText`. No descriptions are stored.
- **In a session** a templated combatant is an `npc` member with `template = <name>`,
  which `F.CleanMember` keeps only when the name is a known template, so it survives
  a reload and a handover. `F.AddCreature("<template name>")` makes one.
- **Attacks and forced saves:** `F.CreatureStrike(index, key)` and
  `F.CreatureForce(index, key)`; damage goes out through `F.Hurt(key, list)`: to a
  player as `D { parts }` (taken one type at a time, each when the sheet is idle), to
  an owner's combatant through `F.AdjustDamage` and `F.ChangeCreatureHP`. Damage
  that waits for a player's save sits in `F.pendingSaves[key]` until `F.owner.A`
  calls `F.SaveResolved`.
- **Window:** `F.picking` swaps the window's content for the list
  (`UI.AddCreaturePicker`); `UI.AddCreatureTurn` lists a templated creature's rolls.
- **Tests:** `tests/t-sync-solo.lua` (one client, no group, `math.random` scripted, and
  the list held against the site file).
