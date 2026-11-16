-- Shared start for the window tests: the fake game (env.lua), the fake UI with the real
-- options library (t-test-windows-ui.lua), the addon, and helpers to build characters,
-- find the parts of a window and report problems. A test begins with
--     dofile(ARG3 .. "/t-test-windows-base.lua")
dofile(ARG3 .. "/env.lua")
dofile(ARG3 .. "/t-test-windows-ui.lua")
F = UIFAKE
AceGUI, AceConfigDialog = F.AceGUI, F.AceConfigDialog

NUM_CHAT_WINDOWS = 10
RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"
SENT = {}
C_ChatInfo = { SendChatMessage = function(msg) SENT[#SENT + 1] = msg end }
function RandomRoll(low, high)
    local ok, err = pcall(function()
        NS.addon:CHAT_MSG_SYSTEM(nil, ("Tester rolls %d (%d-%d)"):format(math.random(low, high), low, high))
    end)
    if not ok then Problem("roll callback: " .. tostring(err)) end
end

PROBLEMS, PROBLEM_COUNT = {}, 0
local function Short(text)
    return (tostring(text):gsub("%S*RPSheet/", ""):gsub("%S*AddOns/RPSheet/", ""))
end
function Problem(text)
    text = Short(text)
    if not PROBLEMS[text] then
        PROBLEMS[text] = true
        PROBLEM_COUNT = PROBLEM_COUNT + 1
        print("PROBLEM: " .. text)
        io.stdout:flush()
    end
end
-- Runs fn; an error becomes a problem under `label` (once per place it was raised).
local seenErrors = {}
function Try(label, fn, ...)
    local res = { xpcall(fn, function(m) return debug.traceback(tostring(m), 2) end, ...) }
    if not res[1] then
        local trace = Short(res[2])
        local first = trace:match("^[^\n]*") or ""
        if not seenErrors[first] then
            seenErrors[first] = true
            Problem(label .. ": " .. trace:sub(1, 1200))
        end
        return nil
    end
    return unpack(res, 2)
end

-- The addon and the libraries hide errors in pcall and safecall. Both are listened to:
-- a hidden error is still an error the player would have had, only silently.
HIDDEN = {}
do
    local real = pcall
    function pcall(fn, ...)
        local res = { real(fn, ...) }
        if not res[1] then HIDDEN[#HIDDEN + 1] = Short(res[2]) end
        return unpack(res, 1, table.maxn(res))
    end
    -- the libraries' safecall hands errors to the error handler
    function geterrorhandler()
        return function(e) HIDDEN[#HIDDEN + 1] = Short(debug.traceback(tostring(e), 2)) end
    end
end
-- Reports what was hidden since the last call, under `label`.
function CheckHidden(label)
    for _, text in ipairs(HIDDEN) do
        local first = text:match("^[^\n]*") or ""
        if not seenErrors[first] then
            seenErrors[first] = true
            Problem(label .. " (hidden error): " .. text:sub(1, 900))
        end
    end
    HIDDEN = {}
end

LoadAddon()
ns = NS
R, RPSheet, W, Opt, UI = ns.Rules, ns.addon, ns.Wizard, ns.Opt, ns.UI
Skin = ns.DialogSkin
REGISTRY = LibStub("AceConfigRegistry-3.0")

-- The addon started as at login, with the sheet window really built. `shown` false
-- leaves the window closed as on a first login.
function Start(shown)
    Try("OnInitialize", function() RPSheet:OnInitialize() end)
    if shown ~= false then RPSheet.db.char.shown = true end
    Try("OnEnable", function() RPSheet:OnEnable() end)
    -- no wizard popping up over every test: this profile counts as having met it
    if RPSheet.State then RPSheet:State().created = true end
    RunTimers()
    CheckHidden("start")
end

-- A character of a class at a level, as smoke.lua makes them.
function NewCharacter(key, subclass, spec, level, n)
    n = n or 1
    local sheet = ns.NewSheet()
    for _, list in ipairs(R.PICK_LIST_ORDER) do sheet.picks[list] = {} end
    local class = R.CLASSES[key]
    sheet.class, sheet.level = key, level
    sheet.subclass = (level >= 3 or class.hero) and (subclass or class.subclasses[1]) or ""
    sheet.spec = spec or class.specs[n % #class.specs + 1]
    sheet.species = R.SPECIES_ORDER[n % #R.SPECIES_ORDER + 1]
    sheet.background = R.BACKGROUND_ORDER[n % #R.BACKGROUND_ORDER + 1]
    sheet.allegiance = R.ALLEGIANCE_ORDER[n % #R.ALLEGIANCE_ORDER + 1]
    local lineages = R.LINEAGES[sheet.species]
    if lineages then sheet.lineage = lineages.options[n % #lineages.options + 1].name end
    sheet.base = { STR = 15, DEX = 14, CON = 13, INT = 12, WIS = 10, CHA = 8 }
    for index = 1, class.skillCount do sheet.skills[class.skills[index]] = 1 end
    return sheet
end
-- Takes every pick the character's lists allow (cantrips, prepared spells, a Mage's
-- spellbook, invocations...), the first names that are open to it.
function FillPicks(sheet)
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local limit, view = ns.SheetPickLimit(sheet, key), ns.ListView(sheet, key)
        if limit > 0 and view then
            sheet.picks[key] = sheet.picks[key] or {}
            local picked, names = sheet.picks[key], {}
            for name in pairs(R.PICK_LISTS[key].items) do names[#names + 1] = name end
            table.sort(names)
            local count = ns.PicksKnown(sheet, key)
            for _ = 1, 2 do -- twice: some options need another one first
                for _, name in ipairs(names) do
                    if count >= limit then break end
                    if not picked[name] and not ns.PickBlocked(key, name, view.level, picked, view.subclass, sheet) then
                        picked[name] = true
                        count = count + 1
                    end
                end
            end
        end
    end
end

-- Makes it the active character. `plain` leaves its picks as they are.
function Use(sheet, plain)
    if not plain then Try("fill picks", FillPicks, sheet) end
    ns.ApplyGrants(sheet)
    RPSheet:ReplaceSheet(sheet)
    RPSheet:State().created = true
    RPSheet.busy = false
    F.Settle(true)
    return RPSheet:Sheet()
end

-- Every AceGUI part inside a container, the container first.
function Parts(root, out)
    out = out or {}
    out[#out + 1] = root
    if type(root.children) == "table" then
        for _, child in ipairs(root.children) do Parts(child, out) end
    end
    return out
end

-- The smoke checks of a sheet: its numbers work out and its settings pages can be read.
local function Member(option, key, path, info)
    local value = option[key]
    if type(value) == "function" then return Try(path .. "." .. key, value, info) end
    return value
end
local function FeedOptions(group, path)
    for key, option in pairs(group.args) do
        local p = path .. "." .. key
        local info = { key, option = option, type = option.type }
        local hidden = Member(option, "hidden", p, info)
        local name = Member(option, "name", p, info)
        if type(name) ~= "string" then Problem(p .. ".name is " .. type(name)) end
        if not hidden then
            Member(option, "desc", p, info)
            Member(option, "disabled", p, info)
            if option.type == "group" then
                FeedOptions(option, p)
            elseif option.type == "select" or option.type == "multiselect" then
                local values = Member(option, "values", p, info)
                if type(values) ~= "table" then Problem(p .. ".values is " .. type(values)) end
                if option.type == "select" then Member(option, "get", p, info) end
            elseif option.type == "range" then
                local current = Member(option, "get", p, info)
                if type(current) ~= "number" then Problem(p .. ".get gives " .. type(current)) end
            elseif option.type == "toggle" or option.type == "input" then
                Member(option, "get", p, info)
            end
        end
    end
end
function SmokeChecks(label)
    Try(label .. " smoke", function()
        local sheet = RPSheet:Sheet()
        RPSheet:GetTrackers()
        local data = RPSheet:GetStatData(); RPSheet:GetStatLines(data); RPSheet:Summary()
        RPSheet:AC(); RPSheet:MaxHP(); RPSheet:Speed(); RPSheet:Initiative(); RPSheet:PassivePerception(); RPSheet:Languages()
        RPSheet:ExplainAC(); RPSheet:ExplainInitiative(); RPSheet:ExplainSpeed()
        for _, stat in ipairs(R.STATS) do RPSheet:SaveMod(stat); RPSheet:CheckMod(stat); RPSheet:ExplainCheck(stat); RPSheet:ExplainSave(stat) end
        for _, skill in ipairs(R.SKILLS) do RPSheet:SkillMod(skill); RPSheet:ExplainSkill(skill) end
        for _, passive in ipairs(sheet.passives) do
            if type(passive.name) ~= "string" or type(passive.desc) ~= "string" then error("passive name/desc is " .. type(passive.name) .. "/" .. type(passive.desc)) end
            for _, effect in ipairs(passive.effects or {}) do RPSheet:EffectText(effect) end
        end
        for _, ability in ipairs(sheet.abilities) do
            if type(ability.name) ~= "string" or type(ability.desc) ~= "string" then error("ability name/desc is " .. type(ability.name)) end
            for _, action in ipairs(ability.actions or {}) do RPSheet:ActionText(action) end
        end
        for _, spell in ipairs(sheet.spells) do RPSheet:SpellText(spell); RPSheet:ExplainSpell(spell) end
        for _, weapon in ipairs(ns.ReadyWeapons(sheet)) do RPSheet:WeaponText(weapon); RPSheet:ExplainWeapon(weapon) end
        ns.RebuildOptions()
        FeedOptions(REGISTRY:GetOptionsTable("RPSheet")("dialog", "AceConfigDialog-3.0"), "options")
    end)
end

-- The summary line every test ends with.
function Finish(name, what)
    local templates = {}
    for template in pairs(F.unknownTemplates) do templates[#templates + 1] = template end
    if #templates > 0 then Problem("frame templates the fake UI doesn't know: " .. table.concat(templates, ", ")) end
    for _, loop in ipairs(F.sizeLoops) do Problem("frames that keep resizing each other: " .. loop) end
    for index = 1, math.min(3, #F.cycles) do Problem("frames anchored in a circle: " .. F.cycles[index]) end
    CheckHidden("end")
    print(("%s: %s; %d problem%s"):format(name, what, PROBLEM_COUNT, PROBLEM_COUNT == 1 and "" or "s"))
    io.stdout:flush()
end

dofile(ARG3 .. "/t-test-windows-walk.lua")
