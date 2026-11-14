-- The cantrips a character picked in the level dialog (lists in Data/SpellPicks.lua):
-- sheet.picks["cantrips<Class>"][<name>] = true. Each is put on the spell list marked
-- auto = "cantrip:<name>". Cantrips from a lineage or a feat are not part of this.
local _, ns = ...
local R = ns.Rules

local PREFIX = "cantrip:"

function ns.ApplySpellPicks(sheet)
    local class = R.CLASSES[sheet.class]
    local key = class and R.CANTRIP_LISTS[class.base]
    local limit = key and ns.PickLimit(key, sheet.class, sheet.level) or 0
    local items = key and R.PICK_LISTS[key].items or {}
    local picks = {}
    if limit > 0 then
        sheet.picks[key] = sheet.picks[key] or {}
        picks = sheet.picks[key]
    end

    -- A cantrip the player deleted from the spell list is no longer picked.
    for name in pairs(picks) do
        if sheet.dismissed[PREFIX .. name] then
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
            -- Put there by an earlier pick: it stays only while it is still picked.
            if picks[spell.name] then have[spell.name] = true else table.remove(sheet.spells, index) end
        elseif spell.level == 0 and not spell.free and items[spell.name] then
            -- Added by hand before cantrips were picked: it counts as a pick while
            -- there is room for one.
            if picks[spell.name] or count < limit then
                if not picks[spell.name] then
                    picks[spell.name] = true
                    count = count + 1
                end
                spell.auto = PREFIX .. spell.name
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
        sheet.spells[#sheet.spells + 1] = spell
    end
end
