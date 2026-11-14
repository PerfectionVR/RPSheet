-- The spellbook window: every spell in a Mage's book, by level. Opened from the
-- sheet's Spells section. Left-click casts, right-click prepares or puts away.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local HELP = "Left-click: cast it.\nRight-click: prepare it, or put it away."

local function Build(self)
    local profile = self.db.profile
    profile.spellbookWindow = profile.spellbookWindow or { width = 300, height = 420 }

    local window = AceGUI:Create("RPSheetWindow")
    window:SetStatusTable(profile.spellbookWindow)
    window:SetLayout("Fill")
    window:SetCallback("OnLockClick", function() window:SetLocked(not window.locked) end)
    window:SetCallback("OnEditClick", function()
        AceConfigDialog:Open(ADDON)
        AceConfigDialog:SelectGroup(ADDON, "customize", "spellbook")
    end)
    window:SetCallback("OnShow", function() self:PopulateSpellbook() end)
    self.bookWindow = window

    local body = AceGUI:Create("ScrollFrame")
    body:SetLayout("Flow")
    window:AddChild(body)
    self.bookBody = body
end

function RPSheet:ToggleSpellbook()
    if not self.bookWindow then
        Build(self) -- a new window is already shown
        self:PopulateSpellbook()
        return
    end
    if self.bookWindow.frame:IsShown() then self.bookWindow:Hide() else self.bookWindow:Show() end
end

-- One row per spell. Spells that aren't prepared are greyed.
local function AddSpell(self, body, name)
    local known = R.SPELLS[name]
    local prepared = self:PreparedSpell(name)
    local spell = prepared or known
    local info = self:SpellText(spell)
    local lines = {}
    if spell.desc ~= "" then lines[#lines + 1] = spell.desc end
    local casting = R.SpellCastingNote(spell)
    if casting then lines[#lines + 1] = casting end
    -- What a higher slot does for it (see Actions/SlotGrowth.lua).
    for _, line in ipairs(self:SlotGrowthHelp(spell)) do lines[#lines + 1] = line end
    -- A spell chosen for a class feature (mastered, signature) says so.
    local mark, note
    if prepared then mark, note = self:ChosenSpellNote(prepared) end
    if note then lines[#lines + 1] = note end
    if prepared then
        lines[#lines + 1] = UI.GREEN .. "Prepared.|r"
    elseif known.ritual then
        lines[#lines + 1] = "Not prepared. As a ritual it can still be cast from the book: ten minutes longer, no slot."
    else
        lines[#lines + 1] = "Not prepared: it can't be cast until it is."
    end
    lines[#lines + 1] = UI.GREY .. HELP .. "|r"

    local tags = {}
    if info ~= "" then tags[#tags + 1] = info end
    if known.ritual then tags[#tags + 1] = "ritual" end
    if mark then tags[#tags + 1] = mark end
    local text
    if prepared then
        text = ("%s  %s%s|r"):format(name, UI.GREY, table.concat(tags, ", "))
    else
        tags[#tags + 1] = "not prepared"
        text = ("%s%s  %s|r"):format(UI.GREY, name, table.concat(tags, ", "))
    end
    UI.AddLabel(body, 1, text, function(button)
        if button == "RightButton" then
            local changed
            if prepared then changed = self:UnprepareSpell(name) else changed = self:PrepareSpell(name) end
            -- On the next frame: this row is part of what gets rebuilt.
            if changed then C_Timer.After(0, function() self:SheetChanged() end) end
        else
            self:CastFromBook(name, ns.RollMode())
        end
    end, name, table.concat(lines, "\n"))
end

-- Fills the window. Called when it opens and whenever the sheet is rebuilt.
function RPSheet:PopulateSpellbook()
    local window, body = self.bookWindow, self.bookBody
    if not window or not window.frame:IsShown() then return end
    local sheet = self:Sheet()
    window:SetTheme(self.db.profile.theme)
    window:SetTitle(("%s - Spellbook"):format(self:GetCharacterName()))

    body:PauseLayout()
    body:ReleaseChildren()
    self.bookSlotLabels = {}
    if not ns.HasSpellbook(sheet) then
        UI.AddLabel(body, 1, "This character keeps no spellbook.")
    else
        local names = ns.SpellbookNames(sheet)
        local _, maxPrepared = self:SpellLimits()
        local _, prepared = self:SpellCounts()
        UI.AddLabel(body, 1, ("Prepared %s%d of %d|r, from %d spells in the book."):format(UI.ACCENT, prepared, maxPrepared, #names),
            nil, "Spellbook", "After a long rest you choose which spells of your book are prepared. Only prepared spells can be cast, except rituals, which can be cast straight from the book.\n\n" .. HELP)
        if #names == 0 then
            UI.AddLabel(body, 1, UI.GREY .. "The book is empty. Add spells under Customize, Spellbook (the cog above).|r")
        end
        -- The core spells and the spells of Azeroth each under their own heading, by level.
        local section, level
        for _, name in ipairs(names) do
            if R.SpellGroup(name) ~= section then
                section, level = R.SpellGroup(name), nil
                UI.AddHeading(body, R.SPELL_GROUPS[section])
            end
            if R.SPELLS[name].level ~= level then
                level = R.SPELLS[name].level
                self:AddLevelLabel(body, level, self.bookSlotLabels)
            end
            AddSpell(self, body, name)
        end
    end
    body:ResumeLayout()
    body:DoLayout()
end
