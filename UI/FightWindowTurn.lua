-- The combat window's lower half: the button that moves the turn on, and a strip of
-- tabs with one tab for each kind of thing this character can do now
-- (Integrations/FightActions.lua), one for the session's owner
-- (UI/FightWindowOwner.lua) and one for the character's place in the session. Only
-- the open tab is drawn. Something the character has but can't use at the moment is a
-- greyed button, and its tooltip and a click say why.
local _, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local F = ns.Fight

local RED = "|cffff5555"
local SESSION, YOU = "Session", "You"
local SHORT = { ["Actions everyone has"] = "Actions" }
local COST = { ACTION = "action", ATTACK = "attack", BONUS = "bonus", REACTION = "reaction", FREE = "free" }

local function AddAction(self, body, entry)
    local wide = entry.info ~= ""
    local text = wide and ("%s  %s%s|r"):format(entry.name, UI.GREY, entry.info)
        or ("%s  %s%s|r"):format(entry.name, UI.GREY, COST[entry.cost] or "")
    local takes = entry.costLabel and ("Takes: %s.\n"):format(entry.costLabel) or ""
    if entry.why then
        UI.AddButton(body, wide and 1 or 0.5, text, function()
            self:Print(("%s: %s"):format(entry.name, entry.why))
        end, entry.name, ("%sNot now: %s|r\n\n%s%s"):format(RED, entry.why, takes, entry.tip or ""), "off")
    else
        UI.AddButton(body, wide and 1 or 0.5, text, function() entry.run() end,
            entry.name, takes .. (entry.tip or "") .. "\n" .. ns.ROLL_MODE_HELP)
    end
end

-- The eight marks to fight under, and none.
local function AddYou(self, body, mine)
    UI.AddLabel(body, 1, "Your group: " .. (F.MARKS[mine.mark] and (F.MarkIcon(mine.mark) .. F.MARKS[mine.mark].name) or (UI.GREY .. "none|r")), nil,
        "Groups", "Those who fight together pick the same mark. The mark stands in front of your name in the order and in what is announced.")
    for index, mark in ipairs(F.MARKS) do
        UI.AddButton(body, 0.11, F.MarkIcon(index), function() F.SetMark(index) end, mark.name, ("Join the %s group."):format(mark.name),
            mine.mark == index and "picked" or "on")
    end
    UI.AddButton(body, 0.11, "x", function() F.SetMark(0) end, "No group", "Fight under no mark.")
    if not F.IsOwner() then
        UI.AddButton(body, 0.5, "Leave the fight", function() F.Leave() end, "Leave", "The session goes on without you.")
    end
end

-- The one button that moves things on, always in sight.
local function AddPrimary(self, body, session)
    if F.MyTurn() then
        UI.AddButton(body, 0.5, "End turn", function() F.EndTurn() end, "End turn", "The turn goes to the next in the order.", "picked")
    elseif F.IsOwner() and session.phase == "RUN" then
        UI.AddButton(body, 0.5, "Next turn", function() F.NextTurn() end, "Next turn",
            "Ends the turn that is running and gives it to the next in the order: for a combatant you run, or someone who can't end theirs.", "picked")
    elseif F.IsOwner() and session.phase == "LOBBY" then
        UI.AddButton(body, 0.5, "Call for initiative", function() F.CallInitiative() end, "Call for initiative",
            "Everyone who joined rolls initiative, a Dexterity check, for their own character; your game rolls for the combatants you run. The turns start when all have rolled.",
            "picked")
    elseif F.IsOwner() and session.phase == "ROLL" then
        UI.AddButton(body, 0.5, "Start without the rest", function() F.Begin() end, "Start without the rest",
            "Starts the turns with those who have rolled. Whoever rolls later takes that place in the order.", "picked")
    end
end

local shownTurn
function UI.AddFightTurn(self, body, session, mine)
    AddPrimary(self, body, session)
    -- the tabs there are now
    local tabs, sections, list = {}, {}, F.Actions()
    for _, entry in ipairs(list) do
        if not sections[entry.section] then
            sections[entry.section] = { free = 0 }
            tabs[#tabs + 1] = { name = entry.section, label = SHORT[entry.section] or entry.section }
        end
        if not entry.why then sections[entry.section].free = sections[entry.section].free + 1 end
    end
    for _, tab in ipairs(tabs) do
        local free = sections[tab.name].free
        tab.tip = free > 0 and ("%d you can use now."):format(free) or "Nothing here can be used right now: each button says why."
        if free == 0 then tab.label = UI.GREY .. tab.label .. "|r" end
    end
    if F.IsOwner() then tabs[#tabs + 1] = { name = SESSION, tip = "Your tools as the session's owner: the combatants you run, and what you do to the one you picked." } end
    tabs[#tabs + 1] = { name = YOU, tip = "The group you fight in, and leaving the fight." }
    -- the open one: the player's choice until the turn moves, then what fits the moment
    local turn = ("%s:%s:%s"):format(session.id, session.phase, tostring(session.turn))
    if turn ~= shownTurn then shownTurn, F.tab = turn, nil end
    local open
    for _, tab in ipairs(tabs) do
        if tab.name == F.tab then open = tab.name end
    end
    if not open then
        local holder = session.members[session.turn or ""]
        if F.IsOwner() and not (F.MyTurn() and #list > 0) and (session.phase ~= "RUN" or (holder and holder.npc)) then
            open = SESSION
        else
            open = tabs[1].name
        end
    end
    UI.AddLabel(body, 1, " ")
    UI.AddTabStrip(body, tabs, open, function(name)
        F.tab = name
        F.Changed()
    end)
    if open == SESSION then
        UI.AddFightOwner(self, body, session)
    elseif open == YOU then
        AddYou(self, body, mine)
    else
        if not F.MyTurn() then
            UI.AddLabel(body, 1, UI.GREY .. "Until your turn you can take a reaction, and do what takes no action.|r")
        end
        for _, entry in ipairs(list) do
            if entry.section == open then AddAction(self, body, entry) end
        end
    end
end
