-- No cantrip is on a sheet twice, and none is offered that the character has from
-- somewhere else (Sheet/SpellPicks.lua):
--   * a Circle of the Stars druid has Guidance from the Star Map: one who picked it
--     as a cantrip gets that pick back, in the dialog where the circle is chosen
--     (without it counting as the level's exchange) and on a character made earlier;
--   * a feat's cantrips (Magic Initiate, Telekinetic) and a cantrip put on the spell
--     list as not counting do the same, and the feat doesn't offer what the class has;
--   * a Mage's exchange after a long rest leaves out what the character has already.
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local checks = 0
local function Check(ok, text)
    checks = checks + 1
    if not ok then Problem(text) end
end
local function Plain(text) return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function Upkeep(sheet)
    ns.ApplyGrants(sheet); ns.NormalizeState(RPSheet:State()); RPSheet:ClampState(true); RPSheet:SheetChanged()
end
-- The entries of a cantrip on the spell list.
local function Entries(sheet, name)
    local found = {}
    for _, spell in ipairs(sheet.spells) do
        if spell.name == name and spell.level == 0 then found[#found + 1] = spell end
    end
    return found
end
local function NoneTwice(sheet, label)
    local seen = {}
    for _, spell in ipairs(sheet.spells) do
        if spell.level == 0 then
            Check(not seen[spell.name], ("%s: %s is on the spell list twice"):format(label, spell.name))
            seen[spell.name] = true
        end
    end
end
-- Makes `name` one of the class's picked cantrips, in the place of another.
local function ForcePick(sheet, key, name)
    local picks = sheet.picks[key]
    if not picks[name] then
        for other in pairs(picks) do picks[other] = nil break end
        picks[name] = true
    end
    Upkeep(sheet)
end
-- The dialog's row of a cantrip.
local function Row(key, name)
    for _, row in ipairs((T.Rows(levelRoot, T.label))) do
        if row.parent == "level.picks" .. key and row.option.type == "toggle" and Plain(row.name or ""):find(name, 1, true) == 1 then return row end
    end
end
local function Group(key)
    local _, byKey = T.Rows(levelRoot, T.label)
    return byKey["picks" .. key]
end

---------------------------------------------------------------------------
-- Circle of the Stars, chosen in the level dialog
---------------------------------------------------------------------------
do
    local KEY = "cantripsDruid"
    local sheet = T.NewCharacter("DRUID", 1, true)
    ForcePick(sheet, KEY, "Guidance")
    Check(#Entries(sheet, "Guidance") == 1 and Entries(sheet, "Guidance")[1].auto == "cantrip:Guidance", "a druid can't pick Guidance as a cantrip")
    T.TakeLevel(nil, {})
    local limit = ns.SheetPickLimit(sheet, KEY)
    T.TakeLevel(nil, { subclass = "Circle of the Stars", inspect = function()
        Check(L.draft.subclass == "Circle of the Stars", "the test couldn't choose Circle of the Stars")
        Check(not L.draft.picks[KEY]["Guidance"], "choosing Circle of the Stars leaves Guidance picked as a cantrip")
        Check(L.PicksChosen(KEY) == limit - 1, ("the freed cantrip isn't asked for: %d of %d chosen"):format(L.PicksChosen(KEY), limit))
        local row = Row(KEY, "Guidance")
        Check(row ~= nil and Plain(row.name):find("you know it already") ~= nil, "Guidance isn't shown as known already")
        Check(row ~= nil and not T.Click(row, true), "Guidance can be picked again beside the Star Map's")
        -- The pick the rules took is no exchange: the level's own is still to make.
        Check(Plain(Group(KEY).name):find("one earlier spell may be exchanged") ~= nil, "the freed pick uses up the level's exchange: " .. Plain(Group(KEY).name))
    end })
    local guidance = Entries(sheet, "Guidance")
    Check(#guidance == 1 and guidance[1].auto == "prepared:Guidance" and guidance[1].free == true, "a Circle of the Stars druid doesn't have Guidance from the Star Map")
    Check(ns.PicksKnown(sheet, KEY) == limit and not sheet.picks[KEY]["Guidance"], "the druid's cantrip picks aren't complete without Guidance")
    Check(not ns.OpenPicks(sheet), "picks are left open after the dialog")
    NoneTwice(sheet, "Stars druid at 3")
    T.Check("Stars druid at 3")
    local cantrips = RPSheet:SpellCounts()
    Check(cantrips == limit, ("the druid counts %d cantrips against %d: Guidance from the Star Map should not count"):format(cantrips, limit))

    -- A druid from before Guidance was granted: picked, and not on the list as prepared.
    for other in pairs(sheet.picks[KEY]) do sheet.picks[KEY][other] = nil break end
    sheet.picks[KEY]["Guidance"] = true
    for index = #sheet.spells, 1, -1 do
        if sheet.spells[index].name == "Guidance" then table.remove(sheet.spells, index) end
    end
    local old = CopyTable(R.SPELLS["Guidance"]); old.auto = "cantrip:Guidance"
    sheet.spells[#sheet.spells + 1] = old
    Upkeep(sheet)
    guidance = Entries(sheet, "Guidance")
    Check(#guidance == 1 and guidance[1].auto == "prepared:Guidance", "an earlier Stars druid keeps Guidance as a picked cantrip")
    Check(not sheet.picks[KEY]["Guidance"] and ns.OpenPicks(sheet), "an earlier Stars druid doesn't get the cantrip pick back")
    Check(table.concat(T.RedLines(sheet), " ") ~= "", "the open cantrip isn't called out on the Character tab")
    ns.RebuildOptions()
    if T.Tab("classChoices") then FlushTimers(); T.Finish("Stars druid choices") else Problem("no choices button for the freed cantrip") end
    Check(not ns.OpenPicks(sheet) and ns.PicksKnown(sheet, KEY) == limit, "the freed cantrip can't be chosen again from the Character tab")
    NoneTwice(sheet, "earlier Stars druid")
    T.Check("earlier Stars druid")
    -- Leaving the circle takes the Star Map's Guidance away and frees nothing.
    while sheet.level < 5 do T.TakeLevel(nil, {}) end
    NoneTwice(sheet, "Stars druid at 5")
end

---------------------------------------------------------------------------
-- A feat's cantrips, and one marked as not counting
---------------------------------------------------------------------------
do
    local KEY = "cantripsCleric"
    -- An Acolyte: Magic Initiate (Cleric) as origin feat.
    local n
    for index, key in ipairs(R.BACKGROUND_ORDER) do
        if key == "ACOLYTE" then n = index - 1 end
    end
    local sheet = T.NewCharacter("PRIEST", n, true)
    Check(sheet.background == "ACOLYTE", "the test character is no Acolyte")
    local instance
    for _, each in ipairs(ns.FeatInstances(sheet)) do
        if each.name == "Magic Initiate" then instance = each end
    end
    Check(instance ~= nil, "an Acolyte has no Magic Initiate")
    if instance then
        local store = sheet.featChoices[instance.id].picks
        local feat = store.cantrips
        Check(feat[1] ~= nil and feat[2] ~= nil, "the feat's cantrips weren't chosen after the wizard")
        NoneTwice(sheet, "Acolyte Priest")
        for name in pairs(sheet.picks[KEY]) do
            Check(name ~= feat[1] and name ~= feat[2], "the class picked " .. name .. ", which the feat gives")
        end
        -- The feat's dropdown leaves out what the class picked; the class's list what the feat gives.
        local slots = ns.FeatChoiceSlots(sheet.featChoices, ns.FeatInstances(sheet), sheet.level)
        local mine
        for name in pairs(sheet.picks[KEY]) do mine = mine or name end
        for _, slot in ipairs(slots) do
            if slot.choice.key == "cantrips" then
                local values = ns.FeatChoiceValues(sheet, sheet.featChoices, ns.FeatInstances(sheet), slot)
                Check(not tContains(values, mine), "Magic Initiate offers " .. mine .. ", which the Priest picked as a cantrip")
                Check(#values > 3, "Magic Initiate offers hardly any cantrips")
            end
        end
        Check(ns.PickBlocked(KEY, feat[1], 1, sheet.picks[KEY], sheet.subclass, sheet) ~= nil, "the Priest can pick " .. feat[1] .. ", which Magic Initiate gives")
        -- A character from before: the same cantrip picked for the class and for the feat.
        feat[1] = mine
        Upkeep(sheet)
        local entries = Entries(sheet, mine)
        Check(#entries == 1 and entries[1].auto == "feat:" .. mine, mine .. " picked twice isn't the feat's alone afterwards")
        Check(not sheet.picks[KEY][mine] and ns.OpenPicks(sheet), "the class's pick of " .. mine .. " isn't freed")
        ns.RebuildOptions()
        if T.Tab("classChoices") then FlushTimers(); T.Finish("Acolyte choices") end
        Check(not ns.OpenPicks(sheet), "the freed cantrip can't be chosen again")
        NoneTwice(sheet, "Acolyte Priest after the choices")
        T.Check("Acolyte Priest")

        -- A cantrip of a lineage, added by hand as not counting.
        local other
        for name in pairs(sheet.picks[KEY]) do other = other or name end
        local own = CopyTable(R.SPELLS[other]); own.free = true
        sheet.spells[#sheet.spells + 1] = own
        Upkeep(sheet)
        entries = Entries(sheet, other)
        Check(#entries == 1 and entries[1].auto == "" and entries[1].free == true, other .. " added as not counting is on the list twice, or lost")
        Check(not sheet.picks[KEY][other], "the pick of " .. other .. " isn't freed for the copy that doesn't count")
        NoneTwice(sheet, "Priest with a cantrip of its own")
    end
end

---------------------------------------------------------------------------
-- A Mage's exchange after a long rest
---------------------------------------------------------------------------
do
    local KEY = "cantripsWizard"
    local sheet = T.NewCharacter("MAGE", 1, true)
    local state = RPSheet:State()
    -- Mage Hand from somewhere else (Telekinetic gives it; here marked as not counting).
    if sheet.picks[KEY]["Mage Hand"] then ForcePick(sheet, KEY, "Mage Hand") end
    local hand = CopyTable(R.SPELLS["Mage Hand"]); hand.free = true
    sheet.spells[#sheet.spells + 1] = hand
    Upkeep(sheet)
    if ns.OpenPicks(sheet) then
        ns.RebuildOptions()
        if T.Tab("classChoices") then FlushTimers(); T.Finish("Mage choices") end
    end
    Check(not sheet.picks[KEY]["Mage Hand"] and #Entries(sheet, "Mage Hand") == 1, "a Mage has Mage Hand twice")
    state.prepareClosed, state.cantripSwap = nil, nil
    local known = RPSheet:BookCantrips()
    Check(#known == ns.SheetPickLimit(sheet, KEY), "the Mage's cantrips aren't complete")
    Check(RPSheet:ChangeCantrip(known[1]) == true, "a cantrip can't be given up after a long rest")
    local _, offered = RPSheet:BookCantrips()
    Check(#offered > 5, "hardly any cantrips are offered in the exchange")
    Check(not tContains(offered, "Mage Hand"), "the exchange offers Mage Hand, which the Mage has already")
    Check(RPSheet:ChangeCantrip("Mage Hand") == false and not sheet.picks[KEY]["Mage Hand"], "Mage Hand can be learned in the exchange beside the one the Mage has")
    Check(RPSheet:ChangeCantrip(offered[1]) == true, "the exchange can't be finished")
    NoneTwice(sheet, "Mage after the exchange")
    T.Check("Mage after the exchange")
end

local problems = 0
for _ in pairs(PROBLEMS) do problems = problems + 1 end
print(("cantrips from elsewhere: %d dialogs, %d checks, %d problems"):format(T.dialogs, checks + T.checks, problems))
