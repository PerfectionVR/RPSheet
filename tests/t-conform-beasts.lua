-- The beasts a druid can turn into against the rules site: challenge rating, size,
-- Armor Class, every speed, Strength, Dexterity and Constitution, skills and saving
-- throws with their bonuses, senses, and each attack's bonus, dice, damage type,
-- reach, range and extra damage. The site's facts are in tests/data/beasts-*.txt.
-- Not held by the addon, so not compared: hit points (the druid keeps its own) and
-- Intelligence, Wisdom and Charisma (likewise).
dofile(ARG3 .. "/t-conform-lib.lua")

-- Deliberate differences, each with its reason.
Allow("beast/Swarm of Insects/speeds", "the DM chooses whether the swarm climbs or flies; the form is the crawling swarm, which climbs")

local SIZES = { T = "Tiny", S = "Small", M = "Medium", L = "Large", H = "Huge" }
local CR = { ["1/8"] = 1 / 8, ["1/4"] = 1 / 4, ["1/2"] = 1 / 2 }
local STATS = { "STR", "DEX", "CON" }
local MOVES = { burrowing = "burrow", climbing = "climb", flying = "fly", swimming = "swim" }

-- "2d6+3 piercing", "1 slashing" or "3d4" as dice, sides, flat and type.
local function Damage(text)
    local dice, kind = text:match("^(%S+)%s*(%a*)$")
    local count, sides, flat = dice:match("^(%d+)d(%d+)([+-]?%d*)$")
    if not count then return 0, 0, tonumber(dice) or 0, kind end
    return tonumber(count), tonumber(sides), tonumber(flat) or 0, kind
end
local function DiceText(count, sides, flat, kind)
    local text = count > 0 and ("%dd%d"):format(count, sides) or ""
    if flat ~= 0 or count == 0 then text = text .. (count > 0 and ("%+d"):format(flat) or tostring(flat)) end
    return text .. " " .. kind
end

-- One action of the site ("Bite:m+5:1d8+3 piercing:r5:2d6 poison") against the addon's.
local function Action(key, attack, text)
    local parts = {}
    for part in (text .. ":"):gmatch("(.-):") do parts[#parts + 1] = part end
    local roll = parts[2] or "-"
    if roll:find("^[mr,]+%+") or roll:find("^[mr,]+%-") then
        Same(key .. "to hit", tostring(attack[2]), roll:match("([+-]?%d+)$"):gsub("^%+", ""))
        local count, sides, flat, kind = Damage(parts[3])
        Same(key .. "damage", DiceText(attack[3], attack[4], attack[5], attack[6]), DiceText(count, sides, flat, kind))
        local where = parts[4] or ""
        Same(key .. "reach", attack.reach or 5, tonumber(where:match("r(%d+)")) or 5)
        Same(key .. "range", attack.ranged or "", where:match("rg([%d/]+)") or "")
        -- What comes on top or instead: damage of another type, or other dice in a situation.
        local extra = {}
        if attack.plus then extra[#extra + 1] = DiceText(attack.plus[1], attack.plus[2], 0, attack.plus[3]) end
        if attack.alt and (attack.alt[2] or 0) > 0 then
            extra[#extra + 1] = DiceText(attack.alt[2], attack.alt[3], attack.alt[4] or 0, attack[6])
        end
        Same(key .. "extra", Sorted(extra), Sorted(parts[5] or "", "&"))
    else
        Same(key .. "to hit", tostring(attack[2]), "false")
        if parts[3] and parts[3] ~= "" then
            local count, sides, flat = Damage(parts[3])
            Same(key .. "damage", DiceText(attack[3], attack[4], attack[5], attack[6]), DiceText(count, sides, flat, parts[4] or ""))
        end
        local stat, dc = roll:match("^save (%a+) (%d+)$")
        if dc then
            COMPARED = COMPARED + 1
            local said = (attack[7] or "") .. " " .. (attack.rider or "")
            if not said:find(("DC %s %s"):format(dc, R.STAT_NAMES[stat:upper()]), 1, true) then
                Differ(key .. "save", ("the note doesn't say DC %s %s"):format(dc, R.STAT_NAMES[stat:upper()]))
            end
        end
    end
end

local siteBeasts, count, unrolled = {}, 0, {}
for _, file in ipairs({ "beasts-1.txt", "beasts-2.txt" }) do
    for _, row in ipairs(ReadData(file)) do
        local name = row[2]
        siteBeasts[name] = true
        count = count + 1
        local beast, form, key = R.BEASTS[name], R.FORMS[R.BeastFormPassive(name)], "beast/" .. name .. "/"
        if beast then
            Same(key .. "cr", beast.cr, CR[row.cr] or tonumber(row.cr))
            Same(key .. "size", beast.size, SIZES[row.sz] or row.sz)
            Same(key .. "ac", beast.ac, row.ac)
            local speeds, siteSpeeds = { "walk " .. beast.speed }, row.spd
            -- The beast's own wording ("climbing and swimming 30 feet"), and the numbers
            -- the form moves with, which have to agree with it.
            for words, feet in (beast.moves or ""):gmatch("([%a ]+) (%d+) feet") do
                for word in words:gmatch("%a+") do
                    if MOVES[word] then
                        speeds[#speeds + 1] = MOVES[word] .. " " .. feet
                        if MOVES[word] ~= "burrow" then Same(key .. "form " .. MOVES[word], form[MOVES[word]], feet) end
                    end
                end
            end
            Same(key .. "speeds", Sorted(speeds), Sorted(siteSpeeds))
            Same(key .. "flies", tostring(beast.fly or false), tostring(siteSpeeds:find("fly") ~= nil))
            local scores = {}
            for score in row.abil:gmatch("%d+") do scores[#scores + 1] = score end
            for index, stat in ipairs(STATS) do Same(key .. stat, beast[stat:lower()], scores[index]) end
            -- Skills and saves with their bonuses: "perception+3,stealth+4".
            local skills, saves = {}, {}
            for _, skill in ipairs(beast.skills) do
                skills[#skills + 1] = ("%s%+d"):format(skill, beast.bonus and beast.bonus[skill] or 0)
            end
            for stat, bonus in pairs(beast.saves or {}) do saves[#saves + 1] = ("%s%+d"):format(stat, bonus) end
            Same(key .. "skills", Sorted(skills), Sorted(row.sk or ""))
            Same(key .. "saves", Sorted(saves), Sorted(row.sv or ""))
            local senses = {}
            for sense, feet in pairs(beast.senses) do senses[#senses + 1] = sense .. " " .. feet end
            Same(key .. "senses", Sorted(senses), Sorted(row.sn or ""))
            -- Attacks, by name, both ways round.
            local byName, seen = {}, {}
            for _, attack in ipairs(beast.attacks) do byName[attack[1]] = attack end
            for _, list in ipairs({ row.atk or "", row.ba or "" }) do
                for text in list:gmatch("[^;]+") do
                    local action = text:match("^([^:]+)"):gsub(" %(.+%)$", "")
                    seen[action] = true
                    if byName[action] then Action(key .. action .. "/", byName[action], text)
                    elseif text:find(":%-$") then unrolled[#unrolled + 1] = name .. ": " .. action
                    else Differ(key .. action .. "/missing", "an action on the site the form doesn't have") end
                end
            end
            for action in pairs(byName) do
                if not seen[action] then Differ(key .. action .. "/extra", "an attack of the form the site doesn't have") end
            end
        end
    end
end
BothWays("beast", siteBeasts, R.BEASTS)

print(("compared: %d beasts. Actions without a roll, told in the form's note: %s"):format(count, table.concat(unrolled, "; ")))
Finish("beasts")
