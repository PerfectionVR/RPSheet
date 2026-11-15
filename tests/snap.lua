-- A flat picture of a table: path -> value, to see whether rules data changes at run time.
function Snapshot(root)
    local flat, seen = {}, {}
    local function Walk(t, path, depth)
        if seen[t] then flat[path] = "<seen " .. seen[t] .. ">" return end
        seen[t] = path
        local n = 0
        for k, v in pairs(t) do
            n = n + 1
            local p = path .. "/" .. tostring(k)
            if type(v) == "table" then
                if depth < 12 then Walk(v, p, depth + 1) end
            elseif type(v) ~= "function" then flat[p] = tostring(v) end
        end
        flat[path .. "#"] = tostring(n)
    end
    Walk(root, "R", 0)
    return flat
end
function SnapDiff(before, after)
    local count = 0
    for path, value in pairs(after) do
        if before[path] ~= value then
            count = count + 1
            if count <= 25 then print(("RULES DATA CHANGED at run time: %s was %s, now %s"):format(path, tostring(before[path]), value)) end
        end
    end
    for path, value in pairs(before) do
        if after[path] == nil then
            count = count + 1
            if count <= 25 then print(("RULES DATA CHANGED at run time: %s was %s, now gone"):format(path, value)) end
        end
    end
    print("rules data differences", count)
end
