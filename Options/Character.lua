-- "Character" tab: class, level, subclass, species, background, alignment.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet, With = Opt.Sheet, Opt.With

-- Changing class, species or background hands out what they grant (saving throws,
-- skills, traits, origin feat). Nothing already on the sheet is removed.
local function Granting(option, key)
    option.get = function() return Sheet()[key] end
    option.set = function(_, value)
        local sheet = Sheet()
        sheet[key] = value
        if key == "class" then sheet.subclass, sheet.spec = "", "" end
        if key == "species" then sheet.lineage = "" end
        ns.ApplyGrants(sheet)
        ns.NormalizeState(RPSheet:State())
        ns.RebuildOptions()
        Opt.Changed()
    end
    return option
end

-- Dropdown of the current class's subclasses or specializations.
local function ClassList(option, field)
    option.values = function()
        local class = RPSheet:ClassData()
        return (Opt.ListMap(class and class[field], true))
    end
    option.sorting = function()
        local class = RPSheet:ClassData()
        return (select(2, Opt.ListMap(class and class[field], true)))
    end
    return option
end

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
    -- Choices that are waiting for the player
    if class and sheet.level >= R.SUBCLASS_LEVEL and sheet.subclass == "" then
        lines[#lines + 1] = ("%sYou can choose a subclass from level %d.|r"):format(Opt.RED, R.SUBCLASS_LEVEL)
    end
    local unspent = RPSheet:ImprovementPoints() - RPSheet:ImprovementSpent()
    if unspent > 0 then
        lines[#lines + 1] = ("%s%d ability score points from level-ups are unplaced. Place them on the Ability scores tab, or take a feat instead.|r"):format(Opt.RED, unspent)
    end
    if class and sheet.level >= R.EPIC_BOON_LEVEL then
        lines[#lines + 1] = ("From level %d you gain an Epic Boon feat. Add it on the Passives tab."):format(R.EPIC_BOON_LEVEL)
    end
    lines[#lines + 1] = "Changing class, species or background adds what they grant. It never removes anything already on the sheet."
    return table.concat(lines, "\n") .. "\n"
end

-- The subclass dropdown only knows the listed subclasses; a typed one shows as "None".
local function ListedSubclass()
    local class = RPSheet:ClassData()
    for _, name in ipairs(class and class.subclasses or {}) do
        if name == Sheet().subclass then return name end
    end
    return ""
end

local function SizeValues()
    local species, values = RPSheet:SpeciesData(), {}
    for _, size in ipairs(species and species.sizes or { "S", "M", "L" }) do
        values[size] = R.SIZE_NAMES[size]
    end
    return values
end

Opt.tabs.character = {
    type = "group", order = 2, name = "Character",
    args = {
        summary = { type = "description", order = 1, fontSize = "medium", name = Summary, dialogControl = "RPSheetTermLabel" },
        class = Granting({
            type = "select", order = 2, name = "Class", values = Opt.CLASS_VALUES, sorting = Opt.CLASS_ORDER,
        }, "class"),
        level = {
            type = "range", order = 3, min = 1, max = R.MAX_LEVEL, step = 1, name = "Level",
            desc = "Sets proficiency bonus, hit points, spell slots and class resources, and adds the class features you reach. What changed is listed in chat.",
            get = function() return Sheet().level end,
            set = function(_, value)
                RPSheet:SetLevel(value)
                ns.RebuildOptions()
                Opt.Changed()
            end,
        },
        break1 = { type = "description", order = 4, name = "" },
        subclass = ClassList({
            type = "select", order = 5, name = "Subclass",
            get = ListedSubclass,
            -- Picking a subclass hands out its features; changing it swaps them.
            set = function(_, value) Sheet().subclass = value; Opt.Regrant() end,
        }, "subclasses"),
        subclassText = {
            type = "input", order = 6, name = "Or type a subclass",
            desc = "For a subclass that isn't in the list. Its features aren't built in; add them on the Abilities and Passives tabs.",
            get = function() return Sheet().subclass end,
            set = function(_, value)
                Sheet().subclass = value:trim():gsub("[|\n\r]", "")
                Opt.Regrant()
            end,
        },
        spec = With(ClassList({
            type = "select", order = 7, name = "Specialization",
            desc = "A World of Warcraft specialization to guide your choices. It has no rules of its own.",
        }, "specs"), Sheet, "spec"),
        break2 = { type = "description", order = 8, name = "" },
        species = Granting({
            type = "select", order = 9, name = "Species", values = Opt.SPECIES_VALUES, sorting = Opt.SPECIES_ORDER,
        }, "species"),
        size = With({ type = "select", order = 10, name = "Size", values = SizeValues }, Sheet, "size"),
        background = Granting({
            type = "select", order = 11, name = "Background", values = Opt.BACKGROUND_VALUES, sorting = Opt.BACKGROUND_ORDER,
        }, "background"),
        alignment = With({
            type = "select", order = 12, name = "Alignment",
            values = Opt.ALIGNMENT_VALUES, sorting = Opt.ALIGNMENT_ORDER,
        }, Sheet, "alignment"),
        featuresHeader = { type = "header", order = 20, name = "Class features" },
        featuresHelp = {
            type = "description", order = 21,
            name = "Your class's and subclass's features are added as abilities and passives when you pick them or change level, and their dice and bonuses follow your level. Delete one you don't want and it stays gone. Changing subclass swaps its features.",
        },
        restore = {
            type = "execute", order = 22, width = "double",
            name = "Add missing class features",
            desc = "Adds the class features for your level, including any you deleted earlier, plus species traits and the background's skills and feat.",
            func = function()
                local sheet = Sheet()
                wipe(sheet.dismissed)
                ns.ApplyGrants(sheet)
                ns.NormalizeState(RPSheet:State())
                ns.RebuildOptions()
                Opt.Changed()
            end,
        },
    },
}
