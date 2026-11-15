-- The random-play tester's core, for t-fuzz-play.lua and t-fuzz-cases.lua.
--
-- A SCENARIO is a list of steps. Each step is { a = action name, p = { what was
-- chosen, by name }, seed = number for the dice }. The first step makes the
-- character. Played at random, every choice an action makes goes through Z.Choose /
-- Z.Int / Z.Flip, which draw from the scenario's random source and write the choice
-- into the step; played again, the same functions read the choice back, so a
-- scenario replays the same way and still means something after the rules data
-- changed (a choice that is gone skips its step).
--
-- A WORLD is one game session. Z.Reset() throws the whole Lua side of the game away
-- (fake UI, libraries, addon) and loads it again, as /reload does, keeping only what
-- the game keeps: the saved variables, as text. Every scenario starts from a world
-- with no saved variables.
--
-- After every step every INVARIANT (t-fuzz-checks-lib.lua) is asked for a problem.
FUZZ = { actions = {}, order = {}, invariants = {}, invariantOrder = {} }
local Z = FUZZ
local HERE = ARG3

---------------------------------------------------------------------------
-- The game's globals as they were before anything was loaded
---------------------------------------------------------------------------
local PRISTINE, LIBRARIES = {}, {}
for key, value in pairs(_G) do PRISTINE[key] = value end
for _, name in ipairs({ "string", "table", "math", "os", "io", "debug", "coroutine" }) do
    LIBRARIES[name] = {}
    for key, value in pairs(_G[name]) do LIBRARIES[name][key] = value end
end
PRISTINE.FUZZ = Z
Z.pcall, Z.loadfile = pcall, loadfile

-- Files are read and compiled once; a reload runs them again.
local chunks = {}
local function CachedLoad(path)
    local chunk = chunks[path]
    if not chunk then
        local problem
        chunk, problem = Z.loadfile(path)
        if not chunk then return nil, problem end
        chunks[path] = chunk
    end
    return chunk
end

local function Pristine()
    setmetatable(_G, nil)
    for key in pairs(_G) do
        if PRISTINE[key] == nil then rawset(_G, key, nil) end
    end
    for key, value in pairs(PRISTINE) do rawset(_G, key, value) end
    for name, members in pairs(LIBRARIES) do
        local library = _G[name]
        for key in pairs(library) do if members[key] == nil then library[key] = nil end end
        for key, value in pairs(members) do library[key] = value end
    end
    loadfile = CachedLoad
    dofile = function(path)
        local chunk, problem = CachedLoad(path)
        if not chunk then error(problem, 2) end
        return chunk()
    end
end

---------------------------------------------------------------------------
-- Random numbers of our own (the addon's dice use math.random, seeded per step)
---------------------------------------------------------------------------
function Z.Rng(seed)
    local state = math.floor(seed) % 2147483646 + 1
    local rng = {}
    function rng:next()
        state = (state * 48271) % 2147483647
        return state
    end
    function rng:int(low, high) return low + math.floor(self:next() / 2147483647 * (high - low + 1)) end
    function rng:chance(p) return self:next() / 2147483647 < p end
    for _ = 1, 5 do rng:next() end
    return rng
end

-- Thrown by an action that finds it can't be done after all: the step is skipped.
Z.SKIP = {}
function Z.Skip() error(Z.SKIP, 0) end

-- One of `list` (strings, or anything with `label` giving its name). The choice the
-- step names under `key` is taken when it is there; otherwise one at random, which
-- is then written into the step. Returns the item and its name.
function Z.Choose(key, list, label)
    local step = Z.step
    local names, byName = {}, {}
    for _, item in ipairs(list) do
        local name = label and label(item) or item
        if name ~= nil then
            name = type(name) == "string" and name or tostring(name)
            if byName[name] == nil then byName[name] = item; names[#names + 1] = name end
        end
    end
    if #names == 0 then Z.Skip() end
    local wanted = step.p[key]
    if wanted ~= nil and byName[tostring(wanted)] ~= nil then return byName[tostring(wanted)], tostring(wanted) end
    table.sort(names)
    local name = names[Z.rng:int(1, #names)]
    step.p[key] = name
    return byName[name], name
end
-- The same without a name of its own: the n-th choice of the step.
function Z.Pick(list, label)
    Z.picks = Z.picks + 1
    return Z.Choose("#" .. Z.picks, list, label)
end
function Z.Int(key, low, high)
    local step = Z.step
    if high < low then Z.Skip() end
    local wanted = tonumber(step.p[key])
    if wanted and wanted >= low and wanted <= high then return wanted end
    local value = Z.rng:int(low, high)
    step.p[key] = value
    return value
end
function Z.Flip(key, p)
    local step = Z.step
    if type(step.p[key]) == "boolean" then return step.p[key] end
    local value = Z.rng:chance(p or 0.5)
    step.p[key] = value
    return value
end
-- The list in a random order (not written into the step).
function Z.Shuffle(list)
    local out = {}
    for index, item in ipairs(list) do out[index] = item end
    for index = #out, 2, -1 do
        local other = Z.rng:int(1, index)
        out[index], out[other] = out[other], out[index]
    end
    return out
end

---------------------------------------------------------------------------
-- Saved variables as text, the way the game writes them to disk
---------------------------------------------------------------------------
-- Returns the text, or nil and what can't be saved.
function Z.Serialize(value)
    local out, seen, problem = {}, {}, nil
    local function Key(key)
        local kind = type(key)
        if kind == "string" then return ("[%q]"):format(key) end
        if kind == "number" or kind == "boolean" then return "[" .. tostring(key) .. "]" end
        problem = problem or ("a key that is a " .. kind)
        return "[0]"
    end
    local function Write(item, path)
        local kind = type(item)
        if kind == "string" then out[#out + 1] = ("%q"):format(item)
        elseif kind == "number" then
            if item ~= item or item == math.huge or item == -math.huge then problem = problem or ("a number that is not one at " .. path) end
            out[#out + 1] = ("%.17g"):format(item)
        elseif kind == "boolean" then out[#out + 1] = tostring(item)
        elseif kind == "table" then
            if IsStub(item) then problem = problem or ("a stand-in at " .. path) out[#out + 1] = "nil" return end
            if seen[item] then problem = problem or ("a table inside itself at " .. path) out[#out + 1] = "nil" return end
            seen[item] = true
            local keys = {}
            for key in pairs(item) do keys[#keys + 1] = key end
            table.sort(keys, function(a, b)
                if type(a) ~= type(b) then return type(a) < type(b) end
                if type(a) == "boolean" then return tostring(a) < tostring(b) end
                return a < b
            end)
            out[#out + 1] = "{"
            for _, key in ipairs(keys) do
                out[#out + 1] = Key(key) .. "="
                Write(item[key], path .. "." .. tostring(key))
                out[#out + 1] = ","
            end
            out[#out + 1] = "}"
            seen[item] = nil
        else
            problem = problem or ("a " .. kind .. " at " .. path)
            out[#out + 1] = "nil"
        end
    end
    Write(value, "RPSheetDB")
    return table.concat(out), problem
end
function Z.Deserialize(text)
    return setfenv(assert(loadstring("return " .. text)), {})()
end

---------------------------------------------------------------------------
-- The world
---------------------------------------------------------------------------
-- What survives a reload besides the addon's saved variables: Total RP 3's own.
Z.trp3 = false -- or { current = id, profiles = { id = { profileName = } } }

local function InstallTRP3()
    local trp3 = Z.trp3
    local callbacks = {}
    local Addon = { Events = { REGISTER_PROFILES_LOADED = "REGISTER_PROFILES_LOADED" } }
    function Addon:TriggerEvent(event, ...)
        for _, callback in ipairs(callbacks[event] or {}) do callback(event, ...) end
    end
    local API = { globals = { player_id = "Tester-Realm" }, profile = {} }
    function API.RegisterCallback(_, event, callback)
        callbacks[event] = callbacks[event] or {}
        table.insert(callbacks[event], callback)
    end
    function API.profile.getPlayerCurrentProfileID() return trp3.current end
    function API.profile.getPlayerCurrentProfile() return trp3.profiles[trp3.current] end
    function API.profile.selectProfile(id)
        trp3.current = id
        Addon:TriggerEvent(Addon.Events.REGISTER_PROFILES_LOADED, trp3.profiles[id])
    end
    rawset(_G, "TRP3_API", API)
    rawset(_G, "TRP3_Addon", Addon)
    rawset(_G, "AddOn_TotalRP3", { Player = { GetCurrentUser = function()
        return { GetFirstName = function() return trp3.profiles[trp3.current].firstName end }
    end } })
end

-- Loads the game side again. `saved` is the text of the saved variables, or nil for
-- a first login.
function Z.Reset(saved)
    Pristine()
    collectgarbage()
    dofile(HERE .. "/t-test-windows-base.lua")
    -- The real saved-variables library: defaults are taken out at logout and laid
    -- under the data at login, as in the game.
    function UnitClass() return "Warrior", "WARRIOR", 1 end
    function UnitRace() return "Human", "Human", 1 end
    function UnitFactionGroup() return "Alliance", "Alliance" end
    function GetCurrentRegion() return 3 end
    function UnitNameUnmodified() return "Tester" end
    rawset(_G, "RegionalUniqueNamesEnabled", false)
    LibStub.libs["AceDB-3.0"], LibStub.minors["AceDB-3.0"] = nil, nil
    assert(CachedLoad(F.libRoot .. "/AceDB-3.0/AceDB-3.0.lua"))("AceDB-3.0", {})
    RPSheetDB = saved and Z.Deserialize(saved) or {} -- (a first login: the library starts from nothing)
    if Z.trp3 then InstallTRP3() end
    Z.InstallGame()
    Z.problems = Z.problems or {}
    Try("OnInitialize", function() RPSheet:OnInitialize() end)
    Try("OnEnable", function() RPSheet:OnEnable() end)
    F.Settle(true) -- the timers of a login: Total RP 3 caught up with, the wizard offered
    Z.CollectErrors("login")
end

-- What the game would write to disk at a logout or reload, as text.
function Z.Logout()
    local db = LibStub("AceDB-3.0")
    local frame = db.frame
    Try("logout", frame:GetScript("OnEvent"), frame, "PLAYER_LOGOUT")
    local text, problem = Z.Serialize(RPSheetDB)
    if problem then Z.Report("saved", "the saved variables hold " .. problem) end
    return text
end

---------------------------------------------------------------------------
-- Problems
---------------------------------------------------------------------------
-- A problem found during a step: `kind` names the invariant.
function Z.Report(kind, text)
    Z.problems[#Z.problems + 1] = { kind = kind, text = tostring(text) }
end
function Z.Short(text) return (tostring(text):gsub("%S*RPSheet/", ""):gsub("%S*wt%-[%w-]+/", "")) end
-- Errors the test helpers caught (Try), and those swallowed by pcall and safecall.
function Z.CollectErrors(where)
    for _, text in ipairs(HIDDEN) do Z.Report("error", where .. " (hidden error): " .. text:sub(1, 900)) end
    HIDDEN = {}
end
-- What two findings have in common when they are the same fault. An error is known
-- by its first line (where it was raised); a stale row by the row, without its
-- numbers; anything else by how its text begins, since the rest names the spell,
-- item or amount it happened to be found with.
function Z.Signature(problem)
    local first = (problem.text:match("^[^\n]*") or ""):gsub("%d+%a%a%f[%A]", "#"):gsub("%d+", "#")
    if problem.kind == "error" then return "error: " .. first:gsub("%b''", "'*'"):sub(1, 160) end
    if problem.kind == "stale" then return "stale: " .. (first:match("it showed '(.-)' where") or first):sub(1, 60) end
    return problem.kind .. ": " .. first:gsub("%b''", "'*'"):gsub('%b""', '"*"'):sub(1, 30)
end

---------------------------------------------------------------------------
-- Playing
---------------------------------------------------------------------------
function Z.Action(name, def)
    def.name = name
    Z.actions[name] = def
    Z.order[#Z.order + 1] = def
end
function Z.Invariant(name, fn, every)
    Z.invariants[name] = { name = name, fn = fn, every = every or 1 }
    Z.invariantOrder[#Z.invariantOrder + 1] = Z.invariants[name]
end

-- Runs one step in the current world. Returns false when it was skipped.
function Z.RunStep(step)
    local action = Z.actions[step.a]
    if not action then return false end
    Z.step = step
    if action.guard and not action.guard() then return false end
    math.randomseed(step.seed or 1)
    Z.rng, Z.picks = Z.Rng(step.seed or 1), 0
    local began = os.clock()
    local ok, problem = xpcall(action.run, function(message)
        if message == Z.SKIP then return message end
        return debug.traceback(tostring(message), 2)
    end)
    if not ok and problem ~= Z.SKIP then
        Z.Report("error", step.a .. ": " .. Z.Short(problem):sub(1, 1200))
    end
    Try(step.a .. " (settle)", F.Settle)
    Z.CollectErrors(step.a)
    Z.Time(step.a, began)
    return ok
end

-- Where the time goes: seconds and calls per action and invariant.
Z.timing = {}
function Z.Time(name, began)
    local entry = Z.timing[name] or { 0, 0 }
    Z.timing[name] = entry
    entry[1], entry[2] = entry[1] + os.clock() - began, entry[2] + 1
end

-- Asks every invariant. `full` also asks the costly ones that run every few steps;
-- `always` names one that is asked whatever the step.
function Z.Check(index, full, always)
    for _, invariant in ipairs(Z.invariantOrder) do
        if full or invariant.every == 1 or index % invariant.every == 0 or invariant.name == always then
            local began = os.clock()
            local ok, problem = xpcall(invariant.fn, function(message) return debug.traceback(tostring(message), 2) end)
            if not ok then Z.Report("error", "invariant " .. invariant.name .. ": " .. Z.Short(problem):sub(1, 1200))
            elseif problem then Z.Report(invariant.name, problem) end
            Z.Time("check: " .. invariant.name, began)
        end
    end
    Z.CollectErrors("checks")
end

-- Plays a scenario from a fresh world. `want`: stop at the first problem with this
-- signature (any problem when nil). Returns the problem and the index of its step.
function Z.Replay(steps, want)
    Z.trp3, Z.problems = false, {}
    Z.Reset(nil)
    Z.freeFrom = 0
    -- the invariant that found it is asked after every step, the others as usual
    local always = want and (want:match("^error: invariant ([%a ]+):") or want:match("^([%a ]+):"))
    if want and want:find("^error: checks %(hidden") then always = "hover" end
    for index, step in ipairs(steps) do
        Z.RunStep(step)
        Z.Check(index, index == #steps, always)
        for _, problem in ipairs(Z.problems) do
            if not want or Z.Signature(problem) == want then return problem, index end
        end
        Z.problems = {}
    end
end

-- Plays `count` random steps after making a character. Returns the steps played, and
-- the first problem if there was one. Problems whose signature is in `known` are
-- passed over, so that a fault already reported doesn't end every later run.
function Z.Play(seed, count, known)
    Z.trp3, Z.problems = false, {}
    Z.Reset(nil)
    local master = Z.Rng(seed)
    -- Free edits (the Customize pages, going back a level) begin late for most
    -- characters: until then the strict limits are checked.
    Z.freeFrom = master:chance(0.3) and 0 or master:int(math.floor(count / 3), count)
    local steps = {}
    local function Do(name, index)
        local step = { a = name, p = {}, seed = master:int(1, 2000000000) }
        local ran = Z.RunStep(step)
        if ran then steps[#steps + 1] = step end
        Z.Check(index, index == count)
        local found
        for _, problem in ipairs(Z.problems) do
            if not found and not (known and known[Z.Signature(problem)]) then found = problem end
        end
        Z.problems = {}
        return found
    end
    local problem = Do("make", 0)
    if not problem and (RPSheet:Sheet().class or "") == "" then
        problem = { kind = "tester", text = "the wizard made no character" }
    end
    local index = 0
    while not problem and index < count do
        index = index + 1
        -- an action that applies, by weight
        local open, total = {}, 0
        for _, action in ipairs(Z.order) do
            if action.weight and (not action.free or index > Z.freeFrom) then
                Z.step, Z.rng = { p = {} }, master
                local ok, applies = Z.pcall(action.guard or function() return true end)
                if ok and applies then
                    open[#open + 1] = action
                    total = total + action.weight
                end
            end
        end
        local roll = master:next() / 2147483647 * total
        local chosen = open[#open]
        for _, action in ipairs(open) do
            roll = roll - action.weight
            if roll < 0 then chosen = action break end
        end
        problem = Do(chosen.name, index)
    end
    -- the checks that end a character's run: a reload, an export and import
    if not problem then problem = Do("final", count) end
    return steps, problem
end

---------------------------------------------------------------------------
-- Shrinking and reporting
---------------------------------------------------------------------------
function Z.StepText(step)
    local parts, keys = {}, {}
    for key in pairs(step.p) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local value = step.p[key]
        parts[#parts + 1] = ("%s = %s"):format(key:match("^[%a_][%w_]*$") and key or ("[%q]"):format(key),
            type(value) == "string" and ("%q"):format(value) or tostring(value))
    end
    return ("{ a = %q, seed = %d, p = { %s } }"):format(step.a, step.seed or 1, table.concat(parts, ", "))
end
function Z.ScenarioText(steps)
    local lines = {}
    for _, step in ipairs(steps) do lines[#lines + 1] = "    " .. Z.StepText(step) .. "," end
    return "{\n" .. table.concat(lines, "\n") .. "\n}"
end

-- The shortest list of steps found, within `budget` replays, that still ends in the
-- same problem. The first step (the character) always stays.
function Z.Shrink(steps, problem, budget)
    local want = Z.Signature(problem)
    local best = steps
    local replays = 0
    local function Fails(candidate)
        replays = replays + 1
        local found, at = Z.Replay(candidate, want)
        if not found then return nil end
        local cut = {}
        for index = 1, at do cut[index] = candidate[index] end
        return cut
    end
    local first = Fails(best)
    if not first then return best, false, replays end -- doesn't happen again when replayed
    best = first
    local chunk = math.max(1, math.floor((#best - 1) / 2))
    while chunk >= 1 and replays < budget do
        local index, removed = 2, false
        while index <= #best and replays < budget do
            local candidate = {}
            for at, step in ipairs(best) do
                if at < index or at >= index + chunk then candidate[#candidate + 1] = step end
            end
            local shorter = #candidate < #best and Fails(candidate)
            if shorter then best, removed = shorter, true else index = index + chunk end
        end
        if chunk == 1 and not removed then break end
        chunk = chunk > 1 and math.floor(chunk / 2) or 1
    end
    return best, true, replays
end

dofile(HERE .. "/t-fuzz-game-lib.lua")
dofile(HERE .. "/t-fuzz-maker-lib.lua")
dofile(HERE .. "/t-fuzz-actions-lib.lua")
dofile(HERE .. "/t-fuzz-items-lib.lua")
dofile(HERE .. "/t-fuzz-edits-lib.lua")
dofile(HERE .. "/t-fuzz-checks-lib.lua")
