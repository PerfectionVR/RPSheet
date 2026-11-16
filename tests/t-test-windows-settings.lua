-- The settings window, really built by the options library, for several characters:
-- every tab and every page of the Customize tree is opened and must show a control
-- for each of its options; every control is hovered and worked the way a player does
-- (ticked on and off, every value of a dropdown chosen from its list, sliders dragged
-- to both ends, texts typed, buttons pressed and their questions answered). After
-- every page the sheet must still pass the smoke checks; the character is then put
-- back as it was, so buttons that replace or wipe it are pressed too.
-- usage: run.sh t-test-windows-settings.lua [quick]
dofile(ARG3 .. "/t-test-windows-base.lua")
dofile(ARG3 .. "/t-test-windows-dialog.lua")
Start()

local APP = "RPSheet"
local D = Dialog
local QUICK = ARG4 == "quick"
local stats = { pages = 0, controls = 0, terms = 0, entries = 0, direct = 0, treeClicks = 0 }
local function Check(what, ok) if not ok then Problem(what) end end

-- Other windows a button may have opened are shut, and the settings brought back.
local function Tidy()
    if W.draft then W.draft = nil end
    if ns.LevelDialog and ns.LevelDialog.draft then ns.LevelDialog.draft = nil end
    for _, other in ipairs({ "RPSheetWizard", "RPSheetLevel" }) do
        if AceConfigDialog.OpenFrames[other] then AceConfigDialog:Close(other) end
    end
    for _, key in ipairs({ "itemWindow", "bookWindow", "preparedWindow" }) do
        if RPSheet[key] and RPSheet[key].frame:IsShown() then RPSheet[key]:Hide() end
    end
    if F.popup then F.PopupCancel() end
    F.Settle()
    if not D.Shown(APP) then
        AceConfigDialog:Open(APP)
        F.Settle()
    end
end

-- Calls an option's set as the dialog would, without the window: for the many pages
-- of a list that all look alike. Every value is put back.
local function Direct(option, path, where)
    local info = D.Info(APP, option, path)
    if D.Hidden(APP, option, path) or D.Member(option, "disabled", info) then return end
    local get, set = option.get, option.set
    if type(set) ~= "function" or type(get) ~= "function" then return end
    local kind = option.type
    stats.direct = stats.direct + 1
    if kind == "toggle" then
        local was = Try(where .. " get", get, info)
        Try(where .. " set", set, info, not was)
        Try(where .. " set back", set, info, was)
    elseif kind == "select" then
        local was = Try(where .. " get", get, info)
        local values = D.Member(option, "values", info) or {}
        local keys = {}
        for key in pairs(values) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for index = 1, #keys, math.max(1, math.floor(#keys / 6)) do
            Try(where .. " set " .. tostring(keys[index]), set, info, keys[index])
        end
        if was ~= nil then Try(where .. " set back", set, info, was) end
    elseif kind == "multiselect" then
        for key in pairs(D.Member(option, "values", info) or {}) do
            local was = Try(where .. " get", get, info, key)
            Try(where .. " set", set, info, key, not was)
            Try(where .. " set back", set, info, key, was)
        end
    elseif kind == "range" then
        local was = Try(where .. " get", get, info)
        Try(where .. " set min", set, info, option.min)
        Try(where .. " set max", set, info, option.max)
        if was then Try(where .. " set back", set, info, was) end
    elseif kind == "input" then
        local was = Try(where .. " get", get, info)
        Try(where .. " set", set, info, tonumber(was) and "7" or "Test text")
        Try(where .. " set back", set, info, was or "")
    end
    RPSheet.busy = false
end

-- One page: shown, checked, hovered, and (with `work`) every control worked.
local function Page(label, page, work)
    local path, group = page.path, page.group
    local where = label .. " page " .. table.concat(path, "/")
    Try(where .. " open", D.Open, APP, path)
    CheckHidden(where)
    stats.pages = stats.pages + 1
    if not D.Shown(APP) then Problem(where .. ": the settings window is gone") Tidy() return end

    -- every option of the page that isn't hidden has a control, and the page nothing else
    local options = D.PageOptions(APP, group, path)
    local shown = 0
    for _, entry in ipairs(options) do
        local option = entry.option
        local hidden = entry.hidden
        local control = D.Control(APP, option)
        if not hidden and not control then
            Problem(("%s: the option %s (%s) has no control"):format(where, entry.key, tostring(option.type)))
        elseif control then
            shown = shown + 1
            stats.controls = stats.controls + 1
            local name = where .. " " .. entry.key
            CheckText(name, PartText(control))
            D.Hover(name, control)
            stats.terms = stats.terms + D.HoverTerms(name, control)
        end
    end
    -- the texts of everything on the page
    for _, part in ipairs(Parts(D.Root(APP))) do
        CheckText(where, PartText(part))
        if part.type == "Dropdown" then
            for _, text in pairs(part.list or {}) do CheckText(where .. " dropdown", text) end
        end
    end
    if not work then return shown end

    -- Options made in a row from one mould (recipe1, recipe2, ... tool37): the first
    -- two and the last are worked through the window, the others set without it.
    local family, size, place = {}, {}, {}
    for _, entry in ipairs(options) do
        local name = entry.key:match("^(.-)%d+$")
        if name then
            family[entry] = name .. "|" .. tostring(entry.option.type)
            size[family[entry]] = (size[family[entry]] or 0) + 1
        end
    end
    for _, entry in ipairs(options) do
        local option = entry.option
        local name = where .. " " .. entry.key
        local through = true
        local kin = family[entry]
        if kin and size[kin] > 4 then
            place[kin] = (place[kin] or 0) + 1
            through = place[kin] <= 2 or place[kin] == size[kin]
        end
        if not through then
            if not entry.hidden then Direct(option, entry.path, name) end
        elseif entry.hidden then
            -- nothing to work
        elseif D.Control(APP, option) then
            if ARG5 == "progress" and rawget(_G, "ARG6") and where:find(ARG6, 1, true) then print(("%.1fs   %s %s"):format(os.clock(), entry.key, tostring(option.type))) io.stdout:flush() end
            D.Work(APP, option, name, QUICK and 6 or 25)
            Tidy()
            -- a button may have moved the window to another page
            if not D.Control(APP, option) then Try(where .. " reopen", D.Open, APP, path) end
        end
    end
    return shown
end

-- Clicks through the tabs and the tree as a player would, instead of by path.
local function ClickAround(label)
    local root = D.Root(APP)
    local tabs
    for _, part in ipairs(Parts(root)) do
        if part.type == "TabGroup" then tabs = part break end
    end
    if not tabs then Problem(label .. ": the settings window has no tabs") return end
    local names = {}
    for index, entry in ipairs(tabs.tablist) do names[index] = entry.value end
    for index, value in ipairs(names) do
        local now
        for _, part in ipairs(Parts(D.Root(APP))) do
            if part.type == "TabGroup" then now = part break end
        end
        local button = now.tabs[index]
        Try(label .. " hover tab " .. tostring(value), F.Enter, button)
        Try(label .. " leave tab", F.Leave, button)
        Try(label .. " click tab " .. tostring(value), F.Click, button)
        F.Settle()
        CheckHidden(label .. " tab " .. tostring(value))
        stats.treeClicks = stats.treeClicks + 1
        local status = AceConfigDialog:GetStatusTable(APP)
        Check(("%s: clicking the tab %s selected %s"):format(label, tostring(value), tostring(status.groups and status.groups.selected)),
            status.groups and status.groups.selected == value)
        -- a tree on this tab: every line clicked, every plus opened
        local function Tree()
            for _, part in ipairs(Parts(D.Root(APP))) do
                if part.type == "TreeGroup" then return part end
            end
        end
        local tree = Tree()
        local guard = 0
        local clicked = {}
        while tree and guard < 400 do
            guard = guard + 1
            local target
            for _, button in ipairs(tree.buttons) do
                if button:IsShown() and button.uniquevalue and not clicked[button.uniquevalue] then target = button break end
            end
            if not target then break end
            clicked[target.uniquevalue] = true
            local unique = target.uniquevalue
            Try(label .. " hover tree line", F.Enter, target)
            Try(label .. " leave tree line", F.Leave, target)
            Try(label .. " click tree line " .. tostring(unique), F.Click, target)
            stats.treeClicks = stats.treeClicks + 1
            F.Settle()
            CheckHidden(label .. " tree line " .. tostring(unique))
            tree = Tree()
            if tree then
                Check(label .. ": clicking the tree line " .. tostring(unique):gsub("\001", "/") .. " didn't select it", (tree.status or tree.localstatus).selected == unique)
                -- its plus, if it has one, to show the lines below it
                for _, button in ipairs(tree.buttons) do
                    if button:IsShown() and button.uniquevalue == unique and button.toggle:IsShown() and not (tree.status or tree.localstatus).groups[unique] then
                        Try(label .. " open tree line", F.Click, button.toggle)
                        F.Settle()
                        tree = Tree()
                        break
                    end
                end
                -- scrolled on, so lines further down come into view
                if tree and tree.scrollbar:IsShown() then
                    local low, high = tree.scrollbar:GetMinMaxValues()
                    Try(label .. " scroll tree", F.Drag, tree.scrollbar, math.min(high, tree.scrollbar:GetValue() + 3))
                    F.Settle()
                    tree = Tree()
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- The characters
---------------------------------------------------------------------------
local function Multi()
    local sheet = NewCharacter("WARRIOR", nil, nil, 5, 2)
    sheet.classes = { MAGE = { level = 4, subclass = R.CLASSES.MAGE.subclasses[1], spec = R.CLASSES.MAGE.specs[1], skill = "", fightingStyle = "", fightingStyle2 = "" } }
    sheet.level = 9
    return sheet
end
local CHARACTERS = {
    { "paladin 11", function() return NewCharacter("PALADIN", nil, nil, 11, 1) end },
    { "mage 9", function() return NewCharacter("MAGE", nil, nil, 9, 3) end },
    { "warrior 5 / mage 4", Multi },
    { "hunter 3", function() return NewCharacter("HUNTER", nil, nil, 3, 5) end },
    { "no class", function() return ns.NewSheet() end },
}
if QUICK then CHARACTERS = { CHARACTERS[2], CHARACTERS[3] } end

for _, entry in ipairs(CHARACTERS) do
    local label = entry[1]
    local function Fresh()
        local sheet = entry[2]()
        if R.CLASSES[sheet.class] then
            Use(sheet)
            for _, name in ipairs({ "Longsword", "Shield", "Chain Mail", "Rope", "Dagger" }) do
                local item = RPSheet:AddItem(name, 1)
                if item then RPSheet:SetEquipped(item, true) end
            end
            RPSheet:AddMount(R.MOUNT_NAMES and R.MOUNT_NAMES[next(R.MOUNT_NAMES)] and R.MOUNT_NAMES[next(R.MOUNT_NAMES)][1] or "")
            RPSheet:AddCoins(100000)
        else
            RPSheet:ReplaceSheet(sheet)
            RPSheet:State().created = true
        end
        ns.RebuildOptions()
        RPSheet:SheetChanged()
        F.Settle(true)
    end
    Try(label .. " build", Fresh)
    Try(label .. " open settings", function()
        AceConfigDialog:Open(APP)
        F.Settle()
    end)
    Check(label .. ": the settings window doesn't open", D.Shown(APP))
    CheckHidden(label .. " open")
    local root = D.Root(APP)
    if root then
        Check(label .. ": the settings window's title is " .. tostring(root.titletext:GetText()), root.titletext:GetText() == "RP Sheet")
    end
    if ARG5 == "progress" then print(("%.1fs %s click around"):format(os.clock(), label)) io.stdout:flush() end
    Try(label .. " click around", ClickAround, label)

    -- every page, by its path
    local pages = D.Pages(APP, D.Options(APP))
    Check(label .. ": only " .. #pages .. " pages", #pages >= 20)
    -- the entries of a list (an ability, a spell, an item...) look alike: the first
    -- two and the last of each list are worked through the window, the rest is opened
    -- and its options are set without it
    local listOf, seen = {}, {}
    for _, page in ipairs(pages) do
        local path = page.path
        if path[1] == "customize" and #path == 3 and path[3]:find("^item%d+$") then
            listOf[page] = path[2]
            seen[path[2]] = (seen[path[2]] or 0) + 1
        end
    end
    local at = {}
    for _, page in ipairs(pages) do
        local list = listOf[page]
        local where = label .. " page " .. table.concat(page.path, "/")
        local work = true
        if list then
            at[list] = (at[list] or 0) + 1
            stats.entries = stats.entries + 1
            work = at[list] <= 2 or at[list] == seen[list]
        end
        -- the page may be gone since the list was made (an entry deleted on another page)
        local group = D.Options(APP)
        for _, key in ipairs(page.path) do group = group and group.args and group.args[key] end
        if group then
            page.group = group
            if ARG5 == "progress" then print(("%.1fs %s %s"):format(os.clock(), where, work and "" or "(direct)")) io.stdout:flush() end
            Try(where, Page, label, page, work)
            if not work then
                for _, option in ipairs(D.PageOptions(APP, group, page.path)) do
                    if not option.hidden then Direct(option.option, option.path, where .. " " .. option.key) end
                end
                Try(where .. " settle", F.Settle)
                CheckHidden(where)
            end
            Tidy()
            SmokeChecks(where)
            if work then Try(where .. " rebuild", Fresh) end
        end
    end
    Try(label .. " close", function()
        AceConfigDialog:Close(APP)
        F.Settle()
    end)
    Check(label .. ": the settings window doesn't close", not D.Shown(APP))
    CheckHidden(label .. " close")
end

local c = D.count
Finish("settings", ("%d characters, %d pages opened (%d list entries), %d controls hovered, %d tab and tree clicks, %d hoverable words; worked: %d ticks, %d dropdown values, %d slider moves, %d texts, %d buttons (%d questions answered, %d refusals), %d colours, %d disabled left alone, %d options set without the window"):format(
    #CHARACTERS, stats.pages, stats.entries, stats.controls, stats.treeClicks, stats.terms,
    c.toggles, c.selects, c.ranges, c.inputs, c.executes, c.confirms, c.refused, c.colors, c.disabled, stats.direct))
