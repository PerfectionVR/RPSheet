-- The Scrolls tab of the crafting window (UI/CraftBrowser.lua): a block for every
-- spell the character could put on a scroll, with what scribing it takes and a
-- button to scribe it (Sheet/Scribing.lua).
local _, ns = ...
local R = ns.Rules
local UI = ns.UI

local RED = "|cffff5555"

UI.Scribe = { tab = { name = "Scrolls", scribe = true } }
local Scribe = UI.Scribe

-- One entry per spell the character has on its list or in its book.
function Scribe.entries(self)
    local entries = {}
    for _, spell in ipairs(self:ScribeSpells()) do
        entries[#entries + 1] = { name = R.SCROLL_PREFIX .. spell.name, spell = spell, scribe = true }
    end
    return entries
end

function Scribe.marks(self, entry)
    local level = entry.spell.level
    local marks = { level == 0 and "cantrip" or (R.SPELL_LEVELS[level] or "spell"):lower() }
    local carried = self:CarriedItem(entry.name)
    if carried then marks[#marks + 1] = "you have " .. carried.qty end
    return marks
end

function Scribe.lines(self, entry)
    local spell = entry.spell
    local rarity = R.SCROLL_RARITY[spell.level] or "Legendary"
    local lines = { ("%sSpell scroll, %s|r"):format(R.RARITY_COLORS[rarity] or UI.ACCENT, rarity:lower()) }
    local facts = self:SpellText(spell)
    if facts ~= "" then lines[#lines + 1] = facts:gsub("^%l", string.upper) .. "." end
    if (spell.desc or "") ~= "" then lines[#lines + 1] = spell.desc end
    lines[#lines + 1] = UI.GREY .. "Read from the scroll it needs no spell slot and no components, and the scroll crumbles.|r"
    return lines
end

function Scribe.notes(self, entry)
    local spell = entry.spell
    local lines = { ("%sTo scribe: inks and parchment worth %s and %s of work, with the spell prepared on each day.|r"):format(
        UI.ACCENT, ns.CoinText((ns.ScribeCost(spell.level))), ns.DaysText(self:ScribeDays(spell))) }
    local can, why = self:CanScribe(spell)
    if not can then lines[#lines + 1] = ("%sNot now: %s.|r"):format(RED, why) end
    return lines
end

-- `changed` rebuilds the windows after a button did something.
function Scribe.buttons(self, card, entry, changed)
    local spell = entry.spell
    UI.AddItemButton(card, 0.5, "Scribe  " .. ns.CoinText((ns.ScribeCost(spell.level))), (self:CanScribe(spell)), function()
        if self:Scribe(spell) then changed(self) end
    end)
    local ways = self:ScribeWays()
    if ways and ways.scribe and self:MaterialsFor(R.PROFESSIONS.inscription) > 0 then
        UI.AddItemButton(card, 0.5, "Coins only", (self:CanScribe(spell, true)), function()
            if self:Scribe(spell, true) then changed(self) end
        end)
    end
end
