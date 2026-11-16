-- Which of the advantages on saving throws in Data/SaveAdvantages.lua the character
-- has right now: the ones that always count (RPSheet:AdvantageFrom uses them), the
-- ones that depend on what the save is against (the sheet asks: see
-- Actions/SaveAdvantages.lua), and the one on the save to keep a spell.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local NONE = {}

-- Everything by name that can give such an advantage, as { name = true }.
local function Owned(self)
    local sheet, owned = self:Sheet(), {}
    local species = R.SPECIES[sheet.species]
    for _, trait in ipairs(species and species.traits or NONE) do owned[trait] = true end
    for _, passive in ipairs(sheet.passives or NONE) do
        if passive.enabled and passive.name ~= "" then owned[passive.name] = true end
    end
    for _, item in ipairs(sheet.items or NONE) do
        if item.name ~= "" and self:ItemActive(item) then owned[item.name] = true end
    end
    for _, list in ipairs({ "invocations", "metamagic" }) do
        for name, picked in pairs(sheet.picks and sheet.picks[list] or NONE) do
            if picked then owned[name] = true end
        end
    end
    local _, companion = self:CompanionGift()
    if companion then owned[(companion.family or "") .. " companion"] = true end
    return owned
end

-- True when the character has what the entry names, and it may be in effect.
local function Has(self, owned, entry)
    return owned[entry.from] == true
end

local function Covers(entry, stat)
    if not entry.saves then return true end
    for _, name in ipairs(entry.saves) do
        if name == stat then return true end
    end
    return false
end

-- For a roll's label ("WIS save"): the entries that always give advantage on it, and
-- the ones that do against something, as { about = "being Charmed", from = "Fey Ancestry" }.
-- Both are empty for a roll that isn't a saving throw.
function RPSheet:SaveAdvantages(label)
    local always, asked = {}, {}
    local stat = type(label) == "string" and label:match("^(%u+) save$")
    if not stat then return always, asked end
    local owned = Owned(self)
    for _, entry in ipairs(R.SAVE_ADVANTAGES) do
        if Has(self, owned, entry) and not entry.concentration and Covers(entry, stat) then
            if not entry.about then always[#always + 1] = entry end
            for _, about in ipairs(entry.about or NONE) do
                asked[#asked + 1] = { about = about, from = entry.from }
            end
        end
    end
    return always, asked
end

-- What gives advantage on the save to keep concentrating on any spell: its name, or nil.
function RPSheet:ConcentrationAdvantage()
    local owned = Owned(self)
    for _, entry in ipairs(R.SAVE_ADVANTAGES) do
        if entry.concentration and not entry.about and Has(self, owned, entry) then return entry.from end
    end
end

-- What gives it for some spells only, as { about = "a spell you extended", from =
-- "Extended Spell" }: the sheet asks when it rolls that save.
function RPSheet:ConcentrationChoices()
    local owned, choices = Owned(self), {}
    for _, entry in ipairs(R.SAVE_ADVANTAGES) do
        if entry.concentration and entry.about and Has(self, owned, entry) then
            for _, about in ipairs(entry.about) do choices[#choices + 1] = { about = about, from = entry.from } end
        end
    end
    return choices
end

-- Lines for a saving throw's tooltip, such as "Advantage against being Charmed (Fey
-- Ancestry)."; nil when there is nothing to say.
function RPSheet:SaveAdvantageText(stat)
    local always, asked = self:SaveAdvantages(stat .. " save")
    local lines = {}
    for _, entry in ipairs(always) do lines[#lines + 1] = ("Advantage (%s)."):format(entry.from) end
    -- A character that has stopped the question (Actions/RollQuestions.lua) rolls it by hand.
    local how = self:RollQuiet("about") and "Shift-click when it applies" or "the sheet asks when you roll"
    for _, entry in ipairs(asked) do
        lines[#lines + 1] = ("Advantage against %s (%s): %s."):format(entry.about, entry.from, how)
    end
    if stat == "CON" and self:ConcentrationAdvantage() then
        lines[#lines + 1] = ("Advantage to keep concentrating (%s)."):format(self:ConcentrationAdvantage())
    end
    for _, choice in ipairs(stat == "CON" and self:ConcentrationChoices() or NONE) do
        local how = self:RollQuiet("holding") and "the question is off, so the sheet rolls without it" or "the sheet asks when damage calls for that save"
        lines[#lines + 1] = ("Advantage to keep concentrating on %s (%s): %s."):format(choice.about, choice.from, how)
    end
    return #lines > 0 and table.concat(lines, "\n") or nil
end
