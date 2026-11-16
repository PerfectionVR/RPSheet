-- /sheet and /rpsheet as typed, through the real console library: every subcommand,
-- with good and with bad arguments.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local anna = world:AddClient({ name = "Anna" }):Login()
world:Advance(5)
anna.opened, anna.ns.Wizard.draft = {}, nil -- the wizard offered at a first login
anna:Build("WARRIOR", "", 5)
local addon = anna.addon
addon.db.profile.channel = "SELF"

-- The window: counted, not drawn.
local toggles = 0
addon.ToggleWindow = function() toggles = toggles + 1 end

local function Run(line)
    local printed, before = #anna.printed, toggles
    Check(anna:Slash(line), "the game knows the command in: " .. line)
    world:Advance(0.3)
    local list = {}
    for i = printed + 1, #anna.printed do list[#list + 1] = anna.printed[i] end
    for _, problem in ipairs(anna.errors) do Check(false, ("\"%s\" raised an error: %s"):format(line:sub(1, 60), problem:sub(1, 600))) end
    anna.errors = {}
    return table.concat(list, "\n"), toggles - before
end
local function Usage(text) return text:find("/sheet config", 1, true) ~= nil and text:find("/sheet heal 8", 1, true) ~= nil end
local function HP() return addon:State().hp end
local MAX = addon:MaxHP()

Section("the window", function()
    for _, line in ipairs({ "/sheet", "/rpsheet", "/sheet ", "/sheet    ", "/SHEET", "/RpSheet" }) do
        local text, toggled = Run(line)
        Check(toggled == 1 and text == "", ("\"%s\" shows or hides the sheet (%d, %s)"):format(line, toggled, text))
    end
end)

Section("config, new, lock, rest", function()
    for _, line in ipairs({ "/sheet config", "/sheet CONFIG", "/sheet   config  ", "/rpsheet Config" }) do
        anna.opened = {}
        local text, toggled = Run(line)
        Check(anna.opened.RPSheet == true and toggled == 0 and text == "", ("\"%s\" opens the settings"):format(line))
    end
    local _, toggled = Run("/sheet new")
    Check(anna.ns.Wizard.draft ~= nil and anna.opened.RPSheetWizard == true and anna.opened.RPSheet == nil and toggled == 0, "\"/sheet new\" opens the wizard in place of the settings")
    anna.opened, anna.ns.Wizard.draft = {}, nil
    Eq(addon.db.profile.locked, false, "unlocked at first")
    Run("/sheet lock")
    Eq(addon.db.profile.locked, true, "\"/sheet lock\" locks")
    Run("/sheet LOCK")
    Eq(addon.db.profile.locked, false, "and unlocks")
    addon:State().hp = 5
    local text = Run("/sheet rest")
    Eq(HP(), MAX, "\"/sheet rest\" is a long rest")
    Check(text:find("finishes a long rest", 1, true), "and says so: " .. text)
end)

Section("damage and healing", function()
    local function Damage(line, want, piece)
        addon:State().hp = MAX
        addon:ClearDeathSaves()
        local text, toggled = Run(line)
        Eq(MAX - HP(), want, ("\"%s\": hit points lost"):format(line))
        Eq(toggled, 0, ("\"%s\": the window is left alone"):format(line))
        if piece then Check(text:find(piece, 1, true), ("\"%s\" says \"%s\": %s"):format(line, piece, text)) end
        return text
    end
    Damage("/sheet damage 5", 5, "takes 5 damage")
    Damage("/sheet damage 5 fire", 5, "takes 5 fire damage")
    Damage("/sheet DAMAGE 5 FIRE", 5, "takes 5 fire damage")
    Damage("/sheet damage   7   cold  ", 7, "takes 7 cold damage")
    Damage("/sheet damage 28 fire -5", 23)
    Damage("/sheet damage 28 - 5", 23)
    Damage("/sheet damage 5 -9", 0)
    Damage("/sheet damage 5 bogus", 0, "is not a damage type")
    Damage("/sheet damage 5 fire extra words", 5)
    Damage("/sheet damage", 0, "Give the damage as a number")
    Damage("/sheet damage abc", 0, "Give the damage as a number")
    Damage("/sheet damage fire", 0, "Give the damage as a number")
    Damage("/sheet damage 0", 0, "Give the damage as a number")
    Damage("/sheet damage -5", 0, "Give the damage as a number")
    Damage("/sheet damage 5.9", 5)
    Damage("/sheet damage 5fire", 5)
    Damage("/sheet damage 99999999999999999999999999", MAX)
    Damage("/sheet damage " .. ("9"):rep(400), MAX)
    Damage("/sheet damage 1e3", 1)
    Damage("/sheet damage 0x10", 0)
    Damage("/sheet damage 5 |cffff0000fire|r", 5)
    Damage("/sheet damage 5 %s %d %", 5)
    local function Heal(line, from, want, piece)
        addon:State().hp = from
        addon:ClearDeathSaves()
        local text, toggled = Run(line)
        Eq(HP(), want, ("\"%s\": hit points"):format(line))
        Eq(toggled, 0, ("\"%s\": the window is left alone"):format(line))
        if piece then Check(text:find(piece, 1, true), ("\"%s\" says \"%s\": %s"):format(line, piece, text)) end
    end
    Heal("/sheet heal 8", 10, 18, "regains 8 hit points")
    Heal("/sheet HEAL 8", 10, 18)
    Heal("/sheet heal 9999", 10, MAX)
    Heal("/sheet heal " .. ("9"):rep(400), 10, MAX)
    Heal("/sheet heal", 10, 10, "Give the healing as a number")
    Heal("/sheet heal abc", 10, 10, "Give the healing as a number")
    Heal("/sheet heal -3", 10, 10, "Give the healing as a number")
    Heal("/sheet heal 0", 10, 10, "Give the healing as a number")
    Heal("/sheet heal 3 fire", 10, 13)
    Heal("/sheet heal 4", 0, 4, "is back up")
end)

Section("short rest, undo, tab, items, level", function()
    -- rests
    local wind
    for _, tracker in ipairs(addon:GetTrackers()) do if tracker.label == "Second Wind" then wind = tracker end end
    for _, line in ipairs({ "/sheet short", "/sheet SHORT", "/sheet rest short", "/sheet  rest   short ", "/rpsheet short" }) do
        addon:State().hp = 5
        wind.set(0)
        local text, toggled = Run(line)
        Check(text:find("finishes a short rest", 1, true) and toggled == 0, ("\"%s\" is a short rest: %s"):format(line, text))
        Check(wind.get() > 0 and HP() == 5, ("\"%s\": what a short rest gives back, and no hit points"):format(line))
    end
    addon:State().hp = 5
    local text = Run("/sheet rest long")
    Check(text:find("finishes a long rest", 1, true) and HP() == MAX, "\"/sheet rest long\" is a long rest")
    text = Run("/sheet undo")
    Check(text:find("takes back the long rest", 1, true) and HP() == 5, "\"/sheet undo\" takes it back: " .. text)
    text = Run("/sheet UNDO")
    Check(text:find("no rest to take back", 1, true) and HP() == 5, "and says so when there is nothing to take back: " .. text)

    -- tabs: every name the sheet has, in any case, and the start of one
    local source = io.open(ARG1 .. "/UI/SheetContent.lua", "rb"):read("*a")
    local names = {}
    for name in source:match("local TABS = (%b{})"):gmatch("{ name = \"(%a+)\"") do names[#names + 1] = name end
    Check(#names >= 6, "the sheet's tabs were found in UI/SheetContent.lua: " .. table.concat(names, " "))
    local populated = 0
    local populate = addon.Populate
    addon.Populate = function(this) populated = populated + 1; return populate(this) end
    for _, name in ipairs(names) do
        for _, typed in ipairs({ name, name:lower(), name:upper(), name:lower():sub(1, 4) }) do
            addon.db.char.sheetTab = "none"
            local before = populated
            local shown, toggled = Run("/sheet tab " .. typed)
            Eq(addon.db.char.sheetTab, name, ("\"/sheet tab %s\" opens the tab"):format(typed))
            Check(populated > before and toggled == 0 and shown == "", ("\"/sheet tab %s\" redraws the sheet and says nothing: %s"):format(typed, shown))
        end
    end
    local usage = Run("/sheet help")
    for _, name in ipairs(names) do Check(usage:find(name:lower(), 1, true), "the help names the tab " .. name) end
    -- shown when it was hidden
    local shows = 0
    addon.window = setmetatable({ frame = { IsShown = function() return false end }, Show = function() shows = shows + 1 end },
        { __index = function() return function() end end })
    Run("/sheet tab items")
    Eq(shows, 1, "a hidden sheet is shown for the tab")
    addon.window.frame.IsShown = function() return true end
    Run("/sheet tab trade")
    Eq(shows, 1, "one that is open is left open")
    addon.db.char.sheetTab = "Actions"
    for _, line in ipairs({ "/sheet tab", "/sheet tab nothing", "/sheet tab x", "/sheet tab tra", "/sheet tab t" }) do
        local shown = Run(line)
        Check(shown:find("Which tab?", 1, true) and shown:find("Actions, Checks", 1, true), ("\"%s\" names the tabs: %s"):format(line, shown))
        Eq(addon.db.char.sheetTab, "Actions", ("\"%s\" leaves the tab"):format(line))
    end
    addon.Populate = populate

    -- the item browser
    local browser = 0
    addon.ToggleItemBrowser = function() browser = browser + 1 end
    for _, line in ipairs({ "/sheet items", "/sheet ITEMS", "/rpsheet items " }) do Run(line) end
    Eq(browser, 3, "\"/sheet items\" shows or hides the item browser")

    -- the level dialog
    local asked = {}
    local open = anna.ns.OpenLevelDialog
    anna.ns.OpenLevelDialog = function(...) asked[#asked + 1] = { n = select("#", ...), ... } end
    text = Run("/sheet level")
    Eq(#asked, 1, "\"/sheet level\" opens the level dialog: " .. text)
    Eq(addon:Sheet().level, 5, "and takes no level by itself")
    addon:Sheet().level = anna.ns.Rules.MAX_LEVEL
    text = Run("/sheet level")
    Check(#asked == 1 and text:find("highest level", 1, true), "at the highest level it says so: " .. text)
    addon:Sheet().level = 5
    local class = addon:Sheet().class
    addon:Sheet().class = ""
    text = Run("/sheet level")
    Check(#asked == 1 and text:find("/sheet new", 1, true), "without a character it points to the wizard: " .. text)
    addon:Sheet().class = class
    anna.ns.OpenLevelDialog = open
    Run("/sheet level")
    world:Advance(1)
    Check(anna.opened.RPSheetLevel == true and anna.ns.LevelDialog.draft ~= nil, "the real dialog opens for the next level")
    anna.opened, anna.ns.LevelDialog.draft = {}, nil

    -- all of them are in the help
    for _, piece in ipairs({ "/sheet short", "/sheet rest short", "/sheet undo", "/sheet tab", "/sheet items", "/sheet level", "/sheet rest - long rest" }) do
        Check(usage:find(piece, 1, true), "the help lists " .. piece)
    end
end)

Section("words it doesn't know", function()
    for _, line in ipairs({ "/sheet help", "/sheet confg", "/sheet config now", "/sheet rest now", "/sheet lock please", "/sheet new character",
        "/sheet damages 5", "/sheet 5", "/sheet ?", "/sheet -", "/sheet d\195\164mage 5", "/sheet |cffff0000config|r", "/sheet |Hitem:1|h[x]|h",
        "/sheet %s%d%q", "/sheet " .. ("x"):rep(5000), "/sheet config\tnew", "/sheet toggle", "/sheet show" }) do
        local hp, locked = HP(), addon.db.profile.locked
        anna.opened = {}
        local text, toggled = Run(line)
        local label = line:sub(1, 40)
        Check(Usage(text), ("\"%s\" lists the commands: %s"):format(label, text:sub(1, 200)))
        Eq(toggled, 0, ("\"%s\": the window is left alone"):format(label))
        Check(HP() == hp and addon.db.profile.locked == locked and next(anna.opened) == nil and anna.ns.Wizard.draft == nil, ("\"%s\" does nothing else"):format(label))
        for shown in text:gmatch("[^\n]+") do
            local body = shown:gsub("^|cff33ff99RPSheet|r: ", "")
            Check(Plain(body, 200), ("\"%s\": a line that isn't plain or is endless: %s"):format(label, body:sub(1, 120)))
        end
        if line ~= "/sheet help" then Check(text:find("is not something /sheet knows", 1, true), ("\"%s\" is called unknown"):format(label)) end
    end
    Check(not Run("/sheet help"):find("is not something", 1, true), "\"/sheet help\" is not called a mistake")
end)

world:CheckClean("slash")
Summary("t-sync-slash")
