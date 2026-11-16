-- What class features give back when the character rolls initiative (the Initiative
-- row, Actions/Dice.lua):
--   Soul Shatter    a soul fragment, with none left
--   Archdruid       a Wild Shape use, with none left
--   Perfect Focus   Focus Points up to 4, with 3 or fewer; using Uncanny Metabolism
--                   afterwards fills them anyway, so nothing is lost by giving them first
local _, ns = ...
local RPSheet = ns.addon

local GAINS = {
    { feature = "Soul Shatter", bar = "Soul Fragments", below = 1, upTo = 1 },
    { feature = "Archdruid", bar = "Wild Shape", below = 1, upTo = 1 },
    { feature = "Perfect Focus", bar = "Focus Points", below = 4, upTo = 4 },
}

-- Gives back what the features say. Returns a note for the announcement, or nil.
function RPSheet:InitiativeGains()
    local sheet, notes = self:Sheet(), {}
    for _, gain in ipairs(GAINS) do
        local tracker = ns.HasFeature(sheet, gain.feature) and self:FindTracker(gain.bar)
        local before = tracker and tracker.get() or 0
        if tracker and before < gain.below then
            tracker.set(math.max(before, gain.upTo))
            if tracker.get() > before then
                notes[#notes + 1] = ("%s: %s %d to %d"):format(gain.feature, tracker.label, before, tracker.get())
            end
        end
    end
    if #notes == 0 then return nil end
    self:PopulateSoon()
    return table.concat(notes, ", ")
end
