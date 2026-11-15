-- Costs that aren't always paid (see Kit.Refundable and Kit.FirstFree):
--   a use or die that is only spent when the roll it was added to turned things around.
--     The DM decides that, so the player says so afterwards: one click on a link in
--     chat, or a right-click on the ability, takes the cost back. Once per use.
--   a cost that is waived for the first use of an ability after each long rest.
local _, ns = ...
local RPSheet = ns.addon

-- A link type of its own, so the term links of Integrations/ChatLinks.lua ignore it.
local LINK = "addon:rpsheetrefund"

---------------------------------------------------------------------------
-- First use after a long rest
---------------------------------------------------------------------------
function RPSheet:FreeUseLeft(name)
    return not self:State().freeUsed[name]
end

function RPSheet:TakeFreeUse(name)
    self:State().freeUsed[name] = true
end

---------------------------------------------------------------------------
-- Taking a cost back
---------------------------------------------------------------------------
-- Called after an ability was used and announced. Remembers what it paid that may be
-- taken back, and tells the player how.
function RPSheet:OfferRefund(ability, costs)
    local back, texts, why = {}, {}, nil
    for _, cost in ipairs(costs) do
        if (cost.refund or "") ~= "" then
            back[#back + 1] = { label = cost.tracker.label, amount = cost.amount }
            texts[#texts + 1] = ("%d %s"):format(cost.amount, cost.tracker.label)
            why = cost.refund
        end
    end
    -- A new use settles the one before it, whether or not it paid anything.
    self.refunds = self.refunds or {}
    self.refunds[ability.name] = #back > 0 and { costs = back, why = why, sheet = self.sheetKey } or nil
    if #back == 0 then return end
    self:Print(("%s: if %s, |H%s:%s|h|cff71d5ff[click here]|r|h or right-click the ability to take back %s."):format(
        ability.name, why, LINK, ability.name, table.concat(texts, ", ")))
end

-- Gives back what the last use of the ability paid. Returns false when there is
-- nothing to take back: it wasn't used, was taken back already, or a rest came between.
function RPSheet:TakeBack(name)
    local pending = self.refunds and self.refunds[name]
    if not pending then return false end
    self.refunds[name] = nil
    if pending.sheet ~= self.sheetKey then return false end -- another character's
    local texts = {}
    for _, cost in ipairs(pending.costs) do
        local tracker = self:FindTracker(cost.label)
        if tracker then
            tracker.set(tracker.get() + cost.amount) -- never above its maximum
            texts[#texts + 1] = ("%d %s"):format(cost.amount, tracker.label)
        end
    end
    if #texts == 0 then return false end
    self:Announce(("keeps %s: %s, so %s costs nothing."):format(table.concat(texts, ", "), pending.why, name))
    self:Refresh()
    return true
end

-- A rest gives resources back by itself; an older cost can't be taken back on top.
function RPSheet:ForgetRefunds()
    self.refunds = nil
end

local function OnClick(link)
    if type(link) ~= "string" or link:sub(1, #LINK + 1) ~= LINK .. ":" then return end
    local name = link:sub(#LINK + 2)
    if not RPSheet:TakeBack(name) then
        RPSheet:Print(("Nothing to take back for %s: that use is already settled."):format(name))
    end
end

hooksecurefunc("SetItemRef", function(link) pcall(OnClick, link) end)
