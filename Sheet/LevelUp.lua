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

-- Sets the character's level. The levels gained or lost are those of `classKey`: the
-- first class when it is left out, one of the character's other classes, or a class
-- it doesn't have yet, which is then added (Sheet/Classes.lua). Losing the last level
-- of a later class removes that class; the first class always keeps one level.
-- `with` may carry what the level dialog picked for a class's first level:
-- { subclass =, skill = }.
function RPSheet:SetLevel(level, classKey, with)
    local sheet, state = self:Sheet(), self:State()
    local old = sheet.level
    level = math.max(1, math.min(R.MAX_LEVEL, level))
    local key = (R.CLASSES[classKey] and R.CLASSES[sheet.class]) and classKey or sheet.class
    local first = key == sheet.class
    local oldClass = ns.ClassLevel(sheet, key) -- 0 for a class it doesn't have yet
    level = old + math.max(level - old, (first and 1 or 0) - oldClass)
    if level == old then return end

    local oldHP, oldBonus = self:MaxHP(), self:ProficiencyBonus()
    local oldNames, oldMaximums = FeatureNames(sheet), TrackerMaximums(self)
    local oldDice = {}
    for _, dice in ipairs(ns.HitDice(sheet)) do oldDice[dice.sides] = dice.count end

    local class = R.CLASSES[key]
    local newClass = oldClass + level - old
    if not first then
        if type(sheet.classes) ~= "table" then sheet.classes = {} end
        if newClass <= 0 then
            sheet.classes[key] = nil
        elseif ns.ClassEntry(sheet, key) then
            sheet.classes[key].level = newClass
        else
            -- A hero class comes with its subclass from the start.
            sheet.classes[key] = { level = newClass, subclass = class.hero and class.subclasses[1] or "", spec = "", skill = "" }
        end
        local entry = ns.ClassEntry(sheet, key)
        if entry and with and with.subclass then entry.subclass = with.subclass end
        if entry and with and (with.skill or "") ~= "" then entry.skill = with.skill end
    end
    sheet.level = level
    -- Remembered for going back a level; only a character of several classes needs it.
    sheet.lastClass = (level > old and ns.IsMulticlass(sheet)) and key or ""
    -- Going down: the choices of the lost levels are undone, and a subclass is given
    -- up below the level of its class it is chosen at.
    Levels.Trim(sheet)
    -- A hero class keeps its subclass: it is fixed when the character is made.
    if newClass > 0 and newClass < R.SUBCLASS_LEVEL and oldClass >= R.SUBCLASS_LEVEL and not (class and class.hero) then
        ns.SetSubclass(sheet, key, "")
    end
    ns.ApplyGrants(sheet)
    ns.NormalizeState(state)

    -- Going up, current HP and hit dice grow by what was gained. Going down they are
    -- only capped by the new maximums.
    if level > old then
        state.hp = (state.hp or oldHP) + math.max(0, self:MaxHP() - oldHP)
        for _, tracker in ipairs(self:GetTrackers()) do
            if tracker.kind == "hitdice" then
                local before = oldDice[tracker.sides] or 0
                tracker.set((tracker.get() or before) + math.max(0, tracker.max - before))
            end
        end
    end
    self:ClampState()

    -- Tell the player what the change did.
    local lines = { ("Level %d -> %d."):format(old, level) }
    if class and (not first or ns.IsMulticlass(sheet)) then
        lines[#lines + 1] = ("%s %d -> %d."):format(class.name, oldClass, math.max(0, newClass))
    end
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
    if #pending > 0 and ns.IsMulticlass(sheet) then
        local names = {}
        for _, slot in ipairs(pending) do names[#names + 1] = ns.SlotLabel(sheet, slot) end
        lines[#lines + 1] = ("Choices are waiting on the Character tab for %s."):format(table.concat(names, ", "))
    elseif #pending > 0 then
        lines[#lines + 1] = ("Choices are waiting on the Character tab for level %s."):format(table.concat(pending, ", "))
    end
    for _, view in ipairs(ns.ClassViews(sheet)) do
        if view.level >= R.SUBCLASS_LEVEL and view.subclass == "" and R.CLASSES[view.class] then
            lines[#lines + 1] = "You can choose a subclass under Customize, Class and origin."
            break
        end
    end
    self:Print(table.concat(lines, " "))
end

-- The class a level is taken from when going back one: the class the last level was
-- taken in while that is known, else the last of the later classes.
function ns.LevelDownClass(sheet)
    local extras = ns.ExtraClassKeys(sheet)
    if #extras == 0 then return sheet.class end
    local last = sheet.lastClass
    if last == sheet.class and ns.ClassLevel(sheet, last) > 1 then return last end
    if ns.ClassEntry(sheet, last) then return last end
    return extras[#extras]
end

-- Back one level. Everything that level gave is taken off the sheet again.
-- `classKey` names the class that loses it; left out, see ns.LevelDownClass.
function RPSheet:LevelDown(classKey)
    self:SetLevel(self:Level() - 1, classKey or ns.LevelDownClass(self:Sheet()))
end
