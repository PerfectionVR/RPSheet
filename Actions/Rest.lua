-- Resting: long rests, short rests, and spending hit dice to heal.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local RollText = ns.RollText

local function HasPassive(sheet, name)
    for _, passive in ipairs(sheet.passives) do
        if passive.name == name and passive.enabled then return true end
    end
    return false
end

-- A beast form lasts half the character's level in hours (rounded down), so a rest of
-- `hours` outlasts it below twice that level, plus one level for a form that would run
-- out exactly as the rest ends.
local function EndFormAfter(self, hours)
    local form = self:Form()
    -- A beast form lasts half the level in the class that shapeshifts.
    local shifter = ns.BaseView(self:Sheet(), "Druid") or self:Sheet()
    if form and form.beast and math.floor((shifter.level or 1) / 2) <= hours then
        self:LeaveForms("the form ran out during the rest")
    end
end

-- What a class feature switched on for ten minutes or less (Data/Lasting.lua) is over
-- once the rest is.
local function EndLasting(self)
    local ended, seen = {}, {}
    for _, passive in ipairs(self:Sheet().passives) do
        local lasting = passive.enabled and (passive.auto or "") ~= "" and R.LASTING[passive.name]
        if lasting then
            passive.enabled = false
            if not seen[lasting.label] then seen[lasting.label], ended[#ended + 1] = true, lasting.label end
        end
    end
    if #ended > 0 then self:Print(("Over during the rest: %s."):format(table.concat(ended, ", "))) end
    return #ended > 0
end

-- Everything back to full: HP, hit dice, resources and spell slots.
function RPSheet:LongRest()
    local state = self:State()
    EndFormAfter(self, 8)
    self:EndBenefits() -- no spell benefit outlasts a rest
    EndLasting(self)   -- nor a feature that lasts minutes
    self:EndWards(8)         -- nor a protective spell of 8 hours or less,
    self:EndWards(nil, true) -- nor one that hangs on concentration
    self:ClampState(true) -- also makes first-use-free abilities free again
    state.tempHP = 0
    state.exhaustion = math.max(0, (state.exhaustion or 0) - 1)
    state.conditions.Concentrating = nil
    state.petMasteryChanged = nil -- Weapon Mastery picks can be changed again
    state.prepareClosed = nil     -- and so can the prepared spells
    state.prepareSwap = nil       -- with the one exchange of a class that changes one per rest
    state.cantripSwap = nil       -- and a Mage's exchange of one cantrip (Sheet/CantripSwap.lua)
    ns.ResetRestPicks()           -- and the feat picks that change after a long rest
    state.lineageCantripChanged = nil -- and an elf's lineage cantrip (Options/Origin.lua)
    self:ClearGrowingSpells()
    self:ClearDeathSaves()
    -- Humans wake up inspired (Resourceful).
    if HasPassive(self:Sheet(), "Resourceful") then state.inspiration = true end
    self:Announce("finishes a long rest.")
    self:QueueBroadcast() -- the group sees the new hit points, also while the sheet is closed
    self:PopulateSoon()
end

-- Gives back what recharges on a short rest. HP only comes back by spending hit dice.
function RPSheet:ShortRest()
    EndFormAfter(self, 1)
    self:ForgetRefunds()
    if EndLasting(self) then self:PopulateSoon() end
    if self:EndBenefits() then
        self:ClampState()
        self:PopulateSoon()
    end
    -- A protective spell of an hour or less has run out.
    if #self:EndWards(1) > 0 then self:PopulateSoon() end
    local regained = {}
    for _, tracker in ipairs(self:GetTrackers()) do
        if tracker.short then
            local before = tracker.get()
            tracker.set(tracker.short == "ALL" and tracker.max or (before + tracker.short))
            if tracker.get() > before then regained[#regained + 1] = tracker.label end
        end
    end
    -- Signature Spells: the casting without a slot is back.
    local spells = self:RestoreChosenCastings(true)
    for _, name in ipairs(spells) do regained[#regained + 1] = name .. " without a slot" end
    if #spells > 0 then self:PopulateSoon() end
    local text = "finishes a short rest"
    if #regained > 0 then text = text .. " (regains " .. table.concat(regained, ", ") .. ")" end
    self:Announce(text .. ".")
    self:QueueBroadcast()
    self:Refresh()
end

-- Rolls one hit die and heals by the result plus the Constitution modifier (at least 1).
-- `pool` is the Hit Dice bar that was clicked: a character whose classes have dice of
-- different sizes has one per size. Without it the first one is used.
function RPSheet:SpendHitDie(pool)
    local state = self:State()
    for _, tracker in ipairs(self:GetTrackers()) do
        if not pool and tracker.kind == "hitdice" then pool = tracker end
    end
    if not pool or (pool.get() or 0) <= 0 then
        self:Print("No hit dice left. A long rest restores them.")
        return
    end
    local sides = pool.sides
    local mod = self:Mod("CON")
    -- Species traits: a hit die that always heals its maximum, or a little extra per die.
    local extra = self:TraitValue("hitDie")
    if type(extra) == "number" then mod = mod + extra end
    local maximum = self:TraitValue("hitDieMax") == true
    self:RollDice(1, sides, function(rolls)
        if maximum then rolls[1] = sides end
        local healed = math.max(1, rolls[1] + mod)
        pool.set(pool.get() - 1)
        state.hp = math.min(self:MaxHP(), (state.hp or 0) + healed)
        self:ClearDeathSaves()
        self:Announce(("spends a hit die - %s (now %d/%d HP)"):format(
            RollText.Dice("healing", rolls, sides, mod), state.hp, self:MaxHP()))
        self:QueueBroadcast()
        self:PopulateSoon()
    end)
end
