# Tests

The game can't be started from a script, so these tests run the addon's Lua code
outside it, in a fake game environment. They are not part of the addon: release zips
leave this folder out.

## What you need

- **Python 3** and **bash** (Git Bash on Windows).
- **A Lua 5.1-compatible interpreter as a DLL**: LuaJIT's `lua51.dll`, or the reference
  Lua 5.1 built as a shared library. The game uses Lua 5.1; LuaJIT is close enough,
  and `lua51.py` reports the few things LuaJIT accepts that the game would not.
- **A copy of the Ace3 libraries**, for example the `Libs` folder of an installed
  release of this addon. They are read, never changed.

Say where both are in `tests/local.cfg` (this file is not in the repository):

    LUA_DLL="C:/path/to/lua51.dll"
    ACE_LIBS="C:/path/to/Interface/AddOns/RPSheet/Libs"

`ACE_LIBS` may list several folders with `;` between them.

## Running

    bash tests/run.sh load.lua            # every file of the load list loads
    bash tests/run.sh smoke.lua quick     # every class built, clicked and cast
    bash tests/run-all.sh                 # every regression script (several minutes)
    bash tests/run-all.sh items           # only the scripts with "items" in the name
    python tests/lua51.py "Sheet/*.lua"   # syntax the game's Lua would reject

A script prints one line starting with `PROBLEM` for each thing that is wrong and
ends with a summary line; `run-all.sh` fails when any script reports a problem.

## What is here

| Files | What they are |
|---|---|
| `env.lua` | The fake game: the globals the addon reads, stand-in frames, the real LibStub, CallbackHandler and AceConfigRegistry (so options tables are really validated), and a strict `string.format` |
| `sim.lua` | The addon switched on with a fresh profile, with fake chat and `/roll` |
| `smoke.lua`, `snap.lua`, `strict.lua`, `load.lua` | Loading, and the smoke test over every class |
| `t-test-play-*.lua` | Damage, healing, death saves, conditions, casting, components, beast forms, companion, rests, scrolls |
| `t-test-levelling-*.lua` | Every level-up for every class, multiclassing, levelling down, exchange limits, refused choices, Customize, export and import, old saved characters, the wizard |
| `t-test-items-*.lua` | Coins, inventory, equipping, every catalogue item and magic make, the item browser's sources, its Makes tab, selling and search (`-search`), professions and crafting, recipes for every magic item (`-recipes`), stacking and the upkeep of carried items (`-stacks`), mounts and what they carry and pull (`-mountload`), starting gear, the armoury |
| `t-test-windows-*.lua` | The real AceGUI and AceConfigDialog on a fake frame API (`-ui*.lua`), then the sheet, its tabs and rows, the item browser, popups, every settings page, the wizard and level dialog by clicking, and the dialog skin's restore |
| `t-conform-spells.lua`, `data/site-*.txt`, `data/spells-allowed.lua` | Every spell fact against the rules site's, read from the files in `data/` (their first lines say how they were made); the differences that are meant are listed with their reasons |
| `t-conform-classes.lua`, `t-conform-origin.lua`, `t-conform-items.lua`, `t-conform-beasts.lua`, `t-conform-*-lib.lua`, `data/` | Every class and subclass at every level, species, backgrounds, feats, weapons, armor, items, mounts and beasts against facts reduced from the rules site |
| `t-sync-clients.lua` | Several players in one run: each gets its own globals, saved variables, name and realm, with the real AceAddon, AceEvent, AceDB, AceConsole, AceComm, ChatThrottleLib, LibSerialize and LibDeflate, joined by a fake addon channel and chat that hold to the game's limits, and a stand-in for Total RP 3 |
| `t-sync-*.lua` | Built on that: sheets shared between two and three players and what their tooltips say (`share`, `tooltip`), broken and hostile messages (`hostile`), how much is sent (`traffic`), which sheet belongs to which character or Total RP 3 profile over logins and reloads (`profiles`), announcements and chat links (`chat`), `/sheet` (`slash`) |
| `t-test-windows-*.lua` | The real AceGUI and AceConfigDialog on a fake frame API (`-ui*.lua`), then the sheet, its tabs and rows, the item browser, popups, every settings page, the wizard and level dialog by clicking, and the dialog skin's restore; `-tooltips` reads every tooltip of the sheet and the spell windows, and given a file name writes them all to it, to compare two versions of the addon |
| `t-perf.lua` | Timing, not a test: how long the sheet window, the upkeep after a change, the settings window and a level dialog take for a few heavy characters, and the addon's slowest functions. `run.sh t-perf.lua 30` for steadier numbers; compare two versions on the same machine |
| `*-lib.lua`, `*-base.lua`, `*-walk.lua`, `*-dialog.lua`, `*-codec.lua` | Helpers shared by the scripts of one group |
| `dupkeys.py`, `dupfuncs.py`, `freenames.py`, `toccheck.py` | Static checks: a key twice in a table, a function defined twice, undeclared names, the load list against the files |

## What these can't tell you

Nothing is drawn. Text widths are estimated, so wrapping and what a window looks like
are not checked; neither is anything that needs the real game: its menus and popups,
other addons, combat lockdown. The players of the `t-sync-*.lua` scripts talk over a
model of the game's addon channel and of Total RP 3 (written from its 3.5.5 source):
what the real ones do differently only two people in the game can find.

## Writing a test

Start from a script of the same group. Set up a character on a fresh sheet, drive the
functions the interface would call, compare the outcome with what the rules say, and
print `PROBLEM: ...` for a difference. Keep a script to seconds. A global that was
never assigned reads as a stand-in in `env.lua`, not as nil: start test flags at
`false`, and read optional arguments with `rawget(_G, "ARG4")`.
