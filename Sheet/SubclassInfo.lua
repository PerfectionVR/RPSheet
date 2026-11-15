-- What a subclass is, for the places it is chosen (the creation wizard, the level
-- dialog, Customize): its note (Data/SubclassNotes.lua) and its features by level,
-- read from the same data that puts them on the sheet.
local _, ns = ...
local R = ns.Rules

local GOLD, GREY = "|cffffd100", "|cff909090"

-- The first sentence of a feature's text, for a one-line list.
local function Short(text)
    -- Some texts are worked out from the character (a function): those are left out here.
    if type(text) ~= "string" then return "" end
    local first = text:match("^(.-[%.!?])%s") or text
    if #first > 140 then first = first:sub(1, 137):gsub("%s+%S*$", "") .. "..." end
    return first
end

-- A few lines about `subclass`; "" for an empty or unknown one.
function ns.SubclassSummary(subclass)
    local features = subclass and R.SUBCLASS_FEATURES[subclass]
    if not features then return "" end
    local lines = {}
    local note = R.SUBCLASS_NOTES and R.SUBCLASS_NOTES[subclass]
    if note then lines[#lines + 1] = note end
    -- Features in level order; helper rows that belong to a choice (Kit.For) are left out.
    local list = {}
    for index, feature in ipairs(features) do
        if feature.name and feature.level and not feature.option and not feature.spec then list[#list + 1] = { feature = feature, index = index } end
    end
    table.sort(list, function(a, b)
        if a.feature.level ~= b.feature.level then return a.feature.level < b.feature.level end
        return a.index < b.index
    end)
    local seen = {}
    for _, entry in ipairs(list) do
        local feature = entry.feature
        if not seen[feature.name] then
            seen[feature.name] = true
            local short = Short(feature.desc)
            lines[#lines + 1] = short ~= "" and ("%sLevel %d|r %s: %s%s|r"):format(GOLD, feature.level, feature.name, GREY, short)
                or ("%sLevel %d|r %s"):format(GOLD, feature.level, feature.name)
        end
    end
    return table.concat(lines, "\n") .. "\n"
end
