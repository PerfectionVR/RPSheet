# Checks to run in the game

The automated tests run the addon's code outside the game and draw nothing (see
[tests/README.md](../tests/README.md)). This list covers what they can't tell: what the
windows look like, the game's own popups and menus, real `/roll` results, other addons,
Total RP 3, and syncing between two players.

Each line is one check: what to do, then what you should see. Tick it when it holds;
write the number down when it doesn't. Section A is the most valuable ten minutes; the
rest is grouped by window and can be done in any order.

## Before you start

- Switch on Lua errors so nothing fails silently: `/console scriptErrors 1`, then `/reload`.
- Have one other addon with an Ace3 settings window installed (for section J), and
  Total RP 3 for section L.
- Section M needs a second player with RP Sheet, in your party; some of its lines also a
  third player, the other faction, another realm, or the released version 0.6.0.
- A spellcaster of level 5 or higher shows the most. The example character
  (settings > General > Load example character) is enough for sections A to C.

## A. The first ten minutes

- [ ] A1. Log in on a Total RP 3 profile (or character) that has no sheet. *After about three seconds the creation wizard opens by itself, with no error.*
- [ ] A2. Look at the wizard before touching it. *Solid background in the theme's colour, the title "Step 1 of 5: Choose a class" on top, themed buttons; "Next" is grey and a red line says "Choose a class first."*
- [ ] A3. Go through the five steps with any class at level 5 and press "Create character". *The wizard closes, chat says the character was created, and the level dialog opens for the first choice still open.*
- [ ] A4. Make every choice the level dialogs ask for. *Each closes on "Take level" / "Save choice"; the next opens by itself; at the end no dialog is left and the sheet shows the character.*
- [ ] A5. Look at the sheet at its default size. *Title bar with name and four buttons, the top part, six tabs on one row, no row lying over another, no text cut off.*
- [ ] A6. Set "Announce to" to Emote and click a skill. *One `/roll` line (1-20) from the game, then an emote line such as "rolls [Stealth]: 14 + 5 = 19" with the total right.*
- [ ] A7. Shift-click a skill, then Ctrl-click one. *Two `/roll` lines each; the announcement names both dice ("[advantage: 14, 6]") and uses the higher, then the lower.*
- [ ] A8. Click the weapon row. *A d20 roll, then one `/roll` per damage die, then one line "attacks with [weapon] - to hit ..., damage ...".*
- [ ] A9. Click "Take damage", pick a type, type 7, press Enter. *The game's menu of thirteen damage types plus "No type" opens at the cursor; the amount box has the focus; the HP bar drops by 7 and one line is announced.*
- [ ] A10. Click the minus button in the title bar and move the mouse away. *The window folds to its title bar, which stays exactly where it was; hovering opens it; it folds again shortly after the mouse leaves.*
- [ ] A11. Click the padlock, then try to drag the title bar and click the sheet's background. *The window doesn't move, the resize grip is gone, the padlock is solid, the click reaches the game world; a row on the sheet still reacts to a click.*
- [ ] A12. Click the cog. *The settings window opens in the sheet's theme: solid background, themed tabs, buttons and text.*
- [ ] A13. Close it and open another addon's Ace3 settings window. *That window looks stock: see-through, the game's own fonts, buttons, tick boxes and sliders.*
- [ ] A14. Move and resize the sheet, then `/reload`. *The sheet comes back at the same place and size, on the same tab, with the same hit points and slots.*
- [ ] A15. Play for two minutes: cast a spell, use an ability, take a short rest. *No Lua error at any point.*

## B. The sheet window

- [ ] B1. Drag the bottom-right corner to make the window as narrow as it goes. *It stops at a width where the six tabs still share one row and no row wraps onto the next.*
- [ ] B2. Make it as wide as half the screen. *Rows stretch; the three-in-a-row numbers (Combat, Checks) and two-in-a-row rows (Skills, Passives) stay in their columns.*
- [ ] B3. Resize slowly back and forth and let go. *After letting go no row lies over another, on every tab.*
- [ ] B4. Make it short. *A themed scroll bar appears; the mouse wheel scrolls; the title bar stays put.*
- [ ] B5. Open each of the six tabs in turn. *The open tab is marked, the others are not; each tab shows its sections; an empty one says "Nothing here yet."*
- [ ] B6. Hover each tab. *A tooltip with the tab's name and what is on it.*
- [ ] B7. Give an ability, a passive, a spell and an item very long names (Customize) and look at their rows at the narrowest width. *Names wrap inside their own row; the row below starts under them.*
- [ ] B8. Hover a row with [?] and click the [?] itself, then the rest of the row. *The [?] prints the breakdown in your chat only; the rest of the row rolls.*
- [ ] B9. Left-click and right-click "Next roll". *Normal, Advantage (green), Disadvantage (red); right-click adds "(every roll)"; after one roll an unlocked choice goes back to Normal.*
- [ ] B10. Hover a passive, a spell and an item. *The tooltip stays on screen, wraps, and is readable against the game's tooltip background.*
- [ ] B11. Drag the window to each screen edge. *It can't be dragged off screen.*
- [ ] B12. With the window minimized, drag it by its title bar and resize it while it is open. *It stays open while the mouse button is down; afterwards it folds to the bar at the new place.*
- [ ] B13. Minimize, then `/reload`. *Still minimized, and it opens to the height it had.*

## C. Popups and menus of the game

- [ ] C1. "Take damage" on a character with a resistance. *The resisted type is marked "(resisted)" in the menu; the announcement says "halved to".*
- [ ] C2. In the amount box press Escape; open it again and click Cancel. *Nothing is taken either time.*
- [ ] C3. Items tab: left-click "Coins", type `5 gp 3 sp`, Enter. *The purse grows by that; the box showed what you had.*
- [ ] C4. Click "Conditions". *A menu of tick boxes at the cursor; each has a tooltip; ticking one announces "is now [Poisoned]." and the row lists it; ticking Unconscious ticks Prone with it.*
- [ ] C5. On a character with advantage against something specific (for example a trait that helps against being Charmed), click the WIS save. *A menu "WIS save: what is it against?" with "Against being Charmed (advantage)" and "Something else"; the first rolls two dice, the second one.*
- [ ] C6. Shift-click the same save. *No menu; two dice.*
- [ ] C7. Cast Protection from Energy (or another protective spell with a choice). *A menu "...: who is it for?" with "Yourself: fire" and the like, and "Someone else"; picking yourself adds a passive and the Combat section lists the resistance.*
- [ ] C8. Close that menu without picking. *No slot is spent and nothing is announced.*
- [ ] C9. Cast a spell that needs its component once per target (Astral Projection, Create Undead). *A menu "...: how many ...s?"; a number your components don't cover is greyed with "(too few components)".*
- [ ] C10. The other menus: a Demon Hunter casting Metamorphosis ("choose a benefit"), a passive that asks for damage types ("resist which damage?"), an enchanter's "Disenchant" on the Trade tab. *Each opens at the cursor, lists its choices, and the pick shows on the sheet.*
- [ ] C11. Customize: press "Delete this ..." on an entry, and "Back to level" on the Character tab. *The game's confirmation popup; Cancel changes nothing.*
- [ ] C12. Open any of these menus while the sheet is minimized. *The menu opens and works; the sheet may fold behind it without an error.*

## D. Rolls and chat

- [ ] D1. Announce to Party, in a party: click a check. *The roll shows as a `/roll` and the line goes to party chat with your character's name in front.*
- [ ] D2. Announce to Party, not in a party (and Raid, not in a raid). *The line is shown to you alone and ends "(only you see this: you are not in a party)".*
- [ ] D3. Announce to Self only. *No `/roll` line at all; the result is printed for you alone.*
- [ ] D4. Cast a spell with many dice (8d6) on Emote. *Eight `/roll` lines, then one announcement with all eight values and the right sum; nothing is announced twice.*
- [ ] D5. Click two rolls quickly one after the other. *The second waits or is ignored; no announcement mixes the two rolls.*
- [ ] D6. Look at an announcement in chat. *Terms in square brackets are coloured links.*
- [ ] D7. Hover a link ([Vex], a skill, a spell, a condition). *A tooltip with what the term means and "Click to see how your number is worked out."*
- [ ] D8. Click your own link. *The breakdown of that number is printed for you alone.*
- [ ] D9. Post an item link and a `[text in brackets]` of your own in party chat. *The item link still works; brackets the rules don't know stay plain text.*
- [ ] D10. Make an announcement longer than a chat line (a spell with many notes). *It is sent as two or more lines: the first ends in "...", the next starts with "(continued)", the break falls between parts of the line and the result at the end is there; no error from the game.*
- [ ] D11. Roll during combat in a dungeon or raid encounter. *Either it works, or the line is shown to you with "the game blocks addon chat messages right now"; no error.*

## E. Item browser, stable, crafting

- [ ] E1. Items tab > "Browse items". *A window above everything else of ours, in the theme: a line with money, weight and attunement, a row of nine tabs, a search box, blocks two to a row.*
- [ ] E2. Open each tab. *The tabs stay on one row; each block has a title, readable text and its buttons on one row.*
- [ ] E3. Open the Magic tab. *"Showing 1-24 of N" with Previous greyed, above and below the blocks; Next shows 25-48 and the view starts at the top.*
- [ ] E4. Type part of a name in the search box and press Enter; then empty it and press Enter. *Only matching blocks from the whole tab; then everything again. No match says "Nothing here matches your search."*
- [ ] E5. Make the browser as narrow and as wide as it goes. *Blocks stay two to a row; button rows don't wrap; text wraps inside its block.*
- [ ] E6. With renown of Honored or better with a faction: click "Buying from". *It cycles through the factions; Buy buttons show the lower price.*
- [ ] E7. Items tab > "Browse the stable". *The same window turns into the stable (title "... - Stable") with its own tabs.*
- [ ] E8. Trade tab > "Make something" with a tool proficiency and the tool carried. *The crafting window: skill, money and materials on top, a tab per profession, each recipe with cost and time.*
- [ ] E9. Click the cog of each of the three. *Settings open on Customize > Inventory, > Mounts and companions, > Professions.*
- [ ] E10. In the creation wizard, step 5: "Open the closet". *The same window above the wizard with Take / Put back / Equip; what you take is counted on the wizard's page behind it.*
- [ ] E11. Look at the search box, buttons and scroll bar. *All in the theme; after closing, another addon's AceGUI window looks stock.*

## F. Spellbook and prepared spells

- [ ] F1. Mage: Actions tab > "Open spellbook". *A themed window titled "... - Spellbook": prepared count, cantrips, then spells by level with the slots left; unprepared spells are grey; a right-click after a long rest prepares one or puts it away and the sheet's list follows.*
- [ ] F2. Priest or Druid: "Change prepared spells". *A window "... - Prepared spells" with the count and every class spell; right-click swaps within the count.*
- [ ] F3. Minimize, lock and resize both windows, then `/reload`. *Each keeps its own size and place; the cog opens the matching Customize page.*

## G. The settings window

- [ ] G1. Open every tab (Character, Customize, General, Appearance, Import / Export, Settings profiles). *Themed tabs with the open one marked; no stock-looking part among them.*
- [ ] G2. Customize: click through every page in the tree on the left. *The tree is themed, the selected page is marked, each page fills in without an error, long pages scroll.*
- [ ] G3. Look at tick boxes (Proficiencies). *Themed box and tick; disabled ones are visibly greyed; clicking one keeps the theme.*
- [ ] G4. Look at sliders (Ability scores). *Themed track and handle; the handle moves in steps; a slider with nothing to choose is greyed.*
- [ ] G5. Open dropdown lists (Class and origin). *The button and the opened list are themed and readable; a long list scrolls; picking closes it.*
- [ ] G6. Type in a text box and a multi-line box (Import / Export). *Themed box, visible cursor and text; Ctrl+A and Ctrl+C work in the export box.*
- [ ] G7. Use a colour swatch (Appearance). *The game's colour picker opens; the sheet and this window follow the colour as you change it.*
- [ ] G8. Scroll a long page (Customize > Spells with many spells). *Themed scroll bar; content doesn't draw over the tabs or outside the window.*
- [ ] G9. Game menu > Options > AddOns > RP Sheet. *The same pages inside the game's own panel, in the game's stock look, working.*

## H. Wizard and level dialog on every theme

For each preset: pick it under Appearance, open `/sheet new` and look at steps 1, 3 and 5,
close with "Not now"; then press "Take level" on the Character tab and look at the
dialog. *Frame, title, headings, text, buttons, tick boxes, sliders, dropdowns and scroll
bars are all readable in that theme; nothing is white on light or dark on dark.*

- [ ] H1. Dark.
- [ ] H2. Parchment (the light one: dark text on a light background, no text shadow).
- [ ] H3. Alliance.
- [ ] H4. Horde.
- [ ] H5. Fel.
- [ ] H6. Void.
- [ ] H7. Minimal (see-through): *the sheet is see-through, the dialogs still have a nearly solid background.*
- [ ] H8. Change the theme while the settings window is open. *The settings window, the sheet and any open browser change at once.*
- [ ] H9. Pick another font and a larger font size. *Sheet rows and dialog text grow without overlapping; buttons still fit their text.*

## I. Wizard and level dialog, working

- [ ] I1. Hover a highlighted word in a summary. *A tooltip with the explanation at the cursor.*
- [ ] I2. Press Back and Next several times. *Choices are kept; the window doesn't flicker shut or reopen.*
- [ ] I3. "Not now" on a fresh profile, then `/reload`. *The wizard doesn't open by itself again; `/sheet new` still opens it.*
- [ ] I4. Open the wizard while the settings window is open. *The settings window closes; only one of the two is on screen.*
- [ ] I5. Level dialog with spells to pick (a caster's level). *Core spells and the spells of Azeroth under separate headings, by level; the count in the red line follows the ticks; "Take level" lights up at exactly the right number.*
- [ ] I6. Take a level from the settings window. *The dialog replaces the settings window, and the settings come back afterwards.*

## J. Other addons stay as they are

- [ ] J1. Open our settings, close them, open another addon's Ace3 settings. *Stock look in every part: frame, tabs, tree, buttons, tick boxes, sliders, dropdowns, text boxes, scroll bars.*
- [ ] J2. Open the other addon's settings first, then ours, then theirs again. *Ours is themed each time, theirs stock each time.*
- [ ] J3. Do the same after the creation wizard and after the level dialog. *Their window is stock.*
- [ ] J4. Do the same after closing the item browser. *Their buttons, text boxes and groups are stock.*
- [ ] J5. Close our settings with Escape and with its Close button, then open theirs. *Stock both ways, and no solid backing panel behind their window.*
- [ ] J6. Open another addon's dropdown list right after ours was open. *Stock list.*

## K. Minimap button

- [ ] K1. Hover the dice icon at the minimap. *A tooltip with the three clicks.*
- [ ] K2. Left-click, Shift-click, right-click it. *Show or hide the sheet; lock or unlock it; open the settings.*
- [ ] K3. Drag it around the minimap, `/reload`. *It stays where you left it.*
- [ ] K4. Untick "Show minimap icon" on the General tab, tick it again. *It goes and comes back without a reload.*

## L. Total RP 3

- [ ] L1. Hover your own character. *The Total RP 3 tooltip has a "Stats" section below the OOC block: summary, hit points and Armor Class, the six scores in two rows, the weapon, conditions.*
- [ ] L2. Change hit points and hover again. *The new value.*
- [ ] L3. Untick "Show stats in Total RP 3 tooltips". *The section is gone; Total RP 3's own tooltip is intact.*
- [ ] L4. Switch Total RP 3 profile. *The sheet switches to that profile's character (or the wizard is offered for an empty one); switching back brings the first one back unchanged.*
- [ ] L5. Settings > General. *"This sheet belongs to: Total RP 3 profile <name>"; "Announcing as" shows the profile's first name; unticking "Use my Total RP 3 name" changes it.*
- [ ] L6. Disable Total RP 3 and log in. *No error; the sheet belongs to "this WoW character"; everything else works.*

## M. Two players

Two players, A and B, both with RP Sheet and Total RP 3, same faction and realm, sharing
on, unless a line says otherwise. Lines that need a third player, another realm, the
other faction or an older version say so; skip the ones you can't set up.

Stats in the tooltip:

- [ ] M1. Not grouped. B hovers A, then targets A. *Within a moment B's Total RP 3 tooltip of A gains the "Stats" section with A's numbers, once (never two "Stats" titles).*
- [ ] M2. A loses 5 hit points; B hovers A again within half a minute, then after it. *B sees the old value at first and nothing is asked again (A is only asked once per 30 seconds), then the new one.*
- [ ] M3. A and B form a party. A loses hit points, ticks a condition, raises exhaustion, switches weapon. *About two seconds after each change B's tooltip of A shows it without B asking.*
- [ ] M4. B keeps the mouse on A while A changes hit points. *The open tooltip updates in place; the Stats section is still there once.*
- [ ] M5. A takes a long rest with the sheet window closed. *B sees A's full hit points.*
- [ ] M6. B types `/reload` while grouped and doesn't hover anyone. *Within about five seconds B has A's stats again (hover to look), and A has B's.*
- [ ] M7. B logs out and in again (not a reload) into the same group. *The same: stats both ways within a few seconds.*
- [ ] M8. A third player C with the addon joins the party. *C gets A's and B's stats and they get C's, without hovering.*
- [ ] M9. Convert the party to a raid. *Stats keep arriving after the next change; no error for anyone.*
- [ ] M10. Many clicks on the sheet for a few minutes in the raid (rolls, damage, healing, conditions). *No disconnect, no "throttled" errors, and the others' tooltips end up on the last values.*

Realms and factions:

- [ ] M11. A and B from different realms, one of them a realm with a space or an apostrophe in its name. *Stats arrive both ways, grouped and by hovering.*
- [ ] M12. Two characters with the same name on two realms, both in A's group. *A's tooltips show each one's own stats, never the other's.*
- [ ] M13. A and B of different factions, in one party. *The code expects stats to arrive through the party, and nothing to be asked by hovering outside one. Note what really happens.*

Sharing switched off:

- [ ] M14. In a party, A unticks "Share my stats". *B's tooltip of A loses its Stats section at once, without a reload; A's tooltip of B has none either.*
- [ ] M15. With A's sharing off: A changes hit points, hovers and targets B; B hovers A. *Nothing arrives either way; neither tooltip has a Stats section; no error.*
- [ ] M16. With A's sharing off, B clicks a term in A's announcement. *B sees "Asking A's sheet about ..." and a few seconds later "A's sheet didn't answer."*
- [ ] M17. A ticks "Share my stats" again. *Within a few seconds both tooltips have their Stats sections back, without hovering first.*

Total RP 3 profiles:

- [ ] M18. A switches Total RP 3 profile during play with the sheet window closed, to a profile with another character. *B's tooltip of A shows the other character after a few seconds.*
- [ ] M19. A switches to a profile without a character. *The wizard is offered to A once (not again on switching back and forth); B's tooltip of A has no Stats section.*
- [ ] M20. A character made without Total RP 3; then Total RP 3 is enabled and A logs in. *The character is on the profile at the first login, no wizard is offered, and B sees its stats.*
- [ ] M21. Total RP 3's tooltip options, one at a time: show the profile only, hide in combat, cropped text blocks. *The Stats section is below the OOC block or absent with the tooltip, never doubled and never in the middle of another block.*

Announcements and terms:

- [ ] M22. A announces a skill check on Emote, then Party, then Raid. *B sees the line with the terms as coloured links each time, and A's `/roll`.*
- [ ] M23. B hovers a term in A's line. *The term's rule text and "Click to ask A's sheet about it."*
- [ ] M24. B clicks it. *B's chat: "Asking A's sheet about ...", then "A - ..." with the breakdown from A's sheet. A sees nothing.*
- [ ] M25. A player of the other faction clicks a term in A's emote. *"Asking A's sheet about ..." and then "A's sheet didn't answer."*
- [ ] M26. Someone posts an item link and a spell link in the same chat, next to a line of the addon. *Both links still open their own tooltips; neither is turned into one of ours.*
- [ ] M27. A, with an accented letter in the character's name, announces a very long line (an attack with many dice and notes) on Emote and on Party. *It arrives as two or three messages, the first ending in "...", the next starting with "(continued)"; no letter is broken, every term is a whole link, the result at the end is there.*
- [ ] M28. A third player without the addon reads A's announcements. *Plain text with the terms in square brackets, nothing odd.*
- [ ] M29. A takes a long rest on Party, then types `/sheet undo`. *B reads "finishes a long rest." and then "takes back the long rest: ..."; B's tooltip of A is back on the hit points from before the rest.*

Blocked messages and versions:

- [ ] M30. Both enter an instance or encounter where the game blocks addon messages; A rolls and changes hit points. *No errors; A's announcements are shown to A alone with "the game blocks addon chat messages right now"; B's tooltip stays on the old values.*
- [ ] M31. The block ends (the encounter is over) and A does nothing. *Within about ten seconds B's tooltip of A is on A's current values.*
- [ ] M32. A on this version, B on the released 0.6.0. *Stats arrive both ways, by hovering and in a party; when A switches sharing off, B keeps the last copy until B reloads.*
- [ ] M33. A and B queue for a dungeon together (a party of friends). *Stats arrive over the instance channel: a third player in the instance with the addon sees both; A's Party announcements still go to party chat.*
- [ ] M34. A queues alone and lands in a dungeon finder group with B. *B's tooltip of A has stats without hovering; A's Party announcements show in instance chat for the whole group.*
- [ ] M35. A switches sharing off after B hovered A outside any group. *B's tooltip of A loses the Stats section within a few seconds (a whispered clear).*

## N. Odds and ends

- [ ] N1. `/sheet`, `/sheet config`, `/sheet new`, `/sheet lock`, `/sheet rest`, `/sheet damage 14 fire`, `/sheet damage 28 fire -5`, `/sheet heal 8`, and each with `/rpsheet`. *Each does what the README's table says; `/sheet damage 5 banana` names the valid types.*
- [ ] N1a. `/sheet short`, `/sheet rest short`, `/sheet tab items` (and each other tab, also while the sheet is hidden), `/sheet items`, `/sheet level`, `/sheet help`. *A short rest; the sheet shows with that tab open; the item browser shows or hides; the level dialog opens (or a line says why not); the help lists every command.*
- [ ] N1b. Take a long rest by mistake, then `/sheet undo`; rest again, and right-click "Long rest" instead. *Hit points, slots, resources and conditions are as before the rest and one line says so on the announce channel; after a roll, a spell or damage the undo says there is nothing to take back.*
- [ ] N1c. Hover the cog in the sheet's title bar. *The tooltip says "Settings" and names what the settings window holds.*
- [ ] N1d. Log in on a character or Total RP 3 profile without a sheet, close the wizard with the window's own close button, log out, and look at `WTF/Account/<name>/SavedVariables/RPSheetDB.lua`. *No entry under `sheets` for that key; the entries of characters that exist are untouched.*
- [ ] N2. Log in while in combat on a fresh profile. *The wizard is not opened in combat.*
- [ ] N3. Open and use the sheet during combat. *Clicks, rolls and the settings window work; no "action blocked" message.*

## O. Combat sessions (two players, A and B, in a party)

- [ ] O1. A types `/sheet combat` and clicks "Start a combat session". *A's chat line says so; B is told and B's combat window offers "Join the session".*
- [ ] O2. B joins and clicks the skull. *Both windows list both characters with hit points and Armor Class; B has the skull in front of the name.*
- [ ] O3. A clicks "Call for initiative"; both roll. *Each roll is announced once, by A's game, with the mark; then "Round 1. ...'s turn." and the window of the one whose turn it is opens with "Your turn".*
- [ ] O4. The one whose turn it is clicks the other's row, then attacks. *A's game announces the attack with "hits" or "misses" and the Armor Class.*
- [ ] O5. Attack again, then hover a greyed action. *The second attack is refused (without Extra Attack); the tooltip says "Not now" and why.*
- [ ] O6. The other player clicks an attack out of turn on the sheet itself. *Refused with "It is ...'s turn."*
- [ ] O7. "End turn", round the table twice. *Turn and round lines are announced; the action is free again each turn.*
- [ ] O8. A third player joins now. *They are asked to roll and act when their place comes up.*
- [ ] O9. A takes damage to 0 with "Take damage". *"... drops to 0 hit points." is announced; the window shows a death save on A's turn.*
- [ ] O10. A reloads mid-fight. *After a few seconds the session is back on both sides with the same turn.*
- [ ] O11. A ends the session; B clicks "Put my character back as before the fight". *B's hit points, slots and resources are as when B joined.*
- [ ] O12. In WoW Forever, as owner. *Your own lines go out with your clicks; lines for the other player's rolls wait behind a [Send it] link.*
- [ ] O13. On your turn cast a spell you concentrate on that lasts a minute (Bless, Blur). *The combat window gets a "Running" heading with the spell and "10 rounds left"; one less each time your turn starts.*
- [ ] O14. Off your turn cast Shield, or switch on a reckless attack on your turn. *Listed as ending when your next turn starts; at that moment it is switched off and the owner's game says so.*
- [ ] O15. Click a running row. *It ends now, announced as ended early.*
- [ ] O16. As a Shaman, rage, then end a later turn without attacking. *You are reminded what keeps a rage up; the rage stays on until you click it off.*
- [ ] O17. End the session with something still running. *You are told it is yours to end again; it stays on.*
- [ ] O18. As owner click "Add a combatant you run" and type `Gnoll 13 22 +1`. *A Gnoll row appears for everyone, marked as run by the owner; with initiative called, its roll is announced.*
- [ ] O19. On the Gnoll's turn click a player's row, then "Roll an attack for Gnoll" and type `+5`. *Your game announces the roll and whether it hits that player's Armor Class.*
- [ ] O20. With the player's row picked, "Deal damage", `7 fire`. *Their sheet takes it (halved if they resist fire) and their hit points in the list follow.*
- [ ] O21. "Ask for a saving throw", `DEX 15`. *They are told and get a "Roll the Dexterity save" row; after their roll your game adds "succeeds" or "fails against DC 15".*
- [ ] O22. Pick the Gnoll and deal it more damage than it has. *"Gnoll drops to 0 hit points."; its turn no longer comes up.*
- [ ] O23. Pick the other player and click "Hand the session over". *They get the owner's rows, you lose them, and their game announces the next turn.*
