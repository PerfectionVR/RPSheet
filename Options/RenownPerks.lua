-- The parts of a renown row on the "Origin" tab (Options/Origin.lua) that deal with a
-- faction's perks: what its trainers taught, and the perks reached and still to come.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet = Opt.Sheet

-- After a change to a renown score: perks the sheet grants follow it. The editor's
-- lists are only rebuilt when a tier was crossed, so dragging the slider stays smooth.
-- `before` is what Opt.RenownTiers() gave ahead of the change: one faction's score can
-- move another's (Sheet/RenownRules.lua), so every faction's tier is compared.
function Opt.RenownChanged(before)
    ns.ApplyClassFeatures(Sheet()) -- ends with the renown perks, and keeps score points right
    ns.NormalizeState(RPSheet:State())
    if before ~= Opt.RenownTiers() then ns.RebuildOptions() end
    Opt.Changed()
end

-- The tier of every faction as one text, to see whether a change crossed any.
function Opt.RenownTiers()
    local tiers = {}
    for _, faction in ipairs(R.ALL_FACTIONS) do
        tiers[#tiers + 1] = R.RenownTier((ns.RenownScore(Sheet(), faction)))
    end
    return table.concat(tiers, ",")
end

-- Says what a pick is, so "History" and "Smith's Tools" read apart in the dropdown.
local function Kind(name)
    if R.TOOLS[name] then return "tool" end
    for _, skill in ipairs(R.SKILLS) do
        if skill.name == name then return "skill" end
    end
    return "language"
end

local function TrainingValues(faction)
    local values, order = { [""] = "Not trained yet" }, { "" }
    for _, name in ipairs(ns.RenownTrainingOptions(Sheet(), faction)) do
        values[name] = ("%s (%s)"):format(name, Kind(name))
        order[#order + 1] = name
    end
    return values, order
end

-- Options to add to a faction's row, after its score and Remove button.
function Opt.RenownPerkArgs(faction)
    return {
        -- Only for a faction with lands a stronghold can stand in; one faction at a time.
        stronghold = {
            type = "toggle", order = 2.5, width = "full", name = "My stronghold stands in its lands (+1)",
            desc = ("While your stronghold is in %s, your renown with this faction counts as 1 higher. Ticking it here takes it off any other faction."):format(R.STRONGHOLD_LANDS[faction] or "its lands"),
            hidden = function() return not R.STRONGHOLD_LANDS[faction] end,
            get = function() return Sheet().stronghold == faction end,
            set = function(_, value)
                local before = Opt.RenownTiers()
                Sheet().stronghold = value and faction or ""
                Opt.RenownChanged(before)
            end,
        },
        training = {
            type = "select", order = 3, width = "double", name = "Taught by its trainers",
            desc = "Thirty days with the faction's trainers teaches you one of these. The sheet adds it while your renown is high enough: a language comes on top of the ones you choose, a tool or skill becomes proficient. More than one month of training? Tick the others by hand.",
            hidden = function() return #ns.RenownTrainingOptions(Sheet(), faction) == 0 end,
            values = function() return (TrainingValues(faction)) end,
            sorting = function() return (select(2, TrainingValues(faction))) end,
            get = function()
                local pick = Sheet().renownTraining[faction] or ""
                return TrainingValues(faction)[pick] and pick or ""
            end,
            set = function(_, value)
                Sheet().renownTraining[faction] = value ~= "" and value or nil
                ns.ApplyRenownTraining(Sheet())
                Opt.Changed()
            end,
        },
        perks = {
            type = "description", order = 4, width = "full",
            name = function() return ns.RenownSummary(Sheet(), faction, Opt.GOLD) .. "\n" end,
        },
    }
end
