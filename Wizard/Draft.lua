-- The character being built in the creation wizard: its choices so far, whether the
-- current step is complete, and turning the finished draft into a sheet.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local W = {}
ns.Wizard = W

W.STEPS = { "Choose a class", "Determine origin", "Determine ability scores", "Choose an alignment and allegiance", "Fill in details" }
W.draft = nil -- set while the wizard is open

-- The entries of a list the player made, leaving out what a class, subclass, species,
-- background or level put there.
local function OwnEntries(list)
    local own = {}
    for _, entry in ipairs(list) do
        if (entry.auto or "") == "" then own[#own + 1] = entry end
    end
    return own
end

function W.NewDraft()
    local current = RPSheet:Sheet()
    local hasContent = #OwnEntries(current.abilities) + #OwnEntries(current.passives)
        + #current.resources + #current.weapons + #current.spells > 0
    return {
        step = 1,
        class = "", subclass = "", spec = "", level = 1, classSkills = {},
        species = "", lineage = "", size = "M", background = "", allegiance = "",
        traitChoices = {}, -- picks for species traits such as Skillful and Versatile
        scoreMethod = "POINTBUY",
        base = { STR = 8, DEX = 8, CON = 8, INT = 8, WIS = 8, CHA = 8 },
        bonus = { STR = 0, DEX = 0, CON = 0, INT = 0, WIS = 0, CHA = 0 },
        alignment = "",
        fightingStyle = "",
        armor = "NONE", shield = false,
        weaponName = "Weapon", weaponStat = "STR", weaponSides = 8,
        -- A new character starts clean. What the player made by hand on the current one
        -- can be carried over, but only if they ask for it.
        keepLists = false, hasContent = hasContent,
    }
end

function W.PointsSpent()
    local total = 0
    for _, stat in ipairs(R.STATS) do total = total + (R.COST[W.draft.base[stat]] or 0) end
    return total
end

function W.BonusSpent()
    local total = 0
    for _, stat in ipairs(R.STATS) do total = total + W.draft.bonus[stat] end
    return total
end

function W.SkillsPicked()
    local count = 0
    for _, picked in pairs(W.draft.classSkills) do
        if picked then count = count + 1 end
    end
    return count
end

-- True if the draft's class has the Fighting Style feature by its level.
function W.NeedsFightingStyle()
    local draft = W.draft
    if not draft or not R.CLASSES[draft.class] then return false end
    for level = 1, draft.level do
        for _, feature in ipairs(ns.FeaturesGainedAt(draft.class, draft.subclass, level)) do
            if feature.name == ns.STYLE_FEATURES[1] then return true end
        end
    end
    return false
end

-- Returns a message when the current step isn't complete, nil when it is.
function W.StepProblem()
    local draft = W.draft
    if draft.step == 1 then
        local class = R.CLASSES[draft.class]
        if not class then return "Choose a class first." end
        if W.SkillsPicked() ~= class.skillCount then
            return ("Pick %d class skills."):format(class.skillCount)
        end
        if draft.level >= R.SUBCLASS_LEVEL and #class.subclasses > 0 and draft.subclass == "" then
            return ("Choose a subclass: a character of level %d or higher has one."):format(R.SUBCLASS_LEVEL)
        end
        if W.NeedsFightingStyle() and draft.fightingStyle == "" then
            return "Choose a Fighting Style."
        end
    elseif draft.step == 2 then
        if not R.SPECIES[draft.species] then return "Choose a species." end
        if not R.BACKGROUNDS[draft.background] then return "Choose a background." end
        if R.LINEAGES[draft.species] and draft.lineage == "" then return "Choose a lineage." end
        for _, trait in ipairs(ns.TraitChoices(draft)) do
            if (draft.traitChoices[trait] or "") == "" then return ("Make your choice for %s."):format(trait) end
        end
    elseif draft.step == 4 then
        if draft.allegiance == "" then return "Choose an allegiance." end
    elseif draft.step == 3 then
        if draft.scoreMethod == "POINTBUY" and W.PointsSpent() > R.POINTS then
            return ("You have spent %d of %d points."):format(W.PointsSpent(), R.POINTS)
        end
        if W.BonusSpent() ~= R.BONUS_TOTAL then
            return ("Place all %d background points: +2 and +1, or +1 on three abilities."):format(R.BONUS_TOTAL)
        end
    end
end

-- Builds the sheet from the draft and makes it the active one.
function W.Finish()
    local draft = W.draft
    local old = RPSheet:Sheet()
    local sheet = ns.NewSheet()

    -- A subclass picked before the level was lowered below 3 doesn't count.
    local subclass = draft.level >= R.SUBCLASS_LEVEL and draft.subclass or ""
    -- A hero class is its subclass, fixed when the character is made.
    local class = R.CLASSES[draft.class]
    if class.hero then subclass = class.subclasses[1] end
    sheet.class, sheet.subclass, sheet.spec, sheet.level = draft.class, subclass, draft.spec, draft.level
    sheet.species, sheet.size, sheet.background, sheet.alignment = draft.species, draft.size, draft.background, draft.alignment
    sheet.lineage, sheet.allegiance = draft.lineage, draft.allegiance
    for _, trait in ipairs(ns.TraitChoices(draft)) do sheet.traitChoices[trait] = draft.traitChoices[trait] end
    sheet.scoreMethod = draft.scoreMethod
    sheet.base, sheet.bonus = CopyTable(draft.base), CopyTable(draft.bonus)
    sheet.armor, sheet.shield = draft.armor, draft.shield
    sheet.fightingStyle = W.NeedsFightingStyle() and draft.fightingStyle or ""
    for skill, picked in pairs(draft.classSkills) do
        if picked then sheet.skills[skill] = 1 end
    end

    if draft.keepLists then
        sheet.resources, sheet.weapons, sheet.spells = old.resources, old.weapons, old.spells
        sheet.abilities, sheet.passives = OwnEntries(old.abilities), OwnEntries(old.passives)
    end
    if #sheet.weapons == 0 and draft.weaponName ~= "" then
        sheet.weapons[1] = {
            name = draft.weaponName, stat = draft.weaponStat, dice = 1, sides = draft.weaponSides,
            proficient = true, heal = false,
        }
    end
    ns.ApplyGrants(sheet)
    RPSheet:ReplaceSheet(sheet, draft.keepLists)
end
