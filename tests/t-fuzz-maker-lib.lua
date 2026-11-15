-- The random-play tester's character maker: a "player" that goes through the
-- creation wizard and the level dialog by their options, as the dialog library
-- would, and makes every choice at random among what is offered.
local Z = FUZZ
local GREY = "|cff888888"

---------------------------------------------------------------------------
-- The level dialog
---------------------------------------------------------------------------
local function LevelRows()
    local rows = Z.Rows(Z.Options(ns.LevelDialog.DIALOG), "level")
    return rows, Z.ByKey(rows)
end

-- Improvement, feat or boon of the level.
local function DecideChoice(byKey)
    local L = ns.LevelDialog
    local draft = L.draft
    if not draft.kind or draft.fuzzDecided then return false end
    draft.fuzzDecided = true
    local want = "FEAT"
    if draft.kind == "ASI" and byKey.choice then
        want = Z.Pick({ "ASI", "FEAT", "FEAT" })
        Z.Set(byKey.choice, want)
    end
    if want == "FEAT" then
        local _, now = LevelRows()
        local names = now.featPick and Z.Candidates(now.featPick) or {}
        if #names == 0 then
            if byKey.choice then Z.Set(byKey.choice, "ASI") end
            return true
        end
        Z.Set(now.featPick, (Z.Pick(names)))
        local _, again = LevelRows()
        if again.featStat then
            -- the ability it raises: one the dialog accepts
            for _, stat in ipairs(Z.Shuffle(Z.Candidates(again.featStat))) do
                Z.Set(again.featStat, stat)
                if not ns.Levels.Problem(L.Sheet(), draft.level, draft.record) then break end
            end
        end
    end
    return true
end

-- One pass over the open dialog: fills what is empty. Returns the clicks made.
local function Sweep()
    local rows, byKey = LevelRows()
    if DecideChoice(byKey) then return 1 end
    local clicks = 0
    -- A list that holds more than it allows (after going back a level): some go.
    for _, group in ipairs(rows) do
        local have, limit = (group.kind == "group" and group.name or ""):match("%((%d+) of (%d+) chosen")
        have, limit = tonumber(have), tonumber(limit)
        if have and have > limit then
            for _, row in ipairs(Z.Shuffle(rows)) do
                if have > limit and row.parent == group.path and row.kind == "toggle" and row.current and Z.Set(row, false) then
                    have, clicks = have - 1, clicks + 1
                end
            end
        end
    end
    if clicks > 0 then return clicks end
    -- A case can say which tick boxes it wants (p.tick = "Starry Wisp, Guidance"):
    -- those come first, the rest in any order.
    local order, first = Z.Shuffle(rows), {}
    local wanted = "," .. tostring(Z.step.p.tick or ""):gsub("%s*,%s*", ",") .. ","
    for _, row in ipairs(order) do
        local plain = F.Plain(row.name or ""):gsub("%s*%(.*$", "")
        if row.kind == "toggle" and wanted:find("," .. plain .. ",", 1, true) then first[#first + 1] = row end
    end
    for _, row in ipairs(order) do first[#first + 1] = row end
    for _, row in ipairs(first) do
        -- (an earlier click of this pass may have changed what the row shows)
        local option, path = row.option, row.path
        if not Z.Member(option, "hidden", path) and not Z.Member(option, "disabled", path) then
            if row.kind == "select" and row.key ~= "choice" and row.key ~= "featPick" and row.key ~= "featStat" then
                local current = Z.Member(option, "get", path)
                if current == nil or current == "" then
                    row.values = Z.Member(option, "values", path) or {}
                    local names = Z.Candidates(row)
                    if #names > 0 and Z.Set(row, (Z.Pick(names))) then clicks = clicks + 1 end
                end
            elseif row.kind == "toggle" then
                local name = Z.Member(option, "name", path) or ""
                if not Z.Member(option, "get", path) and not name:find(GREY, 1, true) and Z.Set(row, true) then clicks = clicks + 1 end
            elseif row.kind == "range" and row.key:find("^asi") then
                local current = Z.Member(option, "get", path) or 0
                if option.max > current and Z.Set(row, option.max) then clicks = clicks + 1 end
            end
        end
    end
    return clicks
end

-- Fills the open level dialog and confirms it. Returns false when it can't be done
-- (the dialog is closed then, as with its Cancel).
function Z.FillLevelDialog(label)
    local L = ns.LevelDialog
    for _ = 1, 60 do
        local problem = Try(label .. " problem", L.Problem)
        if not problem then
            local _, byKey = LevelRows()
            if byKey.confirm and Z.Set(byKey.confirm) then
                F.Settle()
                return true
            end
            Z.Report("tester", label .. ": the level dialog has nothing missing but can't be confirmed")
            break
        end
        if Sweep() == 0 then
            Z.Report("tester", label .. ": the level dialog can't be completed: " .. tostring(problem))
            break
        end
    end
    Z.CloseLevelDialog()
    return false
end
function Z.CloseLevelDialog()
    local L = ns.LevelDialog
    L.draft = nil
    RPSheet:State().fuzzOpen = true -- a choice may now be waiting (t-fuzz-checks-lib.lua)
    Try("close level dialog", function() AceConfigDialog:Close(L.DIALOG) end)
    F.Settle()
end
-- The dialogs that open one after another (a feat's choices, the next open level).
function Z.FillLevelDialogs(label)
    for _ = 1, 30 do
        if not ns.LevelDialog.draft then return true end
        if not Z.FillLevelDialog(label) then return false end
    end
    Z.Report("tester", label .. ": level dialogs keep opening")
    Z.CloseLevelDialog()
    return false
end

---------------------------------------------------------------------------
-- The wizard
---------------------------------------------------------------------------
local function WizardRows()
    local rows = Z.Rows(Z.Options("RPSheetWizard"), "wizard")
    return rows, Z.ByKey(rows)
end
local function Put(key, value)
    local _, byKey = WizardRows()
    local row = byKey[key]
    if not row then return false end
    return Z.Set(row, value)
end
local function Next()
    local problem = W.StepProblem()
    if problem then
        Z.Report("tester", ("the wizard is stuck at step %d: %s"):format(W.draft.step, problem))
        return false
    end
    Put("next")
    F.Settle()
    return true
end
-- Every dropdown that is empty takes one of its choices.
local function FillEmpty(avoid, only)
    for _ = 1, 6 do
        local rows, changed = WizardRows(), false
        for _, row in ipairs(rows) do
            if row.kind == "select" and not row.disabled and (not only or row.key:find(only)) and not row.key:find("^moreClass")
                and (row.current == nil or row.current == "" or row.values[row.current] == nil) then
                local names = Z.Candidates(row, avoid)
                if #names > 0 and Z.Set(row, (Z.Choose(row.key, names))) then changed = true end
            end
        end
        if not changed then break end
    end
end

-- Point-buy scores of 27 points or fewer, the highest first.
local BUYS = { "15 14 13 12 10 8", "14 14 13 13 8 8", "15 15 15 8 8 8", "13 13 13 13 13 12", "14 13 13 13 12 10", "15 15 13 10 8 8" }

local function Make()
    if not W.draft then
        ns.OpenWizard()
        F.Settle()
    end
    local draft = W.draft
    -- Step 1: class and level, more classes, skills
    local key = Z.Choose("class", R.CLASS_ORDER)
    local class = R.CLASSES[key]
    Put("class", key)
    -- low levels and the highest come up more often than a flat draw gives
    local level = Z.Int("level", 1, 24)
    if level > 20 then level = ({ 1, 2, 3, 20 })[level - 20] end
    Put("level", level)
    if class.specs and class.specs[1] then Put("spec", (Z.Choose("spec", class.specs))) end
    local extras = level >= 2 and Z.Int("extras", 0, 4) or 0
    extras = extras > 2 and 0 or extras -- most characters have one class
    for index = 1, extras do
        local _, byKey = WizardRows()
        local row = byKey["moreClass" .. index]
        local names = row and Z.Candidates(row) or {}
        if #names == 0 then break end
        Z.Set(row, (Z.Choose("moreClass" .. index, names)))
        _, byKey = WizardRows()
        local slider = byKey["moreLevel" .. index]
        if slider then
            local most = math.max(1, draft.level - 1 - W.ExtraLevels(index))
            Z.Set(slider, Z.Int("moreLevel" .. index, 1, most))
        end
    end
    local background = Z.Choose("background", R.BACKGROUND_ORDER)
    local avoid = {}
    for _, skill in ipairs(R.BACKGROUNDS[background].skills) do avoid[skill] = true end
    -- subclasses and specializations of every class: any, also where one was pre-selected
    for _ = 1, 2 do
        local rows = WizardRows()
        for _, row in ipairs(rows) do
            if row.kind == "select" and not row.disabled and (row.key == "subclass" or row.key:find("^moreSubclass") or row.key:find("^moreSpec")) then
                local names = Z.Candidates(row)
                if #names > 0 then Z.Set(row, (Z.Choose(row.key, names))) end
            end
        end
    end
    local _, byKey = WizardRows()
    local open = {}
    for index, skill in ipairs(R.SKILLS) do
        local row = byKey["skill" .. index]
        if row and not row.disabled and not avoid[skill.name] and not row.current then open[#open + 1] = "skill" .. index end
    end
    for index = 1, class.skillCount - W.SkillsPicked() do
        local name = Z.Choose("classSkill" .. index, open)
        Put(name, true)
        for at, other in ipairs(open) do if other == name then table.remove(open, at) break end end
    end
    FillEmpty(avoid)
    if not Next() then return false end

    -- Step 2: species and background, and what they ask
    Put("species", (Z.Choose("species", R.SPECIES_ORDER)))
    Put("background", background)
    FillEmpty(avoid)
    if not Next() then return false end

    -- Step 3: scores. What the classes need at 13 gets the high ones.
    local need, order = {}, {}
    local function Needs(classKey)
        local rule = R.MULTICLASS[R.CLASSES[classKey].base]
        for _, stat in ipairs(rule and rule.primary or {}) do
            if not need[stat] then need[stat] = true; order[#order + 1] = stat end
        end
    end
    if #W.Extras() > 0 then
        Needs(draft.class)
        for _, extra in ipairs(W.Extras()) do Needs(extra.class) end
    end
    local needed = #order
    for _, stat in ipairs(Z.Shuffle(R.STATS)) do if not need[stat] then order[#order + 1] = stat end end
    local buys = {}
    for _, buy in ipairs(BUYS) do
        local high = 0
        for value in buy:gmatch("%d+") do if tonumber(value) >= 13 then high = high + 1 end end
        if high >= needed then buys[#buys + 1] = buy end
    end
    local values = {}
    for value in Z.Choose("scores", buys):gmatch("%d+") do values[#values + 1] = tonumber(value) end
    for index, stat in ipairs(order) do Put("score" .. stat, values[index]) end
    local allowed = {}
    for _, stat in ipairs(R.STATS) do if Opt.BackgroundAllows(background, stat) then allowed[#allowed + 1] = stat end end
    if Z.Flip("spread", 0.3) and #allowed >= 3 then
        for index = 1, 3 do Put("bonus" .. allowed[index], 1) end
    else
        local two = Z.Choose("plusTwo", allowed)
        Put("bonus" .. two, 2)
        local rest = {}
        for _, stat in ipairs(allowed) do if stat ~= two then rest[#rest + 1] = stat end end
        Put("bonus" .. Z.Choose("plusOne", rest), 1)
    end
    if not Next() then return false end

    -- Step 4: alignment and allegiance
    Put("alignment", (Z.Choose("alignment", R.ALIGNMENTS)))
    Put("allegiance", (Z.Choose("allegiance", R.ALLEGIANCE_ORDER)))
    if not Next() then return false end

    -- Step 5: gear or gold
    FillEmpty(nil, "^gearSet")
    if Z.Flip("classGear", 0.8) then Put("takeClassGear") end
    if Z.Flip("backgroundGear", 0.8) then Put("takeBackgroundGear") end
    F.Settle()
    FillEmpty(nil, "^gearChoice")
    F.Settle()
    if Z.Flip("closet", 0.3) then Try("open closet", W.OpenCloset) F.Settle() end
    if not Next() then return false end
    F.Settle()
    if W.draft then Z.Report("tester", "the wizard is still open after Create") return false end
    Z.FillLevelDialogs("after the wizard")
    return true
end

Z.Action("make", { run = function()
    if Make() then
        -- a new character: bound by the rules again, nothing left open
        local state = RPSheet:State()
        state.fuzzFree, state.fuzzOpen = nil, nil
    else
        -- left half done: closed as with "Not now"
        if W.draft then W.draft = nil; W.CloseCloset() end
        Try("close wizard", function() AceConfigDialog:Close("RPSheetWizard") end)
    end
    F.Settle()
end })

-- One line that says who the character is.
function Z.Describe()
    local sheet = RPSheet:Sheet()
    local parts = {}
    for _, key in ipairs(ns.ClassKeys(sheet)) do
        local view = ns.BaseView and ns.ClassView(sheet, key) or sheet
        parts[#parts + 1] = ("%s %d%s"):format(key, ns.ClassLevel(sheet, key), (view.subclass or "") ~= "" and (" (" .. view.subclass .. ")") or "")
    end
    return ("%s, level %d, %s, %s"):format(table.concat(parts, " + "), sheet.level, tostring(sheet.species), tostring(sheet.background))
end
