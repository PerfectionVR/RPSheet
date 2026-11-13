-- How the character is described to people: its name, a one-line summary, and the
-- snapshot of stats shown in tooltips and sent to other RP Sheet users.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util

-- Total RP 3 first name -> name from settings -> WoW character name
function RPSheet:GetCharacterName()
    if self.db.profile.useTRP3 and AddOn_TotalRP3 and AddOn_TotalRP3.Player then
        local ok, name = pcall(function()
            return AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
        end)
        if ok and type(name) == "string" and name:trim() ~= "" then
            return name
        end
    end
    local custom = self.db.char.name
    if custom and custom:trim() ~= "" then
        return custom
    end
    return UnitName("player")
end

-- e.g. "Level 3 Rogue (Swashbuckler) - Human - Chaotic Good". Nil until a class is chosen.
function RPSheet:Summary()
    local sheet, class, species = self:Sheet(), self:ClassData(), self:SpeciesData()
    if not class then return end
    local text = ("Level %d %s"):format(sheet.level, class.name)
    if sheet.subclass ~= "" then text = text .. " (" .. sheet.subclass .. ")" end
    local parts = { text }
    if species then parts[#parts + 1] = sheet.lineage ~= "" and sheet.lineage or species.name end
    if sheet.alignment ~= "" then parts[#parts + 1] = sheet.alignment end
    return table.concat(parts, " - ")
end

-- Plain data only, so it can be sent to other players as is.
function RPSheet:GetStatData()
    local data = {
        summary = self:Summary() or "",
        ac = self:AC(),
        stats = {},
        trackers = {},
    }
    for i, stat in ipairs(R.STATS) do
        data.stats[i] = self:Score(stat)
    end
    -- HP and up to three resources; spell slots are left out to keep the message small.
    for _, tracker in ipairs(self:GetTrackers()) do
        if tracker.kind ~= "slot" and #data.trackers < 4 then
            data.trackers[#data.trackers + 1] = { tracker.label, tracker.get() or 0, tracker.max }
        end
    end
    local weapon = self:GetWeapon()
    if weapon then
        data.weapon, data.dice, data.sides = weapon.name, weapon.dice, weapon.sides
    end
    return data
end

-- Lines for the "Stats" section in the Total RP 3 tooltip, from a GetStatData snapshot
-- (our own, or one received from another player).
function RPSheet:GetStatLines(data)
    local SEP = "  \194\183  " -- middle dot
    local lines = {}
    if data.summary ~= "" then lines[#lines + 1] = data.summary end
    local vitals = {}
    for i, tracker in ipairs(data.trackers) do
        vitals[#vitals + 1] = ("%s %d/%d"):format(tracker[1], tracker[2], tracker[3])
        if i == 1 then vitals[#vitals + 1] = "AC " .. data.ac end
    end
    if #vitals == 0 then vitals[1] = "AC " .. data.ac end
    lines[#lines + 1] = table.concat(vitals, SEP)
    for row = 0, 1 do
        local parts = {}
        for i = 1, 3 do
            local index = row * 3 + i
            local score = data.stats[index]
            parts[i] = ("%s %d (%s)"):format(R.STATS[index], score, Util.Signed(Util.ScoreMod(score)))
        end
        lines[#lines + 1] = table.concat(parts, SEP)
    end
    if data.weapon then
        lines[#lines + 1] = ("%s (%dd%d)"):format(data.weapon, data.dice, data.sides)
    end
    return lines
end
