-- The level dialog asks for the ability a species' or lineage's spells are cast with
-- (Sheet/LineageCasting.lua) while a character made before it was asked has none: it
-- is part of the lineage, chosen once. This file adds the dropdown to the dialog and
-- holds the dialog until it is chosen; it loads after the dialog's other parts and
-- before Options/LevelDialog.lua registers them.
local _, ns = ...
local R = ns.Rules
local L = ns.LevelDialog
local args = L.args

local function Asked()
    return L.draft ~= nil and ns.LineageStatMissing(L.Sheet())
end

args.lineageStat = {
    type = "select", order = 13.2, width = 1.5,
    name = function()
        local sheet = L.Sheet()
        return ns.LineageCasts(sheet.species, sheet.lineage) and "Ability for your lineage's spells" or "Ability for your lineage's save DC"
    end,
    desc = function()
        local sheet = L.Sheet()
        if not ns.LineageCasts(sheet.species, sheet.lineage) then
            return ("Your lineage forces saving throws. Choose the ability its DC uses: %s. It is part of your lineage and stays."):format(ns.LineageStatWords(sheet.species, sheet.lineage))
        end
        return ("%s gives you spells. Choose the ability you cast them with: Intelligence, Wisdom or Charisma. It is part of your lineage and stays."):format(ns.LineageTrait(sheet.species))
    end,
    hidden = function() return not Asked() end,
    values = function() return ns.LineageStatValues(L.Sheet().species, L.Sheet().lineage) end,
    sorting = function() return ns.LineageStats(L.Sheet().species, L.Sheet().lineage) end,
    get = function() return L.draft and L.draft.lineageStat or "" end,
    set = function(_, value) L.draft.lineageStat = value end,
}

-- Held until it is chosen.
local problem = L.Problem
function L.Problem()
    if Asked() and (L.draft.lineageStat or "") == "" then
        local sheet = L.Sheet()
        if not ns.LineageCasts(sheet.species, sheet.lineage) then return "Choose the ability your lineage's save DC uses." end
        return "Choose the ability your lineage's spells are cast with."
    end
    return problem()
end

-- Kept on the sheet when the dialog is confirmed, before the level's upkeep.
local confirm = args.confirm.func
args.confirm.func = function(...)
    if Asked() and (L.draft.lineageStat or "") ~= "" then L.Sheet().lineageStat = L.draft.lineageStat end
    return confirm(...)
end
