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

-- The Fighting Style slot (1 or 2) this level opens, or nil.
local function StyleSlot()
    if not draft or not draft.taking then return end
    local sheet = Sheet()
    local subclass = sheet.subclass ~= "" and sheet.subclass or draft.subclass
    for _, feature in ipairs(ns.FeaturesGainedAt(sheet.class, subclass, draft.level)) do
        for slot, name in ipairs(ns.STYLE_FEATURES) do
            if feature.name == name then return slot end
        end
    end
end

-- The subclass the character will have once this dialog is confirmed.
local function SubclassAfter()
    local sheet = Sheet()
    return sheet.subclass ~= "" and sheet.subclass or draft.subclass
end

-- The level the class's own choices are for: the one being taken, or the level the
-- character has when an earlier level's choice is looked at again.
local function ChoiceLevel()
    return draft.taking and draft.level or Sheet().level
end

-- How many maneuvers the character should know at that level.
local function ManeuverLimit()
    if not draft then return 0 end
    return ns.ManeuverLimit(SubclassAfter(), ChoiceLevel())
end

local function ManeuversPicked()
    local count = 0
    for _ in pairs(draft.maneuvers) do count = count + 1 end
    return count
end

-- Features with a skill to pick, as the character will be after this dialog.
local function SkillFeatures()
    if not draft then return {} end
    local sheet = Sheet()
    return ns.SkillChoiceFeatures({ class = sheet.class, subclass = SubclassAfter(), level = ChoiceLevel() })
end

-- Features with options to pick in this dialog: the ones still open when taking a
-- level, all of them when looking at the choices again.
local function OptionFeatures()
    if not draft then return {} end
    local sheet = Sheet()
    local like = setmetatable({ subclass = SubclassAfter(), level = ChoiceLevel() }, { __index = sheet })
    return draft.taking and ns.OpenOptionFeatures(like) or ns.OptionFeatures(like)
end

-- How many options of a pick list (Metamagic, Invocations) the character should know.
local function PickLimit(key)
    if not draft then return 0 end
    return ns.PickLimit(key, Sheet().class, ChoiceLevel())
end

local function PicksChosen(key)
    local count = 0
    for _ in pairs(draft.picks[key]) do count = count + 1 end
    return count
end

-- How many skills to pick expertise in, and the set to pick from (nil = any).
local function ExpertiseLimit()
    if not draft then return 0 end
    local sheet = Sheet()
    return ns.ExpertiseLimit({ class = sheet.class, subclass = SubclassAfter(), level = ChoiceLevel(), passives = sheet.passives })
end

-- Skills to choose for the feats on the sheet (Skilled, Skill Expert).
local function FeatSkillLimit()
    return draft and ns.FeatSkillLimit(Sheet()) or 0
end

local function FeatSkillsPicked()
    local count = 0
    for _ in pairs(draft.featSkills) do count = count + 1 end
    return count
end

local function ExpertisePicked()
    local count = 0
    for _ in pairs(draft.expertise) do count = count + 1 end
    return count
end

local function Problem()
    local featSkills = FeatSkillLimit()
    if featSkills > 0 and FeatSkillsPicked() ~= featSkills then
        return ("Choose %d skills for your feats (%d chosen)."):format(featSkills, FeatSkillsPicked())
    end
    local expertise = ExpertiseLimit()
    if expertise > 0 and ExpertisePicked() ~= expertise then
        return ("Choose %d skills for expertise (%d chosen)."):format(expertise, ExpertisePicked())
    end
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local limit = PickLimit(key)
        if limit > 0 and PicksChosen(key) ~= limit then
            return ("Choose %d %s (%d chosen)."):format(limit, R.PICK_LISTS[key].title, PicksChosen(key))
        end
    end
    for _, feature in ipairs(OptionFeatures()) do
        if (draft.options[feature.name] or "") == "" then return ("Choose an option for %s."):format(feature.name) end
    end
    local limit = ManeuverLimit()
    if limit > 0 and ManeuversPicked() ~= limit then
        return ("Choose %d maneuvers (%d chosen)."):format(limit, ManeuversPicked())
    end
    for _, feature in ipairs(SkillFeatures()) do
        if (draft.featureSkills[feature] or "") == "" then return ("Choose a skill for %s."):format(feature) end
    end
    if AsksSubclass() and draft.taking and draft.subclass == "" then return "Choose a subclass: it is part of this level." end
    if StyleSlot() and draft.style == "" then return "Choose a Fighting Style: it is part of this level." end
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
            -- Some descriptions follow the level.
            local desc = feature.desc
            if type(desc) == "function" then desc = desc(level, setmetatable({ level = level }, { __index = sheet })) end
            lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, feature.name, desc)
        end
    end
    -- What the specialization suggests for this level.
    local suggestions = R.SpecSuggestions(sheet.class, sheet.spec, level)
    if #suggestions > 0 then
        lines[#lines + 1] = ("\n%sSuggested for %s|r: %s"):format(Opt.GOLD, sheet.spec, table.concat(suggestions, " "))
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

-- The listed feats for this level, those the character can take first. Returns the
-- names in order and, for the ones it can't take, why not.
local function FeatChoices()
    local open, closed, why = {}, {}, {}
    for _, name in ipairs(R.FEAT_NAMES[draft and draft.kind == "BOON" and "BOON" or "GENERAL"]) do
        local block = Levels.FeatBlock(Sheet(), draft and draft.level or 0, name)
        if block then
            closed[#closed + 1], why[name] = name, block
        else
            open[#open + 1] = name
        end
    end
    for _, name in ipairs(closed) do open[#open + 1] = name end
    return open, why
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

    style = {
        type = "select", order = 11, name = "Fighting Style", width = "double",
        desc = function()
            local lines = {}
            for _, style in ipairs(R.FIGHTING_STYLE_ORDER) do
                lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, style, R.FIGHTING_STYLES[style].desc)
            end
            return table.concat(lines, "\n\n")
        end,
        hidden = function() return not StyleSlot() end,
        values = function() return (Opt.ListMap(ns.StyleChoices(Sheet(), StyleSlot() or 1), true)) end,
        sorting = function() return (select(2, Opt.ListMap(ns.StyleChoices(Sheet(), StyleSlot() or 1), true))) end,
        get = function() return draft.style end,
        set = function(_, value) draft.style = value end,
    },

    maneuvers = {
        type = "group", inline = true, order = 12, args = {},
        name = function() return ("Maneuvers (%d of %d chosen)"):format(draft and ManeuversPicked() or 0, ManeuverLimit()) end,
        hidden = function() return ManeuverLimit() == 0 end,
    },
    featureSkill = {
        type = "select", order = 13, width = "double",
        name = function() return (SkillFeatures()[1] or "Feature") .. " (skill)" end,
        desc = "A skill from your class's list that you aren't proficient in yet.",
        hidden = function() return #SkillFeatures() == 0 end,
        values = function()
            local sheet = Sheet()
            local like = setmetatable({ subclass = SubclassAfter(), level = ChoiceLevel(), featureSkills = draft.featureSkills }, { __index = sheet })
            return (Opt.ListMap(ns.FeatureSkillOptions(like, SkillFeatures()[1])))
        end,
        get = function() return draft.featureSkills[SkillFeatures()[1]] end,
        set = function(_, value) draft.featureSkills[SkillFeatures()[1]] = value end,
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
            local names, why = FeatChoices()
            for _, name in ipairs(names) do
                values[name] = why[name] and ("|cff888888%s (%s)|r"):format(name, why[name]) or name
            end
            return values
        end,
        sorting = function()
            local order = FeatChoices()
            table.insert(order, 1, "")
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
            local slot = StyleSlot()
            if slot and draft.style ~= "" then sheet[ns.STYLE_FIELDS[slot]] = draft.style end
            if draft.kind then Levels.Set(sheet, level, draft.record) end
            for _, feature in ipairs(OptionFeatures()) do sheet.featureOptions[feature.name] = draft.options[feature.name] end
            for _, key in ipairs(R.PICK_LIST_ORDER) do
                if PickLimit(key) > 0 then sheet.picks[key] = CopyTable(draft.picks[key]) end
            end
            if ManeuverLimit() > 0 then sheet.maneuvers = CopyTable(draft.maneuvers) end
            if ExpertiseLimit() > 0 then sheet.expertise = CopyTable(draft.expertise) end
            if FeatSkillLimit() > 0 then sheet.featSkills = CopyTable(draft.featSkills) end
            for _, feature in ipairs(SkillFeatures()) do sheet.featureSkills[feature] = draft.featureSkills[feature] end
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

-- One checkbox per maneuver. Once the number for the level is chosen the rest grey
-- out; a known one can be unticked to swap it for another.
for index, name in ipairs(R.MANEUVER_ORDER) do
    args.maneuvers.args["maneuver" .. index] = {
        type = "toggle", order = index, width = 1.5, name = name,
        desc = function()
            local maneuver = R.MANEUVERS[name]
            return maneuver.desc .. (maneuver.save and (" " .. R.STAT_NAMES[maneuver.save] .. " save.") or "")
        end,
        disabled = function() return not draft.maneuvers[name] and ManeuversPicked() >= ManeuverLimit() end,
        get = function() return draft.maneuvers[name] or false end,
        set = function(_, value) draft.maneuvers[name] = value or nil end,
    }
end

-- Skills from feats: one checkbox per skill the character isn't proficient in yet.
args.featSkills = {
    type = "group", inline = true, order = 13.4, args = {},
    name = function() return ("Skills from your feats (%d of %d chosen)"):format(draft and FeatSkillsPicked() or 0, FeatSkillLimit()) end,
    hidden = function() return FeatSkillLimit() == 0 end,
}
for index, skill in ipairs(R.SKILLS) do
    local name = skill.name
    args.featSkills.args["skill" .. index] = {
        type = "toggle", order = index, width = 1, name = name,
        desc = "Proficiency in this skill, from a feat such as Skilled or Skill Expert.",
        hidden = function()
            local sheet = Sheet()
            -- Shown when picked, or when the skill isn't proficient from somewhere else.
            return not draft.featSkills[name] and (sheet.skills[name] or 0) > 0 and not sheet.featSkillGranted[name]
        end,
        disabled = function() return not draft.featSkills[name] and FeatSkillsPicked() >= FeatSkillLimit() end,
        get = function() return draft.featSkills[name] or false end,
        set = function(_, value) draft.featSkills[name] = value or nil end,
    }
end

-- Expertise: one checkbox per skill the character is proficient in.
args.expertise = {
    type = "group", inline = true, order = 13.5, args = {},
    name = function() return ("Expertise (%d of %d chosen)"):format(draft and ExpertisePicked() or 0, (ExpertiseLimit())) end,
    hidden = function() return ExpertiseLimit() == 0 end,
}
for index, skill in ipairs(R.SKILLS) do
    local name = skill.name
    args.expertise.args["skill" .. index] = {
        type = "toggle", order = index, width = 1, name = name,
        desc = "Your proficiency bonus is added twice for this skill. Only skills you are proficient in can be picked.",
        hidden = function()
            local _, allowed = ExpertiseLimit()
            return (allowed ~= nil and not allowed[name]) or (not draft.expertise[name] and (Sheet().skills[name] or 0) == 0)
        end,
        disabled = function() return not draft.expertise[name] and ExpertisePicked() >= ExpertiseLimit() end,
        get = function() return draft.expertise[name] or false end,
        set = function(_, value) draft.expertise[name] = value or nil end,
    }
end

-- A group of checkboxes per pick list. An option greys out at the limit, below its
-- level, or without the pick it builds on.
for listIndex, key in ipairs(R.PICK_LIST_ORDER) do
    local list = R.PICK_LISTS[key]
    local group = {
        type = "group", inline = true, order = 12.5 + listIndex / 10, args = {},
        name = function() return ("%s (%d of %d chosen)"):format(list.title, draft and PicksChosen(key) or 0, PickLimit(key)) end,
        hidden = function() return PickLimit(key) == 0 end,
    }
    for index, name in ipairs(list.order) do
        group.args["pick" .. index] = {
            type = "toggle", order = index, width = 1.5,
            name = function()
                local blocked = draft and not draft.picks[key][name] and ns.PickBlocked(key, name, ChoiceLevel(), draft.picks[key], SubclassAfter())
                return blocked and ("|cff888888%s (%s)|r"):format(name, blocked) or name
            end,
            desc = list.items[name].desc,
            disabled = function()
                if draft.picks[key][name] then return false end
                return PicksChosen(key) >= PickLimit(key) or ns.PickBlocked(key, name, ChoiceLevel(), draft.picks[key], SubclassAfter()) ~= nil
            end,
            get = function() return draft.picks[key][name] or false end,
            set = function(_, value) draft.picks[key][name] = value or nil end,
        }
    end
    args["picks" .. key] = group
end

-- A dropdown for each feature that offers options (four at most at one level).
for index = 1, 4 do
    local function Feature() return OptionFeatures()[index] end
    args["option" .. index] = {
        type = "select", order = 11 + index / 10, width = "double",
        name = function() return Feature() and Feature().name or "" end,
        desc = function()
            local feature, lines = Feature(), {}
            -- A long list (pet families) shows only the one picked.
            local options = feature and feature.options or {}
            local picked = feature and draft and draft.options[feature.name]
            for _, option in ipairs(options) do
                if #options <= 8 or option.name == picked then
                    local desc = option.desc
                    if type(desc) == "function" then desc = desc(Sheet().level, Sheet()) end -- some follow the level
                    lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, option.name, desc)
                end
            end
            if #lines == 0 then return "Pick one to read what it gives." end
            return table.concat(lines, "\n\n")
        end,
        hidden = function() return Feature() == nil end,
        values = function()
            local values = {}
            for _, option in ipairs(Feature() and Feature().options or {}) do values[option.name] = option.name end
            return values
        end,
        get = function() return Feature() and draft.options[Feature().name] end,
        set = function(_, value) draft.options[Feature().name] = value end,
    }
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
        level = level, taking = level > sheet.level, kind = kind, subclass = "", style = "", reopen = reopen,
        maneuvers = CopyTable(sheet.maneuvers), featureSkills = CopyTable(sheet.featureSkills),
        options = CopyTable(sheet.featureOptions), picks = CopyTable(sheet.picks), expertise = CopyTable(sheet.expertise), featSkills = CopyTable(sheet.featSkills),
        record = record and CopyTable(record) or Levels.NewRecord(kind),
    }
    for _, key in ipairs(R.PICK_LIST_ORDER) do draft.picks[key] = draft.picks[key] or {} end
    if kind == "BOON" then draft.record.choice = "FEAT" end
    -- The specialization's suggestions are pre-selected; the player can pick otherwise.
    local guide = R.SpecGuide(sheet.class, sheet.spec)
    if guide then
        if guide.subclass and AsksSubclass() then draft.subclass = guide.subclass end
        local slot = StyleSlot()
        if guide.style and slot then
            for _, name in ipairs(ns.StyleChoices(sheet, slot)) do
                if name == guide.style then draft.style = name end
            end
        end
    end
    -- One window at a time: the settings window would sit underneath and show through.
    -- A moment later, for the reason given at Finish.
    C_Timer.After(0, function()
        if not draft then return end
        AceConfigDialog:Close(ADDON)
        AceConfigDialog:Open(DIALOG)
    end)
end
