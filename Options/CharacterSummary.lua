-- The text at the top of the "Character" tab: what the character is, and in red the
-- choices that are still waiting for the player.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet, With = Opt.Sheet, Opt.With
local Levels = ns.Levels

local function Summary()
    local sheet = Sheet()
    local lines = { Opt.GOLD .. (RPSheet:Summary() or "No class chosen yet") .. "|r" }
    local class, species = RPSheet:ClassData(), RPSheet:SpeciesData()
    local background = R.BACKGROUNDS[sheet.background]
    if class then
        lines[#lines + 1] = ("%s uses the %s class: %s d%d, %s %s."):format(
            class.name, class.base, ns.Term("Hit die", "hit die"), class.hitDie,
            ns.Term("Saving throw", "saving throws"), ns.Terms(class.saves, " and "))
        lines[#lines + 1] = "Training: " .. class.training .. "."
        if class.hero and sheet.level < R.HERO_START_LEVEL then
            lines[#lines + 1] = ("%sHero classes normally start at level %d or higher.|r"):format(Opt.RED, R.HERO_START_LEVEL)
        end
    end
    if species then
        lines[#lines + 1] = ("%s: speed %d ft%s. Traits: %s."):format(species.name, species.speed,
            species.darkvision and (", " .. ns.Term("Darkvision", "darkvision " .. species.darkvision .. " ft")) or "",
            ns.Terms(species.traits))
    end
    if background then
        lines[#lines + 1] = ("%s: raises %s; skills %s; %s %s."):format(
            background.name, ns.Terms(background.stats), ns.Terms(background.skills, " and "),
            ns.Term("Origin feat", "origin feat"), ns.Term(background.feat))
    end
    if ns.RenownRival(sheet) then
        lines[#lines + 1] = ("%sYou have renown with two rival factions, under Customize, Lineage, languages, renown.|r"):format(Opt.RED)
    end
    -- Choices that are waiting for the player
    for _, trait in ipairs(ns.OpenTraitChoices(sheet)) do
        lines[#lines + 1] = ("%s%s has a choice to make, under Customize, Lineage, languages, renown.|r"):format(Opt.RED, trait)
    end
    -- Each class with the feature picks its own.
    for _, slot in ipairs(ns.StyleSlots(sheet)) do
        if not R.FIGHTING_STYLES[slot.name] then
            lines[#lines + 1] = ("%sYou have a Fighting Style to choose, under Customize, %s.|r"):format(Opt.RED,
                slot.class == sheet.class and "Class and origin" or "More classes")
        end
    end
    -- Each class picks its subclass at its own level 3.
    for _, view in ipairs(ns.ClassViews(sheet)) do
        if class and view.level >= R.SUBCLASS_LEVEL and view.subclass == "" then
            if view.viewOf then
                lines[#lines + 1] = ("%sYour %s can choose a subclass from level %d of that class.|r"):format(Opt.RED, R.CLASSES[view.class].name, R.SUBCLASS_LEVEL)
            else
                lines[#lines + 1] = ("%sYou can choose a subclass from level %d.|r"):format(Opt.RED, R.SUBCLASS_LEVEL)
            end
        end
    end
    -- The classes taken after the first, and what the rules say about the mix.
    for _, key in ipairs(ns.ExtraClassKeys(sheet)) do
        local other = R.CLASSES[key]
        lines[#lines + 1] = ("%s (level %d) uses the %s class: %s d%d. As a later class it gave %s, and no saving throws."):format(
            other.name, ns.ClassLevel(sheet, key), other.base, ns.Term("Hit die", "hit die"), other.hitDie, ns.MulticlassGains(key))
    end
    for _, warning in ipairs(ns.MulticlassWarnings(sheet)) do
        lines[#lines + 1] = Opt.RED .. warning .. "|r"
    end
    if ns.OpenClassChoices(sheet) then
        -- The button is named after the maneuvers for a Battle Master (see classChoices below).
        lines[#lines + 1] = ("%sYour class or feats have choices to make: use \"%s\" below.|r"):format(Opt.RED,
            ns.SheetManeuverLimit(sheet) > 0 and "Maneuvers" or "Class and feat choices")
    end
    local pending = Levels.Pending(sheet)
    if #pending > 0 and ns.IsMulticlass(sheet) then
        local names = {}
        for _, slot in ipairs(pending) do names[#names + 1] = ns.SlotLabel(sheet, slot) end
        lines[#lines + 1] = ("%sA choice is waiting for %s. See Level choices below.|r"):format(Opt.RED, table.concat(names, ", "))
    elseif #pending > 0 then
        lines[#lines + 1] = ("%sA choice is waiting for level %s. See Level choices below.|r"):format(Opt.RED, table.concat(pending, ", "))
    end
    return table.concat(lines, "\n") .. "\n"
end

Opt.CharacterSummary = Summary
