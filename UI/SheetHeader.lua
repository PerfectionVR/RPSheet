-- The top of the sheet: who the character is, where rolls are announced, how the next
-- roll is made, the slot the next spell uses, and the two rests.
local _, ns = ...
local UI = ns.UI

function UI.HeaderSection(self, body)
    -- (who the character is stands on the window's rail: UI/SheetTabs.lua)
    if not self:Summary() then
        UI.AddLabel(body, 1, UI.GREY .. "No class chosen yet.|r")
        UI.AddLabel(body, 1, UI.ACCENT .. "Create your character|r", function()
            ns.OpenWizard()
        end, "Create your character", "Opens the steps that make a character: class, species, background, ability scores and what it starts with.")
    end

    self.channelLabel = UI.AddLabel(body, 0.5, "", function() self:CycleChannel() end,
        "Announce to", "Click to switch between Emote, Party, Raid and Self only.\nSelf only rolls privately; the others use a real /roll.")

    self.rollModeLabel = UI.AddLabel(body, 0.5, "", function(button) self:CycleRollMode(button == "RightButton") end,
        "Next roll", "How your next d20 is rolled: normally, with advantage (two dice, the higher counts) or with disadvantage (the lower counts).\n\nLeft-click: switch between normal, advantage and disadvantage. It goes back to normal after one roll.\nRight-click: keep it for every roll until you change it, for a condition that lasts.\n\nHolding Shift or Ctrl while clicking a roll still works, and takes priority.")

    -- A die or a number added to the next d20 (UI/SheetNextRoll.lua).
    UI.NextRollSection(self, body)
    self.nextRollAdded = true

    -- Only for a character with spell slots of more than one level.
    self.castLevelLabel = nil
    local slotLevels = 0
    for _, count in pairs(self:SpellSlots()) do
        if count > 0 then slotLevels = slotLevels + 1 end
    end
    if slotLevels > 1 then
        self.castLevelLabel = UI.AddLabel(body, 1, "", function() self:CycleCastLevel() end,
            "Cast at", "The slot your next spell uses. Normally the lowest free slot that fits. Click to pick a higher level: spells that grow with the slot roll more dice. It goes back to the lowest after one spell.")
    end

    -- A rest happens at one click; a right-click takes the last one back (Actions/RestUndo.lua).
    local UNDO = "\n\nRight-click: take the last rest back. That works until your next roll, spell, damage or rest."
    local function Rest(rest)
        return function(button)
            if button == "RightButton" then self:UndoRest() else rest(self) end
        end
    end
    UI.AddLabel(body, 0.5, UI.ACCENT .. "Short rest|r", Rest(self.ShortRest),
        "Short rest", "Gives back what recharges on a short rest. To heal, click the Hit Dice bar." .. UNDO)
    UI.AddLabel(body, 0.5, UI.ACCENT .. "Long rest|r", Rest(self.LongRest),
        "Long rest", "Restores HP, hit dice, class resources, your own resources and spell slots." .. UNDO)
end
