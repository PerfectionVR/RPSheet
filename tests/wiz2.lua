NUM_CHAT_WINDOWS = 10
dofile(ARG3 .. "/sim.lua")
Start()
root = REGISTRY:GetOptionsTable("RPSheetWizard")("dialog", "AceConfigDialog-3.0")
local VERBOSE = ARG4 == "v"

function Find(key, group)
    group = group or root
    for k, option in pairs(group.args) do
        if k == key then return option end
        if option.type == "group" then
            local found = Find(key, option)
            if found then return found end
        end
    end
end
function Set(key, value)
    local option = Find(key)
    if not option then Problem("no option " .. key) return end
    Try("set " .. key, option.set, { key, option = option }, value)
end
function Press(key)
    local option = Find(key)
    Try("press " .. key, option.func, { key, option = option })
    FlushTimers()
end
function Shown(label)
    local out = Try("feed " .. label, Feed, root, "wizard")
    local byKey = {}
    for _, row in ipairs(out or {}) do
        byKey[row.path:match("[^.]+$")] = row
        if row.stray ~= nil and label:find("done$") then Problem(label .. ": " .. row.path .. " shows " .. tostring(row.stray) .. ", not one of its values") end
    end
    return byKey, out
end
function Next(label)
    local problem = W.StepProblem()
    if problem then Problem(label .. ": step " .. W.draft.step .. " stuck: " .. problem) return false end
    Press("next")
    return true
end

-- Makes a character. spec: { class, level, extras = { { class, level } }, species index, background index }
function Make(spec)
    local label = spec.label
    ns.OpenWizard(); FlushTimers()
    local draft = W.draft
    Shown(label .. " empty")
    Set("class", spec.class)
    Set("level", spec.level)
    local class = R.CLASSES[spec.class]
    local shown = Shown(label .. " class")
    -- specialization first: it pre-selects
    if class.specs and class.specs[1] then Set("spec", class.specs[((spec.n or 1) - 1) % #class.specs + 1]) end
    for index, extra in ipairs(spec.extras or {}) do
        Set("moreClass" .. index, extra.class)
        Set("moreLevel" .. index, extra.level)
        shown = Shown(label .. " extra " .. index)
        local picker = shown["moreSpec" .. index]
        if picker then for k in pairs(picker.values) do if k ~= "" then Set("moreSpec" .. index, k) break end end end
        shown = Shown(label .. " extra spec " .. index)
        picker = shown["moreSubclass" .. index]
        if picker and (picker.current or "") == "" then for k in pairs(picker.values) do if k ~= "" then Set("moreSubclass" .. index, k) break end end end
    end
    shown = Shown(label .. " class 2")
    if shown.subclass and (shown.subclass.current or "") == "" then
        for k in pairs(shown.subclass.values) do if k ~= "" then Set("subclass", k) break end end
    end
    -- background first in mind: avoid its skills
    local background = R.BACKGROUNDS[spec.background]
    local avoid = {}
    for _, skill in ipairs(background.skills) do avoid[skill] = true end
    local picked = 0
    for index, skill in ipairs(R.SKILLS) do
        local row = shown["skill" .. index]
        if row and not avoid[skill.name] and picked < class.skillCount then
            Set("skill" .. index, true); picked = picked + 1
        end
    end
    -- styles and the other classes' skills: take the first choice offered, repeatedly
    for pass = 1, 6 do
        shown = Shown(label .. " class 3")
        for key, row in pairs(shown) do
            if row.option.type == "select" and (key:find("[sS]tyle") or key:find("^moreSkill")) and (row.current or "") == "" or row.stray then
                local names = {}
                for k in pairs(row.values) do if k ~= "" and not avoid[k] then names[#names + 1] = k end end
                table.sort(names)
                if names[1] then Set(key, names[1]) end
            end
        end
    end
    Shown(label .. " class done")
    if not Next(label) then return end

    Set("species", spec.species)
    Set("background", spec.background)
    for pass = 1, 4 do
        shown = Shown(label .. " origin")
        for key, row in pairs(shown) do
            if row.option.type == "select" and row.current == nil or row.current == "" then
                local names = {}
                for k in pairs(row.values or {}) do if k ~= "" then names[#names + 1] = k end end
                table.sort(names)
                if names[1] then Set(key, names[(spec.n or 1) % #names + 1]) end
            end
        end
    end
    Shown(label .. " origin done")
    if not Next(label) then return end

    -- scores: what the classes need at 13 gets the high scores
    local need, order = {}, {}
    local function Needs(key)
        local rule = R.MULTICLASS[R.CLASSES[key].base]
        for _, stat in ipairs(rule and rule.primary or {}) do
            if not need[stat] then need[stat] = true; order[#order + 1] = stat end
        end
    end
    Needs(spec.class)
    for _, extra in ipairs(spec.extras or {}) do Needs(extra.class) end
    for _, stat in ipairs(R.STATS) do if not need[stat] then order[#order + 1] = stat end end
    shown = Shown(label .. " scores")
    local buy = { 14, 14, 13, 13, 8, 8 } -- 7+7+5+5 = 24 points
    for index, stat in ipairs(order) do Set("score" .. stat, buy[index]) end
    local left = { 2, 1 }
    for _, stat in ipairs(R.STATS) do
        if Opt.BackgroundAllows(spec.background, stat) and left[1] then Set("bonus" .. stat, table.remove(left, 1)) end
    end
    Shown(label .. " scores done")
    if not Next(label) then return end

    shown = Shown(label .. " alignment")
    Set("alignment", R.ALIGNMENTS[1])
    Set("allegiance", R.ALLEGIANCE_ORDER[(spec.n or 1) % #R.ALLEGIANCE_ORDER + 1])
    if not Next(label) then return end

    shown = Shown(label .. " details")
    if shown.gearSet then Set("gearSet", (spec.n or 1) % 2 + 1) end
    Press("takeClassGear")
    Press("takeBackgroundGear")
    for pass = 1, 2 do
        shown = Shown(label .. " gear")
        for key, row in pairs(shown) do
            if key:find("^gearChoice") and (row.current or "") == "" then
                local names = {}
                for k in pairs(row.values) do if k ~= "" then names[#names + 1] = k end end
                table.sort(names)
                Set(key, names[1]); FlushTimers()
            end
        end
    end
    Try(label .. " open closet", W.OpenCloset)
    shown = Shown(label .. " details done")
    if VERBOSE then
        print(label, "gold", draft.gold, "note", (draft.gearNote or ""):gsub("\n", " / "))
    end
    local closet = CopyTable(draft.closet)
    if not Next(label) then return end
    FlushTimers()
    if W.draft then Problem(label .. ": draft still there after Create") end
    local sheet = RPSheet:Sheet()
    if sheet.class ~= spec.class or sheet.level ~= spec.level then Problem(label .. ": sheet has " .. tostring(sheet.class) .. " " .. tostring(sheet.level)) end
    return sheet, closet
end
