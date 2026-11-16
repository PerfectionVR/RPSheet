-- Archaeology: digging for fragments, and piecing six of them into a relic or six
-- magic ones into a magic item. Fragments only fit together when they have the same
-- origin, which the sheet doesn't track: the player keeps to that.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local HISTORY
for _, skill in ipairs(R.SKILLS) do
    if skill.name == "History" then HISTORY = skill end
end
local ARCHAEOLOGY = R.PROFESSIONS.archaeology

local function Ready(self)
    local can, lacks = self:CanPractise(ARCHAEOLOGY)
    if not can then self:Print(("Archaeology needs %s."):format(lacks)) end
    return can
end

-- An Intelligence (History) check against a DC; `done(d20, total, text)` finishes it.
local function HistoryCheck(self, shown, mode, dc, done)
    self:RollAgainst("History", ("%s, %s"):format(shown, ns.Mark("History")), self:SkillMod(HISTORY),
        self:ResolveMode("History", mode), dc, done)
end

-- An hour at a dig site.
function RPSheet:Dig(mode)
    if not Ready(self) then return end
    local region, fragments = self:GatherRegion(), self:Trade().fragments
    HistoryCheck(self, "Archaeology", mode, region.dc, function(d20, total, text)
        if d20 == 20 then
            fragments.magic = fragments.magic + 1
            self:Announce(text .. ": unearths a magic fragment.")
        elseif total >= region.dc + R.RARE_FIND_MARGIN then
            self:Announce(("%s: unearths a whole relic worth %s."):format(text, ns.CoinText(region.rare)))
            self:AddRelic(region.rare)
        elseif total >= region.dc then
            self:Roll(R.FRAGMENT_DIE, function(count)
                fragments.plain = fragments.plain + count
                self:Announce(("%s: unearths %d %s."):format(text, count, count == 1 and "fragment" or "fragments"))
                self:PopulateSoon()
            end)
            return
        else
            self:Announce(text .. ": nothing found.")
        end
        self:PopulateSoon()
    end)
end

-- A relic as something carried, priced at what it is worth.
function RPSheet:AddRelic(worth)
    local item = self:AddItem(("Relic (%s)"):format(ns.CoinText(worth)), 1)
    item.cost, item.desc = worth, "A piece of history. A collector pays its price."
    ns.RebuildOptions() -- it has a page under Customize
end

-- Why six fragments can't be pieced together now, or nil.
function RPSheet:RelicBlocked()
    local fragments = self:Trade().fragments
    if fragments.plain < R.RELIC_FRAGMENTS then return ("you need %d fragments of one origin"):format(R.RELIC_FRAGMENTS) end
    if fragments.failedAt == fragments.plain then return "after a failed try you need at least one more fragment first" end
end

-- Six fragments into a relic, worth a common find for the character's own level.
function RPSheet:AssembleRelic(mode)
    if not Ready(self) then return end
    local blocked = self:RelicBlocked()
    if blocked then
        self:Print(("You can't assemble a relic: %s."):format(blocked))
        return
    end
    local fragments = self:Trade().fragments
    HistoryCheck(self, "Assembling a relic", mode, R.RELIC_DC, function(_, total, text)
        if total >= R.RELIC_DC then
            local worth = ns.RegionForLevel(self:Level()).common
            fragments.plain, fragments.failedAt = fragments.plain - R.RELIC_FRAGMENTS, nil
            self:Announce(("%s: the fragments make a relic worth %s."):format(text, ns.CoinText(worth)))
            self:AddRelic(worth)
        else
            fragments.failedAt = fragments.plain
            self:Announce(text .. ": the fragments don't fit yet.")
        end
        self:PopulateSoon()
    end)
end

-- Six magic fragments into a magic item. Which one is the DM's choice.
function RPSheet:AssembleMagicItem()
    if not Ready(self) then return end
    local fragments = self:Trade().fragments
    if fragments.magic < R.RELIC_FRAGMENTS then
        self:Print(("You need %d magic fragments of one origin; you have %d."):format(R.RELIC_FRAGMENTS, fragments.magic))
        return
    end
    fragments.magic = fragments.magic - R.RELIC_FRAGMENTS
    self:Announce(("pieces %d magic fragments together into a magic item: %s, of the DM's choice."):format(
        R.RELIC_FRAGMENTS, R.PROFESSION_LEVELS[self:ProfessionLevel()].rarity:lower()))
    self:Print("Add the item the DM names in the item browser or under Customize, Inventory.")
    self:PopulateSoon()
end
