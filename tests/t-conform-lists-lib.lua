-- t-conform-classes.lua: the lists of options (invocations, Metamagic, maneuvers,
-- Fighting Styles) and what each asks, and the summary line.
local C = Conform

local function Options(site, level, name)
    for _, feature in ipairs(site.features[level]) do
        if feature.name == name then return feature.top end
    end
    return {}
end

local function SameList(id, addon, site)
    local have, want = {}, {}
    for _, name in ipairs(addon) do have[name] = true end
    for _, name in ipairs(site) do want[name] = true end
    for name in pairs(want) do
        C.compared = C.compared + 1
        if not have[name] then C.Differs(id .. " " .. name, "on the site, not in the addon") end
    end
    for name in pairs(have) do
        if not want[name] then C.Differs(id .. " " .. name, "in the addon, not on the site") end
    end
end

function C.Lists()
    local invocations = {}
    for name in pairs(R.PICK_LISTS.invocations.items) do
        if not name:find(" %(%a+%)$") then invocations[#invocations + 1] = name end -- (taken again)
    end
    SameList("invocation", invocations, Options(Site.classes["Warlock|WoW"], 1, "Eldritch Invocation Options"))
    SameList("metamagic", R.PICK_LISTS.metamagic.order, Options(Site.classes["Evoker|WoW"], 2, "Metamagic Options"))
    SameList("maneuver", R.MANEUVER_ORDER, Options(Site.subclasses["Warrior|Battle Master"], 3, "Maneuver Options"))
    -- the Fighting Styles only some classes can take
    for id, site in pairs(Site.classes) do
        local key = id:match("^(.*)|WoW$")
        for _, feature in ipairs(key and site.features[2] or {}) do
            for _, style in ipairs(feature.name == "Fighting Style" and feature.top or {}) do
                local data = R.FIGHTING_STYLES[style]
                C.compared = C.compared + 1
                if not data then C.Differs(("%s fighting style %s"):format(key, style), "on the site, not in the addon")
                elseif not data.base and not data.class then C.Differs(("%s fighting style %s"):format(key, style), "open to every class in the addon") end
            end
        end
    end
end

-- What each option asks and costs: an invocation's level and the invocation it builds
-- on, a Metamagic option's Sorcery Points. The lists themselves are compared again,
-- from the options file this time.
function C.Options()
    local function Names_(set) local out = {} for name in pairs(set) do out[#out + 1] = name end return out end
    local invocations = {}
    for name, item in pairs(R.PICK_LISTS.invocations.items) do
        if not name:find(" %(%a+%)$") then
            invocations[#invocations + 1] = name
            local site = Site.options.EI[name]
            if site then
                C.Same("invocation " .. name .. " level", tostring(item.level), tostring(site.level))
                C.Same("invocation " .. name .. " builds on", tostring(item.needs):lower(), tostring(site.needs))
            end
        end
    end
    SameList("invocation (options file)", invocations, Names_(Site.options.EI))
    for name, item in pairs(R.PICK_LISTS.metamagic.items) do
        local site = Site.options.MM[name]
        if site then C.Same("metamagic " .. name .. " cost", tostring(item.cost), tostring(site.cost)) end
    end
    SameList("metamagic (options file)", R.PICK_LISTS.metamagic.order, Names_(Site.options.MM))
    SameList("maneuver (options file)", R.MANEUVER_ORDER, Names_(Site.options["MV:B"]))
end

function C.Summary()
    for id in pairs(Names.ALLOW) do
        if not C.used[id] and not C.partial then Problem("allow-list entry no longer needed: " .. id) end
    end
    local problems = 0
    for _ in pairs(PROBLEMS) do problems = problems + 1 end
    print(("class conformance: %d comparisons, %d site features (%d by a named map, %d growing at a later level), %d helper entries explained, %d allowed differences, %d problems")
        :format(C.compared + C.features, C.features, C.merged, C.grown, C.extras, C.allowed, problems))
end
