-- Metamorphosis on the character: choosing a benefit when the spell is cast, keeping
-- to one benefit at a time, and what the benefits do that a plain bonus can't (data
-- in Data/Metamorphosis.lua). Armor Class, maximum hit points and the extra fire die
-- go through the passive's effects and strike like any other feature's.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local M = R.METAMORPHOSIS

-- The benefit passives a casting of this spell chooses between, in menu order.
-- Nil for any other spell, and for a character without them.
function RPSheet:SpellBenefits(spell)
    if spell.name ~= M.spell then return end
    local found = {}
    for _, name in ipairs(M.order) do
        for _, passive in ipairs(self:Sheet().passives) do
            if passive.name == name then
                found[#found + 1] = passive
                break
            end
        end
    end
    return #found > 0 and found or nil
end

-- A menu at the cursor with the benefits; onPick(passive) gets the one clicked.
-- Returns false when the game has no such menu, so the spell is cast without one.
function RPSheet:AskBenefit(spell, benefits, onPick)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        self:Print(("Switch on the benefit of %s yourself, under Passives and traits."):format(spell.name))
        return false
    end
    MenuUtil.CreateContextMenu(UIParent, function(_, root)
        root:CreateTitle(spell.name .. ": choose a benefit")
        for _, passive in ipairs(benefits) do
            local button = root:CreateButton(M.benefits[passive.name].label, function() onPick(passive) end)
            button:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, passive.name)
                GameTooltip_AddNormalLine(tooltip, passive.desc, true)
            end)
        end
    end)
    return true
end

-- Called when a passive has just gone from off to on. A benefit ends the other
-- benefits, and the one that raises maximum hit points raises the current ones too.
function RPSheet:PassiveSwitchedOn(passive)
    local benefit = M.benefits[passive.name]
    if not benefit then return end
    for _, other in ipairs(self:Sheet().passives) do
        if other ~= passive and M.benefits[other.name] then other.enabled = false end
    end
    if benefit.hp then
        local state, max = self:State(), self:MaxHP()
        state.hp = math.min(max, (state.hp or max) + benefit.hp)
    end
end

-- Switches on the benefit picked for a casting. Returns the words for the announcement.
-- A benefit that is on already just carries on: the hit points are not given twice.
function RPSheet:TakeBenefit(passive)
    if not passive.enabled then
        passive.enabled = true
        self:PassiveSwitchedOn(passive)
    end
    self:ClampState() -- a benefit that ended may have lowered maximum hit points
    return M.benefits[passive.name].took
end

-- Switches every benefit off, as a rest does. Returns true if one was on. The caller
-- brings current hit points back inside the lower maximum (ClampState).
function RPSheet:EndBenefits()
    local ended = false
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and M.benefits[passive.name] then
            passive.enabled = false
            ended = true
        end
    end
    return ended
end

-- Raises low force damage dice while a switched-on passive says so (flag forceMin).
-- Changes `rolls` in place and returns a note for the announcement, or nil.
function RPSheet:RaiseForceDice(rolls)
    local least = self:FeatureFlag("forceMin")
    if type(least) ~= "number" then return end
    local raised = 0
    for index, roll in ipairs(rolls) do
        if roll < least then
            rolls[index] = least
            raised = raised + 1
        end
    end
    if raised > 0 then
        return ("%d low %s raised to %d"):format(raised, raised == 1 and "die" or "dice", least)
    end
end
