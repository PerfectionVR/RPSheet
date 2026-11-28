-- Creature templates: the list of Data/CreatureList.lua made into tables.
--   R.CREATURES[<name>] = {
--       name, size, kind, cr, ac, hp, init,
--       mods = { STR = 5, ... },          ability modifiers
--       saves = { DEX = 9, ... },         every ability: the listed bonus, or the modifier
--       resist, immune, vulnerable        { fire = true, ... }
--       conditionImmune                   { "charmed", ... }
--       attacksPerAction                  how many attacks its action is
--       attacks = { { name, reach = "m" | "r" | "mr", hit, parts, legendary }, ... }
--       forces = { { name, stat, dc, parts, half, kind, recharge, perDay, with, swap }, ... }
--           saves it makes others roll. kind: "action", "bonus", "reaction", "legendary"
--           or "trait"; recharge: the least d6 roll that brings it back; perDay: uses;
--           with: used along with its attacks; swap: attacks it takes the place of
--   }
--   parts = { { count, sides, flat, type }, ... }: dice, what is added, and the damage
--   type (nil when the creature's player picks it)
--   R.CREATURE_ORDER = names by challenge, then by name
local _, ns = ...
local R = ns.Rules

local SIZES = { T = "Tiny", S = "Small", M = "Medium", L = "Large", H = "Huge", G = "Gargantuan", HG = "Huge or Gargantuan" }

local function Set(text)
    local set = {}
    for word in text:gmatch("[^,]+") do set[word] = true end
    return set
end

-- "3d10+5 slashing+2d6 necrotic"
local function Parts(text)
    local parts = {}
    for dice, kind in text:gmatch("%+?([%dd%+]+)%s(%a+)") do
        local count, sides = dice:match("^(%d+)d(%d+)")
        local flat = tonumber(dice:match("%+(%d+)$")) or (not count and tonumber(dice)) or 0
        parts[#parts + 1] = { count = tonumber(count) or 0, sides = tonumber(sides) or 0, flat = flat, type = R.DAMAGE_TYPE[kind] and kind or nil }
    end
    return parts
end

-- "3d10 + 5 slashing + 2d6 necrotic"
function R.DamagePartsText(parts)
    local words = {}
    for _, part in ipairs(parts) do
        local dice = part.count > 0 and ("%dd%d%s"):format(part.count, part.sides, part.flat > 0 and (" + " .. part.flat) or "") or tostring(part.flat)
        words[#words + 1] = part.type and (dice .. " " .. part.type) or dice
    end
    return table.concat(words, " + ")
end

-- The number a challenge rating sorts by ("1/2" is a half).
local function Challenge(cr)
    local over, under = cr:match("^(%d+)/(%d+)$")
    return over and tonumber(over) / tonumber(under) or tonumber(cr) or 0
end

R.CREATURES, R.CREATURE_ORDER = {}, {}
for line in R.CREATURE_DATA:gmatch("[^\r\n]+") do
    local f = {}
    for field in (line .. "|"):gmatch("([^|]*)|") do f[#f + 1] = field end
    local creature = {
        name = f[1], size = SIZES[f[2]] or f[2], kind = f[3]:match("^%a+"), cr = f[4], challenge = Challenge(f[4]),
        ac = tonumber(f[5]), hp = tonumber(f[6]), init = tonumber(f[7]),
        mods = {}, saves = {}, resist = Set(f[10]), immune = Set(f[11]), vulnerable = Set(f[12]),
        conditionImmune = {}, attacksPerAction = tonumber(f[14]:match("^M(%d+)$")) or 1, attacks = {}, forces = {},
    }
    local scores = {}
    for score in f[8]:gmatch("%d+") do scores[#scores + 1] = tonumber(score) end
    for index, stat in ipairs(R.STATS) do
        creature.mods[stat] = math.floor((scores[index] - 10) / 2)
        creature.saves[stat] = creature.mods[stat]
    end
    for stat, bonus in f[9]:gmatch("(%a+)([+-]%d+)") do creature.saves[stat:upper()] = tonumber(bonus) end
    for word in f[13]:gmatch("[^,]+") do creature.conditionImmune[#creature.conditionImmune + 1] = word end
    for entry in f[15]:gmatch("[^;]+") do
        local name, reach, hit, damage, flags = entry:match("^(.-)~(%a+)~(-?%d+)~([^~]*)~?(%a*)$")
        creature.attacks[#creature.attacks + 1] = { name = name, reach = reach, hit = tonumber(hit), parts = Parts(damage), legendary = flags == "l" or nil }
    end
    for entry in (f[16] or ""):gmatch("[^;]+") do
        local name, stat, dc, damage, flags = entry:match("^(.-)~(%a+)~(%d+)~(.-)~(%w*)$")
        creature.forces[#creature.forces + 1] = {
            name = name, stat = stat, dc = tonumber(dc), parts = Parts(damage), half = flags:find("h", 1, true) ~= nil,
            kind = (flags:find("b", 1, true) and "bonus") or (flags:find("e", 1, true) and "reaction") or (flags:find("l", 1, true) and "legendary")
                or (flags:find("t", 1, true) and "trait") or "action",
            recharge = tonumber(flags:match("r(%d)")), perDay = tonumber(flags:match("d(%d)")),
            with = flags:find("w", 1, true) ~= nil or nil, swap = tonumber(flags:match("x(%d)")),
        }
    end
    R.CREATURES[creature.name] = creature
    R.CREATURE_ORDER[#R.CREATURE_ORDER + 1] = creature.name
end
R.CREATURE_DATA = nil
table.sort(R.CREATURE_ORDER, function(a, b)
    local one, two = R.CREATURES[a], R.CREATURES[b]
    if one.challenge ~= two.challenge then return one.challenge < two.challenge end
    return a < b
end)

-- The template of that name, whatever its capitals; nil when there is none.
function R.FindCreature(name)
    name = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    for _, known in ipairs(R.CREATURE_ORDER) do
        if known:lower() == name then return R.CREATURES[known] end
    end
end
