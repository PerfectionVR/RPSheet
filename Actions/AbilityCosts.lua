-- Using an ability, first part: what its SPEND steps cost and whether that can be paid.
local _, ns = ...

-- Works out what the SPEND steps cost. Returns the costs and their wording, or nil
-- (after telling the player why) when the ability can't be paid for.
local function CollectCosts(self, ability)
    local costs, texts = {}, {}
    for _, action in ipairs(ability.actions) do
        -- Only with none of a resource left (Wild Resurgence: a slot for a Wild Shape use).
        if action.type == "EMPTYONLY" then
            local held = self:FindTracker(action.resource)
            if held and held.get() > 0 then
                self:Print(("%s: only when you have no %s left (%d left)."):format(ability.name, held.label, held.get()))
                return
            end
        end
        if action.type == "SPEND" then
            local tracker = self:FindTracker(action.resource)
            if not tracker then
                self:Print(("%s needs the resource \"%s\", which this sheet doesn't have."):format(ability.name, action.resource))
                return
            end
            -- Used up, but another resource can pay for it (Psychic Veil, a spell slot for
            -- Holy Nimbus, a Rage use for Intimidating Presence), maybe only while a
            -- passive is on (Aspect of the Horsemen). A slot then follows the slot rules below.
            local amount = action.amount
            if (action.otherwise or "") ~= "" and tracker.get() < amount and self:OtherwiseAllowed(action) then
                local other = self:FindTracker(action.otherwise)
                if other then tracker, amount = other, action.otherwiseAmount end
            end
            -- The "Cast at" row picks a higher slot to pay with.
            if tracker.kind == "slot" and self.castLevel and self.castLevel > tracker.level then
                for _, other in ipairs(self:GetTrackers()) do
                    -- Of two kinds of slot of that level (Pact Magic beside the others), one with a use left.
                    if other.kind == "slot" and other.level == self.castLevel
                        and (tracker.level ~= self.castLevel or tracker.get() < amount) then
                        tracker = other
                    end
                end
            end
            -- A spell slot that is used up can be paid with the lowest higher one left.
            -- Pact Magic slots kept beside the others count too, at the same level or above.
            if tracker.kind == "slot" and tracker.get() < amount then
                local empty, best = tracker, nil
                for _, other in ipairs(self:GetTrackers()) do
                    if other.kind == "slot" and other.label ~= empty.label and other.level >= empty.level
                        and other.get() >= amount and (not best or other.level < best.level) then
                        best = other
                    end
                end
                tracker = best or tracker
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

-- True if a SPEND step's other resource may pay now: always, or while the passive it
-- names is switched on.
local RPSheet = ns.addon
function RPSheet:OtherwiseAllowed(action)
    if (action.otherwiseWhile or "") == "" then return true end
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and passive.name == action.otherwiseWhile then return true end
    end
    return false
end

ns.AbilityKit = { CollectCosts = CollectCosts }
