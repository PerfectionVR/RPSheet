-- Reads tests/data/site-classes.txt, site-subclasses.txt and site-options.txt: the
-- class facts of the rules site, reduced to lines by tests/data/site-reduce.js (run in
-- the browser on the site; its header describes the lines). The thirteen classes of
-- the setting are there as the site resolves them, on top of their core class, and
-- the twelve core classes beside them. (The core Ranger carries the Hunter's Pet
-- Specialization there: the site's own copying leaks it. Only the setting's classes
-- are compared.)
-- Site.classes["Shaman|WoW"] and Site.subclasses["Shaman|Path of the Elements"] hold:
--   lines[key]      = the fields of a one-off line (hd, saves, armor, skills, mc, ...)
--   cols[label]     = the twenty values of a class table column
--   slots[level]    = "432" (slots per spell level, as digits)
--   features[level] = { { name, wow = true, subclass = true, kids = { ... } }, ... }
--   spells          = { { block, kind, level, { names } }, ... }
--   progress[name]  = an optional-feature or feat progression as written
Site = { classes = {}, subclasses = {} }

local function Split(text, sep)
    local parts = {}
    for part in (text .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do parts[#parts + 1] = part end
    return parts
end
Site.Split = Split

-- "Rage[A/B(c/d)];Totems@WoW*" as a list of features. Brackets hold the named parts of
-- a feature; ";" and "/" inside them don't separate.
local function Features(text)
    local list, depth, start = {}, 0, 1
    local function Add(piece)
        if piece == "" then return end
        local name, kids = piece:match("^(.-)%[(.*)%]$")
        local feature = { name = name or piece, kids = {} }
        feature.subclass = feature.name:sub(-1) == "*"
        feature.name = feature.name:gsub("%*$", "")
        feature.wow = feature.name:find("@WoW$") ~= nil
        feature.name = feature.name:gsub("@%w+$", "")
        -- every name inside the brackets, whatever its depth ("T:" marks a table's caption)...
        for kid in (kids or ""):gmatch("[^/()]+") do
            feature.kids[#feature.kids + 1] = strtrim((kid:gsub("^T:", "")))
        end
        -- ...and the outermost ones alone, for a list of options
        feature.top = {}
        for kid in (kids or ""):gsub("%b()", ""):gmatch("[^/]+") do feature.top[#feature.top + 1] = strtrim(kid) end
        list[#list + 1] = feature
    end
    for index = 1, #text do
        local char = text:sub(index, index)
        if char == "[" then depth = depth + 1 elseif char == "]" then depth = depth - 1
        elseif char == ";" and depth == 0 then Add(text:sub(start, index - 1)); start = index + 1 end
    end
    Add(text:sub(start))
    return list
end

-- "{1:2,4:3}" or "1,3,3" as the value at each level 1 to 20.
function Site.Steps(text)
    local out = {}
    if text:sub(1, 1) == "{" then
        local value = 0
        for level = 1, 20 do
            local found = text:match("[{,]" .. level .. ":(%d+)")
            if found then value = tonumber(found) end
            out[level] = value
        end
    else
        for level, value in ipairs(Split(text, ",")) do out[level] = tonumber(value) or value end
    end
    return out
end

local function Load(file, into)
    local handle = assert(io.open(ARG3 .. "/data/" .. file, "r"), "tests/data/" .. file .. " is missing")
    local entry
    for line in handle:lines() do
        local key, rest = line:match("^([^|]*)|(.*)$")
        if key == "CLASS" or key == "SUB" then
            local f = Split(rest, "|")
            entry = { lines = {}, cols = {}, slots = {}, features = {}, spells = {}, progress = {} }
            for level = 1, 20 do entry.features[level] = {} end
            if key == "CLASS" then
                entry.name, entry.source, entry.base, entry.hero = f[1], f[2], f[3], f[5] == "hero"
                into[f[1] .. "|" .. f[2]] = entry
            else
                entry.class, entry.short, entry.name = f[1], f[3], f[4]
                into[f[1] .. "|" .. f[4]] = entry
            end
        elseif key == "col" then
            local label, values = rest:match("^(.-)|(.*)$")
            entry.cols[label] = Split(values, ",")
        elseif key == "slots" then
            entry.slots = Split(rest, ",")
        elseif key == "SP" then
            local f = Split(rest, "|")
            -- (a "choose" entry carries bars of its own: only whole names are kept)
            local names = {}
            if not rest:find("choose:") and not rest:find("all:") then
                for name in f[4]:gmatch("[^;]+") do names[#names + 1] = (name:gsub("@.*$", "")) end
            end
            entry.spells[#entry.spells + 1] = { block = f[1], kind = f[2], level = tonumber(f[3]), names = names }
        elseif key == "featprog" or key == "optprog" then
            local f = Split(rest, "|")
            entry.progress[f[1]] = Site.Steps(f[3])
        elseif key and key:match("^L%d+$") then
            entry.features[tonumber(key:sub(2))] = Features(rest)
        elseif key then
            entry.lines[key] = Split(rest, "|")
        end
    end
    handle:close()
end

-- Site.options["EI"]["Devouring Blade"] = { level = 12, needs = "thirsting blade", cost = nil }:
-- invocations (EI), Metamagic (MM) and maneuvers (MV:B) with what they ask and cost.
Site.options = {}
local handle = assert(io.open(ARG3 .. "/data/site-options.txt", "r"), "tests/data/site-options.txt is missing")
for line in handle:lines() do
    local f = Split(line, "|")
    Site.options[f[2]] = Site.options[f[2]] or {}
    Site.options[f[2]][f[3]] = { source = f[4], level = tonumber(f[5]), needs = f[6] ~= "" and f[6] or nil, cost = tonumber(f[7]) }
end
handle:close()

Load("site-classes.txt", Site.classes)
Load("site-subclasses.txt", Site.subclasses)
