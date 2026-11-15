-- The ground of t-conform-classes.lua: counting, and the sheets it compares. The
-- comparisons are in the t-conform-*-lib.lua files beside this one. Every difference
-- goes through C.Differs with an id; an id named in Names.ALLOW
-- (t-conform-names-lib.lua) is a deliberate difference and is counted, any other is
-- printed as a PROBLEM.
Conform = { compared = 0, allowed = 0, used = {}, features = 0, merged = 0, grown = 0, extras = 0 }
local C = Conform

function C.Differs(id, text)
    if Names.ALLOW[id] then
        if not C.used[id] then C.used[id] = true; C.allowed = C.allowed + 1 end
        return
    end
    Problem(id .. ": " .. text)
end

-- Counts a comparison; the two sides are compared as text.
function C.Same(id, addon, site)
    C.compared = C.compared + 1
    if tostring(addon) ~= tostring(site) then C.Differs(id, ("addon %s, site %s"):format(tostring(addon), tostring(site))) end
end

-- A list of names as one sorted line, for comparing two lists whatever their order.
function C.Sorted(list, lower)
    local out = {}
    for _, name in ipairs(list) do out[#out + 1] = lower and name:lower() or name end
    table.sort(out)
    return table.concat(out, ",")
end

---------------------------------------------------------------------------
-- Sheets
---------------------------------------------------------------------------
local function Serialize(value)
    if type(value) ~= "table" then return tostring(value) end
    local keys, out = {}, {}
    for key in pairs(value) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local item = value[key]
        if item == nil then item = value[tonumber(key)] end
        out[#out + 1] = key .. "=" .. Serialize(item)
    end
    return "{" .. table.concat(out, ",") .. "}"
end

-- A character of one class on a fresh sheet: scores of 10 (so no modifier hides in a
-- number), a human, nothing chosen.
function C.Build(key, subclass, spec, level)
    local sheet = ns.NewSheet()
    for _, list in ipairs(R.PICK_LIST_ORDER) do sheet.picks[list] = {} end
    sheet.class, sheet.subclass, sheet.spec, sheet.level = key, subclass, spec, level
    sheet.species, sheet.background = "HUMAN", R.BACKGROUND_ORDER[1]
    sheet.base = { STR = 10, DEX = 10, CON = 10, INT = 10, WIS = 10, CHA = 10 }
    -- the class's first skills, so that expertise has skills to go on
    local class = R.CLASSES[key]
    for index = 1, class.skillCount do sheet.skills[class.skills[index]] = 1 end
    ns.ApplyGrants(sheet)
    return sheet
end

function C.Use(sheet)
    RPSheet:ReplaceSheet(sheet)
    return RPSheet:Sheet()
end

-- True when a feature of the class or subclass belongs to one specialization: then
-- the features of a level are those of every specialization together.
local function BySpec(key, subclass)
    local class = R.CLASSES[key]
    for _, list in ipairs({ R.FEATURES[class.base], (R.CLASS_OVERRIDES[key] or {}).features, R.SUBCLASS_FEATURES[subclass] }) do
        for _, feature in ipairs(list or {}) do if feature.spec then return true end end
    end
    return false
end

-- sheets[level] = the sheet; sheets.entries[level][auto key] = { name, sig } for the
-- class and subclass features on it, where sig changes when the entry's text, steps
-- or number of uses change.
function C.Sheets(key, subclass)
    local class = R.CLASSES[key]
    local sheets = { entries = {} }
    local specs = BySpec(key, subclass) and class.specs or { class.specs[1] }
    for level = 1, R.MAX_LEVEL do
        local entries = {}
        for index = #specs, 1, -1 do
            local sheet = C.Use(C.Build(key, (level >= R.SUBCLASS_LEVEL or class.hero) and subclass or "", specs[index], level))
            sheets[level] = sheet
            for _, list in ipairs({ sheet.abilities, sheet.passives }) do
                for _, entry in ipairs(list) do
                    local auto = entry.auto or ""
                    if auto:find("^class:") or auto:find("^subclass:") then
                        local tracker = RPSheet:FindTracker(entry.name)
                        entries[auto] = { name = entry.name, sig = tostring(entry.desc) .. Serialize(entry.actions or entry.effects or {})
                            .. Serialize(entry.advantage or {}) .. (tracker and tracker.max or "") }
                    end
                end
            end
        end
        sheets.entries[level] = entries
    end
    return sheets
end
