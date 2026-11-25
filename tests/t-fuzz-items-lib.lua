-- The random-play tester's actions, part 2: things. Items are added, bought,
-- equipped, attuned, used and removed, mounts bought and ridden, companions called,
-- things made, gathered and scribed, through the rows and buttons that do it: a tab
-- of the sheet is opened and one of its rows clicked, or a browser window is opened
-- (what is carried, the stable, the workshop) and one of its buttons pressed.
local Z = FUZZ
local Action = Z.Action

local function Shown(window) return window ~= nil and not IsStub(window) and window.frame:IsShown() end
local function Label(part) return (part.type .. " " .. F.Plain(PartText(part)):gsub("%s+", " "):sub(1, 48)) end
local BUTTONS = { "LeftButton", "LeftButton", "LeftButton", "RightButton" }
local KEYS = { "", "", "", "shift", "ctrl" }

local function ClickOne(parts)
    local part = Z.Choose("row", parts, Label)
    local keys = Z.Choose("keys", KEYS)
    F.menu = nil
    F.SetKeys(keys == "shift", keys == "ctrl", false)
    F.MoveMouse(part.frame, 0.9, 0.5)
    local ok, problem = xpcall(F.Click, function(message) return debug.traceback(tostring(message), 2) end, part.frame, (Z.Choose("button", BUTTONS)))
    F.SetKeys(false, false, false)
    F.MoveMouse(nil)
    if not ok then error(problem, 0) end
end

-- A tab of the sheet, then one of the rows under the tab strip.
Action("tab row", { weight = 22, guard = function() return Z.HasCharacter() and Shown(RPSheet.window) end, run = function()
    local tabs = {}
    for _, part in ipairs(RPSheet.body.children) do
        if part.type == "RPSheetTab" then tabs[#tabs + 1] = part end
    end
    local tab = Z.Choose("tab", tabs, function(part) return part.text:GetText() end)
    F.Click(tab.frame, "LeftButton")
    F.Settle()
    local rows, below = {}, false
    for _, part in ipairs(RPSheet.body.children) do
        if part.type == "RPSheetTab" then below = true
        elseif below and part.events and part.events.OnClick and part.frame:IsVisible() then rows[#rows + 1] = part end
    end
    ClickOne(rows)
end })

-- A browser window: opened on one of its kinds, then a button, a tab or a label of it.
Action("browser", { weight = 22, guard = Z.HasCharacter, run = function()
    local what = Z.Choose("what", { "open", "open", "items", "stable", "crafting" })
    if what == "items" or (what == "open" and not Shown(RPSheet.itemWindow)) then
        RPSheet:ToggleItemBrowser()
        if not Shown(RPSheet.itemWindow) then RPSheet:ToggleItemBrowser() end
    elseif what == "stable" then
        if not Shown(RPSheet.itemWindow) or Z.Flip("again", 0.5) then RPSheet:ToggleMountBrowser() end
    elseif what == "crafting" then
        if #RPSheet:Professions("make") == 0 then Z.Skip() end
        local professions = RPSheet:Professions("make")
        RPSheet:ShowCrafting(Z.Flip("any", 0.3) and nil or Z.Choose("profession", professions, function(entry) return entry.name end))
    end
    F.Settle()
    if not Shown(RPSheet.itemWindow) then return end
    local parts = {}
    for _, part in ipairs(Parts(RPSheet.itemWindow)) do
        local kind = part.type
        if part.frame:IsVisible() and ((kind == "Button" and part.frame:IsEnabled())
            or ((kind == "RPSheetButton" or kind == "RPSheetTab") and not part.disabled and part.events and part.events.OnClick)) then
            parts[#parts + 1] = part
        end
    end
    ClickOne(parts)
    -- closed again half the time: with it open every change to the sheet refills it
    if Z.Flip("shut", 0.5) and Shown(RPSheet.itemWindow) then RPSheet.itemWindow:Hide() end
end })

-- Something carried, as its row on the sheet does it.
Action("item", { weight = 8, guard = function() return Z.HasCharacter() and #RPSheet:Sheet().items > 0 end, run = function()
    local item = Z.Choose("item", RPSheet:Sheet().items, function(entry) return entry.name end)
    local what = Z.Choose("what", { "equip", "equip", "attune", "use" })
    if what == "equip" then RPSheet:ToggleEquipped(item)
    elseif what == "attune" then RPSheet:ToggleAttuned(item)
    else RPSheet:UseItem(item) end
end })

-- The coin row: a box asks how much (answered by the "popup" action).
Action("coins", { weight = 3, guard = Z.HasCharacter, run = function()
    RPSheet:CoinDialog(Z.Flip("spend", 0.4))
end })

-- A mount or companion owned, as its row does it.
Action("mount", { weight = 5, guard = function() return Z.HasCharacter() and #RPSheet:Mounts() > 0 end, run = function()
    local entry = Z.Choose("mount", RPSheet:Mounts(), function(mount) return mount.name end)
    if entry.kind == "COMPANION" then
        local what = Z.Choose("what", { "call", "call", "hurt", "treat" })
        if what == "hurt" then RPSheet:HurtCompanion(entry)
        elseif what == "treat" then RPSheet:TreatCompanion(entry)
        else RPSheet:ToggleCompanion(entry) end
    else
        RPSheet:ToggleRiding(entry)
    end
end })
