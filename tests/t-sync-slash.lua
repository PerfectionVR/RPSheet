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
