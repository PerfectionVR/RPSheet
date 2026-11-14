-- "Spells" tab: the character's spell list. Spells are entered by the player.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
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
            type = "select", order = 8, name = "Counts as", hidden = rollsDice, values = R.DICE_KINDS, sorting = R.DICE_KIND_ORDER,
        }, self, "dice"),
        addMod = With({
            type = "toggle", order = 9, name = "Add spellcasting modifier", hidden = rollsDice,
            desc = "Adds your spellcasting ability modifier to the dice, as healing spells usually do.",
        }, self, "addMod"),
        scales = With({
            type = "toggle", order = 9.5, name = "Grows with level",
            desc = "For damaging cantrips: rolls one more set of dice at character levels 5, 11 and 17.",
            hidden = function() return spell.count == 0 or spell.level > 0 end,
        }, self, "scales"),
        desc = With({
            type = "input", order = 10, width = "full", multiline = 3, name = "Description",
        }, self, "desc", true),
    }
end

---------------------------------------------------------------------------
-- Adding a spell from the built-in set (Data/Spells.lua)
---------------------------------------------------------------------------
local picked = "" -- the spell chosen in the dropdown

-- Spells of the character's class that aren't on the sheet yet, cantrips first.
local function Available()
    local class = RPSheet:ClassData()
    local have, names = {}, {}
    for _, spell in ipairs(Opt.Sheet().spells) do have[spell.name] = true end
    for _, name in ipairs(class and R.SPELL_LISTS[class.base] or {}) do
        if not have[name] then names[#names + 1] = name end
    end
    table.sort(names, function(a, b)
        if R.SPELLS[a].level ~= R.SPELLS[b].level then return R.SPELLS[a].level < R.SPELLS[b].level end
        return a < b
    end)
    return names
end

-- Extra controls on the Spells page, above the list.
local function Extra(args)
    args.known = {
        type = "select", order = 0.5, name = "Common spells for your class", width = "double",
        desc = "Cantrips and 1st-level spells with their dice and saves filled in. Any other spell can be added by hand.",
        hidden = function() return #Available() == 0 and picked == "" end,
        values = function()
            local values = {}
            for _, name in ipairs(Available()) do
                values[name] = ("%s (%s)"):format(name, R.SPELLS[name].level == 0 and "cantrip" or "1st level")
            end
            return values
        end,
        sorting = Available,
        get = function() return picked end,
        set = function(_, value) picked = value end,
    }
    args.addKnown = {
        type = "execute", order = 0.6, name = "Add this spell",
        hidden = function() return #Available() == 0 and picked == "" end,
        disabled = function() return not R.SPELLS[picked] end,
        func = function()
            local spells = Opt.Sheet().spells
            spells[#spells + 1] = CopyTable(R.SPELLS[picked])
            picked = ""
            ns.RebuildOptions()
            Opt.Changed()
        end,
    }
    args.breakKnown = { type = "description", order = 0.7, name = "" }
end

Opt.lists.spells = {
    extra = Extra,
    order = 2, title = "Spells", noun = "spell", template = R.TEMPLATES.spell, build = Build,
    help = "Your spells. Pick common ones for your class from the list, or add any spell by hand: clicking one on the sheet spends a slot, rolls the attack or shows the save, and rolls its dice. Casting with a higher slot adds dice in most spells; add those by hand.\n",
}
