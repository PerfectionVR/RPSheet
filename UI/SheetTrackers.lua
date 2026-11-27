-- The sheet's trackers: bars for HP, hit dice and resources, temporary HP, inspiration,
-- the damage rows, death saves (only at 0 HP) and the spell slots.
local _, ns = ...
local UI = ns.UI

local TRACKER_HELP = "Left-click: +1\nRight-click: -1\nShift-click: reset"
local HIT_DICE_HELP = "Left-click: spend one to heal (rolls the die and adds your Constitution modifier)\nRight-click: give one back\nShift-click: reset"

-- Bars for HP, hit dice and resources, then temporary HP, inspiration, death saves
-- (only at 0 HP), and spell slots as compact rows.
function UI.TrackerSection(self, body)
    local theme, state = self.db.profile.theme, self:State()
    local barColors = { hp = theme.barHP, hitdice = theme.barHP, pool = theme.barResource, resource = theme.barCounter }
    local trackers = self:GetTrackers()
    self.trackerRows = {}

    local function Change(tracker, button)
        local wasDown = self:IsDown()
        if IsShiftKeyDown() then
            tracker.set(tracker.reset)
        elseif tracker.kind == "hitdice" and button == "LeftButton" then
            self:SpendHitDie(tracker)
            return
        else
            tracker.set(tracker.get() + (button == "LeftButton" and 1 or -1))
            if tracker.kind == "hp" and button ~= "LeftButton" then self:DamageTaken(1) end
        end
        if tracker.kind == "hp" and wasDown ~= self:IsDown() then
            -- Dropping to 0 shows the death save row; getting back up removes it.
            self:ClearDeathSaves()
            if self:IsDown() then
                self:EndConcentration("at 0 hit points")
                self:LeaveForms("at 0 hit points")
            end
            self:PopulateSoon()
        end
        self:Refresh()
    end

    for _, tracker in ipairs(trackers) do
        if tracker.kind ~= "slot" then
            local bar = UI.AddBar(body, barColors[tracker.kind], function(button) Change(tracker, button) end,
                tracker.label, tracker.kind == "hitdice" and HIT_DICE_HELP or TRACKER_HELP, true)
            self.trackerRows[#self.trackerRows + 1] = { widget = bar, tracker = tracker, bar = true }
        end
    end

    self.tempLabel = UI.AddLabel(body, 0.5, "", function(button)
        if IsShiftKeyDown() then
            state.tempHP = 0
        else
            state.tempHP = math.max(0, state.tempHP + (button == "LeftButton" and 1 or -1))
        end
        self:Refresh()
    end, "Temporary HP", "A buffer that is lost before your real hit points. It doesn't stack and a long rest removes it.\n\n" .. TRACKER_HELP)

    self.inspirationLabel = UI.AddLabel(body, 0.5, "", function()
        self:ToggleInspiration() -- (Actions/Inspiration.lua: an Amani troll regains a Hit Die)
    end, "Heroic Inspiration", ns.Glossary["Heroic Inspiration"] .. "\n\nClick to gain or spend it.")

    UI.AddDamageRows(self, body) -- damage by amount and type, with the rules applied

    self.deathLabel = nil
    if self:IsDown() then
        self.deathLabel = UI.AddLabel(body, 1, "", function(button)
            if button == "RightButton" then
                -- Stable but hurt again: the count starts over.
                self:ClearDeathSaves()
                self:Refresh()
            else
                self:RollDeathSave()
            end
        end, "Death saving throw", "You are at 0 HP. Roll a d20 at the start of each turn: 10 or higher passes. Three passes and you are stable: still at 0 HP and unconscious, but no longer rolling. Three failures and you die. A natural 20 puts you back on 1 HP; a natural 1 counts as two failures.\n\nRight-click to start the count over, for when a stable character takes damage.")
    end

    local hasSlots = false
    for _, tracker in ipairs(trackers) do
        if tracker.kind == "slot" then
            if not hasSlots then
                UI.AddHeading(body, "Spell slots")
                hasSlots = true
            end
            local label = UI.AddLabel(body, 0.33, "", function(button) Change(tracker, button) end, tracker.label, TRACKER_HELP)
            self.trackerRows[#self.trackerRows + 1] = { widget = label, tracker = tracker }
        end
    end
end
