-- The spells a subclass always has prepared (a feature's `prepared` list, see
-- AlwaysPrepared in Data/SubclassFeatures.lua). They are put on the sheet's spell list
-- marked auto = "prepared:<name>" and as not counting against the spells prepared.
local _, ns = ...
local R = ns.Rules

local PREFIX = "prepared:"

-- { [auto key] = spell name } for the levels the character has reached, each class by
-- its own level, and { [spell name] = class key } for the class that prepares it when
-- the character has several.
local function Wanted(sheet)
    local wanted, from = {}, {}
    ns.EachGainedFeature(sheet, function(feature, view)
        -- A list, or a function of the sheet for one that follows the specialization.
        local prepared = feature.prepared
        if type(prepared) == "function" then prepared = prepared(view) end
        for _, step in ipairs(prepared or {}) do
            if view.level >= step[1] then
                for name in step[2]:gmatch("[^,]+") do
                    name = strtrim(name)
                    if R.SPELLS[name] and not sheet.dismissed[PREFIX .. name] then
                        wanted[PREFIX .. name], from[name] = name, ns.SpellTag(view)
                    end
                end
            end
        end
    end)
    return wanted, from
end

-- { [spell name] = true } for the same spells. `sheet` may be a stand-in with another
-- level or subclass (the level dialog's).
function ns.AlwaysPrepared(sheet)
    local names = {}
    for _, name in pairs(Wanted(sheet)) do names[name] = true end
    return names
end

-- Adds the spells reached, and takes off those of another subclass or a level the
-- character no longer has. A spell the player added by hand is left as it is.
function ns.ApplyPreparedSpells(sheet)
    -- Corrections to the listed spells reach the copies on the sheet first.
    ns.RefreshListedSpells(sheet)
    local wanted, from = Wanted(sheet)
    local have = {}
    for index = #sheet.spells, 1, -1 do
        local spell = sheet.spells[index]
        local auto = spell.auto or ""
        if auto:find("^" .. PREFIX) then
            if wanted[auto] then
                have[spell.name] = true
                if from[spell.name] then spell.class = from[spell.name] end
            else
                table.remove(sheet.spells, index)
            end
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
        spell.class = from[name] -- the class that prepares it, for a character with several
        sheet.spells[#sheet.spells + 1] = spell
    end
end
