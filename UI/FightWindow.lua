-- The combat window: the session this character is in. Who takes part, in initiative
-- order, each with their group's mark; the buttons of the session's owner; and, while
-- turns are taken, what this character can do now (UI/FightWindowTurn.lua).
-- Opened with /sheet combat, and by itself when initiative is called for or this
-- character's turn starts.
local ADDON, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local F = ns.Fight
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local RED = "|cffff5555"
local PHASE = {
    LOBBY = "Gathering: join, and pick a group if you fight as one.",
    ROLL = "Roll initiative. The turns start when everyone has rolled.",
}

local function Build(self)
    local profile = self.db.profile
    profile.fightWindow = profile.fightWindow or { width = 360, height = 520 }

    local window = AceGUI:Create("RPSheetWindow")
    window:SetStatusTable(profile.fightWindow)
    window:SetLayout("Fill")
    window:SetCallback("OnLockClick", function() window:SetLocked(not window.locked) end)
    window:SetCallback("OnMinimizeClick", function() window:SetMinimized(not window.minimized) end)
    window:SetCallback("OnEditClick", function() AceConfigDialog:Open(ADDON) end)
    window:SetCallback("OnShow", function() self:PopulateFight() end)
    self.fightWindow = window

    local body = AceGUI:Create("ScrollFrame")
    body:SetLayout("Flow")
    window:AddChild(body)
    self.fightBody = body
end

-- Shows the window (it is built the first time).
function F.ShowWindow()
    local self = RPSheet
    if not self.fightWindow then
        Build(self) -- a new window is already shown
        self:PopulateFight()
    elseif not self.fightWindow.frame:IsShown() then
        self.fightWindow:Show()
    end
end

function F.ToggleWindow()
    local window = RPSheet.fightWindow
    if window and window.frame:IsShown() then window:Hide() else F.ShowWindow() end
end

-- The session changed: the open window follows, once a frame at most.
local queued = false
function F.OnChange()
    local window = RPSheet.fightWindow
    if queued or not window or not window.frame:IsShown() then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        RPSheet:PopulateFight()
    end)
end

-- With no session: starting one, and what is left of the last fight.
local function AddIdle(self, body)
    if F.HasSnapshot() then
        UI.AddHeading(body, "After the fight")
        UI.AddLabel(body, 1, UI.ACCENT .. "Put my character back as before the fight|r", function() F.RestoreSnapshot() end, "Before the fight",
            "Your hit points, spell slots, resources, conditions and what was running go back to what they were when you joined. Your character itself (levels, items) is not touched.")
        UI.AddLabel(body, 1, UI.ACCENT .. "Keep the outcome|r", function() F.DropSnapshot() end, "Keep the outcome",
            "Your character stays as the fight left it, and the state from before the fight is forgotten.")
    end
    UI.AddHeading(body, "Combat session")
    UI.AddLabel(body, 1, UI.ACCENT .. "Start a combat session|r", function() F.Start() end, "Start a combat session",
        "You own the session: your group can join it, you call for initiative, and your game announces whose turn it is and what comes of everyone's rolls. Everyone rolls for their own character.")
    UI.AddLabel(body, 1, UI.GREY .. "Others join from this window once you are in a party or raid with them.|r")
end

-- The eight marks to fight under, and none.
local function AddGroups(body, mine)
    UI.AddLabel(body, 1, "Your group: " .. (F.MARKS[mine.mark] and (F.MarkIcon(mine.mark) .. F.MARKS[mine.mark].name) or (UI.GREY .. "none|r")), nil,
        "Groups", "Those who fight together pick the same mark below. The mark stands in front of your name in the order and in what is announced.")
    for index, mark in ipairs(F.MARKS) do
        UI.AddLabel(body, 0.11, F.MarkIcon(index), function() F.SetMark(index) end, mark.name, ("Join the %s group."):format(mark.name))
    end
    UI.AddLabel(body, 0.11, UI.GREY .. "x|r", function() F.SetMark(0) end, "No group", "Fight under no mark.")
end

local function AddRoster(self, body, session)
    UI.AddHeading(body, session.phase == "RUN" and ("Round %d"):format(session.round) or "Who takes part")
    local target = F.joined and F.Target()
    for _, key in ipairs(F.Roster()) do
        local member = session.members[key]
        local init = member.init and ("%d"):format(member.init) or "-"
        local text = ("%s%s%s%s  %s%s  HP %d/%d  AC %d|r"):format(
            session.turn == key and (UI.ACCENT .. "> |r") or "", F.MarkIcon(member.mark), member.name,
            key == target and (RED .. " (your target)|r") or "", UI.GREY, init, member.hp, member.max, member.ac)
        UI.AddLabel(body, 1, text, function()
            F.target = F.target ~= key and key or nil
            F.Changed()
        end, member.name, ("Initiative %s. Click to aim your attacks at %s: the session then says whether an attack roll hits. Click again to aim at no one."):format(
            member.init and init or "not rolled yet", member.name))
    end
end

local function AddOwnerRows(body, session)
    UI.AddHeading(body, "Your session")
    if session.phase == "LOBBY" then
        UI.AddLabel(body, 1, UI.ACCENT .. "Call for initiative|r", function() F.CallInitiative() end, "Call for initiative",
            "Everyone who joined rolls initiative, a Dexterity check, for their own character. The turns start when all have rolled.")
    elseif session.phase == "ROLL" then
        UI.AddLabel(body, 1, UI.ACCENT .. "Start without the rest|r", function() F.Begin() end, "Start without the rest",
            "Starts the turns with those who have rolled. Whoever rolls later takes that place in the order.")
    else
        UI.AddLabel(body, 1, UI.ACCENT .. "Next turn|r", function() F.NextTurn() end, "Next turn",
            "Ends the turn that is running and gives it to the next in the order, for someone who can't end theirs.")
        UI.AddLabel(body, 1, UI.ACCENT .. "Call for initiative again|r", function() F.CallInitiative() end, "Call for initiative again",
            "A new fight in the same session: everyone rolls again.")
    end
    UI.AddLabel(body, 1, UI.ACCENT .. "End the session|r", function() F.End() end, "End the session", "The fight is over for everyone.")
end

function RPSheet:PopulateFight()
    local window, body = self.fightWindow, self.fightBody
    if not window or not window.frame:IsShown() then return end
    window:SetTheme(self.db.profile.theme)
    window:SetTitle("Combat")
    body:PauseLayout()
    body:ReleaseChildren()
    local session = F.session
    if not session then
        AddIdle(self, body)
    else
        local mine = F.Mine()
        UI.AddLabel(body, 1, ("Session of %s%s|r"):format(UI.ACCENT, ns.Game.ShortName(session.owner)))
        if PHASE[session.phase] then UI.AddLabel(body, 1, UI.GREY .. PHASE[session.phase] .. "|r") end
        if not mine then
            UI.AddLabel(body, 1, UI.ACCENT .. "Join the session|r", function() F.Join() end, "Join",
                "Your character joins with the hit points, slots and resources it has now. That state is kept: after the fight you can put it back."
                .. (session.phase == "RUN" and "\nThe turns are running: you roll initiative and act when your place in the order comes up." or ""))
        else
            AddGroups(body, mine)
            if F.OwesInitiative() then
                UI.AddLabel(body, 1, UI.ACCENT .. "Roll initiative|r", function() F.RollInitiative() end, "Roll initiative",
                    "A Dexterity check for your place in the order.\n" .. ns.ROLL_MODE_HELP)
            end
        end
        AddRoster(self, body, session)
        if mine then UI.AddFightRunning(self, body) end
        if mine and session.phase == "RUN" then UI.AddFightTurn(self, body) end
        if F.IsOwner() then AddOwnerRows(body, session) end
        if not F.IsOwner() then
            UI.AddLabel(body, 1, "\n" .. UI.GREY .. (mine and "Leave the fight" or "Forget this session") .. "|r", function() F.Leave() end, "Leave",
                "The session goes on without you.")
        end
    end
    body:ResumeLayout()
    UI.SetOut(body)
end
