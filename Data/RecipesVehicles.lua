-- The vehicles an engineer can build (Data/Vehicles.lua): a journeyman the trike, an
-- expert the flying machine and the two motorcycles. A built vehicle goes to the
-- character's mounts and vehicles, not to its inventory. Building needs no standing
-- with a faction: that is what a seller asks.
--   R.VEHICLE_RECIPES[name] = { cost (materials, copper), days }
local _, ns = ...
local R = ns.Rules

R.VEHICLE_RECIPES = {}

-- Like plain gear: materials worth half the price and a day of work per 10 gp of
-- price. `materials` is given for the one that has no price, only a cost to build.
local function Vehicle(name, level, materials)
    local known = R.MOUNTS[name]
    if not known then return end
    local cost = materials or math.floor(known.cost / 2)
    R.VEHICLE_RECIPES[name] = { cost = cost, days = math.max(1, math.ceil(cost * 2 / R.CRAFT_COPPER_PER_DAY)) }
    local list = R.RECIPES.engineering
    list[#list + 1] = { name = name, level = level, basic = true, vehicle = true }
end

Vehicle("Goblin Trike", 3)
Vehicle("Flying Machine", 4, 200000)
Vehicle("Mechano-Hog", 4)
Vehicle("Mekgineer's Chopper", 4)
