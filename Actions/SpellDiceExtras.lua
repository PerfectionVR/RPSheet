-- What a casting's dice depend on besides the slot (data: Data/SpellVariants.lua): the
-- target or option asked for first, dice that add more at their highest, and dice of
-- two damage types or several darts told apart. Used by RPSheet:CastSpell
-- (Actions/Spells.lua), whose start is wrapped here for the question.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- A spell the player changed under Customize keeps to what they made of it.
local function Listed(spell, list)
    return not spell.edited and list[spell.name]
end

-- The number and size of dice the casting rolls, for the option picked.
function RPSheet:SpellVariantDice(spell, count)
    local variant = spell.variant
    if not variant then return count, spell.sides end
    if variant.count then return variant.count, variant.sides end
    return count + (variant.more or 0), variant.sides or spell.sides
end

-- Asks for the option first; the casting goes on with a copy of the spell that
-- carries it. Every later step of the casting has it already.
local CastSpell = RPSheet.CastSpell
function RPSheet:CastSpell(spell, mode, ritual, benefit, answers)
    local variants = Listed(spell, R.SPELL_VARIANTS)
    if not variants or spell.variant or benefit ~= nil or answers ~= nil or ritual
        or not (MenuUtil and MenuUtil.CreateContextMenu) then
        return CastSpell(self, spell, mode, ritual, benefit, answers)
    end
    if self.busy or self:IsRolling() then return end
    MenuUtil.CreateContextMenu(UIParent, function(_, root)
        root:CreateTitle(variants.title)
        for _, option in ipairs(variants) do
            root:CreateButton(option.label, function()
                local copy = CopyTable(spell)
                copy.variant = option
                if option.kind then copy.kind = option.kind end
                if option.dice then copy.dice = option.dice end
                CastSpell(self, copy, mode, ritual)
            end)
        end
    end)
end

-- Rolls one more die for each die at its highest, up to the spellcasting modifier in
-- all, then calls done(rolls, words or nil).
function RPSheet:ExplodeSpellDice(spell, rolls, sides, done)
    if not Listed(spell, R.EXPLODING_SPELLS) then return done(rolls) end
    local most = math.max(0, self:Mod(self:CastStat(spell)))
    local due, added = 0, 0
    for _, value in ipairs(rolls) do if value == sides then due = due + 1 end end
    local function Next()
        if due <= 0 or added >= most then
            return done(rolls, added > 0 and ("%d more for dice at %d"):format(added, sides) or nil)
        end
        due, added = due - 1, added + 1
        self:Roll(sides, function(value)
            rolls[#rolls + 1] = value
            if value == sides then due = due + 1 end
            Next()
        end)
    end
    Next()
end

-- "fire 9, necrotic 7" or "darts 3, 5, 2": the dice told apart, or nil.
function RPSheet:SpellDiceSplit(spell, rolls, critical)
    local split = Listed(spell, R.SPELL_DICE_SPLIT)
    if not split or #rolls == 0 then return end
    if split.darts then
        local darts = {}
        for index, value in ipairs(rolls) do darts[index] = value + split.darts end
        return "darts " .. table.concat(darts, ", ")
    end
    local first = split.half and math.floor(#rolls / 2) or math.min(#rolls, split.first * (critical and 2 or 1))
    local a, b = 0, 0
    for index, value in ipairs(rolls) do
        if index <= first then a = a + value else b = b + value end
    end
    return ("%s %d, %s %d"):format(split.names[1], a, split.names[2], b)
end
