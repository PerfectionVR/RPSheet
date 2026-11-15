-- What may be exchanged, and what has to stay:
--   * taking a level: one earlier pick of a list where the class allows it (a prepared
--     spell of a Sorcerer or Warlock, a cantrip of every class but the Wizard, one
--     Mystic Arcanum spell, one Metamagic option, one Invocation, one maneuver when
--     new ones are learned), none where it doesn't (a Paladin's or Ranger's prepared
--     spells, a Wizard's cantrips), any number for a Cleric's or Druid's prepared
--     spells; none of a class's picks when the level is taken in another class;
--   * the dialog opened again for a level the character has: everything chosen is
--     locked, and a place that was freed under Customize can be filled.
-- The expectations are the rules', written here by class, not read from the addon.
dofile(ARG3 .. "/t-test-levelling-lib.lua")

local PREPARED = { Sorcerer = 1, Warlock = 1, Paladin = 0, Ranger = 0 } -- Cleric, Druid: any number
local CANTRIPS = { Cleric = 1, Druid = 1, Sorcerer = 1, Warlock = 1, Wizard = 0 }
-- How many earlier picks of a list a level in its own class lets go: a number, or
-- nil for any number, or false for a list the test has no rule for.
local function Allowed(key)
    local list = R.PICK_LISTS[key]
    if key == "metamagic" or key == "invocations" then return 1 end
    if key:find("^arcanum") then return 1, "arcanum" end
    if list.title == "Prepared spells" then return PREPARED[list.base] end
    if list.title == "Cantrips" then return CANTRIPS[list.base] end
    return false
end
local SETTLED = { ["Prepared spells"] = true, Cantrips = true, Metamagic = true, ["Eldritch Invocations"] = true }

local tried, swapped, locked = 0, 0, 0
local function GroupRows(rows, groupKey)
    local out = {}
    for _, row in ipairs(rows) do
        if row.parent == "level." .. groupKey and row.option.type == "toggle" then out[#out + 1] = row end
    end
    return out
end
local function Name(row) return (row.option.desc ~= nil or true) and row.path end

-- Tries to untick every pick the character had before this dialog; returns how many
-- went, and the rows that went.
local function Untick(rows, earlier)
    local gone = {}
    for _, row in ipairs(rows) do
        if earlier[row.path] and row.option.get() and T.Click(row, false) then gone[#gone + 1] = row end
    end
    return gone
end

-- Run inside a level-up dialog, before the player fills it.
local function Inspect(label, ownBase, plan)
    local rows = T.Rows(levelRoot, label)
    local groups = {}
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local list = R.PICK_LISTS[key]
        local toggles = GroupRows(rows, "picks" .. key)
        local earlier, count = {}, 0
        for _, row in ipairs(toggles) do
            if row.option.get() then earlier[row.path], count = true, count + 1 end
        end
        if count > 0 then
            local allowed, group = Allowed(key)
            -- (a Cleric's or Druid's change after a rest whatever class the level is in)
            if list.base ~= ownBase and allowed then allowed = 0 end
            group = group or key
            groups[group] = groups[group] or { allowed = allowed, count = 0, gone = {}, keys = {}, title = list.title }
            local gone = Untick(toggles, earlier)
            groups[group].count = groups[group].count + count
            groups[group].keys[#groups[group].keys + 1] = key
            for _, row in ipairs(gone) do groups[group].gone[#groups[group].gone + 1] = row end
        end
    end
    for group, data in pairs(groups) do
        tried = tried + 1
        local want = data.allowed
        if want == nil then want = data.count end
        if want ~= false then
            want = math.min(want, data.count)
            if #data.gone ~= want then
                Problem(("%s: %s lets %d earlier picks go, the rules allow %d (of %d)"):format(label, group, #data.gone, want, data.count))
            end
            if want == 0 then locked = locked + 1 end
            -- One exchange: another pick has to take its place.
            if want == 1 and #data.gone == 1 then
                plan.avoid = plan.avoid or {}
                plan.avoid[data.gone[1].path] = true
                plan.swaps[#plan.swaps + 1] = { key = data.gone[1].path:match("picks([^.]+)%."), row = data.gone[1] }
            end
        end
    end
    -- Maneuvers: one when the number known grows, else none.
    local toggles = GroupRows(rows, "maneuvers")
    local earlier, count = {}, 0
    for _, row in ipairs(toggles) do
        if row.option.get() then earlier[row.path], count = true, count + 1 end
    end
    if count > 0 then
        tried = tried + 1
        local grows = ns.SheetManeuverLimit(L.Like()) > ns.SheetManeuverLimit(RPSheet:Sheet())
        local gone = Untick(toggles, earlier)
        local want = grows and ownBase == "Fighter" and 1 or 0
        if #gone ~= want then Problem(("%s: %d earlier maneuvers can go, the rules allow %d"):format(label, #gone, want)) end
        if #gone == 1 then
            plan.avoid = plan.avoid or {}
            plan.avoid[gone[1].path] = true
            plan.swaps[#plan.swaps + 1] = { maneuver = gone[1].option.name }
        end
    end
end

local function Level(label, classKey)
    local plan = { swaps = {} }
    plan.inspect = function() Inspect(label, R.CLASSES[classKey or RPSheet:Sheet().class].base, plan) end
    local picksBefore = CopyTable(RPSheet:Sheet().picks)
    if not T.TakeLevel(classKey, plan, label) then return false end
    local sheet = RPSheet:Sheet()
    for _, swap in ipairs(plan.swaps) do
        if swap.maneuver then
            if sheet.maneuvers[swap.maneuver] then Problem(label .. ": the exchanged maneuver " .. swap.maneuver .. " is still known") else swapped = swapped + 1 end
        else
            -- exactly one of the earlier picks of the list is gone
            -- (one that is always prepared from this level on makes way without counting)
            local gone, names = 0, {}
            local always = ns.AlwaysPrepared(ns.ListView(sheet, swap.key))
            for name in pairs(picksBefore[swap.key] or {}) do
                if not sheet.picks[swap.key][name] and not always[name] then gone = gone + 1; names[#names + 1] = name end
            end
            if gone ~= 1 then Problem(("%s: %s: %d earlier picks gone after an exchange of one: %s"):format(label, swap.key, gone, table.concat(names, ", "))) else swapped = swapped + 1 end
        end
    end
    T.Check(label, { level = sheet.level })
    return true
end

-- Every class up to 20 with an exchange tried at every level.
for index, key in ipairs(R.CLASS_ORDER) do
    local class = R.CLASSES[key]
    local sheet = T.NewCharacter(key, index + 40)
    if sheet then
        for level = 2, R.MAX_LEVEL do
            if not Level(("%s %d"):format(key, level)) then break end
        end
    end
end
-- A Battle Master.
do
    local sheet = T.NewCharacter("WARRIOR", 60)
    if sheet then
        for level = 2, R.MAX_LEVEL do
            local plan = { subclass = "Battle Master", swaps = {} }
            local label = "Battle Master " .. level
            plan.inspect = function() Inspect(label, "Fighter", plan) end
            if not T.TakeLevel(nil, plan, label) then break end
            for _, swap in ipairs(plan.swaps) do
                if swap.maneuver and RPSheet:Sheet().maneuvers[swap.maneuver] then Problem(label .. ": the exchanged maneuver is still known") elseif swap.maneuver then swapped = swapped + 1 end
            end
            T.Check(label, { level = level })
        end
        if ns.ClassSubclass(sheet, "WARRIOR") ~= "Battle Master" then Problem("the Battle Master isn't one") end
    end
end
-- Levels in another class: the first class's picks all stay.
for n, keys in ipairs({ { "EVOKER", "WARRIOR" }, { "WARLOCK", "PRIEST" }, { "PALADIN", "MAGE" }, { "WARRIOR", "DRUID" } }) do
    local sheet = T.NewCharacter(keys[1], 70 + n, true)
    if sheet then
        local plan = { subclass = keys[1] == "WARRIOR" and "Battle Master" or nil }
        for level = 2, 8 do T.TakeLevel(nil, plan, keys[1] .. "+ " .. level) end
        for level = 9, 16 do
            local key = keys[level % 2 + 1]
            if not Level(("%s+%s %d (%s)"):format(keys[1], keys[2], level, key), key) then break end
        end
    end
end
print(("exchanges tried in %d lists; %d made; %d lists that let none go"):format(tried, swapped, locked))

---------------------------------------------------------------------------
-- Opened again: what was chosen is locked, a freed place can be filled
---------------------------------------------------------------------------
local reopened, freed = 0, 0
unsaid = 0
local function Locks(label)
    local sheet = RPSheet:Sheet()
    if not T.Tab("classChoices") then Problem(label .. ": no choices button") return end
    FlushTimers()
    if not L.draft then Problem(label .. ": the choices dialog didn't open") return end
    if L.draft.taking then Problem(label .. ": the choices dialog takes a level") end
    reopened = reopened + 1
    local rows, byKey = T.Rows(levelRoot, label)
    local held = false
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local list = R.PICK_LISTS[key]
        local settled = SETTLED[list.title] or key:find("^arcanum")
        for _, row in ipairs(GroupRows(rows, "picks" .. key)) do
            if row.option.get() then
                local went = T.Click(row, false)
                if settled then held = true end
                if went and settled then Problem(("%s: %s: a settled pick can be unticked in the dialog opened again"):format(label, key)) end
                if went then T.Click(row, true) end
            elseif T.Click(row, true) then
                Problem(("%s: %s: one more can be ticked though the list is full"):format(label, key))
            end
        end
    end
    for _, row in ipairs(GroupRows(rows, "maneuvers")) do
        if row.option.get() then
            held = true
            if T.Click(row, false) then Problem(label .. ": a maneuver can be unticked in the dialog opened again") end
        elseif T.Click(row, true) then
            Problem(label .. ": one more maneuver can be ticked though the list is full")
        end
    end
    if held and not byKey.settled then Problem(label .. ": picks are held but the dialog doesn't say why") end
    if L.Problem() then Problem(label .. ": the dialog opened again asks: " .. L.Problem()) end
    T.Click(byKey.cancel); FlushTimers()
    if L.draft then Problem(label .. ": Cancel leaves the dialog open") L.draft = nil end
end

-- Finds the Delete button of an entry's page under Customize.
local function DeleteButton(listKey, name)
    ns.RebuildOptions()
    local group = T.Group("customize", listKey)
    for _, page in pairs(group and group.args or {}) do
        if type(page) == "table" and page.type == "group" and page.args and page.args.delete then
            local title = type(page.name) == "function" and page.name() or page.name
            if title == name then return page.args.delete end
        end
    end
end

local function FreeAndFill(label, what, free)
    local sheet = RPSheet:Sheet()
    local before = RPSheet:ExportSheet()
    local name, key = free(sheet)
    if not name then return end
    freed = freed + 1
    -- (The Delete button of a list page leaves the pick in place until the sheet's
    -- next upkeep, so the tab says nothing yet: counted, and handed over.)
    if not ns.OpenClassChoices(sheet) then unsaid = unsaid + 1 end
    if not T.Tab("classChoices") then Problem(label .. ": no choices button") return end
    FlushTimers()
    local rows = T.Rows(levelRoot, label)
    -- of that list: the others are locked, and exactly one more can be ticked
    local ticked = 0
    for _, row in ipairs(GroupRows(rows, key)) do
        if row.option.get() and T.Click(row, false) then Problem(("%s: %s: a kept pick can be unticked after one was freed"):format(label, what)) T.Click(row, true) end
    end
    for _, row in ipairs(GroupRows(rows, key)) do
        if not row.option.get() and T.Click(row, true) then ticked = ticked + 1 end
    end
    if ticked ~= 1 then Problem(("%s: %s: %d picks could be ticked after freeing one"):format(label, what, ticked)) end
    T.Finish(label .. " fill")
    T.Check(label .. " filled", { level = sheet.level })
end

for index, spec in ipairs({ { "EVOKER", 12 }, { "WARLOCK", 14 }, { "PRIEST", 9 }, { "PALADIN", 9 }, { "MAGE", 10 }, { "DRUID", 9 }, { "WARRIOR", 10, "Battle Master" }, { "HUNTER", 9 } }) do
    local key, top, subclass = spec[1], spec[2], spec[3]
    local sheet = T.NewCharacter(key, index + 80)
    if sheet then
        for level = 2, top do T.TakeLevel(nil, { subclass = subclass }, key .. " " .. level) end
        Locks(key .. " opened again")
        -- a class option unticked on its Customize page
        for _, listKey in ipairs({ "metamagic", "invocations" }) do
            FreeAndFill(key .. " " .. listKey, listKey, function()
                if ns.SheetPickLimit(sheet, listKey) == 0 then return end
                local page = T.Group("customize", "classPicks", "list" .. listKey)
                local names = {}
                for name in pairs(sheet.picks[listKey]) do names[#names + 1] = name end
                table.sort(names)
                -- one nothing else builds on
                for _, name in ipairs(names) do
                    local needed = false
                    for other in pairs(sheet.picks[listKey]) do needed = needed or R.PICK_LISTS[listKey].items[other].needs == name end
                    if not needed then
                        for _, option in pairs(page.args) do
                            if option.type == "toggle" and option.name == name then option.set({}, false) return name, "picks" .. listKey end
                        end
                    end
                end
            end)
        end
        if ns.SheetManeuverLimit(sheet) > 0 then
            FreeAndFill(key .. " maneuver", "maneuvers", function()
                local page = T.Group("customize", "classPicks", "maneuvers")
                for _, option in pairs(page.args) do
                    if option.type == "toggle" and option.get() then option.set({}, false) return option.name, "maneuvers" end
                end
            end)
        end
        -- a prepared spell and a cantrip deleted on the Spells page
        for _, listKey in ipairs(R.PICK_LIST_ORDER) do
            local list = R.PICK_LISTS[listKey]
            if (list.title == "Prepared spells" or list.title == "Cantrips") and ns.SheetPickLimit(sheet, listKey) > 0 then
                FreeAndFill(key .. " " .. list.title, list.title, function()
                    local names = {}
                    for name in pairs(sheet.picks[listKey]) do names[#names + 1] = name end
                    table.sort(names)
                    local button = DeleteButton("spells", names[1])
                    if not button then Problem(key .. ": no Delete button for the spell " .. tostring(names[1])) return end
                    button.func({})
                    return names[1], "picks" .. listKey
                end)
            end
        end
        Locks(key .. " opened again after filling")
    end
end
print(("dialogs opened again: %d; places freed under Customize and filled: %d (the tab said nothing about %d of them until the dialog was opened)"):format(reopened, freed, unsaid))
T.Summary("exchanges and locks")
