-- Spell components with a price (Data/SpellComponents.lua) against what the character
-- carries: whether a spell can be cast, what the casting uses up, and what the spell's
-- tooltip says about it. A setting under Customize, Spells switches the check off,
-- for a table where the DM rules otherwise. Parts that are a weapon or coins are
-- counted in Sheet/ComponentKinds.lua; the number of targets, for a spell that needs
-- its components once for each, is asked in Sheet/ComponentTargets.lua and arrives
-- here as pick.targets.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local RED, GREEN, GREY = "|cffff5555", "|cff80ff80", "|cff909090"

-- The parts a casting of this spell is checked for, or nil when there are none or the
-- check is off. Kept by spell name, so it holds for spells saved long ago too.
function RPSheet:SpellComponents(spell)
    -- A spell read from a scroll needs none (Actions/Scrolls.lua).
    if self:Sheet().componentsWaived or spell.fromScroll then return nil end
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

-- Why the spell can't be cast for want of a component, or nil when it can. `pick` is
-- the answer to "how many targets"; without one the spell is checked for one target.
function RPSheet:MissingComponents(spell, pick)
    local targets = type(pick) == "table" and pick.targets or nil
    local missing, advice = {}, {}
    for _, part in ipairs(self:SpellComponents(spell) or {}) do
        if self:ComponentCount(part) < ns.ComponentNeed(part, targets) then
            missing[#missing + 1] = ns.ComponentText(part, targets)
            if part.weapon then
                advice.weapon = "Ready such a weapon first; a weapon of your own needs its kind and worth set under Customize, Weapons. "
            elseif part.ammo then
                advice.ammo = "Arrows and bolts are under Weapons in the item browser. "
            elseif not part.coins then
                advice.item = "Add or buy it in the item browser (Reagents); one worth more will do. "
            end
        end
    end
    if #missing == 0 then return nil end
    return ("%s needs something you don't have%s: %s. %s%s%sA DM's ruling can switch this check off under Customize, Spells.")
        :format(spell.name, (targets or 1) > 1 and (" for %d targets"):format(targets) or "", table.concat(missing, "; "),
            advice.item or "", advice.ammo or "", advice.weapon or "")
end

-- Takes what the casting uses up out of the inventory and the purse. Returns the
-- names of what was taken.
-- `slotLevel` is the slot the spell was cast with: some parts take more with a
-- higher one (part.upQty more for each level above the spell's own, as far as the
-- character has them; the part's own number is what MissingComponents asks for).
function RPSheet:SpendComponents(spell, pick, slotLevel)
    local targets = type(pick) == "table" and pick.targets or nil
    local taken, dropped = {}, false
    for _, part in ipairs(self:SpellComponents(spell) or {}) do
        local need = part.consumed and ns.ComponentNeed(part, targets) or 0
        if part.coins and need > 0 then
            if self:SpendCoins(part.coins * need, spell.name) then taken[#taken + 1] = ns.CoinText(part.coins * need) end
        elseif part.ammo then
            if need > 0 and part.upQty and slotLevel and slotLevel > (spell.level or 0) then
                local more = part.upQty * (slotLevel - spell.level)
                need = need + math.min(more, math.max(0, self:AmmoCount(part) - need))
            end
            local pieces = need > 0 and self:TakeAmmo(part, need) or 0
            if pieces > 0 then
                taken[#taken + 1] = ("%d %s"):format(pieces, part.words)
                dropped = true
            end
        elseif not part.weapon then
            for _ = 1, need do
                local item = self:CarriedComponent(part)
                if item then
                    taken[#taken + 1] = item.name
                    dropped = true
                    self:DropItem(item)
                end
            end
        end
    end
    if dropped then
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
    local waived, each = self:Sheet().componentsWaived, false
    for _, part in ipairs(parts) do
        local count, have = self:ComponentCount(part), ""
        local enough = count >= ns.ComponentNeed(part)
        if waived then
            have = ""
        elseif part.weapon then
            local weapon = self:ComponentWeapon(part)
            have = weapon and (" %sYour %s will do.|r"):format(GREEN, weapon) or (" %sYou have none ready.|r"):format(RED)
        elseif part.coins then
            have = enough and (" %sYou have it.|r"):format(GREEN) or (" %sYou can't pay it.|r"):format(RED)
        else
            have = (" %sYou carry %s.|r"):format(enough and GREEN or RED, count == 0 and "none" or tostring(count))
        end
        lines[#lines + 1] = ("Needs %s%s.%s"):format(ns.ComponentText(part), part.consumed and ", used up by the casting" or ", which is kept", have)
        if part.note and not waived then lines[#lines + 1] = GREY .. part.note .. "|r" end
        each = each or part.each ~= nil
    end
    if each and not waived then
        lines[#lines + 1] = GREY .. "Casting it asks how many, and checks for that many.|r"
    end
    if waived then lines[#lines + 1] = GREY .. "Components are not checked (Customize, Spells).|r" end
    return lines
end
