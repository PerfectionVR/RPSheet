-- Shared by the t-test-levelling-*.lua scripts: a "player" that fills in the level
-- dialog through its options (hidden / disabled / values / get / set, as the dialog
-- library would), and the checks a sheet has to pass after each level.
-- The expected numbers (slots, cantrips, prepared spells, resources, hit dice) were
-- read from the rules site's class tables (2024 rules), not from the addon.
dofile(ARG3 .. "/exercise_head.lua")
dofile(ARG3 .. "/wiz2.lua")
L = ns.LevelDialog
Levels = ns.Levels
levelRoot = REGISTRY:GetOptionsTable(L.DIALOG)("dialog", "AceConfigDialog-3.0")
mainRoot = REGISTRY:GetOptionsTable("RPSheet")("dialog", "AceConfigDialog-3.0")
T = { checks = 0, dialogs = 0, feats = {}, featRound = 0, boonRound = 0, asiRound = 0, pickRound = 0 }
local GREY = "|cff888888"

---------------------------------------------------------------------------
-- Expected numbers, from the rules site
---------------------------------------------------------------------------
local FULL = { "2", "3", "42", "43", "432", "433", "4331", "4332", "43331", "43332", "433321", "433321", "4333211", "4333211",
    "43332111", "43332111", "433321111", "433331111", "433332111", "433332211" }
local HALF = { "2", "2", "3", "3", "42", "42", "43", "43", "432", "432", "433", "433", "4331", "4331", "4332", "4332", "43331", "43331", "43332", "43332" }
local PACT = { { 1, 1 }, { 2, 1 }, { 2, 2 }, { 2, 2 }, { 2, 3 }, { 2, 3 }, { 2, 4 }, { 2, 4 }, { 2, 5 }, { 2, 5 }, { 3, 5 }, { 3, 5 }, { 3, 5 }, { 3, 5 },
    { 3, 5 }, { 3, 5 }, { 4, 5 }, { 4, 5 }, { 4, 5 }, { 4, 5 } }
local function Steps(...)
    local steps, out, value = { ... }, {}, 0
    for level = 1, 20 do
        for index = 1, #steps, 2 do if steps[index] == level then value = steps[index + 1] end end
        out[level] = value
    end
    return out
end
local FULL_PREPARED = { 4, 5, 6, 7, 9, 10, 11, 12, 14, 15, 16, 16, 17, 17, 18, 18, 19, 20, 21, 22 }
local HALF_PREPARED = { 2, 3, 4, 5, 6, 6, 7, 7, 9, 9, 10, 10, 11, 11, 12, 12, 14, 14, 15, 15 }
T.EXPECT = {
    Barbarian = { die = 12, pools = { Rage = Steps(1, 2, 3, 3, 6, 4, 12, 5, 17, 6) } },
    Cleric = { die = 8, cantrips = Steps(1, 3, 4, 4, 10, 5), prepared = FULL_PREPARED, pools = { ["Channel Divinity"] = Steps(2, 2, 6, 3, 18, 4) } },
    Druid = { die = 8, cantrips = Steps(1, 2, 4, 3, 10, 4), prepared = FULL_PREPARED, pools = { ["Wild Shape"] = Steps(2, 2, 6, 3, 17, 4) } },
    Fighter = { die = 10, pools = { ["Second Wind"] = Steps(1, 2, 4, 3, 10, 4) } },
    Monk = { die = 8, pools = { ["Focus Points"] = Steps(2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20) } },
    Paladin = { die = 10, prepared = HALF_PREPARED, pools = { ["Channel Divinity"] = Steps(3, 2, 11, 3) } },
    Ranger = { die = 10, prepared = HALF_PREPARED, pools = { ["Favored Enemy"] = Steps(1, 2, 5, 3, 9, 4, 13, 5, 17, 6) } },
    Rogue = { die = 8 },
    Sorcerer = { die = 6, cantrips = Steps(1, 4, 4, 5, 10, 6), prepared = { 2, 4, 6, 7, 9, 10, 11, 12, 14, 15, 16, 16, 17, 17, 18, 18, 19, 20, 21, 22 },
        pools = { ["Sorcery Points"] = Steps(2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20) },
        picks = { metamagic = Steps(2, 2, 10, 4, 17, 6) } },
    Warlock = { die = 8, cantrips = Steps(1, 2, 4, 3, 10, 4), prepared = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15 },
        picks = { invocations = Steps(1, 1, 2, 3, 5, 5, 7, 6, 9, 7, 12, 8, 15, 9, 18, 10) } },
    Wizard = { die = 6, cantrips = Steps(1, 3, 4, 4, 10, 5), prepared = { 4, 5, 6, 7, 9, 10, 11, 12, 14, 15, 16, 16, 17, 18, 19, 21, 22, 23, 24, 25 } },
}
local CASTER = { Cleric = "FULL", Druid = "FULL", Sorcerer = "FULL", Wizard = "FULL", Paladin = "HALF", Ranger = "HALF", Warlock = "PACT" }

-- The slots a character of these classes should have: { [spell level] = count }, and
-- the pact slots apart when it also has another spellcasting class.
function T.ExpectedSlots(sheet)
    local casters, casterLevel, pactLevel, single = 0, 0, nil, nil
    for _, key in ipairs(ns.ClassKeys(sheet)) do
        local base, level = R.CLASSES[key].base, ns.ClassLevel(sheet, key)
        local kind = CASTER[base]
        if kind == "FULL" then casters, casterLevel, single = casters + 1, casterLevel + level, { FULL, level }
        elseif kind == "HALF" then casters, casterLevel, single = casters + 1, casterLevel + math.ceil(level / 2), { HALF, level }
        elseif kind == "PACT" then pactLevel = level end
    end
    local slots, pact = {}, {}
    if casters == 1 then
        local row = single[1][single[2]]
        for index = 1, #row do slots[index] = tonumber(row:sub(index, index)) end
    elseif casters > 1 then
        local row = FULL[casterLevel]
        for index = 1, #row do slots[index] = tonumber(row:sub(index, index)) end
    end
    if pactLevel then
        local row = PACT[pactLevel]
        if casters == 0 then slots[row[2]] = row[1] else pact[row[2]] = row[1] end
    end
    return slots, pact
end

---------------------------------------------------------------------------
-- The player
---------------------------------------------------------------------------
local function Info(row) return { row.path:match("[^.]+$"), option = row.option, type = row.option.type } end
local function Val(row, key, ...)
    local value = row.option[key]
    if type(value) == "function" then return Try(row.path .. "." .. key, value, Info(row), ...) end
    return value
end

-- The dialog's visible rows, in the order they are drawn.
function T.Rows(root, label)
    local rows = Try("feed " .. label, Feed, root or levelRoot, "level") or {}
    for index, row in ipairs(rows) do
        row.index, row.parent = index, row.path:match("^(.*)%.[^.]+$")
        if row.parent:find("picksspellbook") and row.option.type == "toggle" then
            local spell = (row.name or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub(" %(.*$", "")
            row.mastery = (R.PICK_LISTS.spellMastery1.items[spell] or R.PICK_LISTS.spellMastery2.items[spell] or R.PICK_LISTS.signatureSpells.items[spell]) ~= nil
        end
    end
    table.sort(rows, function(a, b)
        if a.parent ~= b.parent then return a.parent:gsub("picksspellbook", "picks!") < b.parent:gsub("picksspellbook", "picks!") end
        local x, y = a.option.order or 0, b.option.order or 0
        -- spells: the highest level first, as a player would take them; the lists
        -- that need them in the spellbook after the spellbook
        if a.parent:find("picksprepared") or a.parent:find("picksspellbook") then x, y = -x, -y end
        -- (a Mage thinks ahead: spells that Spell Mastery can take come first)
        if a.parent:find("picksspellbook") and a.mastery ~= b.mastery then return a.mastery end
        if x ~= y then return x < y end
        return a.path < b.path
    end)
    local byKey = {}
    for _, row in ipairs(rows) do byKey[row.path:match("[^.]+$")] = row end
    return rows, byKey
end

-- Sets an option the way a click would: only when it is shown and not greyed out.
-- Returns true if the click was possible.
function T.Click(row, value, ...)
    if Val(row, "hidden") then return false end
    if Val(row, "disabled") then return false end
    if row.option.type == "execute" then Try(row.path .. ".func", row.option.func, Info(row)) FlushTimers() return true end
    if row.option.type == "select" then
        local values = Val(row, "values") or {}
        if values[value] == nil then return false end
    elseif row.option.type == "range" then
        if value < row.option.min or value > row.option.max then return false end
    end
    Try(row.path .. ".set", row.option.set, Info(row), value, ...)
    return true
end

-- The choices of a dropdown a player would take: not the empty one, not a greyed one.
function T.Candidates(row)
    local values, names = Val(row, "values") or {}, {}
    local sorting = Val(row, "sorting")
    if sorting then
        for _, key in ipairs(sorting) do if key ~= "" and values[key] and not values[key]:find(GREY, 1, true) then names[#names + 1] = key end end
    else
        for key, text in pairs(values) do if key ~= "" and not text:find(GREY, 1, true) then names[#names + 1] = key end end
        table.sort(names)
    end
    return names
end

local PLANNED = { choice = true, featPick = true, featStat = true, feat = true, featDesc = true }

-- The Ability Score Improvement, feat or boon of the level, as `plan` says or in turn.
local function DecideChoice(byKey, plan)
    local draft = L.draft
    if not draft.kind or draft.decided then return false end
    draft.decided = true
    local want = plan.choice
    if draft.kind == "BOON" then want = "FEAT" end
    if not want then
        T.asiRound = T.asiRound + 1
        want = T.asiRound % 3 == 0 and "ASI" or "FEAT"
    end
    if draft.kind == "ASI" then T.Click(byKey.choice, want) end
    if want == "FEAT" then
        local _, now = T.Rows(levelRoot, "feat")
        local names = T.Candidates(now.featPick)
        local feat = plan.feat
        if not feat then
            -- the feat least taken so far, so that every feat gets its turn
            local best
            for _, name in ipairs(names) do
                if not best or (T.feats[name] or 0) < (T.feats[best] or 0) then best = name end
            end
            feat = best
        end
        if not feat then
            T.Click(byKey.choice, "ASI")
        else
            T.feats[feat] = (T.feats[feat] or 0) + 1
            if not T.Click(now.featPick, feat) then Problem(T.label .. ": can't pick feat " .. tostring(feat)) end
            -- the ability it raises: the first the dialog accepts
            local _, again = T.Rows(levelRoot, "feat stat")
            if again.featStat then
                for _, stat in ipairs(T.Candidates(again.featStat)) do
                    T.Click(again.featStat, stat)
                    local problem = Levels.Problem(L.Sheet(), draft.level, draft.record)
                    if not problem then break end
                end
            end
        end
    end
    return true
end

-- What the plan names is set first, also where the dialog pre-selected something else.
function T.ApplyPlan(plan)
    local _, byKey = T.Rows(levelRoot, T.label)
    for key, row in pairs(byKey) do
        if row.option.type == "select" and type(plan[key]) == "string" and Val(row, "get") ~= plan[key] then
            if not T.Click(row, plan[key]) then Problem(("%s: can't set %s to %s"):format(T.label, key, plan[key])) end
        end
    end
end

-- One pass over the dialog: fills what is empty. Returns how many clicks it made.
function T.Sweep(plan)
    local rows, byKey = T.Rows(levelRoot, T.label)
    local clicks = 0
    if DecideChoice(byKey, plan) then return 1 end
    -- A list that holds more than it allows ("5 of 4 chosen", after going back a
    -- level): the last ones are unticked.
    for _, group in ipairs(rows) do
        local have, limit = (group.option.type == "group" and group.name or ""):match("%((%d+) of (%d+) chosen")
        have, limit = tonumber(have), tonumber(limit)
        if have and have > limit then
            for index = #rows, 1, -1 do
                local row = rows[index]
                if have > limit and row.parent == group.path and row.option.type == "toggle" and Val(row, "get") and T.Click(row, false) then
                    have, clicks = have - 1, clicks + 1
                end
            end
        end
    end
    if clicks > 0 then return clicks end
    for _, row in ipairs(rows) do
        local key, kind = row.path:match("[^.]+$"), row.option.type
        if kind == "select" and not PLANNED[key] then
            local current = Val(row, "get")
            local want = plan[key]
            if want and current ~= want and not L.draft["did" .. key] then
                if T.Click(row, want) then clicks = clicks + 1; L.draft["did" .. key] = true end
            elseif (current == nil or current == "") and not Val(row, "hidden") then
                local names = T.Candidates(row)
                if not want and #names > 0 then
                    T.pickRound = T.pickRound + 1
                    want = names[T.pickRound % #names + 1]
                end
                if want and T.Click(row, want) then clicks = clicks + 1 end
            end
        elseif kind == "toggle" then
            if not Val(row, "hidden") and not Val(row, "get") and not Val(row, "disabled") then
                local name = Val(row, "name") or ""
                if not name:find(GREY, 1, true) and not (plan.avoid and plan.avoid[row.path]) then
                    if T.Click(row, true) then clicks = clicks + 1 end
                end
            end
        elseif kind == "range" and key:find("^asi") then
            if not Val(row, "hidden") and not Val(row, "disabled") and row.option.max > (Val(row, "get") or 0) then
                if T.Click(row, row.option.max) then clicks = clicks + 1 end
            end
        end
    end
    return clicks
end

-- Fills the open dialog until nothing is asked for any more. Returns true when it
-- can be confirmed.
function T.Fill(plan)
    plan = plan or {}
    for pass = 1, 60 do
        local problem = Try(T.label .. " L.Problem", L.Problem)
        if not problem then return true end
        if T.Sweep(plan) == 0 then
            Problem(("%s: the dialog can't be completed: %s"):format(T.label, tostring(problem)))
            return false
        end
    end
    Problem(T.label .. ": the dialog never settles: " .. tostring(L.Problem()))
    return false
end

function T.Confirm()
    local _, byKey = T.Rows(levelRoot, T.label .. " confirm")
    if not T.Click(byKey.confirm) then Problem(T.label .. ": the confirm button can't be pressed: " .. tostring(L.Problem())) return false end
    FlushTimers()
    -- An earlier level with an open choice opens next by itself; the tests don't want that.
    return true
end

-- Takes the next level in `classKey` (the first class when left out). Returns true
-- when the level was taken.
function T.TakeLevel(classKey, plan, label)
    local sheet = RPSheet:Sheet()
    local before = sheet.level
    T.label = label or ("%s to %d"):format(classKey or sheet.class, before + 1)
    Try(T.label .. " open", ns.OpenLevelDialog, nil, false, classKey); FlushTimers()
    if not L.draft then Problem(T.label .. ": the dialog didn't open") return false end
    T.dialogs = T.dialogs + 1
    T.ApplyPlan(plan or {})
    if plan and plan.inspect then plan.inspect() end
    if not T.Fill(plan) then L.draft = nil return false end
    if plan and plan.before then plan.before() end
    if not T.Confirm() then L.draft = nil return false end
    -- A feat taken here may have choices the dialog asks next (the skills of Skilled).
    T.label = T.label .. " (follow-up)"
    for guard = 1, 3 do
        if not L.draft then break end
        if L.draft.kind then L.draft.decided = true end
        if not T.Fill({}) or not T.Confirm() then L.draft = nil end
    end
    if L.draft then Problem(T.label .. ": dialogs keep opening") L.draft = nil end
    if sheet.level ~= before + 1 then Problem(("%s: level is %d after taking the level"):format(T.label, sheet.level)) return false end
    return true
end

-- Opens the dialog for a level the character has (the "choices" button when `slot`
-- is left out), fills what is open and saves.
function T.Reopen(slot, plan, label)
    local sheet = RPSheet:Sheet()
    slot = slot or ns.LevelSlot(sheet, sheet.class, ns.ClassLevel(sheet, sheet.class))
    T.label = label or ("reopen " .. slot)
    Try(T.label .. " open", ns.OpenLevelDialog, slot, false); FlushTimers()
    if not L.draft then Problem(T.label .. ": the dialog didn't open") return false end
    if L.draft.kind then L.draft.decided = Levels.Record(sheet, slot) ~= nil and not Levels.Problem(sheet, slot, Levels.Record(sheet, slot)) end
    if not T.Fill(plan) then L.draft = nil return false end
    if not T.Confirm() then L.draft = nil return false end
    for guard = 1, 10 do -- the next open level opens by itself
        if not L.draft then break end
        if not T.Fill(plan) or not T.Confirm() then L.draft = nil end
    end
    return true
end

---------------------------------------------------------------------------
-- The checks after each level
---------------------------------------------------------------------------
local function Count(set) local n = 0 for _ in pairs(set or {}) do n = n + 1 end return n end
T.Count = Count

function T.RedLines(sheet)
    local out = {}
    local text = Try("summary", mainRoot.args.character.args.summary.name) or ""
    for line in text:gmatch("[^\n]+") do
        if line:find(Opt.RED, 1, true) and not line:find("Hero classes normally start") then out[#out + 1] = line end
    end
    return out
end

local function HasEntry(sheet, name)
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for _, entry in ipairs(list) do if entry.name == name or entry.name:sub(1, #name + 1) == name .. ":" then return true end end
    end
    return false
end
T.HasEntry = HasEntry

-- `want` may carry: level, classes = { KEY = level }, noFeatures (skip the feature check)
function T.Check(label, want)
    want = want or {}
    local sheet = RPSheet:Sheet()
    T.checks = T.checks + 1
    local function Bad(text, ...) Problem(label .. ": " .. text:format(...)) end
    if want.level and sheet.level ~= want.level then Bad("level %d, expected %d", sheet.level, want.level) end
    local total = 0
    for _, key in ipairs(ns.ClassKeys(sheet)) do total = total + ns.ClassLevel(sheet, key) end
    if total ~= sheet.level then Bad("class levels add up to %d, level is %d", total, sheet.level) end
    for key, level in pairs(want.classes or {}) do
        if ns.ClassLevel(sheet, key) ~= level then Bad("%s level %d, expected %d", key, ns.ClassLevel(sheet, key), level) end
    end
    -- nothing waiting (want.open: choices may be open, after going back a level)
    if not want.open then T.CheckSettled(label, sheet) end
    T.CheckNumbers(label, sheet, want)
end

function T.CheckSettled(label, sheet)
    local function Bad(text, ...) Problem(label .. ": " .. text:format(...)) end
    for _, line in ipairs(T.RedLines(sheet)) do Bad("red on the Character tab: %s", line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
    local pending = Levels.Pending(sheet)
    if #pending > 0 then Bad("level choices pending: %s", table.concat(pending, ",")) end
    if ns.OpenClassChoices(sheet) then Bad("OpenClassChoices is true") end
    -- counts against limits
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local limit, known = ns.SheetPickLimit(sheet, key), ns.PicksKnown(sheet, key)
        if limit > 0 and known ~= limit then Bad("%s: %d picked, limit %d", key, known, limit) end
        if limit > 0 and Count(sheet.picks[key]) ~= known then Bad("%s: %d stored picks, %d of them known", key, Count(sheet.picks[key]), known) end
    end
    local maneuvers = ns.SheetManeuverLimit(sheet)
    if maneuvers > 0 and ns.ManeuversKnown(sheet) ~= maneuvers then Bad("maneuvers %d, limit %d", ns.ManeuversKnown(sheet), maneuvers) end
    local expertise = ns.ExpertiseLimit(sheet)
    if expertise > 0 and ns.ExpertiseKnown(sheet) ~= expertise then Bad("expertise %d, limit %d", ns.ExpertiseKnown(sheet), expertise) end
    for skill in pairs(sheet.expertise) do
        if (sheet.skills[skill] or 0) < 2 then Bad("expertise in %s but the skill is at %s", skill, tostring(sheet.skills[skill])) end
    end
    if ns.FeatSkillLimit(sheet) > 0 and ns.FeatSkillsKnown(sheet) ~= ns.FeatSkillLimit(sheet) then Bad("feat skills %d, limit %d", ns.FeatSkillsKnown(sheet), ns.FeatSkillLimit(sheet)) end
    if ns.OpenFeatChoices(sheet) then Bad("a feat has an open choice") end
    for _, feature in ipairs(ns.OpenOptionFeatures(sheet)) do Bad("feature %s has no option picked", feature.name) end
    for _, slot in ipairs(ns.StyleSlots(sheet)) do
        if not R.FIGHTING_STYLES[slot.name] then Bad("a Fighting Style of %s is empty", tostring(slot.class)) end
    end
end

function T.CheckNumbers(label, sheet, want)
    local function Bad(text, ...) Problem(label .. ": " .. text:format(...)) end
    -- the numbers the rules give
    local views = ns.ClassViews(sheet)
    local hp, con = 0, RPSheet:Mod("CON")
    for index, view in ipairs(views) do
        local class = R.CLASSES[view.class]
        local expect = T.EXPECT[class.base]
        if class.hitDie ~= expect.die then Bad("%s hit die d%d, expected d%d", view.class, class.hitDie, expect.die) end
        hp = hp + (index == 1 and expect.die or 0) + (expect.die / 2 + 1) * (view.level - (index == 1 and 1 or 0))
        if view.level >= R.SUBCLASS_LEVEL and view.subclass == "" and not want.open then Bad("%s has no subclass at level %d", view.class, view.level) end
        -- class resources
        local removed = {}
        for _, name in ipairs((R.CLASS_OVERRIDES[view.class] or {}).removePools or {}) do removed[name] = true end
        for name, steps in pairs(expect.pools or {}) do
            local tracker = RPSheet:FindTracker(name)
            local have = tracker and tracker.max or 0
            if not removed[name] and #views == 1 and have ~= steps[view.level] then Bad("%s is %d, expected %d", name, have, steps[view.level]) end
        end
        for key, steps in pairs(expect.picks or {}) do
            if ns.SheetPickLimit(sheet, key) ~= steps[view.level] then Bad("%s limit %d, expected %d", key, ns.SheetPickLimit(sheet, key), steps[view.level]) end
        end
        for _, key in ipairs(R.PICK_LIST_ORDER) do
            local list = R.PICK_LISTS[key]
            if list.base == class.base and list.title == "Cantrips" and expect.cantrips and ns.SheetPickLimit(sheet, key) ~= expect.cantrips[view.level] then
                Bad("%s cantrips limit %d, expected %d", view.class, ns.SheetPickLimit(sheet, key), expect.cantrips[view.level])
            end
            if list.base == class.base and list.title == "Prepared spells" and expect.prepared and ns.SheetPickLimit(sheet, key) ~= expect.prepared[view.level] then
                Bad("%s prepared limit %d, expected %d", view.class, ns.SheetPickLimit(sheet, key), expect.prepared[view.level])
            end
        end
        -- features
        if not want.noFeatures then
            for level = 1, view.level do
                for _, feature in ipairs(ns.FeaturesGainedAt(view.class, view.subclass, level)) do
                    if not HasEntry(sheet, feature.name) and not T.FeatureElsewhere(sheet, feature, view) then
                        Bad("feature %s (%s level %d) is not on the sheet", feature.name, view.class, level)
                    end
                end
            end
        end
    end
    hp = hp + con * sheet.level + T.ExtraHP(sheet)
    if RPSheet:MaxHP() ~= hp then Bad("maximum HP %d, expected %d", RPSheet:MaxHP(), hp) end
    local state = RPSheet:State()
    if type(state.hp) == "number" and state.hp > RPSheet:MaxHP() then Bad("current HP %d above the maximum %d", state.hp, RPSheet:MaxHP()) end
    if state.hp ~= RPSheet:MaxHP() and not want.hurt then Bad("current HP %s of %d", tostring(state.hp), RPSheet:MaxHP()) end
    -- hit dice: one per level
    local dice = 0
    for _, tracker in ipairs(RPSheet:GetTrackers()) do
        if tracker.kind == "hitdice" then
            dice = dice + tracker.max
            if tracker.get() ~= tracker.max then Bad("%s: %s of %d", tracker.label, tostring(tracker.get()), tracker.max) end
        elseif tracker.kind ~= "hp" and (tracker.get() or 0) > tracker.max then
            Bad("%s holds %s of %d", tracker.label, tostring(tracker.get()), tracker.max)
        end
    end
    if dice ~= sheet.level then Bad("%d hit dice at level %d", dice, sheet.level) end
    if RPSheet:ProficiencyBonus() ~= math.ceil(sheet.level / 4) + 1 then Bad("proficiency bonus %d", RPSheet:ProficiencyBonus()) end
    -- spell slots
    local slots, pactSlots = ns.SheetSlots(sheet)
    local wantSlots, wantPact = T.ExpectedSlots(sheet)
    for spellLevel = 1, 9 do
        if (slots[spellLevel] or 0) ~= (wantSlots[spellLevel] or 0) then Bad("%d slots of level %d, expected %d", slots[spellLevel] or 0, spellLevel, wantSlots[spellLevel] or 0) end
        if ((pactSlots or {})[spellLevel] or 0) ~= (wantPact[spellLevel] or 0) then Bad("%d pact slots of level %d, expected %d", (pactSlots or {})[spellLevel] or 0, spellLevel, wantPact[spellLevel] or 0) end
    end
    -- scores
    for _, stat in ipairs(R.STATS) do
        local natural = RPSheet:NaturalScore(stat, true)
        local capstone = (sheet.featureScores[stat] or 0) > 0 -- a level 20 feature that lifts the score and its cap
        if natural > R.BOON_MAX_SCORE or (natural > R.MAX_SCORE and not T.BoonRaised(sheet, stat) and not capstone) then Bad("%s is %d", stat, natural) end
    end
    -- nothing twice
    local seen = {}
    for _, list in ipairs({ sheet.abilities, sheet.passives, sheet.spells }) do
        for _, entry in ipairs(list) do
            if entry.auto and entry.auto ~= "" then
                if seen[entry.auto] then Bad("two entries marked %s (%s)", entry.auto, tostring(entry.name)) end
                seen[entry.auto] = true
            end
        end
    end
    local spellSeen = {}
    for _, spell in ipairs(sheet.spells) do
        -- two classes may each prepare the same spell: the entries name their class
        local id = spell.name .. "/" .. tostring(spell.class or "")
        if spellSeen[id] then Bad("spell %s is on the sheet twice", id) end
        spellSeen[id] = true
    end
end

function T.BoonRaised(sheet, stat)
    for slot, record in pairs(sheet.levels) do
        if ns.HasSlot(sheet, slot) and Levels.Kind(sheet, slot) == "BOON" and (record.asi[stat] or 0) > 0 then return true end
    end
    return false
end

-- Hit points on top of the hit dice and Constitution. Filled in by the scripts'
-- findings: each source is a rule, named here so the check stays independent.
function T.ExtraHP(sheet)
    local extra = 0
    for _, passive in ipairs(sheet.passives) do
        if passive.name == "Tough" then extra = extra + 2 * sheet.level end
        if passive.name == "Boon of Fortitude" then extra = extra + 40 end
        if passive.name == "Pet Specialization: Tenacity" and passive.enabled then extra = extra + ns.SubclassLevel(sheet, "Beast Master") end
    end
    local sorcerer = ns.SubclassLevel and ns.SubclassLevel(sheet, "Draconic Sorcery") or 0
    if sorcerer >= 3 then extra = extra + sorcerer end
    if sheet.species == "DWARF" then extra = extra + sheet.level end
    return extra
end

-- A feature that isn't on the sheet under its own name for a good reason.
function T.FeatureElsewhere(sheet, feature, view)
    -- only with a specialization, an option or a condition the bare check can't know
    if feature.when or feature.option or feature.spec then return true end
    return false
end

---------------------------------------------------------------------------
-- Characters
---------------------------------------------------------------------------
-- A level 1 character from the creation wizard. Scores are then set so that every
-- class is open to it (13 in everything): the tests are about levels, not point buy.
function T.NewCharacter(classKey, n, open)
    local sheet = Make({ label = classKey .. " start", class = classKey, level = 1, species = "HUMAN", background = R.BACKGROUND_ORDER[(n or 1) % #R.BACKGROUND_ORDER + 1], n = n or 1 })
    if not sheet then Problem(classKey .. ": the wizard didn't make a character") return end
    if open then
        for _, stat in ipairs(R.STATS) do sheet.base[stat] = math.max(sheet.base[stat], 13) end
        ns.ApplyGrants(sheet); ns.NormalizeState(RPSheet:State()); RPSheet:ClampState(true); RPSheet:SheetChanged()
    end
    -- The wizard opens the level dialog for what it didn't ask (the origin feat's choices).
    T.label = classKey .. " after the wizard"
    for guard = 1, 5 do
        if not L.draft then break end
        if not T.Fill({}) or not T.Confirm() then L.draft = nil end
    end
    return sheet
end

-- The Character tab's buttons, pressed as a player would.
function T.Tab(key, value)
    local _, byKey = T.Rows(mainRoot.args.character, "character tab")
    local row = byKey[key]
    if not row then Problem("Character tab: no " .. key .. " shown") return false end
    return T.Click(row, value)
end

-- Fills and confirms whatever dialog is open, and those that follow it.
function T.Finish(label, plan)
    T.label = label
    for guard = 1, 12 do
        if not L.draft then return true end
        if L.draft.kind then
            local record = Levels.Record(RPSheet:Sheet(), L.draft.level)
            L.draft.decided = L.draft.decided or (not L.draft.taking and record ~= nil and not Levels.Problem(RPSheet:Sheet(), L.draft.level, record))
        end
        if not T.Fill(plan or {}) or not T.Confirm() then L.draft = nil return false end
    end
    Problem(label .. ": dialogs keep opening") L.draft = nil
    return false
end

-- A group of the main options by the names on the way to it, e.g. ("customize", "spells").
function T.Group(...)
    local group = mainRoot
    for _, key in ipairs({ ... }) do
        group = group and group.args and group.args[key]
    end
    return group
end

function T.Summary(name)
    local problems = 0
    for _ in pairs(PROBLEMS) do problems = problems + 1 end
    print(("%s: %d dialogs, %d checks, %d problems"):format(name, T.dialogs, T.checks, problems))
end
