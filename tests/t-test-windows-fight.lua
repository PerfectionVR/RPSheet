-- The combat window, really built, for every class alone in a session of its own:
-- with no session, gathering, rolling initiative, on the character's turn, and after
-- the fight. In each state its rows must not lie over each other and every row's
-- tooltip must build; on the turn every listed action is clicked once, and what the
-- list greys out must say why.
dofile(ARG3 .. "/t-test-windows-base.lua")
Start()

local FT = ns.Fight
local characters, rows, actions, greyed, running, tabs = 0, 0, 0, 0, 0, 0
local CLICKABLE = { RPSheetButton = true, RPSheetTab = true, RPSheetBar = true }

-- Clicks the window's row that reads `needle` and types `text` into the box it opens.
local owner = 0
local function Ask(where, needle, text)
    Try(where .. " fill", function() RPSheet:PopulateFight(); F.Settle() end)
    for _, part in ipairs(RPSheet.fightBody.children) do
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
    for _, part in ipairs(RPSheet.fightBody.children) do
        if not CLICKABLE[part.type] and part.GetUserData and part:GetUserData("onClick") then
            Problem(("%s: plain text that can be clicked: %s"):format(where, F.Plain(PartText(part)):sub(1, 40)))
        end
    end
end

-- Opens every tab of the strip in turn and looks at what it shows.
local function LookAtTabs(where)
    Try(where .. " fill", function() RPSheet:PopulateFight(); F.Settle() end)
    local names = {}
    for _, part in ipairs(RPSheet.fightBody.children) do
        if part.type == "RPSheetTab" then names[#names + 1] = F.Plain(PartText(part)) end
    end
    if #names < 2 then Problem(where .. ": only " .. #names .. " tabs") end
    for _, name in ipairs(names) do
        tabs = tabs + 1
        for _, part in ipairs(RPSheet.fightBody.children) do
            if part.type == "RPSheetTab" and F.Plain(PartText(part)) == name then
                Try(where .. " tab " .. name, function() F.Click(part.frame); F.Settle() end)
                break
            end
        end
        Try(where .. " fill", function() RPSheet:PopulateFight(); F.Settle() end)
        CheckOverlap(RPSheet.fightBody, where .. " tab " .. name)
        CheckClickable(where .. " tab " .. name)
        for _, part in ipairs(RPSheet.fightBody.children) do HoverPart(where .. " tab " .. name, part) end
    end
end

local function Look(where)
    Try(where .. " fill", function() RPSheet:PopulateFight(); F.Settle() end)
    CheckOverlap(RPSheet.fightBody, where)
    CheckClickable(where)
    for _, part in ipairs(RPSheet.fightBody.children) do
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
                Ask(label, "War Stomp")
                if not FT.owedSave then Problem(label .. ": the creature's War Stomp asked no save of the character") end
                Look(label .. " the creature's turn, a save owed")
                FT.owedSave, FT.target = nil, nil
                RPSheet:State().hp = hp
            end
        end
        Try(label .. " end", function() FT.End(); F.Settle() end)
        if FT.session then Problem(label .. ": the session is still there after its end") end
        if RPSheet:State().fightTimers then Problem(label .. ": rounds are still counted after the session") end
        Look(label .. " after the fight")
        if not FT.HasSnapshot() then Problem(label .. ": no state from before the fight is kept") end
        Try(label .. " restore", function() FT.RestoreSnapshot(); F.Settle() end)
        Dismiss()
        CheckHidden(label)
    end
end

if running == 0 then Problem("no action of any class left something running for the window to list") end
Finish("fight", ("%d characters, %d rows hovered, %d tabs opened, %d actions clicked, %d greyed with a reason, %d running things ended, %d owner rows used"):format(
    characters, rows, tabs, actions, greyed, running, owner))
