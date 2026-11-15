-- "Defense" tab: the damage types of a passive that lets you choose them (Heavenly
-- Spirit; see Sheet/DefensePicks.lua). Switching the passive on from the sheet asks
-- the same and keeps to the count; this page is free and only warns.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local Sheet = Opt.Sheet

local function Has(name)
    for _, passive in ipairs(Sheet().passives) do
        if passive.name == name then return true end
    end
    return false
end

local order = 20
for name, rule in pairs(R.DEFENSE_PICKS) do
    order = order + 1
    local values = {}
    for _, each in ipairs(rule.from) do values[each] = each:sub(1, 1):upper() .. each:sub(2) end
    Opt.custom.defense.args["picks" .. order] = {
        type = "multiselect", order = order, name = name .. ": damage you resist",
        desc = ("Choose %d. They count while %s is switched on."):format(rule.count, name),
        hidden = function() return not Has(name) end,
        values = values,
        get = function(_, key)
            for _, each in ipairs(ns.DefensePicks(Sheet(), name)) do
                if each == key then return true end
            end
            return false
        end,
        set = function(_, key, value)
            local sheet, list = Sheet(), {}
            for _, each in ipairs(ns.DefensePicks(sheet, name)) do
                if each ~= key then list[#list + 1] = each end
            end
            if value then list[#list + 1] = key end
            if type(sheet.defensePicks) ~= "table" then sheet.defensePicks = {} end
            sheet.defensePicks[name] = list
            Opt.Changed()
        end,
    }
    Opt.custom.defense.args["picksNote" .. order] = {
        type = "description", order = order + 0.5,
        hidden = function() return not Has(name) or #ns.DefensePicks(Sheet(), name) == rule.count end,
        name = function()
            return ("%s%s lets you resist %d of these, and %d are chosen.|r\n"):format(Opt.RED, name, rule.count, #ns.DefensePicks(Sheet(), name))
        end,
    }
end
