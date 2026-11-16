-- The top of the Customize, Spells list: the counts against the class's limits, the
-- spell components switch, and adding a spell from the built-in set (Data/Spells.lua).
-- The list itself is set up in Options/Spells.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt

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

Opt.SpellListTop = Extra
