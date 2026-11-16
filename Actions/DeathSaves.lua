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
    -- The saves end once they are decided, one way or the other.
    if state.deathFail >= 3 then
        self:Print("Your character is dead: no more death saves.")
        return
    elseif state.deathPass >= 3 then
        self:Print("Your character is stable at 0 HP: no more death saves. Healing brings them back up. If they take damage, right-click the death save row to start the count over.")
        return
    end
    -- A Champion's Survivor: advantage, and 18 or 19 count as a 20.
    local survivor = self:HasAdvantage("death save")
    -- The Durable feat gives the advantage without the rest, and so does a loyal
    -- undead companion (RPSheet:AdvantageFrom).
    local advantage = survivor or self:HasAdvantage("death save roll") or self:AdvantageFrom("death save roll") ~= nil
    -- Exhaustion weighs on this roll like on any d20; a natural 20 or 1 goes by the die.
    local penalty = ns.Rules.EXHAUSTION_D20 * self:Exhaustion()
    self:RollD20(advantage and "ADV" or nil, function(d20)
        local outcome
        local passed = d20 - penalty >= 10
        if d20 == 20 or (survivor and d20 >= 18) then
            state.hp = 1
            self:ClearDeathSaves()
            outcome = d20 == 20 and "NATURAL 20! Back up with 1 HP" or "counts as a 20 for a Survivor. Back up with 1 HP"
        else
            if passed then
                state.deathPass = math.min(3, state.deathPass + 1)
            else
                state.deathFail = math.min(3, state.deathFail + (d20 == 1 and 2 or 1))
            end
            outcome = ("%s - %d passed, %d failed"):format(
                passed and "passed" or (d20 == 1 and "natural 1, two failures" or "failed"),
                state.deathPass, state.deathFail)
            if state.deathFail >= 3 then
                outcome = outcome .. ". Dead"
            elseif state.deathPass >= 3 then
                outcome = outcome .. ". Stable"
            end
        end
        self:Announce(("rolls a death save: %d%s (%s)."):format(d20, penalty > 0 and (" - %d for exhaustion"):format(penalty) or "", outcome))
        self:PopulateSoon()
    end, true)
end
