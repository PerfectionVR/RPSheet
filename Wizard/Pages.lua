-- The five pages of the creation wizard, following the book's steps:
-- 1 class, 2 origin (species and background), 3 ability scores, 4 alignment, 5 details.
-- Each page is an AceConfig group that is only shown on its step.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Util = ns.Util
local W = ns.Wizard

local GOLD, RED = Opt.GOLD, Opt.RED

-- hidden unless the wizard is on step `n`
local function Step(n)
    return function() return not W.draft or W.draft.step ~= n end
end

-- Binds an option to a field of the draft.
local function Field(option, key)
    option.get = function() return W.draft[key] end
    option.set = function(_, value) W.draft[key] = value end
    return option
end

local function Page(order, args)
    return { type = "group", inline = true, order = order * 10, name = "", hidden = Step(order), args = args }
end

local function DraftClass()
    return R.CLASSES[W.draft.class]
end

---------------------------------------------------------------------------
-- 1: Class
---------------------------------------------------------------------------
local function ClassSummary()
    local class = DraftClass()
    if not class then return "Choose the class you want to play. Each one builds on a core class, which sets your hit points, saving throws and skills.\n" end
    local lines = {
        ("%s%s|r uses the %s%s|r class."):format(GOLD, class.name, GOLD, class.base),
        ("%s d%d. %s: %s."):format(ns.Term("Hit die"), class.hitDie, ns.Term("Saving throw", "Saving throws"), ns.Terms(class.saves)),
        "Training: " .. class.training .. ".",
        ("Pick %d skills from: %s."):format(class.skillCount, ns.Terms(class.skills)),
    }
    if class.cast then
        lines[#lines + 1] = "Spellcasting ability: " .. ns.Term(R.STAT_NAMES[class.cast]) .. "."
    end
    if class.hero then
        lines[#lines + 1] = ("%s: %snormally starts at level %d or higher.|r"):format(ns.Term("Hero class"), RED, R.HERO_START_LEVEL)
    end
    lines[#lines + 1] = "|cff909090Hover a highlighted word for an explanation.|r"
    return table.concat(lines, "\n") .. "\n"
end

-- Dropdown of the chosen class's subclasses or specializations.
local function ClassChoice(option, field, key)
    option.hidden = function() return not DraftClass() end
    option.values = function() return (Opt.ListMap(DraftClass()[field], true)) end
    option.sorting = function() return (select(2, Opt.ListMap(DraftClass()[field], true))) end
    return Field(option, key)
end

local classPage = Page(1, {
    class = {
        type = "select", order = 1, name = "Class",
        values = Opt.NameMap(R.CLASSES, R.CLASS_ORDER), sorting = R.CLASS_ORDER,
        get = function() return W.draft.class end,
        set = function(_, value)
            local draft = W.draft
            draft.class = value
            draft.subclass, draft.spec, draft.classSkills = "", "", {}
            if R.CLASSES[value].hero and draft.level < R.HERO_START_LEVEL then
                draft.level = R.HERO_START_LEVEL
            end
        end,
    },
    level = Field({ type = "range", order = 2, min = 1, max = R.MAX_LEVEL, step = 1, name = "Level" }, "level"),
    summary = { type = "description", order = 3, fontSize = "medium", name = ClassSummary, dialogControl = "RPSheetTermLabel" },
    subclass = ClassChoice({
        type = "select", order = 4, name = "Subclass",
        desc = "Usually chosen at level 3. Other subclasses can be typed in later in the editor.",
    }, "subclasses", "subclass"),
    spec = ClassChoice({
        type = "select", order = 5, name = "Specialization",
        desc = "A World of Warcraft specialization to guide your choices. It has no rules of its own.",
    }, "specs", "spec"),
    skills = {
        -- width applies to each checkbox: 1.5 units (255px) fits two per row in this window.
        type = "multiselect", order = 6, width = 1.5,
        -- The dialog asks for the name even while the option is hidden (no class chosen yet).
        name = function()
            local class = DraftClass()
            return ("Class skills (%d of %d picked)"):format(W.SkillsPicked(), class and class.skillCount or 0)
        end,
        hidden = function() return not DraftClass() end,
        values = function() return (Opt.ListMap(DraftClass().skills)) end,
        get = function(_, skill) return W.draft.classSkills[skill] or false end,
        set = function(_, skill, value) W.draft.classSkills[skill] = value or nil end,
    },
})

---------------------------------------------------------------------------
-- 2: Origin
---------------------------------------------------------------------------
local function OriginSummary()
    local lines = {}
    local species, background = R.SPECIES[W.draft.species], R.BACKGROUNDS[W.draft.background]
    if species then
        lines[#lines + 1] = ("%s%s|r: speed %d ft%s."):format(
            GOLD, species.name, species.speed,
            species.darkvision and (", " .. ns.Term("Darkvision", "darkvision " .. species.darkvision .. " ft")) or "")
        lines[#lines + 1] = "Traits: " .. ns.Terms(species.traits) .. "."
        local _, lineage = R.Lineage(W.draft.species, W.draft.lineage)
        if lineage then
            lines[#lines + 1] = ("%s%s|r: %s"):format(GOLD, lineage.name, lineage.desc)
        end
        lines[#lines + 1] = ""
    end
    if background then
        lines[#lines + 1] = ("%s%s|r: raise %s."):format(GOLD, background.name, ns.Terms(background.stats))
        lines[#lines + 1] = ("Skills: %s. %s: %s."):format(
            ns.Terms(background.skills), ns.Term("Origin feat"), ns.Term(background.feat))
        lines[#lines + 1] = ""
    end
    if #lines == 0 then
        lines[1] = "Pick a species and a background. Together they are your origin: traits, skills, a feat and ability score increases."
    else
        lines[#lines + 1] = "|cff909090Hover a highlighted word for an explanation.|r"
    end
    return table.concat(lines, "\n") .. "\n"
end

local originPage = Page(2, {
    species = {
        type = "select", order = 1, name = "Species",
        values = Opt.NameMap(R.SPECIES, R.SPECIES_ORDER), sorting = R.SPECIES_ORDER,
        get = function() return W.draft.species end,
        set = function(_, value)
            local sizes = R.SPECIES[value].sizes
            W.draft.species, W.draft.size, W.draft.lineage = value, sizes[#sizes], ""
        end,
    },
    size = Field({
        type = "select", order = 2, name = "Size",
        hidden = function()
            local species = R.SPECIES[W.draft.species]
            return not species or #species.sizes < 2
        end,
        values = function()
            local values = {}
            for _, size in ipairs(R.SPECIES[W.draft.species].sizes) do values[size] = R.SIZE_NAMES[size] end
            return values
        end,
    }, "size"),
    lineage = Field({
        type = "select", order = 2.5, name = "Lineage",
        hidden = function() return not R.LINEAGES[W.draft.species] end,
        values = function()
            local values = {}
            for _, option in ipairs(R.LINEAGES[W.draft.species].options) do values[option.name] = option.name end
            return values
        end,
    }, "lineage"),
    background = {
        type = "select", order = 3, name = "Background",
        values = Opt.NameMap(R.BACKGROUNDS, R.BACKGROUND_ORDER), sorting = R.BACKGROUND_ORDER,
        get = function() return W.draft.background end,
        set = function(_, value)
            W.draft.background = value
            -- The points belong to the old background's abilities; place them again.
            for _, stat in ipairs(R.STATS) do W.draft.bonus[stat] = 0 end
        end,
    },
    summary = { type = "description", order = 4, fontSize = "medium", name = OriginSummary, dialogControl = "RPSheetTermLabel" },
})

---------------------------------------------------------------------------
-- 3: Ability scores
---------------------------------------------------------------------------
local function ScoreSummary()
    local draft, lines = W.draft, {}
    if draft.scoreMethod == "POINTBUY" then
        lines[#lines + 1] = ("Points spent: %s%d / %d|r. Scores of 14 and 15 cost 2 points per step."):format(GOLD, W.PointsSpent(), R.POINTS)
    elseif draft.scoreMethod == "ARRAY" then
        lines[#lines + 1] = "Assign 15, 14, 13, 12, 10 and 8. Picking a value swaps it with the ability that had it."
    else
        lines[#lines + 1] = "Enter the scores you rolled or agreed with your DM."
    end
    local background = R.BACKGROUNDS[draft.background]
    lines[#lines + 1] = ("Background points placed: %s%d / %d|r%s"):format(
        GOLD, W.BonusSpent(), R.BONUS_TOTAL,
        background and (" on " .. ns.Terms(background.stats) .. " (+2 and +1, or +1 each).") or ".")
    local totals = {}
    for _, stat in ipairs(R.STATS) do
        local score = draft.base[stat] + draft.bonus[stat]
        totals[#totals + 1] = ("%s %d (%s)"):format(ns.Term(stat), score, Util.Signed(Util.ScoreMod(score)))
    end
    lines[#lines + 1] = table.concat(totals, "    ")
    return table.concat(lines, "\n") .. "\n"
end

local scoreArgs = {
    method = {
        type = "select", order = 1, name = "Method", width = "double",
        values = R.SCORE_METHODS, sorting = R.SCORE_METHOD_ORDER,
        get = function() return W.draft.scoreMethod end,
        set = function(_, value)
            W.draft.scoreMethod = value
            for i, stat in ipairs(R.STATS) do
                W.draft.base[stat] = value == "ARRAY" and R.STANDARD_ARRAY[i] or R.BASE_MIN
            end
        end,
    },
    summary = { type = "description", order = 2, fontSize = "medium", name = ScoreSummary, dialogControl = "RPSheetTermLabel" },
}
for i, stat in ipairs(R.STATS) do
    scoreArgs["score" .. stat] = {
        type = "range", order = i * 10, step = 1, name = R.STAT_NAMES[stat], min = 3, max = R.MAX_SCORE,
        desc = ns.Glossary[stat],
        hidden = function() return W.draft.scoreMethod == "ARRAY" end,
        get = function() return W.draft.base[stat] end,
        set = function(_, value)
            if W.draft.scoreMethod == "POINTBUY" then
                value = math.max(R.BASE_MIN, math.min(R.BASE_MAX, value))
            end
            W.draft.base[stat] = value
        end,
    }
    scoreArgs["array" .. stat] = {
        type = "select", order = i * 10, name = R.STAT_NAMES[stat], desc = ns.Glossary[stat],
        values = Opt.ARRAY_VALUES, sorting = Opt.ARRAY_ORDER,
        hidden = function() return W.draft.scoreMethod ~= "ARRAY" end,
        get = function() return W.draft.base[stat] end,
        set = function(_, value)
            local base = W.draft.base
            for _, other in ipairs(R.STATS) do
                if base[other] == value then base[other] = base[stat] end
            end
            base[stat] = value
        end,
    }
    scoreArgs["bonus" .. stat] = {
        type = "range", order = i * 10 + 1, min = 0, max = R.BONUS_MAX, step = 1,
        name = R.STAT_NAMES[stat] .. " (background)",
        disabled = function() return not Opt.BackgroundAllows(W.draft.background, stat) end,
        get = function() return W.draft.bonus[stat] end,
        set = function(_, value)
            local bonus = W.draft.bonus
            local old = bonus[stat]
            bonus[stat] = value
            if W.BonusSpent() > R.BONUS_TOTAL then
                bonus[stat] = old
                RPSheet:Print(("Only %d background points in total."):format(R.BONUS_TOTAL))
            end
        end,
    }
    scoreArgs["break" .. stat] = { type = "description", order = i * 10 + 2, name = "" }
end
local scorePage = Page(3, scoreArgs)

---------------------------------------------------------------------------
-- 4: Alignment
---------------------------------------------------------------------------
local alignmentPage = Page(4, {
    help = {
        type = "description", order = 1, fontSize = "medium",
        name = "Alignment is a short description of your character's moral outlook. The peoples of the Alliance lean Lawful Good and those of the Horde Chaotic Good, but the choice is yours.\n",
    },
    alignment = Field({
        type = "select", order = 2, name = "Alignment",
        values = Opt.ALIGNMENT_VALUES, sorting = Opt.ALIGNMENT_ORDER,
    }, "alignment"),
    allegianceHelp = {
        type = "description", order = 3, fontSize = "medium",
        name = "\nAllegiance is the side your character stands with. It decides your common tongue (Common or Orcish) and, for some species, which faction you start with renown in.\n",
    },
    allegiance = Field({
        type = "select", order = 4, name = "Allegiance",
        values = R.ALLEGIANCES, sorting = R.ALLEGIANCE_ORDER,
    }, "allegiance"),
})

---------------------------------------------------------------------------
-- 5: Details
---------------------------------------------------------------------------
local detailsPage = Page(5, {
    help = {
        type = "description", order = 1, fontSize = "medium",
        name = "Starting gear. Hit points, Armor Class, proficiency bonus, saving throws, spell slots and class resources are worked out for you. More weapons, abilities and passives can be added in the editor afterwards.\n",
    },
    armor = Field({
        type = "select", order = 2, name = "Armor", values = Opt.ARMOR_VALUES, sorting = R.ARMOR_ORDER,
    }, "armor"),
    shield = Field({ type = "toggle", order = 3, name = "Shield (+2 AC)" }, "shield"),
    weaponHeader = { type = "header", order = 10, name = "Main weapon" },
    weaponName = Field({ type = "input", order = 11, name = "Name" }, "weaponName"),
    weaponStat = Field({
        type = "select", order = 12, name = "Ability",
        desc = "Strength for most melee weapons, Dexterity for ranged and finesse weapons.",
        values = Opt.STAT_VALUES, sorting = R.STATS,
    }, "weaponStat"),
    weaponSides = Field({
        type = "select", order = 13, name = "Damage die", values = Opt.DIE_VALUES, sorting = Opt.DIE_ORDER,
    }, "weaponSides"),
    keepLists = Field({
        type = "toggle", order = 20, width = "full",
        name = "Keep my existing weapons, resources, abilities and passives",
        desc = "On: only class, origin, scores and gear are replaced. Off: start from a clean sheet.",
        hidden = function() return not W.draft.hasContent end,
    }, "keepLists"),
})

W.pages = { classPage, originPage, scorePage, alignmentPage, detailsPage }
