-- The session window: what whoever runs a combat session needs, apart from the combat
-- window of their own character (UI/FightWindow.lua). The same three parts
-- (UI/Panes.lua): on top who is here, with the health bars that pick who a tool is
-- for, and the button that moves the fight on; in the middle the rolls of the
-- combatant whose turn it is and the tools (UI/FightWindowOwner.lua), or the list a
-- creature is added from (UI/FightWindowCreatures.lua); at the bottom the fight's log.
-- Opened with /sheet session, from the combat window, and by itself for whoever
-- starts a session or is handed one. It closes when the session is over.
local _, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local F = ns.Fight

local PHASE = {
    LOBBY = "Gathering. Add what the players fight, then call for initiative.",
    ROLL = "Initiative is being rolled. The turns start when everyone has rolled.",
}

function F.ShowSessionWindow()
    local self = RPSheet
    if not self.sessionWindow then
        local profile = self.db.profile
        profile.sessionWindow = profile.sessionWindow or { width = 380, height = 520 }
        self.sessionWindow, self.sessionPanes = UI.NewPanedWindow(profile.sessionWindow, function() self:PopulateSession() end)
        self:PopulateSession()
    elseif not self.sessionWindow.frame:IsShown() then
        self.sessionWindow:Show()
    end
end

function F.ToggleSessionWindow()
    local window = RPSheet.sessionWindow
    if window and window.frame:IsShown() then window:Hide() else F.ShowSessionWindow() end
end

-- The one button that moves the fight on.
local function AddPrimary(head, session)
    if session.phase == "RUN" then
        UI.AddButton(head, 0.5, "Next turn", function() F.NextTurn() end, "Next turn",
            "Ends the turn that is running and gives it to the next in the order: for a combatant you run, or someone who can't end theirs.", "picked")
    elseif session.phase == "LOBBY" then
        UI.AddButton(head, 0.5, "Call for initiative", function() F.CallInitiative() end, "Call for initiative",
            "Everyone who joined rolls initiative, a Dexterity check, for their own character; your game rolls for the combatants you run. The turns start when all have rolled.",
            "picked")
    elseif session.phase == "ROLL" then
        UI.AddButton(head, 0.5, "Start without the rest", function() F.Begin() end, "Start without the rest",
            "Starts the turns with those who have rolled. Whoever rolls later takes that place in the order.", "picked")
    end
end

local shownFor -- the session this window was last filled for
function RPSheet:PopulateSession()
    local window, panes = self.sessionWindow, self.sessionPanes
    if not window or not window.frame:IsShown() then return end
    local session = F.session
    -- The session it showed is over, or was handed to someone else: nothing to run.
    if shownFor and not (session and F.IsOwner()) then
        shownFor = nil
        F.picking = nil
        window:Hide()
        return
    end
    window:SetTheme(self.db.profile.theme)
    window:SetTitle("Session")
    panes:Clear()
    if not session then
        UI.AddLabel(panes.main, 1, UI.GREY .. "No combat session is running. Whoever starts one runs it from this window.|r")
        UI.AddButton(panes.main, 1, "Start a combat session", function() F.Start() end, "Start a combat session",
            "You run the session: your group can join it, you call for initiative, and your game announces whose turn it is and what comes of everyone's rolls.", "picked")
    elseif not F.IsOwner() then
        UI.AddLabel(panes.main, 1, ("%s%s runs this session. This window is for whoever runs one; your own turn is in the combat window.|r"):format(
            UI.GREY, ns.Game.ShortName(session.owner)))
    else
        shownFor = session.id
        UI.AddLabel(panes.head, 1, UI.FightHeadline(session))
        if UI.AddCreaturePicker(self, panes.main) then
            -- the list to add a creature from takes the middle
        else
            if PHASE[session.phase] then UI.AddLabel(panes.head, 1, UI.GREY .. PHASE[session.phase] .. "|r") end
            UI.AddFightRoster(self, panes.head, session)
            AddPrimary(panes.head, session)
            UI.AddFightOwner(self, panes.main, session)
            UI.AddFightLog(self, panes.log)
        end
    end
    panes:SetOut()
end
