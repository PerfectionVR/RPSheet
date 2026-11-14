-- The spells a subclass always has prepared (a feature's `prepared` list, see
-- AlwaysPrepared in Data/SubclassFeatures.lua). They are put on the sheet's spell list
-- marked auto = "prepared:<name>" and as not counting against the spells prepared.
local _, ns = ...
local R = ns.Rules

local PREFIX = "prepared:"

-- { [auto key] = spell name } for the levels the character has reached.
local function Wanted(sheet)
    local wanted = {}
    if not R.CLASSES[sheet.class] then return wanted end
    for level = 1, sheet.level do
        for _, feature in ipairs(ns.FeaturesGainedAt(sheet.class, sheet.subclass, level)) do
            -- A list, or a function of the sheet for one that follows the specialization.
            local prepared = feature.prepared
            if type(prepared) == "function" then prepared = prepared(sheet) end
            for _, step in ipairs(prepared or {}) do
                if sheet.level >= step[1] then
                    for name in step[2]:gmatch("[^,]+") do
                        name = strtrim(name)
                        if R.SPELLS[name] and not sheet.dismissed[PREFIX .. name] then wanted[PREFIX .. name] = name end
                    end
                end
            end
        end
    end
    return wanted
end

-- Adds the spells reached, and takes off those of another subclass or a level the
-- character no longer has. A spell the player added by hand is left as it is.
function ns.ApplyPreparedSpells(sheet)
    -- Spells added before higher slots added dice learn how many they add.
    for _, spell in ipairs(sheet.spells) do
        local known = R.SPELLS[spell.name]
        if known and known.ritual and known.level == spell.level then spell.ritual = true end
        -- Spells that make several attacks learn how many.
        if known and known.level == spell.level and (known.hits > 1 or known.hitsUp > 0 or known.hitsScale) then
            spell.hits, spell.hitsUp, spell.hitsScale, spell.desc = known.hits, known.hitsUp, known.hitsScale, known.desc
        end
        if known and (spell.up or 0) == 0 and known.level == spell.level and known.sides == spell.sides and known.count == spell.count then
            spell.up = known.up
        end
    end
    local wanted = Wanted(sheet)
    local have = {}
    for index = #sheet.spells, 1, -1 do
        local spell = sheet.spells[index]
        local auto = spell.auto or ""
        if auto:find("^" .. PREFIX) then
            if wanted[auto] then have[spell.name] = true else table.remove(sheet.spells, index) end
        else
            have[spell.name] = true
        end
    end
    local names = {}
    for auto, name in pairs(wanted) do
        if not have[name] then names[#names + 1] = name end
    end
    table.sort(names, function(a, b)
        if R.SPELLS[a].level ~= R.SPELLS[b].level then return R.SPELLS[a].level < R.SPELLS[b].level end
        return a < b
    end)
    for _, name in ipairs(names) do
        local spell = CopyTable(R.SPELLS[name])
        spell.free, spell.auto = true, PREFIX .. name
        sheet.spells[#sheet.spells + 1] = spell
    end
end
