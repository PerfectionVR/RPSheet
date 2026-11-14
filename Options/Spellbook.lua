-- "Spellbook" page under Customize: the spells in a Mage's book. Spells are added from
-- the class list and removed here; which of them are prepared can be set here too, or
-- in the spellbook window on the sheet.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet = Opt.Sheet

local picked = "" -- the spell chosen in the dropdown

local function Highest()
    local highest = 0
    for level, count in pairs(RPSheet:SpellSlots()) do
        if count > 0 then highest = math.max(highest, level) end
    end
    return highest
end

local function Choices()
    return ns.SpellbookChoices(Sheet(), Highest())
end

local function Count(have, limit)
    return ("%s%d of %d|r"):format(have > limit and Opt.RED or Opt.GOLD, have, limit)
end

local args = {
    help = {
        type = "description", order = 0, fontSize = "medium",
        name = function()
            local sheet = Sheet()
            local _, maxPrepared = RPSheet:SpellLimits()
            local _, prepared = RPSheet:SpellCounts()
            return ("Your spellbook holds the spells of level 1 and higher that you own. You start with six and write in two more each level; others can be copied in from scrolls and other books. Cantrips are not in the book: they are on the Spells page.\n\nIn the book: %s for level %d by the rules. Prepared: %s.\n\nOnly prepared spells can be cast, except rituals. Open the book from the Spells section of the sheet to cast and prepare.\n"):format(
                Count(#ns.SpellbookNames(sheet), ns.SpellbookSize(sheet.level)), sheet.level, Count(prepared, maxPrepared))
        end,
    },
    known = {
        type = "select", order = 1, name = "Spells for your class", width = "double",
        desc = "The spells of your class up to the highest level you have slots for.",
        hidden = function() return #Choices() == 0 and picked == "" end,
        values = function()
            local values = {}
            for _, name in ipairs(Choices()) do
                values[name] = ("%s (%s)"):format(name, R.SPELL_LEVELS[R.SPELLS[name].level]:lower())
            end
            return values
        end,
        sorting = Choices,
        get = function() return picked end,
        set = function(_, value) picked = value end,
    },
    add = {
        type = "execute", order = 2, name = "Write it in the book",
        hidden = function() return #Choices() == 0 and picked == "" end,
        disabled = function() return not R.SPELLS[picked] end,
        func = function()
            ns.Spellbook(Sheet())[picked] = true
            picked = ""
            ns.RebuildOptions()
            Opt.Changed()
        end,
    },
    listHeader = { type = "header", order = 5, name = "In the book" },
}

-- One row per spell: a tick box for prepared, and a button to take it out of the book.
table.insert(Opt.rebuilders, function()
    for key in pairs(args) do
        if key:find("^book") then args[key] = nil end
    end
    local sheet = Sheet()
    if not ns.HasSpellbook(sheet) then return end
    for index, name in ipairs(ns.SpellbookNames(sheet)) do
        local known = R.SPELLS[name]
        args["bookPrepared" .. index] = {
            type = "toggle", order = 10 + index, width = 1.6,
            name = ("%s (%s)"):format(name, R.SPELL_LEVELS[known.level]:lower()),
            desc = known.desc .. "\n\nTicked: prepared.",
            get = function() return RPSheet:PreparedSpell(name) ~= nil end,
            set = function(_, value)
                if value then RPSheet:PrepareSpell(name) else RPSheet:UnprepareSpell(name) end
                Opt.Changed()
            end,
        }
        args["bookRemove" .. index] = {
            type = "execute", order = 10 + index + 0.5, width = 0.7, name = "Remove",
            desc = ("Takes %s out of the book, and off your prepared spells."):format(name),
            func = function()
                RPSheet:UnprepareSpell(name)
                ns.Spellbook(Sheet())[name] = nil
                ns.RebuildOptions()
                Opt.Changed()
            end,
        }
    end
end)

Opt.custom.spellbook = {
    type = "group", order = 2.5, name = "Spellbook", args = args,
    hidden = function() return not ns.HasSpellbook(Sheet()) end,
}
