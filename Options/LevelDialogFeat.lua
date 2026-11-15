-- The level dialog: the Ability Score Improvement, feat or Epic Boon of a level, and
-- the feat's own choices. The sliders for the points are in Options/LevelDialogPoints.lua.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local Levels = ns.Levels
local L = ns.LevelDialog
local args = L.args

function L.IsImprovement() return L.draft and L.draft.kind == "ASI" and L.draft.record.choice == "ASI" end
function L.IsFeat() return L.draft and L.draft.kind and L.draft.record.choice == "FEAT" end

-- The listed feat the draft names, or nil for one the player typed.
function L.KnownFeat()
    return L.draft and R.FEATS[L.draft.record.feat]
end

-- Abilities the chosen feat can raise by 1: its own list, or any for a typed feat.
function L.FeatStats()
    local feat = L.KnownFeat()
    local allowed = feat and feat.stats or R.STATS
    if L.draft and L.draft.kind ~= "BOON" and feat and feat.kind == "BOON" then allowed = {} end
    return allowed
end

-- The listed feats for this level, those the character can take first. Returns the
-- names in order and, for the ones it can't take, why not.
function L.FeatChoices()
    local open, closed, why = {}, {}, {}
    for _, name in ipairs(R.FEAT_NAMES[L.draft and L.draft.kind == "BOON" and "BOON" or "GENERAL"]) do
        local block = Levels.FeatBlock(L.Sheet(), L.draft and L.draft.level or 0, name)
        if block then
            closed[#closed + 1], why[name] = name, block
        else
            open[#open + 1] = name
        end
    end
    for _, name in ipairs(closed) do open[#open + 1] = name end
    return open, why
end

function L.Text(value, length)
    value = value:gsub("[|\r]", "")
    return value:trim():sub(1, length)
end

args.choiceHeader = {
    type = "header", order = 20,
    name = function() return L.draft and L.draft.kind == "BOON" and "Epic Boon" or "Ability Score Improvement or feat" end,
    hidden = function() return not L.draft or not L.draft.kind end,
}
args.choice = {
    type = "select", order = 21, name = "You take", width = "double",
    hidden = function() return not L.draft or L.draft.kind ~= "ASI" end,
    values = Levels.CHOICES, sorting = Levels.CHOICE_ORDER,
    get = function() return L.draft.record.choice end,
    set = function(_, value)
        L.draft.record.choice = value
        wipe(L.draft.record.asi)
    end,
}
args.choiceHelp = {
    type = "description", order = 22,
    hidden = function() return not L.draft or not L.draft.kind end,
    name = function()
        if L.IsImprovement() then
            return ("Place %d points: +2 to one ability, or +1 to two. A score can't go above %d.\n"):format(R.ASI_POINTS, R.MAX_SCORE)
        elseif L.draft and L.draft.kind == "BOON" then
            return ("Pick an Epic Boon. Each raises one ability by 1, up to %d. It is added as a passive.\n"):format(R.BOON_MAX_SCORE)
        end
        return "Pick a feat, or choose Other to type one that isn't listed. Most feats also raise one ability by 1. It is added as a passive; the ones that change numbers do so by themselves.\n"
    end,
}
args.featPick = {
    type = "select", order = 39, name = "Feat", width = "double",
    hidden = function() return not L.IsFeat() end,
    values = function()
        local values = { [""] = "Other (type a name)" }
        local names, why = L.FeatChoices()
        for _, name in ipairs(names) do
            values[name] = why[name] and ("|cff888888%s (%s)|r"):format(name, why[name]) or name
        end
        return values
    end,
    sorting = function()
        local order = L.FeatChoices()
        table.insert(order, 1, "")
        return order
    end,
    get = function() return L.KnownFeat() and L.draft.record.feat or "" end,
    set = function(_, value)
        local record, feat = L.draft.record, R.FEATS[value]
        record.feat = value
        record.featDesc = feat and feat.desc or ""
        -- Keep the +1 only if this feat can raise that ability.
        local keep
        for _, stat in ipairs(feat and feat.stats or R.STATS) do
            if (record.asi[stat] or 0) > 0 then keep = stat end
        end
        wipe(record.asi)
        if keep then record.asi[keep] = 1 end
    end,
}
args.feat = {
    type = "input", order = 40, name = "Name", width = "double",
    hidden = function() return not L.IsFeat() or L.KnownFeat() ~= nil end,
    get = function() return L.draft.record.feat end,
    set = function(_, value) L.draft.record.feat = L.Text((value:gsub("\n", " ")), 60) end,
}
args.featStat = {
    type = "select", order = 41, name = "Raises by 1",
    hidden = function() return not L.IsFeat() or #L.FeatStats() == 0 end,
    values = function()
        local values = { [""] = "None" }
        for _, stat in ipairs(L.FeatStats()) do values[stat] = R.STAT_NAMES[stat] end
        return values
    end,
    sorting = function()
        local order = { "" }
        for _, stat in ipairs(L.FeatStats()) do order[#order + 1] = stat end
        return order
    end,
    get = function()
        for _, stat in ipairs(R.STATS) do
            if (L.draft.record.asi[stat] or 0) > 0 then return stat end
        end
        return ""
    end,
    set = function(_, value)
        wipe(L.draft.record.asi)
        if value ~= "" then L.draft.record.asi[value] = 1 end
    end,
}
args.featDesc = {
    type = "input", order = 42, name = "What it does", width = "full", multiline = 3,
    hidden = function() return not L.IsFeat() end,
    get = function() return L.draft.record.featDesc end,
    set = function(_, value) L.draft.record.featDesc = L.Text(value, 400) end,
}

-- The choices inside feats, right under the feat this level takes.
args.featChoices = Opt.FeatChoiceGroup(43, L.FeatChoiceContext)
