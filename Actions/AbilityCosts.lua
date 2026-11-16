-- Using an ability, first part: what its SPEND steps cost and whether that can be paid.
local _, ns = ...

-- Works out what the SPEND steps cost. Returns the costs and their wording, or nil
-- (after telling the player why) when the ability can't be paid for.
local function CollectCosts(self, ability)
    local costs, texts = {}, {}
    for _, action in ipairs(ability.actions) do
        if action.type == "SPEND" then
            local tracker = self:FindTracker(action.resource)
            if not tracker then
                self:Print(("%s needs the resource \"%s\", which this sheet doesn't have."):format(ability.name, action.resource))
                return
            end
            -- The "Cast at" row picks a higher slot to pay with.
            if tracker.kind == "slot" and self.castLevel and self.castLevel > tracker.level then
                for _, other in ipairs(self:GetTrackers()) do
                    -- Of two kinds of slot of that level (Pact Magic beside the others), one with a use left.
                    if other.kind == "slot" and other.level == self.castLevel
                        and (tracker.level ~= self.castLevel or tracker.get() < action.amount) then
                        tracker = other
                    end
                end
            end
            -- A spell slot that is used up can be paid with the lowest higher one left.
            -- Pact Magic slots kept beside the others count too, at the same level or above.
            if tracker.kind == "slot" and tracker.get() < action.amount then
                local empty, best = tracker, nil
                for _, other in ipairs(self:GetTrackers()) do
                    if other.kind == "slot" and other.label ~= empty.label and other.level >= empty.level
                        and other.get() >= action.amount and (not best or other.level < best.level) then
                        best = other
                    end
                end
                tracker = best or tracker
            end
            -- Used up, but another resource can pay for it (Psychic Veil, Rend Mind).
            local amount = action.amount
            if (action.otherwise or "") ~= "" and tracker.get() < amount then
                local other = self:FindTracker(action.otherwise)
                if other then tracker, amount = other, action.otherwiseAmount end
            end
            local full = action.freeIfFull ~= "" and self:FindTracker(action.freeIfFull)
            if full and full.get() >= full.max then
                texts[#texts + 1] = ("free, %s is full"):format(full.label)
            elseif action.firstFree and self:FreeUseLeft(ability.name) then
                costs.freeUse = true -- marked as taken once the ability has gone through
                texts[#texts + 1] = "free, the first use since a long rest"
            else
                -- `refund` lets the player take it back afterwards (Actions/Refunds.lua).
                costs[#costs + 1] = { tracker = tracker, amount = amount, refund = action.refund }
                if tracker.kind == "slot" then costs.slotLevel = tracker.level end
                texts[#texts + 1] = ("%d %s"):format(amount, tracker.label)
            end
        end
    end
    local needed = {}
    for _, cost in ipairs(costs) do
        local label = cost.tracker.label
        needed[label] = (needed[label] or 0) + cost.amount
        if needed[label] > cost.tracker.get() then
            self:Print(("Not enough %s for %s (%d needed, %d left)."):format(label, ability.name, needed[label], cost.tracker.get()))
            return
        end
    end
    return costs, texts
end

ns.AbilityKit = { CollectCosts = CollectCosts }
