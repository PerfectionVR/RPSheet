-- The combat window, really built, for every class alone in a session of its own:
-- with no session, gathering, rolling initiative, on the character's turn, and after
-- the fight. In each state its rows must not lie over each other and every row's
-- tooltip must build; on the turn every listed action is clicked once, and what the
-- list greys out must say why.
dofile(ARG3 .. "/t-test-windows-base.lua")
Start()

local FT = ns.Fight
local characters, rows, actions, greyed = 0, 0, 0, 0

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
        Look(label .. " after the fight")
        if not FT.HasSnapshot() then Problem(label .. ": no state from before the fight is kept") end
        Try(label .. " restore", function() FT.RestoreSnapshot(); F.Settle() end)
        Dismiss()
        CheckHidden(label)
    end
end

Finish("fight", ("%d characters, %d rows hovered, %d actions clicked, %d greyed with a reason"):format(characters, rows, actions, greyed))
