-- Two points of the creation wizard: the background's points can't lift a score set
-- by hand above 20, and two classes whose specializations suggest the same Fighting
-- Style don't both end up with it (and with two blank dropdowns).
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local function Rows() return select(2, T.Rows(root, "wizard")) end

-- Scores set by hand, with the background's points on top.
do
    ns.OpenWizard(); FlushTimers()
    Set("class", "WARRIOR")
    local background, stat
    for _, key in ipairs(R.BACKGROUND_ORDER) do
        if not background then background, stat = key, R.BACKGROUNDS[key].stats[1] end
    end
    W.draft.background = background
    W.draft.step = 3
    Set("method", "MANUAL")
    if not T.Click(Rows()["score" .. stat], 20) then Problem("scores: a score can't be set to 20 by hand") end
    for points = 1, 2 do
        if T.Click(Rows()["bonus" .. stat], points) then Problem(("scores: %d background points go on a score of 20"):format(points)) end
    end
    T.Click(Rows()["score" .. stat], 19)
    if not T.Click(Rows()["bonus" .. stat], 1) then Problem("scores: a score of 19 can't take one background point") end
    if T.Click(Rows()["bonus" .. stat], 2) then Problem("scores: a score of 19 takes two background points") end
    if T.Click(Rows()["score" .. stat], 20) then Problem("scores: a score with a background point can be set to 20") end
    for _, other in ipairs(R.STATS) do
        if W.draft.base[other] + W.draft.bonus[other] > R.MAX_SCORE then Problem("scores: " .. other .. " is " .. W.draft.base[other] + W.draft.bonus[other]) end
    end
    -- point buy is as it was: 15 and two points
    Set("method", "POINTBUY")
    W.draft.bonus[stat] = 0
    if not T.Click(Rows()["score" .. stat], 15) or not T.Click(Rows()["bonus" .. stat], 2) then Problem("scores: point buy 15 + 2 is refused") end
    W.draft = nil
end

-- The same Fighting Style suggested for two classes.
local function Styles(label, firstSpecLast)
    ns.OpenWizard(); FlushTimers()
    Set("class", "WARRIOR")
    Set("level", 6)
    if not firstSpecLast then Set("spec", "Arms") end
    Set("moreClass1", "PALADIN")
    Set("moreLevel1", 2)
    Set("moreSpec1", "Retribution")
    if firstSpecLast then Set("spec", "Arms") end
    local shown = Shown(label)
    local draft = W.draft
    local row = draft.classes[1]
    if R.SpecGuide("WARRIOR", "Arms").style ~= R.SpecGuide("PALADIN", "Retribution").style then Problem(label .. ": the two specializations no longer suggest the same style") end
    if draft.fightingStyle ~= "" and draft.fightingStyle == row.fightingStyle then Problem(label .. ": both classes were given " .. draft.fightingStyle) end
    if draft.fightingStyle == "" and row.fightingStyle == "" then Problem(label .. ": neither class was given the suggested style") end
    local blank = 0
    for key, each in pairs(shown) do
        if key:find("[sS]tyle") and each.option.type == "select" then
            if each.stray then Problem(("%s: %s shows %s, which is not one of its choices"):format(label, key, tostring(each.stray))) end
            if (each.current or "") == "" then blank = blank + 1 end
        end
    end
    if blank ~= 1 then Problem(label .. ": " .. blank .. " style dropdowns are empty, expected the one still to choose") end
    local problem = W.StyleProblem()
    if not problem or not problem:find("Choose a Fighting Style for") then Problem(label .. ": the wizard doesn't ask for the missing style: " .. tostring(problem)) end
    -- both forced to the same style (a level raised later): the first keeps it
    draft.fightingStyle, row.fightingStyle = "Defense", "Defense"
    shown = Shown(label .. " same")
    if shown.fightingStyle.stray then Problem(label .. ": with the same style on both, the first class's dropdown is blank as well") end
    problem = W.StyleProblem()
    if not problem or not problem:find("Paladin") then Problem(label .. ": with the same style on both, the wizard doesn't ask the later class again: " .. tostring(problem)) end
    W.draft = nil
end
Styles("styles", false)
Styles("styles, first class's specialization last", true)
T.Summary("wizard: scores by hand and shared Fighting Styles")
