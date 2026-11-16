-- Counting what a beast form can only do now and then (data in Data/Beasts.lua): an
-- action that recharges on a d6 rolled at the start of a turn, and one that is there
-- once a day. Using the row takes the use; a used row is refused. A right-click on a
-- recharging row rolls its d6. A long rest brings everything back, a short rest what
-- recharges. state.beastUsed[<key of the row>] = "day" or "recharge" while it is used up.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The limit of an ability made for a beast form: { key, day = true } or { key,
-- recharge = 5 }, or nil. The rows of one attack (plain and in a situation) share
-- its use; a follow-up with a limit of its own has its own.
local function Limit(ability)
    local name, kind, index, row = (ability.auto or ""):match("^form:(.+):(%a+)(%d+):?(%a*)$")
    local beast = name and R.BEASTS[name]
    if not beast or (kind ~= "attack" and kind ~= "extra") then return end
    local entry = (kind == "extra" and beast.extras or beast.attacks or {})[tonumber(index)]
    if not entry then return end
    local key = ("%s:%s%s"):format(name, kind, index)
    if row == "follow" then
        if not (entry.follow and entry.follow.day) then return end
        return { key = key .. ":follow", day = true }
    end
    if entry.day then return { key = key, day = true } end
    if entry.recharge then return { key = key, recharge = entry.recharge } end
end

local function Used(self)
    local state = self:State()
    if type(state.beastUsed) ~= "table" then state.beastUsed = {} end
    return state.beastUsed
end

local function From(limit)
    return limit.recharge >= 6 and "a 6" or ("%d or higher"):format(limit.recharge)
end

-- What the ability's row says after its name: "1/1 a day", "used, recharges on a 6".
-- Nil for an ability without such a limit.
function RPSheet:BeastUseText(ability)
    local limit = Limit(ability)
    if not limit then return end
    local used = Used(self)[limit.key]
    if limit.day then return ("%d/1 a day"):format(used and 0 or 1) end
    return used and ("used, recharges on %s"):format(From(limit)) or "ready"
end

-- True, after telling the player, when the ability is used up.
function RPSheet:BeastUseSpent(ability)
    local limit = Limit(ability)
    if not limit or not Used(self)[limit.key] then return false end
    self:Print(limit.day and ("%s is used up for today: a long rest brings it back."):format(ability.name)
        or ("%s is used up: right-click it at the start of your turn to roll for it. It comes back on %s, or with a rest."):format(ability.name, From(limit)))
    return true
end

-- Called when the ability has gone through.
function RPSheet:TakeBeastUse(ability)
    local limit = Limit(ability)
    if not limit then return end
    Used(self)[limit.key] = limit.day and "day" or "recharge"
    self:PopulateSoon() -- the row says so
end

-- A right-click on a row that recharges: rolls its d6 when it is used up. Returns
-- true when the click was this row's to take (rolled, or nothing to roll for).
function RPSheet:RollBeastRecharge(ability)
    local limit = Limit(ability)
    if not limit or not limit.recharge then return false end
    if not Used(self)[limit.key] then
        self:Print(("%s is ready: there is nothing to roll for."):format(ability.name))
        return true
    end
    if self.busy or self:IsRolling() then return true end
    self:Roll(6, function(rolled)
        local back = rolled >= limit.recharge
        if back then Used(self)[limit.key] = nil end
        self:Announce(("rolls to recharge %s: %d - %s."):format(ns.Mark(ability.name), rolled, back and "it is back" or "not yet"))
        self:PopulateSoon()
    end)
    return true
end

-- Rests: a long one brings every use back, a short one what recharges.
local LongRest, ShortRest = RPSheet.LongRest, RPSheet.ShortRest
function RPSheet:LongRest(...)
    self:State().beastUsed = {}
    return LongRest(self, ...)
end
function RPSheet:ShortRest(...)
    local used = Used(self)
    for key, kind in pairs(used) do
        if kind ~= "day" then used[key] = nil end -- only a long rest ends the day
    end
    return ShortRest(self, ...)
end
