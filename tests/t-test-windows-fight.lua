-- The combat window, really built, for every class alone in a session of its own:
-- with no session, gathering, rolling initiative, on the character's turn, and after
-- the fight. In each state its rows must not lie over each other and every row's
-- tooltip must build; on the turn every listed action is clicked once, and what the
-- list greys out must say why.
dofile(ARG3 .. "/t-test-windows-base.lua")
Start()

local FT = ns.Fight
local characters, rows, actions, greyed, running, tabs, targets = 0, 0, 0, 0, 0, 0, 0
local CLICKABLE = { RPSheetButton = true, RPSheetTab = true, RPSheetBar = true }

-- The parts of the combat window and of the session window, while they are shown,
-- and every row in them.
local function Panes()
    local list = {}
    for _, key in ipairs({ "fightPanes", "sessionPanes" }) do
        local panes = RPSheet[key]
        if panes and panes.window.frame:IsShown() then
            for _, pane in ipairs(panes) do list[#list + 1] = pane end
        end
    end
    return list
end
local function Parts()
    local all = {}
    for _, pane in ipairs(Panes()) do
        for _, part in ipairs(pane.children) do all[#all + 1] = part end
    end
    return all
end
local function OverlapAll(where)
    for _, pane in ipairs(Panes()) do
        CheckOverlap(pane, where)
        -- a part with rows has room on the screen, inside its window
        local frame, content = pane.frame, pane.parent.content
        if #pane.children > 0 and (frame:GetHeight() < 10 or frame:GetBottom() < content:GetBottom() - 0.5 or frame:GetTop() > content:GetTop() + 0.5) then
            Problem(("%s: a part of the window has no room (%d high)"):format(where, frame:GetHeight()))
        end
    end
    -- the parts don't lie over each other
    local panes = Panes()
    for index = 2, #panes do
        local above, below = panes[index - 1], panes[index]
        if above.parent == below.parent and above.frame:IsShown() and below.frame:IsShown() and below.frame:GetTop() > above.frame:GetBottom() + 0.5 then
            Problem(where .. ": two parts of the window overlap")
        end
    end
end

-- Clicks the window's row that reads `needle` and types `text` into the box it opens.
local owner = 0
local function Ask(where, needle, text)
    Try(where .. " fill", function() RPSheet:PopulateFight(); F.Settle() end)
    for _, part in ipairs(Parts()) do
        -- (only what reads as something to click: the fight's log repeats the names)
        if CLICKABLE[part.type] and F.Plain(PartText(part)):find(needle, 1, true) then
            owner = owner + 1
            Try(where .. " click " .. needle, function() F.Click(part.frame); F.Settle() end)
            if text then
                if not F.popup then Problem(where .. ": " .. needle .. " opened no box") return end
                Try(where .. " type " .. needle, function() F.PopupType(text, true); F.Settle() end)
            end
            Dismiss()
            return
        end
    end
    Problem(where .. ": no row reads " .. needle)
end
local function Creature(name)
    for key, member in pairs(FT.session.members) do
        if member.name == name then return key, member end
    end
end

-- What can be clicked in this window is a button, a tab or a bar, and nothing else is.
local function CheckClickable(where)
    for _, part in ipairs(Parts()) do
        if not CLICKABLE[part.type] and part.GetUserData and part:GetUserData("onClick") then
            Problem(("%s: plain text that can be clicked: %s"):format(where, F.Plain(PartText(part)):sub(1, 40)))
        end
    end
end

-- Opens every tab of the strip in turn and looks at what it shows.
local function LookAtTabs(where)
    Try(where .. " fill", function() RPSheet:PopulateFight(); F.Settle() end)
    local names = {}
    for _, part in ipairs(Parts()) do
        if part.type == "RPSheetTab" then names[#names + 1] = F.Plain(PartText(part)) end
    end
    if #names < 2 then Problem(where .. ": only " .. #names .. " tabs") end
    for _, name in ipairs(names) do
        tabs = tabs + 1
        for _, part in ipairs(Parts()) do
            if part.type == "RPSheetTab" and F.Plain(PartText(part)) == name then
                Try(where .. " tab " .. name, function() F.Click(part.frame); F.Settle() end)
                break
            end
        end
        Try(where .. " fill", function() RPSheet:PopulateFight(); F.Settle() end)
        OverlapAll(where .. " tab " .. name)
        CheckClickable(where .. " tab " .. name)
        for _, part in ipairs(Parts()) do HoverPart(where .. " tab " .. name, part) end
    end
end

local function Look(where)
    Try(where .. " fill", function() RPSheet:PopulateFight(); F.Settle() end)
    OverlapAll(where)
    CheckClickable(where)
    for _, part in ipairs(Parts()) do
        HoverPart(where, part)
        rows = rows + 1
    end
end

for index, key in ipairs(R.CLASS_ORDER) do
    local level = ({ 3, 5, 11 })[index % 3 + 1]
    local label = ("%s L%d"):format(key, level)
    local sheet = Try(label .. " build", NewCharacter, key, nil, nil, level, index)
    if sheet then
        Try(label .. " use", Use, sheet)
        characters = characters + 1
        Try(label .. " open", function() FT.ShowWindow(); F.Settle() end)
        Look(label .. " idle")
        Try(label .. " start", function() FT.Start(); F.Settle() end)
        if not (FT.IsOwner() and FT.Mine()) then Problem(label .. ": starting a session didn't put the character in it") end
        if not (RPSheet.sessionWindow and RPSheet.sessionWindow.frame:IsShown()) then Problem(label .. ": starting a session didn't open the session window") end
        Try(label .. " mark", function() FT.SetMark(8); F.Settle() end)
        Look(label .. " gathering")
        -- the owner's rows: a combatant of their own, picked, hurt, healed and asked for a save
        Ask(label, "Add a combatant you run", "Gnoll 13 22 +1")
        local gnoll = Creature("Gnoll")
        if not gnoll then
            Problem(label .. ": typing a combatant didn't add it")
        else
            FT.target = gnoll
            Look(label .. " gathering, a row picked")
            Ask(label, "Deal damage", "5 fire")
            if FT.session.members[gnoll].hp ~= 17 then Problem(label .. ": typed damage didn't come off the combatant's hit points") end
            Ask(label, "Heal", "2")
            if FT.session.members[gnoll].hp ~= 19 then Problem(label .. ": typed healing didn't come back") end
            Ask(label, "Ask for a saving throw", "DEX 15 +2")
            -- the owner's own row: the save is asked of this character
            FT.target = FT.Me()
            Ask(label, "Ask for a saving throw", "WIS 10")
            if not FT.owedSave then Problem(label .. ": a save asked of the owner's own character isn't owed") end
            Look(label .. " a save owed")
            Ask(label, "Roll the Wisdom save")
            FT.owedSave = nil
            FT.target = gnoll
            Ask(label, "Remove from the fight")
            if Creature("Gnoll") then Problem(label .. ": the combatant is still there after it was removed") end
            FT.target = nil
        end
        -- the list of creatures: opened, narrowed, one added, closed
        Ask(label, "Add a creature from the list")
        if not FT.picking then Problem(label .. ": the creature list didn't open") end
        Look(label .. " creature list")
        LookAtTabs(label .. " creature list")
        Ask(label, "Side")
        Ask(label, "Scourge")
        Ask(label, "Abomination  CR 12")
        local abomination = Creature("Abomination")
        if not abomination then Problem(label .. ": a creature of a group wasn't added by its button") else FT.RemoveCreature(abomination) end
        Ask(label, "Name has:", "fel")
        if #FT.CreatureMatches(FT.pickFilter) ~= 4 then Problem(label .. ": the filter gives " .. #FT.CreatureMatches(FT.pickFilter) .. " creatures") end
        Look(label .. " creature list, narrowed")
        Ask(label, "Felguard  CR 4")
        local felguard = Creature("Felguard")
        if not (felguard and FT.Template(FT.session.members[felguard])) then Problem(label .. ": a click in the list didn't add the creature") end
        Ask(label, "Show all of them")
        Ask(label, "Back to the fight")
        if FT.picking then Problem(label .. ": the creature list didn't close") end
        if felguard then FT.RemoveCreature(felguard) end
        Try(label .. " call", function() FT.CallInitiative(); F.Settle() end)
        Look(label .. " rolling")
        Try(label .. " roll", function() FT.RollInitiative(); F.Settle() end)
        Dismiss()
        if not FT.MyTurn() then
            Problem(label .. ": alone in the session, the roll didn't start the character's turn")
        else
            -- an attack with no one picked asks who it is for, and goes on at the answer
            Try(label .. " add a target", function() FT.AddCreature("Felguard"); F.Settle() end)
            local felguard, aimedAt = Creature("Felguard"), nil
            for _, entry in ipairs(FT.Actions()) do
                if entry.section == "Attack" and not entry.why and not aimedAt then aimedAt = entry end
            end
            if felguard and aimedAt then
                FT.target = nil
                Ask(label, "Felguard")
                if FT.target ~= felguard then Problem(label .. ": the target button didn't pick the creature") end
                Ask(label, "Felguard")
                if FT.target then Problem(label .. ": a second click on the target button didn't let go of it") end
                local lines = #FT.LogLines()
                Try(label .. " attack, no target", function() FT.Act(aimedAt); F.Settle() end)
                if not FT.aiming then Problem(label .. ": an attack with no target didn't ask for one") end
                if #FT.LogLines() ~= lines then Problem(label .. ": an attack with no target was rolled before one was picked") end
                Look(label .. " asking for a target")
                Ask(label, "Felguard")
                Dismiss()
                if FT.aiming or FT.target ~= felguard then Problem(label .. ": picking a target didn't aim the attack") end
                local last = F.Plain(FT.LogText(FT.LogLines()[#FT.LogLines()]) or "")
                if #FT.LogLines() == lines or not (last:find("hit", 1, true) or last:find("miss", 1, true)) then
                    Problem(label .. ": the aimed attack wasn't resolved: " .. last:sub(1, 80))
                end
                targets = targets + 1
            end
            if felguard then FT.RemoveCreature(felguard) end
            FT.target, FT.aiming = nil, nil
            RPSheet.busy = false
            FT.used.action, FT.used.attacks, FT.used.bonus = nil, nil, nil
            Look(label .. " turn")
            LookAtTabs(label .. " turn")
            FT.tab = nil
            local list = FT.Actions()
            if #list < 11 then Problem(label .. ": the turn lists only " .. #list .. " actions") end
            for _, entry in ipairs(list) do
                if entry.why then
                    greyed = greyed + 1
                    if entry.why == "" then Problem(label .. ": " .. entry.name .. " is greyed without a reason") end
                else
                    actions = actions + 1
                    Try(label .. " action " .. entry.name, function() entry.run(); F.Settle() end)
                    Dismiss()
                end
            end
            Look(label .. " turn, after acting")
            -- what the actions left running is listed with its rounds, and a click ends it
            for _, timer in ipairs(CopyTable(FT.SyncTimers())) do
                running = running + 1
                if FT.TimerText(timer) == "" then Problem(label .. ": " .. timer.name .. " runs without a time") end
                Try(label .. " end " .. timer.name, function() FT.EndTimer(timer.kind, timer.name); F.Settle() end)
                Dismiss()
            end
            if #FT.SyncTimers() > 0 then Problem(label .. ": something still runs after everything was ended") end
            -- everything that costs an action is greyed once the action is spent
            RPSheet.busy = false
            FT.used.action, FT.used.attacks, FT.used.bonus = true, 0, true
            for _, entry in ipairs(FT.Actions()) do
                if (entry.cost == "ACTION" or entry.cost == "BONUS") and not entry.why then
                    Problem(label .. ": " .. entry.name .. " is offered with the action and bonus action spent")
                end
            end
            local round = FT.session.round
            Try(label .. " end turn", function() FT.EndTurn(); F.Settle() end)
            if FT.session.round ~= round + 1 or FT.used.action then Problem(label .. ": ending the turn alone didn't start the next round") end
            -- a creature from the list takes its turn: its attacks and saves are rows of the owner's
            Try(label .. " add creature", function() FT.AddCreature("Doomguard"); F.Settle() end)
            local doomguard = Creature("Doomguard")
            for _ = 1, 3 do
                if FT.session.turn ~= doomguard then Try(label .. " next turn", function() FT.NextTurn(); F.Settle() end) end
            end
            if not doomguard or FT.session.turn ~= doomguard then
                Problem(label .. ": the creature's turn didn't come up")
            else
                FT.target = FT.Me()
                Look(label .. " the creature's turn")
                if #FT.LogLines() == 0 then Problem(label .. ": the fight's log is empty") end
                local hp = RPSheet:State().hp
                -- alone with the creature, it is aimed at the character without a click
                FT.target = nil
                if FT.session.members[FT.Me()].hp > 0 and FT.CreatureTarget(doomguard) ~= FT.Me() then
                    Problem(label .. ": the creature isn't aimed at its only opponent")
                end
                FT.target = FT.Me()
                Ask(label, "Fel Claw")
                Ask(label, "Gore")
                if not FT.CreatureWhy("attack", 1, doomguard) then Problem(label .. ": the creature can attack a third time in its turn") end
                Look(label .. " the creature's turn, its action used")
                Ask(label, "Another action")
                if FT.CreatureWhy("force", 1, doomguard, FT.Me()) then Problem(label .. ": another action didn't free the creature's buttons") end
                Ask(label, "War Stomp")
                if not FT.owedSave then Problem(label .. ": the creature's War Stomp asked no save of the character") end
                Look(label .. " the creature's turn, a save owed")
                FT.owedSave, FT.target = nil, nil
                RPSheet:State().hp = hp
            end
        end
        Try(label .. " end", function() FT.End(); F.Settle() end)
        if FT.session then Problem(label .. ": the session is still there after its end") end
        if RPSheet.sessionWindow.frame:IsShown() then Problem(label .. ": the session window is still open after the session") end
        if RPSheet:State().fightTimers then Problem(label .. ": rounds are still counted after the session") end
        Look(label .. " after the fight")
        if not FT.HasSnapshot() then Problem(label .. ": no state from before the fight is kept") end
        Try(label .. " restore", function() FT.RestoreSnapshot(); F.Settle() end)
        Dismiss()
        CheckHidden(label)
    end
end

if targets == 0 then Problem("no attack was aimed through the target buttons") end
if running == 0 then Problem("no action of any class left something running for the window to list") end
Finish("fight", ("%d characters, %d rows hovered, %d tabs opened, %d actions clicked, %d greyed with a reason, %d running things ended, %d owner rows used"):format(
    characters, rows, tabs, actions, greyed, running, owner))
