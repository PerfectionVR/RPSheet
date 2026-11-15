-- Numbers worked out from the saved sheet: initiative and speed.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

function RPSheet:Initiative()
    return self:Mod("DEX") + self:Bonus("INIT")
end

-- `onFoot` leaves the mount out: the character's own speed.
function RPSheet:Speed(onFoot)
    if self:Immobile() then return 0 end
    -- In the saddle the mount's speed counts in place of your own (Sheet/Mounts.lua).
    local mount = not onFoot and self:RiddenMount()
    if mount then return (ns.MountPace(mount)) end
    -- An item can set the speed everything is added to, or multiply the outcome.
    local base, times = self:BaseSpeed(), self:EffectMultiplier("SPEED")
    local gift = self:CompanionSpeed() -- a loyal flying companion (Sheet/Companions.lua)
    if self:Form() then return math.max(0, base + self:Bonus("SPEED") + gift) * times end
    local speed = math.max(0, base + self:Bonus("SPEED") + gift - self:ArmorSpeedPenalty()) * times
    -- Hauling more than you can carry.
    if self:Overloaded() then speed = math.min(speed, R.OVERLOADED_SPEED) end
    return speed
end
