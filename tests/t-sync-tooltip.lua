-- The Stats section in the Total RP 3 tooltip: where it goes, that it is there once,
-- that it stays out of other tooltips, and that a Total RP 3 built differently from
-- the one the addon knows costs the section but never an error or TRP3's own tooltip.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local function Count(lines, text)
    local count = 0
    for _, line in ipairs(lines or {}) do if line == text then count = count + 1 end end
    return count
end
local function Index(lines, text)
    for index, line in ipairs(lines or {}) do if line == text then return index end end
end
local function Pair(shape)
    local world = NewWorld()
    local bert = world:AddClient({ name = "Bert", trp3 = { shape = shape } }):Login()
    local anna = world:AddClient({ name = "Anna" }):Login()
    world:Advance(5)
    bert:Build("MAGE", "", 3); anna:Build("WARRIOR", "", 5)
    world:Group({ anna, bert })
    world:Advance(3)
    return world, bert, anna
end

Section("the usual tooltip", function()
    local world, bert, anna = Pair()
    bert:Hover(anna, true)
    local lines = bert:Tooltip()
    Eq(Count(lines, "Stats"), 1, "one Stats section")
    Check(Index(lines, "OOC") and Index(lines, "Stats") == Index(lines, "OOC") + 2, "below the OOC block")
    Check(Index(lines, "Pronouns: they") and Index(lines, "Pronouns: they") > Index(lines, "Stats"), "above what follows")
    Eq(lines[Index(lines, "Stats") + 1], "Level 5 Arms Warrior - Human", "the summary first")
    -- again and again: always once
    for _ = 1, 5 do bert:Hover(anna, true) end
    Eq(Count(bert:Tooltip(), "Stats"), 1, "still one after showing it five times")
    bert:Hover(bert, true)
    Eq(Count(bert:Tooltip(), "Stats"), 1, "one on the player's own")
    Eq(bert:Tooltip()[Index(bert:Tooltip(), "Stats") + 1], "Level 3 Arcane Mage - Human", "which is the player's own sheet")
    -- someone nothing was received from
    local carl = world:AddClient({ name = "Carl" }):Bare()
    bert:Hover(carl, true)
    Eq(Count(bert:Tooltip(), "Stats"), 0, "no section for a player without the addon")
    Check(Index(bert:Tooltip(), "Click for the profile"), "Total RP 3's tooltip is whole")
    bert:Hover(anna, true)
    Eq(Count(bert:Tooltip(), "Stats"), 1, "and back on someone with stats")
    -- a builder of Total RP 3 for another tooltip (its companion tooltip) is left alone
    local other = bert.env.CreateFrame("GameTooltip", "TRP3_CompanionTooltip")
    local builder = bert.env.TRP3_API.ui.tooltip.createTooltipBuilder(other)
    for index = 1, 6 do builder:AddLine("Pet line " .. index, { "c" }, 12); builder:AddSpace() end
    builder:Build()
    Eq(Count(other.lines, "Stats"), 0, "no section in another tooltip")
    bert:Hover(anna, true)
    Eq(Count(bert:Tooltip(), "Stats"), 1, "and the count for the character tooltip is not thrown off by it")
    -- a profile without a character shows no section, on either side
    world:Advance(3)
    anna.addon:ReplaceSheet(anna.ns.NewSheet())
    anna.addon:State().created = false
    anna.addon:QueueBroadcast()
    world:Advance(3)
    bert:Hover(anna, true)
    Eq(Count(bert:Tooltip(), "Stats"), 0, "no section for a player who has no character")
    bert.addon:ReplaceSheet(bert.ns.NewSheet())
    bert:Hover(bert, true)
    Eq(Count(bert:Tooltip(), "Stats"), 0, "none on the player's own without a character")
    -- data that can't be turned into lines costs the section, not the tooltip
    bert:Build("MAGE", "", 3)
    bert.addon.GetStatLines = function() error("broken lines") end
    bert:Hover(bert, true)
    Check(Index(bert:Tooltip(), "Click for the profile") ~= nil, "Total RP 3's tooltip survives an error in the section")
    Eq(Count(bert:Tooltip(), "Stats"), 0, "and no title without lines is left in it")
    world:CheckClean("usual")
end)

Section("a Total RP 3 that is built differently", function()
    -- fewer blocks: the section goes to the bottom
    local world, bert, anna = Pair("short")
    bert:Hover(anna, true)
    local lines = bert:Tooltip()
    Eq(Count(lines, "Stats"), 1, "fewer blocks: one section")
    Check(Index(lines, "Stats") > Index(lines, "Click for the profile"), "fewer blocks: at the bottom")
    bert:Hover(anna, true)
    Eq(Count(bert:Tooltip(), "Stats"), 1, "fewer blocks: one section the second time")
    world:CheckClean("short")
    for _, shape in ipairs({ "flat", "throws", "bare" }) do
        world, bert, anna = Pair(shape)
        Check(bert.addon:GetCachedStats(anna.full) ~= nil, shape .. ": the stats are still received")
        if shape ~= "bare" then
            bert:Hover(anna, true)
            Eq(Count(bert:Tooltip(), "Stats"), 0, shape .. ": no section")
            Check(Index(bert:Tooltip(), "Click for the profile") ~= nil, shape .. ": Total RP 3's tooltip is whole")
        end
        anna.addon:TakeDamage(1)
        world:Advance(3)
        Eq(bert.addon.sheetKey, "trp3:p1", shape .. ": the profile link still works")
        world:CheckClean(shape)
    end
end)

Summary("t-sync-tooltip")
