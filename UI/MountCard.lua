-- What is said about a mount, vehicle or companion creature: in its tooltip on the
-- sheet (UI/MountSection.lua) and in its block in the stable (UI/MountBrowser.lua).
local _, ns = ...
local R = ns.Rules
local UI = ns.UI

local RED = "|cffff5555"

local function MountLines(self, lines, about)
    -- A flying carpet and the like: no size to fit, no saddle, nothing to hitch.
    if ns.MountIsThing(about) then
        lines[#lines + 1] = ("Something you ride that is not an animal: a rider of any size, no saddle. Speed %s."):format(ns.MountSpeeds(about))
        if about.capacity > 0 then lines[#lines + 1] = ("Carries %d lb."):format(about.capacity) end
        return
    end
    lines[#lines + 1] = ("%s mount. Speed %s."):format(R.MOUNT_SIZES[about.size] or "Large", ns.MountSpeeds(about) ~= "" and ns.MountSpeeds(about) or "not set")
    if about.capacity > 0 then
        lines[#lines + 1] = ("Carries %d lb. In %s to a drawn vehicle it moves %d lb., the vehicle included."):format(about.capacity, ns.Term("Harness", "harness"), about.capacity * R.DRAW_TIMES)
    end
    if (R.SIZE_RANK[about.size] or 3) <= (R.SIZE_RANK[self:Sheet().size] or 2) then
        lines[#lines + 1] = RED .. "Too small for you to ride: a mount has to be at least one size larger than its rider. It can still carry and pull.|r"
    end
    if ns.NeedsExoticSaddle(about) then
        lines[#lines + 1] = (self:CarriedItem(R.EXOTIC_SADDLE) and "" or RED)
            .. ("Riding a mount that flies or swims takes an %s (item browser, Gear).|r"):format(R.EXOTIC_SADDLE)
    end
end

local function VehicleLines(self, lines, about, known)
    if about.travel ~= "" then
        lines[#lines + 1] = ("Travels at %s. Those aboard don't choose a travel pace."):format(about.travel)
        if about.capacity > 0 then lines[#lines + 1] = ("Cargo: %d lb.%s"):format(about.capacity, about.load > 0 and (" Loaded with %d lb."):format(about.load) or "") end
        if known and known.group == "Powered vehicles" then
            lines[#lines + 1] = ("It burns Fuel: one load (item browser, Gear) lasts %d hours of travel."):format(R.FUEL_HOURS)
        end
        return
    end
    lines[#lines + 1] = ("Pulled by animals in %s. It weighs %d lb.; an animal pulls %d times what it carries, the vehicle included, and a team adds up."):format(ns.Term("Harness", "harness"), about.weight, R.DRAW_TIMES)
    if about.load > 0 then lines[#lines + 1] = ("Loaded with %d lb."):format(about.load) end
    for _, animal in ipairs(self:Sheet().mounts or {}) do
        if animal.kind == "MOUNT" and animal.name ~= "" and animal.capacity > 0 and not ns.MountIsThing(animal) then
            local load = ns.PullLimit(animal, about)
            lines[#lines + 1] = ("%sBehind your %s: a load of up to %d lb.|r"):format(load < 0 and RED or UI.GREEN, animal.name, math.max(0, load))
        end
    end
end

local function CompanionLines(self, lines, about, owned)
    local family = R.COMPANIONS[about.family]
    lines[#lines + 1] = family and ("%s companion creature."):format(about.family) or "Companion creature. Its kind is not set."
    if owned then
        local cap = self:LoyaltyCap()
        lines[#lines + 1] = ("Loyalty %s%d|r of at most %d (your Charisma score)."):format(about.loyalty > cap and RED or UI.ACCENT, about.loyalty, cap)
    end
    if family then
        local given = owned and about.called and about.loyalty >= R.LOYALTY_GIFT
        lines[#lines + 1] = ("%sGift at loyalty %d, while it is out: %s|r"):format(given and UI.GREEN or UI.GREY, R.LOYALTY_GIFT, family.gift)
    end
end

-- Lines for the one called `name`. `entry` is the owned entry when there is one;
-- otherwise the catalogue describes it.
function UI.MountLines(self, name, entry)
    local known, lines = R.MOUNTS[name], {}
    local about = entry or ns.NewMount(name)
    if about.kind == "MOUNT" then
        MountLines(self, lines, about)
    elseif about.kind == "VEHICLE" then
        VehicleLines(self, lines, about, known)
    else
        CompanionLines(self, lines, about, entry ~= nil)
    end
    -- An owned one: in harness, and whether what it carries or pulls is too much.
    if entry then
        if entry.hitched then
            lines[#lines + 1] = ns.Term("Harness", "In harness") .. UI.GREY
                .. (about.kind == "VEHICLE" and ": your harnessed animals pull it.|r" or ": it pulls your harnessed vehicle.|r")
        end
        local problem = self:VehicleLoadProblem(entry)
        if not problem and entry.riding and about.kind == "MOUNT" then problem = self:MountHeldNote(entry) end
        if problem and problem ~= "" then lines[#lines + 1] = RED .. problem .. "|r" end
    end
    if about.desc ~= "" then lines[#lines + 1] = about.desc end

    -- What a seller asks: standing, then money.
    local met, need = ns.MountRenown(self:Sheet(), name)
    if need then
        local keep = known.keep and " It only obeys you while you have that." or ""
        lines[#lines + 1] = ("%s%s those with %s.%s|r"):format(met and UI.GREY or RED, known.unsold and "Only for" or "Sold to", need, keep)
    end
    if known and known.unsold and not entry then
        lines[#lines + 1] = UI.GREY .. "Not for sale: Add puts it in your stable once you have made, found or summoned it.|r"
    elseif about.cost > 0 then
        lines[#lines + 1] = UI.GREY .. ns.CoinText(about.cost) .. "|r"
    elseif about.kind == "COMPANION" and not entry then
        lines[#lines + 1] = UI.GREY .. "No listed price: a few gold from a merchant, a reward or a find, as the DM says.|r"
    end
    return lines
end
