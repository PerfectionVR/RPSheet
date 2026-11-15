-- The Trade tab of the sheet window: the character's skill at professions, the ones
-- it makes things with, the gathering checks, and the materials it has gathered.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local Signed = ns.Util.Signed

local LEVELS = { 2, 3, 4, 5, 6 }

-- What each skill level of a making profession opens; the levels reached are lit.
local function MakesText(profession, level)
    local lines = {}
    for _, at in ipairs(LEVELS) do
        local makes = profession.makes and profession.makes[at]
        if makes then
            lines[#lines + 1] = ("%s%s (+%d):|r %s"):format(at <= level and UI.ACCENT or UI.GREY, R.PROFESSION_LEVELS[at].name, at, makes)
        end
    end
    return table.concat(lines, "\n")
end

-- The tooltips of this section are put together when a row is hovered.
local function SkillTip(level)
    local lines = { "Your skill at every profession you practise follows your proficiency bonus, and sets how rare a magic item you can make:" }
    for _, at in ipairs(LEVELS) do
        local row = R.PROFESSION_LEVELS[at]
        lines[#lines + 1] = ("%s%s (+%d):|r %s"):format(at <= level and UI.ACCENT or UI.GREY, row.name, at, row.rarity:lower())
    end
    lines[#lines + 1] = ("\nYou practise a profession when you are proficient with one of its tools. Where your table trains to gain levels, a new skill level takes as many days with a trainer as your new bonus, at %s a day."):format(ns.CoinText(R.TRAINING_COPPER_PER_DAY))
    return table.concat(lines, "\n")
end

local function SkillRow(body, level)
    UI.AddLabel(body, 1, ("Skill  %s%s (%s)|r"):format(UI.ACCENT, R.PROFESSION_LEVELS[level].name, Signed(level)), nil,
        "Profession skill", function() return SkillTip(level) end)
end

local function MakingTip(self, profession, level)
    local lines = { profession.desc, ("You use: %s."):format(self:CraftTool(profession) or self:ProfessionTool(profession)), MakesText(profession, level) }
    local missing = self:MissingTool(profession)
    if missing then lines[#lines + 1] = ("|cffff5555Not now: %s.|r"):format(missing) end
    if self:ProfessionHaste(profession) then lines[#lines + 1] = UI.GREEN .. "A faction's favor halves the time it takes you.|r" end
    lines[#lines + 1] = ("\nGathered %s pay for materials before your coins do, unless you choose coins only. Click to see what you can make."):format(
        table.concat(ns.MaterialNames(profession.uses), " and "))
    return table.concat(lines, "\n")
end

local function MakingRows(self, body, level)
    local made = self:Professions("make")
    for _, profession in ipairs(made) do
        UI.AddLabel(body, 0.5, UI.ACCENT .. profession.name .. "|r", function() self:ShowCrafting(profession) end,
            profession.name, function() return MakingTip(self, profession, level) end)
    end
    if self:CanPractise(R.PROFESSIONS.cooking) and level >= R.FEAST_LEVEL then
        UI.AddLabel(body, 0.5, "Great feast", function() self:CookFeast() end, "Great feast", function()
            return ("An hour of cooking and %s of ingredients lay out a meal that works as Heroes' Feast. Fish and herbs you gathered pay first."):format(ns.CoinText(R.FEAST_COST))
        end)
    end
    if self:CanPractise(R.PROFESSIONS.enchanting) and level >= R.DISENCHANT_LEVEL then
        local label
        label = UI.AddLabel(body, 0.5, "Disenchant", function() self:OpenDisenchantMenu(label.frame) end, "Disenchant",
            "An hour with a lasting magic item you carry turns it into magical residue, which pays for enchanting. A common item takes journeyman skill and leaves 25 gp, an uncommon one expert skill and 100 gp, a rare one artisan skill and 1,000 gp, a very rare one master skill and 10,000 gp. Legendary items and artifacts can't be taken apart.")
    end
    return #made
end

local function GatheringRows(self, body)
    local region = self:GatherRegion()
    local function RegionTip()
        local lines = { "Where you gather sets the DC and what a find is worth. For skinning it is the creature's challenge rating.\n" }
        for _, row in ipairs(R.REGIONS) do
            lines[#lines + 1] = ("%s%s:|r DC %d, common %s, rare %s"):format(row == region and UI.ACCENT or UI.GREY,
                row.name:gsub("^%l", string.upper), row.dc, ns.CoinText(row.common), ns.CoinText(row.rare))
        end
        lines[#lines + 1] = "\nLeft-click: the next one.\nRight-click: the one before."
        return table.concat(lines, "\n")
    end
    UI.AddLabel(body, 1, ("Gathering at %s%s|r  %sDC %d|r"):format(UI.ACCENT, region.name, UI.GREY, region.dc),
        function(button) self:CycleGatherRegion(button == "RightButton") end, "Region", RegionTip)
    for _, profession in ipairs(self:Professions("gather")) do
        local dig = profession.key == "archaeology"
        local mod = self:GatherMod(profession)
        UI.AddLabel(body, 0.5, ("%s%s|r %s%s|r"):format(UI.ACCENT, profession.name, UI.GREY, Signed(mod)),
            function() if dig then self:Dig(ns.RollMode()) else self:Gather(profession, ns.RollMode()) end end,
            profession.name, function() return ("%s\n\nClick to roll against DC %d.\n%s"):format(profession.desc, region.dc, ns.ROLL_MODE_HELP) end)
    end
    local fragments = self:Trade().fragments
    if self:CanPractise(R.PROFESSIONS.archaeology) or fragments.plain + fragments.magic > 0 then
        UI.AddLabel(body, 0.5, ("Fragments %s%d/%d|r"):format(UI.ACCENT, fragments.plain, R.RELIC_FRAGMENTS),
            function() self:AssembleRelic(ns.RollMode()) end, "Fragments",
            function()
                local blocked = self:RelicBlocked()
                return ("%d fragments of one origin make a relic with a DC %d Intelligence (History) check. It is worth a common find for your own level. After a failed try you need another fragment first.%s\n\nClick to try.\n%s"):format(
                    R.RELIC_FRAGMENTS, R.RELIC_DC, blocked and ("\n\n|cffff5555Not now: %s.|r"):format(blocked) or "", ns.ROLL_MODE_HELP)
            end)
        UI.AddLabel(body, 0.5, ("Magic fragments %s%d/%d|r"):format(UI.ACCENT, fragments.magic, R.RELIC_FRAGMENTS),
            function() self:AssembleMagicItem() end, "Magic fragments",
            function()
                return ("%d magic fragments of one origin make a magic item of the DM's choice, as rare as your skill allows: %s now.\n\nClick to assemble one."):format(
                    R.RELIC_FRAGMENTS, R.PROFESSION_LEVELS[self:ProfessionLevel()].rarity:lower())
            end)
    end
end

local function MaterialRows(self, body)
    local materials = self:Trade().materials
    for _, kind in ipairs(R.MATERIAL_ORDER) do
        UI.AddLabel(body, 0.5, ("%s %s%s|r"):format(R.MATERIALS[kind], UI.ACCENT, ns.CoinText(materials[kind])),
            function(button) self:MaterialDialog(kind, button == "RightButton") end, R.MATERIALS[kind],
            "What you gathered, bought or found, kept as a worth and not as named things. It pays for what you make before your coins do, and can be sold.\n\nLeft-click: add.\nRight-click: take away.")
    end
end

function UI.ProfessionSection(self, body)
    local level = self:ProfessionLevel()
    UI.AddHeading(body, "Professions")
    SkillRow(body, level)
    UI.AddLabel(body, 1, UI.ACCENT .. "Make something|r", function() self:ShowCrafting() end, "Crafting",
        "Opens a window with everything your professions can make, and the spell scrolls you can scribe: what it costs in materials, how long it takes, and a button to make it.")
    if MakingRows(self, body, level) == 0 then
        UI.AddLabel(body, 1, UI.GREY .. "You make things once you are proficient with a kind of artisan's tools.|r", nil, "Making professions",
            function() return ns.ProfessionNeeds("make") end)
    end
    UI.AddHeading(body, "Gathering")
    GatheringRows(self, body)
    UI.AddLabel(body, 1, UI.GREY .. "What the other professions need|r", nil, "Professions", function() return ns.ProfessionNeeds() end)
    UI.AddHeading(body, "Materials")
    MaterialRows(self, body)
end
