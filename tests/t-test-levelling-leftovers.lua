-- Smaller levelling points: hit points that follow a larger maximum when class or
-- subclass change under Customize; a Fighting Style left empty asked for in the
-- choices dialog; the level dialog listing only the features that apply to the
-- character (a land beast's charge, a pet specialization's feature).
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local identity = T.Group("customize", "identity").args
local function Check(label, ok)
    T.checks = T.checks + 1
    if not ok then Problem(label) end
end
local function HP() return RPSheet:State().hp or RPSheet:MaxHP() end

---------------------------------------------------------------------------
-- Hit points after a change of class or subclass under Customize
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("MAGE", 1)
    for level = 2, 5 do T.TakeLevel(nil, nil, "mage " .. level) end
    RPSheet:State().hp = RPSheet:MaxHP() - 7
    local maxWas, hpWas = RPSheet:MaxHP(), HP()
    Try("class to warrior", identity.class.set, {}, "WARRIOR"); FlushTimers()
    local gained = RPSheet:MaxHP() - maxWas
    Check(("a larger hit die raised the maximum by only %d"):format(gained), gained > 0)
    Check(("changing class to a larger hit die: HP %d -> %d, the maximum grew by %d"):format(hpWas, HP(), gained), HP() == hpWas + gained)
    -- and back: the maximum shrinks, current HP only stop at it
    hpWas = HP()
    Try("class to mage", identity.class.set, {}, "MAGE"); FlushTimers()
    Check(("changing back: HP %d over the maximum %d"):format(HP(), RPSheet:MaxHP()), HP() <= RPSheet:MaxHP())
    Check("changing back healed", HP() <= hpWas)
    Check("the sheet isn't a mage again", sheet.class == "MAGE")
end
do
    -- Draconic Resilience: a subclass that raises the maximum by the class level
    T.NewCharacter("EVOKER", 2)
    for level = 2, 5 do T.TakeLevel(nil, nil, "evoker " .. level) end
    local subclass = RPSheet:Sheet().subclass
    Try("subclass none", identity.subclass.set, {}, ""); FlushTimers()
    RPSheet:State().hp = RPSheet:MaxHP() - 3
    local maxWas, hpWas = RPSheet:MaxHP(), HP()
    Try("subclass back", identity.subclass.set, {}, subclass); FlushTimers()
    local gained = RPSheet:MaxHP() - maxWas
    Check(("%s raised the maximum by %d, not 5"):format(subclass, gained), gained == 5)
    Check(("choosing %s: HP %d -> %d, the maximum grew by %d"):format(subclass, hpWas, HP(), gained), HP() == hpWas + gained)
    -- a typed subclass takes the features away: HP stop at the new maximum
    Try("typed subclass", identity.subclassText.set, {}, "Something else"); FlushTimers()
    Check("a smaller maximum left HP above it", HP() <= RPSheet:MaxHP())
end

---------------------------------------------------------------------------
-- A Fighting Style emptied under Customize is asked for with the other choices
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("WARRIOR", 3)
    for level = 2, 4 do T.TakeLevel(nil, { subclass = "Champion" }, "warrior " .. level) end
    local style = sheet.fightingStyle
    Check("a Warrior has no Fighting Style after the wizard", R.FIGHTING_STYLES[style] ~= nil)
    Try("empty the style", identity.fightingStyle.set, {}, ""); FlushTimers()
    Check("an empty Fighting Style isn't an open choice", ns.OpenClassChoices(sheet))
    local red = table.concat(T.RedLines(sheet), " ")
    Check("one red line names the empty Fighting Style, not two", red:find("Fighting Style to choose") and not red:find("choices to make"))
    Check("no choices button for it", T.Tab("classChoices")); FlushTimers()
    Check("the choices dialog didn't open", L.draft ~= nil)
    if L.draft then
        local _, byKey = T.Rows(levelRoot, "style")
        local row = byKey.openStyle1
        Check("the dialog doesn't ask for the Fighting Style", row and not row.option.hidden())
        Check("the dialog can be saved without a style", L.Problem() ~= nil)
        if row then
            local values = row.option.values()
            Check("the style picker doesn't offer the old style", values[style] ~= nil)
            T.Click(row, style)
        end
        Check("the dialog still refuses: " .. tostring(L.Problem()), L.Problem() == nil)
        T.Confirm()
        Check("the style picked in the dialog wasn't saved", sheet.fightingStyle == style)
        Check("nothing open after the dialog", not ns.OpenClassChoices(sheet))
    end
    -- A Champion's second style: both empty, one dialog, no style twice
    for level = 5, 7 do T.TakeLevel(nil, nil, "warrior " .. level) end
    Check("a Champion 7 has no second Fighting Style", ns.HasStyleSlot(sheet, 2))
    Try("empty style 1", identity.fightingStyle.set, {}, "")
    Try("empty style 2", identity.fightingStyle2.set, {}, ""); FlushTimers()
    ns.OpenLevelDialog(ns.LevelSlot(sheet, sheet.class, ns.ClassLevel(sheet, sheet.class)), false); FlushTimers()
    if L.draft then
        local _, byKey = T.Rows(levelRoot, "two styles")
        local first = byKey.openStyle1 and T.Candidates(byKey.openStyle1)[1]
        T.Click(byKey.openStyle1, first)
        local offered = byKey.openStyle2 and byKey.openStyle2.option.values() or {}
        Check("the second style offers the first one again", offered[first] == nil)
        T.Finish("two styles")
        Check("the two styles weren't both saved, or are the same", R.FIGHTING_STYLES[sheet.fightingStyle] and R.FIGHTING_STYLES[sheet.fightingStyle2]
            and sheet.fightingStyle ~= sheet.fightingStyle2)
    else
        Problem("the choices dialog didn't open for two styles")
    end
    T.CheckSettled("warrior styles", sheet)
end

---------------------------------------------------------------------------
-- What a level gives lists what applies to this character
---------------------------------------------------------------------------
do
    local function Gains(family)
        L.draft.subclass = "Beast Master"
        L.draft.options[R.PET_FEATURE] = family
        return L.Gains()
    end
    local sheet = T.NewCharacter("HUNTER", 4)
    T.TakeLevel(nil, nil, "hunter 2")
    ns.OpenLevelDialog(nil, false); FlushTimers()
    if L.draft then
        Check("a land beast's level 3 doesn't list the charge", Gains("Bear"):find("Beast's Strike: charge", 1, true) ~= nil)
        Check("a sea beast's level 3 lists the charge", Gains("Dolphin") and not Gains("Dolphin"):find("Beast's Strike: charge", 1, true))
        Check("the strike itself isn't listed for a sea beast", Gains("Dolphin"):find("Beast's Strike", 1, true) ~= nil)
        L.draft = nil
    else
        Problem("the hunter's level 3 dialog didn't open")
    end
    T.TakeLevel(nil, { subclass = "Beast Master" }, "hunter 3")
    sheet.featureOptions[R.PET_FEATURE] = "Bear" -- (the companion's family, as under Customize)
    Opt.Regrant()
    for level = 4, 5 do T.TakeLevel(nil, nil, "hunter " .. level) end
    Check("the pet isn't a bear", sheet.featureOptions[R.PET_FEATURE] == "Bear")
    ns.OpenLevelDialog(nil, false); FlushTimers()
    if L.draft then
        local text = L.Gains()
        Check("a Tenacity pet's level 6 doesn't list Stoneskin", text:find("Companion: Stoneskin", 1, true) ~= nil)
        Check("a Tenacity pet's level 6 lists Haste", not text:find("Companion: Haste", 1, true))
        L.draft = nil
    else
        Problem("the hunter's level 6 dialog didn't open")
    end
end

T.Summary("levelling leftovers")
