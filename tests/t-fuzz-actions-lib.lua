-- The random-play tester's actions, part 1: what a player does with the mouse (any
-- row of any open window, any button, any modifier, menus and popups answered or
-- left), the dice (kept back, landing late, never landing), and play itself called
-- as the rows call it: casting, attacking, abilities, damage, healing, conditions,
-- exhaustion, rests, hit dice, /sheet.
local Z = FUZZ
local Action = Z.Action

local function HasCharacter()
    local state = RPSheet:State()
    return state ~= nil and R.CLASSES[state.sheet.class] ~= nil
end
Z.HasCharacter = HasCharacter
-- No wizard or level dialog in the way (they are finished or closed by their own actions).
local function Idle() return not W.draft and not ns.LevelDialog.draft end
Z.Idle = Idle
local function Playing() return HasCharacter() end

---------------------------------------------------------------------------
-- The mouse
---------------------------------------------------------------------------
local function Clickable(part)
    local kind = part.type
    if kind == "RPSheetButton" or kind == "RPSheetBar" or kind == "RPSheetTab" then
        if part.disabled then return false end
        return part.events and part.events.OnClick ~= nil and part.frame:IsVisible()
    end
    if kind == "Button" then return part.frame:IsEnabled() and part.frame:IsVisible() end
    return false
end
local function Label(part)
    return (part.type .. " " .. F.Plain(PartText(part)):gsub("%s+", " "):sub(1, 48))
end
-- The parts of the open windows a player could click, as { part, window key }.
function Z.Clickables()
    local list = {}
    for _, entry in ipairs(Z.Windows()) do
        for _, part in ipairs(Parts(entry.window)) do
            if part ~= entry.window and Clickable(part) then list[#list + 1] = { part = part, key = entry.key } end
        end
    end
    return list
end

local BUTTONS = { "LeftButton", "LeftButton", "LeftButton", "RightButton", "MiddleButton" }
local KEYS = { "", "", "", "shift", "ctrl", "alt", "shift+ctrl", "ctrl+alt" }
local function Click(part, button, keys, mark)
    F.menu = nil -- a click elsewhere closes an open menu
    F.SetKeys(keys:find("shift") ~= nil, keys:find("ctrl") ~= nil, keys:find("alt") ~= nil)
    if mark and part.mark and part.mark:IsShown() then part = { frame = part.mark } end
    F.MoveMouse(part.frame, 0.5, 0.5, 0)
    local ok, problem = xpcall(F.Click, function(message) return debug.traceback(tostring(message), 2) end, part.frame, button)
    F.SetKeys(false, false, false)
    F.MoveMouse(nil)
    if not ok then error(problem, 0) end
end

Action("click", { weight = 30, guard = function() return #Z.Windows() > 0 end, run = function()
    local target = Z.Choose("row", Z.Clickables(), function(item) return item.key .. ": " .. Label(item.part) end)
    Click(target.part, Z.Choose("button", BUTTONS), Z.Choose("keys", KEYS), Z.Flip("mark", 0.1))
end })

-- The mouse over a row and away: its tooltip is read.
Action("hover", { weight = 4, guard = function() return #Z.Windows() > 0 end, run = function()
    local list = {}
    for _, entry in ipairs(Z.Windows()) do
        for _, part in ipairs(Parts(entry.window)) do
            if part ~= entry.window and part.frame:IsVisible() and part.events and part.events.OnEnter then list[#list + 1] = { part = part, key = entry.key } end
        end
    end
    local target = Z.Choose("row", list, function(item) return item.key .. ": " .. Label(item.part) end)
    F.Enter(target.part.frame)
    for _, line in ipairs(F.TooltipLines() or {}) do
        if Z.OddText(line.text) then Z.Report("text", "tooltip of " .. Label(target.part) .. ": " .. Z.OddText(line.text)) end
    end
    F.Leave(target.part.frame)
    if GameTooltip:IsShown() then GameTooltip:Hide() end
end })

-- Typing into a search box of a browser window.
local WORDS = { "", "sword", "potion", "a", "zz", "of", "%", "(", "[", "Heal", "  ", "1" }
Action("search", { weight = 2, guard = function() return RPSheet.itemWindow ~= nil and not IsStub(RPSheet.itemWindow) and RPSheet.itemWindow.frame:IsShown() end, run = function()
    local boxes = {}
    for _, part in ipairs(Parts(RPSheet.itemWindow)) do
        if part.type == "EditBox" and part.frame:IsVisible() then boxes[#boxes + 1] = part end
    end
    if #boxes == 0 then Z.Skip() end
    F.Type(boxes[1].editbox, (Z.Choose("text", WORDS)), true)
end })

Action("menu", { weight = 150, guard = function() return F.menu ~= nil end, run = function()
    local rows = {}
    for _, row in ipairs(F.MenuRows()) do
        if Z.OddText(row.text) then Z.Report("text", "menu row: " .. Z.OddText(row.text)) end
        if row.enabled then rows[#rows + 1] = row end
    end
    if #rows == 0 or Z.Flip("leave", 0.15) then F.menu = nil return end
    F.MenuClick((Z.Choose("row", rows, function(row) return F.Plain(row.text) end)))
end })

local TYPED = { "", "0", "1", "3", "7", "12", "40", "250", "9999", "-5", "2.5", "lots", "12 gp", "5 5", " 8 ", "1e3", "007" }
Action("popup", { weight = 90, guard = function() return F.popup ~= nil end, run = function()
    local dialog = F.popup
    if Z.OddText(F.PopupText() or "") then Z.Report("text", "popup: " .. Z.OddText(F.PopupText())) end
    local how = Z.Choose("how", { "accept", "accept", "accept", "enter", "cancel", "escape" })
    if dialog.EditBox:IsShown() then
        F.PopupType((Z.Choose("text", TYPED)), how == "enter")
        if how == "enter" then return end
    end
    if how == "cancel" then F.PopupCancel() elseif how == "escape" then F.PopupEscape() else F.PopupAccept() end
end })

---------------------------------------------------------------------------
-- Dice
---------------------------------------------------------------------------
-- From now on the game is slow to answer /roll: results wait until they are landed.
Action("hold rolls", { weight = 1.5, guard = function() return not Z.hold end, run = function() Z.hold = true end })
Action("land rolls", { weight = 12, guard = function() return #Z.held > 0 end, run = function()
    -- each result may start the next roll, which waits again while rolls are held
    local stop = Z.Flip("stop", 0.3)
    if stop then Z.hold = false end
    for _ = 1, Z.hold and Z.Int("count", 1, 3) or 200 do
        local roll = table.remove(Z.held, 1)
        if not roll then break end
        Z.Land(roll[1], roll[2])
    end
end })
-- The results never come: three seconds pass and the addon gives the roll up. What
-- was held then arrives after all, too late (or is lost for good).
Action("lose rolls", { weight = 4, guard = function() return #Z.held > 0 end, run = function()
    F.Settle(true)
    Z.waiting = false
    local late = Z.Flip("late", 0.5)
    local held = Z.held
    Z.held = {}
    if Z.Flip("stop", 0.5) then Z.hold = false end
    if late then for _, roll in ipairs(held) do Z.Land(roll[1], roll[2]) end end
end })
-- Somebody else's roll, and one of ours nobody asked for.
Action("stray roll", { weight = 1, run = function()
    local sides = Z.Choose("sides", { "20", "6", "8", "100", "4" })
    local line = Z.Flip("own", 0.5) and ("Tester rolls %d (1-%s)"):format(Z.Int("value", 1, tonumber(sides)), sides)
        or ("Other rolls 3 (1-%s)"):format(sides)
    RPSheet:CHAT_MSG_SYSTEM(nil, line)
end })
-- Time passes: every timer that was waiting runs (a few seconds of the game).
Action("wait", { weight = 3, run = function()
    F.Settle(true)
    if #Z.held == 0 then Z.waiting = false end
end })

---------------------------------------------------------------------------
-- Play, called as the rows call it
---------------------------------------------------------------------------
local MODES = { "none", "none", "ADV", "DIS" }
local function Mode() local mode = Z.Choose("mode", MODES) return mode ~= "none" and mode or nil end
local function Named(key, list) return Z.Choose(key, list, function(entry) return entry.name end) end

Action("cast", { weight = 10, guard = function() return Playing() and #RPSheet:Sheet().spells > 0 end, run = function()
    local spell = Named("spell", RPSheet:Sheet().spells)
    -- the slot level row: clicked a few times to cast with a higher slot
    for _ = 1, Z.Int("slotClicks", 0, 12) - 6 do RPSheet:CycleCastLevel() end
    Z.cast = spell.name -- (for the cases that need a certain spell)
    RPSheet:CastSpell(spell, Mode(), Z.Flip("ritual", 0.15))
end })
Action("ability", { weight = 10, guard = function() return Playing() and #RPSheet:Sheet().abilities > 0 end, run = function()
    RPSheet:UseAbility(Named("ability", RPSheet:Sheet().abilities), Mode())
end })
-- Into a beast form, whichever the character knows (the "ability" action does it
-- too, among everything else; this one is for the cases).
Action("wild shape", { weight = 1.5, guard = Playing, run = function()
    local forms = {}
    for _, ability in ipairs(RPSheet:Sheet().abilities) do
        if ability.name:find("^Wild Shape: ") then forms[#forms + 1] = ability end
    end
    RPSheet:UseAbility(Named("form", forms), nil)
end })
Action("attack", { weight = 5, guard = Playing, run = function()
    if Z.Flip("swap", 0.3) then RPSheet:SwapWeapon() end
    RPSheet:Attack(Mode())
end })
Action("check", { weight = 3, guard = Playing, run = function()
    local what = Z.Choose("what", { "skill", "save", "check", "initiative", "death" })
    if what == "skill" then
        local skill = Z.Choose("skill", R.SKILLS, function(entry) return entry.name end)
        RPSheet:RollCheck(skill.name, RPSheet:SkillMod(skill), Mode())
    elseif what == "save" then
        local stat = Z.Choose("stat", R.STATS)
        RPSheet:RollCheck(stat .. " save", RPSheet:SaveMod(stat), Mode())
    elseif what == "check" then
        local stat = Z.Choose("stat", R.STATS)
        RPSheet:RollCheck(stat .. " check", RPSheet:CheckMod(stat), Mode())
    elseif what == "initiative" then
        RPSheet:RollCheck("initiative", RPSheet:Initiative(), Mode())
    else
        RPSheet:RollDeathSave()
    end
end })

local AMOUNTS = { 0, 1, 2, 3, 5, 8, 13, 21, 40, 75, 150, 400, 9999 }
Action("damage", { weight = 8, guard = Playing, run = function()
    local kinds = { "none" }
    for _, kind in ipairs(R.DAMAGE_TYPES) do kinds[#kinds + 1] = kind end
    local kind = Z.Choose("type", kinds)
    RPSheet:TakeDamage(tonumber((Z.Choose("amount", AMOUNTS))), kind ~= "none" and kind or nil)
end })
Action("heal", { weight = 5, guard = Playing, run = function()
    RPSheet:Heal(tonumber((Z.Choose("amount", AMOUNTS))))
end })
Action("condition", { weight = 5, guard = Playing, run = function()
    RPSheet:ToggleCondition(Z.Choose("name", R.CONDITIONS, function(entry) return entry.name end).name)
end })
Action("exhaustion", { weight = 3, guard = Playing, run = function()
    RPSheet:ChangeExhaustion(Z.Flip("more", 0.6) and 1 or -1)
end })
Action("long rest", { weight = 2, guard = Playing, run = function() RPSheet:LongRest() end })
Action("short rest", { weight = 3, guard = Playing, run = function() RPSheet:ShortRest() end })
Action("hit die", { weight = 3, guard = Playing, run = function()
    local pools = {}
    for _, tracker in ipairs(RPSheet:GetTrackers()) do
        if tracker.kind == "hitdice" then pools[#pools + 1] = tracker end
    end
    RPSheet:SpendHitDie((Z.Choose("pool", pools, function(tracker) return tracker.label end)))
end })

-- /sheet with anything after it.
local SLASH = { "", "config", "lock", "lock", "new", "rest", "help", "damage", "damage 5", "damage 12 fire", "damage 7 cold - 3", "damage 99999",
    "damage five", "damage 3 nonsense", "heal", "heal 4", "heal 9999", "heal -2", "DAMAGE 6 FIRE", "  rest  ", "what", "damage 4 fire extra words", "100%", "new new" }
Action("slash", { weight = 3, run = function()
    local line = Z.Choose("line", SLASH)
    -- the wizard and the settings are other actions' business
    if (line:find("new") or line == "config") and not Z.Idle() then Z.Skip() end
    RPSheet:SlashCommand(line)
end })
