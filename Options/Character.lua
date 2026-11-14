-- "Character" tab: an overview with the two wizards (create a character, take or
-- undo a level) and the choices made at each level.
-- "Class and origin" page under Customize: class, subclass, species, background,
-- alignment, changed directly.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet, With = Opt.Sheet, Opt.With
local Levels = ns.Levels

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
    local pending = Levels.Pending(sheet)
    if #pending > 0 then
        lines[#lines + 1] = ("%sA choice is waiting for level %s. See Level choices below.|r"):format(Opt.RED, table.concat(pending, ", "))
    end
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

Opt.custom.identity = {
    type = "group", order = 6, name = "Class and origin",
    args = {
        intro = {
            type = "description", order = 1,
            name = "Changing class, species or background adds what they grant. It never removes anything already on the sheet. Level is changed on the Character tab.\n",
        },
        class = Granting({
            type = "select", order = 2, name = "Class", values = Opt.CLASS_VALUES, sorting = Opt.CLASS_ORDER,
        }, "class"),
        break1 = { type = "description", order = 4, name = "" },
        subclass = ClassList({
            type = "select", order = 5, name = "Subclass",
            get = ListedSubclass,
            -- Picking a subclass hands out its features; changing it swaps them.
            set = function(_, value) Sheet().subclass = value; Opt.Regrant() end,
        }, "subclasses"),
        subclassText = {
            type = "input", order = 6, name = "Or type a subclass",
            desc = "For a subclass that isn't in the list. Its features aren't built in; add them under Abilities and Passives.",
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
            name = "Your class's and subclass's features are added as abilities and passives as you reach their level, and taken off again if you go back down. Their dice and bonuses follow your level. Delete one you don't want and it stays gone. Changing subclass swaps its features.",
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

local function NoCharacter() return RPSheet:ClassData() == nil end

Opt.tabs.character = {
    type = "group", order = 1, name = "Character",
    args = {
        summary = { type = "description", order = 1, fontSize = "medium", name = Summary, dialogControl = "RPSheetTermLabel" },
        create = {
            type = "execute", order = 2, width = "double", name = "Create character",
            desc = "Opens the creation wizard: class, origin, ability scores, alignment and details.",
            hidden = function() return not NoCharacter() end,
            func = function() ns.OpenWizard() end,
        },
        levelUp = {
            hidden = NoCharacter,
            type = "execute", order = 3.1,
            name = function() return Sheet().level >= R.MAX_LEVEL and "Highest level" or ("Take level " .. (Sheet().level + 1)) end,
            desc = "Shows what the next level gives and asks for the choices that come with it.",
            disabled = function() return Sheet().level >= R.MAX_LEVEL end,
            func = function() ns.OpenLevelDialog() end,
        },
        levelDown = {
            hidden = NoCharacter,
            type = "execute", order = 3.2,
            name = function() return Sheet().level <= 1 and "Level 1" or ("Back to level " .. (Sheet().level - 1)) end,
            desc = "Goes down one level. What that level gave is taken off the sheet again: its features, hit points, and the choice you made for it.",
            disabled = function() return Sheet().level <= 1 end,
            confirm = function()
                return ("Go back to level %d? Everything level %d gave is removed, including the choice you made for it."):format(Sheet().level - 1, Sheet().level)
            end,
            func = function()
                RPSheet:LevelDown()
                ns.RebuildOptions()
                Opt.Changed()
            end,
        },
        choicesHeader = { type = "header", order = 14, name = "Level choices", hidden = NoCharacter },
        choicesHelp = {
            type = "description", order = 15,
            hidden = NoCharacter,
            name = function()
                for level = 1, Sheet().level do
                    if Levels.Kind(Sheet(), level) then
                        return "What you chose at the levels that offer an Ability Score Improvement, a feat or an Epic Boon. Click one to change it.\n"
                    end
                end
                return "Some levels offer an Ability Score Improvement, a feat or an Epic Boon. Your choices will be listed here.\n"
            end,
        },
        moreHeader = { type = "header", order = 30, name = "Changing the character" },
        moreHelp = {
            type = "description", order = 31,
            name = "Levels are taken and undone here. To change anything else directly (class, origin, scores, proficiencies, weapons, spells, abilities, passives), use the Customize tab. To begin again, start a new character.\n",
        },
        restart = {
            type = "execute", order = 32, name = "New character",
            desc = "Opens the creation wizard. Finishing it replaces this character; closing it changes nothing.",
            hidden = NoCharacter,
            func = function() ns.OpenWizard() end,
        },
    },
}

-- One button per level that comes with a choice, showing what was chosen.
table.insert(Opt.rebuilders, function()
    local args = Opt.tabs.character.args
    for key in pairs(args) do
        if key:find("^levelChoice") then args[key] = nil end
    end
    for level = 1, Sheet().level do
        if Levels.Kind(Sheet(), level) then
            args["levelChoice" .. level] = {
                type = "execute", order = 15 + level / 100, width = "double",
                name = function()
                    local sheet = Sheet()
                    local record = Levels.Record(sheet, level)
                    if not record or Levels.Problem(sheet, level, record) then
                        return ("%sLevel %d: choose|r"):format(Opt.RED, level)
                    end
                    return ("Level %d: %s"):format(level, Levels.Describe(record))
                end,
                func = function() ns.OpenLevelDialog(level) end,
            }
        end
    end
end)
