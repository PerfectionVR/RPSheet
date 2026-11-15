-- Casting a protective spell (Data/SpellWards.lua) from the sheet: it asks whether the
-- spell is on yourself, and with which option, and then switches on its ward
-- (Sheet/Wards.lua).
--
-- Actions/Spells.lua already asks a spell for a choice of benefits before it spends
-- anything: RPSheet:SpellBenefits, then RPSheet:AskBenefit, then RPSheet:TakeBenefit
-- with the pick (made for Metamorphosis, Sheet/Metamorphosis.lua). The three are
-- wrapped here, so a ward's choice travels the same road and the casting code is
-- untouched. A pick of ours is a table with ward = true.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local SpellBenefits, AskBenefit, TakeBenefit = RPSheet.SpellBenefits, RPSheet.AskBenefit, RPSheet.TakeBenefit

-- The picks a casting chooses between, or the earlier answer for any other spell.
-- CastSpell asks this once nothing can stop the casting any more, so it is also where
-- a new concentration spell ends the wards that hung on the old one.
function RPSheet:SpellBenefits(spell)
    local ward = R.SPELL_WARDS[spell.name]
    if not ward then
        local benefits = SpellBenefits(self, spell)
        -- With a menu of its own the casting can still be called off, so nothing ends yet.
        if not benefits and spell.concentration and self:State().conditions.Concentrating then self:EndConcentrationWards() end
        return benefits
    end
    local picks = {}
    for index, option in ipairs(ward) do
        picks[#picks + 1] = { ward = true, spell = spell.name, index = index, option = option }
    end
    return picks
end

function RPSheet:AskBenefit(spell, benefits, onPick)
    if not (benefits[1] and benefits[1].ward) then return AskBenefit(self, spell, benefits, onPick) end
    local ward = R.SPELL_WARDS[spell.name]
    -- Always on the caster and nothing to choose: no question.
    if ward.own and #benefits == 1 then
        onPick(benefits[1])
        return true
    end
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        if ward.conc then self:EndWards(nil, true) end
        self:Print(("If %s is on you, add its protection as a passive of your own."):format(spell.name))
        return false
    end
    MenuUtil.CreateContextMenu(UIParent, function(_, root)
        root:CreateTitle(spell.name .. (ward.own and ": which one?" or ": who is it for?"))
        for _, pick in ipairs(benefits) do
            local label = pick.option.label
            local text = label and ("Yourself: " .. label) or "Yourself"
            if ward.own and label then text = label:sub(1, 1):upper() .. label:sub(2) end
            local button = root:CreateButton(text, function() onPick(pick) end)
            button:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, spell.name)
                GameTooltip_AddNormalLine(tooltip, ("The sheet counts %s while the spell lasts."):format(ns.WardText(pick.option)), true)
            end)
        end
        -- A pick without an option: the spell is cast, and nothing is switched on.
        if not ward.own then root:CreateButton("Someone else", function() onPick({ ward = true, spell = spell.name }) end) end
    end)
    return true
end

-- Switches the picked ward on. Returns the words for the announcement, or nil.
function RPSheet:TakeBenefit(pick)
    if not pick.ward then return TakeBenefit(self, pick) end
    local ward = R.SPELL_WARDS[pick.spell]
    if not ward then return end
    -- CastSpell has just started concentrating on this spell: the old spell's wards go.
    if ward.conc then self:EndWards(nil, true) end
    if not pick.index then return end -- cast on someone else
    local option = self:StartWard(pick.spell, pick.index)
    return option and (ns.WardText(option) .. " while it lasts")
end
