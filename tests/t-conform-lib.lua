-- Shared by the t-conform-*.lua scripts, which compare the addon's rules data with
-- facts reduced from the rules site (tests/data/*.txt; each file's head says where its
-- lines come from). A difference is a PROBLEM unless the script's allow-list names it
-- with a reason; an allow-list entry that no longer matches anything is a PROBLEM too,
-- so the list can't go stale.
dofile(ARG3 .. "/sim.lua")

COMPARED, ALLOWED = 0, 0
local allow, patterns, used = {}, {}, {}

-- Allow(key, reason): one difference. AllowLike(pattern, reason): every key matching it.
function Allow(key, reason) allow[key] = reason end
function AllowLike(pattern, reason) patterns[#patterns + 1] = { pattern, reason } end

-- A difference found: `key` names the thing ("weapon/Club/mastery"), `text` says what.
function Differ(key, text)
    if allow[key] then used[key] = true; ALLOWED = ALLOWED + 1 return end
    for _, entry in ipairs(patterns) do
        if key:find(entry[1]) then used[entry[1]] = true; ALLOWED = ALLOWED + 1 return end
    end
    Problem(("%s: %s"):format(key, text))
end

local function Text(value)
    if type(value) == "table" then
        local parts = {}
        for _, v in ipairs(value) do parts[#parts + 1] = tostring(v) end
        return table.concat(parts, ",")
    end
    return tostring(value)
end
-- One fact compared; numbers and their text count as the same.
function Same(key, got, want)
    COMPARED = COMPARED + 1
    local g, w = Text(got), Text(want)
    if tonumber(g) and tonumber(w) then g, w = tonumber(g), tonumber(w) end
    if g ~= w then Differ(key, ("addon has %s, the site %s"):format(Text(got), Text(want))) end
end

-- "a,b" or { "a", "b" } as a sorted, lower-case, comma-joined text; "" for nothing.
function Sorted(list, sep)
    local parts = {}
    if type(list) == "string" then
        for part in list:gmatch("[^" .. (sep or ",") .. "]+") do parts[#parts + 1] = strtrim(part):lower() end
    else
        for _, part in ipairs(list or {}) do parts[#parts + 1] = tostring(part):lower() end
    end
    table.sort(parts)
    return table.concat(parts, ",")
end
-- The keys of a table whose values are true, as Sorted text.
function Keys(set)
    local parts = {}
    for key, value in pairs(set or {}) do if value then parts[#parts + 1] = key end end
    return Sorted(parts)
end

-- The lines of tests/data/<file>: each a table of its "|" fields, with k=v fields
-- also under their key. Comment lines start with "#".
function ReadData(file)
    local handle = io.open(ARG3 .. "/data/" .. file, "r")
    if not handle then Problem("can't read tests/data/" .. file) return {} end
    local lines = {}
    for line in handle:lines() do
        line = line:gsub("\r$", "")
        if line ~= "" and line:sub(1, 1) ~= "#" then
            local row, index, from = {}, 0, 1
            while true do
                local bar = line:find("|", from, true)
                local field = line:sub(from, bar and bar - 1 or nil)
                index = index + 1
                row[index] = field
                local key, value = field:match("^(%a[%w]*)=(.*)$")
                if key then row[key] = value end
                if not bar then break end
                from = bar + 1
            end
            lines[#lines + 1] = row
        end
    end
    handle:close()
    return lines
end

-- Both ways round: every name of `site` (a set) the addon lacks, and every name of
-- `addon` the site lacks. `kind` starts the key: "weapon" gives "weapon/Club/missing"
-- for one the addon lacks and "weapon/Club/extra" for one only the addon has.
function BothWays(kind, site, addon)
    local names = {}
    for name in pairs(site) do if not addon[name] then names[#names + 1] = name end end
    table.sort(names)
    for _, name in ipairs(names) do Differ(("%s/%s/missing"):format(kind, name), "on the site, not in the addon") end
    names = {}
    for name in pairs(addon) do if not site[name] then names[#names + 1] = name end end
    table.sort(names)
    for _, name in ipairs(names) do Differ(("%s/%s/extra"):format(kind, name), "in the addon, not on the site") end
end

-- The summary line run-all.sh reads; stale allow-list entries are problems.
function Finish(label)
    for key in pairs(allow) do
        if not used[key] then Problem("allow-list entry matches nothing any more: " .. key) end
    end
    for _, entry in ipairs(patterns) do
        if not used[entry[1]] then Problem("allow-list pattern matches nothing any more: " .. entry[1]) end
    end
    local count = 0
    for _ in pairs(PROBLEMS) do count = count + 1 end
    print(("conform %s: %d facts compared, %d allowed differences, %d problems"):format(label, COMPARED, ALLOWED, count))
end
