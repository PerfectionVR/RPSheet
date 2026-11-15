-- The line above each spell level in a list of spells: "1st level  slots 2/4". The
-- slot count follows the sheet, so the lines are kept and updated on every Refresh.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI

-- "slots 2/4" for a spell level, or "" when the character has no slots of it.
function RPSheet:SlotText(level)
    for _, tracker in ipairs(self:GetTrackers()) do
        if tracker.kind == "slot" and tracker.level == level then
            return ("slots %d/%d"):format(tracker.get() or 0, tracker.max)
        end
    end
    return ""
end

local function Text(self, level)
    if level == 0 then return UI.ACCENT .. "Cantrips|r  " .. UI.GREY .. "no slot needed|r" end
    local slots = self:SlotText(level)
    if slots == "" then
        -- A Warlock's spells above 5th level are Mystic Arcanum: cast without a slot.
        local class = self:ClassData()
        slots = class and class.caster == "PACT" and "cast once each, without a slot" or "no slots of this level"
    end
    return ("%s%s|r  %s%s|r"):format(UI.ACCENT, R.SPELL_LEVELS[level], UI.GREY, slots)
end

-- Adds the line for a spell level and remembers it in `list` for RefreshSlotLabels.
function RPSheet:AddLevelLabel(body, level, list)
    local label = UI.AddLabel(body, 1, Text(self, level), nil, level == 0 and "Cantrips" or R.SPELL_LEVELS[level],
        level == 0 and "Cantrips are cast at will."
            or "Casting a spell spends one slot of its level, or of a higher level when those are used up or when you set one at \"Cast at\". All slots come back on a long rest.")
    list[#list + 1] = { label = label, level = level }
    return label
end

-- self.sheetSlotLabels belong to the sheet, self.bookSlotLabels to the spellbook window.
function RPSheet:RefreshSlotLabels()
    for _, list in ipairs({ self.sheetSlotLabels or {}, self.bookSlotLabels or {} }) do
        for _, entry in ipairs(list) do
            entry.label:SetText(Text(self, entry.level))
        end
    end
end
