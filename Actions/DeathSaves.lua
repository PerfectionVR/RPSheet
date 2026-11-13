-- Death saving throws, rolled while the character is at 0 HP.
-- 10 or higher passes; three passes stabilise, three failures kill.
-- A natural 20 puts the character back on 1 HP; a natural 1 counts as two failures.
local _, ns = ...
local RPSheet = ns.addon

function RPSheet:IsDown()
    return (self:State().hp or 1) <= 0
end

function RPSheet:ClearDeathSaves()
    local state = self:State()
    state.deathPass, state.deathFail = 0, 0
end

function RPSheet:RollDeathSave()
    local state = self:State()
    if not self:IsDown() then return end
    self:RollD20(nil, function(d20)
        local outcome
        if d20 == 20 then
            state.hp = 1
            self:ClearDeathSaves()
            outcome = "NATURAL 20! Back up with 1 HP"
        else
            if d20 >= 10 then
                state.deathPass = math.min(3, state.deathPass + 1)
            else
                state.deathFail = math.min(3, state.deathFail + (d20 == 1 and 2 or 1))
            end
            outcome = ("%s - %d passed, %d failed"):format(
                d20 >= 10 and "passed" or (d20 == 1 and "natural 1, two failures" or "failed"),
                state.deathPass, state.deathFail)
            if state.deathFail >= 3 then
                outcome = outcome .. ". Dead"
            elseif state.deathPass >= 3 then
                outcome = outcome .. ". Stable"
            end
        end
        self:Announce(("rolls a death save: %d (%s)."):format(d20, outcome))
        self:PopulateSoon()
    end)
end
