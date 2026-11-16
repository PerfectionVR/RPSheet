-- The ability a species' or lineage's spells are cast with. The rules let the player
-- choose Intelligence, Wisdom or Charisma when the lineage is chosen (the species, for
-- one without lineages): sheet.lineageStat. The wizard and the level dialog ask for it
-- (Wizard/PageOrigin.lua, Options/LineageAbility.lua); Customize > Lineage, languages,
-- renown changes it freely. The spells themselves are in Sheet/LineageSpells.lua.
local _, ns = ...
local R = ns.Rules

-- What gives the spells: the chosen lineage's entry, or the species' own for one
-- without lineages (Gnome, Haranir). Nil when they give none (or no lineage is chosen).
function ns.LineageSource(speciesKey, lineageName)
    local lineages, option = R.Lineage(speciesKey, lineageName)
    local from = lineages and option or (not lineages and R.SPECIES[speciesKey or ""]) or nil
    if from and (from.cantrips or from.spells) then return from end
end

-- True when the species and lineage give spells, so the ability is to be chosen.
function ns.LineageCasts(speciesKey, lineageName)
    return ns.LineageSource(speciesKey, lineageName) ~= nil
end

-- The trait the spells come with, as the sheet calls it ("Elven Lineage").
function ns.LineageTrait(speciesKey)
    local lineages, species = R.LINEAGES[speciesKey or ""], R.SPECIES[speciesKey or ""]
    return lineages and lineages.trait or species and species.spellTrait or "Lineage"
end

-- The chosen ability, or nil when none (or one the rules don't offer) is set.
function ns.LineageStatChosen(sheet)
    for _, stat in ipairs(R.LINEAGE_STATS) do
        if sheet.lineageStat == stat then return stat end
    end
end

-- The ability the spells are cast with: the chosen one, or until one is chosen the
-- best of the three, so the numbers aren't worse than they will be.
function ns.LineageCastStat(sheet)
    local chosen = ns.LineageStatChosen(sheet)
    if chosen then return chosen end
    local best, score
    for _, stat in ipairs(R.LINEAGE_STATS) do
        local value = ns.FeatureKit.Score(sheet, stat)
        if not score or value > score then best, score = stat, value end
    end
    return best
end

-- The three abilities for a dropdown: { INT = "Intelligence", ... }.
function ns.LineageStatValues()
    local values = {}
    for _, stat in ipairs(R.LINEAGE_STATS) do values[stat] = R.STAT_NAMES[stat] end
    return values
end

-- True when the character's spells from its species want the ability chosen.
function ns.LineageStatMissing(sheet)
    return ns.LineageCasts(sheet.species, sheet.lineage) and not ns.LineageStatChosen(sheet)
end

-- The cantrip a lineage that lets it be exchanged after a long rest (an elf's
-- Prestidigitation, for another Wizard cantrip) has right now.
function ns.LineageCantrip(sheet)
    local from = ns.LineageSource(sheet.species, sheet.lineage)
    local swap = from and from.swap
    if not swap then return end
    local list = R.PICK_LISTS[R.CANTRIP_LISTS[swap.list] or ""]
    local name = sheet.lineageCantrip or ""
    if list and list.items[name] then return name end
    return swap.cantrip
end

-- The cantrips it can be exchanged for, in the list's order (Data/SpellPicks.lua).
function ns.LineageCantripChoices(sheet)
    local from = ns.LineageSource(sheet.species, sheet.lineage)
    local list = from and from.swap and R.PICK_LISTS[R.CANTRIP_LISTS[from.swap.list] or ""]
    return list and list.order or {}
end

-- A sentence for the lineage's text on the sheet: which ability its spells use, or
-- that one is still to be chosen. Empty for a lineage without spells.
function ns.LineageCastingText(sheet)
    if not ns.LineageCasts(sheet.species, sheet.lineage) then return "" end
    local chosen = ns.LineageStatChosen(sheet)
    if chosen then return (" Its spells are cast with %s."):format(R.STAT_NAMES[chosen]) end
    return " Choose the ability its spells are cast with under Customize, Lineage, languages, renown."
end
