-- What the sheet window shows. Populate rebuilds every row from the saved sheet: the
-- top part, the tab row, and the sections of the open tab; Refresh only updates the text
-- that changes during play. The sections themselves are in the UI\Sheet*.lua files above.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI

-- Rebuilds the rows on the next frame. Used from a row's own click, because that row
-- is part of what gets rebuilt. Asked for several times in one frame, it rebuilds once.
function RPSheet:PopulateSoon()
    if self.populatePending then return end
    self.populatePending = true
    C_Timer.After(0, function()
        self.populatePending = nil
        self:Populate()
    end)
end

-- Always shown, above the tabs.
local TOP = { UI.HeaderSection, UI.TrackerSection, UI.ConditionSection, UI.CombatSection }

-- The rest, one tab at a time (UI/SheetTabs.lua).
local TABS = {
    { name = "Actions", tip = "Your abilities and spells, and your companion if you have one.",
      UI.PetSection, UI.AbilitySection, UI.SpellSection },
    { name = "Checks", tip = "Ability checks and saving throws.", UI.CheckSection, UI.SaveSection },
    { name = "Skills", tip = "Skills and tools.", UI.SkillSection, UI.ToolSection },
    { name = "Traits", tip = "Passives and traits, languages and renown.", UI.PassiveSection, UI.OriginSection },
    { name = "Items", tip = "Your coins and what you carry, and your mounts, vehicles and companion creatures.",
      UI.InventorySection, UI.MountSection },
    { name = "Trade", tip = "Your professions: what you can make, gathering, and the materials you have.", UI.ProfessionSection },
}

---------------------------------------------------------------------------
-- Populate and Refresh
---------------------------------------------------------------------------
-- Releases and makes again every row of the sheet window.
local function Rebuild(self, body)
    self.populateSkipped = nil
    body:PauseLayout()
    body:ReleaseChildren()
    self.sheetSlotLabels = {} -- the old lines are gone with the rows
    for _, section in ipairs(TOP) do
        section(self, body)
    end
    local tab = UI.AddTabBar(self, body, TABS)
    local before = #body.children
    for _, section in ipairs(tab) do
        section(self, body)
    end
    if #body.children == before then
        UI.AddLabel(body, 1, ("\n%sNothing here yet.|r"):format(UI.GREY))
    end
    -- Fill in the rows whose text comes from Refresh before laying out: a row that is
    -- still empty has no height, and the rows below it would be placed on top of it.
    self:Refresh()
    body:ResumeLayout()
    UI.SetOut(body)
end

local function Fill(self, body)
    -- Nobody sees the rows of a hidden window: they are made when it is shown again
    -- (its OnShow calls Refresh, which catches up).
    if self.window.frame:IsShown() then
        Rebuild(self, body)
    else
        self.populateSkipped = true
    end
    self:PopulateSpellbook() -- the open spellbook follows the sheet
    self:PopulatePrepared()  -- and the open list of spells to prepare
    self:PopulateItemBrowser() -- and so does the open item browser
end

function RPSheet:Populate()
    local body = self.body
    if not body then return end
    -- Making the rows only reads the sheet, so the numbers they ask for again and again
    -- are kept while they are made (Sheet/PassCache.lua). The pass is closed whatever
    -- happens: a number kept past this point could outlive a change to the sheet.
    ns.BeginPass()
    local ok, problem = pcall(Fill, self, body)
    ns.EndPass()
    if not ok then error(problem, 0) end
end

function RPSheet:Refresh()
    if not self.window or not self.channelLabel then return end
    if self.populateSkipped then
        -- The rows are out of date. Shown again: make them now, which ends in a Refresh.
        if self.window.frame:IsShown() then return Rebuild(self, self.body) end
        -- Still hidden: only what reaches beyond the sheet's own rows.
        self:RefreshSlotLabels() -- the spellbook window may be open
        self:QueueBroadcast()
        return
    end
    self:RefreshSlotLabels()
    self:QueueBroadcast()
    local state = self:State()
    self.window:SetTitle(self:GetCharacterName())
    self.channelLabel:SetText(("Announce to: %s%s|r"):format(UI.ACCENT, ns.CHANNEL_LABEL[self.db.profile.channel]))
    if self.rollModeLabel then
        local mode = self.rollMode
        local text = (mode == "ADV" and "|cff80ff80Advantage|r") or (mode == "DIS" and "|cffff5555Disadvantage|r") or (UI.ACCENT .. "Normal|r")
        if mode and self.rollModeLocked then text = text .. " (every roll)" end
        self.rollModeLabel:SetText(("Next roll: %s"):format(text))
    end

    if self.castLevelLabel then
        self.castLevelLabel:SetText(("Cast at: %s%s|r"):format(UI.ACCENT, self.castLevel and (R.ORDINALS[self.castLevel] .. " level") or "lowest slot"))
    end

    local weapon = self:GetWeapon()
    if weapon and self.attackLabel then
        UI.SetText(self.attackLabel, ("%s  %s%s|r"):format(weapon.name, UI.GREY, self:WeaponText(weapon)))
    end

    for _, row in ipairs(self.trackerRows) do
        local tracker = row.tracker
        local value = tracker.get() or 0
        -- A slot made above the usual number lifts the row's upper end while it lasts (Sheet/Trackers.lua).
        local max = tracker.usual and math.max(tracker.usual, value) or tracker.max
        if row.bar then
            local text = ("%s %d/%d"):format(tracker.label, value, max)
            if tracker.kind == "hp" and state.tempHP > 0 then text = text .. (" (+%d)"):format(state.tempHP) end
            row.widget:SetValue(value, max)
            row.widget:SetText(text)
        else
            local short = tracker.label:gsub("%-level slot", "")
            row.widget:SetText(("%s %s%d/%d|r"):format(short, UI.ACCENT, value, max))
        end
    end

    self.tempLabel:SetText(("Temp HP %s%d|r"):format(UI.ACCENT, state.tempHP))
    self.inspirationLabel:SetText(("Inspiration %s%s|r"):format(UI.ACCENT, state.inspiration and "yes" or "no"))
    if self.deathLabel then
        local status = "click to roll"
        if state.deathFail >= 3 then
            status = "dead"
        elseif state.deathPass >= 3 then
            status = "stable at 0 HP"
        end
        self.deathLabel:SetText(("%sDeath saves: %d passed, %d failed - %s|r"):format(
            "|cffff5555", state.deathPass, state.deathFail, status))
    end
end
