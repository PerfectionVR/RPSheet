-- Three small rows under the "Next roll" row of the sheet's top part: a die added to
-- the next d20, a die taken off it, and a plain number (Actions/NextRollBonus.lua).
-- UI.HeaderSection adds them with UI.NextRollSection(self, body); until it does, they
-- are put below the top part.
local _, ns = ...
local RPSheet = ns.addon
local UI = ns.UI

local KEEP = "\nShift-click: keep what is set for every roll, or go back to one roll."
local GREEN, RED = "|cff80ff80", "|cffff5555"

function UI.NextRollSection(self, body)
    self.nextRollAdded = true
    local function Die(sign, title, tip)
        return UI.AddLabel(body, 0.33, " ", function(button)
            if IsShiftKeyDown() then return self:LockRollBonus() end
            self:SetRollBonusDie(sign, button == "RightButton")
        end, title, tip .. "\n\nLeft-click: a d4, on or off. It is rolled after the d20 and used up by that roll.\nRight-click: a larger die." .. KEEP)
    end
    self.rollBonusLabels = {
        plus = Die(1, "Next roll: a die added", "A die added to your next d20 roll: Bless, Guidance, Bardic Inspiration."),
        minus = Die(-1, "Next roll: a die taken off", "A die taken off your next d20 roll: Bane and the like."),
        flat = UI.AddLabel(body, 0.33, " ", function(button)
            if IsShiftKeyDown() then return self:LockRollBonus() end
            self:ChangeRollBonusFlat(button == "RightButton" and -1 or 1)
        end, "Next roll: a number", "A number added to your next d20 roll, or taken off it: cover on a Dexterity save, a ruling of the DM.\n\nLeft-click: one more.\nRight-click: one less. It is used up by the roll." .. KEEP),
    }
    self:RefreshRollBonus()
end

-- The text of the three rows: grey while nothing is set. Like RPSheet:Refresh, it
-- leaves rows alone that a closed or out-of-date window no longer shows.
function RPSheet:RefreshRollBonus()
    local labels = self.rollBonusLabels
    if not labels or not self.window or not self.channelLabel or self.populateSkipped then return end
    local die, flat = self.rollBonusDie, self.rollBonusFlat or 0
    local kept = self.rollBonusLocked and " (every roll)" or ""
    local plus, minus = die and die.sign > 0, die and die.sign < 0
    labels.plus:SetText(plus and ("%s+d%d|r%s"):format(GREEN, die.sides, kept) or (UI.GREY .. "+d4|r"))
    labels.minus:SetText(minus and ("%s-d%d|r%s"):format(RED, die.sides, kept) or (UI.GREY .. "-d4|r"))
    labels.flat:SetText(flat ~= 0 and ("%s%s|r%s"):format(flat > 0 and GREEN or RED, ns.Util.Signed(flat), kept) or (UI.GREY .. "+N|r"))
end

-- Until the top part adds the rows itself, they go right below it.
local Header = UI.HeaderSection
function UI.HeaderSection(self, body)
    self.nextRollAdded, self.rollBonusLabels = false, nil
    Header(self, body)
    if not self.nextRollAdded then UI.NextRollSection(self, body) end
end
