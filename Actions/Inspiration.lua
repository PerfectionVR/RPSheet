-- Heroic Inspiration: gaining and spending it, and the traits and blessings that hang
-- on it. An Amani troll regains a Hit Die when it is spent; a Zandalari troll gains it
-- on a natural 1; a draenei's Heroic Presence gives it when a lineage spell is cast;
-- a short rest in meditation gives it to the Tushui (Actions/Rest.lua). One is all a
-- character can have.
local _, ns = ...
local RPSheet = ns.addon

-- Gives Heroic Inspiration. False if the character had it already.
function RPSheet:GainInspiration()
    local state = self:State()
    if state.inspiration then return false end
    state.inspiration = true
    return true
end

-- Spends it. An Amani troll regains one spent Hit Die: from the first bar that has one
-- spent. Returns a note for the announcement, or nil.
function RPSheet:SpendInspiration()
    local state = self:State()
    if not state.inspiration then return end
    state.inspiration = false
    if self:Sheet().lineage ~= "Amani Troll" or not self:HasTrait("Troll Lineage") then return end
    for _, tracker in ipairs(self:GetTrackers()) do
        if tracker.kind == "hitdice" and (tracker.get() or 0) < tracker.max then
            tracker.set(tracker.get() + 1)
            return ("regains a spent Hit Die (%s)"):format(ns.Mark("Amani Troll"))
        end
    end
end

-- The sheet's Inspiration row: a click gains or spends it.
function RPSheet:ToggleInspiration()
    if self:State().inspiration then
        local note = self:SpendInspiration()
        if note then self:Announce(("spends %s and %s."):format(ns.Mark("Heroic Inspiration"), note)) end
    else
        self:GainInspiration()
    end
    self:Refresh()
end

-- A natural 1 on a d20 test: a Zandalari troll gains Heroic Inspiration.
function RPSheet:NaturalOne()
    if self:Sheet().lineage ~= "Zandalari Troll" or not self:HasTrait("Troll Lineage") then return end
    if self:GainInspiration() then
        self:Print("Zandalari Troll: the 1 gives you Heroic Inspiration.")
        self:PopulateSoon()
    end
end

-- Heroic Presence: casting a spell of the Eredar Lineage gives Heroic Inspiration to a
-- draenei without it, once per rest. Returns a note for the casting, or nil.
function RPSheet:HeroicPresence(spell)
    if (spell.auto or "") ~= "species:" .. spell.name or not self:HasTrait("Heroic Presence") then return end
    local tracker = self:FindTracker("Heroic Presence")
    if self:State().inspiration or not tracker or (tracker.get() or 0) <= 0 then return end
    tracker.set(tracker.get() - 1)
    self:GainInspiration()
    return ("gains Heroic Inspiration (%s)"):format(ns.Mark("Heroic Presence"))
end
