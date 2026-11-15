-- Timing: how long the sheet window, the upkeep after a change, the settings window
-- and a level dialog take for a few heavy characters, and which of the addon's own
-- functions the time of rebuilding the sheet goes to.
-- Nothing here fails on a slow machine: the numbers are printed to be read, and to be
-- compared between two versions of the addon on the same machine. The fake game draws
-- nothing, so they say what the addon's own code costs, not what the game's frames do.
-- usage: run.sh t-perf.lua [repetitions, 5 when left out] [how many functions to list, 10 when left out]
dofile(ARG3 .. "/t-test-windows-base.lua")
Start()
ns.checkPass = false -- the tests' check of the numbers kept for a rebuild works them out twice

local REPS = tonumber(rawget(_G, "ARG4") or "") or 5
local TABS = { "Actions", "Checks", "Skills", "Traits", "Items", "Trade" }
local MAIN, LEVEL = "RPSheet", "RPSheetLevel"
local saved = RPSheet.db.char

-- Milliseconds one call takes: the best of three rounds of `reps` calls, so that a
-- pause of the machine doesn't count.
local function Time(fn, reps)
    reps = reps or REPS
    local best
    for _ = 1, 3 do
        local began = os.clock()
        for _ = 1, reps do fn() end
        local each = (os.clock() - began) * 1000 / reps
        if not best or each < best then best = each end
    end
    return best
end

local function Line(label, ms)
    print(("  %-44s %9.3f ms"):format(label, ms))
end

---------------------------------------------------------------------------
-- A call count and time profile, by wrapping the addon's own functions
---------------------------------------------------------------------------
-- Every function kept in one of the addon's shared tables is replaced by one that
-- counts the call and adds up its time: in all, and without the time of the wrapped
-- functions it called itself ("own"). A function another file kept in a local of its
-- own before this ran is not seen. os.clock ticks coarsely, so a short function's time
-- is only right as a sum over many calls.
local stats, depth, inner, originals = {}, 0, {}, {}

local function Done(stat, began, ...)
    local spent = os.clock() - began
    stat.calls, stat.total = stat.calls + 1, stat.total + spent
    stat.own = stat.own + spent - inner[depth]
    depth = depth - 1
    if depth > 0 then inner[depth] = inner[depth] + spent end
    return ...
end

local function WrapAll(owner, prefix)
    for key, fn in pairs(owner) do
        if type(key) == "string" and type(fn) == "function" and key:find("^%u") then
            local stat = { name = prefix .. key, calls = 0, total = 0, own = 0 }
            stats[#stats + 1] = stat
            originals[#originals + 1] = { owner = owner, key = key, fn = fn }
            owner[key] = function(...)
                depth = depth + 1
                inner[depth] = 0
                return Done(stat, os.clock(), fn(...))
            end
        end
    end
end

local function Unwrap()
    for _, entry in ipairs(originals) do entry.owner[entry.key] = entry.fn end
    stats, originals, depth = {}, {}, 0
end

local function Profile(label, fn, reps)
    WrapAll(RPSheet, "RPSheet:")
    WrapAll(ns, "ns.")
    WrapAll(ns.UI, "UI.")
    WrapAll(ns.Rules, "R.")
    WrapAll(ns.Util, "Util.")
    WrapAll(ns.Levels, "Levels.")
    WrapAll(ns.Opt, "Opt.")
    WrapAll(ns.Wizard, "W.")
    if ns.LevelDialog then WrapAll(ns.LevelDialog, "LevelDialog.") end
    for _ = 1, reps do fn() end
    table.sort(stats, function(a, b) return a.own > b.own end)
    local listed = math.min(tonumber(rawget(_G, "ARG5") or "") or 10, #stats)
    print(("  the %d slowest functions of %s (%d times; calls and ms each time):"):format(listed, label, reps))
    print(("    %-34s %8s %10s %10s"):format("function", "calls", "own ms", "with inner"))
    for index = 1, listed do
        local stat = stats[index]
        print(("    %-34s %8d %10.3f %10.3f"):format(stat.name, stat.calls / reps, stat.own * 1000 / reps, stat.total * 1000 / reps))
    end
    Unwrap()
end

---------------------------------------------------------------------------
-- The characters
---------------------------------------------------------------------------
local function Class(sheet, key, level)
    local class = R.CLASSES[key]
    sheet.classes[key] = { level = level, subclass = (level >= 3 or class.hero) and class.subclasses[1] or "", spec = class.specs[1],
        skill = "", fightingStyle = "", fightingStyle2 = "" }
    sheet.level = sheet.level + level
end

local function Gear()
    for _, name in ipairs({ "Longsword", "Longbow", "Dagger", "Shield", "Chain Mail", "Rope", "Potion of Healing" }) do
        local item = RPSheet:AddItem(name, 1)
        if item then RPSheet:SetEquipped(item, true) end
    end
    local names, added = {}, 0
    for name in pairs(R.ITEMS) do names[#names + 1] = name end
    table.sort(names)
    for index = 1, #names, 9 do
        if R.ITEMS[names[index]].rarity and added < 8 then
            local item = RPSheet:AddItem(names[index], 1)
            item.equipped, item.attuned, added = true, item.attune and added < 3, added + 1
        end
    end
    for _, name in ipairs({ "Riding Horse", "Cart" }) do RPSheet:AddMount(name) end
    for index = 1, #R.TOOL_ORDER, 4 do RPSheet:Sheet().tools[R.TOOL_ORDER[index]] = true end
    RPSheet:AddCoins(12345)
end

local CHARACTERS = {
    { "a level 20 caster with a full spell list", function()
        return NewCharacter("PRIEST", nil, nil, 20, 1)
    end },
    { "a character of three classes", function()
        local sheet = NewCharacter("PALADIN", nil, nil, 8, 2)
        Class(sheet, "WARLOCK", 6)
        Class(sheet, "ROGUE", 6)
        return sheet
    end },
    { "a level 20 mage with a full spellbook", function()
        return NewCharacter("MAGE", nil, nil, 20, 4)
    end },
    { "a level 20 druid who knows every beast form", function()
        local sheet = NewCharacter("DRUID", "Circle of the Moon", nil, 20, 3)
        sheet.picks.forms = {}
        for name in pairs(R.BEASTS) do sheet.picks.forms[name] = true end
        return sheet
    end },
}

---------------------------------------------------------------------------
-- The measurements
---------------------------------------------------------------------------
local function Sections()
    local names = {}
    for name, fn in pairs(UI) do
        if type(fn) == "function" and name:find("Section$") then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

local function Measure(label, build)
    local sheet = Use(build())
    -- once more: the spells to prepare are picked from a spellbook that is full now
    Try(label .. " picks", FillPicks, sheet)
    ns.ApplyGrants(sheet)
    Try(label .. " gear", Gear)
    RPSheet:SheetChanged()
    F.Settle(true)
    local body = RPSheet.body
    print(("%s: %d abilities, %d passives, %d spells, %d items"):format(label, #sheet.abilities, #sheet.passives, #sheet.spells, #sheet.items))

    local sum = 0
    for _, tab in ipairs(TABS) do
        saved.sheetTab = tab
        local ms = Time(function() RPSheet:Populate() end)
        Line("Populate, tab " .. tab, ms)
        sum = sum + ms
    end
    Line("Populate, the six tabs together", sum)
    -- with the spellbook open every rebuild fills that window too
    if ns.HasSpellbook(sheet) then
        saved.sheetTab = "Actions"
        RPSheet:ToggleSpellbook()
        F.Settle()
        Line(("Populate with the spellbook open (%d rows)"):format(#RPSheet.bookBody.children), Time(function() RPSheet:Populate() end))
        RPSheet.bookWindow:Hide()
        F.Settle()
    end

    -- every row of every tab hovered once: the tooltips are put together then
    local hover = 0
    for _, tab in ipairs(TABS) do
        saved.sheetTab = tab
        RPSheet:Populate()
        F.Settle()
        hover = hover + Time(function()
            for _, part in ipairs(body.children) do
                if part.events and part.events.OnEnter then
                    F.Fire(part.frame, "OnEnter", true)
                    F.Fire(part.frame, "OnLeave", true)
                end
            end
        end)
    end
    Line("hovering every row of the six tabs", hover)

    for _, name in ipairs(Sections()) do
        Line("section " .. name, Time(function()
            body:PauseLayout()
            body:ReleaseChildren()
            UI[name](RPSheet, body)
            body:ResumeLayout()
        end, REPS * 4))
    end
    saved.sheetTab = "Actions"
    RPSheet:Populate()

    Line("RPSheet:Refresh", Time(function() RPSheet:Refresh() end))
    Line("ns.ApplyClassFeatures", Time(function() ns.ApplyClassFeatures(sheet) end))
    Line("ns.ApplyGrants (every grant)", Time(function() ns.ApplyGrants(sheet) end))
    Line("ns.NormalizeState", Time(function() ns.NormalizeState(RPSheet:State()) end))
    Line("RPSheet:ClampState", Time(function() RPSheet:ClampState() end))
    Line("RPSheet:SheetChanged (upkeep and rebuild)", Time(function() RPSheet:SheetChanged() end))
    Line("ns.RebuildOptions", Time(function() ns.RebuildOptions() end))

    local function Settings()
        AceConfigDialog:Open(MAIN)
        F.Settle()
        AceConfigDialog:Close(MAIN)
        F.Settle()
    end
    -- the dialog of the first class's latest level: it shows every choice of the character
    local slot = ns.LevelSlot(sheet, sheet.class, ns.ClassLevel(sheet, sheet.class))
    local function LevelDialog()
        ns.OpenLevelDialog(slot)
        F.Settle()
        if AceConfigDialog.OpenFrames[LEVEL] then AceConfigDialog:Close(LEVEL) end
        if ns.LevelDialog and ns.LevelDialog.draft then ns.LevelDialog.draft = nil end
        F.Settle()
    end
    Line("opening the settings window", Time(Settings))
    Line("opening a level dialog", Time(LevelDialog))

    Profile("rebuilding the six tabs", function()
        for _, tab in ipairs(TABS) do
            saved.sheetTab = tab
            RPSheet:Populate()
        end
    end, math.max(3, REPS))
    Profile("the upkeep after a change", function()
        ns.ApplyGrants(sheet)
        ns.NormalizeState(RPSheet:State())
        RPSheet:ClampState()
    end, math.max(3, REPS))
    Profile("opening the settings window", Settings, math.max(3, REPS))
    Profile("opening a level dialog", LevelDialog, math.max(3, REPS))
    print("")
    io.stdout:flush()
end

for _, entry in ipairs(CHARACTERS) do
    Try(entry[1], Measure, entry[1], entry[2])
end

Finish("perf", ("%d characters timed, %d repetitions each"):format(#CHARACTERS, REPS))
