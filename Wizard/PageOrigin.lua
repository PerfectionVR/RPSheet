-- Wizard step 2: the origin (species, size, lineage and background).
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard
local GOLD = Opt.GOLD
local Field, Page = W.DraftField, W.Page
local DraftTraitPicker = W.DraftTraitPicker -- Wizard/PageOriginTraits.lua

local function OriginSummary()
    local lines = {}
    local species, background = R.SPECIES[W.draft.species], R.BACKGROUNDS[W.draft.background]
    if species then
        lines[#lines + 1] = ("%s%s|r: speed %d ft%s."):format(
            GOLD, species.name, species.speed,
            species.darkvision and (", " .. ns.Term("Darkvision", "darkvision " .. species.darkvision .. " ft")) or "")
        lines[#lines + 1] = "Traits: " .. ns.Terms(species.traits) .. "."
        local _, lineage = R.Lineage(W.draft.species, W.draft.lineage)
        if lineage then
            lines[#lines + 1] = ("%s%s|r: %s"):format(GOLD, lineage.name, lineage.desc)
        end
        lines[#lines + 1] = ""
    end
    if background then
        lines[#lines + 1] = ("%s%s|r: raise %s."):format(GOLD, background.name, ns.Terms(background.stats))
        lines[#lines + 1] = ("Skills: %s. %s: %s."):format(
            ns.Terms(background.skills), ns.Term("Origin feat"), ns.Term(background.feat))
        lines[#lines + 1] = ""
    end
    if #lines == 0 then
        lines[1] = "Pick a species and a background. Together they are your origin: traits, skills, a feat and ability score increases."
    else
        lines[#lines + 1] = "|cff909090Hover a highlighted word for an explanation.|r"
    end
    return table.concat(lines, "\n") .. "\n"
end

local originPage = Page(2, {
    traitSkillful = DraftTraitPicker("Skillful", 3.1),
    traitKeenSenses = DraftTraitPicker("Keen Senses", 3.2),
    traitVersatile = DraftTraitPicker("Versatile", 3.3),
    traitDesign = DraftTraitPicker("Specialized Design", 3.4),
    traitDesign2 = DraftTraitPicker("Specialized Design 2", 3.5),
    species = {
        type = "select", order = 1, name = "Species",
        values = Opt.NameMap(R.SPECIES, R.SPECIES_ORDER), sorting = R.SPECIES_ORDER,
        get = function() return W.draft.species end,
        set = function(_, value)
            local sizes = R.SPECIES[value].sizes
            W.draft.species, W.draft.size, W.draft.lineage = value, sizes[#sizes], ""
            wipe(W.draft.traitChoices)
        end,
    },
    size = Field({
        type = "select", order = 2, name = "Size",
        hidden = function()
            local species = R.SPECIES[W.draft.species]
            return not species or #species.sizes < 2
        end,
        values = function()
            local values = {}
            for _, size in ipairs(R.SPECIES[W.draft.species].sizes) do values[size] = R.SIZE_NAMES[size] end
            return values
        end,
    }, "size"),
    lineage = Field({
        type = "select", order = 2.5, name = "Lineage",
        hidden = function() return not R.LINEAGES[W.draft.species] end,
        values = function()
            local values = {}
            for _, option in ipairs(R.LINEAGES[W.draft.species].options) do values[option.name] = option.name end
            return values
        end,
    }, "lineage"),
    -- The ability the spells of the species or lineage are cast with, chosen with it.
    lineageStat = Field({
        type = "select", order = 2.6,
        name = function() return "Ability for " .. ns.LineageStatUse(W.draft.species, W.draft.lineage) end,
        desc = function()
            if not ns.LineageCasts(W.draft.species, W.draft.lineage) then
                return ("Your lineage forces saving throws. Choose the ability its DC uses: %s. It stays with the lineage."):format(ns.LineageStatWords(W.draft.species, W.draft.lineage))
            end
            return "Your species or lineage gives you spells. Choose the ability you cast them with: Intelligence, Wisdom or Charisma. It stays with the lineage."
        end,
        hidden = function() return not ns.LineageAsks(W.draft.species, W.draft.lineage) end,
        values = function() return ns.LineageStatValues(W.draft.species, W.draft.lineage) end,
        sorting = function() return ns.LineageStats(W.draft.species, W.draft.lineage) end,
    }, "lineageStat"),
    background = {
        type = "select", order = 3, name = "Background",
        values = Opt.NameMap(R.BACKGROUNDS, R.BACKGROUND_ORDER), sorting = R.BACKGROUND_ORDER,
        get = function() return W.draft.background end,
        set = function(_, value)
            W.draft.background = value
            W.DropStaleGear() -- the old background's starting gear goes back
            -- The points belong to the old background's abilities; place them again.
            for _, stat in ipairs(R.STATS) do W.draft.bonus[stat] = 0 end
        end,
    },
    summary = { type = "description", order = 4, fontSize = "medium", name = OriginSummary, dialogControl = "RPSheetTermLabel" },
})

W.pages[2] = originPage
