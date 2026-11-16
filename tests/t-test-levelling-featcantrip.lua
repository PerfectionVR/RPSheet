-- A cantrip can't be taken twice in one level dialog: once as a class cantrip and once
-- through a feat (Magic Initiate), in either order.
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local checks, problems = 0, 0
local function Expect(label, ok)
    checks = checks + 1
    if not ok then problems = problems + 1 print("PROBLEM: " .. label) end
end
local function ClassRow(name)
    for _, row in ipairs((T.Rows(levelRoot, "feat cantrip"))) do
        if row.parent:find("pickscantrips") and tostring(row.name):find(name, 1, true) then return row end
    end
end
local function FeatSlot()
    local sheet, store, instances, level = L.FeatChoiceContext()
    for _, slot in ipairs(ns.FeatChoiceSlots(store, instances, level)) do
        if slot.choice.key == "cantrips" then return slot, sheet, store, instances end
    end
end
local function FeatOffers(name)
    local slot, sheet, store, instances = FeatSlot()
    for _, value in ipairs(ns.FeatChoiceValues(sheet, store, instances, slot)) do
        if value == name then return true end
    end
    return false
end

-- (class, background with Magic Initiate of the class's own list)
for _, case in ipairs({ { "MAGE", "SAGE", "True Strike" }, { "PRIEST", "ACOLYTE", "Guidance" }, { "DRUID", "GUIDE", "Guidance" } }) do
    local class, background, cantrip = case[1], case[2], case[3]
    Make({ label = class, class = class, level = 1, species = "HUMAN", background = background, n = 1 })
    local label = ("%s with %s's Magic Initiate, %s"):format(class, background, cantrip)
    if not L.draft or not ClassRow(cantrip) or not FeatSlot() then
        Expect(label .. ": the dialog asks for both a class cantrip and the feat's", false)
    else
        Expect(label .. ": the feat offers it before anything is picked", FeatOffers(cantrip))
        Expect(label .. ": it can be ticked as a class cantrip", T.Click(ClassRow(cantrip), true))
        Expect(label .. ": once ticked as a class cantrip, the feat no longer offers it", not FeatOffers(cantrip))
        T.Click(ClassRow(cantrip), false)
        Expect(label .. ": unticked, the feat offers it again", FeatOffers(cantrip))
        local slot = FeatSlot()
        slot.picked[slot.index] = cantrip
        Expect(label .. ": taken through the feat, it can't be ticked as a class cantrip", not T.Click(ClassRow(cantrip), true))
    end
    L.draft = nil
end
print(("feat cantrips: %d checks, %d problems"):format(checks, problems))
