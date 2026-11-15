-- Every class from level 1 to 20, one level at a time through the level dialog, with
-- the sheet checked after each level, for every subclass. Run with a class key to do
-- only that class, and with "quick" for one subclass per class (in turn).
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local A4 = type(rawget(_G, "ARG4")) == "string" and ARG4 ~= "" and ARG4 or nil
local only, every = (A4 ~= "all" and A4 ~= "quick") and A4 or nil, A4 ~= "quick" and rawget(_G, "ARG5") ~= "quick"
local n = 0
for classIndex, key in ipairs(R.CLASS_ORDER) do
    local class = R.CLASSES[key]
    for subIndex, subclass in ipairs(class.subclasses) do
        if (not only or only == key) and (every or subIndex == (classIndex % #class.subclasses) + 1) then
            n = n + 1
            local sheet = T.NewCharacter(key, n)
            if sheet then
                T.Check(key .. " 1 (wizard)", { level = 1 })
                for level = 2, R.MAX_LEVEL do
                    local label = ("%s/%s %d"):format(key, subclass, level)
                    if not T.TakeLevel(nil, { subclass = subclass }, label) then break end
                    T.Check(label, { level = level })
                end
                if sheet.level == R.MAX_LEVEL and ns.ClassSubclass(sheet, key) ~= subclass then
                    Problem(key .. ": subclass is " .. tostring(ns.ClassSubclass(sheet, key)) .. ", picked " .. subclass)
                end
            end
        end
    end
end
-- The one feat the turns above never reach: it asks for Dexterity and Wisdom of 13.
if not only then
    local sheet = T.NewCharacter("MONK", 99, true)
    if sheet then
        for level = 2, 4 do T.TakeLevel(nil, level == 4 and { choice = "FEAT", feat = "Stagger and Sway" } or {}, "MONK feat " .. level) end
        if not T.HasEntry(sheet, "Stagger and Sway") then Problem("Stagger and Sway isn't on the sheet after being taken at level 4") end
        T.Check("MONK feat", { level = 4 })
    end
end
local taken = {}
for name, count in pairs(T.feats) do taken[#taken + 1] = name end
local missed = {}
for _, group in ipairs({ "GENERAL", "BOON" }) do
    for _, name in ipairs(R.FEAT_NAMES[group]) do if not T.feats[name] then missed[#missed + 1] = name end end
end
print(("feats taken: %d different; never taken: %s"):format(#taken, table.concat(missed, ", ")))
T.Summary("single-class levelling")
