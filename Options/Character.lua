-- "Character" tab: an overview with the two wizards (create a character, take or
-- undo a level) and the choices made at each level.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet = Opt.Sheet
local Levels = ns.Levels
local Summary = Opt.CharacterSummary -- Options/CharacterSummary.lua

local function NoCharacter() return RPSheet:ClassData() == nil end

local MIN_LEVEL = 1 -- the lowest level a character can go back to

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
            name = function() return Sheet().level <= MIN_LEVEL and ("Level " .. Sheet().level) or ("Back to level " .. (Sheet().level - 1)) end,
            desc = "Goes down one level. What that level gave is taken off the sheet again: its features, hit points, and the choice you made for it.",
            disabled = function() return Sheet().level <= MIN_LEVEL end,
            confirm = function()
                return ("Go back to level %d? Everything level %d gave is removed, including the choice you made for it."):format(Sheet().level - 1, Sheet().level)
            end,
            func = function()
                RPSheet:LevelDown()
                ns.RebuildOptions()
                Opt.Changed()
            end,
        },
        classChoices = {
            type = "execute", order = 3.3,
            name = function()
                local limit = ns.SheetManeuverLimit(Sheet())
                if limit > 0 then return ("Maneuvers (%d of %d)"):format(ns.ManeuversKnown(Sheet()), limit) end
                return "Class and feat choices"
            end,
            desc = "The choices your class, subclass and feats give you at this level, such as a Battle Master's maneuvers, a Fighting Style left empty or the spells of Magic Initiate.",
            hidden = function()
                local sheet = Sheet()
                return NoCharacter() or (ns.SheetManeuverLimit(sheet) == 0 and #ns.SkillChoiceFeatures(sheet) == 0
                    and #ns.OptionFeatures(sheet) == 0 and not ns.HasPickList(sheet)
                    and ns.ExpertiseLimit(sheet) == 0 and ns.FeatSkillLimit(sheet) == 0 and not ns.HasFeatChoices(sheet)
                    and #ns.OpenStyleSlots(sheet) == 0)
            end,
            -- The dialog of the first class's latest level shows every class's choices.
            func = function()
                local sheet = Sheet()
                ns.OpenLevelDialog(ns.LevelSlot(sheet, sheet.class, ns.ClassLevel(sheet, sheet.class)))
            end,
        },
        choicesHeader = { type = "header", order = 14, name = "Level choices", hidden = NoCharacter },
        choicesHelp = {
            type = "description", order = 15,
            hidden = NoCharacter,
            name = function()
                for _, level in ipairs(ns.LevelSlots(Sheet())) do
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
    for _, level in ipairs(ns.LevelSlots(Sheet())) do
        if Levels.Kind(Sheet(), level) then
            args["levelChoice" .. level] = {
                type = "execute", order = 15 + level / 100, width = "double",
                name = function()
                    local sheet = Sheet()
                    local record = Levels.Record(sheet, level)
                    -- With several classes the level is one of a class: "Mage level 4".
                    local label = ns.IsMulticlass(sheet) and ns.SlotLabel(sheet, level) or ("Level %d"):format(level)
                    if not record or Levels.Problem(sheet, level, record) then
                        return ("%s%s: choose|r"):format(Opt.RED, label)
                    end
                    return ("%s: %s"):format(label, Levels.Describe(record))
                end,
                func = function() ns.OpenLevelDialog(level) end,
            }
        end
    end
end)
