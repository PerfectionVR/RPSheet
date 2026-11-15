-- Reading a spell scroll (an item named "Spell Scroll: <spell>", Sheet/Scribing.lua).
--   The spell has to be on the reader's spell list (Sheet/ScrollReading.lua);
--   otherwise the scroll can't be read, and is kept.
--   A spell of a higher level than the reader casts takes an ability check with the
--   spellcasting ability against 10 + the spell's level. On a failure the writing
--   fades and the scroll is lost without effect.
--   A scroll the character wrote (item.scribed) casts with its own spell save DC and
--   spell attack bonus; any other casts with the fixed numbers of its level.
-- The casting goes through the usual one (Actions/Spells.lua) as a copy of the spell
-- that needs no slot and no components. A spell the lists don't know can't be judged
-- or rolled: it is only announced.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- A copy cast from a found scroll carries the scroll's numbers (cast.scroll), and
-- the casting asks here for its DC and attack bonus like for any spell.
local SpellDC, SpellAttack = RPSheet.SpellDC, RPSheet.SpellAttack
function RPSheet:SpellDC(spell)
    if spell and spell.scroll then return spell.scroll[1] end
    return SpellDC(self, spell)
end
function RPSheet:SpellAttack(spell)
    if spell and spell.scroll then return spell.scroll[2] end
    return SpellAttack(self, spell)
end

-- Takes the scroll that was read off the list, after a roll decided what became of it.
local function Crumble(self, item)
    self:DropItem(item)
    ns.RebuildOptions() -- its page under Customize may be gone
    self:ClampState()
    self:PopulateSoon()
end

-- Reads the scroll. True when it was read and should crumble; false when something
-- stopped the reading and the scroll is kept, or when a check is being rolled, which
-- takes the scroll itself once the die has fallen.
function RPSheet:ReadScroll(item)
    local name, level = ns.ScrollSpell(item)
    if not name then return false end
    if self.busy or self:IsRolling() then return false end
    local found = not item.scribed and R.SCROLL_FOUND[math.max(0, math.min(9, level))] or nil
    local listed = R.SPELLS[name]
    if not listed then
        self:Announce(("reads %s%s."):format(ns.Mark(item.name),
            found and (" (save DC %d, spell attack +%d)"):format(found[1], found[2]) or ""))
        return true
    end
    local key, reach = ns.ScrollReader(self:Sheet(), name)
    if not key then
        self:Print(("%s is not on your spell list, so you can't make sense of the scroll. It is kept."):format(name))
        return false
    end
    local known = self:PreparedSpell(name) or listed
    local blocked = self:FormBlocksSpell(known)
    if blocked then
        self:Print(blocked)
        return false
    end
    -- The copy is no listed spell: no slot (level 0), no components, base strength.
    -- A scroll's cantrip does grow with the reader's level, like any cantrip.
    local cast = CopyTable(known)
    cast.name, cast.level, cast.class = ("%s (scroll)"):format(name), 0, key
    cast.damage = ns.SpellDamageType(known) or ""
    cast.material, cast.consumed, cast.auto = 0, false, ""
    cast.scroll = found
    -- Shift is held to read it, so only the Next roll row sets advantage here.
    if listed.level <= reach then
        self:CastSpell(cast, self.rollMode)
        return true
    end

    -- Beyond the reader's own casting: an ability check first.
    local stat = self:CastStat(cast)
    local dc, label = 10 + listed.level, stat .. " check"
    local mod = self:CheckMod(stat)
    self:RollD20(self:ResolveMode(label, self.rollMode), function(d20, note)
        local passed = d20 + mod >= dc
        self:Announce(("tries to read %s, a spell beyond their own: %s against DC %d - %s"):format(ns.Mark(item.name),
            ns.RollText.Check(ns.Mark(label), d20, mod, note), dc,
            passed and "the spell holds." or "the writing fades and the scroll is lost."))
        Crumble(self, item)
        if passed then self:CastSpell(cast, self.rollMode) end
    end)
    return false
end

-- What a scroll's tooltip or page can say about reading it, for this character.
function RPSheet:ScrollHelp(item)
    local name, level = ns.ScrollSpell(item)
    if not name then return nil end
    local numbers = R.SCROLL_FOUND[math.max(0, math.min(9, level))]
    local lines = { item.scribed and "Written by you: it casts with your own spell save DC and spell attack bonus."
        or ("Not written by you: it casts with save DC %d and spell attack +%d."):format(numbers[1], numbers[2]) }
    if not R.SPELLS[name] then return lines end
    local key, reach = ns.ScrollReader(self:Sheet(), name)
    if not key then
        lines[#lines + 1] = "|cffff5555The spell is not on your spell list: you can't read it.|r"
    elseif R.SPELLS[name].level > reach then
        lines[#lines + 1] = ("The spell is beyond your own casting: reading it takes a %s check against DC %d, and a failure loses the scroll."):format(
            R.STAT_NAMES[R.CLASSES[key].cast] or "spellcasting ability", 10 + R.SPELLS[name].level)
    end
    return lines
end
