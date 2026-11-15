-- The window for changing prepared spells after a long rest, for the classes that
-- prepare from their class list (rules in Sheet/PrepareRules.lua). Opened from the
-- sheet's Spells section. Left-click casts a prepared spell, right-click prepares a
-- spell or puts it away. A Mage has the spellbook window instead.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local HELP = "Left-click: cast it, if it is prepared.\nRight-click: prepare it, or put it away."
local RULES = {
    REST = "When you finish a long rest you can change any of your prepared spells for others of your class.",
    REST_ONE = "When you finish a long rest you can change one of your prepared spells for another of your class.",
}

local function Build(self)
    local profile = self.db.profile
    profile.preparedWindow = profile.preparedWindow or { width = 300, height = 420 }

    local window = AceGUI:Create("RPSheetWindow")
    window:SetStatusTable(profile.preparedWindow)
    window:SetLayout("Fill")
    window:SetCallback("OnLockClick", function() window:SetLocked(not window.locked) end)
    window:SetCallback("OnMinimizeClick", function() window:SetMinimized(not window.minimized) end)
    window:SetCallback("OnEditClick", function()
        AceConfigDialog:Open(ADDON)
        AceConfigDialog:SelectGroup(ADDON, "customize", "spells")
    end)
    window:SetCallback("OnShow", function() self:PopulatePrepared() end)
    self.preparedWindow = window

    local body = AceGUI:Create("ScrollFrame")
    body:SetLayout("Flow")
    window:AddChild(body)
    self.preparedBody = body
end

function RPSheet:TogglePreparedWindow()
    if not self.preparedWindow then
        Build(self) -- a new window is already shown
        self:PopulatePrepared()
        return
    end
    if self.preparedWindow.frame:IsShown() then self.preparedWindow:Hide() else self.preparedWindow:Show() end
end

-- One row per spell. Spells that aren't prepared are greyed.
-- `classKey` is the class the spell is prepared for.
local function AddSpell(self, body, name, isPrepared, classKey)
    local known = R.SPELLS[name]
    local entry = isPrepared and self:PreparedSpell(name) or nil
    -- Two classes can have the same spell prepared: the row is this class's own.
    for _, spell in ipairs(isPrepared and self:Sheet().spells or {}) do
        if spell.name == name and spell.class == classKey then entry = spell end
    end
    local spell = entry or known
    local info = self:SpellText(spell)
    local lines = {}
    if spell.desc ~= "" then lines[#lines + 1] = spell.desc end
    local casting = R.SpellCastingNote(spell)
    if casting then lines[#lines + 1] = casting end
    for _, line in ipairs(self:SlotGrowthHelp(spell)) do lines[#lines + 1] = line end
    lines[#lines + 1] = isPrepared and (UI.GREEN .. "Prepared.|r") or "Not prepared: it can't be cast until it is."
    lines[#lines + 1] = UI.GREY .. HELP .. "|r"

    local text
    if isPrepared then
        text = ("%s  %s%s|r"):format(name, UI.GREY, info)
    else
        text = ("%s%s  %s|r"):format(UI.GREY, name, info ~= "" and (info .. ", not prepared") or "not prepared")
    end
    UI.AddLabel(body, 1, text, function(button)
        if button == "RightButton" then
            -- On the next frame: this row is part of what gets rebuilt.
            if self:ChangePrepared(name, classKey) then C_Timer.After(0, function() self:SheetChanged() end) end
        elseif entry then
            self:CastSpell(entry, ns.RollMode())
        else
            self:Print(("%s isn't prepared. Right-click it to prepare it."):format(name))
        end
    end, name, table.concat(lines, "\n"))
end

-- The spells of one class (an entry of ns.PrepareRules). `named` puts the class's name
-- above them, for a character with several classes that prepare this way.
local function AddClass(self, body, sheet, entry, named)
    local key, view = entry.key, entry.view
    local picks = sheet.picks[key] or {}
    if named then UI.AddHeading(body, R.CLASSES[entry.class].name) end
    UI.AddLabel(body, 1, ("Prepared %s%d of %d|r. %s"):format(UI.ACCENT, ns.PicksKnown(sheet, key),
        ns.PickLimit(key, view.class, view.level), self:PrepareStatus(entry.class)),
        nil, "Prepared spells", RULES[entry.rule] .. " The sheet keeps no clock: the list can be changed from a long rest until you cast your first spell after it. Spells that are always prepared are not listed here.\n\n" .. HELP)
    -- The core spells and the spells of Azeroth each under their own heading, by level.
    local section, level
    for _, name in ipairs(ns.PreparedChoices(sheet, entry)) do
        if R.SpellGroup(name) ~= section then
            section, level = R.SpellGroup(name), nil
            local group = R.SPELL_GROUPS[section]
            UI.AddHeading(body, named and ("%s: %s"):format(R.CLASSES[entry.class].name, group) or group)
        end
        if R.SPELLS[name].level ~= level then
            level = R.SPELLS[name].level
            UI.AddLabel(body, 1, UI.ACCENT .. R.SPELL_LEVELS[level] .. "|r")
        end
        AddSpell(self, body, name, picks[name] == true, entry.class)
    end
end

-- Fills the window. Called when it opens and whenever the sheet is rebuilt.
function RPSheet:PopulatePrepared()
    local window, body = self.preparedWindow, self.preparedBody
    if not window or not window.frame:IsShown() then return end
    local sheet = self:Sheet()
    window:SetTheme(self.db.profile.theme)
    window:SetTitle(("%s - Prepared spells"):format(self:GetCharacterName()))

    body:PauseLayout()
    body:ReleaseChildren()
    local entries = ns.RestPreparers(sheet)
    if #entries == 0 then
        UI.AddLabel(body, 1, "This character doesn't change prepared spells after a long rest.")
    end
    -- One part per class, each with its own count and rule.
    for _, entry in ipairs(entries) do AddClass(self, body, sheet, entry, #entries > 1) end
    -- A class that changes them by level is named, so it isn't looked for here.
    for _, entry in ipairs(#entries > 0 and ns.PrepareRules(sheet) or {}) do
        if entry.rule == "LEVEL" then
            UI.AddLabel(body, 1, ("%s%s changes a prepared spell when it gains a level, not after a rest.|r"):format(UI.GREY, R.CLASSES[entry.class].name))
        end
    end
    body:ResumeLayout()
    body:DoLayout()
end
