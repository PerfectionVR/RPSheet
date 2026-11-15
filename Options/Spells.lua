-- "Spells" tab: the character's spell list. Spells are entered by the player.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
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

---------------------------------------------------------------------------
-- Adding a spell from the built-in set (Data/Spells.lua)
---------------------------------------------------------------------------
local picked = "" -- the spell chosen in the dropdown

-- "Cantrips 3 of 3. Prepared spells 4 of 5, up to 1st level."
local function Limits()
    local maxCantrips, maxPrepared, highest = RPSheet:SpellLimits()
    local cantrips, prepared = RPSheet:SpellCounts()
    if maxPrepared == 0 and maxCantrips == 0 then
        return "Your class doesn't cast spells. Spells from a lineage or a feat can still be added; they don't count against a limit.\n"
    end
    local function Count(have, limit)
        return ("%s%d of %d|r"):format(have > limit and Opt.RED or Opt.GOLD, have, limit)
    end
    -- With several classes every spellcasting class has its own numbers.
    local sheet = Opt.Sheet()
    if ns.IsMulticlass(sheet) then
        local lines = {}
        for _, key in ipairs(ns.CasterKeys(sheet)) do
            local classCantrips, classPrepared, classHighest = RPSheet:SpellLimits(key)
            local haveCantrips, havePrepared = RPSheet:SpellCounts(nil, key)
            lines[#lines + 1] = ("%s: cantrips %s, prepared spells %s, of spell levels up to %s."):format(R.CLASSES[key].name,
                Count(haveCantrips, classCantrips), Count(havePrepared, classPrepared),
                classHighest > 0 and R.SPELL_LEVELS[classHighest]:lower() or "none")
        end
        lines[#lines + 1] = "Each class prepares its own spells, as if it were your only class, and casts them with its own ability; the spell slots are shared. A spell's page says which class it belongs to. Spells marked as not counting are left out.\n"
        return table.concat(lines, "\n")
    end
    local text = ("Prepared spells %s, with spell slots up to %s."):format(Count(prepared, maxPrepared), highest > 0 and R.SPELL_LEVELS[highest]:lower() or "none")
    if maxCantrips > 0 then text = ("Cantrips %s. "):format(Count(cantrips, maxCantrips)) .. text end
    return text .. " Spells marked as not counting are left out.\n"
end

-- Spells of the character's class that aren't on the sheet yet, cantrips first.
local function Available()
    local class = RPSheet:ClassData()
    local have, names = {}, {}
    for _, spell in ipairs(Opt.Sheet().spells) do have[spell.name] = true end
    -- Only spells of a level the character has slots for.
    local highest = 0
    for level, count in pairs(RPSheet:SpellSlots()) do
        if count > 0 then highest = math.max(highest, level) end
    end
    for _, name in ipairs(class and R.ClassSpellList(Opt.Sheet().class) or {}) do
        if not have[name] and R.SPELLS[name].level <= highest then names[#names + 1] = name end
    end
    -- Spells the class's own subclass gives are always prepared: they only need the slots.
    for _, name in ipairs(R.CLASS_SPELLS[Opt.Sheet().class] or {}) do
        if not have[name] then names[#names + 1] = name end
    end
    -- The spells of the classes taken after the first.
    local listed = {}
    for _, name in ipairs(names) do listed[name] = true end
    for _, key in ipairs(ns.ExtraClassKeys(Opt.Sheet())) do
        for _, name in ipairs(R.ClassSpellList(key)) do
            if not have[name] and not listed[name] and R.SPELLS[name].level <= highest then
                names[#names + 1], listed[name] = name, true
            end
        end
        for _, name in ipairs(R.CLASS_SPELLS[key] or {}) do
            if not have[name] and not listed[name] then names[#names + 1], listed[name] = name, true end
        end
    end
    table.sort(names, R.SpellBefore) -- core spells first, then those of Azeroth
    return names
end

-- Extra controls on the Spells page, above the list.
local function Extra(args)
    args.limits = { type = "description", order = 0.4, fontSize = "medium", name = Limits }
    args.components = {
        type = "toggle", order = 0.45, width = "full", name = "Check spell components",
        desc = "Some spells need a component with a price, such as a diamond. While this is on, such a spell can only be cast when you carry the component, and a component the casting uses up is taken from your inventory. Switch it off when your DM rules otherwise.",
        get = function() return not Opt.Sheet().componentsWaived end,
        set = function(_, value) Opt.Sheet().componentsWaived = not value; Opt.Changed() end,
    }
    args.known = {
        type = "select", order = 0.5, name = "Spells for your class", width = "double",
        desc = "The spells of your class up to the highest level you have slots for, with their dice and saves filled in. Any other spell can be added by hand. The counts above turn red when you go past what your class allows.",
        hidden = function() return #Available() == 0 and picked == "" end,
        values = function()
            local values = {}
            for _, name in ipairs(Available()) do
                values[name] = R.SpellChoiceLabel(name)
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
            local spell = CopyTable(R.SPELLS[picked])
            for _, name in ipairs(R.CLASS_SPELLS[Opt.Sheet().class] or {}) do
                if name == picked then spell.free = true end -- always prepared
            end
            -- With several classes the spell goes to the first of them that has it on
            -- its list; it can be given to another on the spell's own page.
            local sheet = Opt.Sheet()
            if ns.IsMulticlass(sheet) then
                for _, key in ipairs(ns.CasterKeys(sheet)) do
                    local owns = R.OnClassSpellList(key, picked)
                    for _, name in ipairs(R.CLASS_SPELLS[key] or {}) do
                        if name == picked then owns, spell.free = true, true end
                    end
                    if owns and (spell.class or "") == "" then spell.class = key end
                end
            end
            spells[#spells + 1] = spell
            -- A Mage prepares from the book, so the spell is written into it as well.
            if ns.HasSpellbook(sheet) and spell.level > 0 and not spell.free and ns.SpellIsOf(spell, ns.BookClass(sheet)) then
                ns.SpellbookAdd(sheet, picked)
            end
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
    help = "Your spells. Pick common ones for your class from the list, or add any spell by hand: clicking one on the sheet spends a slot, rolls the attack or shows the save, and rolls its dice. A built-in spell knows what a higher slot adds to it. For a spell of your own, set \"Dice per higher slot\" on its page; \"Grows with level\" does the same for a cantrip's dice at character levels 5, 11 and 17.\n",
}
