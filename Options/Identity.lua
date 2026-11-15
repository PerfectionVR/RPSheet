-- "Class and origin" page under Customize: class, subclass, species, background,
-- alignment, changed directly.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet, With = Opt.Sheet, Opt.With
local Granting = Opt.IdentityPickers.Granting
local ClassList = Opt.IdentityPickers.ClassList
local StylePicker = Opt.IdentityPickers.StylePicker
local OptionPicker = Opt.IdentityPickers.OptionPicker

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
        subclassLater = {
            type = "description", order = 5,
            name = function() return ("%sBy the rules a subclass is chosen at level %d; its features start then.|r\n"):format(Opt.RED, R.SUBCLASS_LEVEL) end,
            -- (A hero class is its subclass from the start.)
            hidden = function()
                local class = RPSheet:ClassData()
                return ns.ClassLevel(Sheet(), Sheet().class) >= R.SUBCLASS_LEVEL or Sheet().subclass == "" or (class ~= nil and class.hero == true)
            end,
        },
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
        option1 = OptionPicker(1), option2 = OptionPicker(2), option3 = OptionPicker(3), option4 = OptionPicker(4),
        option5 = OptionPicker(5), option6 = OptionPicker(6),
        fightingStyle = StylePicker(1, 7.1, "Fighting Style"),
        fightingStyle2 = StylePicker(2, 7.2, "Second Fighting Style"),
        spec = ClassList({
            type = "select", order = 7, name = "Specialization",
            desc = "Your World of Warcraft specialization. It guides your choice of subclass, spells and feats and has no rules of its own, except that a Death Knight's rune is its specialization. It is shown with your class.",
            get = function() return Sheet().spec end,
            -- Features that follow the specialization are refreshed.
            set = function(_, value) Sheet().spec = value; Opt.Regrant() end,
        }, "specs"),
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
