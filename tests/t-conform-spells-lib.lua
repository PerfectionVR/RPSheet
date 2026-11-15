-- Shared by t-conform-spells.lua: reads the rules site's spell facts from tests/data
-- (how those files are made is in their first lines) and keeps the list of
-- differences that are meant (tests/data/spells-allowed.lua).
dofile(ARG3 .. "/sim.lua")

local DATA = ARG3 .. "/data/"

-- Splits on a separator and keeps empty fields.
function Fields(text, sep)
    local out = {}
    for piece in (text .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = piece end
    return out
end
function List(text, sep)
    local out = {}
    for _, piece in ipairs(Fields(text, sep or ",")) do
        if piece ~= "" then out[#out + 1] = piece end
    end
    return out
end
function Has(list, value)
    for _, item in ipairs(list) do if item == value then return true end end
    return false
end
local function Lines(file)
    local handle = io.open(DATA .. file, "r")
    if not handle then Problem("can't read tests/data/" .. file) return {} end
    local out = {}
    for line in handle:lines() do
        line = line:gsub("\r$", "")
        if line ~= "" and line:sub(1, 1) ~= "#" then out[#out + 1] = line end
    end
    handle:close()
    return out
end

-- "10d6 + 40" -> { count = 10, sides = 6, flat = 40 }; "d8" counts as 1d8.
local function Dice(text)
    local count, sides, rest = text:match("^(%d*)d(%d+)(.*)$")
    if not sides then return { raw = text } end
    return { raw = text, count = tonumber(count) or 1, sides = tonumber(sides), flat = tonumber(rest:match("^ %+ (%d+)$")), odd = rest ~= "" and not rest:match("^ %+ %d+$") }
end
local function DiceList(text)
    local out = {}
    for _, piece in ipairs(List(text)) do out[#out + 1] = Dice(piece) end
    return out
end
function DiceText(list)
    local out = {}
    for _, dice in ipairs(list) do out[#out + 1] = dice.raw end
    return #out > 0 and table.concat(out, ", ") or "none"
end

local CORE = { B = "Bard", C = "Cleric", D = "Druid", P = "Paladin", R = "Ranger", S = "Sorcerer", K = "Warlock", W = "Wizard" }
local SETTING = { Pr = "Priest", Ma = "Mage", Ev = "Evoker", Hu = "Hunter", Dr = "Druid", Pa = "Paladin", Wl = "Warlock", DK = "Death Knight", DH = "Demon Hunter" }

-- SITE[<spell name>] = its facts; SITE_NAMES in the file's order.
SITE, SITE_NAMES, SITE_LOWER = {}, {}, {}
for _, line in ipairs(Lines("site-spells.txt")) do
    local f = Fields(line, "|")
    if #f ~= 17 then
        Problem("site-spells.txt: a line with " .. #f .. " fields: " .. line:sub(1, 60))
    else
        local damage, other = f[15]:match("^(.-)~(.*)$")
        local price, consumed, what = f[11]:match("^([%d%.]+)gp(!?)%S* (.+)$")
        local core, setting = f[17]:match("^(.-);(.*)$")
        local spell = {
            name = f[1], source = f[2], level = tonumber(f[3]), school = f[4], time = f[5],
            ritual = f[6] == "r", concentration = f[7] == "c", duration = f[8], range = f[9], components = f[10],
            price = tonumber(price), consumed = consumed == "!", material = what or "",
            saves = List(f[12]), attack = f[13], types = List(f[14]),
            damage = DiceList(damage or f[15]), other = DiceList(other or ""), scaling = f[16],
            classes = {},
        }
        for letter in (core or ""):gmatch(".") do spell.classes["XPHB/" .. (CORE[letter] or letter)] = true end
        for _, code in ipairs(List(setting or "")) do spell.classes["WoW/" .. (SETTING[code] or code)] = true end
        if SITE[spell.name] then Problem("site-spells.txt names " .. spell.name .. " twice") end
        SITE[spell.name], SITE_LOWER[spell.name:lower()] = spell, spell.name
        SITE_NAMES[#SITE_NAMES + 1] = spell.name
    end
end

-- SITE_LISTS["WoW/Priest"] = { [spell name] = true }
SITE_LISTS = {}
for _, line in ipairs(Lines("site-class-lists.txt")) do
    local source, class, names = line:match("^(.-)|(.-)|(.*)$")
    local set = {}
    for _, name in ipairs(List(names or "", ";")) do set[name] = true end
    SITE_LISTS[source .. "/" .. class] = set
end
-- The two files say the same thing two ways: they have to agree.
for key, set in pairs(SITE_LISTS) do
    for name in pairs(set) do
        if not (SITE[name] and SITE[name].classes[key]) then Problem(("site-class-lists.txt gives %s to %s, site-spells.txt doesn't"):format(name, key)) end
    end
end
for name, spell in pairs(SITE) do
    for key in pairs(spell.classes) do
        if not (SITE_LISTS[key] and SITE_LISTS[key][name]) then Problem(("site-spells.txt gives %s to %s, site-class-lists.txt doesn't"):format(name, key)) end
    end
end

-- SITE_GRANTS[#] = { kind, class, classSource, subclass, option, prepared = { [level] = { names } },
--                    cantrips = the same for the cantrips it makes known }
-- with the spells' names as the site's list spells them.
SITE_GRANTS = {}
for _, line in ipairs(Lines("site-granted-spells.txt")) do
    local f = Fields(line, "|")
    local grant = { kind = f[1], class = f[2], classSource = f[3], subclass = f[4], option = f[6], prepared = {}, cantrips = {}, others = {} }
    for _, part in ipairs(List(f[7] or "", ";")) do
        local how, level, names = part:match("^(%a+) ([%w_]+):(.*)$")
        local list = {}
        for _, name in ipairs(List(names or "")) do list[#list + 1] = SITE_LOWER[name] or name end
        if how == "prepared" and tonumber(level) then
            grant.prepared[tonumber(level)] = list
        elseif how then
            grant.others[#grant.others + 1] = part
            -- A cantrip a feature makes known is one more the character has prepared.
            if how == "known" and tonumber(level) then
                for _, name in ipairs(list) do
                    if SITE[name] and SITE[name].level == 0 then
                        grant.cantrips[tonumber(level)] = grant.cantrips[tonumber(level)] or {}
                        table.insert(grant.cantrips[tonumber(level)], name)
                    end
                end
            end
        end
    end
    SITE_GRANTS[#SITE_GRANTS + 1] = grant
end

-- PLUS_MOD[<spell name>] = true where a roll adds the spellcasting modifier.
-- ATTACK_TEXT[<spell name>] = true where the text has an attack roll the tags leave out.
PLUS_MOD, ATTACK_TEXT = {}, {}
local FLAGS = { plusmod = PLUS_MOD, attacktext = ATTACK_TEXT }
for _, line in ipairs(Lines("site-spell-flags.txt")) do
    local flag, names = line:match("^(.-)|(.*)$")
    for _, name in ipairs(List(names or "", ";")) do
        local saves
        if flag == "savetext" then name, saves = name:match("^(.-)=(.*)$") end
        if not SITE[name] then
            Problem("site-spell-flags.txt names " .. tostring(name) .. ", which site-spells.txt doesn't have")
        elseif saves then
            SITE[name].saves = List(saves)
        elseif FLAGS[flag] then
            FLAGS[flag][name] = true
        else
            Problem("site-spell-flags.txt: unknown flag " .. tostring(flag))
        end
    end
end

-- Differences that are meant: ALLOWED["<spell or list>|<field>"] = the reason.
ALLOWED = dofile(DATA .. "spells-allowed.lua")
CHECKS, DIFFS, USED, ALLOWED_SEEN = 0, 0, {}, 0
function Same(ok, subject, field, text)
    CHECKS = CHECKS + 1
    if ok then return true end
    local key = subject .. "|" .. field
    if ALLOWED[key] then
        if not USED[key] then USED[key] = true; ALLOWED_SEEN = ALLOWED_SEEN + 1 end
        if rawget(_G, "ARG4") == "allowed" then print(("allowed: %s, %s: %s  [%s]"):format(subject, field, text, ALLOWED[key])) end
        return false
    end
    DIFFS = DIFFS + 1
    Problem(("%s, %s: %s"):format(subject, field, text))
    return false
end
