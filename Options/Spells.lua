-- Customize, Spells: the character's spell list. Spells are picked from the built-in
-- set or entered by the player. The parts: Options/SpellListTop.lua (above the list)
-- and Options/SpellPage.lua (one spell's page).
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt

Opt.lists.spells = {
    extra = Opt.SpellListTop,
    order = 2, title = "Spells", noun = "spell", template = R.TEMPLATES.spell, build = Opt.SpellPage,
    help = "Your spells. Pick common ones for your class from the list, or add any spell by hand: clicking one on the sheet spends a slot, rolls the attack or shows the save, and rolls its dice. A built-in spell knows what a higher slot adds to it. For a spell of your own, set \"Dice per higher slot\" on its page; \"Grows with level\" does the same for a cantrip's dice at character levels 5, 11 and 17.\n",
}
