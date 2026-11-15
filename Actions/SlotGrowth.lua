-- What the slot a spell is cast with changes: the one place that works it out, for
-- the casting (Actions/Spells.lua) and for the spell's tooltip. The facts are in
-- Data/SlotGrowth.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local NONE = {}

-- The facts hold for the listed spell of that name. A spell the player made, or one
-- whose level or dice they changed, only has the dice they gave it.
local function Listed(spell)
    local known = R.SPELLS[spell.name]
    if known and known.level == spell.level and known.sides == spell.sides and known.count == spell.count then
        return known, R.SLOT_GROWTH[spell.name] or NONE
    end
    return spell, NONE
end

-- The entry of the highest slot level reached in { [slot level] = entry }.
local function Reached(steps, level)
    local best
    for from in pairs(steps or NONE) do
        if from <= level and (not best or from > best) then best = from end
    end
    return best and steps[best]
end

-- For a casting with a slot of `level` (the spell's own when there is no slot):
--   dice             dice added to the spell's own
--   flat             a number added to the roll
--   also             a second roll, { count, sides, kind, word }, or nil
--   noConcentration  true when this slot needs no concentration
--   notes            what else the slot changes, for the announcement
function RPSheet:SlotGrowth(spell, level)
    local known, facts = Listed(spell)
    level = math.max(level or spell.level, spell.level)
    local above = level - spell.level
    local growth = {
        dice = above * (known.up or 0) + (Reached(facts.upAt, level) or 0),
        flat = (facts.flat or 0) + above * (facts.flatUp or 0),
        noConcentration = facts.noConc ~= nil and level >= facts.noConc,
        notes = {},
    }
    local also = facts.also
    if also then
        growth.also = { count = also.count + above * (also.up or 0), sides = also.sides, kind = also.kind, word = also.word }
    end
    if above > 0 then
        for _, amount in ipairs(facts) do
            local steps = math.floor(above / (amount.every or 1))
            if steps > 0 then
                growth.notes[#growth.notes + 1] = amount.text:format((amount.base or spell.level) + steps * amount.per)
            end
        end
        local step = Reached(facts.at, level)
        if step then growth.notes[#growth.notes + 1] = step end
    end
    return growth
end

-- What this casting comes to at a slot level, e.g. "10d6, 4 attacks, targets: 3".
local function AtLevel(self, spell, level)
    local growth = self:SlotGrowth(spell, level)
    local parts = {}
    if spell.count > 0 then
        local dice = ("%dd%d"):format(spell.count + growth.dice, spell.sides)
        if growth.flat > 0 then dice = ("%s + %d"):format(dice, growth.flat) end
        parts[#parts + 1] = dice
    end
    if (spell.hitsUp or 0) > 0 then parts[#parts + 1] = ("%d attacks"):format(self:SpellHits(spell, { level = level })) end
    if growth.also then parts[#parts + 1] = ("%dd%d %s"):format(growth.also.count, growth.also.sides, growth.also.word) end
    for _, note in ipairs(growth.notes) do parts[#parts + 1] = note end
    return table.concat(parts, ", ")
end

-- The lines a spell's tooltip gets about higher slots; none for a cantrip.
function RPSheet:SlotGrowthHelp(spell)
    local lines = {}
    if spell.level <= 0 then return lines end
    local known, facts = Listed(spell)
    local own = R.ORDINALS[spell.level]
    local also = facts.also
    if also then lines[#lines + 1] = ("It also rolls %dd%d %s."):format(also.count, also.sides, also.word) end

    -- What the sheet rolls or adds by itself.
    local rolled = {}
    if spell.count > 0 and (known.up or 0) > 0 then rolled[#rolled + 1] = ("%dd%d"):format(known.up, spell.sides) end
    if spell.count > 0 and (facts.flatUp or 0) > 0 then rolled[#rolled + 1] = ("%d to the total"):format(facts.flatUp) end
    if (spell.hitsUp or 0) > 0 then rolled[#rolled + 1] = spell.hitsUp == 1 and "one more attack" or ("%d more attacks"):format(spell.hitsUp) end
    if also and (also.up or 0) > 0 then rolled[#rolled + 1] = ("%dd%d %s"):format(also.up, also.sides, also.word) end
    if #rolled > 0 then
        lines[#lines + 1] = ("Each slot level above %s adds %s."):format(own, table.concat(rolled, ", "))
    end

    -- What is only stated when the spell is cast.
    local stated = {}
    for _, amount in ipairs(facts) do
        local pace = amount.every == 2 and "two slot levels" or "slot level"
        local base = amount.base or spell.level
        if base > 0 then
            stated[#stated + 1] = ("%s (+%d per %s)"):format(amount.text:format(base), amount.per, pace)
        else
            stated[#stated + 1] = ("%s per %s"):format(amount.text:format(amount.per), pace)
        end
    end
    if #stated > 0 then
        lines[#lines + 1] = ("Grows with slots above %s, as the casting tells: %s."):format(own, table.concat(stated, "; "))
    end
    local levels = {}
    for from in pairs(facts.at or NONE) do levels[#levels + 1] = from end
    table.sort(levels)
    for _, from in ipairs(levels) do
        lines[#lines + 1] = ("%s-level slot%s: %s."):format(R.ORDINALS[from], from < 9 and " or higher" or "", facts.at[from])
    end

    -- The slot level set at "Cast at", when it is above the spell's own.
    local chosen = self.castLevel
    if chosen and chosen > spell.level and #lines > 0 then
        local text = AtLevel(self, spell, chosen)
        if text ~= "" then lines[#lines + 1] = ("Cast at %s level as set now: %s."):format(R.ORDINALS[chosen], text) end
    end
    return lines
end
