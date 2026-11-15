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
        classes = {}, -- the classes taken beside the first (Wizard/MoreClasses.lua)
        species = "", lineage = "", size = "M", background = "", allegiance = "",
        traitChoices = {}, -- picks for species traits such as Skillful and Versatile
        scoreMethod = "POINTBUY",
        base = { STR = 8, DEX = 8, CON = 8, INT = 8, WIS = 8, CHA = 8 },
        bonus = { STR = 0, DEX = 0, CON = 0, INT = 0, WIS = 0, CHA = 0 },
        alignment = "",
        fightingStyle = "", fightingStyle2 = "", -- the first class's; a later class has its own (Wizard/Styles.lua)
        closet = {}, -- starting gear taken: item name -> how many (Wizard/Closet.lua)
        worn = {},   -- the taken armor, shield and weapons that are equipped
        gold = 0,    -- gold pieces to start with
        gear = {},   -- the ready sets taken from class and background (Wizard/StartingGear.lua)
        gearSet = 1, -- which of the class's sets, for a class that offers two
        gearNote = "",
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

-- Returns a message when the current step isn't complete, nil when it is.
function W.StepProblem()
    local draft = W.draft
    if draft.step == 1 then
        local class = R.CLASSES[draft.class]
        if not class then return "Choose a class first." end
        if W.SkillsPicked() ~= class.skillCount then
            return ("Pick %d class skills."):format(class.skillCount)
        end
        -- With other classes, the first class goes by its own level (Wizard/MoreClasses.lua).
        if W.FirstLevel() >= R.SUBCLASS_LEVEL and #class.subclasses > 0 and draft.subclass == "" then
            return ("Choose a subclass: a character of level %d or higher has one."):format(R.SUBCLASS_LEVEL)
        end
        return W.ExtrasProblem(1) or W.StyleProblem()
    elseif draft.step == 2 then
        if not R.SPECIES[draft.species] then return "Choose a species." end
        if not R.BACKGROUNDS[draft.background] then return "Choose a background." end
        if R.LINEAGES[draft.species] and draft.lineage == "" then return "Choose a lineage." end
        -- A skill the background gives can't also be a class pick: that pick would be wasted.
        for _, skill in ipairs(R.BACKGROUNDS[draft.background].skills) do
            if draft.classSkills[skill] then
                return ("This background already gives %s, which is one of your class skills. Go back to step 1 and pick another class skill, or choose a different background."):format(skill)
            end
        end
        for _, trait in ipairs(ns.TraitChoices(draft)) do
            if (draft.traitChoices[trait] or "") == "" then return ("Make your choice for %s."):format(trait) end
        end
        return W.ExtrasProblem(2)
    elseif draft.step == 4 then
        if draft.allegiance == "" then return "Choose an allegiance." end
    elseif draft.step == 3 then
        if draft.scoreMethod == "POINTBUY" and W.PointsSpent() > R.POINTS then
            return ("You have spent %d of %d points."):format(W.PointsSpent(), R.POINTS)
        end
        if W.BonusSpent() ~= R.BONUS_TOTAL then
            return ("Place all %d background points: +2 and +1, or +1 on three abilities."):format(R.BONUS_TOTAL)
        end
        -- Another class asks for 13 in its main abilities and in the first class's.
        return W.ExtrasProblem(3)
    end
end

-- Builds the sheet from the draft and makes it the active one.
function W.Finish()
    local draft = W.draft
    local old = RPSheet:Sheet()
    local sheet = ns.NewSheet()
    for _, key in ipairs(R.PICK_LIST_ORDER) do sheet.picks[key] = {} end

    -- A subclass picked before the level was lowered below 3 doesn't count.
    local subclass = W.FirstLevel() >= R.SUBCLASS_LEVEL and draft.subclass or ""
    -- A hero class is its subclass, fixed when the character is made.
    local class = R.CLASSES[draft.class]
    if class.hero then subclass = class.subclasses[1] end
    sheet.class, sheet.subclass, sheet.spec, sheet.level = draft.class, subclass, draft.spec, draft.level
    W.ApplyExtras(sheet) -- the other classes; the level above is the whole character's
    sheet.species, sheet.size, sheet.background, sheet.alignment = draft.species, draft.size, draft.background, draft.alignment
    sheet.lineage, sheet.allegiance = draft.lineage, draft.allegiance
    for _, trait in ipairs(ns.TraitChoices(draft)) do sheet.traitChoices[trait] = draft.traitChoices[trait] end
    sheet.scoreMethod = draft.scoreMethod
    sheet.base, sheet.bonus = CopyTable(draft.base), CopyTable(draft.bonus)
    W.ApplyStyles(sheet) -- each class's Fighting Styles, where it has the feature by its level
    for skill, picked in pairs(draft.classSkills) do
        if picked then sheet.skills[skill] = 1 end
    end

    if draft.keepLists then
        sheet.resources, sheet.weapons, sheet.spells = old.resources, old.weapons, old.spells
        sheet.abilities, sheet.passives = OwnEntries(old.abilities), OwnEntries(old.passives)
        sheet.items, sheet.coins = old.items or {}, old.coins or sheet.coins
        sheet.mounts = old.mounts or {}
    end
    sheet.coins.gp = (sheet.coins.gp or 0) + (draft.gold or 0)
    W.FillInventory(sheet)
    W.GrantGearTools(sheet) -- a tool chosen with a set of starting gear (Wizard/GearChoices.lua)
    ns.ApplyGrants(sheet)
    RPSheet:ReplaceSheet(sheet, draft.keepLists)
end
