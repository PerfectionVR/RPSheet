-- The prepared spells a character picked in the level dialog (lists in
-- Data/PreparedPicks.lua): sheet.picks["prepared<Class>"][<name>] = true. Each is put
-- on the spell list marked auto = "spell:<name>" and counts as a prepared spell.
-- Spells that are always prepared (from a subclass or a feature, or chosen for one)
-- are not part of this: they don't count and can't be picked a second time.
local _, ns = ...
local R = ns.Rules

local PREFIX = "spell:"

-- { [name] = true } for the spells the character has without preparing them: the
-- always-prepared ones of its class and subclass, and every spell on the spell list
-- marked as not counting. `sheet` may be the level dialog's stand-in, so the subclass
-- and level being chosen there count already.
-- The dialog asks once per spell each time it is drawn, so the answer is kept for as
-- long as the same moment lasts.
local kept = {}
local function Taken(sheet, fresh)
    local now = GetTime()
    if not fresh and kept.names and kept.time == now and kept.spells == sheet.spells and kept.class == sheet.class
        and kept.subclass == sheet.subclass and kept.spec == sheet.spec and kept.level == sheet.level then
        return kept.names
    end
    local names = ns.AlwaysPrepared(sheet)
    for _, spell in ipairs(sheet.spells) do
        -- Always-prepared entries are covered above; one of another subclass is on its way out.
        if spell.free and not (spell.auto or ""):find("^prepared:") then names[spell.name] = true end
    end
    kept = { names = names, time = now, spells = sheet.spells, class = sheet.class, subclass = sheet.subclass, spec = sheet.spec, level = sheet.level }
    return names
end

-- A list is shared by the classes of one Player's Handbook class, and not all of them
-- have every spell on it (Data/SpellLists.lua). A spell the character picked before
-- that was held to stays its own.
for _, key in pairs(R.PREPARED_LISTS) do
    R.PICK_LISTS[key].blocked = function(sheet, name)
        if Taken(sheet)[name] then return "always prepared" end
        local picks = type(sheet.picks) == "table" and sheet.picks[key]
        if not R.OnClassSpellList(sheet.class, name) and not (type(picks) == "table" and picks[name]) then
            return ("not a %s spell"):format(R.CLASSES[sheet.class] and R.CLASSES[sheet.class].name or "class")
        end
    end
end

-- Sheet upkeep (see Sheet/ClassFeatures.lua). Runs before the always-prepared spells
-- are put on the sheet, so a pick that became one of them makes way for it.
-- `sheet` is a character of one class, or a view of one class of a character with
-- several: that one's spells name their class, and what its other classes prepared
-- is left alone.
local function ApplyFor(sheet)
    local foreign, tag = ns.ForeignPicks(sheet, R.PREPARED_LISTS), ns.SpellTag(sheet)
    local class = R.CLASSES[sheet.class]
    local key = class and R.PREPARED_LISTS[class.base]
    local limit = key and ns.PickLimit(key, sheet.class, sheet.level) or 0
    local items = key and R.PICK_LISTS[key].items or {}
    local picks = {}
    if limit > 0 then
        if type(sheet.picks[key]) ~= "table" then sheet.picks[key] = {} end
        picks = sheet.picks[key]
    end
    local taken = limit > 0 and Taken(sheet, true) or {}

    -- A spell the player deleted from the spell list is no longer picked, and neither
    -- is one that is always prepared now: the level dialog asks for another.
    local stays = ns.OwnEntries(sheet, PREFIX, tag)
    for name in pairs(picks) do
        if (sheet.dismissed[PREFIX .. name] and not stays[name]) or taken[name] then
            picks[name] = nil
            sheet.dismissed[PREFIX .. name] = nil
        end
    end
    local count = 0
    for name in pairs(picks) do
        if items[name] then count = count + 1 end
    end

    -- Added by hand before prepared spells were picked: it counts as a pick while
    -- there is room for one, the first on the list first. The rest stay as they are.
    local have = {}
    for _, spell in ipairs(sheet.spells) do
        local item, known = items[spell.name], R.SPELLS[spell.name]
        if (spell.auto or "") == "" and not spell.free and item and known.level == spell.level and not taken[spell.name]
            and ns.SpellIsOf(spell, tag) and (picks[spell.name] or R.OnClassSpellList(sheet.class, spell.name)) then
            if not picks[spell.name] and count < limit and sheet.level >= item.level then
                picks[spell.name] = true
                count = count + 1
            end
            if picks[spell.name] and not have[spell.name] then
                spell.auto = PREFIX .. spell.name
                if tag then spell.class = tag end
            end
            have[spell.name] = true
        end
    end

    -- Put there by an earlier pick: it stays only while it is still picked. An entry
    -- that names another class is that class's: two classes that prepare the same
    -- spell each have their own, cast with their own ability.
    local seen = {}
    for index = #sheet.spells, 1, -1 do
        local spell = sheet.spells[index]
        if (spell.auto or ""):find("^" .. PREFIX) and ns.SpellIsOf(spell, tag) then
            if picks[spell.name] and items[spell.name] and not seen[spell.name] then
                seen[spell.name], have[spell.name] = true, true
                if tag then spell.class = tag end
            elseif spell.class == tag or not foreign[spell.name] then
                -- (one without a class that another class picked is left for that class)
                table.remove(sheet.spells, index)
            end
        end
    end

    local names = {}
    for name in pairs(picks) do
        if items[name] and not have[name] then names[#names + 1] = name end
    end
    table.sort(names, R.SpellBefore)
    for _, name in ipairs(names) do
        local spell = CopyTable(R.SPELLS[name])
        spell.auto = PREFIX .. name
        spell.class = tag
        sheet.spells[#sheet.spells + 1] = spell
    end
    kept = {} -- the spell list changed
end

function ns.ApplyPreparedPicks(sheet)
    ns.ForEachClass(sheet, ApplyFor)
end
