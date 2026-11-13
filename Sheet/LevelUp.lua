-- Changing level: hands out what the new level grants, grows current HP and hit dice
-- along with their maximums, and tells the player what changed.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Levels at which the class grants an Ability Score Improvement (or a feat instead).
local function ImprovementLevels(class)
    local levels = {}
    for _, level in ipairs(R.ASI_LEVELS) do levels[#levels + 1] = level end
    for _, level in ipairs(class and class.asiLevels or {}) do levels[#levels + 1] = level end
    return levels
end

-- Points from Ability Score Improvements reached so far: 2 per improvement.
function RPSheet:ImprovementPoints()
    local count = 0
    for _, level in ipairs(ImprovementLevels(self:ClassData())) do
        if self:Level() >= level then count = count + 1 end
    end
    return count * R.ASI_POINTS
end

function RPSheet:ImprovementSpent()
    local total = 0
    for _, stat in ipairs(R.STATS) do
        total = total + (self:Sheet().asi[stat] or 0)
    end
    return total
end

-- Names of everything on the sheet, to spot what a level added.
local function FeatureNames(sheet)
    local names = {}
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for _, entry in ipairs(list) do names[entry.name] = true end
    end
    return names
end

local function TrackerMaximums(self)
    local maximums = {}
    for _, tracker in ipairs(self:GetTrackers()) do maximums[tracker.label] = tracker.max end
    return maximums
end

function RPSheet:SetLevel(level)
    local sheet, state = self:Sheet(), self:State()
    local old = sheet.level
    if level == old then return end

    local oldHP, oldBonus = self:MaxHP(), self:ProficiencyBonus()
    local oldNames, oldMaximums, oldPoints = FeatureNames(sheet), TrackerMaximums(self), self:ImprovementPoints()

    sheet.level = level
    ns.ApplyGrants(sheet)
    ns.NormalizeState(state)

    -- Going up, current HP and hit dice grow by what was gained. Going down they are
    -- only capped by the new maximums.
    if level > old then
        state.hp = (state.hp or oldHP) + math.max(0, self:MaxHP() - oldHP)
        state.hitDice = (state.hitDice or old) + (level - old)
    end
    self:ClampState()

    -- Tell the player what the change did.
    local lines = { ("Level %d -> %d."):format(old, level) }
    if self:MaxHP() ~= oldHP then
        lines[#lines + 1] = ("Maximum HP %d -> %d."):format(oldHP, self:MaxHP())
    end
    if self:ProficiencyBonus() ~= oldBonus then
        lines[#lines + 1] = ("Proficiency bonus +%d -> +%d."):format(oldBonus, self:ProficiencyBonus())
    end
    local changed = {}
    for _, tracker in ipairs(self:GetTrackers()) do
        local before = oldMaximums[tracker.label]
        if tracker.kind ~= "hp" and tracker.kind ~= "hitdice" and before ~= tracker.max then
            changed[#changed + 1] = ("%s %d -> %d"):format(tracker.label, before or 0, tracker.max)
        end
    end
    if #changed > 0 then lines[#lines + 1] = table.concat(changed, ", ") .. "." end
    local gained = {}
    for name in pairs(FeatureNames(sheet)) do
        if not oldNames[name] then gained[#gained + 1] = name end
    end
    table.sort(gained)
    if #gained > 0 then lines[#lines + 1] = "New: " .. table.concat(gained, ", ") .. "." end

    local unspent = self:ImprovementPoints() - self:ImprovementSpent()
    if self:ImprovementPoints() > oldPoints or (level > old and unspent > 0) then
        lines[#lines + 1] = ("You have %d ability score points to place on the Ability scores tab (or take a feat instead)."):format(unspent)
    end
    if level >= R.SUBCLASS_LEVEL and old < R.SUBCLASS_LEVEL and sheet.subclass == "" and self:ClassData() then
        lines[#lines + 1] = "You can now choose a subclass on the Character tab."
    end
    self:Print(table.concat(lines, " "))
end
