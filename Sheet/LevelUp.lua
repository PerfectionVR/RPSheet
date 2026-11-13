-- Changing level: hands out what the new level grants, takes back what a lost level
-- gave, grows current HP and hit dice along with their maximums, and tells the player
-- what changed. The choices a level asks for are made in Options/LevelDialog.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Levels = ns.Levels

-- Names of everything on the sheet, to spot what a level added or removed.
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

-- Names in `after` that aren't in `before`, sorted.
local function Added(before, after)
    local names = {}
    for name in pairs(after) do
        if not before[name] then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

function RPSheet:SetLevel(level)
    local sheet, state = self:Sheet(), self:State()
    local old = sheet.level
    level = math.max(1, math.min(R.MAX_LEVEL, level))
    if level == old then return end

    local oldHP, oldBonus = self:MaxHP(), self:ProficiencyBonus()
    local oldNames, oldMaximums = FeatureNames(sheet), TrackerMaximums(self)

    sheet.level = level
    -- Going down: the choices of the lost levels are undone, and a subclass is given
    -- up below the level it is chosen at.
    Levels.Trim(sheet)
    if level < R.SUBCLASS_LEVEL and old >= R.SUBCLASS_LEVEL then sheet.subclass = "" end
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
    local changed, newMaximums = {}, TrackerMaximums(self)
    for _, tracker in ipairs(self:GetTrackers()) do
        local before = oldMaximums[tracker.label]
        if tracker.kind ~= "hp" and tracker.kind ~= "hitdice" and before ~= tracker.max then
            changed[#changed + 1] = ("%s %d -> %d"):format(tracker.label, before or 0, tracker.max)
        end
    end
    for label, before in pairs(oldMaximums) do
        if not newMaximums[label] then changed[#changed + 1] = ("%s %d -> 0"):format(label, before) end
    end
    table.sort(changed)
    if #changed > 0 then lines[#lines + 1] = table.concat(changed, ", ") .. "." end
    local newNames = FeatureNames(sheet)
    local gained, lost = Added(oldNames, newNames), Added(newNames, oldNames)
    if #gained > 0 then lines[#lines + 1] = "New: " .. table.concat(gained, ", ") .. "." end
    if #lost > 0 then lines[#lines + 1] = "Lost: " .. table.concat(lost, ", ") .. "." end

    local pending = Levels.Pending(sheet)
    if #pending > 0 then
        lines[#lines + 1] = ("Choices are waiting on the Character tab for level %s."):format(table.concat(pending, ", "))
    end
    if level >= R.SUBCLASS_LEVEL and sheet.subclass == "" and self:ClassData() then
        lines[#lines + 1] = "You can choose a subclass on the Character tab."
    end
    self:Print(table.concat(lines, " "))
end

-- Back one level. Everything that level gave is taken off the sheet again.
function RPSheet:LevelDown()
    self:SetLevel(self:Level() - 1)
end
