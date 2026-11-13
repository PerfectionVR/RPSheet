-- "Proficiencies" tab: saving throws, skills, spellcasting ability.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Util = ns.Util
local Sheet = Opt.Sheet

local args = {
    summary = {
        type = "description", order = 1, fontSize = "medium",
        name = function()
            return ("Proficiency bonus %s%s|r at level %d. It is added to proficient saving throws, skills, weapon attacks and spells; expertise adds it twice.\n"):format(
                Opt.GOLD, Util.Signed(RPSheet:ProficiencyBonus()), RPSheet:Level())
        end,
    },
    savesHeader = { type = "header", order = 10, name = "Saving throws" },
    skillsHeader = { type = "header", order = 30, name = "Skills" },
    castHeader = { type = "header", order = 80, name = "Spellcasting" },
    castStat = Opt.With({
        type = "select", order = 81, name = "Spellcasting ability",
        desc = "None uses your class's spellcasting ability. Set one here for a subclass or feat that grants spells.",
        values = Opt.STAT_OR_NONE, sorting = Opt.STAT_OR_NONE_ORDER,
    }, Sheet, "castStat"),
}

for i, stat in ipairs(R.STATS) do
    args["save" .. stat] = {
        type = "toggle", order = 10 + i, name = R.STAT_NAMES[stat],
        desc = "Proficient in " .. R.STAT_NAMES[stat] .. " saving throws.\n\n" .. ns.Glossary["Saving throw"],
        get = function() return Sheet().saves[stat] or false end,
        set = function(_, value) Sheet().saves[stat] = value or nil; Opt.Changed() end,
    }
end

for i, skill in ipairs(R.SKILLS) do
    args["skill" .. i] = {
        type = "select", order = 30 + i, name = ("%s (%s)"):format(skill.name, skill.stat),
        desc = ns.Glossary[skill.name],
        values = R.PROFICIENCY_NAMES,
        get = function() return Sheet().skills[skill.name] or 0 end,
        set = function(_, value) Sheet().skills[skill.name] = value > 0 and value or nil; Opt.Changed() end,
    }
end

Opt.tabs.proficiencies = { type = "group", order = 4, name = "Proficiencies", args = args }
