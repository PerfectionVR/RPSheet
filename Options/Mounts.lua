-- "Mounts and companions" page under Customize: one page per owned mount, vehicle or
-- companion creature, where anything can be set. What goes beyond the rules is said
-- in red; the sheet and the stable hold to them.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local With = Opt.With

-- What stands in the way of this entry as it is set now.
local function Status(entry)
    local lines = {}
    if entry.kind == "COMPANION" then
        local cap = RPSheet:LoyaltyCap()
        if entry.loyalty > cap then lines[#lines + 1] = ("Its loyalty can't go above your Charisma score (%d)."):format(cap) end
        if entry.family == "" then lines[#lines + 1] = "Pick what kind of companion it is: its gift depends on that." end
    else
        local why = RPSheet:MountRefusal(entry)
        if why then lines[#lines + 1] = ("You can't get on from the sheet: %s."):format(why) end
    end
    return #lines > 0 and (Opt.RED .. table.concat(lines, "\n") .. "|r\n") or ""
end

local function Number(order, name, key, high, desc, hidden, entry)
    return {
        type = "input", order = order, width = 0.7, name = name, desc = desc, hidden = hidden,
        get = function() return tostring(entry[key]) end,
        set = function(_, value)
            entry[key] = math.max(0, math.min(high, math.floor(tonumber(value) or 0)))
            Opt.Changed()
        end,
    }
end

local function Build(entry)
    local function self() return entry end
    local function NotMount() return entry.kind ~= "MOUNT" end
    local function NotVehicle() return entry.kind ~= "VEHICLE" end
    local function NotCompanion() return entry.kind ~= "COMPANION" end
    local function IsCompanion() return entry.kind == "COMPANION" end
    -- Switching one on switches the others off: one mount ridden, one companion out.
    local function Only(key)
        return function(_, value)
            for _, other in ipairs(RPSheet:Mounts()) do other[key] = false end
            entry[key] = value
            Opt.Changed()
        end
    end
    return {
        status = { type = "description", order = 0.5, fontSize = "medium", name = function() return Status(entry) end },
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        kind = With({ type = "select", order = 2, name = "It is a", values = R.MOUNT_KINDS, sorting = R.MOUNT_KIND_ORDER }, self, "kind"),
        cost = {
            type = "input", order = 3, width = 0.8, name = "Price", desc = "What it cost, written like 75 gp. Only a note here: nothing is paid.",
            get = function() return entry.cost > 0 and ns.CoinText(entry.cost) or "" end,
            set = function(_, value)
                entry.cost = ns.ParseCoins(value) or 0
                Opt.Changed()
            end,
        },
        desc = With({ type = "input", order = 4, width = "full", multiline = 2, name = "Note" }, self, "desc", true),
        riding = {
            type = "toggle", order = 5, hidden = IsCompanion,
            name = function() return entry.kind == "VEHICLE" and "Aboard" or "Riding" end,
            desc = "You are on it right now. A mount's speed then counts in place of your own. You can also click it on the sheet, which checks that you can.",
            get = function() return entry.riding end, set = Only("riding"),
        },
        size = With({
            type = "select", order = 10, name = "Size", hidden = NotMount, values = R.MOUNT_SIZES, sorting = R.MOUNT_SIZE_ORDER,
            desc = "A mount has to be at least one size larger than its rider.",
        }, self, "size"),
        speed = Number(11, "Speed (ft)", "speed", 999, "Feet it moves in a turn on the ground.", NotMount, entry),
        fly = Number(12, "Flying (ft)", "fly", 999, "Its flying speed; 0 when it doesn't fly. A flyer is ridden at this speed.", NotMount, entry),
        swim = Number(13, "Swimming (ft)", "swim", 999, "Its swimming speed; 0 when it has none. It counts as your speed only when the mount can hardly walk.", NotMount, entry),
        climb = Number(14, "Climbing (ft)", "climb", 999, "Its climbing speed; 0 when it has none.", NotMount, entry),
        capacity = Number(15, "Carries (lb.)", "capacity", 999999, "Pounds a mount carries, or a vehicle's cargo. Pulling a vehicle, an animal moves five times as much.", IsCompanion, entry),
        travel = With({
            type = "input", order = 20, width = 0.7, name = "Travel pace", hidden = NotVehicle,
            desc = "How fast it travels, such as 4 mph. Leave it empty for a vehicle that animals pull.",
        }, self, "travel", true),
        weight = Number(21, "Weight (lb.)", "weight", 99999, "What a drawn vehicle weighs itself: it counts against what the animals can pull.", NotVehicle, entry),
        family = With({
            type = "select", order = 30, name = "Kind of companion", hidden = NotCompanion,
            values = function() return (Opt.ListMap(R.COMPANION_ORDER, true)) end,
            sorting = function() return (select(2, Opt.ListMap(R.COMPANION_ORDER, true))) end,
        }, self, "family"),
        loyalty = With({
            type = "range", order = 31, min = 0, max = R.LOYALTY_MAX, step = 1, name = "Loyalty", hidden = NotCompanion, desc = R.LOYALTY_HELP,
        }, self, "loyalty"),
        called = {
            type = "toggle", order = 32, name = "Out", hidden = NotCompanion, desc = R.COMPANION_HELP,
            get = function() return entry.called end, set = Only("called"),
        },
        gift = {
            type = "description", order = 33, hidden = NotCompanion,
            name = function()
                local family = R.COMPANIONS[entry.family]
                return family and ("\n%s\n%sGift at loyalty %d, while it is out:|r %s"):format(family.desc, Opt.GOLD, R.LOYALTY_GIFT, family.gift) or ""
            end,
        },
    }
end

Opt.lists.mounts = {
    extra = function(args)
        args.browse = {
            type = "execute", order = 0.5, name = "Browse the stable", width = "double",
            desc = "Opens the stable: what you own and every listed mount, vehicle and companion creature as a block, with buttons to add, buy, ride and remove it.",
            func = function() RPSheet:ToggleMountBrowser() end,
        }
    end,
    order = 5.6, title = "Mounts and companions", noun = "mount", template = R.TEMPLATES.mount, build = Build,
    help = "The mounts, vehicles and companion creatures you own. Listed ones are added and bought in the stable; one of your own is added here as an empty mount to fill in, and turned into a vehicle or a companion creature with \"It is a\".\n",
}
