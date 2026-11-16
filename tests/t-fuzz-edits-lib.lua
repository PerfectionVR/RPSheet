-- The random-play tester's actions, part 3: the settings (any option, any value it
-- takes), levels up through the dialog and down, the free edits under Customize,
-- export and import, windows opened and closed, a reload, Total RP 3 profiles.
--
-- FREE actions are the ones the rules don't bind: the Customize pages, going back a
-- level, the example character. After one of them the character may hold more than
-- its limits allow; until then it may not (t-fuzz-checks-lib.lua).
local Z = FUZZ
local Action = Z.Action
local MAIN = "RPSheet"

-- The mark goes with the saved character, so it follows it through reloads and
-- from a WoW character's sheet to a Total RP 3 profile's.
function Z.MarkFree(on) RPSheet:State().fuzzFree = on or nil end
function Z.IsFree() return RPSheet:State().fuzzFree == true end

---------------------------------------------------------------------------
-- Any option of the settings window
---------------------------------------------------------------------------
local TEXTS = { "", "0", "1", "7", "15", "120", "99999", "-3", "2.5", "abc", "Sir Test of Testing", "100%", "%1", "a|cffff0000b|r", "two\nlines",
    "|Hitem:1|h[x]|h", "Ünïcödé", ("long "):rep(60), "12 gp", "  " }
local SETTABLE = { toggle = true, select = true, multiselect = true, range = true, input = true, execute = true, color = true }
-- Options that other actions press, or that only make sense with what they do.
local LEFT = { levelDown = true, apply = true, import = true, export = true, example = true }

local function Settable(free)
    local rows, list = Z.Rows(Z.Options(MAIN)), {}
    for _, row in ipairs(rows) do
        local custom = row.path:find("^options%.customize%.") ~= nil
        if SETTABLE[row.kind] and not row.disabled and custom == free and not (LEFT[row.key] and not custom) then list[#list + 1] = row end
    end
    return list
end

local function SetAny(row)
    local kind, option = row.kind, row.option
    if kind == "toggle" then
        Z.Set(row, not row.current)
    elseif kind == "select" then
        local keys = {}
        for key in pairs(row.values) do keys[#keys + 1] = key end
        if #keys == 0 then Z.Skip() end
        local wanted = Z.Choose("value", keys, tostring)
        for _, key in ipairs(keys) do if tostring(key) == tostring(wanted) then Z.Set(row, key) break end end
    elseif kind == "multiselect" then
        local keys = {}
        for key in pairs(row.values) do keys[#keys + 1] = key end
        if #keys == 0 then Z.Skip() end
        local wanted = Z.Choose("value", keys, tostring)
        for _, key in ipairs(keys) do
            if tostring(key) == tostring(wanted) then
                local on = Z.Member(option, "get", row.path, key)
                Z.Set(row, key, not on)
                break
            end
        end
    elseif kind == "range" then
        local low, high, step = option.min or 0, option.max or 100, option.step or 1
        local how = Z.Choose("how", { "low", "high", "any", "any" })
        local value = how == "low" and low or how == "high" and high or (low + step * Z.Int("steps", 0, math.floor((high - low) / step)))
        Z.Set(row, value)
    elseif kind == "input" then
        Z.Set(row, (Z.Choose("text", TEXTS)))
    elseif kind == "color" then
        Z.Set(row, Z.Int("r", 0, 10) / 10, Z.Int("g", 0, 10) / 10, Z.Int("b", 0, 10) / 10, Z.Int("a", 0, 10) / 10)
    else
        Z.Set(row)
    end
    Try("notify", function() REGISTRY:NotifyChange(MAIN) end)
end

-- Settings, the theme, the Character tab's buttons (which open the wizard and the
-- level dialog).
Action("option", { weight = 6, guard = Z.Idle, run = function()
    SetAny((Z.Choose("option", Settable(false), function(row) return row.path end)))
end })
-- The Customize pages.
Action("customize", { weight = 14, free = true, guard = function() return Z.Idle() and Z.HasCharacter() end, run = function()
    Z.MarkFree(true)
    SetAny((Z.Choose("option", Settable(true), function(row) return row.path end)))
end })
Action("example", { weight = 0.2, free = true, guard = Z.Idle, run = function()
    Z.Set(Z.ByKey(Z.Rows(Z.Options(MAIN).args.general, "options.general")).example)
    Z.MarkFree(true)
end })

---------------------------------------------------------------------------
-- Levels
---------------------------------------------------------------------------
local function CharacterTab() return Z.ByKey(Z.Rows(Z.Options(MAIN).args.character, "options.character")) end

Action("level up", { weight = 8, guard = function() return Z.Idle() and Z.HasCharacter() and RPSheet:Sheet().level < R.MAX_LEVEL end, run = function()
    local tab = CharacterTab()
    -- another class now and then, when the character may take one
    if tab.levelClass and not tab.levelClass.disabled and Z.Flip("other", 0.3) then
        local names = Z.Candidates(tab.levelClass)
        if #names > 0 then Z.Set(tab.levelClass, (Z.Choose("class", names))) end
        tab = CharacterTab()
    end
    if not tab.levelUp or not Z.Set(tab.levelUp) then Z.Skip() end
    F.Settle()
    -- most of the time the dialog is worked at once; otherwise it stays open
    if ns.LevelDialog.draft and Z.Flip("now", 0.75) then Z.FillLevelDialogs("level up") end
end })
Action("level choices", { weight = 2, guard = function() return Z.Idle() and Z.HasCharacter() end, run = function()
    local rows = {}
    for key, row in pairs(CharacterTab()) do
        if (key:find("^levelChoice") or key == "classChoices") and not row.disabled then rows[#rows + 1] = row end
    end
    Z.Set((Z.Choose("which", rows, function(row) return row.key end)))
    F.Settle()
    if ns.LevelDialog.draft and Z.Flip("now", 0.75) then Z.FillLevelDialogs("level choices") end
end })
Action("level dialog", { weight = 25, guard = function() return ns.LevelDialog.draft ~= nil end, run = function()
    if Z.Flip("cancel", 0.2) then Z.CloseLevelDialog() else Z.FillLevelDialogs("level dialog") end
end })
Action("level down", { weight = 3, free = true, guard = function() return Z.Idle() and Z.HasCharacter() and RPSheet:Sheet().level > 1 end, run = function()
    local tab = CharacterTab()
    if not tab.levelDown or tab.levelDown.disabled then Z.Skip() end
    Z.MarkFree(true)
    Z.Set(tab.levelDown)
end })

-- The wizard: finished by "make" (t-fuzz-maker-lib.lua), or closed with "Not now".
Z.actions.make.weight = 25
Z.actions.make.guard = function() return W.draft ~= nil end
Action("wizard open", { weight = 0.4, guard = Z.Idle, run = function() RPSheet:SlashCommand("new") end })
Action("wizard close", { weight = 4, guard = function() return W.draft ~= nil end, run = function()
    Z.Set(Z.ByKey(Z.Rows(Z.Options("RPSheetWizard"), "wizard")).skip)
end })

---------------------------------------------------------------------------
-- Export and import
---------------------------------------------------------------------------
Action("export import", { weight = 2, guard = function() return Z.Idle() and Z.HasCharacter() end, run = function()
    local tab = Z.ByKey(Z.Rows(Z.Options(MAIN).args.transfer, "options.transfer"))
    local text = tab.export.current
    if type(text) ~= "string" or text == "" then Z.Report("transfer", "the export box is empty") return end
    Z.Set(tab.import, text)
    tab = Z.ByKey(Z.Rows(Z.Options(MAIN).args.transfer, "options.transfer"))
    if tab.apply.disabled then
        Z.Report("transfer", "the character's own export can't be imported: " .. F.Plain(tab.status.name or ""))
        return
    end
    Z.Set(tab.apply)
    F.Settle()
    Z.ExportSame(text)
end })
-- The character just imported from `text` exports to the same text. After a free
-- edit the import may have cleaned something: then the next round must be the same.
function Z.ExportSame(text)
    local again = RPSheet:ExportSheet()
    if again ~= text and Z.IsFree() then
        text = again
        RPSheet:ReplaceSheet((RPSheet:DecodeSheet(text)))
        F.Settle()
        again = RPSheet:ExportSheet()
    end
    if again ~= text then
        local one, two = RPSheet:DecodeSheet(text), RPSheet:DecodeSheet(again)
        Z.Report("transfer", "export, import, export gives another string: " .. tostring(one and two and Z.Compare(one, two, "sheet") or "?"))
    end
end
Action("final", { run = function() Z.Final() end })

---------------------------------------------------------------------------
-- Windows
---------------------------------------------------------------------------
Action("window", { weight = 5, run = function()
    local what = Z.Choose("what", { "sheet", "sheet", "items", "stable", "crafting", "settings", "settings shut", "lock", "minimize", "all shut" })
    if what == "sheet" then RPSheet:ToggleWindow()
    elseif what == "items" then RPSheet:ToggleItemBrowser()
    elseif what == "stable" then RPSheet:ToggleMountBrowser()
    elseif what == "crafting" then
        if not Z.HasCharacter() or #RPSheet:Professions("make") == 0 then Z.Skip() end
        RPSheet:ShowCrafting()
    elseif what == "settings" then
        if not Z.Idle() then Z.Skip() end
        AceConfigDialog:Open(MAIN)
        -- a page of it, as a click on the tree or the tabs
        local groups = {}
        for _, row in ipairs(Z.Rows(Z.Options(MAIN))) do
            if row.kind == "group" and not row.option.inline then groups[#groups + 1] = row end
        end
        local path = {}
        for key in Z.Choose("page", groups, function(row) return row.path end).path:gmatch("[^.]+") do path[#path + 1] = key end
        table.remove(path, 1)
        AceConfigDialog:SelectGroup(MAIN, unpack(path))
    elseif what == "settings shut" then AceConfigDialog:Close(MAIN)
    elseif what == "lock" then RPSheet:ToggleLock()
    elseif what == "minimize" then RPSheet:ToggleMinimized()
    else
        for _, entry in ipairs(Z.Windows()) do entry.window:Hide() end
        AceConfigDialog:Close(MAIN)
    end
end })

---------------------------------------------------------------------------
-- Reload
---------------------------------------------------------------------------
-- The game side is thrown away and loaded again from the saved variables. What the
-- reload can't keep (a roll on its way, an open dialog) is gone, as in the game.
function Z.Reload()
    Z.held = {}
    local problems = Z.problems
    local text = Z.Logout()
    Z.Reset(text)
    for _, problem in ipairs(Z.problems) do problems[#problems + 1] = problem end
    Z.problems = problems
end
-- A reload leaves the character as it was. After a free edit the first reload may
-- still tidy up (a class feature's text the player rewrote is the addon's again):
-- then a second one must change nothing.
function Z.ReloadSame()
    if Z.HasCharacter() and Z.IsFree() then Z.Reload() end
    local before = Z.HasCharacter() and Z.Dump() or nil
    Z.Reload()
    if before then
        local difference = Z.Compare(before, Z.Dump())
        if difference then Z.Report("reload", "after a reload the character differs: " .. difference) end
    end
end
Action("reload", { weight = 1.2, run = function() Z.ReloadSame() end })

---------------------------------------------------------------------------
-- Total RP 3
---------------------------------------------------------------------------
local PROFILES = { p1 = { profileName = "First", firstName = "Alia" }, p2 = { profileName = "Second", firstName = "Borin" },
    p3 = { profileName = "Third" } }
Action("trp3", { weight = 0.8, run = function()
    if not Z.trp3 then
        -- installed since the last session
        Z.trp3 = { current = "p1", profiles = PROFILES }
        Z.Reload()
    elseif Z.Flip("remove", 0.1) then
        Z.trp3 = false
        Z.Reload()
    else
        local ids = {}
        for id in pairs(Z.trp3.profiles) do if id ~= Z.trp3.current then ids[#ids + 1] = id end end
        TRP3_API.profile.selectProfile((Z.Choose("profile", ids)))
    end
end })
