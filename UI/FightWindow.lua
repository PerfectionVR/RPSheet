-- The combat window: the session this character is in, laid out like the screen of a
-- text adventure. From the top: who is here, each with a health bar
-- (UI/FightWindowRoster.lua); the fight's log; this character's own line; and the
-- buttons, behind tabs, for what it can do now (UI/FightWindowTurn.lua). What can be
-- clicked is a button, a tab or a bar (UI/FightParts.lua).
-- Opened with /sheet combat, and by itself when initiative is called for or this
-- character's turn starts.
local ADDON, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local F = ns.Fight
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

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
        UI.AddButton(body, 1, "Put my character back as before the fight", function() F.RestoreSnapshot() end, "Before the fight",
            "Your hit points, spell slots, resources, conditions and what was running go back to what they were when you joined. Your character itself (levels, items) is not touched.")
        UI.AddButton(body, 1, "Keep the outcome", function() F.DropSnapshot() end, "Keep the outcome",
            "Your character stays as the fight left it, and the state from before the fight is forgotten.")
    end
    UI.AddHeading(body, "Combat session")
    UI.AddButton(body, 1, "Start a combat session", function() F.Start() end, "Start a combat session",
        "You own the session: your group can join it, you call for initiative, and your game announces whose turn it is and what comes of everyone's rolls. Everyone rolls for their own character.",
        "picked")
    UI.AddLabel(body, 1, UI.GREY .. "Others join from this window once you are in a party or raid with them. Alone, you can still start one and add creatures to fight.|r")
end

-- What the session is doing, in one line.
local function Headline(session)
    local holder = session.members[session.turn or ""]
    local owner = ("Session of %s%s|r"):format(UI.ACCENT, ns.Game.ShortName(session.owner))
    if session.phase ~= "RUN" then return owner end
    return ("%s  %sround %d, %s|r"):format(owner, UI.GREY, session.round, F.MyTurn() and "your turn" or (holder and (holder.name .. "'s turn") or "between turns"))
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
    elseif UI.AddCreaturePicker(self, body) then
        -- the list to add a creature from fills the window (UI/FightWindowCreatures.lua)
    else
        local mine = F.Mine()
        UI.AddLabel(body, 1, Headline(session))
        if PHASE[session.phase] then UI.AddLabel(body, 1, UI.GREY .. PHASE[session.phase] .. "|r") end
        if not mine then
            UI.AddButton(body, 0.5, "Join the session", function() F.Join() end, "Join",
                "Your character joins with the hit points, slots and resources it has now. That state is kept: after the fight you can put it back."
                .. (session.phase == "RUN" and "\nThe turns are running: you roll initiative and act when your place in the order comes up." or ""), "picked")
            UI.AddButton(body, 0.5, "Forget this session", function() F.Leave() end, "Forget", "The session goes on without you.")
        else
            if F.owedSave then
                UI.AddButton(body, 1, ("Roll the %s save (DC %d)"):format(ns.Rules.STAT_NAMES[F.owedSave.stat], F.owedSave.dc),
                    function() F.RollOwedSave() end, "Saving throw",
                    "The session's owner asked for this saving throw. You roll it on your own sheet; the owner's game says whether it meets the DC.\n" .. ns.ROLL_MODE_HELP, "picked")
            end
            if F.OwesInitiative() then
                UI.AddButton(body, 1, "Roll initiative", function() F.RollInitiative() end, "Roll initiative",
                    "A Dexterity check for your place in the order.\n" .. ns.ROLL_MODE_HELP, "picked")
            end
        end
        UI.AddFightRoster(self, body, session)
        UI.AddFightLog(self, body)
        if mine then
            UI.AddFightRunning(self, body)
            UI.AddFightStatus(self, body)
            UI.AddFightTurn(self, body, session, mine)
        end
    end
    body:ResumeLayout()
    UI.SetOut(body)
end
