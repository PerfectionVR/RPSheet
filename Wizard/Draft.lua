-- The character being built in the creation wizard: its choices so far, whether the
-- current step is complete, and turning the finished draft into a sheet.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local W = {}
ns.Wizard = W

W.STEPS = { "Choose a class", "Determine origin", "Determine ability scores", "Choose an alignment and allegiance", "Fill in details" }
W.draft = nil -- set while the wizard is open

function W.NewDraft()
    local current = RPSheet:Sheet()
    local hasContent = #current.abilities + #current.passives + #current.resources > 0
    return {
        step = 1,
        class = "", subclass = "", spec = "", level = 1, classSkills = {},
        species = "", lineage = "", size = "M", background = "", allegiance = "",
        scoreMethod = "POINTBUY",
        base = { STR = 8, DEX = 8, CON = 8, INT = 8, WIS = 8, CHA = 8 },
        bonus = { STR = 0, DEX = 0, CON = 0, INT = 0, WIS = 0, CHA = 0 },
        alignment = "",
        armor = "NONE", shield = false,
        weaponName = "Weapon", weaponStat = "STR", weaponSides = 8,
        -- An existing sheet (for example one converted from an older version) can keep its lists.
        keepLists = hasContent, hasContent = hasContent,
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
        if W.SkillsPicked() > class.skillCount then
            return ("Pick at most %d class skills."):format(class.skillCount)
        end
    elseif draft.step == 2 then
        if not R.SPECIES[draft.species] then return "Choose a species." end
        if not R.BACKGROUNDS[draft.background] then return "Choose a background." end
        if R.LINEAGES[draft.species] and draft.lineage == "" then return "Choose a lineage." end
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

    sheet.class, sheet.subclass, sheet.spec, sheet.level = draft.class, draft.subclass, draft.spec, draft.level
    sheet.species, sheet.size, sheet.background, sheet.alignment = draft.species, draft.size, draft.background, draft.alignment
    sheet.lineage, sheet.allegiance = draft.lineage, draft.allegiance
    sheet.scoreMethod = draft.scoreMethod
    sheet.base, sheet.bonus = CopyTable(draft.base), CopyTable(draft.bonus)
    sheet.armor, sheet.shield = draft.armor, draft.shield
    for skill, picked in pairs(draft.classSkills) do
        if picked then sheet.skills[skill] = 1 end
    end

    if draft.keepLists then
        sheet.resources, sheet.weapons = old.resources, old.weapons
        sheet.abilities, sheet.passives = old.abilities, old.passives
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
