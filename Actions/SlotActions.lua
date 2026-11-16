-- Ability steps that change spell slots (step type "SLOTS", see Kit.Slots):
--   RECOVER     gives back spent slots with a combined level of up to half the level
--               in the feature's class, none above 5th (Arcane Recovery, Natural
--               Recovery)
--   TOPOINTS    turns a slot into Sorcery Points equal to its level (Font of Magic)
--   FROMPOINTS  makes a slot from Sorcery Points (Font of Magic)
--   MAKE        adds a slot of the step's `level`, paid for by the ability's other
--               steps (Nature Magician)
-- TOPOINTS and FROMPOINTS use the level set at the sheet's "Cast at" row, or the lowest.
-- ns.PlanSlotAction checks a step before anything is spent and returns
-- { text = what to announce, apply = function } or nil after telling the player why.
local _, ns = ...
local R = ns.Rules

local POINTS = "Sorcery Points"
local SLOT_COST = { 2, 3, 5, 6, 7 } -- Sorcery Points for a slot of levels 1 to 5
local HIGHEST = 5                   -- neither recovery nor Font of Magic reaches above 5th-level slots

ns.SLOT_ACTION_TEXT = {
    RECOVER = "Recover spent spell slots",
    TOPOINTS = "Turn a spell slot into Sorcery Points",
    FROMPOINTS = "Make a spell slot from Sorcery Points",
}

-- Slot trackers by spell level.
local function Slots(self)
    local slots = {}
    for _, tracker in ipairs(self:GetTrackers()) do
        -- Pact Magic slots kept beside the others are not part of this.
        if tracker.kind == "slot" and not tracker.pact then slots[tracker.level] = tracker end
    end
    return slots
end

-- The class a recovery feature belongs to: each goes by its own class's level, so a
-- character with both (Arcane Recovery and Natural Recovery) has two budgets.
local RECOVERS = { { "^Natural Recovery", "Druid" }, { "^Arcane Recovery", "Wizard" } }

local function Recover(self, ability)
    -- Half the level in the feature's own class, for a character with several. An
    -- ability made by hand (no known name) goes by the first class that recovers slots.
    local sheet = self:Sheet()
    local recovering
    for _, rule in ipairs(RECOVERS) do
        if ability and type(ability.name) == "string" and ability.name:find(rule[1]) then
            recovering = ns.BaseView(sheet, rule[2])
        end
    end
    recovering = recovering or ns.BaseView(sheet, "Wizard") or ns.BaseView(sheet, "Druid") or sheet
    local slots, budget, gains, texts = Slots(self), math.ceil(recovering.level / 2), {}, {}
    -- The highest spent slots that fit come back first.
    for level = HIGHEST, 1, -1 do
        local tracker = slots[level]
        local spent = tracker and (tracker.max - tracker.get()) or 0
        local count = math.min(spent, math.floor(budget / level))
        if count > 0 then
            budget = budget - count * level
            gains[#gains + 1] = { tracker = tracker, count = count }
            texts[#texts + 1] = ("%d %s"):format(count, tracker.label)
        end
    end
    if #gains == 0 then
        self:Print("No spent spell slot of 5th level or lower to recover.")
        return
    end
    return {
        text = "recovers " .. table.concat(texts, ", "),
        apply = function()
            for _, gain in ipairs(gains) do gain.tracker.set(gain.tracker.get() + gain.count) end
        end,
    }
end

local function ToPoints(self)
    local slots, points = Slots(self), self:FindTracker(POINTS)
    if not points then self:Print(("This sheet has no %s."):format(POINTS)) return end
    local tracker = self.castLevel and slots[self.castLevel]
    if not self.castLevel then
        for level = 1, 9 do
            if slots[level] and slots[level].get() > 0 then tracker = slots[level] break end
        end
    end
    if not tracker or tracker.get() <= 0 then
        self:Print(self.castLevel and ("No %s slot left to turn into %s."):format(R.SPELL_LEVELS[self.castLevel]:lower(), POINTS)
            or "No spell slot left.")
        return
    end
    if points.get() >= points.max then
        self:Print(("Your %s are full."):format(POINTS))
        return
    end
    return {
        text = ("turns a %s into %d %s"):format(tracker.label, tracker.level, POINTS),
        apply = function()
            tracker.set(tracker.get() - 1)
            points.set(points.get() + tracker.level)
            self.castLevel = nil
        end,
    }
end

local function FromPoints(self)
    local slots, points = Slots(self), self:FindTracker(POINTS)
    if not points then self:Print(("This sheet has no %s."):format(POINTS)) return end
    local level = self.castLevel or 1
    local tracker, cost = slots[level], SLOT_COST[level]
    if not tracker or not cost then
        self:Print(("A slot made from %s can be of 5th level at most, and of a level you have slots for."):format(POINTS))
        return
    end
    if points.get() < cost then
        self:Print(("A %s costs %d %s (%d left)."):format(tracker.label, cost, POINTS, points.get()))
        return
    end
    -- A made slot may go above the usual number; it lasts until a long rest.
    local above = tracker.get() >= tracker.usual
    return {
        text = ("makes a %s from %d %s%s"):format(tracker.label, cost, POINTS,
            above and (" (%d, above the usual %d until a long rest)"):format(tracker.get() + 1, tracker.usual) or ""),
        apply = function()
            points.set(points.get() - cost)
            -- Written straight to the state: the tracker's own limit is what is being passed.
            self:State().slots[level] = tracker.get() + 1
            self.castLevel = nil
        end,
    }
end

-- A slot of a set level; like one made from Sorcery Points it can go above the usual
-- number until a long rest.
local function Make(self, level)
    local tracker = Slots(self)[level or 0]
    if not tracker then
        self:Print(("You have no %s spell slots to add one to."):format(R.SPELL_LEVELS[level or 1] and R.SPELL_LEVELS[level]:lower() or "such"))
        return
    end
    return {
        text = ("makes a %s"):format(tracker.label),
        apply = function() self:State().slots[level] = tracker.get() + 1 end,
    }
end

-- `ability` is the ability the step belongs to: it tells whose feature recovers.
function ns.PlanSlotAction(self, action, ability)
    if action.mode == "MAKE" then return Make(self, action.level) end
    if action.mode == "RECOVER" then return Recover(self, ability) end
    if action.mode == "TOPOINTS" then return ToPoints(self) end
    if action.mode == "FROMPOINTS" then return FromPoints(self) end
    self:Print("This step doesn't know what to do with spell slots.")
end
