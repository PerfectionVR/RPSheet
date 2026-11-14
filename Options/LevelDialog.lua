-- The level dialog: shows what a level gives and asks for the choices it comes with
-- (an Ability Score Improvement or a feat, an Epic Boon, a subclass).
-- It is used to take the next level, and to make or change the choice of a level
-- the character already has.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Levels = ns.Levels
local Util = ns.Util
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local DIALOG = ADDON .. "Level"

-- The level being decided, while the dialog is open:
--   level, taking (true when it is a new level), kind ("ASI", "BOON" or nil),
--   record (the choice so far), subclass (picked here), reopen (settings were open)
local draft

local function Sheet() return RPSheet:Sheet() end

local function AsksSubclass()
    local class = RPSheet:ClassData()
    return draft.level >= R.SUBCLASS_LEVEL and Sheet().subclass == "" and class and #class.subclasses > 0
end

local function Problem()
    return draft.kind and Levels.Problem(Sheet(), draft.level, draft.record)
end

-- Closes the dialog, then opens the dialog for `nextLevel` or goes back to the settings.
-- The window is closed a moment later: the options library redraws a window right
-- after one of its buttons was pressed, which would bring a closed one straight back.
local function Finish(nextLevel)
    local reopen = draft and draft.reopen
    draft = nil
    C_Timer.After(0, function()
        AceConfigDialog:Close(DIALOG)
        if nextLevel then
            ns.OpenLevelDialog(nextLevel, reopen)
        elseif reopen then
            AceConfigDialog:Open(ADDON)
        end
    end)
end

---------------------------------------------------------------------------
-- What the level gives
---------------------------------------------------------------------------
local function Gains()
    local sheet, class = Sheet(), RPSheet:ClassData()
    local level, lines = draft.level, {}
    if draft.taking then
        local die = class and class.hitDie or R.DEFAULT_HIT_DIE
        lines[#lines + 1] = ("Maximum HP %s%s|r, and one more d%d Hit Die."):format(
            Opt.GREEN, Util.Signed(die / 2 + 1 + RPSheet:Mod("CON")), die)
        local before, after = math.ceil((level - 1) / 4) + 1, math.ceil(level / 4) + 1
        if after ~= before then
            lines[#lines + 1] = ("Proficiency bonus %s+%d|r."):format(Opt.GREEN, after)
        end
    end
    local subclass = sheet.subclass ~= "" and sheet.subclass or draft.subclass
    local features = ns.FeaturesGainedAt(sheet.class, subclass, level)
    if draft.taking and #features > 0 then
        lines[#lines + 1] = ""
        for _, feature in ipairs(features) do
            lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, feature.name, feature.desc)
        end
    end
    if draft.taking and class and class.cast then
        lines[#lines + 1] = "\nSpell slots and class resources that grow are listed in chat when you take the level."
    end
    return table.concat(lines, "\n") .. "\n"
end

---------------------------------------------------------------------------
-- Options
---------------------------------------------------------------------------
local function IsImprovement() return draft and draft.kind == "ASI" and draft.record.choice == "ASI" end
local function IsFeat() return draft and draft.kind and draft.record.choice == "FEAT" end

-- The listed feat the draft names, or nil for one the player typed.
local function KnownFeat()
    return draft and R.FEATS[draft.record.feat]
end

-- Abilities the chosen feat can raise by 1: its own list, or any for a typed feat.
local function FeatStats()
    local feat = KnownFeat()
    local allowed = feat and feat.stats or R.STATS
    if draft and draft.kind ~= "BOON" and feat and feat.kind == "BOON" then allowed = {} end
    return allowed
end

local function Text(value, length)
    value = value:gsub("[|\r]", "")
    return value:trim():sub(1, length)
end

local args = {
    title = {
        type = "description", order = 1, fontSize = "large",
        name = function()
            if not draft then return "" end
            local text = draft.taking and ("Level %d to %d"):format(draft.level - 1, draft.level)
                or ("Your choice for level %d"):format(draft.level)
            return Opt.GOLD .. text .. "|r\n"
        end,
    },
    gains = {
        type = "description", order = 2, fontSize = "medium",
        name = function() return draft and Gains() or "" end,
    },

    subclass = {
        type = "select", order = 10, name = "Subclass", width = "double",
        desc = "Its features are added to the sheet. A subclass that isn't listed can be typed under Customize afterwards.",
        hidden = function() return not draft or not AsksSubclass() end,
        values = function()
            local class = RPSheet:ClassData()
            return (Opt.ListMap(class and class.subclasses, true))
        end,
        sorting = function()
            local class = RPSheet:ClassData()
            return (select(2, Opt.ListMap(class and class.subclasses, true)))
        end,
        get = function() return draft.subclass end,
        set = function(_, value) draft.subclass = value end,
    },

    choiceHeader = {
        type = "header", order = 20,
        name = function() return draft and draft.kind == "BOON" and "Epic Boon" or "Ability Score Improvement or feat" end,
        hidden = function() return not draft or not draft.kind end,
    },
    choice = {
        type = "select", order = 21, name = "You take", width = "double",
        hidden = function() return not draft or draft.kind ~= "ASI" end,
        values = Levels.CHOICES, sorting = Levels.CHOICE_ORDER,
        get = function() return draft.record.choice end,
        set = function(_, value)
            draft.record.choice = value
            wipe(draft.record.asi)
        end,
    },
    choiceHelp = {
        type = "description", order = 22,
        hidden = function() return not draft or not draft.kind end,
        name = function()
            if IsImprovement() then
                return ("Place %d points: +2 to one ability, or +1 to two. A score can't go above %d.\n"):format(R.ASI_POINTS, R.MAX_SCORE)
            elseif draft and draft.kind == "BOON" then
                return ("Pick an Epic Boon. Each raises one ability by 1, up to %d. It is added as a passive.\n"):format(R.BOON_MAX_SCORE)
            end
            return "Pick a feat, or choose Other to type one that isn't listed. Most feats also raise one ability by 1. It is added as a passive; the ones that change numbers do so by themselves.\n"
        end,
    },
    featPick = {
        type = "select", order = 39, name = "Feat", width = "double",
        hidden = function() return not IsFeat() end,
        values = function()
            local values = { [""] = "Other (type a name)" }
            for _, name in ipairs(R.FEAT_NAMES[draft and draft.kind == "BOON" and "BOON" or "GENERAL"]) do values[name] = name end
            return values
        end,
        sorting = function()
            local order = {}
            for _, name in ipairs(R.FEAT_NAMES[draft and draft.kind == "BOON" and "BOON" or "GENERAL"]) do order[#order + 1] = name end
            order[#order + 1] = ""
            return order
        end,
        get = function() return KnownFeat() and draft.record.feat or "" end,
        set = function(_, value)
            local record, feat = draft.record, R.FEATS[value]
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
    },
    feat = {
        type = "input", order = 40, name = "Name", width = "double",
        hidden = function() return not IsFeat() or KnownFeat() ~= nil end,
        get = function() return draft.record.feat end,
        set = function(_, value) draft.record.feat = Text((value:gsub("\n", " ")), 60) end,
    },
    featStat = {
        type = "select", order = 41, name = "Raises by 1",
        hidden = function() return not IsFeat() or #FeatStats() == 0 end,
        values = function()
            local values = { [""] = "None" }
            for _, stat in ipairs(FeatStats()) do values[stat] = R.STAT_NAMES[stat] end
            return values
        end,
        sorting = function()
            local order = { "" }
            for _, stat in ipairs(FeatStats()) do order[#order + 1] = stat end
            return order
        end,
        get = function()
            for _, stat in ipairs(R.STATS) do
                if (draft.record.asi[stat] or 0) > 0 then return stat end
            end
            return ""
        end,
        set = function(_, value)
            wipe(draft.record.asi)
            if value ~= "" then draft.record.asi[value] = 1 end
        end,
    },
    featDesc = {
        type = "input", order = 42, name = "What it does", width = "full", multiline = 3,
        hidden = function() return not IsFeat() end,
        get = function() return draft.record.featDesc end,
        set = function(_, value) draft.record.featDesc = Text(value, 400) end,
    },

    problem = {
        type = "description", order = 90, fontSize = "medium",
        name = function()
            local problem = draft and Problem()
            return problem and (Opt.RED .. problem .. "|r\n") or "\n"
        end,
    },
    confirm = {
        type = "execute", order = 91,
        name = function() return draft and draft.taking and ("Take level " .. draft.level) or "Save choice" end,
        disabled = function() return not draft or Problem() ~= nil end,
        func = function()
            local sheet, level, taking = Sheet(), draft.level, draft.taking
            if AsksSubclass() and draft.subclass ~= "" then sheet.subclass = draft.subclass end
            if draft.kind then Levels.Set(sheet, level, draft.record) end
            if taking then
                RPSheet:SetLevel(level)
            else
                ns.ApplyGrants(sheet)
                ns.NormalizeState(RPSheet:State())
            end
            ns.RebuildOptions()
            Opt.Changed()
            -- Earlier levels with an open choice are asked for next.
            Finish(not taking and Levels.Pending(sheet)[1] or nil)
        end,
    },
    cancel = {
        type = "execute", order = 92, name = "Cancel",
        func = function() Finish() end,
    },
}

-- Two points to place: a slider per ability.
for index, stat in ipairs(R.STATS) do
    args["asi" .. stat] = Opt.Bounded({
        type = "range", order = 30 + index, min = 0, max = R.ASI_POINTS, step = 1,
        name = function()
            return ("%s (%d)"):format(R.STAT_NAMES[stat], RPSheet:Score(stat))
        end,
        desc = ns.Glossary[stat],
        hidden = function() return not IsImprovement() end,
        get = function() return draft and draft.record.asi[stat] or 0 end,
        set = function(_, value) draft.record.asi[stat] = value > 0 and value or nil end,
    }, function()
        if not draft then return 0, R.ASI_POINTS end
        -- The points still to place, and no further than the highest score allowed.
        local sheet, mine, placed = Sheet(), draft.record.asi[stat] or 0, 0
        for _, other in ipairs(R.STATS) do placed = placed + (draft.record.asi[other] or 0) end
        local saved = Levels.Record(sheet, draft.level)
        local counted = saved and draft.level <= sheet.level and saved.asi[stat] or 0
        local room = R.MAX_SCORE - (RPSheet:Score(stat) - counted)
        return 0, math.max(0, math.min(R.ASI_POINTS, mine + R.ASI_POINTS - placed, room))
    end)
end

ns.SnapSliders({ args = args })

LibStub("AceConfig-3.0"):RegisterOptionsTable(DIALOG, {
    type = "group",
    name = "RP Sheet - Level",
    args = args,
})
AceConfigDialog:SetDefaultSize(DIALOG, 620, 560)

-- Opens the dialog for `level`: the next level to take it, or a level the character
-- has to make or change its choice. `reopen` brings the settings back afterwards.
function ns.OpenLevelDialog(level, reopen)
    local sheet = Sheet()
    level = level or sheet.level + 1
    if level > R.MAX_LEVEL then return end
    if reopen == nil then reopen = AceConfigDialog.OpenFrames[ADDON] ~= nil end
    local kind = Levels.Kind(sheet, level)
    local record = Levels.Record(sheet, level)
    draft = {
        level = level, taking = level > sheet.level, kind = kind, subclass = "", reopen = reopen,
        record = record and CopyTable(record) or Levels.NewRecord(kind),
    }
    if kind == "BOON" then draft.record.choice = "FEAT" end
    -- One window at a time: the settings window would sit underneath and show through.
    -- A moment later, for the reason given at Finish.
    C_Timer.After(0, function()
        if not draft then return end
        AceConfigDialog:Close(ADDON)
        AceConfigDialog:Open(DIALOG)
    end)
end
