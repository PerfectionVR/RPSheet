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
- **Themes:** seven presets plus custom colours, font, size and scale.
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

A new character starts with every stat at 8. The General tab of the settings has a
"Load example character" button that fills in a finished sheet to learn from.

## Rules implemented

- **Stats:** 27-point buy from 8 to 15 (14 and 15 cost 2 points per step), then 3 bonus
  points (at most +2 on one stat).
- **HP:** 6 / 8 / 10 for small / medium / large races, plus 2 x CON modifier.
- **AC:** 5 / 6 / 7 / 8 for cloth / leather / mail / plate, plus DEX modifier, plus shield
  (+1 small, +2 large), plus passive effects. Mail and plate show a warning below 13 and
  14 Strength.
- **Class resource:** main stat modifier x CON modifier x 2.
- **Attack:** d20 + stat modifier, then damage: one-handed 1d4, ranged 1d6, two-handed 1d8,
  or custom dice, plus the same modifier. Healing: 1d3 + modifier, no attack roll.
- **Skills:** the standard 18 skills, each using its stat modifier plus passive effects.

The fixed numbers live in `Rules.lua`. The addon does not enforce limits on how many
abilities or passives a character has; that is left to players and their DM.

## Syncing with other players

Players who both run RP Sheet see each other's stats in the Total RP 3 tooltip.

- Hovering or targeting a player asks them for their stats with a hidden addon whisper.
- Your own changes are pushed to your party or raid.
- Sent: HP, AC, resource, counter, the six stats and the equipped weapon.
- Cross-faction only works inside a group. Received stats are kept for the session only.
- Sharing can be switched off in the settings.

## Files

| File | Purpose |
|---|---|
| `Rules.lua` | Ruleset numbers, skill list, the example character |
| `RPSheet.lua` | Core: saved data, derived values, rolling, the sheet window contents |
| `Options.lua` | Settings and the character editor |
| `Themes.lua` | Theme presets (add your own here) |
| `Window.lua`, `Bar.lua` | The themeable window and bar widgets |
| `Sync.lua` | Sharing stats between RP Sheet users |
| `TRP3Tooltip.lua` | The Stats section in Total RP 3 tooltips |

## Known limits

- Once-per-combat abilities, timed buffs and Heroic Interception are not automated.
- The TRP3 tooltip section relies on Total RP 3 internals and may need an update when
  TRP3 changes its tooltip code. If that happens the section disappears; nothing else breaks.
- No `/say` announcements: the game blocks addons from sending those outside a direct click.

## Bundled libraries

Release zips include unmodified copies of these third-party libraries in the `Libs` folder,
downloaded from their own sources at build time. They are not covered by this project's
licence; each keeps its own:

| Library | Licence |
|---|---|
| [Ace3](https://www.wowace.com/projects/ace3): AceAddon, AceComm, AceConfig, AceConsole, AceDB, AceEvent, AceGUI, AceSerializer | Ace3 Style BSD, see `Libs/Ace3-LICENSE.txt` |
| [LibDBIcon-1.0](https://www.wowace.com/projects/libdbicon-1-0) | Ace3 Style BSD, see `Libs/Ace3-LICENSE.txt` |
| [CallbackHandler-1.0](https://www.wowace.com/projects/callbackhandler) | BSD |
| [LibStub](https://www.wowace.com/projects/libstub) | Public domain |
| ChatThrottleLib (inside AceComm-3.0) | Public domain |
| [LibDataBroker-1.1](https://github.com/tekkub/libdatabroker-1-1) | No licence stated by its author; included unmodified, as is common practice for addons |

## Licence

The addon's own code is released under the MIT licence; see [LICENSE](LICENSE). The bundled
libraries keep their own licences.

World of Warcraft is a trademark of Blizzard Entertainment. This addon is a fan project and
is not affiliated with or endorsed by Blizzard Entertainment or the Total RP 3 team.
