-- Reading a spell scroll (an item named "Spell Scroll: <spell>", Sheet/Scribing.lua).
-- A spell the lists know, read by a spellcaster, goes through the usual casting
-- (Actions/Spells.lua) as a copy that needs no slot and no components, so it rolls
-- its attack and dice with the reader's own numbers, as a scroll you wrote does.
-- Anything else is only announced, with the numbers a found scroll carries.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Reads the scroll. True when it was read and should crumble; false when something
-- stopped the casting and the scroll is kept.
function RPSheet:ReadScroll(item)
    local name, level = ns.ScrollSpell(item)
    if not name then return false end
    if self.busy or self:IsRolling() then return false end
    local known = self:PreparedSpell(name) or R.SPELLS[name]
    if known and self:CastStat(known) then
        local blocked = self:FormBlocksSpell(known)
        if blocked then
            self:Print(blocked)
            return false
        end
        -- The copy is no listed spell: no slot (level 0), no components, base strength.
        -- A scroll's cantrip does grow with the reader's level, like any cantrip.
        local cast = CopyTable(known)
        cast.name, cast.level = ("%s (scroll)"):format(name), 0
        cast.damage = ns.SpellDamageType(known) or ""
        cast.material, cast.consumed, cast.auto = 0, false, ""
        -- Shift is held to read it, so only the Next roll row sets advantage here.
        self:CastSpell(cast, self.rollMode)
        return true
    end
    local numbers = R.SCROLL_FOUND[math.max(0, math.min(9, level))]
    local text = known and known.desc or ""
    self:Announce(("reads %s (save DC %d, spell attack +%d)%s"):format(ns.Mark(item.name), numbers[1], numbers[2],
        text ~= "" and (": " .. text) or "."))
    return true
end
