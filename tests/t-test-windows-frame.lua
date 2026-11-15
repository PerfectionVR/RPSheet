-- The sheet window as a window: its title buttons, closing and reopening, locking,
-- minimizing (folding when the mouse is away, opening when it is over), moving, and
-- resizing from the smallest width up to 900: at every width no tab and no row of
-- part-width rows may wrap, and no rows may lie over each other.
dofile(ARG3 .. "/t-test-windows-base.lua")
Start()

local TABS = { "Actions", "Checks", "Skills", "Traits", "Items", "Trade" }
local saved, profile = RPSheet.db.char, RPSheet.db.profile
local window = RPSheet.window
local frame = window.frame
local widths, rowsChecked = 0, 0

local function Check(what, ok)
    if not ok then Problem(what) end
end
local function TipTitle(button)
    F.Enter(button)
    local lines = F.TooltipLines()
    local title = lines and lines[1] and lines[1].text
    if lines and (not lines[2] or lines[2].text == "") then Problem("title button tooltip without a body: " .. tostring(title)) end
    F.Leave(button)
    Check("the tooltip of a title button stays open", not GameTooltip:IsShown())
    return title
end

Use(NewCharacter("PALADIN", nil, nil, 9, 2))
for _, name in ipairs({ "Longsword", "Shield", "Chain Mail", "Rope" }) do
    local item = RPSheet:AddItem(name, 1)
    RPSheet:SetEquipped(item, true)
end
RPSheet:SheetChanged()
F.Settle(true)

---------------------------------------------------------------------------
-- Closing and reopening
---------------------------------------------------------------------------
Try("close and reopen", function()
    Check("the window isn't shown after login with shown saved", frame:IsShown() and saved.shown == true)
    Check("title is not the character's name", window.titleText:GetText() == RPSheet:GetCharacterName())
    local close
    for _, child in ipairs({ frame:GetChildren() }) do
        if child:IsObjectType("Button") and child ~= window.lockButton and child ~= window.editButton and child ~= window.minimizeButton then close = child end
    end
    F.Click(close)
    Check("the close button leaves the window open", not frame:IsShown())
    Check("closing isn't remembered", saved.shown == false)
    -- a change while it is closed is caught up with when it opens
    local rowsBefore = #RPSheet.body.children
    RPSheet:State().conditions.Prone = true
    RPSheet:SheetChanged()
    F.Settle()
    Check("rows were rebuilt while the window was closed", RPSheet.populateSkipped == true)
    RPSheet:ToggleWindow()
    F.Settle()
    Check("ToggleWindow doesn't open the window", frame:IsShown() and saved.shown == true)
    local found
    for _, part in ipairs(RPSheet.body.children) do
        if F.Plain(PartText(part)):find("Conditions Prone", 1, true) then found = true end
    end
    Check("the reopened window doesn't show a change made while it was closed", found)
    RPSheet:State().conditions.Prone = nil
    RPSheet:SheetChanged()
    RPSheet:SlashCommand("")
    Check("/sheet doesn't close the window", not frame:IsShown())
    RPSheet:SlashCommand("")
    Check("/sheet doesn't open the window", frame:IsShown())
    F.Settle()
end)

---------------------------------------------------------------------------
-- Locking
---------------------------------------------------------------------------
Try("lock", function()
    Check("unlocked tooltip", TipTitle(window.lockButton) == "Lock window")
    F.Click(window.lockButton)
    F.Settle()
    Check("clicking the padlock doesn't lock", profile.locked == true and window.locked == true)
    Check("a locked window's frame still takes the mouse", not frame:IsMouseEnabled() and not window.titleBar:IsMouseEnabled())
    Check("a locked window shows its resize grip", not window.sizer:IsShown())
    Check("locked padlock isn't solid", window.lockButton.icon:GetAlpha() == 1)
    Check("locked tooltip", TipTitle(window.lockButton) == "Unlock window")
    -- the rows stay clickable
    local label = RPSheet.inspirationLabel
    local before = RPSheet:State().inspiration
    ClickPart("inspiration while locked", label, "LeftButton")
    Check("a row of a locked window can't be clicked", RPSheet:State().inspiration ~= before)
    RPSheet:SlashCommand("lock")
    F.Settle()
    Check("/sheet lock doesn't unlock", profile.locked == false and window.locked == false)
    Check("an unlocked window's frame ignores the mouse", frame:IsMouseEnabled() and window.titleBar:IsMouseEnabled())
    Check("an unlocked window hides its resize grip", window.sizer:IsShown())
    Check("unlocked padlock isn't faded", window.lockButton.icon:GetAlpha() < 1)
end)

---------------------------------------------------------------------------
-- Moving
---------------------------------------------------------------------------
Try("move", function()
    F.Fire(window.titleBar, "OnMouseDown", "LeftButton")
    Check("the title bar doesn't start a move", F.S[frame].moving == true)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 222, 777)
    F.Fire(window.titleBar, "OnMouseUp", "LeftButton")
    Check("the move isn't ended", F.S[frame].moving == nil)
    Check("the new place isn't saved", profile.window.left == 222 and profile.window.top == 777)
    window:ApplyStatus()
    Check("the saved place isn't restored", frame:GetLeft() == 222 and frame:GetTop() == 777)
end)

---------------------------------------------------------------------------
-- Minimizing
---------------------------------------------------------------------------
Try("minimize", function()
    local full = frame:GetHeight()
    local left, top = frame:GetLeft(), frame:GetTop()
    Check("open tooltip", TipTitle(window.minimizeButton) == "Minimize window")
    F.Click(window.minimizeButton)
    Check("clicking minus doesn't minimize", profile.minimized == true and window.minimized == true)
    Check("minimized tooltip", TipTitle(window.minimizeButton) == "Keep window open")
    -- mouse away: folds after a moment, not at once
    F.MoveMouse(nil)
    F.Update(0.2)
    Check("folds before the delay is over", not window.collapsed and frame:GetHeight() == full)
    F.Update(0.25)
    Check("doesn't fold when the mouse is away", window.collapsed == true and frame:GetHeight() < 30)
    Check("a folded window shows its rows", not window.content:IsShown())
    Check("a folded window shows its resize grip", not window.sizer:IsShown())
    Check("folding moves the window's top left corner", frame:GetLeft() == left and frame:GetTop() == top)
    -- its place and size are saved as the open window's
    F.Fire(window.titleBar, "OnMouseDown", "LeftButton")
    F.Fire(window.titleBar, "OnMouseUp", "LeftButton")
    Check("a folded window saves its folded height", profile.window.height == full)
    F.Update(0.5)
    Check("stays folded", window.collapsed == true)
    -- mouse over: opens
    F.MoveMouse(frame)
    F.Update(0.02)
    Check("doesn't open under the mouse", window.collapsed == false and frame:GetHeight() == full)
    Check("an opened window hides its rows", window.content:IsShown() and window.sizer:IsShown())
    Check("opening moves the window's top left corner", frame:GetLeft() == left and frame:GetTop() == top)
    -- held open while a mouse button is down (dragging, resizing), even off the window
    F.MoveMouse(nil)
    F.buttonsDown.LeftButton = true
    F.Update(1)
    Check("folds while the mouse button is held", window.collapsed == false)
    F.buttonsDown.LeftButton = nil
    F.Update(0.5)
    Check("doesn't fold after the button is let go", window.collapsed == true)
    -- a rebuild while folded, then opening
    RPSheet:SheetChanged()
    F.Settle()
    F.MoveMouse(frame)
    F.Update(0.02)
    F.Settle()
    Check("rows are missing after opening", #RPSheet.body.children > 10 and window.content:IsShown())
    CheckOverlap(RPSheet.body, "after folding and opening")
    -- locked and minimized together
    F.MoveMouse(nil)
    F.Update(0.5)
    RPSheet:ToggleLock()
    Check("a folded, locked window shows its grip", not window.sizer:IsShown())
    F.MoveMouse(frame)
    F.Update(0.02)
    Check("a locked window doesn't open under the mouse", window.collapsed == false)
    Check("an open, locked window shows its grip", not window.sizer:IsShown())
    RPSheet:ToggleLock()
    Check("unlocking brings no grip back", window.sizer:IsShown())
    -- back to normal
    F.Click(window.minimizeButton)
    Check("clicking plus doesn't restore", profile.minimized == false and window.minimized == false and window.collapsed == false)
    Check("a restored window still watches the mouse", F.S[frame].scripts.OnUpdate == nil)
    Check("restored height", frame:GetHeight() == full)
    F.MoveMouse(nil)
    F.Update(2)
    Check("a restored window folds", window.collapsed == false)
    -- restoring while folded
    F.Click(window.minimizeButton)
    F.MoveMouse(nil)
    F.Update(0.5)
    Check("folded again", window.collapsed == true)
    RPSheet:ToggleMinimized()
    Check("restoring a folded window leaves it folded", window.collapsed == false and frame:GetHeight() == full and window.content:IsShown())
    -- the settings profile says minimized: SettingsChanged applies it
    profile.minimized = true
    RPSheet:SettingsChanged()
    Check("SettingsChanged doesn't minimize", window.minimized == true)
    profile.minimized = false
    RPSheet:SettingsChanged()
    Check("SettingsChanged doesn't restore", window.minimized == false and F.S[frame].scripts.OnUpdate == nil)
    F.Settle()
end)

---------------------------------------------------------------------------
-- The cog
---------------------------------------------------------------------------
Try("edit button", function()
    Check("cog tooltip", TipTitle(window.editButton) == "Edit character")
    F.Click(window.editButton)
    F.Settle()
    Check("the cog doesn't open the settings", AceConfigDialog.OpenFrames.RPSheet ~= nil)
    AceConfigDialog:CloseAll()
    F.Settle()
end)

---------------------------------------------------------------------------
-- Resizing
---------------------------------------------------------------------------
local function TabStrip()
    local tabs = {}
    for _, part in ipairs(RPSheet.body.children) do
        if part.type == "RPSheetTab" then tabs[#tabs + 1] = part end
    end
    return tabs
end

local function CheckWidth(label, width)
    local where = ("%s at width %d"):format(label, width)
    local tabs = TabStrip()
    Check(where .. ": " .. #tabs .. " tabs", #tabs == #TABS)
    for index = 2, #tabs do
        if not SameRow(tabs[1], tabs[index]) then
            Problem(("%s: the tab %s wrapped to another row"):format(where, tostring(tabs[index].text:GetText())))
        end
    end
    -- the tabs fill the row and don't run past it
    local last = tabs[#tabs].frame
    local edge = RPSheet.body.content:GetLeft() + RPSheet.body.content:GetWidth()
    Check(where .. ": the tabs run past the window's edge", last:GetRight() <= edge + 0.5)
    rowsChecked = rowsChecked + CheckFlowRows(RPSheet.body, where)
    CheckOverlap(RPSheet.body, where)
    -- nothing is wider than the window
    for _, part in ipairs(RPSheet.body.children) do
        if part.frame:GetRight() > edge + 0.5 then
            Problem(("%s: '%s' runs past the window's edge"):format(where, F.Plain(PartText(part)):sub(1, 30)))
            break
        end
    end
end

local minWidth, minHeight = frame:GetResizeBounds()
Check("the smallest width is " .. tostring(minWidth), minWidth == 340)

local function ResizeRun(label)
    for _, tab in ipairs(TABS) do
        saved.sheetTab = tab
        RPSheet:Populate()
        F.Settle()
        for width = minWidth, 900, 20 do
            -- as the player drags the grip: the game sizes the frame itself
            F.Fire(window.sizer, "OnMouseDown", "LeftButton")
            frame:SetWidth(width)
            F.Settle() -- the game draws frames while the grip is held
            F.Fire(window.sizer, "OnMouseUp", "LeftButton")
            F.Settle()
            widths = widths + 1
            if profile.window.width ~= width then Problem(label .. ": the width " .. width .. " isn't saved") end
            if math.abs(RPSheet.body.content:GetWidth() - (width - 16 - (RPSheet.body.scrollBarShown and 20 or 0))) > 0.5 then
                Problem(("%s: at width %d the rows are laid out for %s"):format(label, width, tostring(RPSheet.body.content:GetWidth())))
            end
            CheckWidth(label .. " tab " .. tab, width)
        end
        -- and back down in one go, then a few odd widths
        for _, width in ipairs({ minWidth, 341, 347, 353, 359.5, 401, 455, 523, 611, 700.25 }) do
            F.Fire(window.sizer, "OnMouseDown", "LeftButton")
            frame:SetWidth(width)
            F.Settle() -- the game draws frames while the grip is held
            F.Fire(window.sizer, "OnMouseUp", "LeftButton")
            F.Settle()
            widths = widths + 1
            CheckWidth(label .. " tab " .. tab, width)
        end
    end
end

Try("resize paladin", ResizeRun, "PALADIN 9")
Try("resize height", function()
    for _, height in ipairs({ minHeight, 300, 480, 900 }) do
        F.Fire(window.sizer, "OnMouseDown", "LeftButton")
        frame:SetHeight(height)
        F.Fire(window.sizer, "OnMouseUp", "LeftButton")
        F.Settle()
        Check("the height " .. height .. " isn't saved", profile.window.height == height)
        Check("at height " .. height .. " the scroll area doesn't fit the window", math.abs(RPSheet.body.scrollframe:GetHeight() - (height - 22 - 16)) < 0.5)
        CheckOverlap(RPSheet.body, "height " .. height)
        -- scrolling to the end and back
        if RPSheet.body.scrollBarShown then
            RPSheet.body:SetScroll(1000)
            F.Settle()
            RPSheet.body:SetScroll(0)
            F.Settle()
        end
    end
    -- a saved size below the smallest is brought up to it
    profile.window.width, profile.window.height = 100, 50
    window:ApplyStatus()
    Check("a saved size below the smallest is used as it is", frame:GetWidth() == minWidth and frame:GetHeight() == minHeight)
    profile.window.width, profile.window.height = 420, 560
    window:ApplyStatus()
    F.Settle()
end)

-- A caster with every slot level, a character with three classes, and a bigger font.
Try("resize mage", function()
    Use(NewCharacter("MAGE", nil, nil, 20, 3))
    ResizeRun("MAGE 20")
end)
Try("resize multiclass", function()
    local sheet = NewCharacter("PRIEST", nil, nil, 3, 4)
    sheet.classes = {
        SHAMAN = { level = 3, subclass = R.CLASSES.SHAMAN.subclasses[1], spec = R.CLASSES.SHAMAN.specs[1], skill = "", fightingStyle = "", fightingStyle2 = "" },
        HUNTER = { level = 3, subclass = R.CLASSES.HUNTER.subclasses[1], spec = R.CLASSES.HUNTER.specs[1], skill = "", fightingStyle = "", fightingStyle2 = "" },
    }
    sheet.level = 9
    Use(sheet)
    ResizeRun("PRIEST+SHAMAN+HUNTER")
end)
Try("resize with a large font", function()
    Use(NewCharacter("WARRIOR", nil, nil, 11, 5))
    local theme = profile.theme
    local was = theme.fontSize
    theme.fontSize = 16
    RPSheet:ApplyTheme()
    ResizeRun("WARRIOR 11 font 16")
    theme.fontSize = was
    RPSheet:ApplyTheme()
    F.Settle()
end)

SmokeChecks("after the window tests")
Finish("frame", ("close, lock, move, minimize and cog checked; %d widths laid out, %d part-width rows checked"):format(widths, rowsChecked))
