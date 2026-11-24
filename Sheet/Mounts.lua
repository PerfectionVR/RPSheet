-- The mounts, vehicles and companion creatures the character owns (sheet.mounts):
-- which one is ridden and what that changes, why one can't be ridden, the standing a
-- seller asks for, and keeping the saved list well-formed. Adding and buying is in
-- Sheet/MountStore.lua; the companion creatures' own numbers in Sheet/Companions.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local NONE = {}
local CRAWL = 10 -- a mount that walks slower than this is ridden for how it swims

-- The owned list; older characters get an empty one.
function RPSheet:Mounts()
    local sheet = self:Sheet()
    if type(sheet.mounts) ~= "table" then sheet.mounts = {} end
    return sheet.mounts
end

---------------------------------------------------------------------------
-- Speed
---------------------------------------------------------------------------
-- The speed a rider gets out of a mount, in feet, and how: "fly", "swim" or "" for
-- on the ground. A flyer is ridden in the air; a swimmer counts as one only when it
-- can hardly walk.
function ns.MountPace(entry)
    local walk, fly, swim = entry.speed or 0, entry.fly or 0, entry.swim or 0
    if fly > 0 then return fly, "fly" end
    if walk < CRAWL and swim > walk then return swim, "swim" end
    return walk, ""
end

-- "30 ft, fly 80 ft" for a mount; "4 mph" for a vehicle; "" when it has neither.
function ns.MountSpeeds(entry)
    local parts = {}
    if (entry.speed or 0) > 0 then parts[#parts + 1] = entry.speed .. " ft" end
    for _, mode in ipairs({ "fly", "swim", "climb" }) do
        if (entry[mode] or 0) > 0 then parts[#parts + 1] = ("%s %d ft"):format(mode, entry[mode]) end
    end
    if (entry.travel or "") ~= "" then parts[#parts + 1] = entry.travel end
    return table.concat(parts, ", ")
end

---------------------------------------------------------------------------
-- Riding
---------------------------------------------------------------------------
-- The mount or vehicle the character is on right now, if any.
function RPSheet:Riding()
    for _, entry in ipairs(self:Sheet().mounts or NONE) do
        if entry.riding and entry.name ~= "" and entry.kind ~= "COMPANION" then return entry end
    end
end

-- The mount whose speed counts in place of the character's own (RPSheet:Speed).
-- Aboard a vehicle nothing changes on a turn: it only has a pace for journeys.
function RPSheet:RiddenMount()
    local entry = self:Riding()
    if entry and entry.kind == "MOUNT" and ns.MountPace(entry) > 0 then return entry end
end

-- True for a listed mount that is a thing and not an animal, such as a flying carpet:
-- a rider of any size sits on it, and it takes no saddle.
function ns.MountIsThing(entry)
    local known = R.MOUNTS[entry.name]
    return entry.kind == "MOUNT" and known ~= nil and known.thing == true
end

-- True for a mount that needs the saddle made for flyers and swimmers.
function ns.NeedsExoticSaddle(entry)
    if ns.MountIsThing(entry) then return false end
    return entry.kind == "MOUNT" and ((entry.fly or 0) > 0 or (entry.swim or 0) > 0)
end

-- Pounds an animal can pull in a drawn vehicle, on top of the vehicle itself.
function ns.PullLimit(animal, vehicle)
    return (animal.capacity or 0) * R.DRAW_TIMES - (vehicle.weight or 0)
end

-- Why the character can't get on, in a few words; nil when nothing stands in the way.
function RPSheet:MountRefusal(entry)
    local sheet = self:Sheet()
    if entry.kind == "COMPANION" then return "a companion creature is too small to ride" end
    if entry.kind == "VEHICLE" then
        return (entry.travel or "") == "" and "an animal pulls it: ride or lead the animal" or nil
    end
    if not ns.MountIsThing(entry) and (R.SIZE_RANK[entry.size] or 3) <= (R.SIZE_RANK[sheet.size] or 2) then
        return ("a mount has to be at least one size larger than you, and it is %s"):format((R.MOUNT_SIZES[entry.size] or "Large"):lower())
    end
    if ns.NeedsExoticSaddle(entry) and not self:CarriedItem(R.EXOTIC_SADDLE) then
        return ("a mount that flies or swims needs an %s, and you have none"):format(R.EXOTIC_SADDLE)
    end
    local known = R.MOUNTS[entry.name]
    if known and known.keep then
        local met, need = ns.MountRenown(sheet, entry.name)
        if not met then return ("it no longer obeys you: that takes %s"):format(need) end
    end
end

---------------------------------------------------------------------------
-- Renown a seller asks for
---------------------------------------------------------------------------
-- The character's standing with a faction, or the best with any faction of a side.
local function Standing(sheet, who)
    local renown, best = type(sheet.renown) == "table" and sheet.renown or NONE, 0
    for _, faction in ipairs(R.FACTIONS[who] or { who }) do
        best = math.max(best, tonumber(renown[faction]) or 0)
    end
    return best
end

-- Whether the character may buy the listed mount `name`, and the standing it takes in
-- words ("renown 10 with Huojin or Tushui"). True and nothing when anyone may.
function ns.MountRenown(sheet, name)
    local need = R.MOUNTS[name] and R.MOUNTS[name].renown
    if not need then return true end
    local met, names = false, {}
    for index = 2, #need do
        local who = need[index]
        met = met or Standing(sheet, who) >= need[1]
        names[#names + 1] = R.SIDE_NAMES[who] and ("any faction of the " .. R.SIDE_NAMES[who]) or who
    end
    return met, ("renown %d with %s"):format(need[1], table.concat(names, " or "))
end

---------------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------------
local Whole = ns.Util.Whole

-- Makes the owned list of a saved or imported sheet well-formed: known kinds, whole
-- numbers, one mount ridden and one companion out at most.
function ns.NormalizeMounts(sheet)
    if type(sheet.mounts) ~= "table" then sheet.mounts = {} end
    local riding, called, harnessed = false, false, false
    sheet.bodyWeight = Whole(sheet.bodyWeight, 999) -- what the character weighs, for its mount (Sheet/MountLoad.lua)
    for _, entry in ipairs(sheet.mounts) do
        if not R.MOUNT_KINDS[entry.kind] then entry.kind = "MOUNT" end
        if not R.MOUNT_SIZES[entry.size] then entry.size = "L" end
        if not R.COMPANIONS[entry.family] then entry.family = "" end
        for _, key in ipairs({ "speed", "fly", "swim", "climb" }) do entry[key] = Whole(entry[key], 999) end
        entry.cost, entry.capacity, entry.weight = Whole(entry.cost, 99999999), Whole(entry.capacity, 999999), Whole(entry.weight, 99999)
        entry.load = entry.kind == "VEHICLE" and Whole(entry.load, 999999) or 0
        -- In harness: an animal that can pull, or one drawn vehicle.
        local drawn = ns.IsDrawn(entry)
        entry.hitched = entry.hitched == true and (ns.CanPull(entry) or (drawn and not harnessed))
        harnessed = harnessed or (drawn and entry.hitched)
        entry.loyalty = Whole(entry.loyalty, R.LOYALTY_MAX)
        entry.riding = entry.riding == true and entry.kind ~= "COMPANION" and not riding
        entry.called = entry.called == true and entry.kind == "COMPANION" and not called
        riding, called = riding or entry.riding, called or entry.called
    end
end
