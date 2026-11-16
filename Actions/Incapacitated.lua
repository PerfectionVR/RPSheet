-- What being incapacitated does to the character's own turn: no actions, bonus
-- actions or reactions, so an attack, an ability or a spell is refused with a line
-- that says why; and what lasts "until you are incapacitated" ends when such a
-- condition is ticked. Saving throws and death saves still roll.
-- (A spell being held and a Wild Shape form end in Actions/Conditions.lua; a Beast
-- Master's companion acts by itself while its master can't.)
local _, ns = ...
local RPSheet = ns.addon

local R = ns.Rules

-- True, after telling the player why, when the character can't do `what` ("attack",
-- "use Second Wind") because of a condition that incapacitates.
function RPSheet:CantAct(what)
    local name = self:Incapacitated()
    if not name then return false end
    self:Print(("You can't %s while %s: no actions, bonus actions or reactions."):format(what, name:lower()))
    return true
end

-- Called when `condition` has just been ticked and is one that incapacitates.
function RPSheet:EndForIncapacitated(condition)
    local sheet, ended, seen = self:Sheet(), {}, {}
    -- From level 15 (Persistent Rage, an ability of the class) a rage only ends early
    -- when the character is knocked out.
    local persistent = false
    for _, ability in ipairs(sheet.abilities) do
        if ability.name == "Persistent Rage" and (ability.auto or "") ~= "" then persistent = true end
    end
    for _, passive in ipairs(sheet.passives) do
        -- The switched-on passives of class features that end so (Data/Lasting.lua).
        local lasting = passive.enabled and (passive.auto or "") ~= "" and R.LASTING[passive.name]
        local label = lasting and lasting.incapacitated and lasting.label
        if label and not (label == "Rage" and persistent and condition ~= "Unconscious") then
            passive.enabled = false
            if not seen[label] then
                seen[label] = true
                ended[#ended + 1] = label
            end
        end
    end
    if #ended == 0 then return end
    self:Announce(("loses %s: %s."):format(table.concat(ended, ", "), condition:lower()))
    self:ClampState()
end
