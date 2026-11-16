-- "Metamagic, invocations, maneuvers" page under Customize: the options a class picks
-- a set number of (Data/Picks.lua, Data/Maneuvers.lua), set directly. The level dialog
-- lets one be exchanged where the rules do and keeps the rest; nothing is refused
-- here, and what goes against the rules is said in red.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local Sheet = Opt.Sheet

local RED, GOLD = Opt.RED, Opt.GOLD

-- "Name (2 of 3 chosen)", the count in red when it is not what the rules give.
local function Heading(title, have, limit)
    return ("%s (%s%d of %d|r chosen)"):format(title, have ~= limit and RED or GOLD, have, limit)
end

local function Picks(key)
    local sheet = Sheet()
    if type(sheet.picks[key]) ~= "table" then sheet.picks[key] = {} end
    return sheet.picks[key]
end

-- A pick that was deleted from the sheet's lists comes back when it is ticked again.
local function Set(store, auto, name, value)
    store[name] = value or nil
    if value and type(Sheet().dismissed) == "table" then Sheet().dismissed[auto] = nil end
    Opt.Regrant()
end

-- What the picks of a list have against the rules, as red lines, or "".
local function ListWarnings(key)
    local sheet, list, lines = Sheet(), R.PICK_LISTS[key], {}
    local have, limit = ns.PicksKnown(sheet, key), ns.SheetPickLimit(sheet, key)
    if have ~= limit then
        lines[#lines + 1] = ("By the rules you know %d at this level, and %d are chosen."):format(limit, have)
    end
    local view, picked = ns.ListView(sheet, key), Picks(key)
    for _, name in ipairs(list.order) do
        local why = picked[name] and ns.PickBlocked(key, name, view.level, picked, view.subclass, view)
        if why then lines[#lines + 1] = ("%s %s."):format(name, why) end
    end
    if #lines == 0 then return "" end
    return RED .. table.concat(lines, "\n") .. "|r\n"
end

local args = {
    help = {
        type = "description", order = 0, fontSize = "medium",
        name = "The options your class lets you pick a set number of. They are chosen when you level, where one of them can be exchanged for another: a Metamagic option or an invocation with each level of its class, a maneuver each time you learn new ones. Here any of them can be ticked or unticked, for a DM's ruling or to put a mistake right.\n",
    },
}

local order = 0
for _, key in ipairs(R.PICK_LIST_ORDER) do
    local list = R.PICK_LISTS[key]
    -- A list marked custom has a page of its own (spells, beast forms, tools).
    if not list.custom then
        order = order + 10
        local group = {
            type = "group", inline = true, order = order, args = {},
            name = function() return Heading(list.title, ns.PicksKnown(Sheet(), key), ns.SheetPickLimit(Sheet(), key)) end,
            hidden = function() return ns.SheetPickLimit(Sheet(), key) == 0 end,
        }
        group.args.warning = {
            type = "description", order = 0, fontSize = "medium",
            name = function() return ListWarnings(key) end,
            hidden = function() return ListWarnings(key) == "" end,
        }
        for index, name in ipairs(list.order) do
            group.args["pick" .. index] = {
                type = "toggle", order = index, width = 1.5, name = name, desc = list.items[name].desc,
                get = function() return Picks(key)[name] or false end,
                set = function(_, value) Set(Picks(key), ("pick:%s:%s"):format(key, name), name, value) end,
            }
        end
        args["list" .. key] = group
    end
end

-- The origin feat of each Lessons of the First Ones (Sheet/LessonFeats.lua). Any can
-- be set here; one taken already is said in red.
local LESSONS = { "Lessons of the First Ones", "Lessons of the First Ones (second)", "Lessons of the First Ones (third)" }
for index, pick in ipairs(LESSONS) do
    args.listinvocations.args["lessons" .. index] = {
        type = "select", order = 900 + index, width = 1.5, name = pick .. ": origin feat",
        desc = function()
            local lines = { "The origin feat this invocation gives. Its own choices, if any, are made under Class and feat choices." }
            local picked = Sheet().featureOptions[pick]
            local allowed = false
            for _, name in ipairs(ns.LessonOptions(Sheet(), pick)) do allowed = allowed or name == picked end
            if picked and R.FEATS[picked] and not allowed then lines[#lines + 1] = RED .. "You have this feat already from elsewhere.|r" end
            return table.concat(lines, "\n\n")
        end,
        hidden = function()
            for _, each in ipairs(ns.LessonPicks(Sheet())) do
                if each == pick then return false end
            end
            return true
        end,
        values = function() return (Opt.ListMap(ns.LessonOptions(Sheet(), pick, true), true)) end,
        sorting = function() return (select(2, Opt.ListMap(ns.LessonOptions(Sheet(), pick, true), true))) end,
        get = function() return Sheet().featureOptions[pick] or "" end,
        set = function(_, value)
            Sheet().featureOptions[pick] = value ~= "" and value or nil
            Opt.Regrant()
        end,
    }
end

local function Maneuvers()
    local sheet = Sheet()
    if type(sheet.maneuvers) ~= "table" then sheet.maneuvers = {} end
    return sheet.maneuvers
end

args.maneuvers = {
    type = "group", inline = true, order = order + 10, args = {},
    name = function() return Heading("Maneuvers", ns.ManeuversKnown(Sheet()), ns.SheetManeuverLimit(Sheet())) end,
    hidden = function() return ns.SheetManeuverLimit(Sheet()) == 0 end,
}
args.maneuvers.args.warning = {
    type = "description", order = 0, fontSize = "medium",
    name = function()
        return ("%sBy the rules you know %d at this level, and %d are chosen.|r\n"):format(RED, ns.SheetManeuverLimit(Sheet()), ns.ManeuversKnown(Sheet()))
    end,
    hidden = function() return ns.ManeuversKnown(Sheet()) == ns.SheetManeuverLimit(Sheet()) end,
}
for index, name in ipairs(R.MANEUVER_ORDER) do
    local maneuver = R.MANEUVERS[name]
    args.maneuvers.args["maneuver" .. index] = {
        type = "toggle", order = index, width = 1.5, name = name,
        desc = maneuver.desc .. (maneuver.save and (" " .. R.STAT_NAMES[maneuver.save] .. " save.") or ""),
        get = function() return Maneuvers()[name] or false end,
        set = function(_, value) Set(Maneuvers(), "maneuver:" .. name, name, value) end,
    }
end

Opt.custom.classPicks = {
    type = "group", order = 6.6, name = Opt.CLASS_PICKS_PAGE, args = args,
    hidden = function() return not ns.HasClassPicks(Sheet()) end,
}
