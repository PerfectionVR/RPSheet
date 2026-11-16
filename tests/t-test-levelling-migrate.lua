-- Sheets saved by older versions, brought in through the path a login takes
-- (RPSheet:UpdateSheetKey, Sheet/Storage.lua and Sheet/Migration.lua), and then used:
--   * a version 1 sheet (the homebrew rules before 5e) that was kept per WoW character;
--   * levelled characters with everything newer taken off again: the choices kept per
--     level, the picks, the fields added to the sheet and to its entries. Once the way
--     the game loads them (the saved-variables library fills in the defaults), once
--     with nothing filled in at all.
-- Afterwards everything is read and clicked, the Character tab's buttons settle what
-- is open, and the character goes on levelling.
dofile(ARG3 .. "/t-test-levelling-lib.lua")
dofile(ARG3 .. "/exercise_body.lua")
dofile(ARG3 .. "/t-test-levelling-codec.lua")
local Util = ns.Util
local sheets = RPSheet.db.global.sheets
local blank = ns.defaults.global.sheets["*"]
local migrated = 0

-- Makes `state` the saved sheet of this profile and logs in again.
local function Login(state, fill)
    local key = RPSheet.sheetKey
    -- What the saved-variables library does on load: every default that is missing.
    -- Without `fill` only the current values beside the sheet get theirs, and the
    -- sheet itself is left as bare as it was saved.
    local bare = state.sheet
    if not fill then state.sheet = nil end
    Util.FillDefaults(state, blank)
    if not fill then state.sheet = bare end
    rawset(sheets, key, state)
    RPSheet.sheetKey = nil
    Try("login", function() RPSheet:UpdateSheetKey() end)
    migrated = migrated + 1
    return RPSheet:Sheet()
end

local function Settle(label)
    local sheet = RPSheet:Sheet()
    for guard = 1, 8 do
        local pending = Levels.Pending(sheet)
        if #pending > 0 then
            ns.RebuildOptions()
            if not T.Tab("levelChoice" .. pending[1]) then Problem(label .. ": no button for level choice " .. pending[1]) break end
            FlushTimers(); T.Finish(label .. " level choice")
        elseif ns.OpenClassChoices(sheet) then
            if not T.Tab("classChoices") then Problem(label .. ": no choices button") break end
            FlushTimers(); T.Finish(label .. " choices")
        else
            break
        end
    end
    -- A species trait with a choice is picked on its Customize page, as the red line says.
    for _, trait in ipairs(ns.OpenTraitChoices(sheet)) do
        if not table.concat(T.RedLines(sheet), " "):find(trait .. " has a choice to make") then Problem(label .. ": the open choice of " .. trait .. " isn't called out") end
        sheet.traitChoices[trait] = ns.TraitOptions(sheet, trait)[1]
        Opt.Regrant()
    end
    if ns.OpenClassChoices(sheet) then
        T.Tab("classChoices"); FlushTimers(); T.Finish(label .. " choices after the traits")
    end
    RPSheet:ClampState(true)
end

---------------------------------------------------------------------------
-- Version 1
---------------------------------------------------------------------------
do
    local key = RPSheet.sheetKey
    rawset(sheets, key, nil)
    local old = RPSheet.db.char
    old.sheet = {
        base = { STR = 14, DEX = 12, CON = 14, INT = 8, WIS = 10, CHA = 10 }, bonus = { STR = 1 },
        size = "LARGE", armor = "MAIL", shield = "SMALL", acBonus = 1,
        resourceName = "Fury", resourceStat = "STR", counterName = "Combo", counterMax = 5,
        weapons = { { name = "Old Axe", kind = "TWO", stat = "STR" }, { name = "Bandage", kind = "HEAL", stat = "WIS" } },
        abilities = {
            { name = "Cleave", desc = "A wide swing.", cost = 2, stat1 = "STR", stat2 = "", weaponDamage = 2, usesCounter = true },
            { name = "Shout", desc = "", cost = 0, stat1 = "CHA" },
        },
        passives = { { name = "Thick Hide", desc = "Hard to hurt.", enabled = true, skill = "Athletics", stat = "CON" } },
    }
    old.hp, old.resource, old.counter, old.weapon = 9, 3, 2, 1
    RPSheet.sheetKey = nil
    Try("v1 login", function() RPSheet:UpdateSheetKey() end)
    migrated = migrated + 1
    local sheet, state = RPSheet:Sheet(), RPSheet:State()
    if sheet.version ~= 2 then Problem("v1: version " .. tostring(sheet.version)) end
    if rawget(old, "sheet") then Problem("v1: the old per-character sheet is still there") end
    if sheet.armor ~= "CHAINMAIL" or sheet.shield ~= true or sheet.size ~= "M" then Problem(("v1: armor %s, shield %s, size %s"):format(tostring(sheet.armor), tostring(sheet.shield), tostring(sheet.size))) end
    if RPSheet:MaxHP() ~= 10 + 2 * 2 then Problem("v1: maximum HP " .. RPSheet:MaxHP() .. ", the old rules gave 14") end
    if #sheet.resources ~= 2 or sheet.resources[1].name ~= "Fury" or sheet.resources[2].name ~= "Combo" then Problem("v1: resources " .. #sheet.resources) end
    if state.res.Fury ~= 3 or state.res.Combo ~= 2 then Problem("v1: the resources' current values were lost") end
    if #sheet.weapons ~= 2 or sheet.weapons[1].sides ~= 8 or not sheet.weapons[2].heal then Problem("v1: weapons not converted") end
    local cleave = sheet.abilities[1]
    if not cleave or #cleave.actions ~= 4 then Problem("v1: Cleave has " .. tostring(cleave and #cleave.actions) .. " actions, expected spend, roll, weapon, empty") end
    local hide, bonus
    for _, passive in ipairs(sheet.passives) do
        if passive.name == "Thick Hide" then hide = passive end
        if passive.name == "AC bonus" then bonus = passive end
    end
    if not hide or #hide.effects ~= 1 or hide.effects[1].target ~= "SKILL:Athletics" then Problem("v1: the passive's skill bonus wasn't converted") end
    if not bonus then Problem("v1: the AC bonus was lost") end
    for field, default in pairs(ns.NewSheet()) do
        if type(sheet[field]) ~= type(default) then Problem(("v1: sheet.%s is %s"):format(field, type(sheet[field]))) end
    end
    ns.RebuildOptions()
    Try("v1 options", Feed, mainRoot, "options")
    Exercise("v1")
    -- it has no class: the wizard makes the character, and it can be levelled
    local made = T.NewCharacter("SHAMAN", 5)
    if made then
        for level = 2, 4 do T.TakeLevel(nil, {}, "v1 then " .. level) end
        T.Check("v1, then a new character", { level = 4 })
    end
end

---------------------------------------------------------------------------
-- Levelled characters with the newer fields taken off
---------------------------------------------------------------------------
local KEEP_SHEET = { version = true, level = true, class = true, subclass = true, spec = true, species = true, size = true,
    background = true, alignment = true, scoreMethod = true, base = true, bonus = true, asi = true, skills = true, saves = true,
    armor = true, shield = true, hpAdjust = true, castStat = true, resources = true, weapons = true, abilities = true,
    passives = true, spells = true, fightingStyle = true, lineage = true, languages = true }
local KEEP_ENTRY = { name = true, desc = true, enabled = true, effects = true, actions = true, auto = true,
    level = true, count = true, sides = true, dice = true, stat = true, flat = true, times = true, proficient = true, heal = true,
    startEmpty = true, save = true, attack = true, damage = true }

local function Strip(state, keepClasses)
    local sheet = state.sheet
    for field in pairs(sheet) do
        if not KEEP_SHEET[field] and not (keepClasses and (field == "classes")) then sheet[field] = nil end
    end
    for _, listKey in ipairs({ "abilities", "passives", "spells", "weapons", "resources" }) do
        for _, entry in ipairs(sheet[listKey]) do
            for field in pairs(entry) do
                if not KEEP_ENTRY[field] then entry[field] = nil end
            end
            -- prepared spells were added by hand then; feats were plain passives; an
            -- invocation's spell was added by hand too
            local auto = entry.auto or ""
            for _, prefix in ipairs({ "spell", "cantrip", "chosen", "feat", "level", "pick", "maneuver", "invocation" }) do
                if auto:find("^" .. prefix .. ":") then entry.auto = nil end
            end
        end
    end
    for field in pairs(state) do
        if field ~= "sheet" and field ~= "hp" and field ~= "created" and field ~= "weapon" then state[field] = nil end
    end
    return state
end

local function Old(label, keys, top, fill)
    local sheet = T.NewCharacter(keys[1], #label, #keys > 1)
    if not sheet then return end
    for level = 2, top do
        local key = keys[(level - 1) % #keys + 1]
        if level < R.HERO_START_LEVEL and R.CLASSES[key].hero then key = keys[1] end
        if not T.TakeLevel(key, { choice = "ASI" }, label .. " " .. level) then return end
    end
    local scores = {}
    for _, stat in ipairs(R.STATS) do scores[stat] = RPSheet:NaturalScore(stat, true) end
    local spells = #sheet.spells
    local state = Strip(CopyTable(RPSheet:State()), #keys > 1)
    sheet = Login(state, fill)
    label = label .. (fill and " (loaded by the game)" or " (sheet left bare)")
    if sheet.level ~= top or sheet.class ~= keys[1] then Problem(label .. ": level " .. tostring(sheet.level) .. " " .. tostring(sheet.class)) return end
    for field, default in pairs(ns.NewSheet()) do
        if type(sheet[field]) ~= type(default) then Problem(("%s: sheet.%s is %s after loading"):format(label, field, type(sheet[field]))) end
    end
    -- the points from level-ups are spread over the levels again: the scores are as they were
    for _, stat in ipairs(R.STATS) do
        if RPSheet:NaturalScore(stat, true) ~= scores[stat] then Problem(("%s: %s was %d, is %d"):format(label, stat, scores[stat], RPSheet:NaturalScore(stat, true))) end
    end
    if #sheet.spells < spells then Problem(("%s: %d spells before, %d after"):format(label, spells, #sheet.spells)) end
    ns.RebuildOptions()
    Try(label .. " options", Feed, mainRoot, "options")
    Exercise(label)
    RPSheet:Sheet().items = {} -- what the exercise put in the bags
    Opt.Regrant()
    Settle(label)
    -- a Fighting Style of a later class is chosen on its page; none of these have one open
    T.Check(label, { level = top })
    -- and on it goes: up, down, export and import
    if T.TakeLevel(nil, {}, label .. " next") then T.Check(label .. " next", { level = top + 1 }) end
    T.Tab("levelDown"); FlushTimers()
    Settle(label .. " down")
    T.Check(label .. " down", { level = top })
    local first = RPSheet:ExportSheet()
    local clean = RPSheet:DecodeSheet(first)
    if not clean then Problem(label .. ": the export can't be read back")
    else
        RPSheet:ReplaceSheet(clean)
        if RPSheet:ExportSheet() ~= first then Problem(label .. ": export, import, export gives another string") end
    end
end

for index, key in ipairs(R.CLASS_ORDER) do
    Old(key, { key }, 9, true)
    Old(key, { key }, 9, false)
end
Old("WARRIOR+MAGE", { "WARRIOR", "MAGE" }, 10, true)
Old("PRIEST+WARLOCK", { "PRIEST", "WARLOCK" }, 10, false)
print("sheets migrated: " .. migrated)
T.Summary("old sheets")
