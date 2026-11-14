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
-- `minLevel` hides the choice until the character is of that level.
local function ClassChoice(option, field, key, minLevel)
    option.hidden = function() return not DraftClass() or (minLevel ~= nil and W.draft.level < minLevel) end
    option.values = function() return (Opt.ListMap(DraftClass()[field], true)) end
    option.sorting = function() return (select(2, Opt.ListMap(DraftClass()[field], true))) end
    return Field(option, key)
end

-- One checkbox per skill, shown for the skills the class offers. Once the class's
-- number of skills is picked the rest grey out, until one is unticked.
local skillArgs = {}
for index, skill in ipairs(R.SKILLS) do
    local name = skill.name
    local function Offered()
        for _, offered in ipairs(DraftClass() and DraftClass().skills or {}) do
            if offered == name then return true end
        end
        return false
    end
    skillArgs["skill" .. index] = {
        -- 1.5 units (255px) fits two per row in this window.
        type = "toggle", order = index, width = 1.5, name = name, desc = ns.Glossary[name],
        hidden = function() return not Offered() end,
        disabled = function()
            return not W.draft.classSkills[name] and W.SkillsPicked() >= DraftClass().skillCount
        end,
        get = function() return W.draft.classSkills[name] or false end,
        set = function(_, value) W.draft.classSkills[name] = value or nil end,
    }
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
            -- A hero class is its subclass: the choice is fixed from the start.
            if R.CLASSES[value].hero then draft.subclass = R.CLASSES[value].subclasses[1] end
            if R.CLASSES[value].hero and draft.level < R.HERO_START_LEVEL then
                draft.level = R.HERO_START_LEVEL
            end
        end,
    },
    level = Field({
        type = "range", order = 2, min = 1, max = R.MAX_LEVEL, step = 1, name = "Level",
        desc = "A hero class normally starts at level 3 or higher; a lower level needs your DM's permission.",
    }, "level"),
    summary = { type = "description", order = 3, fontSize = "medium", name = ClassSummary, dialogControl = "RPSheetTermLabel" },
    subclass = ClassChoice({
        type = "select", order = 4, name = "Subclass",
        desc = "Every class chooses its subclass at level 3, so this appears from that level.",
    }, "subclasses", "subclass", R.SUBCLASS_LEVEL),
    spec = (function()
        local option = ClassChoice({
            type = "select", order = 5, name = "Specialization",
            desc = "How you play your class. It has no rules of its own: it guides your choice of subclass, Fighting Style, weapons and spells, and the suggestions below follow it.",
        }, "specs", "spec")
        -- Picking one pre-selects what it suggests, where that is a single choice.
        option.set = function(_, value)
            local draft = W.draft
            draft.spec = value
            local guide = R.SpecGuide(draft.class, value)
            if guide then
                if guide.subclass then draft.subclass = guide.subclass end
                if guide.style then draft.fightingStyle = guide.style end
            end
        end
        return option
    end)(),
    specGuide = {
        type = "description", order = 5.2, fontSize = "medium",
        hidden = function() return not W.draft or #R.SpecSuggestions(W.draft.class, W.draft.spec, W.draft.level, 1) == 0 end,
        name = function()
            local draft = W.draft
            if not draft then return "" end
            local lines = R.SpecSuggestions(draft.class, draft.spec, draft.level, 1)
            return ("%sSuggested for %s|r\n%s\n"):format(GOLD, draft.spec, table.concat(lines, "\n"))
        end,
    },
    fightingStyle = {
        type = "select", order = 5.5, name = "Fighting Style",
        desc = function()
            local lines = {}
            for _, style in ipairs(R.FIGHTING_STYLE_ORDER) do
                lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, style, R.FIGHTING_STYLES[style].desc)
            end
            return table.concat(lines, "\n\n")
        end,
        -- Only for a class that has the feature by the chosen level.
        hidden = function()
            local draft = W.draft
            if not draft or not DraftClass() then return true end
            for level = 1, draft.level do
                for _, feature in ipairs(ns.FeaturesGainedAt(draft.class, draft.subclass, level)) do
                    if feature.name == ns.STYLE_FEATURES[1] then return false end
                end
            end
            return true
        end,
        values = function() return (Opt.ListMap(ns.StyleChoices({ class = W.draft.class, passives = {} }, 1), true)) end,
        sorting = function() return (select(2, Opt.ListMap(ns.StyleChoices({ class = W.draft.class, passives = {} }, 1), true))) end,
        get = function() return W.draft.fightingStyle end,
        set = function(_, value) W.draft.fightingStyle = value end,
    },
    skills = {
        type = "group", inline = true, order = 6, args = skillArgs,
        -- The dialog asks for the name even while the option is hidden (no class chosen yet).
        name = function()
            local class = DraftClass()
            return ("Class skills (%d of %d picked)"):format(W.SkillsPicked(), class and class.skillCount or 0)
        end,
        hidden = function() return not DraftClass() end,
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

-- What the draft can pick for a species trait: skills its class and background don't
-- already give, or origin feats other than the background's.
local function DraftTraitOptions(name)
    local draft, trait, names = W.draft, R.TRAITS[name], {}
    local background = R.BACKGROUNDS[draft.background]
    if trait.choice == "SKILL" then
        local taken = {}
        for skill, picked in pairs(draft.classSkills) do taken[skill] = picked end
        for _, skill in ipairs(background and background.skills or {}) do taken[skill] = true end
        for other, choice in pairs(draft.traitChoices) do
            if other ~= name then taken[choice] = true end
        end
        local pool = trait.options
        if not pool then
            pool = {}
            for _, skill in ipairs(R.SKILLS) do pool[#pool + 1] = skill.name end
        end
        for _, skill in ipairs(pool) do
            if not taken[skill] then names[#names + 1] = skill end
        end
    else
        for _, feat in ipairs(R.FEAT_NAMES.GENERAL) do
            local data = R.FEATS[feat]
            local allowed = not data.needSpecies or data.needSpecies == draft.species
            if data.kind == "ORIGIN" and allowed and (data.repeatable or not (background and background.feat == feat)) then
                names[#names + 1] = feat
            end
        end
    end
    return names
end

local function DraftTraitPicker(name, order)
    return {
        type = "select", order = order,
        name = function() return name .. (R.TRAITS[name].choice == "FEAT" and " (origin feat)" or " (skill)") end,
        desc = function()
            if R.TRAITS[name].choice ~= "FEAT" then return ns.Glossary[name] end
            local lines = { ns.Glossary[name] or "" }
            for _, feat in ipairs(DraftTraitOptions(name)) do
                lines[#lines + 1] = ("%s%s|r: %s"):format(GOLD, feat, R.FEATS[feat].desc)
            end
            return table.concat(lines, "\n\n")
        end,
        hidden = function()
            for _, trait in ipairs(W.draft and ns.TraitChoices(W.draft) or {}) do
                if trait == name then return false end
            end
            return true
        end,
        values = function() return (Opt.ListMap(DraftTraitOptions(name))) end,
        sorting = function() return (select(2, Opt.ListMap(DraftTraitOptions(name)))) end,
        get = function() return W.draft.traitChoices[name] end,
        set = function(_, value) W.draft.traitChoices[name] = value end,
    }
end

local originPage = Page(2, {
    traitSkillful = DraftTraitPicker("Skillful", 3.1),
    traitKeenSenses = DraftTraitPicker("Keen Senses", 3.2),
    traitVersatile = DraftTraitPicker("Versatile", 3.3),
    species = {
        type = "select", order = 1, name = "Species",
        values = Opt.NameMap(R.SPECIES, R.SPECIES_ORDER), sorting = R.SPECIES_ORDER,
        get = function() return W.draft.species end,
        set = function(_, value)
            local sizes = R.SPECIES[value].sizes
            W.draft.species, W.draft.size, W.draft.lineage = value, sizes[#sizes], ""
            wipe(W.draft.traitChoices)
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
    scoreArgs["score" .. stat] = Opt.Bounded({
        type = "range", order = i * 10, step = 1, name = R.STAT_NAMES[stat], min = 3, max = R.MAX_SCORE,
        desc = ns.Glossary[stat],
        hidden = function() return not W.draft or W.draft.scoreMethod == "ARRAY" end,
        get = function() return W.draft and W.draft.base[stat] end,
        set = function(_, value) W.draft.base[stat] = value end,
    }, function()
        if not W.draft then return 3, R.MAX_SCORE end
        -- Point buy: 8 up to what the remaining points can pay for.
        if W.draft.scoreMethod == "POINTBUY" then return R.BASE_MIN, Opt.PointBuyMax(W.draft.base, stat) end
        return 3, R.MAX_SCORE
    end)
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
    scoreArgs["bonus" .. stat] = Opt.Bounded({
        type = "range", order = i * 10 + 1, min = 0, max = R.BONUS_MAX, step = 1,
        name = R.STAT_NAMES[stat] .. " (background)",
        hidden = function() return not W.draft end,
        get = function() return W.draft and W.draft.bonus[stat] end,
        set = function(_, value) W.draft.bonus[stat] = value end,
    }, function()
        if not W.draft then return 0, R.BONUS_MAX end
        -- Only the abilities the background names, and only the points that are left.
        if not Opt.BackgroundAllows(W.draft.background, stat) then return 0, 0 end
        return 0, Opt.BonusMax(W.draft.bonus, stat)
    end)
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
        type = "select", order = 2, name = "Armor",
        desc = "Only armor your class is trained with is offered.",
        values = function() return (ns.ArmorChoices(ns.ArmorTraining(W.draft.class), W.draft.armor)) end,
        sorting = function() return (select(2, ns.ArmorChoices(ns.ArmorTraining(W.draft.class), W.draft.armor))) end,
    }, "armor"),
    shield = Field({
        type = "toggle", order = 3, name = "Shield (+2 AC)",
        disabled = function() return not W.draft.shield and not ns.ArmorTraining(W.draft.class).shield end,
    }, "shield"),
    weaponHeader = { type = "header", order = 10, name = "Main weapon" },
    weapon = Field({
        type = "select", order = 11, name = "Weapon", width = "double",
        desc = "The basic weapons your class is proficient with. More weapons, and ones of your own, can be added under Customize afterwards.",
        values = function()
            local values = {}
            for _, name in ipairs(ns.ProficientWeapons(W.draft.class)) do
                values[name] = ("%s - %s"):format(name, R.WeaponSummary(name))
            end
            return values
        end,
        sorting = function() return ns.ProficientWeapons(W.draft.class) end,
    }, "weapon"),
    weaponInfo = {
        type = "description", order = 12, fontSize = "medium",
        hidden = function() return not (W.draft and R.WEAPONS[W.draft.weapon]) end,
        name = function()
            local data = W.draft and R.WEAPONS[W.draft.weapon]
            if not data then return "" end
            local lines = { ("%s%s|r: %s weapon, %s."):format(GOLD, data.name, data.category == "SIMPLE" and "simple" or "martial", R.WeaponSummary(data.name)) }
            if R.MASTERY_LIMITS[DraftClass().base] then
                lines[#lines + 1] = ("Mastery: %s. %s"):format(data.mastery, R.MASTERIES[data.mastery].desc)
            end
            return table.concat(lines, "\n") .. "\n"
        end,
    },
    keepLists = Field({
        type = "toggle", order = 20, width = "full",
        name = "Carry over the weapons, spells, resources, abilities and passives I made myself",
        desc = "Off: the new character starts clean. On: entries you added by hand on the current character are kept. What its class, species, background and levels gave is never carried over.",
        hidden = function() return not W.draft.hasContent end,
    }, "keepLists"),
})

W.pages = { classPage, originPage, scorePage, alignmentPage, detailsPage }
