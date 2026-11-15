-- The top of the sheet: who the character is, where rolls are announced, how the next
-- roll is made, the slot the next spell uses, and the two rests.
local _, ns = ...
local UI = ns.UI

function UI.HeaderSection(self, body)
    local summary = self:Summary()
    if summary then
        UI.AddLabel(body, 1, UI.GREY .. summary .. "|r")
    else
        UI.AddLabel(body, 1, UI.ACCENT .. "No class chosen yet - click here to create your character|r", function()
            ns.OpenWizard()
        end)
    end

    self.channelLabel = UI.AddLabel(body, 1, "", function() self:CycleChannel() end,
        "Announce to", "Click to switch between Emote, Party, Raid and Self only.\nSelf only rolls privately; the others use a real /roll.")

    self.rollModeLabel = UI.AddLabel(body, 1, "", function(button) self:CycleRollMode(button == "RightButton") end,
        "Next roll", "How your next d20 is rolled: normally, with advantage (two dice, the higher counts) or with disadvantage (the lower counts).\n\nLeft-click: switch between normal, advantage and disadvantage. It goes back to normal after one roll.\nRight-click: keep it for every roll until you change it, for a condition that lasts.\n\nHolding Shift or Ctrl while clicking a roll still works, and takes priority.")

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

    UI.AddLabel(body, 0.5, UI.ACCENT .. "Short rest|r", function() self:ShortRest() end,
        "Short rest", "Gives back what recharges on a short rest. To heal, click the Hit Dice bar.")
    UI.AddLabel(body, 0.5, UI.ACCENT .. "Long rest|r", function() self:LongRest() end,
        "Long rest", "Restores HP, hit dice, class resources, your own resources and spell slots.")
end
