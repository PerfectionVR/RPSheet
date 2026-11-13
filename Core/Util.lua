-- Small helpers with no knowledge of the addon's data.
local _, ns = ...

local Util = {}
ns.Util = Util

-- 3 -> "+3", -1 -> "-1"
function Util.Signed(n)
    return (n >= 0 and "+" or "") .. n
end

-- Ability modifier for a score: 10 -> 0, 16 -> +3.
function Util.ScoreMod(score)
    return math.floor((score - 10) / 2)
end

-- Colour escape code for a { r, g, b } colour.
function Util.HexCode(color)
    return ("|cff%02x%02x%02x"):format(color[1] * 255, color[2] * 255, color[3] * 255)
end

-- Copies every value missing from `target` out of `template`.
function Util.FillDefaults(target, template)
    for key, value in pairs(template) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            Util.FillDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

-- Turns a saved list into a clean array of tables with every template field present.
-- `keep(entry)` decides which entries survive (default: those with a name).
function Util.NormalizeList(list, template, keep)
    local keys = {}
    for key, entry in pairs(list) do
        if type(key) == "number" and type(entry) == "table" then
            if keep and keep(entry) or (not keep and (entry.name or "") ~= "") then
                keys[#keys + 1] = key
            end
        end
    end
    table.sort(keys)
    local entries = {}
    for i, key in ipairs(keys) do entries[i] = Util.FillDefaults(list[key], template) end
    wipe(list)
    for i, entry in ipairs(entries) do list[i] = entry end
end

-- The entries of a list that have a name.
function Util.Named(list)
    local result = {}
    for _, entry in ipairs(list) do
        if entry.name ~= "" then result[#result + 1] = entry end
    end
    return result
end
