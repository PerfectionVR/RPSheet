-- Vehicles: the ones an animal pulls, the powered ones of goblin and gnomish make, and
-- ships. Prices are in copper pieces, cargo and weight in pounds (a ton is 2,000).
local _, ns = ...
local R = ns.Rules

R.FUEL_HOURS = 8 -- hours of travel one load of Fuel lasts a powered vehicle

-- Pulled by animals: its own weight counts against what they can pull.
local function Drawn(name, gold, weight, desc)
    R.AddMount("Drawn vehicles", name, { cost = gold * 100, weight = weight, desc = desc })
end
Drawn("Carriage", 100, 600, "A closed coach for passengers.")
Drawn("Cart", 15, 200, "Two wheels and a flat bed.")
Drawn("Chariot", 250, 100, "A light two-wheeled war vehicle.")
Drawn("Sled", 20, 300, "Runners for snow and ice.")
Drawn("Wagon", 35, 400, "Four wheels and room for a heavy load.")

-- Powered: they move at their own pace on a journey and burn Fuel.
local function Powered(name, gold, mph, cargo, desc, extra)
    local entry = { cost = gold * 100, travel = mph .. " mph", capacity = cargo, desc = desc .. " Armor Class 19, 27 hit points." }
    for key, value in pairs(extra or {}) do entry[key] = value end
    R.AddMount("Powered vehicles", name, entry)
end
Powered("Flying Machine", 0, 4, 300, "A small gyrocopter for its pilot alone. It is not for sale: an expert engineer builds it from 2,000 gold of materials.", { unsold = true })
Powered("Goblin Trike", 400, 3, 600, "A three-wheeled motor vehicle with wood panelling, for its driver alone.", { renown = { 10, "Bilgewater Cartel", "Steamwheedle Cartel" } })
Powered("Mechano-Hog", 4000, 4, 800, "A heavy motorcycle of Horde make. A sidecar takes one passenger.", { renown = { 10, "HORDE" } })
Powered("Mekgineer's Chopper", 4000, 4, 800, "A heavy motorcycle of Alliance make. A sidecar takes one passenger.", { renown = { 10, "ALLIANCE" } })

-- Ships: travel pace, crew needed, passengers in hammocks, cargo in tons, Armor Class,
-- hit points, and the damage a single hit must reach to harm it (0 = none).
local function Ship(name, gold, mph, crew, passengers, tons, ac, hp, threshold, desc)
    local parts = { desc, ("Crew %d"):format(crew) }
    if passengers > 0 then parts[#parts + 1] = ("%d passengers"):format(passengers) end
    parts[#parts + 1] = ("Armor Class %d, %d hit points"):format(ac, hp)
    if threshold > 0 then parts[#parts + 1] = ("hits of less than %d damage do nothing"):format(threshold) end
    R.AddMount("Ships", name, {
        cost = gold * 100, travel = mph .. " mph", capacity = tons * 2000,
        desc = parts[1] .. " " .. table.concat(parts, ", ", 2) .. ".",
    })
end
Ship("Airship", 40000, "8", 10, 20, 1, 13, 300, 0, "Flies.")
Ship("Galley", 30000, "4", 80, 0, 150, 15, 500, 20, "A great oared ship.")
Ship("Keelboat", 3000, "1", 1, 6, 0.5, 15, 100, 10, "For rivers and lakes; one person can handle it.")
Ship("Longship", 10000, "3", 40, 150, 10, 15, 300, 15, "Oars and a sail.")
Ship("Rowboat", 50, "1.5", 1, 3, 0, 11, 50, 0, "For rivers and lakes. It weighs 100 pounds and can be carried.")
Ship("Sailing Ship", 10000, "2", 20, 20, 100, 15, 300, 15, "A trading ship under sail.")
Ship("Warship", 25000, "2.5", 60, 60, 200, 15, 500, 20, "Built to fight at sea.")
R.MOUNTS["Rowboat"].weight = 100
