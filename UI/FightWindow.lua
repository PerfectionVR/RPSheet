-- The combat window: this character's place in the session it is in, in three parts
-- that keep their place (UI/Panes.lua). On top who is here, each with a health bar
-- (UI/FightWindowRoster.lua), this character's own line and the button that ends its
-- turn; in the middle who its attacks are for (UI/FightWindowTarget.lua) and, behind
-- tabs, the buttons for what it can do now (UI/FightWindowTurn.lua); at the bottom the fight's log. What can be clicked is a
-- button, a tab or a bar (UI/Parts.lua).
-- Whoever runs the session does that from a window of its own
-- (UI/FightSessionWindow.lua).
-- Opened with /sheet combat, and by itself when initiative is called for or this
-- character's turn starts.
local _, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local F = ns.Fight

local PHASE = {
    LOBBY = "Gathering: join, and pick a group if you fight as one.",
    ROLL = "Roll initiative. The turns start when everyone has rolled.",
}

-- Shows the window (it is built the first time).
function F.ShowWindow()
    local self = RPSheet
    if not self.fightWindow then
        local profile = self.db.profile
        profile.fightWindow = profile.fightWindow or { width = 360, height = 520 }
        -- (a new window is already shown)
        self.fightWindow, self.fightPanes = UI.NewPanedWindow(profile.fightWindow, function() self:PopulateFight() end)
        self:PopulateFight()
    elseif not self.fightWindow.frame:IsShown() then
        self.fightWindow:Show()
    end
end

function F.ToggleWindow()
    local window = RPSheet.fightWindow
    if window and window.frame:IsShown() then window:Hide() else F.ShowWindow() end
end

-- The session changed: the open windows follow, once a frame at most.
local queued = false
function F.OnChange()
    if queued then return end
    local mine, session = RPSheet.fightWindow, RPSheet.sessionWindow
    if not (mine and mine.frame:IsShown()) and not (session and session.frame:IsShown()) then return end
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
        UI.AddButton(body, 1, "Put my character back as before the fight", function() F.RestoreSnapshot() end, "Before the fight",
            "Your hit points, spell slots, resources, conditions and what was running go back to what they were when you joined. Your character itself (levels, items) is not touched.")
        UI.AddButton(body, 1, "Keep the outcome", function() F.DropSnapshot() end, "Keep the outcome",
            "Your character stays as the fight left it, and the state from before the fight is forgotten.")
    end
    UI.AddHeading(body, "Combat session")
    UI.AddButton(body, 1, "Start a combat session", function() F.Start() end, "Start a combat session",
        "You run the session: your group can join it, you call for initiative, and your game announces whose turn it is and what comes of everyone's rolls. Everyone rolls for their own character. A second window opens with what you need to run it.",
        "picked")
    UI.AddLabel(body, 1, UI.GREY .. "Others join from this window once you are in a party or raid with them. Alone, you can still start one and add creatures to fight.|r")
end

-- What the session is doing, in one line.
function UI.FightHeadline(session)
    local holder = session.members[session.turn or ""]
    local owner = ("Session of %s%s|r"):format(UI.ACCENT, ns.Game.ShortName(session.owner))
    if session.phase ~= "RUN" then return owner end
    return ("%s  %sround %d, %s|r"):format(owner, UI.GREY, session.round, F.MyTurn() and "your turn" or (holder and (holder.name .. "'s turn") or "between turns"))
end

-- The top part: the session's line, what is asked of this character, who is here,
-- and its own line with the button that ends its turn.
local function AddHead(self, head, session, mine)
    UI.AddLabel(head, 1, UI.FightHeadline(session))
    if PHASE[session.phase] then UI.AddLabel(head, 1, UI.GREY .. PHASE[session.phase] .. "|r") end
    if not mine then
        UI.AddButton(head, 0.5, "Join the session", function() F.Join() end, "Join",
            "Your character joins with the hit points, slots and resources it has now. That state is kept: after the fight you can put it back."
            .. (session.phase == "RUN" and "\nThe turns are running: you roll initiative and act when your place in the order comes up." or ""), "picked")
        UI.AddButton(head, 0.5, "Forget this session", function() F.Leave() end, "Forget", "The session goes on without you.")
    else
        if F.owedSave then
            UI.AddButton(head, 1, ("Roll the %s save (DC %d)"):format(ns.Rules.STAT_NAMES[F.owedSave.stat], F.owedSave.dc),
                function() F.RollOwedSave() end, "Saving throw",
                "Whoever runs the session asked for this saving throw. You roll it on your own sheet; their game says whether it meets the DC.\n" .. ns.ROLL_MODE_HELP, "picked")
        end
        if F.OwesInitiative() then
            UI.AddButton(head, 1, "Roll initiative", function() F.RollInitiative() end, "Roll initiative",
                "A Dexterity check for your place in the order.\n" .. ns.ROLL_MODE_HELP, "picked")
        end
    end
    UI.AddFightRoster(self, head, session)
    if mine then
        UI.AddFightStatus(self, head)
        UI.AddFightPrimary(self, head)
    end
end

function RPSheet:PopulateFight()
    self:PopulateSession() -- the window of whoever runs the session follows too
    local window, panes = self.fightWindow, self.fightPanes
    if not window or not window.frame:IsShown() then return end
    window:SetTheme(self.db.profile.theme)
    window:SetTitle("Combat")
    panes:Clear()
    local session = F.session
    if not session then
        AddIdle(self, panes.main)
    else
        local mine = F.Mine()
        AddHead(self, panes.head, session, mine)
        if mine then
            UI.AddFightRunning(self, panes.main)
            UI.AddFightTarget(self, panes.main, session)
            UI.AddFightTurn(self, panes.main, session, mine)
        end
        UI.AddFightLog(self, panes.log)
    end
    panes:SetOut()
end
