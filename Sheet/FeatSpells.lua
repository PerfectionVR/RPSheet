-- The spells a feat gives: the ones picked for it (Sheet/FeatChoices.lua) and the
-- ones it always comes with (Data/FeatChoices.lua). Each is on the spell list marked
-- auto = "feat:<name>" and as not counting against cantrips known or spells prepared.
-- One marked `once` is also cast once per long rest without a slot, through
-- ns.SpellChoice (Sheet/SpellChoices.lua, Actions/SpellChoices.lua).
local _, ns = ...
local R = ns.Rules

local PREFIX = "feat:"

local STAT_BY_NAME = {}
for stat, name in pairs(R.STAT_NAMES) do STAT_BY_NAME[name] = stat end

-- The ability a feat's spells use: the one picked for it, or the one the feat raised
-- at the level it was taken. Nil when that isn't known.
local function InstanceStat(sheet, instance)
    local from = instance.feat.castStat
    if not from then return end
    if from ~= "raised" then
        local entry = (sheet.featChoices or {})[instance.id]
        local picked = entry and entry.picks and entry.picks[from]
        return picked and STAT_BY_NAME[picked[1] or ""]
    end
    local level = tonumber(instance.id:match("^level:(%d+)$"))
    local record = level and ns.Levels.Record(sheet, level)
    for _, stat in ipairs(R.STATS) do
        if record and (record.asi[stat] or 0) > 0 then return stat end
    end
end

-- { [spell name] = { feat =, level =, once =, stat = } } for every spell the
-- character's feats give.
function ns.FeatSpells(sheet, instances)
    local found = {}
    for _, instance in ipairs(instances or ns.FeatInstances(sheet)) do
        local stat = InstanceStat(sheet, instance)
        local function Add(name, once)
            local spell = R.SPELLS[name]
            if spell and not found[name] then
                found[name] = { feat = instance.name, level = spell.level, once = once == true, stat = stat }
            end
        end
        for _, given in ipairs(instance.feat.spells or {}) do Add(given.name, given.once) end
        ns.EachFeatPick(sheet.featChoices, instance, "spell", function(value, choice) Add(value, choice.once) end)
    end
    return found
end

-- How a spell is cast without a slot because a feat gives it, in the form of an entry
-- of R.SPELL_CHOICES, or nil.
function ns.FeatSpellCasting(sheet, name)
    local found = ns.FeatSpells(sheet)[name]
    if not found or not found.once or found.level == 0 then return end
    return {
        feature = found.feat, spellLevel = found.level, once = true, mark = "feat",
        note = ("%s: always prepared. You cast it once without a spell slot; a long rest brings that casting back. Other castings spend a slot."):format(found.feat),
    }
end

-- The ability a spell is cast with if a feat put it on the spell list and that
-- feat's ability is known; nil for any other spell.
function ns.FeatSpellStat(sheet, spell)
    if (spell.auto or "") ~= PREFIX .. (spell.name or "") then return end
    local found = ns.FeatSpells(sheet)[spell.name]
    return found and found.stat
end

-- Takes a spell out of the picks it was chosen in. True if it was picked.
local function Unpick(sheet, instances, name)
    local removed = false
    for _, instance in ipairs(instances) do
        local entry = sheet.featChoices[instance.id]
        for _, choice in ipairs(instance.feat.choices or {}) do
            local picked = entry and entry.picks[choice.key]
            if choice.kind == "spell" and picked then
                for slot, value in pairs(picked) do
                    if value == name then picked[slot], removed = nil, true end
                end
            end
        end
    end
    return removed
end

-- Sheet upkeep, after ns.ApplyFeatChoices and the class's own spells: keeps the
-- spell list in step with the feats.
function ns.ApplyFeatSpells(sheet)
    local instances = ns.FeatInstances(sheet)
    local wanted = ns.FeatSpells(sheet, instances)
    for name in pairs(wanted) do
        local auto = PREFIX .. name
        if sheet.dismissed[auto] then
            -- Deleted from the spell list by the player: a picked spell is asked for
            -- again, one the feat always gives stays off.
            if Unpick(sheet, instances, name) then sheet.dismissed[auto] = nil end
            wanted[name] = nil
        end
    end

    -- A spell the class already put on the list isn't listed twice.
    local have = {}
    for _, spell in ipairs(sheet.spells) do
        local auto = spell.auto or ""
        if auto ~= "" and not auto:find("^" .. PREFIX) and wanted[spell.name] and wanted[spell.name].level == spell.level then
            have[spell.name] = true
        end
    end
    for index = #sheet.spells, 1, -1 do
        local spell = sheet.spells[index]
        local auto = spell.auto or ""
        local own = auto:match("^" .. PREFIX .. "(.+)$")
        if own then
            -- Put there for a feat: it stays only while a feat still gives it.
            if wanted[own] and not have[own] then have[own] = true else table.remove(sheet.spells, index) end
        elseif auto == "" and wanted[spell.name] and wanted[spell.name].level == spell.level and not have[spell.name] then
            -- Added by hand before: from now on it belongs to the feat.
            spell.auto, spell.free = PREFIX .. spell.name, true
            have[spell.name] = true
        end
    end

    local names = {}
    for name in pairs(wanted) do
        if not have[name] then names[#names + 1] = name end
    end
    table.sort(names, R.SpellBefore)
    for _, name in ipairs(names) do
        local spell = CopyTable(R.SPELLS[name])
        spell.free, spell.auto = true, PREFIX .. name
        sheet.spells[#sheet.spells + 1] = spell
    end
end
