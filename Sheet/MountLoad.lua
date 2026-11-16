-- What a mount carries and a team pulls, against what they can. A creature that
-- carries more than it can moves 5 feet a turn at most: that holds for the mount under
-- the character as it does for the character on foot. Animals in harness move five
-- times what they carry, the vehicle's own weight included, and their capacities add
-- up; more than that they can't move at all. Saved for this:
--   sheet.bodyWeight   pounds the character weighs; 0 = not said, and only gear counts
--   mount.hitched      an animal in harness, or the drawn vehicle it is harnessed to
--   mount.load         pounds of cargo on a vehicle
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local NONE = {}

-- Pounds the mount under the character has to carry: everything carried, and the
-- character itself where its weight is said.
function RPSheet:RiderLoad()
    return math.max(0, tonumber(self:Sheet().bodyWeight) or 0) + self:CarriedWeight()
end

-- True for an animal that can be put in harness: a mount that is not a thing.
function ns.CanPull(entry)
    return entry.kind == "MOUNT" and entry.name ~= "" and (entry.capacity or 0) > 0 and not ns.MountIsThing(entry)
end

-- True for a vehicle that animals pull: one without a pace of its own.
function ns.IsDrawn(entry)
    return entry.kind == "VEHICLE" and entry.name ~= "" and (entry.travel or "") == ""
end

-- The drawn vehicle in harness and the animals harnessed to it. No vehicle, or no
-- animal, and there is no team.
function RPSheet:Team()
    local vehicle, animals = nil, {}
    for _, entry in ipairs(self:Sheet().mounts or NONE) do
        if entry.hitched and ns.IsDrawn(entry) then vehicle = vehicle or entry end
        if entry.hitched and ns.CanPull(entry) then animals[#animals + 1] = entry end
    end
    if vehicle and #animals > 0 then return vehicle, animals end
end

-- Pounds the team has to move (the vehicle and what is on it) and pounds it can.
function RPSheet:TeamLoad()
    local vehicle, animals = self:Team()
    if not vehicle then return 0, 0 end
    local limit = 0
    for _, animal in ipairs(animals) do limit = limit + animal.capacity * R.DRAW_TIMES end
    return (vehicle.weight or 0) + (vehicle.load or 0), limit
end

-- What holds a ridden mount back: the most feet it moves and why, in words that
-- finish "it ...". Nothing when it moves freely. A mount without a listed capacity
-- (0) is not judged.
function RPSheet:MountHeld(mount)
    if mount.hitched and ns.CanPull(mount) then
        local pulled, limit = self:TeamLoad()
        local vehicle = self:Team()
        if vehicle and pulled > limit then
            return 0, ("is harnessed to the %s, which with its load weighs %d lb.: more than the %d lb. its team can move"):format(vehicle.name, pulled, limit)
        end
    end
    local capacity, load = mount.capacity or 0, self:RiderLoad()
    if capacity > 0 and load > capacity then
        return R.OVERLOADED_SPEED, ("carries %.1f lb., more than the %d lb. it can"):format(load, capacity)
    end
end

-- Feet a turn the character gets out of the mount it rides: at its pace, or with
-- `kind` its swimming, climbing or flying speed. An overloaded mount is held to 5
-- feet, one harnessed to more than its team can move to none.
function RPSheet:MountSpeed(mount, kind)
    local feet = kind and (mount[kind] or 0) or (ns.MountPace(mount))
    local limit = self:MountHeld(mount)
    return limit and math.min(feet, limit) or feet
end

-- The Speed row's explanation while riding (RPSheet:ExplainSpeed, Sheet/ExplainDefense.lua).
function RPSheet:MountSpeedText(mount)
    local feet, mode = ns.MountPace(mount)
    local moves = (mode ~= "" and (mode == "fly" and "flying; it moves " or "swimming; it moves ") or "it moves ") .. ns.MountSpeeds(mount)
    local limit, why = self:MountHeld(mount)
    if limit then
        return ("Speed |cffffd100%d ft|r: you are riding %s, and its speed counts in place of your own (%s). But it %s, which holds it to %d feet. On foot your speed is %d ft."):format(
            math.min(feet, limit), mount.name, moves, why, limit, self:Speed(true))
    end
    return ("Speed |cffffd100%d ft|r: you are riding %s, and its speed counts in place of your own (%s). Your armor, your load and your exhaustion don't slow it. On foot your speed is %d ft."):format(
        feet, mount.name, moves, self:Speed(true))
end

-- "It " and what holds the ridden mount back, for a tooltip; "" when nothing does.
function RPSheet:MountHeldNote(mount)
    local limit, why = self:MountHeld(mount)
    return limit and ("It %s, which holds it to %d feet."):format(why, limit) or ""
end

-- Puts an animal in harness or takes it out; for a drawn vehicle, makes it the one
-- in harness (one at a time) or stands it aside.
function RPSheet:SetHitched(entry, on)
    if on and ns.IsDrawn(entry) then
        for _, other in ipairs(self:Mounts()) do
            if ns.IsDrawn(other) then other.hitched = false end
        end
    end
    entry.hitched = on and (ns.IsDrawn(entry) or ns.CanPull(entry)) or false
end

-- What is wrong with a vehicle's load, in a sentence, or nil: more cargo than a
-- powered vehicle or ship takes, or more than the team in harness can move.
function RPSheet:VehicleLoadProblem(entry)
    if entry.kind ~= "VEHICLE" then return end
    if not ns.IsDrawn(entry) then
        if (entry.capacity or 0) > 0 and (entry.load or 0) > entry.capacity then
            return ("It is loaded with %d lb., more than the %d lb. of cargo it takes."):format(entry.load, entry.capacity)
        end
        return
    end
    local vehicle = self:Team()
    local pulled, limit = self:TeamLoad()
    if vehicle == entry and pulled > limit then
        return ("With its load it weighs %d lb., more than the %d lb. its team can move: it stands still until it is lightened or more animals are harnessed."):format(pulled, limit)
    end
end
