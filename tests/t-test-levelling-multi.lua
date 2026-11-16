-- Characters of two and three classes, taking levels in their classes in turn through
-- the level dialog up to level 20, with the sheet checked after each level. Then every
-- level's dialog is opened again, and the choices button, and nothing may be asked.
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local order = R.CLASS_ORDER
refused = 0
local function Run(keys, n)
    local label = table.concat(keys, "+")
    local sheet = T.NewCharacter(keys[1], n, true)
    if not sheet then return end
    local levels = { [keys[1]] = 1 }
    for level = 2, R.MAX_LEVEL do
        local key = keys[(level - 1) % #keys + 1]
        -- A hero class opens at character level 3: until then the dialog has to refuse.
        if not levels[key] and R.CLASSES[key].hero and level < R.HERO_START_LEVEL then
            ns.OpenLevelDialog(nil, false, key); FlushTimers()
            local problem = L.draft and L.Problem()
            if not (problem and problem:find("hero class")) then Problem(label .. ": a hero class at level " .. level .. " is not refused: " .. tostring(problem)) end
            local _, byKey = T.Rows(levelRoot, label)
            if T.Click(byKey.confirm) then Problem(label .. ": the refused level can be confirmed") end
            L.draft, refused = nil, refused + 1
            key = keys[1]
        end
        local step = ("%s %d (%s)"):format(label, level, key)
        if not T.TakeLevel(key, {}, step) then return end
        levels[key] = (levels[key] or 0) + 1
        T.Check(step, { level = level, classes = levels })
    end
    -- Looking again changes nothing and asks nothing.
    local before = RPSheet:ExportSheet()
    for index, slot in ipairs(ns.LevelSlots(sheet)) do
      if Levels.Kind(sheet, slot) or index % 4 == 0 then -- every level with a choice, and some without
        T.label = label .. " again " .. slot
        Try(T.label, ns.OpenLevelDialog, slot, false); FlushTimers()
        if not L.draft then Problem(T.label .. ": no dialog")
        else
            T.Rows(levelRoot, T.label)
            local problem = L.Problem()
            if problem then Problem(T.label .. ": asks: " .. problem) end
            T.Confirm()
            if L.draft then Problem(T.label .. ": another dialog opened"); L.draft = nil end
        end
      end
    end
    if RPSheet:ExportSheet() ~= before then Problem(label .. ": saving every level's dialog unchanged changed the sheet") end
    T.Check(label .. " after looking again", { level = R.MAX_LEVEL, classes = levels })
end
local n = 0
for i = 1, #order do
    local a, b = order[i], order[(i + 4) % #order + 1]
    n = n + 1
    Run({ a, b }, n)
end
for i = 1, #order do
    local a, b, c = order[i], order[(i + 2) % #order + 1], order[(i + 7) % #order + 1]
    n = n + 1
    local bases = { [R.CLASSES[a].base] = true, [R.CLASSES[b].base] = true, [R.CLASSES[c].base] = true }
    if T.Count(bases) == 3 and i % 2 == 1 then Run({ a, b, c }, n) end
end
print("hero classes refused below level 3: " .. refused)
T.Summary("multiclass levelling")
