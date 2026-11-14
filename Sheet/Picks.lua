-- The options a character picked from a class's list (data in Data/Picks.lua):
-- Metamagic, Eldritch Invocations. sheet.picks[<list>][<name>] = true.
-- Each pick is put on the sheet as an ability or a passive marked
-- auto = "pick:<list>:<name>". The choosing happens in Options/LevelDialog.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit

-- How many options of a list a character of this class and level knows.
function ns.PickLimit(key, classKey, level)
    local list, class = R.PICK_LISTS[key], R.CLASSES[classKey]
    if not list or not class or class.base ~= list.base then return 0 end
    return Kit.AtLevel(level, list.known) or 0
end

function ns.PicksKnown(sheet, key)
    local count = 0
    for name in pairs(sheet.picks[key] or {}) do
        if R.PICK_LISTS[key].items[name] then count = count + 1 end
    end
    return count
end

-- Why an option can't be picked, given the level and the other picks, or nil.
-- `subclass` matters for beast forms, which a Circle of the Moon druid learns sooner.
function ns.PickBlocked(key, name, level, picked, subclass)
    local item = R.PICK_LISTS[key].items[name]
    local need = (subclass == "Circle of the Moon" and item.moonLevel) or item.level
    if need and level < need then return ("needs level %d"):format(need) end
    if item.needs and not picked[item.needs] then return "needs " .. item.needs end
end

-- True if any list has the wrong number of picks.
function ns.OpenPicks(sheet)
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local limit = ns.PickLimit(key, sheet.class, sheet.level)
        if limit > 0 and ns.PicksKnown(sheet, key) ~= limit then return true end
    end
    return false
end

-- Puts the picks on the sheet and takes off those no longer picked.
function ns.ApplyPicks(sheet)
    local wanted = {}
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        -- A list marked custom has its own way onto the sheet (beast forms).
        if not R.PICK_LISTS[key].custom and ns.PickLimit(key, sheet.class, sheet.level) > 0 then
            for name in pairs(sheet.picks[key] or {}) do
                local auto = ("pick:%s:%s"):format(key, name)
                if R.PICK_LISTS[key].items[name] and not sheet.dismissed[auto] then
                    wanted[auto] = { list = R.PICK_LISTS[key], name = name, item = R.PICK_LISTS[key].items[name] }
                end
            end
        end
    end
    for _, entries in ipairs({ sheet.abilities, sheet.passives }) do
        for index = #entries, 1, -1 do
            local auto = entries[index].auto or ""
            if auto:find("^pick:") then
                if wanted[auto] then wanted[auto].entry = entries[index] else table.remove(entries, index) end
            end
        end
    end
    for auto, pick in pairs(wanted) do
        local item = pick.item
        local clickable = item.cost ~= nil or item.dice ~= nil
        local entry = pick.entry
        if not entry then
            entry = { name = pick.name, auto = auto }
            if not clickable then entry.enabled = true end
            local target = clickable and sheet.abilities or sheet.passives
            target[#target + 1] = entry
        end
        entry.desc = ("%s. %s"):format(pick.list.title, item.desc)
        if clickable then
            entry.actions = {}
            if item.cost then entry.actions[#entry.actions + 1] = Kit.Spend("Sorcery Points", item.cost) end
            if item.dice then entry.actions[#entry.actions + 1] = Kit.Dice(item.dice[1], item.dice[2], item.dice[3]) end
        else
            entry.effects = entry.effects or {}
        end
    end
end
