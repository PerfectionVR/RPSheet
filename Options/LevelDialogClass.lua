-- The level dialog: the choices that come with the class: a subclass, the skill of a
-- class taken after the first, a Fighting Style, maneuvers, a feature's skill and the
-- features that offer options.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local L = ns.LevelDialog
local args = L.args

args.subclass = {
    type = "select", order = 10, name = "Subclass", width = "double",
    desc = "Its features are added to the sheet. A subclass that isn't listed can be typed under Customize afterwards.",
    hidden = function() return not L.draft or not L.AsksSubclass() end,
    values = function()
        local class = L.DraftClass()
        return (Opt.ListMap(class and class.subclasses, true))
    end,
    sorting = function()
        local class = L.DraftClass()
        return (select(2, Opt.ListMap(class and class.subclasses, true)))
    end,
    get = function() return L.draft.subclass end,
    set = function(_, value)
        L.draft.subclass = value
        L.DropUnfollowed() -- its always-prepared spells can't be picked as well
    end,
}
args.newClassSkill = {
    type = "select", order = 10.5, name = "Skill from your new class", width = "double",
    desc = "A class taken after your first gives one skill from its list, where it gives any. Skills you are proficient in are left out.",
    hidden = function() return #L.NewClassSkills() == 0 end,
    values = function() return (Opt.ListMap(L.NewClassSkills())) end,
    get = function() return L.draft.skill end,
    set = function(_, value) L.draft.skill = value end,
}

args.style = {
    type = "select", order = 11, name = "Fighting Style", width = "double",
    desc = function()
        local lines = {}
        for _, style in ipairs(R.FIGHTING_STYLE_ORDER) do
            lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, style, R.FIGHTING_STYLES[style].desc)
        end
        return table.concat(lines, "\n\n")
    end,
    hidden = function() return not L.StyleSlot() end,
    values = function() return (Opt.ListMap(ns.StyleChoices(ns.ClassView(L.Sheet(), L.draft.class), L.StyleSlot() or 1), true)) end,
    sorting = function() return (select(2, Opt.ListMap(ns.StyleChoices(ns.ClassView(L.Sheet(), L.draft.class), L.StyleSlot() or 1), true))) end,
    get = function() return L.draft.style end,
    set = function(_, value) L.draft.style = value end,
}

args.maneuvers = {
    type = "group", inline = true, order = 12, args = {},
    name = function()
        return ("Maneuvers (%d of %d chosen%s)"):format(L.draft and L.ManeuversPicked() or 0, L.ManeuverLimit(), L.ManeuverNote())
    end,
    hidden = function() return L.ManeuverLimit() == 0 end,
}
args.featureSkill = {
    type = "select", order = 13, width = "double",
    name = function() return (L.SkillFeatures()[1] or "Feature") .. " (skill)" end,
    desc = "A skill from your class's list that you aren't proficient in yet.",
    hidden = function() return #L.SkillFeatures() == 0 end,
    values = function()
        local like = setmetatable({ featureSkills = L.draft.featureSkills }, { __index = L.Like() })
        return (Opt.ListMap(ns.FeatureSkillOptions(like, L.SkillFeatures()[1])))
    end,
    get = function() return L.draft.featureSkills[L.SkillFeatures()[1]] end,
    set = function(_, value) L.draft.featureSkills[L.SkillFeatures()[1]] = value end,
}

-- One checkbox per maneuver. Once the number for the level is chosen the rest grey
-- out. A maneuver known before can be unticked to exchange it only where the rules
-- allow that (Options/LevelDialogManeuvers.lua).
for index, name in ipairs(R.MANEUVER_ORDER) do
    args.maneuvers.args["maneuver" .. index] = {
        type = "toggle", order = index, width = 1.5, name = name,
        desc = function()
            local maneuver = R.MANEUVERS[name]
            return maneuver.desc .. (maneuver.save and (" " .. R.STAT_NAMES[maneuver.save] .. " save.") or "")
        end,
        disabled = function()
            if L.draft.maneuvers[name] then return L.ManeuverLocked(name) end
            return L.ManeuversPicked() >= L.ManeuverLimit()
        end,
        get = function() return L.draft.maneuvers[name] or false end,
        set = function(_, value) L.draft.maneuvers[name] = value or nil end,
    }
end

-- A dropdown for each feature that offers options (four at most at one level).
for index = 1, 4 do
    local function Feature() return L.OptionFeatures()[index] end
    args["option" .. index] = {
        type = "select", order = 11 + index / 10, width = "double",
        name = function() return Feature() and Feature().name or "" end,
        desc = function()
            local feature, lines = Feature(), {}
            -- A long list (pet families) shows only the one picked.
            local options = feature and feature.options or {}
            local picked = feature and L.draft and L.draft.options[feature.name]
            for _, option in ipairs(options) do
                if #options <= 8 or option.name == picked then
                    local desc = option.desc
                    if type(desc) == "function" then desc = desc(L.Sheet().level, L.Sheet()) end -- some follow the level
                    lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, option.name, desc)
                end
            end
            if #lines == 0 then return "Pick one to read what it gives." end
            return table.concat(lines, "\n\n")
        end,
        hidden = function() return Feature() == nil end,
        values = function()
            local values = {}
            for _, option in ipairs(Feature() and Feature().options or {}) do values[option.name] = option.name end
            return values
        end,
        get = function() return Feature() and L.draft.options[Feature().name] end,
        set = function(_, value) L.draft.options[Feature().name] = value end,
    }
end
