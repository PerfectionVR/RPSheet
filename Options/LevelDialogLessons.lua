-- The level dialog asks for the origin feat of each Lessons of the First Ones picked
-- (Sheet/LessonFeats.lua), and holds the dialog until it is chosen. Kept in the
-- draft's copy of featureOptions; written to the sheet when the dialog is confirmed.
-- It loads after the dialog's other parts and before Options/LevelDialog.lua
-- registers them.
local _, ns = ...
local R = ns.Rules
local L = ns.LevelDialog
local args = L.args

local LESSONS = { "Lessons of the First Ones", "Lessons of the First Ones (second)", "Lessons of the First Ones (third)" }

local function Picked(pick)
    return L.draft ~= nil and L.PickLimit("invocations") > 0 and L.draft.picks.invocations[pick] == true
end

-- What the pick can be: an origin feat the character doesn't have from elsewhere,
-- nor from another of these picks.
local function Options(pick)
    local like = setmetatable({ featureOptions = L.draft.options }, { __index = L.Sheet() })
    local names = {}
    for _, name in ipairs(ns.LessonOptions(like, pick)) do
        local other = false
        for _, each in ipairs(LESSONS) do
            other = other or (each ~= pick and Picked(each) and L.draft.options[each] == name and not R.FEATS[name].repeatable)
        end
        if not other then names[#names + 1] = name end
    end
    return names
end

local function Chosen(pick)
    local value = L.draft.options[pick]
    for _, name in ipairs(Options(pick)) do
        if name == value then return value end
    end
end

for index, pick in ipairs(LESSONS) do
    args["lessons" .. index] = {
        type = "select", order = 12.75 + index / 100, width = 1.5, name = pick .. ": origin feat",
        desc = function()
            local lines = { "The origin feat this invocation gives you." }
            for _, name in ipairs(L.draft and Options(pick) or {}) do
                lines[#lines + 1] = ("|cffffd100%s|r: %s"):format(name, R.FEATS[name].desc)
            end
            return table.concat(lines, "\n\n")
        end,
        hidden = function() return not Picked(pick) end,
        values = function() return (ns.Opt.ListMap(Options(pick))) end,
        sorting = function() return (select(2, ns.Opt.ListMap(Options(pick)))) end,
        get = function() return L.draft and Chosen(pick) or nil end,
        set = function(_, value) L.draft.options[pick] = value end,
    }
end

-- Held until each is chosen.
local problem = L.Problem
function L.Problem()
    for _, pick in ipairs(LESSONS) do
        if Picked(pick) and not Chosen(pick) then return ("Choose the origin feat of %s."):format(pick) end
    end
    return problem()
end

-- Kept on the sheet when the dialog is confirmed, before the level's upkeep.
local confirm = args.confirm.func
args.confirm.func = function(...)
    local sheet = L.Sheet()
    for _, pick in ipairs(LESSONS) do
        if Picked(pick) then sheet.featureOptions[pick] = Chosen(pick) end
    end
    return confirm(...)
end
