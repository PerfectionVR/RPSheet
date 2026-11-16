-- One spell's page under Customize, Spells: the controls for its facts. The list
-- itself is set up in Options/Spells.lua.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local With = Opt.With

local function Build(spell)
    local function self() return spell end
    local rollsDice = function() return spell.count == 0 end
    -- A control for a fact of the spell. Changing one makes the spell the player's
    -- own: a copy of a listed spell then keeps it when the listed spell is corrected
    -- (Sheet/SpellRefresh.lua).
    local function Own(option, key, isText)
        With(option, self, key, isText)
        local set = option.set
        option.set = function(info, value)
            spell.edited = true
            set(info, value)
        end
        return option
    end
    return {
        name = Own({ type = "input", order = 1, name = "Name" }, "name", true),
        level = {
            type = "select", order = 2, name = "Level",
            desc = "Cantrips need no slot. Other spells use your lowest free slot of that level or higher, so a spell above your slots can't be cast.",
            values = R.SPELL_LEVELS,
            get = function() return spell.level end,
            set = function(_, value) spell.level, spell.edited = value, true; Opt.Changed() end,
        },
        -- Only a character with more than one spellcasting class has this to choose.
        class = {
            type = "select", order = 2.4, name = "Class",
            desc = "The class this spell belongs to. It is cast with that class's spellcasting ability and counts against that class's cantrips or prepared spells.",
            hidden = function() return #ns.CasterKeys(Opt.Sheet()) < 2 end,
            values = function()
                local values = {}
                for _, key in ipairs(ns.CasterKeys(Opt.Sheet())) do values[key] = R.CLASSES[key].name end
                return values
            end,
            get = function() return ns.SpellClass(Opt.Sheet(), spell) end,
            set = function(_, value) spell.class = value; Opt.Changed() end,
        },
        free = With({
            type = "toggle", order = 2.5, width = "double",
            name = "Doesn't count against my limit",
            desc = "For spells that are always prepared, or that come from a subclass, a lineage or a feat. They are left out of the counts above.",
        }, self, "free"),
        concentration = Own({
            type = "toggle", order = 3, name = "Concentration",
        }, "concentration"),
        kind = Own({
            type = "select", order = 4, name = "Resolved by",
            desc = "Spell attack: you roll a d20 + your spell attack bonus. Saving throw: the target rolls against your spell save DC.",
            values = R.SPELL_KINDS, sorting = R.SPELL_KIND_ORDER,
        }, "kind"),
        save = Own({
            type = "select", order = 5, name = "Saving throw",
            hidden = function() return spell.kind ~= "SAVE" end,
            values = Opt.STAT_VALUES, sorting = R.STATS,
        }, "save"),
        count = Own({
            type = "range", order = 6, min = 0, max = 40, softMax = 12, step = 1, name = "Number of dice",
            desc = "Dice of damage or healing. 0 if the spell rolls none.",
        }, "count"),
        sides = Own({
            type = "select", order = 7, name = "Die", hidden = rollsDice,
            values = Opt.DIE_VALUES, sorting = Opt.DIE_ORDER,
        }, "sides"),
        dice = Own({
            type = "select", order = 8, name = "Counts as", hidden = rollsDice, values = R.DICE_KINDS, sorting = R.DICE_KIND_ORDER,
        }, "dice"),
        -- (never overwritten by the listed spell, so setting it doesn't mark the spell)
        damage = With({
            type = "select", order = 8.5, name = "Damage type",
            desc = "What kind of damage the dice deal, for features that treat one kind differently. Left unset, a spell from the built-in list keeps its own.",
            hidden = function() return spell.count == 0 or spell.dice ~= "DAMAGE" end,
            values = R.DAMAGE_TYPE_VALUES, sorting = R.DAMAGE_TYPE_ORDER,
        }, self, "damage"),
        addMod = Own({
            type = "toggle", order = 9, name = "Add spellcasting modifier", hidden = rollsDice,
            desc = "Adds your spellcasting ability modifier to the dice, as healing spells usually do.",
        }, "addMod"),
        scales = Own({
            type = "toggle", order = 9.5, name = "Grows with level",
            desc = "For damaging cantrips: rolls one more set of dice at character levels 5, 11 and 17.",
            hidden = function() return spell.count == 0 or spell.level > 0 end,
        }, "scales"),
        up = Own({
            type = "range", order = 9.7, min = 0, max = 10, softMax = 4, step = 1, name = "Dice per higher slot",
            desc = "How many more of its dice the spell rolls for each slot level above its own, when you cast it with a higher slot. 0 if a higher slot adds none.",
            hidden = function() return spell.count == 0 or spell.level == 0 end,
        }, "up"),
        desc = Own({
            type = "input", order = 10, width = "full", multiline = 3, name = "Description",
        }, "desc", true),
        -- A copy of a built-in spell that was changed here no longer follows it.
        own = {
            type = "description", order = 11, fontSize = "medium",
            hidden = function() return not (spell.edited and ns.ListedSpell(spell)) end,
            name = Opt.GOLD .. "You changed this spell by hand, so it keeps what you set when the built-in spell of this name is corrected.|r",
        },
        restore = {
            type = "execute", order = 12, name = "Use the built-in spell", width = "double",
            desc = "Puts back the built-in spell's roll, dice and description, and lets it follow corrections again. Its class and whether it counts against your limit stay.",
            hidden = function() return not (spell.edited and ns.ListedSpell(spell)) end,
            func = function()
                ns.RefreshSpell(spell, true)
                Opt.Changed()
            end,
        },
    }
end

Opt.SpellPage = Build
