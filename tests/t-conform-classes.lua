-- Every class fact the addon holds against the rules site's class data, mechanically:
-- each class and subclass is put on a sheet at every level 1 to 20 and compared with
-- the files in tests/data (made by tests/data/site-reduce.js).
-- One PROBLEM line per difference; deliberate differences are named, with a reason
-- each, in t-conform-names-lib.lua. Run with a class key to do only that class.
dofile(ARG3 .. "/exercise_head.lua") -- the chat the addon talks to
dofile(ARG3 .. "/sim.lua")
Start()
dofile(ARG3 .. "/t-conform-site-lib.lua")
dofile(ARG3 .. "/t-conform-names-lib.lua")
dofile(ARG3 .. "/t-conform-sheets-lib.lua")
dofile(ARG3 .. "/t-conform-statics-lib.lua")
dofile(ARG3 .. "/t-conform-numbers-lib.lua")
dofile(ARG3 .. "/t-conform-features-lib.lua")
dofile(ARG3 .. "/t-conform-lists-lib.lua")
local C = Conform
local only = type(rawget(_G, "ARG4")) == "string" and ARG4 ~= "" and ARG4 or nil

for _, key in ipairs(R.CLASS_ORDER) do
    if not only or only == key then
        local class = R.CLASSES[key]
        local site = Site.classes[class.name .. "|WoW"]
        if not site then
            Problem(key .. ": the site has no class named " .. class.name)
        else
            C.Statics(key, class, site)
            C.Multiclass(key, class, site)
            -- the class at every level, with its first subclass
            local first = Names.CLASS_WITH[key] or class.subclasses[1]
            local sheets = C.Sheets(key, first)
            for level = 1, R.MAX_LEVEL do
                C.Numbers(key, class, site, sheets[level], level)
                C.Choices(key, class, site, sheets[level], level)
            end
            C.Features(key, key, site, sheets, "class")
            C.Spells(key, key, site, first)
            -- each subclass, at every level
            local listed = {}
            for _, subclass in ipairs(class.subclasses) do
                listed[subclass] = true
                local siteSub = Site.subclasses[class.name .. "|" .. subclass]
                if not siteSub then
                    Problem(("%s: the site has no %s subclass named %s"):format(key, class.name, subclass))
                else
                    local subSheets = subclass == first and sheets or C.Sheets(key, subclass)
                    C.Features(key, key .. "/" .. subclass, siteSub, subSheets, "subclass")
                    C.SubclassNumbers(key, subclass, siteSub, subSheets)
                    C.Spells(key, key .. "/" .. subclass, siteSub, subclass)
                end
            end
            for id, siteSub in pairs(Site.subclasses) do
                if siteSub.class == class.name and not listed[siteSub.name] then
                    C.Differs(key, "subclass list", siteSub.name, "the site has this subclass, the addon doesn't")
                end
            end
        end
    end
end
C.partial = only ~= nil -- (then the allow-list isn't checked for entries no longer needed)
C.Lists()
C.Options()
Names.Custom(C)
C.Summary()
