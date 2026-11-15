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
--   level (the number of the level its choice is kept under, Sheet/ClassSlots.lua),
--   class (the class the level belongs to), classLevel (its level in that class),
--   taking (true when it is a new level), newClass (the first level in that class),
--   kind ("ASI", "BOON" or nil), record (the choice so far), subclass and skill
--   (picked here), reopen (settings were open)
local draft

local function Sheet() return RPSheet:Sheet() end

local function DraftClass()
    return draft and R.CLASSES[draft.class]
end

local function AsksSubclass()
    local class = DraftClass()
    return draft.classLevel >= R.SUBCLASS_LEVEL and ns.ClassSubclass(Sheet(), draft.class) == "" and class and #class.subclasses > 0
end

-- The subclass the dialog's class will have once this dialog is confirmed.
local function SubclassAfter()
    local current = ns.ClassSubclass(Sheet(), draft.class)
    return current ~= "" and current or draft.subclass
end

-- The Fighting Style slot (1 or 2) this level opens, or nil.
local function StyleSlot()
    if not draft or not draft.taking then return end
    for _, feature in ipairs(ns.FeaturesGainedAt(draft.class, SubclassAfter(), draft.classLevel)) do
        for slot, name in ipairs(ns.STYLE_FEATURES) do
            if feature.name == name then return slot end
        end
    end
end

-- The whole character as this dialog would leave it: the level being taken counted
-- in, in its class, and the subclass picked here. When an earlier level's choice is
-- looked at again it is the character as it is. The classes' own choices are asked for
-- this character, each class by its own level (Sheet/ClassViews.lua).
local function Like()
    local subclass = SubclassAfter()
    if not draft.like or draft.likeSubclass ~= subclass then
        local sheet = Sheet()
        local level = draft.taking and draft.classLevel or ns.ClassLevel(sheet, draft.class)
        draft.like, draft.likeSubclass = ns.SheetWith(sheet, draft.class, level, subclass), subclass
    end
    return draft.like
end

-- Skills the first level of a class taken after the first lets the character pick from.
local function NewClassSkills()
    if not draft or not draft.newClass then return {} end
    return ns.MulticlassSkills(Sheet(), draft.class, draft.skill)
end

-- How many maneuvers the character should know at that level.
local function ManeuverLimit()
    if not draft then return 0 end
    return ns.SheetManeuverLimit(Like())
end

local function ManeuversPicked()
    local count = 0
    for _ in pairs(draft.maneuvers) do count = count + 1 end
    return count
end

-- Features with a skill to pick, as the character will be after this dialog.
local function SkillFeatures()
    if not draft then return {} end
    return ns.SkillChoiceFeatures(Like())
end

-- Features with options to pick in this dialog: the ones still open when taking a
-- level, all of them when looking at the choices again.
local function OptionFeatures()
    if not draft then return {} end
    local like = Like()
    return draft.taking and ns.OpenOptionFeatures(like) or ns.OptionFeatures(like)
end

-- How many options of a pick list (Metamagic, Invocations) the character should know.
local function PickLimit(key)
    if not draft then return 0 end
    return ns.SheetPickLimit(Like(), key)
end

local function PicksChosen(key)
    local count = 0
    for _ in pairs(draft.picks[key]) do count = count + 1 end
    return count
end

-- The character as this dialog would leave it, for a list whose options depend on
-- other picks made here (spells that have to be in the spellbook).
local function Picking()
    return setmetatable({ picks = draft.picks }, { __index = Like() })
end

-- Why an option of a list can't be picked right now, or nil. The level and subclass
-- that count are those of the class the list belongs to.
local function Blocked(key, name)
    local view = ns.ListView(Picking(), key)
    return ns.PickBlocked(key, name, view.level, draft.picks[key], view.subclass, view)
end

-- True if a pick made at an earlier level has to stay: only so many may be exchanged
-- when a level is gained (Sheet/PickSwaps.lua). Looking at the choices again is free.
local function SwapLocked(key, name)
    return ns.PickSwapLocked(key, name, draft.before, draft.picks, Picking())
end

-- A list that follows another (list.follows) loses the picks that list no longer
-- allows: a mastered spell that was taken out of the spellbook is open again.
local function DropUnfollowed()
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local list = R.PICK_LISTS[key]
        if list.follows and list.blocked and PickLimit(key) > 0 then
            local like = ns.ListView(Picking(), key)
            for name in pairs(draft.picks[key]) do
                if not list.items[name] or list.blocked(like, name) then draft.picks[key][name] = nil end
            end
        end
    end
end

-- How many skills to pick expertise in, and the set to pick from (nil = any).
local function ExpertiseLimit()
    if not draft then return 0 end
    return ns.ExpertiseLimit(Like())
end

-- Skills to choose for the feats on the sheet (Skilled, Skill Expert).
local function FeatSkillLimit()
    return draft and ns.FeatSkillLimit(Sheet()) or 0
end

-- Tools picked in place of skills (Skilled), out of the same picks.
local function FeatToolsPicked()
    local count = 0
    for _ in pairs(draft.featTools) do count = count + 1 end
    return count
end

local function FeatSkillsPicked()
    local count = FeatToolsPicked()
    for _ in pairs(draft.featSkills) do count = count + 1 end
    return count
end

-- The feats whose own choices are asked for here (a damage type, spells, tools):
-- those on the sheet, with this level's feat as it is being decided. Returns what
-- ns.FeatChoiceProgress and Opt.FeatChoiceGroup need.
local function FeatChoiceContext()
    if not draft then return end
    local sheet, override = Sheet(), nil
    if draft.kind then
        override = { id = "level:" .. draft.level, name = draft.record.choice == "FEAT" and draft.record.feat or "" }
    end
    local instances = ns.FeatInstances(sheet, override)
    -- Picks for a feat that was swapped out here, or that no longer fit, are dropped.
    ns.NormalizeFeatChoices(draft.featChoices, instances, Like().level)
    return sheet, draft.featChoices, instances, Like().level
end

local function ExpertisePicked()
    local count = 0
    for _ in pairs(draft.expertise) do count = count + 1 end
    return count
end

local function Problem()
    -- A class the character doesn't have yet has to be open to it.
    local block = draft.newClass and ns.MulticlassBlock(Sheet(), draft.class)
    if block then return ("You can't take a level of %s: %s."):format(DraftClass().name, block) end
    if #NewClassSkills() > 0 and draft.skill == "" then return "Choose the skill your new class gives you." end
    local featSkills = FeatSkillLimit()
    if featSkills > 0 and FeatSkillsPicked() ~= featSkills then
        return ("Choose %d skills or tools for your feats (%d chosen)."):format(featSkills, FeatSkillsPicked())
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
    local problem = draft.kind and Levels.Problem(Sheet(), draft.level, draft.record)
    if problem then return problem end
    -- Last: the feat has to be settled before its own choices are.
    local _, store, instances, level = FeatChoiceContext()
    return (select(3, ns.FeatChoiceProgress(store, instances, level)))
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
    local sheet, class = Sheet(), DraftClass()
    -- The class's features come at its own level; the proficiency bonus follows the
    -- whole character's.
    local level, total, lines = draft.classLevel, Like().level, {}
    if draft.taking then
        local die = class and class.hitDie or R.DEFAULT_HIT_DIE
        lines[#lines + 1] = ("Maximum HP %s%s|r, and one more d%d Hit Die."):format(
            Opt.GREEN, Util.Signed(die / 2 + 1 + RPSheet:OwnMod("CON")), die)
        local before, after = math.ceil((total - 1) / 4) + 1, math.ceil(total / 4) + 1
        if after ~= before then
            lines[#lines + 1] = ("Proficiency bonus %s+%d|r."):format(Opt.GREEN, after)
        end
        if draft.newClass then
            lines[#lines + 1] = ("A class taken after your first gives less than it does at the start: %s. It gives no saving throw proficiencies."):format(
                ns.MulticlassGains(draft.class))
        end
    end
    local subclass = SubclassAfter()
    local features = ns.FeaturesGainedAt(draft.class, subclass, level)
    if draft.taking and #features > 0 then
        lines[#lines + 1] = ""
        for _, feature in ipairs(features) do
            -- Some descriptions follow the level.
            local desc = feature.desc
            if type(desc) == "function" then desc = desc(level, ns.ClassView(Like(), draft.class)) end
            lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, feature.name, desc)
        end
    end
    -- What the specialization suggests for this level.
    local spec = ns.ClassSpec(sheet, draft.class)
    local suggestions = R.SpecSuggestions(draft.class, spec, level)
    if #suggestions > 0 then
        lines[#lines + 1] = ("\n%sSuggested for %s|r: %s"):format(Opt.GOLD, spec, table.concat(suggestions, " "))
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
            local total = Like().level
            local text = draft.taking and ("Level %d to %d"):format(total - 1, total)
                or ("Your choice for %s"):format(ns.SlotLabel(Sheet(), draft.level))
            -- With several classes, or a new one, the class the level is taken in is named.
            if draft.taking and (draft.newClass or ns.IsMulticlass(Sheet())) then
                text = ("%s: %s level %d"):format(text, DraftClass().name, draft.classLevel)
            end
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
            local class = DraftClass()
            return (Opt.ListMap(class and class.subclasses, true))
        end,
        sorting = function()
            local class = DraftClass()
            return (select(2, Opt.ListMap(class and class.subclasses, true)))
        end,
        get = function() return draft.subclass end,
        set = function(_, value)
            draft.subclass = value
            DropUnfollowed() -- its always-prepared spells can't be picked as well
        end,
    },
    newClassSkill = {
        type = "select", order = 10.5, name = "Skill from your new class", width = "double",
        desc = "A class taken after your first gives one skill from its list, where it gives any. Skills you are proficient in are left out.",
        hidden = function() return #NewClassSkills() == 0 end,
        values = function() return (Opt.ListMap(NewClassSkills())) end,
        get = function() return draft.skill end,
        set = function(_, value) draft.skill = value end,
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
        values = function() return (Opt.ListMap(ns.StyleChoices(ns.ClassView(Sheet(), draft.class), StyleSlot() or 1), true)) end,
        sorting = function() return (select(2, Opt.ListMap(ns.StyleChoices(ns.ClassView(Sheet(), draft.class), StyleSlot() or 1), true))) end,
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
            local like = setmetatable({ featureSkills = draft.featureSkills }, { __index = Like() })
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
        name = function() return draft and draft.taking and ("Take level " .. Like().level) or "Save choice" end,
        disabled = function() return not draft or Problem() ~= nil end,
        func = function()
            local sheet, level, taking = Sheet(), draft.level, draft.taking
            -- For a class that is only added by taking the level, RPSheet:SetLevel below
            -- writes the subclass and the skill.
            local subclass = AsksSubclass() and draft.subclass ~= "" and draft.subclass or nil
            if subclass then ns.SetSubclass(sheet, draft.class, subclass) end
            local slot = StyleSlot()
            if slot and draft.style ~= "" then sheet[ns.STYLE_FIELDS[slot]] = draft.style end
            if draft.kind then Levels.Set(sheet, level, draft.record) end
            for _, feature in ipairs(OptionFeatures()) do sheet.featureOptions[feature.name] = draft.options[feature.name] end
            for _, key in ipairs(R.PICK_LIST_ORDER) do
                if PickLimit(key) > 0 then sheet.picks[key] = CopyTable(draft.picks[key]) end
            end
            if ManeuverLimit() > 0 then sheet.maneuvers = CopyTable(draft.maneuvers) end
            if ExpertiseLimit() > 0 then sheet.expertise = CopyTable(draft.expertise) end
            if FeatSkillLimit() > 0 then
                sheet.featSkills, sheet.featTools = CopyTable(draft.featSkills), CopyTable(draft.featTools)
            end
            sheet.featChoices = CopyTable(draft.featChoices) -- kept per feat; the upkeep drops what no feat asks for
            for _, feature in ipairs(SkillFeatures()) do sheet.featureSkills[feature] = draft.featureSkills[feature] end
            if taking then
                RPSheet:SetLevel(sheet.level + 1, draft.class, { subclass = subclass, skill = draft.skill })
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
            return ("%s (%d)"):format(R.STAT_NAMES[stat], (RPSheet:NaturalScore(stat)))
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
        local counted = saved and ns.HasSlot(sheet, draft.level) and saved.asi[stat] or 0
        local room = R.MAX_SCORE - (RPSheet:NaturalScore(stat) - counted) -- your own score: an item that sets it higher leaves the room as it is
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
    name = function()
        local title = draft and ns.FeatToolLimit(Sheet()) > 0 and "Skills and tools from your feats" or "Skills from your feats"
        return ("%s (%d of %d chosen)"):format(title, draft and FeatSkillsPicked() or 0, FeatSkillLimit())
    end,
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

-- A feat that offers skills or tools (Skilled) lists the tools under the skills: the
-- ones the character isn't proficient with from somewhere else.
args.featSkills.args.toolHead = {
    type = "header", order = 100, name = "Or tools",
    hidden = function() return not draft or ns.FeatToolLimit(Sheet()) == 0 end,
}
for index, name in ipairs(R.TOOL_ORDER) do
    args.featSkills.args["tool" .. index] = {
        type = "toggle", order = 100 + index, width = 1, name = name,
        desc = ("Proficiency with this tool in place of a skill, from the Skilled feat. %s; checks with it normally use %s."):format(
            R.TOOL_KINDS[R.TOOLS[name].kind] or "Tool", R.STAT_NAMES[R.TOOLS[name].stat] or "an ability"),
        hidden = function()
            if not draft or ns.FeatToolLimit(Sheet()) == 0 then return true end
            return not draft.featTools[name] and ns.FeatToolTaken(Sheet(), name)
        end,
        disabled = function()
            if draft.featTools[name] then return false end
            return FeatSkillsPicked() >= FeatSkillLimit() or FeatToolsPicked() >= ns.FeatToolLimit(Sheet())
        end,
        get = function() return draft.featTools[name] or false end,
        set = function(_, value) draft.featTools[name] = value or nil end,
    }
end

-- The choices inside feats, right under the feat this level takes.
args.featChoices = Opt.FeatChoiceGroup(43, FeatChoiceContext)

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
        name = function()
            local swaps = draft and ns.PickSwapNote(key, draft.before, draft.picks, Picking()) or ""
            return ("%s (%d of %d chosen%s)"):format(list.title, draft and PicksChosen(key) or 0, PickLimit(key), swaps)
        end,
        hidden = function() return PickLimit(key) == 0 end,
    }
    -- A long list leaves out what the character can't pick yet.
    local function Hidden(name)
        return list.hideBlocked == true and draft ~= nil and not draft.picks[key][name]
            and Blocked(key, name) ~= nil
    end
    local section
    for index, name in ipairs(list.order) do
        -- Items that carry a group get a heading where a new group starts.
        local itemGroup = list.items[name].group
        if itemGroup and itemGroup ~= section then
            section = itemGroup
            group.args["head" .. index] = {
                type = "header", order = index - 0.5, name = itemGroup,
                hidden = function()
                    for _, other in ipairs(list.order) do
                        if list.items[other].group == itemGroup and not Hidden(other) then return false end
                    end
                    return true
                end,
            }
        end
        group.args["pick" .. index] = {
            type = "toggle", order = index, width = 1.5,
            name = function()
                local blocked = draft and not draft.picks[key][name] and Blocked(key, name)
                -- A spell shows its level behind the name.
                local tag = list.items[name].tag
                local shown = tag and ("%s |cff888888(%s)|r"):format(name, tag) or name
                return blocked and ("|cff888888%s (%s)|r"):format(name, blocked) or shown
            end,
            hidden = function() return Hidden(name) end,
            desc = list.items[name].desc,
            disabled = function()
                if draft.picks[key][name] then return SwapLocked(key, name) end
                return PicksChosen(key) >= PickLimit(key) or Blocked(key, name) ~= nil
            end,
            get = function() return draft.picks[key][name] or false end,
            set = function(_, value)
                local picked = draft.picks[key]
                picked[name] = value or nil
                -- Dropping a pick drops the ones that build on it.
                local dropped = not value
                while dropped do
                    dropped = false
                    for other in pairs(picked) do
                        local needs = list.items[other] and list.items[other].needs
                        if needs and not picked[needs] then
                            picked[other] = nil
                            dropped = true
                            break
                        end
                    end
                end
                if not value then DropUnfollowed() end
            end,
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

-- Opens the dialog for `level`: a level the character has (its number, see
-- Sheet/ClassSlots.lua) to make or change its choice, or nothing to take the next
-- level. `reopen` brings the settings back afterwards. `classKey` is the class the
-- next level is taken in: the first class when left out, another of the character's
-- classes, or a class it doesn't have yet.
function ns.OpenLevelDialog(level, reopen, classKey)
    local sheet = Sheet()
    local taking = not (level and ns.HasSlot(sheet, level))
    local own, classLevel
    if taking then
        if sheet.level >= R.MAX_LEVEL then return end
        own = R.CLASSES[classKey] and classKey or sheet.class
        classLevel = ns.ClassLevel(sheet, own) + 1
        level = ns.LevelSlot(sheet, own, classLevel)
    else
        own, classLevel = ns.SlotClass(sheet, level)
    end
    if reopen == nil then reopen = AceConfigDialog.OpenFrames[ADDON] ~= nil end
    local kind = Levels.Kind(sheet, level)
    local record = Levels.Record(sheet, level)
    local newClass = taking and ns.ClassLevel(sheet, own) == 0
    draft = {
        level = level, class = own, classLevel = classLevel, newClass = newClass, skill = "",
        taking = taking, kind = kind, subclass = "", style = "", reopen = reopen,
        maneuvers = CopyTable(sheet.maneuvers), featureSkills = CopyTable(sheet.featureSkills),
        options = CopyTable(sheet.featureOptions), picks = CopyTable(sheet.picks), expertise = CopyTable(sheet.expertise), featSkills = CopyTable(sheet.featSkills),
        featTools = CopyTable(sheet.featTools or {}), before = {},
        featChoices = CopyTable(sheet.featChoices or {}),
        record = record and CopyTable(record) or Levels.NewRecord(kind),
    }
    for _, key in ipairs(R.PICK_LIST_ORDER) do draft.picks[key] = draft.picks[key] or {} end
    DropUnfollowed() -- a pick that stopped being valid is asked for again
    -- The picks the character had before this level: only so many of them may be
    -- exchanged while taking it (see SwapLocked).
    if draft.taking then
        for _, key in ipairs(R.PICK_LIST_ORDER) do
            if R.PICK_LISTS[key].swaps and ns.SheetPickLimit(sheet, key) > 0 then
                draft.before[key] = CopyTable(draft.picks[key])
            end
        end
    end
    if kind == "BOON" then draft.record.choice = "FEAT" end
    -- A hero class taken as a new class comes with its subclass.
    if newClass and R.CLASSES[own].hero then draft.subclass = R.CLASSES[own].subclasses[1] or "" end
    -- The specialization's suggestions are pre-selected; the player can pick otherwise.
    local guide = R.SpecGuide(own, ns.ClassSpec(sheet, own))
    if guide then
        if guide.subclass and AsksSubclass() then draft.subclass = guide.subclass end
        local slot = StyleSlot()
        if guide.style and slot then
            for _, name in ipairs(ns.StyleChoices(ns.ClassView(sheet, own), slot)) do
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
