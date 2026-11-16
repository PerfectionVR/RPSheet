-- The spellbook window's cantrips: the ones a Mage knows, and the exchange of one of
-- them after a long rest (Sheet/CantripSwap.lua). Left-click casts, right-click gives
-- a cantrip up; the cantrips to learn in its place are then listed below it.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI

local RULE = "When you finish a long rest you can exchange one of your cantrips for another of your class. As with your prepared spells, that can be done until you cast your first spell after the rest."
local HELP = "Left-click: cast it.\nRight-click: give it up for another cantrip."
local OFFER_HELP = "Right-click: learn it in place of the cantrip you gave up."

-- On the next frame: the row that was clicked is part of what gets rebuilt.
local function Change(self, name)
    if self:ChangeCantrip(name) then C_Timer.After(0, function() self:SheetChanged() end) end
end

function RPSheet:AddBookCantrips(body)
    local known, offered = self:BookCantrips()
    if #known + #offered == 0 then return end
    UI.AddHeading(body, "Cantrips")
    UI.AddLabel(body, 1, UI.GREY .. self:CantripStatus() .. "|r", nil, "Cantrips", RULE .. "\n\n" .. HELP)
    for _, name in ipairs(known) do
        local spell = self:PreparedSpell(name) or R.SPELLS[name]
        local info = self:SpellText(spell)
        local text = info ~= "" and ("%s  %s%s|r"):format(name, UI.GREY, info) or name
        UI.AddLabel(body, 1, text, function(button)
            if button == "RightButton" then Change(self, name) else self:CastFromBook(name, ns.RollMode()) end
        end, name, function() return ("%s\n%s%s|r"):format(spell.desc or "", UI.GREY, HELP) end)
    end
    for _, name in ipairs(offered) do
        UI.AddLabel(body, 1, ("%s%s  can be learned|r"):format(UI.GREY, name), function(button)
            if button == "RightButton" then Change(self, name) else self:Print(OFFER_HELP) end
        end, name, function() return ("%s\n%s%s|r"):format(R.SPELLS[name].desc or "", UI.GREY, OFFER_HELP) end)
    end
end
