-- Spells that need their components once for each target (Astral Projection, Create
-- Undead; data in Data/SpellComponentKinds.lua): casting one asks how many, and that
-- many are checked for and taken (Sheet/SpellComponents.lua).
--
-- The question travels the road Actions/Spells.lua already has for a choice made
-- before anything is spent: RPSheet:SpellBenefits, AskBenefit and TakeBenefit, wrapped
-- here the way Sheet/WardCasting.lua wraps them. A pick of ours is a table with
-- targets = the number; any other spell gets the earlier answer.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local SpellBenefits, AskBenefit, TakeBenefit = RPSheet.SpellBenefits, RPSheet.AskBenefit, RPSheet.TakeBenefit

-- What one of them is called: the word of the first part that is needed for each.
local function EachWord(spell)
    for _, part in ipairs(R.SPELL_COMPONENTS[spell.name] or {}) do
        if part.each then return part.each end
    end
end

-- `slotLevel` is the level of the slot the casting uses, which can raise the number.
function RPSheet:SpellBenefits(spell, slotLevel)
    local earlier = SpellBenefits(self, spell)
    local rule, word = R.COMPONENT_TARGETS[spell.name], EachWord(spell)
    if earlier or not rule or not word or not self:SpellComponents(spell) then return earlier end
    local most = rule.max + (rule.up or 0) * math.max(0, (slotLevel or spell.level) - spell.level)
    local picks = {}
    for count = 1, most do
        picks[count] = { targets = count, spell = spell.name, word = word }
    end
    return picks
end

function RPSheet:AskBenefit(spell, benefits, onPick)
    if not (benefits[1] and benefits[1].targets) then return AskBenefit(self, spell, benefits, onPick) end
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        self:Print(("%s is checked for one %s; see to the components of the others yourself."):format(spell.name, benefits[1].word))
        return false
    end
    MenuUtil.CreateContextMenu(UIParent, function(_, root)
        root:CreateTitle(("%s: how many %ss?"):format(spell.name, benefits[1].word))
        for _, pick in ipairs(benefits) do
            -- A number the components don't stretch to is shown, and refused when clicked.
            local short = self:MissingComponents(spell, pick)
            local button = root:CreateButton(short and ("|cff909090%d (too few components)|r"):format(pick.targets) or tostring(pick.targets),
                function() onPick(pick) end)
            button:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, spell.name)
                GameTooltip_AddNormalLine(tooltip, short or "The components are needed once for each, and that many are checked for.", true)
            end)
        end
    end)
    return true
end

-- Nothing to switch on: only the words for the announcement.
function RPSheet:TakeBenefit(pick)
    if not pick.targets then return TakeBenefit(self, pick) end
    return ("for %d %s%s"):format(pick.targets, pick.word, pick.targets == 1 and "" or "s")
end
