-- Spell components with a price (Data/SpellComponents.lua) against what the character
-- carries: whether a spell can be cast, what the casting uses up, and what the spell's
-- tooltip says about it. A setting under Customize, Spells switches the check off,
-- for a table where the DM rules otherwise.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local RED, GREEN, GREY = "|cffff5555", "|cff80ff80", "|cff909090"

-- The parts a casting of this spell is checked for, or nil when there are none or the
-- check is off. Kept by spell name, so it holds for spells saved long ago too.
function RPSheet:SpellComponents(spell)
    if self:Sheet().componentsWaived then return nil end
    return R.SPELL_COMPONENTS[spell.name]
end

-- The carried entry that serves as this part, and how many such things are carried.
-- The listed item itself comes first, then the cheapest thing that is worth enough.
function RPSheet:CarriedComponent(part)
    local best, bestWorth, count = nil, nil, 0
    for _, item in ipairs(self:Sheet().items or {}) do
        if item.name ~= "" and (item.qty or 0) > 0 then
            local base, worth = R.ComponentWorth(item.name)
            worth = worth or item.cost or 0
            local exact = item.name == part.item
            if exact or (part.accept[base] and worth >= part.cost) then
                count = count + item.qty
                if exact then
                    best, bestWorth = item, -1
                elseif not bestWorth or worth < bestWorth then
                    best, bestWorth = item, worth
                end
            end
        end
    end
    return best, count
end

-- "4 x Ivory strip (50 gp)", "Black onyx (150 gp) for each corpse"
local function PartText(part)
    local text = part.qty > 1 and ("%d x %s"):format(part.qty, part.item) or part.item
    if part.each then text = ("%s for each %s"):format(text, part.each) end
    return text
end

-- Why the spell can't be cast for want of a component, or nil when it can.
function RPSheet:MissingComponents(spell)
    local missing = {}
    for _, part in ipairs(self:SpellComponents(spell) or {}) do
        local _, count = self:CarriedComponent(part)
        if count < part.qty then missing[#missing + 1] = PartText(part) end
    end
    if #missing == 0 then return nil end
    return ("%s needs a component you don't carry: %s. Add or buy it in the item browser (Reagents); one worth more will do. A DM's ruling can switch this check off under Customize, Spells.")
        :format(spell.name, table.concat(missing, "; "))
end

-- Takes what the casting uses up out of the inventory. Returns the names taken.
function RPSheet:SpendComponents(spell)
    local taken = {}
    for _, part in ipairs(self:SpellComponents(spell) or {}) do
        if part.consumed then
            for _ = 1, part.qty do
                local item = self:CarriedComponent(part)
                if item then
                    taken[#taken + 1] = item.name
                    self:DropItem(item)
                end
            end
        end
    end
    if #taken > 0 then
        ns.RebuildOptions() -- an item's page under Customize may be gone
        self:PopulateSoon() -- the tooltips and the item list say how many are left
    end
    return taken
end

-- The lines a spell's tooltip gets about its components; none when it has no priced one.
function RPSheet:ComponentHelp(spell)
    local lines = {}
    local parts = R.SPELL_COMPONENTS[spell.name]
    if not parts then return lines end
    local waived = self:Sheet().componentsWaived
    for _, part in ipairs(parts) do
        local _, count = self:CarriedComponent(part)
        local have
        if waived then
            have = ""
        elseif count >= part.qty then
            have = (" %sYou carry %d.|r"):format(GREEN, count)
        else
            have = (" %sYou carry %s.|r"):format(RED, count == 0 and "none" or tostring(count))
        end
        lines[#lines + 1] = ("Needs %s%s.%s"):format(PartText(part), part.consumed and ", used up by the casting" or ", which is kept", have)
        if part.each and not waived then
            lines[#lines + 1] = GREY .. "The sheet checks for one" .. (part.consumed and " and takes one" or "") .. "; see to the rest yourself.|r"
        end
    end
    if waived then lines[#lines + 1] = GREY .. "Components are not checked (Customize, Spells).|r" end
    return lines
end
