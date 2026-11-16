-- The level dialog: its title and the text about what the level gives.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Util = ns.Util
local L = ns.LevelDialog
local args = L.args

function L.Gains()
    local sheet, class = L.Sheet(), L.DraftClass()
    -- The class's features come at its own level; the proficiency bonus follows the
    -- whole character's.
    local level, total, lines = L.draft.classLevel, L.Like().level, {}
    if L.draft.taking then
        local die = class and class.hitDie or R.DEFAULT_HIT_DIE
        lines[#lines + 1] = ("Maximum HP %s%s|r, and one more d%d Hit Die."):format(
            Opt.GREEN, Util.Signed(die / 2 + 1 + RPSheet:OwnMod("CON")), die)
        local before, after = math.ceil((total - 1) / 4) + 1, math.ceil(total / 4) + 1
        if after ~= before then
            lines[#lines + 1] = ("Proficiency bonus %s+%d|r."):format(Opt.GREEN, after)
        end
        if L.draft.newClass then
            lines[#lines + 1] = ("A class taken after your first gives less than it does at the start: %s. It gives no saving throw proficiencies."):format(
                ns.MulticlassGains(L.draft.class))
        end
    end
    -- Only what applies to this character, with the options picked here: a land
    -- beast's charge only for a beast of the land, a specialization's feature only
    -- for that specialization.
    local features = {}
    if L.draft.taking then
        local view = setmetatable({ featureOptions = L.draft.options }, { __index = ns.ClassView(L.Like(), L.draft.class) })
        features = ns.FeaturesGainedFor(view, level)
    end
    if L.draft.taking and #features > 0 then
        lines[#lines + 1] = ""
        for _, feature in ipairs(features) do
            -- Some descriptions follow the level.
            local desc = feature.desc
            if type(desc) == "function" then desc = desc(level, ns.ClassView(L.Like(), L.draft.class)) end
            lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, feature.name, desc)
        end
    end
    -- What the specialization suggests for this level.
    local spec = ns.ClassSpec(sheet, L.draft.class)
    local suggestions = R.SpecSuggestions(L.draft.class, spec, level)
    if #suggestions > 0 then
        lines[#lines + 1] = ("\n%sSuggested for %s|r: %s"):format(Opt.GOLD, spec, table.concat(suggestions, " "))
    end
    if L.draft.taking and class and class.cast then
        lines[#lines + 1] = "\nSpell slots and class resources that grow are listed in chat when you take the level."
    end
    return table.concat(lines, "\n") .. "\n"
end

args.title = {
    type = "description", order = 1, fontSize = "large",
    name = function()
        if not L.draft then return "" end
        local total = L.Like().level
        local text = L.draft.taking and ("Level %d to %d"):format(total - 1, total)
            or ("Your choice for %s"):format(ns.SlotLabel(L.Sheet(), L.draft.level))
        -- With several classes, or a new one, the class the level is taken in is named.
        if L.draft.taking and (L.draft.newClass or ns.IsMulticlass(L.Sheet())) then
            text = ("%s: %s level %d"):format(text, L.DraftClass().name, L.draft.classLevel)
        end
        return Opt.GOLD .. text .. "|r\n"
    end,
}
args.gains = {
    type = "description", order = 2, fontSize = "medium",
    name = function() return L.draft and L.Gains() or "" end,
}
