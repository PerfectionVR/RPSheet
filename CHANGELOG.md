# Changelog

## Unreleased

Switched from the earlier simplified rules to D&D 5e (2024) as used by the
*D&D: World of Warcraft* book.

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
