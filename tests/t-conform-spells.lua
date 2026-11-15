-- Every spell fact the addon holds against the rules site's (tests/data/site-*.txt):
-- level, ritual, concentration, attack or save, dice, damage type, casting time, what
-- a higher slot adds, cantrip growth, priced components, school and range of the
-- lines of facts, the class lists, the pick lists made from them, and the spells a
-- class or subclass always has prepared. One PROBLEM line per difference; the ones
-- that are meant are in tests/data/spells-allowed.lua, each with its reason.
--   bash tests/run.sh t-conform-spells.lua            the differences
--   bash tests/run.sh t-conform-spells.lua allowed    also lists the allowed ones
dofile(ARG3 .. "/t-conform-spells-lib.lua")

local G = R.SLOT_GROWTH
local SCHOOLS = { A = "Abjuration", C = "Conjuration", D = "Divination", E = "Enchantment", V = "Evocation", I = "Illusion", N = "Necromancy", T = "Transmutation" }
local TIMES = { action = "ACTION", bonus = "BONUS", reaction = "REACTION", minute = "LONG", hour = "LONG" }
local HEALS = { HEALING = true, SELFHEAL = true, TEMPHP = true }

local function Join(list) return #list > 0 and table.concat(list, ",") or "none" end
local function Matching(list, count, sides)
    for _, dice in ipairs(list) do
        if dice.sides == sides and (count == nil or dice.count == count) then return dice end
    end
end

-- Attack or save ---------------------------------------------------------------
local function Roll(name, mine, site)
    local attack, saves = site.attack ~= "" or ATTACK_TEXT[name] == true, #site.saves > 0
    local held = mine.kind == "ATTACK" and "an attack" or mine.kind == "SAVE" and (mine.save .. " save") or "no roll"
    local theirs = (attack and "attack " or "") .. (saves and ("save " .. Join(site.saves)) or "") .. ((attack or saves) and "" or "no roll")
    local ok = (mine.kind == "ATTACK" and attack) or (mine.kind == "SAVE" and Has(site.saves, mine.save)) or (mine.kind == "NONE" and not attack and not saves)
    if not Same(ok, name, "roll", ("addon %s, site %s"):format(held, theirs)) then return end
    -- The sheet holds one roll: a spell with more than one is a choice the addon made.
    Same(not (attack and saves) and #site.saves < 2, name, "one roll", ("addon %s, site %s"):format(held, theirs))
end

-- Dice ---------------------------------------------------------------------------
local function Dice(name, mine, site)
    local growth = G[name] or {}
    local pool = HEALS[mine.dice] and site.other or site.damage
    local what = ("addon %dd%d %s, site damage %s, other dice %s"):format(mine.count, mine.sides, mine.dice:lower(), DiceText(site.damage), DiceText(site.other))
    if mine.count == 0 then
        Same(#site.damage == 0, name, "dice", "addon rolls nothing, site damage " .. DiceText(site.damage))
        return
    end
    local tag = Matching(pool, mine.count, mine.sides)
    if not Same(tag ~= nil, name, "dice", what) then return end
    Same((tag.flat or 0) == (growth.flat or 0), name, "flat", ("addon adds %d, site %s"):format(growth.flat or 0, tag.raw))
    -- The spellcasting modifier is added where the site's text adds it.
    Same((mine.addMod or false) == (PLUS_MOD[name] == true), name, "modifier", ("the addon %s the spellcasting modifier, the site's text %s"):format(mine.addMod and "adds" or "doesn't add", PLUS_MOD[name] and "does" or "doesn't"))
    -- A second roll of the same casting has to be one the site names too.
    local also = growth.also
    if also then
        local second = Matching(HEALS[also.kind] and site.other or site.damage, also.count, also.sides)
        Same(second ~= nil, name, "second roll", ("addon %dd%d, site damage %s, other dice %s"):format(also.count, also.sides, DiceText(site.damage), DiceText(site.other)))
    end
    -- Damage dice of the site that the casting doesn't roll: each needs its reason.
    local unrolled = {}
    for _, dice in ipairs(site.damage) do
        local rolled = dice == tag or (also and dice.count == also.count and dice.sides == also.sides) or (R.GROWING_SPELLS[name] and dice.count == mine.count)
        if not rolled then unrolled[#unrolled + 1] = dice.raw end
    end
    Same(#unrolled == 0, name, "other damage", ("the casting rolls %dd%d%s, the site also has %s"):format(mine.count, mine.sides, also and (" and %dd%d"):format(also.count, also.sides) or "", table.concat(unrolled, ", ")))
end

-- Damage type ----------------------------------------------------------------------
local function Type(name, mine, site)
    local held = R.SPELL_DAMAGE[name]
    if held then
        Same(Has(site.types, held), name, "type", ("addon %s, site %s"):format(held, Join(site.types)))
    elseif mine.count > 0 and mine.dice == "DAMAGE" and #site.types == 1 then
        -- The sheet asks for the type of force spells (Sheet/Metamorphosis.lua) and of
        -- the spells Data/SpellsCore.lua lists; the rest may go without.
        Same(site.types[1] ~= "force" and not R.SPELL_FACT_LINES[name], name, "type", "addon none, site " .. site.types[1])
    end
end

-- Higher slots -----------------------------------------------------------------------
local function Slots(name, mine, site)
    local growth, added = G[name], {}
    for dice in site.scaling:gmatch("%d*d%d+") do added[#added + 1] = { count = tonumber(dice:match("^%d+")) or 1, sides = tonumber(dice:match("d(%d+)")) } end
    local own = mine.count > 0 and Matching(added, nil, mine.sides)
    Same((mine.up or 0) == (own and own.count or 0), name, "up", ("addon adds %d d%d per slot level, site: %s"):format(mine.up or 0, mine.sides, site.scaling == "" and "nothing" or site.scaling))
    if growth and growth.also and (growth.also.up or 0) > 0 then
        local second = Matching(added, growth.also.up, growth.also.sides)
        Same(second ~= nil, name, "second roll up", ("addon adds %d d%d, site: %s"):format(growth.also.up, growth.also.sides, site.scaling))
    end
    -- Something grows on the site: the addon has to hold something about it.
    local holds = (mine.up or 0) > 0 or (mine.hitsUp or 0) > 0 or growth ~= nil
    if site.scaling ~= "" then
        Same(holds, name, "higher slots", "site: " .. site.scaling .. ", the addon holds nothing")
    else
        local says = growth and (growth[1] or growth.at or growth.upAt or growth.flatUp or (growth.also and (growth.also.up or 0) > 0)) or (mine.hitsUp or 0) > 0
        Same(not says, name, "higher slots", "the addon holds growth, the site names none")
    end
end

-- Cantrips -----------------------------------------------------------------------------
local function Cantrip(name, mine, site)
    local first = site.scaling:match("^1:(%d+d%d+) ")
    if first then
        local count, sides = first:match("^(%d+)d(%d+)$")
        local standard = site.scaling == ("1:%dd%d 5:%dd%d 11:%dd%d 17:%dd%d"):format(count, sides, count * 2, sides, count * 3, sides, count * 4, sides)
        Same(mine.scales and standard and mine.count == tonumber(count) and mine.sides == tonumber(sides), name, "cantrip",
            ("addon %dd%d%s, site %s"):format(mine.count, mine.sides, mine.scales and " growing" or " fixed", site.scaling))
    elseif site.scaling == "*" then
        Same(mine.hitsScale or mine.count == 0, name, "cantrip", "site: something grows with level, the addon holds no more attacks")
        Same(not mine.scales, name, "cantrip", "addon dice grow, site: something else does")
    else
        Same(not mine.scales and site.scaling == "", name, "cantrip", ("addon %s, site %s"):format(mine.scales and "growing" or "fixed", site.scaling == "" and "no growth" or site.scaling))
    end
end

-- Components with a price ----------------------------------------------------------------
local function Gold(amount)
    local text = tostring(amount)
    return amount >= 1000 and (text:sub(1, -4) .. "," .. text:sub(-3)) or text
end
local function Named(part, text)
    text = text:lower()
    for base in pairs(part.accept or {}) do
        for word in base:lower():gmatch("%a+") do
            if #word >= 3 and text:find(word:gsub("s$", ""), 1, true) then return true end
        end
    end
end
local function Components(name, mine, site)
    local gold = site.price and site.price >= 1 and math.floor(site.price) or 0
    Same((mine.material or 0) == gold, name, "material", ("addon %d gold, site %s"):format(mine.material or 0, site.price and (site.price .. " gp") or "no price"))
    Same((mine.consumed or false) == (gold > 0 and site.consumed), name, "consumed", ("addon %s, site %s"):format(tostring(mine.consumed), tostring(site.consumed)))
    local parts = R.SPELL_COMPONENTS[name]
    if not Same((parts ~= nil) == (site.price ~= nil), name, "component", parts and "the addon checks for one, the site names no price" or ("the addon checks for none, site: " .. site.material)) then return end
    if not (parts and site.price) then return end
    local copper, used, priced = math.floor(site.price * 100 + 0.5), false, false
    for _, part in ipairs(parts) do
        used = used or part.consumed == true
        if part.weapon then
            priced = priced or part.cost == copper
        elseif part.coins then
            priced = priced or part.coins == copper
        elseif part.item then
            priced = priced or part.cost == copper
            local worth = Gold(part.cost / 100) .. "+ GP"
            Same(site.material:find("%f[%d]" .. worth:gsub("%p", "%%%0")) ~= nil, name, "component", ("addon %s worth %s gold, site: %s"):format(part.item, part.cost / 100, site.material))
            Same(Named(part, site.material), name, "component name", ("addon %s, site: %s"):format(part.item, site.material))
        end
    end
    Same(priced, name, "component", ("no part is worth the site's %s gp"):format(site.price))
    Same(used == site.consumed, name, "component consumed", ("addon %s, site %s"):format(tostring(used), tostring(site.consumed)))
end

-- School and range, where the addon keeps a line of facts ------------------------------------
local function Range(site)
    local shape, amount, unit = site.range:match("^(%a+) (%d+) (%a+)$")
    if shape then return ("Self, %s-%s %s"):format(amount, unit == "feet" and "foot" or "mile", shape) end
    amount, unit = site.range:match("^(%d+) (%a+)$")
    if amount then return amount .. " " .. (unit == "miles" and amount == "1" and "mile" or unit) end
    return site.range:gsub("^%l", string.upper)
end
local function FactLine(name, mine, site)
    local line = R.SPELL_FACT_LINES[name] or mine.desc
    local school, range = line:match("^(%a+)%. Range (.-)%. ")
    if not school then school, range = line:match("^(%a+)%. Range (.-)%.$") end
    if not school then return end
    Same(school == SCHOOLS[site.school], name, "school", ("addon %s, site %s"):format(school, SCHOOLS[site.school] or site.school))
    Same(range == Range(site), name, "range", ("addon %s, site %s"):format(range, Range(site)))
end

-- Every spell -------------------------------------------------------------------------------------
local compared = 0
local names = {}
for name in pairs(R.SPELLS) do names[#names + 1] = name end
table.sort(names)
for _, name in ipairs(names) do
    local mine, site = R.SPELLS[name], SITE[name]
    if Same(site ~= nil, name, "unknown", "the addon lists it, the site (XPHB, WoW) doesn't") then
        compared = compared + 1
        Same((R.AZEROTH_SPELLS[name] == true) == (site.source == "WoW"), name, "group", ("the site's source is %s"):format(site.source))
        Same(mine.level == site.level, name, "level", ("addon %d, site %d"):format(mine.level, site.level))
        Same((mine.ritual or false) == site.ritual, name, "ritual", ("addon %s, site %s"):format(tostring(mine.ritual), tostring(site.ritual)))
        Same((mine.concentration or false) == site.concentration, name, "concentration", ("addon %s, site %s"):format(tostring(mine.concentration), tostring(site.concentration)))
        local time = false
        for _, option in ipairs(List(site.time, "/")) do time = time or TIMES[option:match("%a+$")] == (mine.time or "ACTION") end
        Same(time, name, "time", ("addon %s, site %s"):format(mine.time or "ACTION", site.time))
        Roll(name, mine, site)
        Dice(name, mine, site)
        Type(name, mine, site)
        if mine.level == 0 then Cantrip(name, mine, site) else Slots(name, mine, site) end
        Components(name, mine, site)
        FactLine(name, mine, site)
    end
end
for _, name in ipairs(SITE_NAMES) do
    Same(R.SPELLS[name] ~= nil, name, "missing", ("the site has it (%s, level %d), the addon doesn't"):format(SITE[name].source, SITE[name].level))
end
for name in pairs(G) do Same(R.SPELLS[name] ~= nil, name, "unknown", "Data/SlotGrowth.lua names a spell that isn't listed") end
for name in pairs(R.SPELL_COMPONENTS) do Same(R.SPELLS[name] ~= nil, name, "unknown", "the components name a spell that isn't listed") end
for name in pairs(R.SPELL_DAMAGE) do Same(R.SPELLS[name] ~= nil, name, "unknown", "the damage types name a spell that isn't listed") end
-- Protection that lasts while a spell does: how long, and whether it hangs on concentration.
local HOURS = { hour = 1, day = 24 }
for name, ward in pairs(R.SPELL_WARDS) do
    local site = SITE[name]
    if Same(site ~= nil, name, "unknown", "the wards name a spell that isn't listed") then
        local amount, unit = site.duration:match("^(%d+) (%a+)$")
        local hours = (tonumber(amount) or 0) * (HOURS[unit] or 0)
        Same(ward.hours == hours, name, "ward hours", ("addon %d, site %s"):format(ward.hours, site.duration))
        Same((ward.conc or false) == site.concentration, name, "ward concentration", ("addon %s, site %s"):format(tostring(ward.conc), tostring(site.concentration)))
    end
end
-- A die that grows while the spell lasts: the sizes are the site's damage dice, in order.
for name, sizes in pairs(R.GROWING_SPELLS) do
    local theirs = {}
    for _, dice in ipairs(SITE[name] and SITE[name].damage or {}) do theirs[#theirs + 1] = dice.sides end
    Same(table.concat(sizes, ",") == table.concat(theirs, ","), name, "growing die", ("addon d%s, site d%s"):format(table.concat(sizes, " d"), table.concat(theirs, " d")))
end

-- Class lists: the list of a class is that of its core class in the addon ------------------------
local function SiteList(key)
    local class = R.CLASSES[key]
    return SITE_LISTS["WoW/" .. class.name] or SITE_LISTS["XPHB/" .. class.base], class.name
end
for _, key in ipairs(R.CLASS_ORDER) do
    local class = R.CLASSES[key]
    local mine, site, label = R.SPELL_LISTS[class.base], SiteList(key)
    if mine and class.caster then
        local have = {}
        for _, name in ipairs(mine) do
            Same(not have[name], label .. " list", name, "listed twice")
            have[name] = true
            Same(site[name] == true, label .. " list", name, "on the addon's list, not on the site's")
        end
        for name in pairs(site) do Same(have[name] == true, label .. " list", name, "on the site's list, not on the addon's") end
    end
end
-- The spells a hero class only gets from its subclass are not on a list of the site.
for key, list in pairs(R.CLASS_SPELLS) do
    for _, name in ipairs(list) do
        local on = false
        for class in pairs(SITE[name] and SITE[name].classes or {}) do on = true end
        Same(SITE[name] ~= nil and not on, R.CLASSES[key].name .. " own spells", name, "the site puts it on a class list")
    end
end
for _, name in ipairs(SITE_NAMES) do
    local on, held = false, false
    for class in pairs(SITE[name].classes) do on = true end
    for _, list in pairs(R.CLASS_SPELLS) do held = held or Has(list, name) end
    if not on and SITE[name].source == "WoW" then Same(held, "own spells", name, "on no class list of the site, and in no R.CLASS_SPELLS") end
end

-- Pick lists: made from the class lists, by level -------------------------------------------------
local CASTER_OF = {} -- [core class] = the first class of the addon that casts as it
for _, key in ipairs(R.CLASS_ORDER) do
    local class = R.CLASSES[key]
    if class.caster and not class.hero and not CASTER_OF[class.base] then CASTER_OF[class.base] = key end
end
for _, key in ipairs(R.CLASS_ORDER) do
    local class = R.CLASSES[key]
    if class.caster and not CASTER_OF[class.base] then CASTER_OF[class.base] = key end
end
-- wanted(spell) gives the character level a spell can be picked from, or nil to leave it out.
local function Picks(listKey, base, wanted)
    local list, label = R.PICK_LISTS[listKey], "pick list " .. listKey
    if not Same(list ~= nil and CASTER_OF[base] ~= nil, label, "exists", "no such list") then return end
    local site = SiteList(CASTER_OF[base])
    for name in pairs(site) do
        local level = wanted(SITE[name])
        if level then
            local item = list.items[name]
            if Same(item ~= nil, label, name, "the site's list has it, the pick list doesn't") and level ~= true then
                Same(item.level == level, label, name, ("can be picked from level %s, slots of its level come at %d"):format(tostring(item.level), level))
            end
        end
    end
    for name in pairs(list.items) do
        Same(site[name] and wanted(SITE[name]) ~= nil, label, name, "on the pick list, not on the site's list at that level")
    end
end
local FIRST = {
    FULL = function(level) return 2 * level - 1 end,
    HALF = function(level) return level <= 5 and 4 * level - 3 or nil end,
    PACT = function(level) return level <= 5 and 2 * level - 1 or nil end,
}
for base in pairs(R.CANTRIPS_KNOWN) do
    Picks("cantrips" .. base, base, function(spell) return spell.level == 0 or nil end)
end
for base in pairs(R.SPELLS_PREPARED) do
    if base ~= "Wizard" and CASTER_OF[base] then
        local first = FIRST[R.CLASSES[CASTER_OF[base]].caster]
        Picks("prepared" .. base, base, function(spell) return spell.level > 0 and first(spell.level) or nil end)
    end
end
Picks("spellbook", "Wizard", function(spell) return spell.level > 0 and FIRST.FULL(spell.level) or nil end)
for level = 6, 9 do Picks("arcanum" .. level, "Warlock", function(spell) return spell.level == level or nil end) end
for level = 1, 2 do
    Picks("spellMastery" .. level, "Wizard", function(spell) return spell.level == level and spell.time == "1 action" or nil end)
end
Picks("signatureSpells", "Wizard", function(spell) return spell.level == 3 or nil end)

-- Always prepared: what a class and its subclasses give, by class level ---------------------------
local function Grant(kind, class, subclass, option)
    for _, source in ipairs({ class.name, class.base }) do
        for _, grant in ipairs(SITE_GRANTS) do
            if grant.kind == kind and grant.class == source and (kind == "class" or grant.subclass == subclass) and grant.option == (option or "") then return grant end
        end
    end
end
local function Prepared(key, subclass, spec)
    local byLevel = {}
    for level = 1, R.MAX_LEVEL do
        for _, feature in ipairs(ns.FeaturesGainedAt(key, subclass, level)) do
            local steps = feature.prepared
            if type(steps) == "function" then steps = steps({ spec = spec or "", level = R.MAX_LEVEL, class = key, subclass = subclass }) end
            -- A choice whose options name their spells in words: "Level 3: A, B. Level 5: C."
            for _, option in ipairs(feature.options or {}) do
                if option.name == spec or option.name .. " Land" == spec then
                    steps = {}
                    for level, names in option.desc:gmatch("Level (%d+): ([^%.]+)%.") do steps[#steps + 1] = { tonumber(level), names } end
                end
            end
            for _, step in ipairs(steps or {}) do
                byLevel[step[1]] = byLevel[step[1]] or {}
                for name in step[2]:gmatch("[^,]+") do byLevel[step[1]][strtrim(name)] = true end
            end
        end
    end
    return byLevel
end
local function Compare(label, mine, site)
    for level, names in pairs(site) do
        for _, name in ipairs(names) do
            Same(mine[level] and mine[level][name] == true, label, name, ("the site prepares it at level %d, the addon doesn't"):format(level))
        end
    end
    for level, names in pairs(mine) do
        for name in pairs(names) do
            Same(Has(site[level] or {}, name), label, name, ("the addon prepares it at level %d, the site doesn't"):format(level))
            Same(R.SPELLS[name] ~= nil, label, name, "prepared, but not a listed spell")
        end
    end
end
local grantsSeen = {}
for _, key in ipairs(R.CLASS_ORDER) do
    local class = R.CLASSES[key]
    local own = Grant("class", class)
    local ownSteps = Prepared(key, "", "")
    grantsSeen[own or 0] = true
    Compare(class.name .. " prepared", ownSteps, own and own.prepared or {})
    for _, subclass in ipairs(class.subclasses) do
        local options = { false }
        for _, grant in ipairs(SITE_GRANTS) do
            if grant.kind == "subclass" and grant.subclass == subclass and (grant.class == class.name or grant.class == class.base) and grant.option ~= "" then
                options[#options + 1] = grant.option
            end
        end
        if #options > 1 then table.remove(options, 1) end
        for _, option in ipairs(options) do
            local grant = Grant("subclass", class, subclass, option or nil)
            grantsSeen[grant or 0] = true
            local mine = Prepared(key, subclass, option or "")
            for level, names in pairs(ownSteps) do
                for name in pairs(names) do if mine[level] then mine[level][name] = nil end end
            end
            for level, names in pairs(mine) do if not next(names) then mine[level] = nil end end
            Compare(("%s, %s%s prepared"):format(class.name, subclass, option and (" (" .. option .. ")") or ""), mine, grant and grant.prepared or {})
        end
    end
end

-- A saved copy that still carries a line of facts from before a correction gets the
-- written summary all the same (Data/SpellSummaries.lua).
for name, line in pairs({
    ["Control Weather"] = "Transmutation. Range Self, 5-foot sphere. Concentration.",
    ["Earthquake"] = "Transmutation. Range 500 feet. Constitution save. 12d6 bludgeoning damage. Concentration.",
}) do
    local known = R.SPELLS[name]
    Same(R.FreshSpellSummary({ name = name, level = known.level, desc = line }) == known.desc, name, "former line", "a saved copy with the earlier line of facts isn't brought up to date")
    Same(R.FreshSpellSummary({ name = name, level = known.level, desc = R.SPELL_FACT_LINES[name] }) == known.desc, name, "fact line", "a saved copy with the line of facts isn't brought up to date")
end

-- Allowed differences that no longer occur have to go.
for key in pairs(ALLOWED) do
    if not USED[key] then Problem("tests/data/spells-allowed.lua allows \"" .. key .. "\", which is no difference any more") end
end
local problems = 0
for _ in pairs(PROBLEMS) do problems = problems + 1 end
print(("t-conform-spells: %d spells compared with the site's %d, %d checks, %d allowed differences, %d problems"):format(compared, #SITE_NAMES, CHECKS, ALLOWED_SEEN, problems))
