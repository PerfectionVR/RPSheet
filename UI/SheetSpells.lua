-- The sheet's spell list, with the doors to the spellbook and the prepared spells.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local Util = ns.Util

-- What a spell's tooltip says below its own text: how it is cast, what a higher slot
-- does for it, its components, and how it is clicked. Worked out when it is hovered.
local function Tip(self, spell)
    local lines = {}
    if spell.desc ~= "" then lines[#lines + 1] = spell.desc end
    -- A spell chosen for a class feature says so, and how it is cast without a slot.
    local mark, note, noSlots = self:ChosenSpellNote(spell)
    if mark then lines[#lines + 1] = note end
    if not noSlots then
        lines[#lines + 1] = spell.level == 0 and "A cantrip: no spell slot needed."
            or ("Uses your lowest free slot of %s level or higher, or the level set at \"Cast at\"."):format(R.ORDINALS[spell.level])
    end
    -- What a higher slot does for it (see Actions/SlotGrowth.lua).
    for _, line in ipairs(self:SlotGrowthHelp(spell)) do lines[#lines + 1] = line end
    local casting = R.SpellCastingNote(spell)
    if casting then lines[#lines + 1] = casting end
    for _, line in ipairs(self:ComponentHelp(spell)) do lines[#lines + 1] = line end
    if spell.ritual then lines[#lines + 1] = "Right-click: cast it as a ritual. It takes ten minutes longer and uses no slot." end
    if spell.kind == "ATTACK" then lines[#lines + 1] = ns.ROLL_MODE_HELP end
    if R.GROWING_SPELLS[spell.name] then
        lines[#lines + 1] = self:GrowingSides(spell)
            and "It is running. Left-click when the target fails its save again: the die grows and the damage is rolled, without a slot. Right-click when it succeeds or the spell runs out: that ends it."
            or "After casting, click it again each time the target fails its save: the die grows and the damage is rolled, without a slot."
    end
    return table.concat(lines, "\n")
end

-- The spell list, cantrips first, then by level.
function UI.SpellSection(self, body)
    local spells = Util.Named(self:Sheet().spells)
    local book = ns.HasSpellbook(self:Sheet())
    local atRest = ns.ChangesPreparedAtRest(self:Sheet())
    local runs = self:ScrollRuns() -- growing spells read from a scroll (Actions/GrowingSpells.lua)
    if #spells == 0 and not book and not atRest and #runs == 0 then return end
    table.sort(spells, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)

    UI.AddHeading(body, "Spells")
    self.sheetSlotLabels = {}
    if book then
        UI.AddLabel(body, 1, UI.ACCENT .. "Open spellbook|r", function() self:ToggleSpellbook() end, "Spellbook",
            "Every spell in your book. Cast from it, and choose which spells are prepared. The spells listed below are the prepared ones and your cantrips.")
    end
    if atRest then
        UI.AddLabel(body, 1, UI.ACCENT .. "Change prepared spells|r", function() self:TogglePreparedWindow() end, "Prepared spells",
            "The spells of your class you could have prepared. After a long rest you change which ones are, until you cast your first spell.")
    end
    local shown -- the spell level whose line was added last
    for _, spell in ipairs(spells) do
        -- A line per spell level, with the slots left of that level.
        if spell.level ~= shown then
            shown = spell.level
            self:AddLevelLabel(body, shown, self.sheetSlotLabels)
        end
        local info = self:SpellText(spell)
        -- A spell chosen for a class feature says so.
        local mark = self:ChosenSpellNote(spell)
        if mark then info = info ~= "" and (info .. ", " .. mark) or mark end
        UI.AddLabel(body, 1, ("%s  %s%s|r"):format(spell.name, UI.GREY, info),
            function(button) self:CastSpell(spell, ns.RollMode(), button == "RightButton") end, spell.name,
            function() return Tip(self, spell) end,
            function() self:ExplainSpell(spell) end)
    end
    -- A growing spell read from a scroll runs with the scroll's numbers: a row of its
    -- own for as long as it lasts.
    for _, run in ipairs(runs) do
        UI.AddLabel(body, 1, ("%s (from a scroll)  %s%s|r"):format(run.name, UI.GREY, self:SpellText(run)),
            function(button)
                if self.busy or self:IsRolling() then return end
                self:GrowingSpellClick(run, button == "RightButton")
            end, run.name .. " (from a scroll)",
            "It is running. Left-click when the target fails its save again: the die grows and the damage is rolled. Right-click when it succeeds or the spell runs out: that ends it.")
    end
end
