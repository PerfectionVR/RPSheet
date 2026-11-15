-- t-conform-classes.lua: what a class has at every level alike (hit die, saving
-- throws, skills, training, the kind of caster), and the multiclassing rules.
local C = Conform
local Sorted = C.Sorted

local CASTER = { full = "FULL", artificer = "HALF", pact = "PACT", [""] = "nil" } -- (the site files a 2024 half caster, who rounds up, under "artificer")

function C.Statics(key, class, site)
    C.Same(key .. " base class", class.base, site.base)
    C.Same(key .. " hero class", tostring(class.hero == true), tostring(site.hero))
    C.Same(key .. " hit die", class.hitDie, site.lines.hd[1])
    C.Same(key .. " saving throws", Sorted(class.saves, true), Sorted(Site.Split(site.lines.saves[1], ",")))
    C.Same(key .. " skill picks", class.skillCount, site.lines.skills[1])
    C.Same(key .. " skill list", Sorted(class.skills, true), Sorted(Site.Split(site.lines.skills[2], ",")))
    C.Same(key .. " caster", tostring(class.caster), CASTER[site.lines.caster[1]])
    C.Same(key .. " spellcasting ability", (class.cast or ""):lower(), site.lines.caster[2])
    C.Same(key .. " class tools", Sorted(R.CLASS_TOOLS[class.base] or {}), site.lines.tools[1])
    local has = {}
    for level = 1, 20 do for _, feature in ipairs(site.features[level]) do has[feature.name] = has[feature.name] or level end end
    C.Same(key .. " Unarmored Defense", tostring(class.unarmored ~= nil), tostring(has["Unarmored Defense"] == 1))
    C.Same(key .. " Spellcasting feature", tostring(class.caster == "FULL" or class.caster == "HALF"), tostring(has["Spellcasting"] == 1))
    C.Same(key .. " Pact Magic feature", tostring(class.caster == "PACT"), tostring(has["Pact Magic"] == 1))
    -- armor training
    local training, want = ns.ArmorTraining(key, {}), {}
    for _, kind in ipairs(Site.Split(site.lines.armor[1], ",")) do want[kind] = true end
    for _, kind in ipairs({ "light", "medium", "heavy", "shield" }) do
        C.Same(("%s %s armor training"):format(key, kind), tostring(training[kind] == true), tostring(want[kind] == true))
    end
    -- weapons: every basic weapon, by what the site's wording allows
    local text = site.lines.weapons[1]
    local simple, martial = text:find("simple") ~= nil, text:find("martial") ~= nil
    local light, finesse = text:find("Light property") ~= nil, text:find("Finesse") ~= nil
    for _, name in ipairs(R.WEAPON_ORDER) do
        local weapon = R.WEAPONS[name]
        local expect
        if weapon.category == "SIMPLE" then expect = simple
        elseif light then expect = weapon.props.L == true or (finesse and weapon.props.F == true)
        else expect = martial end
        C.Same(("%s proficient with %s"):format(key, name), tostring(ns.WeaponProficient(key, name)), tostring(expect))
    end
    -- the improvements the class data adds must be levels the site names
    C.Same(key .. " subclass level", R.SUBCLASS_LEVEL, C.SubclassLevel(site))
end

function C.SubclassLevel(site)
    for level = 1, 20 do
        for _, feature in ipairs(site.features[level]) do
            if feature.subclass then return level end
        end
    end
end

local STATS = { str = "STR", dex = "DEX", con = "CON", int = "INT", wis = "WIS", cha = "CHA" }

-- Data/Multiclass.lua against the class's primary abilities (a score of 13 in them is
-- what the 2024 rules ask) and the proficiencies a later class gives.
function C.Multiclass(key, class, site)
    local rule = R.MULTICLASS[class.base]
    if not rule then C.Differs(key .. " multiclass", "no entry in R.MULTICLASS for " .. class.base) return end
    local primary = site.lines.primary[1]
    local either = primary:find(" or ") ~= nil
    local stats = {}
    for stat in primary:gmatch("%a%a%a") do if STATS[stat] then stats[#stats + 1] = STATS[stat] end end
    C.Same(key .. " multiclass abilities", Sorted(rule.primary), Sorted(stats))
    C.Same(key .. " multiclass either ability", tostring(rule.either == true), tostring(either))
    C.Same(key .. " multiclass score", R.MULTICLASS_SCORE, 13)
    local gains = {}
    for _, part in ipairs(site.lines.mc) do
        local name, value = part:match("^(%a+)=(.*)$")
        if name then gains[name] = value end
    end
    C.Same(key .. " multiclass armor", Sorted(rule.armor or {}), Sorted(Site.Split(gains.armor, ",")):gsub("^,", ""))
    C.Same(key .. " multiclass martial weapons", tostring(rule.martial == true), tostring(gains.weapons == "martial"))
    C.Same(key .. " multiclass tools", Sorted(rule.tools or {}), gains.tools)
    local count, skills = gains.skills:match("^(%d+):(.*)$")
    C.Same(key .. " multiclass skill", tostring(rule.skill == true), tostring(count == "1"))
    if skills then C.Same(key .. " multiclass skill list", Sorted(class.skills, true), Sorted(Site.Split(skills, ","))) end
end
