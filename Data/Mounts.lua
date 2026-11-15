-- What an owned mount, vehicle or companion creature is made of, the limits that go
-- with riding, and the catalogue the lists fill (Data/MountList.lua, Data/Vehicles.lua).
-- The companion creatures' own rules are in Data/Companions.lua.
local _, ns = ...
local R = ns.Rules

-- An entry of sheet.mounts.
R.TEMPLATES.mount = {
    name = "", desc = "",
    kind = "MOUNT",    -- MOUNT, VEHICLE or COMPANION (Rules.MOUNT_KINDS)
    cost = 0,          -- copper pieces; 0 = no listed price
    speed = 0,         -- feet a turn on the ground; a vehicle has a travel pace instead
    fly = 0, swim = 0, climb = 0, -- its other ways of moving, in feet
    capacity = 0,      -- pounds it carries; a vehicle's cargo
    weight = 0,        -- pounds a drawn vehicle weighs itself
    travel = "",       -- a vehicle's pace on a journey: "4 mph"
    size = "L",        -- a mount's size (Rules.MOUNT_SIZES)
    riding = false,    -- in the saddle or aboard right now; one at a time
    family = "",       -- a companion creature's kind (Rules.COMPANIONS)
    loyalty = 0,       -- a companion creature's Loyalty Score
    called = false,    -- the companion is at your side; one at a time
}

R.MOUNT_KINDS = { MOUNT = "Mount", VEHICLE = "Vehicle", COMPANION = "Companion creature" }
R.MOUNT_KIND_ORDER = { "MOUNT", "VEHICLE", "COMPANION" }

-- Sizes from small to large. A mount has to be at least one size larger than its rider.
R.MOUNT_SIZES = { S = "Small", M = "Medium", L = "Large", H = "Huge" }
R.MOUNT_SIZE_ORDER = { "S", "M", "L", "H" }
R.SIZE_RANK = { S = 1, M = 2, L = 3, H = 4 }

R.DRAW_TIMES = 5            -- an animal pulls this many times what it carries, the vehicle included
R.EXOTIC_SADDLE = "Exotic Saddle" -- needed to ride a mount that flies or swims
R.FEED_COPPER, R.STABLE_COPPER = 5, 50 -- a day's feed and a day's stabling
R.BARDING_COST, R.BARDING_WEIGHT = 4, 2 -- armor made for a mount: times the price and the weight

-- Saddles, feed and fuel are carried like any gear: name, price in copper, pounds.
R.AddGear("Adventuring gear",
    "Exotic Saddle|6000|40;Military Saddle|2000|30;Riding Saddle|1000|25;Feed|5|10;Fuel|100|10")

---------------------------------------------------------------------------
-- The catalogue
---------------------------------------------------------------------------
-- R.MOUNTS[name] = the fields of the template that are not zero, and
--   group    the tab of the stable it is listed under (Rules.MOUNT_GROUPS)
--   renown   { score, faction, ... }: buying it takes that standing with one of them;
--            "ALLIANCE" or "HORDE" means any faction of that side
--   keep     true when it stops obeying once the standing is lost
--   unsold   true when it can't be bought at all
-- R.MOUNT_NAMES[group] lists a group's names in alphabetical order.
R.MOUNTS, R.MOUNT_NAMES = {}, {}
R.MOUNT_GROUPS = { "Mounts", "Drawn vehicles", "Powered vehicles", "Ships", "Companions" }
for _, group in ipairs(R.MOUNT_GROUPS) do R.MOUNT_NAMES[group] = {} end

function R.AddMount(group, name, entry)
    entry.group = group
    entry.kind = entry.kind or (group == "Mounts" and "MOUNT") or (group == "Companions" and "COMPANION") or "VEHICLE"
    R.MOUNTS[name] = entry
    table.insert(R.MOUNT_NAMES[group], name)
    table.sort(R.MOUNT_NAMES[group])
end

-- Something to ride: price in gold, feet a turn, pounds carried, a note, and `extra`
-- for size (Large when left out), fly, swim, climb, renown and keep.
function R.AddRide(name, gold, speed, capacity, desc, extra)
    local entry = { cost = gold * 100, speed = speed, capacity = capacity, desc = desc, size = "L" }
    for key, value in pairs(extra or {}) do entry[key] = value end
    R.AddMount("Mounts", name, entry)
end
