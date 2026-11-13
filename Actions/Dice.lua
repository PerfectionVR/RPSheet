-- Rolling dice. Rolls use the game's real /roll so others can verify them; the result
-- is read back from the system message. "Self only" rolls privately instead.
local _, ns = ...
local RPSheet = ns.addon

local pending -- the roll we are waiting on: { sides = "20", callback = function }

-- Lua pattern matching the game's "<name> rolls <n> (<low>-<high>)" message.
local rollPattern = "^" .. RANDOM_ROLL_RESULT
    :gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
    :gsub("%%s", "(.+)")
    :gsub("%%d", "(%%d+)") .. "$"

function RPSheet:IsRolling()
    return pending ~= nil
end

-- Rolls one die and passes the result to `callback`. Ignored while another roll is waiting.
function RPSheet:Roll(sides, callback)
    if self.db.profile.channel == "SELF" then
        callback(math.random(1, sides))
        return
    end
    if pending then return end
    local request = { sides = tostring(sides), callback = callback }
    pending = request
    RandomRoll(1, sides)
    C_Timer.After(3, function()
        if pending == request then
            pending = nil
            self.busy = false
            self:Print("Couldn't read the roll result from chat. Nothing was announced.")
        end
    end)
end

-- Rolls `count` dice one after another and passes the list of results on.
function RPSheet:RollDice(count, sides, callback, results)
    results = results or {}
    if #results >= count then
        callback(results)
        return
    end
    self:Roll(sides, function(value)
        results[#results + 1] = value
        self:RollDice(count, sides, callback, results)
    end)
end

-- Advantage ("ADV") or disadvantage ("DIS") from the keys held while clicking a roll:
-- Shift for advantage, Ctrl for disadvantage. Nil for a normal roll.
function ns.RollMode()
    if IsShiftKeyDown() then return "ADV" end
    if IsControlKeyDown() then return "DIS" end
end
ns.ROLL_MODE_HELP = "Shift-click: advantage. Ctrl-click: disadvantage."

-- Rolls a d20, or two with advantage or disadvantage, and passes on the die that
-- counts plus a note such as " [advantage: 14, 6]" for the announcement.
function RPSheet:RollD20(mode, callback)
    if mode ~= "ADV" and mode ~= "DIS" then
        self:Roll(20, function(d20) callback(d20, "") end)
        return
    end
    self:RollDice(2, 20, function(rolls)
        local kept = mode == "ADV" and math.max(rolls[1], rolls[2]) or math.min(rolls[1], rolls[2])
        callback(kept, (" [%s: %d, %d]"):format(mode == "ADV" and "advantage" or "disadvantage", rolls[1], rolls[2]))
    end)
end

function RPSheet:CHAT_MSG_SYSTEM(_, msg)
    if not pending or (issecretvalue and issecretvalue(msg)) then return end
    local name, roll, low, high = msg:match(rollPattern)
    if name == UnitName("player") and low == "1" and high == pending.sides then
        local callback = pending.callback
        pending = nil
        callback(tonumber(roll))
    end
end

---------------------------------------------------------------------------
-- Wording of results
---------------------------------------------------------------------------
ns.RollText = {}

-- e.g. "Stealth: 14 + 5 = 19", or with a note "Stealth: 14 [advantage: 14, 6] + 5 = 19"
function ns.RollText.Check(label, d20, mod, note)
    local text = ("%s: %d%s %s %d = %d"):format(label, d20, note or "", mod >= 0 and "+" or "-", math.abs(mod), d20 + mod)
    if d20 == 20 then
        text = text .. " (NATURAL 20!)"
    elseif d20 == 1 then
        text = text .. " (natural 1)"
    end
    return text
end

-- e.g. "damage 2d6 + 3: (5 + 2) + 3 = 10"
function ns.RollText.Dice(label, rolls, sides, mod)
    local sum = 0
    for _, value in ipairs(rolls) do sum = sum + value end
    local dice = table.concat(rolls, " + ")
    if #rolls > 1 then dice = "(" .. dice .. ")" end
    if mod == 0 then
        return ("%s %dd%d: %s = %d"):format(label, #rolls, sides, dice, sum)
    end
    local sign = mod >= 0 and "+" or "-"
    return ("%s %dd%d %s %d: %s %s %d = %d"):format(label, #rolls, sides, sign, math.abs(mod), dice, sign, math.abs(mod), sum + mod)
end

-- A plain d20 check: ability check, saving throw, skill, initiative, spell attack.
function RPSheet:RollCheck(label, mod, mode)
    self:RollD20(mode, function(d20, note)
        self:Announce("rolls " .. ns.RollText.Check(label, d20, mod, note))
    end)
end
