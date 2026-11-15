-- The level dialog: how many of each kind of choice the level asks for, how many are
-- made in the draft, and what keeps an option from being picked.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local L = ns.LevelDialog

-- How many maneuvers the character should know at that level.
function L.ManeuverLimit()
    if not L.draft then return 0 end
    return ns.SheetManeuverLimit(L.Like())
end

function L.ManeuversPicked()
    local count = 0
    for _ in pairs(L.draft.maneuvers) do count = count + 1 end
    return count
end

-- Features with a skill to pick, as the character will be after this dialog.
function L.SkillFeatures()
    if not L.draft then return {} end
    return ns.SkillChoiceFeatures(L.Like())
end

-- Features with options to pick in this dialog: the ones still open when taking a
-- level, all of them when looking at the choices again.
function L.OptionFeatures()
    if not L.draft then return {} end
    local like = L.Like()
    return L.draft.taking and ns.OpenOptionFeatures(like) or ns.OptionFeatures(like)
end

-- How many options of a pick list (Metamagic, Invocations) the character should know.
function L.PickLimit(key)
    if not L.draft then return 0 end
    return ns.SheetPickLimit(L.Like(), key)
end

function L.PicksChosen(key)
    local count = 0
    for _ in pairs(L.draft.picks[key]) do count = count + 1 end
    return count
end

-- Why an option of a list can't be picked right now, or nil. The level and subclass
-- that count are those of the class the list belongs to.
function L.Blocked(key, name)
    local view = ns.ListView(L.Picking(), key)
    return ns.PickBlocked(key, name, view.level, L.draft.picks[key], view.subclass, view)
end

-- True if a pick made at an earlier level has to stay: only so many may be exchanged
-- when a level is gained (Sheet/PickSwaps.lua). Looking at the choices again is free.
function L.SwapLocked(key, name)
    return ns.PickSwapLocked(key, name, L.draft.before, L.draft.picks, L.Picking())
end

-- A list that follows another (list.follows) loses the picks that list no longer
-- allows: a mastered spell that was taken out of the spellbook is open again.
function L.DropUnfollowed()
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local list = R.PICK_LISTS[key]
        if list.follows and list.blocked and L.PickLimit(key) > 0 then
            local like = ns.ListView(L.Picking(), key)
            for name in pairs(L.draft.picks[key]) do
                if not list.items[name] or list.blocked(like, name) then L.draft.picks[key][name] = nil end
            end
        end
    end
end

-- How many skills to pick expertise in, and the set to pick from (nil = any).
function L.ExpertiseLimit()
    if not L.draft then return 0 end
    return ns.ExpertiseLimit(L.Like())
end

-- Skills to choose for the feats on the sheet (Skilled, Skill Expert).
function L.FeatSkillLimit()
    return L.draft and ns.FeatSkillLimit(L.Sheet()) or 0
end

-- Tools picked in place of skills (Skilled), out of the same picks.
function L.FeatToolsPicked()
    local count = 0
    for _ in pairs(L.draft.featTools) do count = count + 1 end
    return count
end

function L.FeatSkillsPicked()
    local count = L.FeatToolsPicked()
    for _ in pairs(L.draft.featSkills) do count = count + 1 end
    return count
end

-- The feats whose own choices are asked for here (a damage type, spells, tools):
-- those on the sheet, with this level's feat as it is being decided. Returns what
-- ns.FeatChoiceProgress and Opt.FeatChoiceGroup need.
function L.FeatChoiceContext()
    if not L.draft then return end
    local sheet, override = L.Sheet(), nil
    if L.draft.kind then
        override = { id = "level:" .. L.draft.level, name = L.draft.record.choice == "FEAT" and L.draft.record.feat or "" }
    end
    local instances = ns.FeatInstances(sheet, override)
    -- Picks for a feat that was swapped out here, or that no longer fit, are dropped.
    ns.NormalizeFeatChoices(L.draft.featChoices, instances, L.Like().level)
    return sheet, L.draft.featChoices, instances, L.Like().level
end

function L.ExpertisePicked()
    local count = 0
    for _ in pairs(L.draft.expertise) do count = count + 1 end
    return count
end
