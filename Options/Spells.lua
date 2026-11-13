-- "Spells" tab: the character's spell list. Spells are entered by the player.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local With = Opt.With

local function Build(spell)
    local function self() return spell end
    local rollsDice = function() return spell.count == 0 end
    return {
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        level = With({
            type = "select", order = 2, name = "Level",
            desc = "Cantrips need no slot. Other spells use your lowest free slot of that level or higher.",
            values = R.SPELL_LEVELS,
        }, self, "level"),
        concentration = With({
            type = "toggle", order = 3, name = "Concentration",
        }, self, "concentration"),
        kind = With({
            type = "select", order = 4, name = "Resolved by",
            desc = "Spell attack: you roll a d20 + your spell attack bonus. Saving throw: the target rolls against your spell save DC.",
            values = R.SPELL_KINDS, sorting = R.SPELL_KIND_ORDER,
        }, self, "kind"),
        save = With({
            type = "select", order = 5, name = "Saving throw",
            hidden = function() return spell.kind ~= "SAVE" end,
            values = Opt.STAT_VALUES, sorting = R.STATS,
        }, self, "save"),
        count = With({
            type = "range", order = 6, min = 0, max = 40, softMax = 12, step = 1, name = "Number of dice",
            desc = "Dice of damage or healing. 0 if the spell rolls none.",
        }, self, "count"),
        sides = With({
            type = "select", order = 7, name = "Die", hidden = rollsDice,
            values = Opt.DIE_VALUES, sorting = Opt.DIE_ORDER,
        }, self, "sides"),
        dice = With({
            type = "select", order = 8, name = "Counts as", hidden = rollsDice, values = R.DICE_KINDS,
        }, self, "dice"),
        addMod = With({
            type = "toggle", order = 9, name = "Add spellcasting modifier", hidden = rollsDice,
            desc = "Adds your spellcasting ability modifier to the dice, as healing spells usually do.",
        }, self, "addMod"),
        desc = With({
            type = "input", order = 10, width = "full", multiline = 3, name = "Description",
        }, self, "desc", true),
    }
end

Opt.lists.spells = {
    order = 8.5, title = "Spells", noun = "spell", template = R.TEMPLATES.spell, build = Build,
    help = "Your spells. Enter the ones you know or have prepared: clicking one on the sheet spends a slot, rolls the attack or shows the save, and rolls its dice. Casting with a higher slot adds dice in most spells; add those by hand.\n",
}
