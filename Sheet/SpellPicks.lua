-- The cantrips a character picked in the level dialog (lists in Data/SpellPicks.lua):
-- sheet.picks["cantrips<Class>"][<name>] = true. Each is put on the spell list marked
-- auto = "cantrip:<name>". A cantrip the character has from somewhere else (a feature
-- that always keeps it prepared, a feat, one put on the spell list as not counting)
-- is not picked as well: no cantrip is on a sheet twice, and a pick that became one
-- of those is freed for another cantrip.
local _, ns = ...
local R = ns.Rules

local PREFIX = "cantrip:"

-- { [name] = true } for the cantrips the character knows without picking them.
-- `sheet` may be the level dialog's stand-in, so a subclass chosen there counts.
-- The dialog asks once per cantrip each time it is drawn, so the answer is kept for
-- as long as the same moment lasts; `fresh` works it out anew.
local kept = {}
function ns.CantripsElsewhere(sheet, fresh)
    local now = GetTime()
    if not fresh and kept.names and kept.time == now and kept.spells == sheet.spells and kept.class == sheet.class
        and kept.subclass == sheet.subclass and kept.spec == sheet.spec and kept.level == sheet.level then
        return kept.names
    end
    local names = {}
    for name in pairs(ns.AlwaysPrepared(sheet)) do
        if R.SPELLS[name].level == 0 then names[name] = true end
    end
    for name, found in pairs(ns.FeatSpells(sheet)) do
        -- (One the player deleted from the spell list isn't given by the feat any more.)
        if found.level == 0 and not (sheet.dismissed or {})["feat:" .. name] then names[name] = true end
    end
    for _, spell in ipairs(sheet.spells or {}) do
        local auto = spell.auto or ""
        -- Entries of the two kinds above are covered there; a stale one is on its way out.
        if spell.level == 0 and spell.free and not auto:find("^prepared:") and not auto:find("^feat:") then names[spell.name] = true end
    end
    kept = { names = names, time = now, spells = sheet.spells, class = sheet.class, subclass = sheet.subclass, spec = sheet.spec, level = sheet.level }
    return names
end

for _, key in pairs(R.CANTRIP_LISTS) do
    R.PICK_LISTS[key].blocked = function(sheet, name)
        if ns.CantripsElsewhere(sheet)[name] then return "you know it already" end
    end
end

-- The cantrips of one class: `sheet` is a character of one class, or a view of one
-- class of a character with several. That one's spells name their class, and the
-- cantrips its other classes picked are left alone.
local function ApplyFor(sheet)
    local foreign, tag = ns.ForeignPicks(sheet, R.CANTRIP_LISTS), ns.SpellTag(sheet)
    local class = R.CLASSES[sheet.class]
    local key = class and R.CANTRIP_LISTS[class.base]
    local limit = key and ns.PickLimit(key, sheet.class, sheet.level) or 0
    local items = key and R.PICK_LISTS[key].items or {}
    local picks = {}
    if limit > 0 then
        sheet.picks[key] = sheet.picks[key] or {}
        picks = sheet.picks[key]
    end

    -- A cantrip the player deleted from the spell list is no longer picked, and neither
    -- is one the character now knows without picking it: the level dialog asks for another.
    local elsewhere = limit > 0 and ns.CantripsElsewhere(sheet, true) or {}
    local stays = ns.OwnEntries(sheet, PREFIX, tag)
    for name in pairs(picks) do
        if (sheet.dismissed[PREFIX .. name] and not stays[name]) or elsewhere[name] then
            picks[name] = nil
            sheet.dismissed[PREFIX .. name] = nil
        end
    end
    local count = 0
    for name in pairs(picks) do
        if items[name] then count = count + 1 end
    end

    local have = {}
    for index = #sheet.spells, 1, -1 do
        local spell = sheet.spells[index]
        local auto = spell.auto or ""
        if auto:find("^" .. PREFIX) then
            -- Put there by an earlier pick: it stays only while it is still picked. One
            -- that names another class is that class's own (two classes may both know
            -- a cantrip, each with its own ability).
            if not ns.SpellIsOf(spell, tag) then
                -- not this class's
            elseif picks[spell.name] and not have[spell.name] then
                have[spell.name] = true
                if tag then spell.class = tag end
            elseif spell.class == tag or have[spell.name] or not foreign[spell.name] then
                -- (one without a class that another class picked is left for that class)
                table.remove(sheet.spells, index)
            end
        elseif spell.level == 0 and not spell.free and items[spell.name] and ns.SpellIsOf(spell, tag) then
            -- Added by hand before cantrips were picked: it counts as a pick while
            -- there is room for one.
            if picks[spell.name] or count < limit then
                if not picks[spell.name] then
                    picks[spell.name] = true
                    count = count + 1
                end
                spell.auto = PREFIX .. spell.name
                if tag then spell.class = tag end
            end
            have[spell.name] = true
        end
    end

    local names = {}
    for name in pairs(picks) do
        if items[name] and not have[name] then names[#names + 1] = name end
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local spell = CopyTable(R.SPELLS[name])
        spell.auto = PREFIX .. name
        spell.class = tag
        sheet.spells[#sheet.spells + 1] = spell
    end
    kept = {} -- the spell list changed
end

function ns.ApplySpellPicks(sheet)
    ns.ForEachClass(sheet, ApplyFor)
end
