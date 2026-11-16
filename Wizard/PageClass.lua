-- Wizard step 1: the class, its level, subclass, specialization, Fighting Styles and skills.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard
local GOLD, RED = Opt.GOLD, Opt.RED
local Field, Page, DraftClass = W.DraftField, W.Page, W.DraftClass
local skillArgs = W.classSkillArgs -- Wizard/PageClassSkills.lua

local function ClassSummary()
    local class = DraftClass()
    if not class then return "Choose the class you want to play. Each one builds on a core class, which sets your hit points, saving throws and skills.\n" end
    local lines = {
        ("%s%s|r uses the %s%s|r class."):format(GOLD, class.name, GOLD, class.base),
        ("%s d%d. %s: %s."):format(ns.Term("Hit die"), class.hitDie, ns.Term("Saving throw", "Saving throws"), ns.Terms(class.saves)),
        "Training: " .. class.training .. ".",
        ("Pick %d skills from: %s."):format(class.skillCount, ns.Terms(class.skills)),
    }
    if class.cast then
        lines[#lines + 1] = "Spellcasting ability: " .. ns.Term(R.STAT_NAMES[class.cast]) .. "."
    end
    if class.hero then
        lines[#lines + 1] = ("%s: %snormally starts at level %d or higher.|r"):format(ns.Term("Hero class"), RED, R.HERO_START_LEVEL)
    end
    lines[#lines + 1] = "|cff909090Hover a highlighted word for an explanation.|r"
    return table.concat(lines, "\n") .. "\n"
end

-- Dropdown of the chosen class's subclasses or specializations.
-- `minLevel` hides the choice until the character has that level in its first class.
local function ClassChoice(option, field, key, minLevel)
    option.hidden = function() return not DraftClass() or (minLevel ~= nil and W.FirstLevel() < minLevel) end
    option.values = function() return (Opt.ListMap(DraftClass()[field], true)) end
    option.sorting = function() return (select(2, Opt.ListMap(DraftClass()[field], true))) end
    return Field(option, key)
end

local classPage = Page(1, {
    class = {
        type = "select", order = 1, name = "Class",
        values = Opt.NameMap(R.CLASSES, R.CLASS_ORDER), sorting = R.CLASS_ORDER,
        get = function() return W.draft.class end,
        set = function(_, value)
            local draft = W.draft
            draft.class = value
            W.DropStaleGear() -- the old class's starting gear goes back (Wizard/StartingGear.lua)
            draft.subclass, draft.spec, draft.classSkills = "", "", {}
            draft.fightingStyle, draft.fightingStyle2 = "", "" -- the styles on offer differ by class
            W.DropExtra(value) -- it can't be one of the other classes as well
            -- A hero class is its subclass: the choice is fixed from the start.
            if R.CLASSES[value].hero then draft.subclass = R.CLASSES[value].subclasses[1] end
            if R.CLASSES[value].hero and draft.level < R.HERO_START_LEVEL then
                draft.level = R.HERO_START_LEVEL
            end
        end,
    },
    level = Field({
        type = "range", order = 2, min = 1, max = R.MAX_LEVEL, step = 1, name = "Level",
        desc = "A hero class normally starts at level 3 or higher; a lower level needs your DM's permission.",
    }, "level"),
    summary = { type = "description", order = 3, fontSize = "medium", name = ClassSummary, dialogControl = "RPSheetTermLabel" },
    subclass = ClassChoice({
        type = "select", order = 4, name = "Subclass",
        desc = "Every class chooses its subclass at level 3, so this appears from that level.",
    }, "subclasses", "subclass", R.SUBCLASS_LEVEL),
    subclassInfo = {
        type = "description", order = 4.1, fontSize = "medium",
        hidden = function() return not DraftClass() or W.FirstLevel() < R.SUBCLASS_LEVEL or (W.draft.subclass or "") == "" end,
        name = function() return ns.SubclassSummary(W.draft.subclass) end,
    },
    spec = (function()
        local option = ClassChoice({
            type = "select", order = 5, name = "Specialization",
            desc = "How you play your class. It has no rules of its own: it guides your choice of subclass, Fighting Style, weapons and spells, and the suggestions below follow it.",
        }, "specs", "spec")
        -- Picking one pre-selects what it suggests, where that is a single choice.
        option.set = function(_, value)
            local draft = W.draft
            draft.spec = value
            local guide = R.SpecGuide(draft.class, value)
            if guide then
                if guide.subclass then draft.subclass = guide.subclass end
                -- (not a style another of the character's classes has: it can be taken once)
                if guide.style and W.StyleOpen(draft.class, 1, guide.style) then draft.fightingStyle = guide.style end
            end
        end
        return option
    end)(),
    specGuide = {
        type = "description", order = 5.2, fontSize = "medium",
        hidden = function() return not W.draft or #R.SpecSuggestions(W.draft.class, W.draft.spec, W.FirstLevel(), 1) == 0 end,
        name = function()
            local draft = W.draft
            if not draft then return "" end
            local lines = R.SpecSuggestions(draft.class, draft.spec, W.FirstLevel(), 1)
            return ("%sSuggested for %s|r\n%s\n"):format(GOLD, draft.spec, table.concat(lines, "\n"))
        end,
    },
    -- The first class's own styles, where it has the feature by its level; a later
    -- class's are on its row (Wizard/Styles.lua).
    fightingStyle = W.StyleOption(5.5, 1, function() return W.draft end),
    fightingStyle2 = W.StyleOption(5.6, 2, function() return W.draft end),
    skills = {
        type = "group", inline = true, order = 6, args = skillArgs,
        -- The dialog asks for the name even while the option is hidden (no class chosen yet).
        name = function()
            local class = DraftClass()
            return ("Class skills (%d of %d picked)"):format(W.SkillsPicked(), class and class.skillCount or 0)
        end,
        hidden = function() return not DraftClass() end,
    },
})
W.AddMoreClassArgs(classPage.args) -- splitting the levels over more classes (Wizard/MoreClassesPage.lua)

W.pages[1] = classPage
