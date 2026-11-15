-- t-conform-classes.lua: the numbers of each level (hit points, the class table's
-- columns, spell slots, how many of each thing is known) and what a level asks.
local C = Conform
local Kit = ns.FeatureKit
local Levels = ns.Levels

local function Tracker(name)
    local tracker = RPSheet:FindTracker(name)
    return tracker and tracker.max or 0
end

local function Entry(sheet, name)
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for _, entry in ipairs(list) do if entry.name == name then return entry end end
    end
end

local function PactSlots(sheet)
    local slots = ns.SheetSlots(sheet)
    for spellLevel = 9, 1, -1 do if slots[spellLevel] then return slots[spellLevel], spellLevel end end
    return 0, 0
end

-- What the addon has for a column of the site's class table, by the column's label.
local COLUMNS = {
    ["Rages"] = function() return Tracker("Rage") end,
    ["Rage Damage"] = function(_, level) return "+" .. Kit.RageDamage(level) end,
    ["Weapon Mastery"] = function() return RPSheet:MasteryLimit() end,
    ["Channel Divinity"] = function() return Tracker("Channel Divinity") end,
    ["Wild Shape"] = function() return Tracker("Wild Shape") end,
    ["Second Wind"] = function() return Tracker("Second Wind") end,
    ["Focus Points"] = function() return Tracker("Focus Points") end,
    ["Sorcery Points"] = function() return Tracker("Sorcery Points") end,
    ["Favored Enemy"] = function() return Tracker("Favored Enemy") end,
    ["Cantrips"] = function(sheet, _, class) return ns.SheetPickLimit(sheet, R.CANTRIP_LISTS[class.base]) end,
    ["Prepared Spells"] = function() return (select(2, RPSheet:SpellLimits())) end,
    ["Invocations"] = function(sheet) return ns.SheetPickLimit(sheet, "invocations") end,
    ["Spell Slots"] = function(sheet) return (PactSlots(sheet)) end,
    ["Slot Level"] = function(sheet) return (select(2, PactSlots(sheet))) end,
    ["Martial Arts"] = function(_, level) return "1d" .. Kit.MartialDie(level) end,
    ["Unarmored Movement"] = function(sheet)
        local entry = Entry(sheet, "Unarmored Movement")
        for _, effect in ipairs(entry and entry.effects or {}) do
            if effect.target == "SPEED" then return "+" .. effect.flat end
        end
        return "+0"
    end,
    ["Sneak Attack"] = function(sheet)
        local entry = Entry(sheet, "Sneak Attack")
        for _, action in ipairs(entry and entry.actions or {}) do
            if action.type == "DICE" then return action.count .. "d" .. action.sides end
        end
    end,
    -- Soulknife
    ["Number"] = function() return Tracker("Psionic Energy Dice") end,
    ["Die Size"] = function(sheet, level)
        if level < 3 then return 0 end
        local entry = Entry(sheet, "Psionic Power") or Entry(sheet, "Psychic Blades")
        local sides = entry and tostring(entry.desc):match("d(%d+)")
        return "D" .. tostring(Names.SoulknifeDie and Names.SoulknifeDie(sheet, level) or sides)
    end,
}

local function Columns(id, site, sheet, level, class)
    for label, values in pairs(site.cols) do
        local read = COLUMNS[label]
        if not read then
            C.Differs(id .. " column " .. label, "a column of the site's table that nothing is compared with")
        else
            C.Same(("%s L%d %s"):format(id, level, label), read(sheet, level, class), values[level])
        end
    end
end

function C.Numbers(key, class, site, sheet, level)
    sheet = C.Use(sheet)
    local id = ("%s L%d"):format(key, level)
    local die = tonumber(site.lines.hd[1])
    -- hit points: the whole die at level 1, then the average rounded up (Constitution is 10)
    C.Same(id .. " hit points", RPSheet:MaxHP() - (Names.ExtraHP(sheet, level)), die + (level - 1) * (die / 2 + 1))
    local dice, sides = 0, {}
    for _, tracker in ipairs(RPSheet:GetTrackers()) do
        if tracker.kind == "hitdice" then dice = dice + tracker.max; sides[#sides + 1] = tracker.sides end
    end
    C.Same(id .. " hit dice", dice .. "d" .. table.concat(sides, "/"), level .. "d" .. die)
    C.Same(id .. " proficiency bonus", RPSheet:ProficiencyBonus(), math.ceil(level / 4) + 1)
    Columns(key, site, sheet, level, class)
    -- spell slots
    if #site.slots > 0 then
        local slots, text = ns.SheetSlots(sheet), ""
        for spellLevel = 1, 9 do text = text .. (slots[spellLevel] and tostring(slots[spellLevel]) or "") end
        C.Same(id .. " spell slots", text, site.slots[level])
    elseif not site.cols["Spell Slots"] then
        C.Same(id .. " spell slots", next(ns.SheetSlots(sheet)) == nil and "none" or "some", "none")
    end
    -- the progressions the site keeps beside the table
    if site.lines.cantrips then C.Same(id .. " cantrips known", COLUMNS["Cantrips"](sheet, level, class), Site.Split(site.lines.cantrips[1], ",")[level]) end
    if site.lines.prepared then C.Same(id .. " spells prepared", COLUMNS["Prepared Spells"](), Site.Split(site.lines.prepared[1], ",")[level]) end
    C.Same(id .. " weapon masteries", RPSheet:MasteryLimit(), site.lines.mastery and Site.Steps(site.lines.mastery[1])[level] or 0)
    if site.lines.spellbook then
        local total = 0
        for index = 1, level do total = total + tonumber(Site.Split(site.lines.spellbook[1], ",")[index]) end
        C.Same(id .. " spellbook spells", ns.SheetPickLimit(sheet, "spellbook"), total)
    end
    if site.lines.arcanum then
        -- one spell of each of these levels, from the character levels named
        local have = Names.Arcanum(sheet, level)
        local want = {}
        for from, spellLevel in site.lines.arcanum[1]:gmatch("(%d+):{(%d+):1}") do
            if level >= tonumber(from) then want[#want + 1] = spellLevel end
        end
        C.Same(id .. " Mystic Arcanum spell levels", have, table.concat(want, ","))
    end
    local expertise = 0
    for index = 1, level do
        for _, feature in ipairs(site.features[index]) do expertise = expertise + (Names.EXPERTISE[feature.name] or 0) end
    end
    C.Same(id .. " expertise picks", (ns.ExpertiseLimit(sheet)), expertise)
    C.Same(id .. " Metamagic options", ns.SheetPickLimit(sheet, "metamagic"), (site.progress["Metamagic"] or {})[level] or 0)
    C.Same(id .. " Eldritch Invocations", ns.SheetPickLimit(sheet, "invocations"), (site.progress["Eldritch Invocations"] or {})[level] or 0)
    C.Same(id .. " Fighting Style picks", #ns.StyleSlots(sheet) - Names.SubclassStyles(sheet), (site.progress["Fighting Style"] or {})[level] or 0)
end

-- What a level asks the player: an improvement or feat, an Epic Boon, a subclass.
function C.Choices(key, class, site, sheet, level)
    local want
    for _, feature in ipairs(site.features[level]) do
        if feature.name == "Ability Score Improvement" then want = "ASI" end
        if feature.name == "Epic Boon" then want = "BOON" end
    end
    C.Same(("%s L%d improvement or boon"):format(key, level), tostring((Levels.Kind(sheet, ns.LevelSlot(sheet, key, level)))), tostring(want))
    C.Same(("%s L%d Epic Boon feat"):format(key, level), tostring(level == R.EPIC_BOON_LEVEL), tostring((site.progress["Epic Boon"] or {})[level] == 1 and (site.progress["Epic Boon"][level - 1] or 0) == 0))
end

function C.SubclassNumbers(key, subclass, site, sheets)
    for level = 1, R.MAX_LEVEL do
        local sheet = C.Use(sheets[level])
        Columns(key .. "/" .. subclass, site, sheet, level, R.CLASSES[key])
        if site.progress["Maneuvers"] then
            C.Same(("%s/%s L%d maneuvers known"):format(key, subclass, level), ns.SheetManeuverLimit(sheet), site.progress["Maneuvers"][level])
        end
    end
end
