-- Spell slots by class. A character of one class reads its class's own table. With
-- several classes the ones that prepare spells share one set of slots: full casters
-- count every level, half casters half of theirs (rounded up), and the total is looked
-- up in the full caster's table. A Warlock's Pact Magic slots stay a set of their own
-- beside them; either set can pay for any of the character's spells.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Spell slots of one class at one of its levels, as { [spell level] = number }.
function ns.ClassSlots(class, level)
    local slots = {}
    if not class or not class.caster then return slots end
    if class.caster == "FULL" then
        for spellLevel, count in ipairs(R.FULL_SLOTS[level]) do slots[spellLevel] = count end
    elseif class.caster == "HALF" then
        for spellLevel, count in ipairs(R.FULL_SLOTS[math.ceil(level / 2)]) do slots[spellLevel] = count end
    elseif class.caster == "PACT" then
        local pact = R.PACT_SLOTS[level]
        slots[pact[2]] = pact[1]
    end
    return slots
end

-- The highest spell level a class can prepare at one of its levels: what it would have
-- slots for by itself, whatever the character's other classes add.
function ns.ClassSpellLevel(class, level)
    local highest = 0
    for spellLevel in pairs(ns.ClassSlots(class, level)) do highest = math.max(highest, spellLevel) end
    return highest
end

-- The character's spell slots. Returns:
--   slots     { [spell level] = number }
--   pact      a Warlock's slots when they are kept beside the others, else nil
--   allPact   true when `slots` are Pact Magic slots (they come back on a short rest)
function ns.SheetSlots(sheet)
    local views = ns.ClassViews(sheet)
    if #views == 1 then
        local class = R.CLASSES[views[1].class]
        return ns.ClassSlots(class, views[1].level), nil, class ~= nil and class.caster == "PACT"
    end
    local shared, pact = 0, nil
    for _, view in ipairs(views) do
        local class = R.CLASSES[view.class]
        if class and class.caster == "FULL" then
            shared = shared + view.level
        elseif class and class.caster == "HALF" then
            shared = shared + math.ceil(view.level / 2)
        elseif class and class.caster == "PACT" then
            pact = ns.ClassSlots(class, view.level)
        end
    end
    if shared == 0 then return pact or {}, nil, pact ~= nil end
    local slots = {}
    for spellLevel, count in ipairs(R.FULL_SLOTS[math.min(R.MAX_LEVEL, shared)]) do slots[spellLevel] = count end
    return slots, pact, false
end

-- Pact Magic slots kept beside the shared ones; empty for everyone else.
function RPSheet:PactSlots()
    local _, pact = ns.SheetSlots(self:Sheet())
    return pact or {}
end
