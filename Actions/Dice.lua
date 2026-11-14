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
-- Without a key held, the "Next roll" row on the sheet decides (see CycleRollMode).
-- Unless that row is locked, it goes back to normal once a d20 has been rolled with
-- it (see RollD20), so an ability that rolls no d20 doesn't use it up.
function ns.RollMode()
    if IsShiftKeyDown() then return "ADV" end
    if IsControlKeyDown() then return "DIS" end
    return RPSheet.rollMode
end
ns.ROLL_MODE_HELP = "Shift-click: advantage. Ctrl-click: disadvantage. Or set the Next roll row at the top of the sheet."

-- The "Next roll" row: normal -> advantage -> disadvantage -> normal.
-- `lock` keeps the chosen mode for every roll until it is changed.
function RPSheet:CycleRollMode(lock)
    if lock then
        -- Locking a normal roll makes no sense: start from advantage.
        if not self.rollMode then self.rollMode = "ADV" end
        self.rollModeLocked = not self.rollModeLocked
    else
        self.rollMode = (self.rollMode == nil and "ADV") or (self.rollMode == "ADV" and "DIS") or nil
        if not self.rollMode then self.rollModeLocked = false end
    end
    self:Refresh()
end

-- Rolls a d20, or two with advantage or disadvantage, and passes on the die that
-- counts plus a note such as " [advantage: 14, 6]" for the announcement.
function RPSheet:RollD20(mode, callback)
    if mode ~= "ADV" and mode ~= "DIS" then
        self:Roll(20, function(d20) callback(d20, "") end)
        return
    end
    -- The "Next roll" row is used up by this roll, unless it is locked.
    if self.rollMode and not self.rollModeLocked then
        self.rollMode = nil
        self:Refresh()
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
-- A feature that gives advantage on this roll applies by itself; with disadvantage
-- chosen on top, the two cancel out.
function RPSheet:RollCheck(label, mod, mode)
    local failed = self:AutoFail(label)
    if failed then
        self:Announce(("fails the %s without a roll (%s)."):format(ns.Mark(label), ns.Mark(failed)))
        return
    end
    -- Features, conditions and armor can give advantage or disadvantage by themselves.
    mode = self:ResolveMode(label, mode)
    -- Reliable Talent: on a skill you are proficient in, a low die counts as a 10.
    local reliable = (self:Sheet().skills[label] or 0) >= 1 and self:FeatureFlag("reliable")
    self:RollD20(mode, function(d20, note)
        if reliable and d20 < 10 then
            note = ("%s [rolled %d, counts as 10]"):format(note, d20)
            d20 = 10
        end
        self:Announce("rolls " .. ns.RollText.Check(ns.Mark(label), d20, mod, note))
    end)
end

-- How dice of a kind (see Rules.DICE_KINDS) are announced, and which passive bonus
-- applies to them.
function ns.DiceWord(kind)
    if kind == "TEMPHP" then return "temporary HP" end
    if kind == "OTHER" then return "bonus" end
    if kind == "HEALING" or kind == "SELFHEAL" then return "healing", "HEALING" end
    return "damage", "DAMAGE"
end

-- Dice that act on the character itself: healing raises HP, temporary HP replaces a
-- lower amount. Returns a note for the announcement, or nil for other dice.
function RPSheet:ApplyDice(kind, rolls, mod)
    local total = mod
    for _, roll in ipairs(rolls) do total = total + roll end
    total = math.max(0, total)
    local state = self:State()
    if kind == "SELFHEAL" or kind == "DRAIN" then
        local max = self:MaxHP()
        state.hp = math.min(max, (state.hp or max) + total)
        if total > 0 then self:ClearDeathSaves() end
        return ("now %d/%d HP"):format(state.hp, max)
    elseif kind == "TEMPHP" then
        state.tempHP = math.max(state.tempHP or 0, total)
        return ("now %d temporary HP"):format(state.tempHP)
    end
end
