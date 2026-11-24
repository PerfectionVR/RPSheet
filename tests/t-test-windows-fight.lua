-- The combat window, really built, for every class alone in a session of its own:
-- with no session, gathering, rolling initiative, on the character's turn, and after
-- the fight. In each state its rows must not lie over each other and every row's
-- tooltip must build; on the turn every listed action is clicked once, and what the
-- list greys out must say why.
dofile(ARG3 .. "/t-test-windows-base.lua")
Start()

local FT = ns.Fight
local characters, rows, actions, greyed, running = 0, 0, 0, 0, 0

-- Clicks the window's row that reads `needle` and types `text` into the box it opens.
local owner = 0
local function Ask(where, needle, text)
    Try(where .. " fill", function() RPSheet:PopulateFight(); F.Settle() end)
    for _, part in ipairs(RPSheet.fightBody.children) do
        if F.Plain(PartText(part)):find(needle, 1, true) then
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

local function Look(where)
    Try(where .. " fill", function() RPSheet:PopulateFight(); F.Settle() end)
    CheckOverlap(RPSheet.fightBody, where)
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
        Try(label .. " call", function() FT.CallInitiative(); F.Settle() end)
        Look(label .. " rolling")
        Try(label .. " roll", function() FT.RollInitiative(); F.Settle() end)
        Dismiss()
        if not FT.MyTurn() then
            Problem(label .. ": alone in the session, the roll didn't start the character's turn")
        else
            Look(label .. " turn")
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
Finish("fight", ("%d characters, %d rows hovered, %d actions clicked, %d greyed with a reason, %d running things ended, %d owner rows used"):format(
    characters, rows, actions, greyed, running, owner))
