-- Tries to break each rule of the level dialog. Every attempt has to be refused: the
-- option can't be clicked (hidden or greyed out), or L.Problem names what is wrong and
-- the confirm button stays greyed out. After each attempt the dialog is completed
-- properly and the sheet checked.
dofile(ARG3 .. "/t-test-levelling-lib.lua")
dofile(ARG3 .. "/t-test-levelling-codec.lua")
local refused = 0

local function Open(classKey, label)
    T.label = label
    Try(label .. " open", ns.OpenLevelDialog, nil, false, classKey); FlushTimers()
    if not L.draft then Problem(label .. ": the dialog didn't open") return false end
    return true
end
local function Row(key)
    local rows, byKey = T.Rows(levelRoot, T.label)
    return byKey[key], rows, byKey
end
-- The dialog has to say `pattern` and keep the confirm button greyed out.
local function Refused(what, pattern)
    local problem = L.Problem()
    local confirm = Row("confirm")
    if not problem or not problem:find(pattern) then
        Problem(("%s: %s is not refused (the dialog says: %s)"):format(T.label, what, tostring(problem)))
    elseif T.Click(confirm) then
        Problem(("%s: %s: the dialog names the problem but can be confirmed"):format(T.label, what))
    else
        refused = refused + 1
    end
    if not L.draft then Open(nil, T.label) end
end
-- A click that must not be possible.
local function NoClick(what, key, value)
    local row = Row(key)
    if row and T.Click(row, value) then Problem(("%s: %s can be clicked"):format(T.label, what)) else refused = refused + 1 end
end
local function Toggles(groupKey)
    local _, rows = Row("confirm")
    local out = {}
    for _, row in ipairs(rows) do
        if row.parent == "level." .. groupKey and row.option.type == "toggle" then out[#out + 1] = row end
    end
    return out
end
local function Plain(text) return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function Done(label, plan)
    T.label = label
    if L.draft and L.draft.kind then L.draft.decided = L.draft.decided or (plan and plan.keepChoice) end
    if T.Fill(plan or {}) and T.Confirm() then T.Finish(label .. " follow-up") end
    L.draft = nil
    T.Check(label)
end
local function To(level, plan)
    while RPSheet:Sheet().level < level do
        if not T.TakeLevel(nil, plan or {}) then return false end
    end
    return true
end

---------------------------------------------------------------------------
-- Ability Score Improvement
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("WARRIOR", 1)
    To(3, { subclass = "Champion" })
    Open(nil, "ASI")
    if L.draft.kind ~= "ASI" then Problem("level 4 has no Ability Score Improvement") end
    Refused("no points placed", "Place 2 ability score points")
    T.Click(Row("asiSTR"), 1)
    Refused("one point placed", "Place 2 ability score points")
    NoClick("three points on one ability", "asiSTR", 3)
    T.Click(Row("asiSTR"), 2)
    NoClick("a third point on another ability", "asiDEX", 1)
    -- the slider bypassed: the check itself has to hold
    L.draft.record.asi.DEX = 1
    Refused("three points placed behind the slider's back", "Place 2 ability score points")
    L.draft.record.asi.DEX = nil
    -- a score at 19 takes one point, a score at 20 none
    local was = sheet.base.STR
    sheet.base.STR = 19 - (sheet.bonus.STR or 0); L.draft.like = nil
    L.draft.record.asi = {}
    NoClick("two points on a score of 19", "asiSTR", 2)
    L.draft.record.asi.STR = 2
    Refused("a score raised to 21", "can't go above 20")
    sheet.base.STR = 20 - (sheet.bonus.STR or 0)
    L.draft.record.asi = {}
    NoClick("a point on a score of 20", "asiSTR", 1)
    sheet.base.STR = was
    -- a feat: none named, one it has, one it can't take, a +1 too many
    T.Click(Row("choice"), "FEAT")
    Refused("no feat named", "Name the feat")
    local origin = R.BACKGROUNDS[sheet.background].feat
    if R.FEATS[origin] and not R.FEATS[origin].repeatable then
        T.Click(Row("featPick"), origin)
        Refused("the origin feat a second time", "already have it")
        T.Click(Row("featPick"), "")
        T.Click(Row("feat"), origin)
        Refused("the origin feat typed by hand", "already have it")
    end
    local greyed
    for name, text in pairs(Row("featPick").option.values()) do
        if text:find("needs", 1, true) then greyed = name end
    end
    if greyed then
        T.Click(Row("featPick"), greyed)
        Refused("a feat whose prerequisite isn't met (" .. greyed .. ")", "You can't take")
    else
        Problem("ASI: no feat is greyed out for a level 4 Warrior")
    end
    T.Click(Row("featPick"), "Spell Sniper")
    Refused("a spellcaster's feat for a Warrior", "needs a spellcasting class")
    T.Click(Row("featPick"), "Boon of Fortitude")
    if Row("featPick").option.get() == "Boon of Fortitude" then Problem("ASI: an Epic Boon can be picked at level 4") else refused = refused + 1 end
    T.Click(Row("featPick"), "Athlete")
    L.draft.record.asi = { STR = 1, DEX = 1 }
    Refused("a feat raising two abilities", "one ability by 1 at most")
    L.draft.record.asi = {}
    NoClick("an ability the feat doesn't raise", "featStat", "CHA")
    -- Resilient: a save the class already gives
    T.Click(Row("featPick"), "Resilient")
    Refused("Resilient without an ability", "Choose the ability")
    T.Click(Row("featStat"), "STR")
    Refused("Resilient for a save the class gives", "already proficient")
    T.Click(Row("featStat"), "WIS")
    if L.Problem() then Problem("ASI: Resilient (Wisdom) is refused: " .. L.Problem()) end
    Done("ASI done", { keepChoice = true })
    if not sheet.saves.WIS then Problem("Resilient (Wisdom) gave no saving throw proficiency") end
    if not T.HasEntry(sheet, "Resilient") then Problem("Resilient is not on the sheet") end
    -- Cancel changes nothing
    local before = RPSheet:ExportSheet()
    Open(nil, "cancel")
    for _, row in ipairs(select(2, Row("confirm"))) do
        if row.option.type == "toggle" then T.Click(row, not row.option.get()) end
    end
    T.Click(Row("cancel")); FlushTimers()
    if L.draft then Problem("cancel: the dialog is still open") L.draft = nil end
    if RPSheet:ExportSheet() ~= before then Problem("cancel: the sheet changed") end
    if sheet.level ~= 4 then Problem("cancel: the level was taken") end
    -- a feat with choices of its own: asked in the same dialog
    To(7, {})
    Open(nil, "feat choices")
    T.Click(Row("choice"), "FEAT")
    T.Click(Row("featPick"), "Weapon Master")
    T.Click(Row("featStat"), "STR")
    Refused("a feat's own choice left open", "Weapon Master has a choice to make")
    local pick = Row("pick1") or select(3, Row("confirm")).pick1
    Done("feat choices done", { keepChoice = true })
    local found
    for _, instance in ipairs(ns.FeatInstances(sheet)) do
        if instance.name == "Weapon Master" then found = sheet.featChoices[instance.id] end
    end
    if not found or not next(found.picks) then Problem("Weapon Master: the weapon chosen in the dialog wasn't kept") end
    -- Epic Boon
    To(18, {})
    Open(nil, "boon")
    if L.draft.kind ~= "BOON" then Problem("level 19 has no Epic Boon") end
    Refused("no boon named", "Name the Epic Boon")
    if Row("choice") then Problem("boon: an Ability Score Improvement is offered in place of the boon") end
    T.Click(Row("featPick"), "Alert")
    if L.draft.record.feat == "Alert" then Problem("boon: a general feat can be picked as the Epic Boon") else refused = refused + 1 end
    Done("boon done")
    To(20, {})
    -- the highest level
    if T.Tab("levelUp") then Problem("level 20: the level button can still be pressed") else refused = refused + 1 end
    ns.OpenLevelDialog(); FlushTimers()
    if L.draft then Problem("level 20: the dialog opens for level 21") L.draft = nil else refused = refused + 1 end
end

---------------------------------------------------------------------------
-- Subclass, Fighting Style, maneuvers, the feature's tool and skill
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("WARRIOR", 2)
    To(2, {})
    Open(nil, "subclass")
    T.Click(Row("subclass"), "")
    Refused("no subclass at level 3", "Choose a subclass")
    NoClick("a subclass of another class", "subclass", "Assassin")
    T.Click(Row("subclass"), "Battle Master")
    Refused("the Battle Master's tool left open", "Choose 1 Artisan's tools")
    for _, row in ipairs(Toggles("picks" .. R.TOOL_PICK_LIST)) do
        if T.Click(row, true) then break end
    end
    Refused("no maneuvers", "Choose 3 maneuvers")
    local toggles = Toggles("maneuvers")
    for index = 1, 3 do T.Click(toggles[index], true) end
    if T.Click(toggles[4], true) then Problem("subclass: a fourth maneuver can be ticked at level 3") else refused = refused + 1 end
    T.Click(toggles[1], false)
    Refused("two maneuvers of three", "Choose 3 maneuvers")
    Done("subclass done", { subclass = "Battle Master" })
    if sheet.subclass ~= "Battle Master" then Problem("subclass: " .. tostring(sheet.subclass)) end
    if ns.SheetPickLimit(sheet, R.TOOL_PICK_LIST) ~= 1 or ns.PicksKnown(sheet, R.TOOL_PICK_LIST) ~= 1 then Problem("Student of War: no tool picked") end
    if #ns.SkillChoiceFeatures(sheet) == 0 then Problem("Student of War: no skill to pick") end
    for name, skill in pairs(sheet.featureSkills) do
        if (sheet.skills[skill] or 0) < 1 then Problem("Student of War: " .. skill .. " isn't proficient") end
    end
end
do
    local sheet = T.NewCharacter("PALADIN", 3)
    Open(nil, "style")
    if not L.StyleSlot() then Problem("a Paladin's level 2 opens no Fighting Style")
    else
        T.Fill({})
        T.Click(Row("style"), "")
        Refused("no Fighting Style", "Choose a Fighting Style")
        NoClick("a style that isn't one", "style", "Rage")
    end
    Done("style done")
    if not R.FIGHTING_STYLES[sheet.fightingStyle] then Problem("style: none on the sheet") end
end

---------------------------------------------------------------------------
-- Pick lists: counts, levels, prerequisites
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("WARLOCK", 4)
    Open(nil, "invocations")
    Refused("invocations left open", "Choose 3 Eldritch Invocations")
    local function Find(name)
        for _, row in ipairs(Toggles("picksinvocations")) do
            if Plain(Val and row.name or row.name):sub(1, #name) == name then return row end
        end
    end
    for _, name in ipairs({ "Thirsting Blade", "Eldritch Smite", "Witch Sight", "Devouring Blade" }) do
        local row = Find(name)
        if row and T.Click(row, true) then Problem("invocations: " .. name .. " can be ticked at level 2") else refused = refused + 1 end
    end
    local second = Find("Agonizing Blast (second)")
    if second and T.Click(second, true) then Problem("invocations: Agonizing Blast (second) without the first") else refused = refused + 1 end
    -- at the limit the rest grey out
    local count = 0
    for _, row in ipairs(Toggles("picksinvocations")) do
        if not row.option.get() and T.Click(row, true) then count = count + 1 end
    end
    if L.PicksChosen("invocations") ~= 3 then Problem("invocations: " .. L.PicksChosen("invocations") .. " ticked, limit 3") end
    Done("invocations done")
    To(4, {})
    -- level 5: Thirsting Blade needs Pact of the Blade; dropping the pact drops it
    Open(nil, "prerequisite")
    local pact, thirsting = Find("Pact of the Blade"), Find("Thirsting Blade")
    if not pact.option.get() then
        -- make room: give up one earlier invocation (the one exchange), then take the pact
        for _, row in ipairs(Toggles("picksinvocations")) do
            if row.option.get() and T.Click(row, false) then break end
        end
        T.Click(pact, true)
    end
    if not pact.option.get() then Problem("prerequisite: Pact of the Blade can't be taken")
    else
        if not T.Click(Find("Thirsting Blade"), true) then Problem("prerequisite: Thirsting Blade can't be ticked with Pact of the Blade at level 5") end
        if not L.draft.picks.invocations["Pact of the Blade"] or not T.Click(Find("Pact of the Blade"), false) then
            refused = refused + 1 -- an earlier pact another pick builds on is locked
        else
            if L.draft.picks.invocations["Thirsting Blade"] then Problem("prerequisite: Thirsting Blade stays without Pact of the Blade") else refused = refused + 1 end
        end
    end
    Done("prerequisite done")
    for name in pairs(sheet.picks.invocations) do
        local item = R.PICK_LISTS.invocations.items[name]
        if item.needs and not sheet.picks.invocations[item.needs] then Problem("invocations: " .. name .. " is known without " .. item.needs) end
        if item.level and item.level > sheet.level then Problem("invocations: " .. name .. " is known below its level") end
    end
    -- cantrips, prepared spells: counts
    Open(nil, "spells")
    local rows = Toggles("pickspreparedWarlock")
    local shownHigh
    for _, row in ipairs(rows) do
        local name = Plain(row.name):gsub(" %(.*$", "")
        local spell = R.SPELLS[name]
        if spell and spell.level > 3 then shownHigh = name end
    end
    if shownHigh then Problem("spells: a level 6 Warlock is offered " .. shownHigh) else refused = refused + 1 end
    Done("spells done")
    -- Mystic Arcanum
    To(10, {})
    Open(nil, "arcanum")
    T.Fill({})
    for _, row in ipairs(Toggles("picksarcanum6")) do
        if row.option.get() then T.Click(row, false) end
    end
    Refused("no Mystic Arcanum spell", "Choose 1 Mystic Arcanum")
    local arcana = Toggles("picksarcanum6")
    T.Click(arcana[1], true)
    if T.Click(arcana[2], true) then Problem("arcanum: two 6th-level spells can be ticked") else refused = refused + 1 end
    if #Toggles("picksarcanum7") > 0 then Problem("arcanum: 7th-level spells are offered at level 11") else refused = refused + 1 end
    Done("arcanum done")
end
do
    -- Metamagic
    local sheet = T.NewCharacter("EVOKER", 5)
    Open(nil, "metamagic")
    Refused("Metamagic left open", "Choose 2 Metamagic")
    local rows = Toggles("picksmetamagic")
    T.Click(rows[1], true); T.Click(rows[2], true)
    if T.Click(rows[3], true) then Problem("metamagic: a third option can be ticked at level 2") else refused = refused + 1 end
    Done("metamagic done")
end
do
    -- Wild Shape forms: a Circle of the Land druid isn't offered the Moon's beasts
    local sheet = T.NewCharacter("DRUID", 6)
    Open(nil, "forms")
    Refused("beast forms left open", "Choose 4 Wild Shape forms")
    local offered = {}
    for _, row in ipairs(Toggles("picksforms")) do offered[Plain(row.name):gsub(" %(.*$", "")] = true end
    for name, item in pairs(R.PICK_LISTS.forms.items) do
        if offered[name] and item.level and item.level > 2 then Problem("forms: " .. name .. " (druid level " .. item.level .. ") is offered at level 2") end
        if offered[name] and item.moonLevel and not item.level then Problem("forms: " .. name .. " (Circle of the Moon only) is offered at level 2") end
    end
    Done("forms done")
    T.TakeLevel(nil, { subclass = "Circle of the Land" })
    for name in pairs(sheet.picks.forms) do
        local item = R.PICK_LISTS.forms.items[name]
        if item.moonLevel and not item.level then Problem("forms: a Land druid knows " .. name) end
    end
end
do
    -- Expertise: only skills the character is proficient in, and no more than the feature gives
    local sheet = T.NewCharacter("ROGUE", 7)
    local limit = ns.ExpertiseLimit(sheet)
    if limit ~= 2 or ns.ExpertiseKnown(sheet) ~= 2 then Problem(("expertise: a level 1 Rogue has %d of %d"):format(ns.ExpertiseKnown(sheet), limit)) end
    To(5, {})
    Open(nil, "expertise")
    Refused("expertise left open", "Choose 4 skills for expertise")
    for _, row in ipairs(Toggles("expertise")) do
        local skill = row.option.name
        if (sheet.skills[skill] or 0) == 0 then Problem("expertise: " .. skill .. " is offered without proficiency") end
    end
    local count = 0
    for _, row in ipairs(Toggles("expertise")) do
        if not row.option.get() and T.Click(row, true) then count = count + 1 end
    end
    if count ~= 2 then Problem("expertise: " .. count .. " more skills could be ticked at level 6") else refused = refused + 1 end
    Done("expertise done")
end

---------------------------------------------------------------------------
-- A new class
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("WARRIOR", 8)
    for _, stat in ipairs(R.STATS) do sheet.base[stat] = 10; sheet.bonus[stat] = 0 end
    sheet.base.STR = 15
    Opt.Regrant()
    Open("MAGE", "new class")
    Refused("a Mage with Intelligence 10", "needs Intelligence 13")
    L.draft = nil
    sheet.base.INT, sheet.base.STR, sheet.base.DEX = 15, 10, 10
    Opt.Regrant()
    Open("MAGE", "new class")
    Refused("another class with the first class's own score too low", "your Warrior needs")
    L.draft = nil
    sheet.base.STR = 15
    Opt.Regrant()
    Open("DEMONHUNTER", "new class")
    Refused("a hero class at level 2", "hero class")
    L.draft = nil
    Open("ROGUE", "new class")
    Refused("a Rogue with Dexterity 10", "needs Dexterity 13")
    L.draft = nil
    sheet.base.DEX = 13
    Opt.Regrant()
    Open("ROGUE", "new class")
    Refused("the new class's skill left open", "Choose the skill your new class gives")
    local skillRow = Row("newClassSkill")
    for skill in pairs(skillRow.option.values()) do
        if (sheet.skills[skill] or 0) > 0 then Problem("new class: " .. skill .. " is offered though the character is proficient") end
    end
    Done("new class done")
    if ns.ClassLevel(sheet, "ROGUE") ~= 1 or sheet.level ~= 2 then Problem("new class: Rogue level " .. ns.ClassLevel(sheet, "ROGUE")) end
    if sheet.saves.DEX then Problem("new class: a later class gave a saving throw proficiency") end
    local entry = ns.ClassEntry(sheet, "ROGUE")
    if not entry or (entry.skill or "") == "" or (sheet.skills[entry.skill] or 0) < 1 then Problem("new class: its skill isn't on the sheet") end
    -- the same core class twice
    sheet.base.WIS, sheet.base.CHA = 13, 13
    Opt.Regrant()
    T.TakeLevel("PALADIN", {}, "paladin")
    Open("DEATHKNIGHT", "same class")
    Refused("Paladin and Death Knight together", "can't be taken twice")
    L.draft = nil
    -- the tab greys the class out with the reason
    local _, byKey = T.Rows(mainRoot.args.character, "tab")
    local text = byKey.levelClass.option.values().DEATHKNIGHT
    if not text:find("can't be taken twice") then Problem("the class dropdown doesn't say why a Death Knight is closed: " .. text) end
    T.Check("new class end")
end
print("attempts refused: " .. refused)
T.Summary("breaking the rules")
