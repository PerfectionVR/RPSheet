-- Scribing spell scrolls (rules in Data/Scrolls.lua): who may, of which spells, what
-- it costs, and the scribing itself. A scroll is an inventory item named after its
-- spell; reading it is in Actions/Scrolls.lua.
--   Who: a character proficient in Arcana, or one who practises inscription. With
--   Arcana alone any spell it has will do; a scribe's tools alone reach as far as
--   the profession's skill (a common scroll for an apprentice, and so on).
--   Which: the spells on its spell list, and those in its spellbook.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local INSCRIPTION = R.PROFESSIONS.inscription

-- The spell a scroll item holds and that spell's level, or nil for any other item.
-- The level is the listed spell's; 1 for a spell the lists don't know.
function ns.ScrollSpell(item)
    local name = type(item) == "table" and item.name or item
    local spell = type(name) == "string" and name:sub(1, #R.SCROLL_PREFIX) == R.SCROLL_PREFIX and name:sub(#R.SCROLL_PREFIX + 1)
    if not spell or spell == "" then return nil end
    return spell, R.SPELLS[spell] and R.SPELLS[spell].level or 1
end

-- Materials in copper and days of work for a scroll of a spell of that level.
function ns.ScribeCost(level)
    local row = R.SCROLL_COSTS[math.max(0, math.min(9, level or 0))]
    return row.cost, row.days
end

-- How the character may scribe: { arcana, scribe } (either can be false), or nil and
-- what it lacks. `scribe` is true when it practises inscription.
function RPSheet:ScribeWays()
    local arcana = (self:Sheet().skills[R.SCRIBE_SKILL] or 0) >= 1
    local scribe = self:CanPractise(INSCRIPTION)
    if arcana or scribe then return { arcana = arcana, scribe = scribe } end
    return nil, ("proficiency in %s or with %s"):format(R.SCRIBE_SKILL, table.concat(INSCRIPTION.tools, " or "))
end

-- The spells the character could put on a scroll, lowest level first: those on its
-- spell list and those in its spellbook, as spell entries.
function RPSheet:ScribeSpells()
    local sheet, seen, list = self:Sheet(), {}, {}
    for _, spell in ipairs(sheet.spells or {}) do
        if spell.name ~= "" and not seen[spell.name] then
            seen[spell.name] = true
            list[#list + 1] = spell
        end
    end
    for _, name in ipairs(ns.HasSpellbook(sheet) and ns.SpellbookNames(sheet) or {}) do
        if not seen[name] then
            seen[name] = true
            list[#list + 1] = R.SPELLS[name]
        end
    end
    table.sort(list, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)
    return list
end

-- Days the character needs: a faction that favors its inscription halves them.
function RPSheet:ScribeDays(spell)
    local _, days = ns.ScribeCost(spell.level)
    local ways = self:ScribeWays()
    return ways and ways.scribe and self:ProfessionHaste(INSCRIPTION) and days / 2 or days
end

-- What the character can pay a scroll with: its coins, and the herbs it gathered
-- when it practises inscription (unless `coinsOnly`).
local function Funds(self, ways, coinsOnly)
    return self:Coins() + ((ways.scribe and not coinsOnly) and self:MaterialsFor(INSCRIPTION) or 0)
end

-- True when the character may scribe the spell now. Otherwise false and why not.
function RPSheet:CanScribe(spell, coinsOnly)
    local ways, lacks = self:ScribeWays()
    if not ways then return false, "you need " .. lacks end
    if not ways.arcana then
        -- A scribe's tools alone: they have to be at hand, and the skill sets the rarity.
        local missing = self:MissingTool(INSCRIPTION)
        if missing then return false, missing end
        local level = R.RARITY_LEVEL[R.SCROLL_RARITY[spell.level] or "Legendary"]
        if self:ProfessionLevel() < level then
            return false, ("without %s it takes %s skill (proficiency bonus +%d)"):format(R.SCRIBE_SKILL, R.PROFESSION_LEVELS[level].name:lower(), level)
        end
    end
    if self:MissingComponents(spell) then return false, "you don't carry a component the spell needs" end
    if Funds(self, ways, coinsOnly) < ns.ScribeCost(spell.level) then return false, "you can't pay for the inks and parchment" end
    return true
end

-- Scribes one scroll: pays, uses up what the spell consumes, and adds the scroll.
-- True when it was made.
function RPSheet:Scribe(spell, coinsOnly)
    local can, why = self:CanScribe(spell, coinsOnly)
    if not can then
        self:Print(("You can't scribe %s: %s."):format(spell.name, why))
        return false
    end
    local ways = self:ScribeWays()
    local cost, name = ns.ScribeCost(spell.level), R.SCROLL_PREFIX .. spell.name
    local reason = "scribing " .. spell.name
    local paid
    if ways.scribe and not coinsOnly then
        paid = self:PayWithMaterials(INSCRIPTION, cost, reason)
    else
        paid = self:SpendCoins(cost, reason)
    end
    if not paid then return false end
    self:SpendComponents(spell)

    -- Scrolls of one spell stack, though they are magic items.
    local item = self:CarriedItem(name)
    if item then
        item.qty = item.qty + 1
    else
        item = self:AddItem(name, 1)
        item.magic, item.rarity = true, R.SCROLL_RARITY[spell.level] or ""
        local kind = spell.level == 0 and "cantrip" or ((R.SPELL_LEVELS[spell.level] or "high level"):lower() .. " spell")
        item.desc = ("A scroll of a %s, written by you: it casts with your own spell save DC and spell attack bonus, needs no components, and crumbles when read. Shift-click it to read it.\n%s"):format(
            kind, spell.desc or "")
    end
    local days = self:ScribeDays(spell)
    self:Announce(("scribes %s (%s of work)."):format(ns.Mark(name), ns.DaysText(days)))
    self:Print(("%s of eight hours' work, which needn't follow one another. The spell has to be prepared on each of them."):format(ns.DaysText(days)))
    return true
end
