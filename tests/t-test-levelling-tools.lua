-- Tools as the strict places hold to them:
--   * a Monk's tool, one kind of artisan's tools or a musical instrument, is a pick of
--     the level dialog (Data/ToolPicks.lua): asked for once, never a tool the
--     character has already, taken over from a tick an earlier Monk made by hand,
--     and not given to a character who takes Monk as a later class;
--   * Inscription Adept needs proficiency with Calligrapher's Supplies, Cartographer's
--     Tools or Painter's Supplies (Data/Feats.lua): the level dialog refuses it
--     without one, whichever way the proficiency was gained.
-- And two classes that prepare the same spell: both entries stay, each named with
-- its class on the sheet (Sheet/ClassSpells.lua).
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local checks = 0
local function Check(ok, text)
    checks = checks + 1
    if not ok then Problem(text) end
end
local function Plain(text) return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function Upkeep(sheet)
    ns.ApplyGrants(sheet); ns.NormalizeState(RPSheet:State()); RPSheet:ClampState(true); RPSheet:SheetChanged()
end
local function Count(set) local n = 0 for _ in pairs(set or {}) do n = n + 1 end return n end
local function ToolRows(key)
    local rows = {}
    for _, row in ipairs((T.Rows(levelRoot, T.label))) do
        if row.parent == "level.picks" .. key and row.option.type == "toggle" then rows[#rows + 1] = row end
    end
    return rows
end
local function Settle(label)
    ns.RebuildOptions()
    if T.Tab("classChoices") then FlushTimers(); T.Finish(label) else Problem(label .. ": no choices button") end
end

local KEY = R.MONK_TOOL_LIST
local list = R.PICK_LISTS[KEY]

---------------------------------------------------------------------------
-- The list itself: every kind of artisan's tools and every instrument
---------------------------------------------------------------------------
for _, name in ipairs(R.TOOL_ORDER) do
    local kind = R.TOOLS[name].kind
    Check((list.items[name] ~= nil) == (kind == "AT" or kind == "INS"), name .. (list.items[name] and " is offered as a Monk's tool" or " is missing from the Monk's tools"))
end
Check(ns.PickLimit(KEY, "MONK", 1) == 1 and ns.PickLimit(KEY, "MONK", 20) == 1, "a Monk doesn't pick exactly one tool")
Check(ns.PickLimit(KEY, "WARRIOR", 5) == 0, "a Warrior picks a Monk's tool")

---------------------------------------------------------------------------
-- A new Monk
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("MONK", 1, true)
    local picks = sheet.picks[KEY]
    Check(Count(picks) == 1 and not ns.OpenPicks(sheet), ("a new Monk has %d tools picked"):format(Count(picks)))
    local tool = next(picks)
    Check(tool and RPSheet:ToolSource(tool) == "feature" and not sheet.tools[tool], "the Monk isn't proficient with the tool it picked")
    T.Check("new Monk")

    -- Asked for again when it is open, and held to one tool the Monk doesn't have.
    picks[tool] = nil
    local had = R.BACKGROUND_TOOLS[sheet.background]
    sheet.tools["Lute"] = true -- one ticked by hand under Customize since
    Check(ns.SheetPickLimit(sheet, KEY) == 1, "the list is gone")
    -- (the tick would be taken for the pick: that is tested below; here it is another tool's)
    picks["Drum"] = true
    Upkeep(sheet)
    Check(picks["Drum"] and sheet.tools["Lute"], "a pick and a tick of another tool don't stand side by side")
    picks["Drum"] = nil
    sheet.tools["Lute"] = nil
    sheet.picks[R.TOOL_PICK_LIST] = sheet.picks[R.TOOL_PICK_LIST] or {}
    Check(ns.OpenPicks(sheet) and ns.OpenClassChoices(sheet), "a Monk without its tool has nothing open")
    Check(table.concat(T.RedLines(sheet), " ") ~= "", "the open tool isn't called out on the Character tab")
    sheet.tools["Flute"] = true
    T.label = "Monk's tool"
    -- (straight to the dialog: the upkeep on the way would take the Flute for the pick)
    L.draft = nil
    local slot = ns.LevelSlot(sheet, sheet.class, 1)
    sheet.tools["Flute"] = nil
    Try("open", ns.OpenLevelDialog, slot, false); FlushTimers()
    sheet.tools["Flute"] = true
    if L.draft then
        local problem = L.Problem() or ""
        Check(problem:find("Choose 1 Monk's tool") ~= nil, "the dialog doesn't ask for the Monk's tool: " .. problem)
        local rows = ToolRows(KEY)
        Check(#rows == #list.order, ("the dialog shows %d of %d tools"):format(#rows, #list.order))
        local clicked
        for _, row in ipairs(rows) do
            local name = Plain(row.name or "")
            local taken = name:find("already proficient") ~= nil
            local which = name:gsub(" %(.*$", "")
            if which == "Flute" or which == had then
                Check(taken and not T.Click(row, true), which .. ", which the Monk is proficient with, can be picked as its tool")
            elseif not clicked then
                Check(not taken and T.Click(row, true), which .. " can't be picked")
                clicked = which
            else
                Check(not T.Click(row, true), "a second tool can be picked: " .. which)
            end
        end
        Check(L.Problem() == nil or not L.Problem():find("Monk's tool"), "the dialog still asks for a tool after one was picked")
        if T.Fill({}) and T.Confirm() then T.Finish("Monk's tool follow-up") end
        L.draft = nil
        Check(clicked and sheet.picks[KEY][clicked] == true and RPSheet:ToolSource(clicked) == "feature", "the tool picked in the dialog isn't the Monk's")
    else
        Problem("the dialog for the Monk's first level didn't open")
    end
    sheet.tools["Flute"] = nil
    T.Check("Monk with its tool")

    -- A Monk from before the tool was a pick: ticked by hand, nothing picked.
    wipe(sheet.picks[KEY])
    sheet.tools["Weaver's Tools"] = true
    Upkeep(sheet)
    Check(sheet.picks[KEY]["Weaver's Tools"] == true and not sheet.tools["Weaver's Tools"], "a tool an earlier Monk ticked by hand isn't taken for its pick")
    Check(not ns.OpenPicks(sheet) and RPSheet:ToolSource("Weaver's Tools") == "feature", "an earlier Monk is asked for its tool again")
    -- A tick that is the background's own tool isn't the class's.
    wipe(sheet.picks[KEY])
    Upkeep(sheet)
    Check(Count(sheet.picks[KEY]) == 0 and ns.OpenPicks(sheet), "a tool is picked from nothing")
    Settle("Monk choices")
    Check(Count(sheet.picks[KEY]) == 1, "the Character tab's button can't settle the Monk's tool")

    -- Another class later: the tool stays, and a Battle Master can't pick the same kind.
    wipe(sheet.picks[KEY]); sheet.picks[KEY]["Smith's Tools"] = true
    Upkeep(sheet)
    for level = 1, 3 do
        T.TakeLevel("WARRIOR", { subclass = "Battle Master", inspect = level == 3 and function()
            local seen = false
            for _, row in ipairs(ToolRows(R.TOOL_PICK_LIST)) do
                local name = Plain(row.name or "")
                if name:find("^Smith's Tools") then
                    seen = true
                    Check(name:find("already proficient") ~= nil and not T.Click(row, true), "a Battle Master can pick the Monk's own tool again")
                end
            end
            Check(seen, "Student of War's tools aren't asked for at Fighter level 3")
        end or nil })
    end
    Check(sheet.picks[KEY]["Smith's Tools"] == true and RPSheet:ToolSource("Smith's Tools") == "feature", "the Monk's tool is lost with a second class")
    Check(Count(sheet.picks[R.TOOL_PICK_LIST]) == 1 and not sheet.picks[R.TOOL_PICK_LIST]["Smith's Tools"], "Student of War's tool isn't a second kind")
    T.Check("Monk and Battle Master")
end

---------------------------------------------------------------------------
-- Monk as a later class brings no tool
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("WARRIOR", 2, true)
    local before = #RPSheet:Tools()
    T.TakeLevel("MONK", { inspect = function()
        Check(L.PickLimit(KEY) == 0 and #ToolRows(KEY) == 0, "a character who takes Monk as a second class is asked for a Monk's tool")
    end })
    Check(ns.ClassLevel(sheet, "MONK") == 1 and ns.SheetPickLimit(sheet, KEY) == 0, "Monk as a later class has the tool list")
    sheet.tools["Flute"] = true
    Upkeep(sheet)
    Check(sheet.tools["Flute"] == true and Count(sheet.picks[KEY]) == 0, "a tick is taken for the pick of a class that has none")
    sheet.tools["Flute"] = nil
    Upkeep(sheet)
    Check(#RPSheet:Tools() == before and not ns.OpenPicks(sheet), "Monk as a later class changes the tools")
    T.Check("Warrior and Monk")
end

---------------------------------------------------------------------------
-- Inscription Adept
---------------------------------------------------------------------------
do
    local FEAT = "Inscription Adept"
    local NEEDS = { "Calligrapher's Supplies", "Cartographer's Tools", "Painter's Supplies" }
    Check(table.concat(R.FEATS[FEAT].needTools or {}, "|") == table.concat(NEEDS, "|"), FEAT .. " doesn't need the three scribe's tools")
    -- A Farmer (Carpenter's Tools) who fights: none of the three.
    local n
    for index, key in ipairs(R.BACKGROUND_ORDER) do
        if key == "FARMER" then n = index - 1 end
    end
    local sheet = T.NewCharacter("WARRIOR", n, true)
    Check(sheet.background == "FARMER", "the test character is no Farmer")
    for _, stat in ipairs({ "INT", "WIS", "CHA" }) do sheet.base[stat] = 13 end
    for _, tool in ipairs(NEEDS) do sheet.tools[tool] = nil end
    Upkeep(sheet)
    while sheet.level < 3 do T.TakeLevel(nil, { subclass = "Champion" }) end
    T.label = "feat without the tool"
    Try("open", ns.OpenLevelDialog, nil, false); FlushTimers()
    local function Row(key)
        local _, byKey = T.Rows(levelRoot, T.label)
        return byKey[key]
    end
    local function Offered()
        T.Click(Row("choice"), "FEAT")
        local text = Row("featPick").option.values()[FEAT] or ""
        return not text:find("needs proficiency with", 1, true), Plain(text)
    end
    if L.draft and L.draft.kind == "ASI" then
        local open, text = Offered()
        Check(not open, FEAT .. " is offered without the tool: " .. text)
        Check(text:find("Calligrapher's Supplies or Cartographer's Tools or Painter's Supplies", 1, true) ~= nil, "the dialog doesn't name the tools it needs: " .. text)
        T.Click(Row("featPick"), FEAT)
        T.Click(Row("featStat"), "INT")
        local problem = L.Problem() or ""
        Check(problem:find("You can't take " .. FEAT, 1, true) ~= nil, "the dialog accepts " .. FEAT .. " without the tool: " .. problem)
        Check(not T.Click(Row("confirm")), "the level can be confirmed with a feat the character can't take")
        if not L.draft then Try("open", ns.OpenLevelDialog, nil, false); FlushTimers() end
        -- Each of the three tools opens it, however the proficiency came.
        for index, tool in ipairs(NEEDS) do
            sheet.tools[tool] = true
            Check((Offered()), ("%s isn't offered to a character proficient with %s"):format(FEAT, tool))
            sheet.tools[tool] = nil
            Check(not (Offered()), FEAT .. " stays offered without " .. tool)
        end
        sheet.tools["Smith's Tools"] = true
        Check(not (Offered()), FEAT .. " is offered for a tool it doesn't ask for")
        sheet.tools["Smith's Tools"] = nil
        sheet.background = "SCRIBE" -- Calligrapher's Supplies from the background
        Check((Offered()), FEAT .. " isn't offered to a Scribe")
        sheet.background = "FARMER"
        sheet.tools[NEEDS[3]] = true
        T.Click(Row("choice"), "FEAT")
        Check(T.Click(Row("featPick"), FEAT), FEAT .. " can't be picked with Painter's Supplies")
        T.Click(Row("featStat"), "INT")
        L.draft.decided = true
        if T.Fill({}) and T.Confirm() then T.Finish("feat follow-up") end
        L.draft = nil
        Check(sheet.level == 4 and ns.Levels.HasFeat(sheet, FEAT, 0), "the level with " .. FEAT .. " wasn't taken")
        T.Check("Warrior with " .. FEAT)
        -- Losing the tool afterwards is called out, as any feat that no longer fits is.
        sheet.tools[NEEDS[3]] = nil
        Upkeep(sheet)
        Check(#ns.Levels.Pending(sheet) > 0, "a feat whose tool is gone isn't called out")
        sheet.tools[NEEDS[3]] = true
        Upkeep(sheet)
        Check(#ns.Levels.Pending(sheet) == 0, "the feat stays called out with its tool back")
    else
        Problem("level 4 has no Ability Score Improvement")
    end
    L.draft = nil
end

---------------------------------------------------------------------------
-- The same spell prepared by two classes
---------------------------------------------------------------------------
do
    local sheet = T.NewCharacter("PRIEST", 1, true)
    Check(ns.SpellRowName(sheet, sheet.spells[1]) == sheet.spells[1].name, "a spell of a character of one class names its class")
    T.TakeLevel("DRUID", {})
    local SPELL = "Cure Wounds"
    for _, key in ipairs({ "preparedCleric", "preparedDruid" }) do
        local picks = sheet.picks[key]
        if not picks[SPELL] then
            for other in pairs(picks) do picks[other] = nil break end
            picks[SPELL] = true
        end
    end
    Upkeep(sheet)
    local found, other, times = {}, nil, {}
    for _, spell in ipairs(sheet.spells) do times[spell.name] = (times[spell.name] or 0) + 1 end
    for _, spell in ipairs(sheet.spells) do
        if spell.name == SPELL then found[#found + 1] = spell
        elseif times[spell.name] == 1 then other = other or spell end
    end
    Check(#found == 2 and found[1].class ~= found[2].class, ("%s prepared by a Priest and a Druid is on the list %d times"):format(SPELL, #found))
    Check(not ns.OpenPicks(sheet), "one of the two classes lost its " .. SPELL)
    local names = {}
    for _, spell in ipairs(found) do names[ns.SpellRowName(sheet, spell)] = spell.class end
    Check(names[SPELL .. " (Priest)"] == "PRIEST" and names[SPELL .. " (Druid)"] == "DRUID", "the two entries don't name their classes")
    Check(RPSheet:CastStat(found[1]) ~= nil and RPSheet:SpellDC(found[1]) ~= nil, "a spell of two classes can't be cast")
    Check(other ~= nil and ns.SpellRowName(sheet, other) == other.name, "a spell that is on the list once names its class")
    -- What the sheet's spell section writes on its rows.
    local UI, rows = ns.UI, {}
    local heading, label, level = UI.AddHeading, UI.AddLabel, RPSheet.AddLevelLabel
    UI.AddHeading = function() end
    UI.AddLabel = function(_, _, text) rows[#rows + 1] = Plain(text) end
    RPSheet.AddLevelLabel = function() end
    Try("spell section", UI.SpellSection, RPSheet, {})
    UI.AddHeading, UI.AddLabel, RPSheet.AddLevelLabel = heading, label, level
    local priest, druid, plain = 0, 0, 0
    for _, text in ipairs(rows) do
        if text:find(SPELL .. " (Priest)", 1, true) == 1 then priest = priest + 1
        elseif text:find(SPELL .. " (Druid)", 1, true) == 1 then druid = druid + 1
        elseif text:find(SPELL, 1, true) == 1 then plain = plain + 1 end
    end
    Check(priest == 1 and druid == 1 and plain == 0, ("the sheet shows %s as %d Priest's, %d Druid's and %d unnamed rows"):format(SPELL, priest, druid, plain))
    -- Each class counts its own, so neither is one short of what it prepares.
    for _, key in ipairs({ "PRIEST", "DRUID" }) do
        local _, limit = RPSheet:SpellLimits(key)
        local _, prepared = RPSheet:SpellCounts(nil, key)
        Check(prepared == limit, ("%s has %d of %d spells prepared on the sheet"):format(key, prepared, limit))
    end
    -- Deleting one class's entry under Customize frees that class's pick only.
    local gone = found[2]
    ns.DismissAuto(sheet, gone)
    for index = #sheet.spells, 1, -1 do
        if sheet.spells[index] == gone then table.remove(sheet.spells, index) end
    end
    Upkeep(sheet)
    local left = {}
    for _, spell in ipairs(sheet.spells) do
        if spell.name == SPELL then left[#left + 1] = spell.class end
    end
    Check(#left == 1 and left[1] == found[1].class, ("deleting the %s's %s leaves: %s"):format(gone.class, SPELL, table.concat(left, ", ")))
    local mine = gone.class == "PRIEST" and "preparedCleric" or "preparedDruid"
    local theirs = gone.class == "PRIEST" and "preparedDruid" or "preparedCleric"
    Check(not sheet.picks[mine][SPELL] and sheet.picks[theirs][SPELL] == true, "deleting one class's entry frees the wrong pick")
    Settle("shared spell choices")
    T.Check("Priest and Druid with " .. SPELL)
end

local problems = 0
for _ in pairs(PROBLEMS) do problems = problems + 1 end
print(("tools and shared spells: %d dialogs, %d checks, %d problems"):format(T.dialogs, checks + T.checks, problems))
