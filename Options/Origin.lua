-- "Origin" tab: allegiance, lineage, languages and renown.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet = Opt.Sheet

---------------------------------------------------------------------------
-- Lineage
---------------------------------------------------------------------------
local function Lineages()
    return R.LINEAGES[Sheet().species]
end

local function LineageNames()
    local names = {}
    for _, option in ipairs(Lineages().options) do names[#names + 1] = option.name end
    return names
end

local function LineageInfo()
    local lineage = RPSheet:LineageData()
    if not lineage then return "Choose the lineage your character belongs to. It replaces the general lineage trait on the sheet.\n" end
    return ("%s%s|r: %s\n"):format(Opt.GOLD, lineage.name, lineage.desc)
end

-- The spells of the species or lineage: the ability they are cast with, and an elf's
-- cantrip (Sheet/LineageCasting.lua). Free here; the page says in red what is missing.
local function Casts()
    return ns.LineageCasts(Sheet().species, Sheet().lineage)
end

local function CastingInfo()
    local sheet, lines = Sheet(), {}
    if ns.LineageStatMissing(sheet) then
        lines[#lines + 1] = ("%sChoose the ability your %s spells are cast with. Until then the sheet uses the best of the three.|r"):format(Opt.RED, ns.LineageTrait(sheet.species))
    end
    if ns.LineageCantrip(sheet) and RPSheet:State().lineageCantripChanged then
        lines[#lines + 1] = ("%sYou exchanged the cantrip since your last long rest: the rules allow one exchange after each long rest.|r"):format(Opt.RED)
    end
    return #lines > 0 and (table.concat(lines, "\n") .. "\n") or ""
end

---------------------------------------------------------------------------
-- Languages: the common tongue plus two, or three for the unaffiliated, plus
-- any that features grant.
---------------------------------------------------------------------------
local function LanguageLimit()
    -- The usual number, the ones features and a faction's trainers bring, and any the
    -- player added by hand.
    return R.LANGUAGE_PICKS + 1 + Sheet().extraLanguages + (RPSheet:FeatureFlag("languages") or 0)
        + ns.RenownLanguageCount(Sheet())
end

local function LanguageInfo()
    local sheet = Sheet()
    local common = R.COMMON_LANGUAGE[sheet.allegiance]
    local rule = common
        and ("You speak %s, plus %d more of your choice."):format(common, R.LANGUAGE_PICKS)
        or ("Unaffiliated characters pick %d languages."):format(R.LANGUAGE_PICKS + 1)
    local known, limit = #RPSheet:Languages(), LanguageLimit()
    local color = known >= limit and Opt.GREEN or Opt.GOLD
    return ("%s Rare languages normally come from a feature.\nChosen: %s%d of %d|r. Untick one to pick another.\n"):format(rule, color, known, limit)
end

local function SetLanguage(_, language, value)
    local sheet = Sheet()
    if value and not sheet.languages[language] and #RPSheet:Languages() >= LanguageLimit() then
        RPSheet:Print(("You already know %d languages. Untick one first, or raise \"Extra languages\" if a feature grants more."):format(LanguageLimit()))
        return
    end
    sheet.languages[language] = value or nil
    Opt.Changed()
end

---------------------------------------------------------------------------
-- Renown: one row per faction the character has standing with
---------------------------------------------------------------------------
local adding = "" -- the faction picked in the "add" dropdown

local function UntrackedFactions()
    local names = {}
    for _, faction in ipairs(R.ALL_FACTIONS) do
        if Sheet().renown[faction] == nil then names[#names + 1] = faction end
    end
    return names
end

local function RenownRow(faction, order)
    local function Score() return Sheet().renown[faction] or 0 end
    local row = {
        type = "group", inline = true, order = order,
        -- The score that counts: the player's own and what the rules add to it.
        name = function()
            local counted, added = ns.RenownScore(Sheet(), faction)
            local tier = R.RenownTier(counted)
            return ("%s %s%d|r%s%s%s"):format(faction, Opt.GOLD, counted, tier ~= "" and (" - " .. tier) or "",
                #added > 0 and (" (%d of your own)"):format(Score()) or "",
                ns.RenownRival(Sheet(), faction) and (Opt.RED .. " - rival of another faction you stand with|r") or "")
        end,
        args = {
            score = {
                type = "range", order = 1, width = "double", min = 0, max = 100, softMax = 50, step = 1, name = "Renown",
                desc = "The score your DM gave you. What a stronghold or the other factions of your side add is counted on top by the sheet.",
                get = Score,
                set = function(_, value)
                    local before = Opt.RenownTiers()
                    Sheet().renown[faction] = value
                    Opt.RenownChanged(before) -- the perks follow the scores
                end,
            },
            remove = {
                type = "execute", order = 2, name = "Remove",
                func = function()
                    local before = Opt.RenownTiers()
                    Sheet().renown[faction] = nil
                    Sheet().renownReached[faction] = nil -- taken off the sheet: as if never known
                    if Sheet().stronghold == faction then Sheet().stronghold = "" end
                    ns.RebuildOptions()
                    Opt.RenownChanged(before)
                end,
            },
        },
    }
    -- Its trainers' teaching and its perks (Options/RenownPerks.lua).
    for key, option in pairs(Opt.RenownPerkArgs(faction)) do row.args[key] = option end
    return row
end

---------------------------------------------------------------------------
-- Species traits that ask for a choice
---------------------------------------------------------------------------
local function TraitPicker(name, order)
    return {
        type = "select", order = order,
        name = function() return name .. (R.TRAITS[name].choice == "FEAT" and " (origin feat)" or " (skill)") end,
        desc = function()
            if R.TRAITS[name].choice ~= "FEAT" then return ns.Glossary[name] end
            local lines = { ns.Glossary[name] or "" }
            for _, feat in ipairs(ns.TraitOptions(Sheet(), name, true)) do
                lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, feat, R.FEATS[feat].desc)
            end
            return table.concat(lines, "\n\n")
        end,
        hidden = function()
            for _, trait in ipairs(ns.TraitChoices(Sheet())) do
                if trait == name then return false end
            end
            return true
        end,
        values = function() return (Opt.ListMap(ns.TraitOptions(Sheet(), name, true), true)) end,
        sorting = function() return (select(2, Opt.ListMap(ns.TraitOptions(Sheet(), name, true), true))) end,
        get = function() return Sheet().traitChoices[name] or "" end,
        set = function(_, value)
            Sheet().traitChoices[name] = value ~= "" and value or nil
            Opt.Regrant()
        end,
    }
end

local args = {
    allegiance = {
        type = "select", order = 1, name = "Allegiance",
        desc = "Decides your common tongue and, for some species, which faction you start with renown in.",
        values = R.ALLEGIANCES, sorting = R.ALLEGIANCE_ORDER,
        get = function() return Sheet().allegiance end,
        set = function(_, value) Sheet().allegiance = value; Opt.Regrant() end,
    },
    lineage = {
        type = "select", order = 2, name = "Lineage",
        hidden = function() return not Lineages() end,
        values = function() return (Opt.ListMap(LineageNames(), true)) end,
        sorting = function() return (select(2, Opt.ListMap(LineageNames(), true))) end,
        get = function() return Sheet().lineage end,
        set = function(_, value) Sheet().lineage = value; Opt.Regrant() end,
    },
    lineageInfo = {
        type = "description", order = 3, fontSize = "medium", name = LineageInfo,
        hidden = function() return not Lineages() end,
    },

    lineageStat = {
        type = "select", order = 3.1, name = "Ability for its spells",
        desc = "The ability your species' or lineage's spells and cantrips are cast with: Intelligence, Wisdom or Charisma, chosen with the lineage.",
        hidden = function() return not Casts() end,
        values = function()
            local values = ns.LineageStatValues()
            values[""] = "Not chosen"
            return values
        end,
        sorting = { "", "INT", "WIS", "CHA" },
        get = function() return ns.LineageStatChosen(Sheet()) or "" end,
        set = function(_, value) Sheet().lineageStat = value; Opt.Regrant() end,
    },
    lineageCantrip = {
        type = "select", order = 3.2, name = "Lineage cantrip",
        desc = "You know Prestidigitation, and after each long rest you can exchange it for another Wizard cantrip.",
        hidden = function() return ns.LineageCantrip(Sheet()) == nil end,
        values = function()
            local values = {}
            for _, name in ipairs(ns.LineageCantripChoices(Sheet())) do values[name] = name end
            return values
        end,
        sorting = function() return ns.LineageCantripChoices(Sheet()) end,
        get = function() return ns.LineageCantrip(Sheet()) end,
        set = function(_, value)
            if value ~= ns.LineageCantrip(Sheet()) then RPSheet:State().lineageCantripChanged = true end
            Sheet().lineageCantrip = value
            Opt.Regrant()
        end,
    },
    castingInfo = {
        type = "description", order = 3.3, fontSize = "medium", name = CastingInfo,
        hidden = function() return CastingInfo() == "" end,
    },

    traitSkillful = TraitPicker("Skillful", 4),
    traitKeenSenses = TraitPicker("Keen Senses", 4.1),
    traitVersatile = TraitPicker("Versatile", 4.2),

    languageHeader = { type = "header", order = 10, name = "Languages" },
    languageInfo = { type = "description", order = 11, fontSize = "medium", name = LanguageInfo },
    extraLanguages = Opt.With({
        type = "range", order = 12, min = 0, max = 10, step = 1, name = "Extra languages",
        desc = "More languages from a source the sheet doesn't know about. Class features that grant languages are counted already.",
    }, Sheet, "extraLanguages"),
    languages = { type = "group", inline = true, order = 13, name = "Languages", args = {} },

    renownHeader = { type = "header", order = 20, name = "Renown" },
    renownInfo = {
        type = "description", order = 21,
        name = "Standing with a faction: Friendly at 3, Honored at 10, Revered at 25, Exalted at 50. Pick a faction and press Add, then set its score. "
            .. "Each faction has perks of its own; the sheet adds the ones it can work with and takes them off when the score drops.\n"
            .. "Your DM raises a score. Two rules the sheet counts by itself: a stronghold in a faction's lands adds 1 (tick it on that faction), and the faction your species starts with gains 1, 2, 3 and 5 for each other faction of your side that is Friendly, Honored, Revered and Exalted.\n",
    },
    renownRivals = {
        type = "description", order = 21.5,
        hidden = function() return not ns.RenownRival(Sheet()) end,
        name = function()
            local first, second = ns.RenownRival(Sheet())
            if not first then return "" end
            return ("%sYou have renown with both the %s and the %s. They are rivals: a character rises with only one of the two. Set one of them to 0 or remove it.|r\n"):format(Opt.RED, first, second)
        end,
    },
    addFaction = {
        type = "select", order = 22, name = "Faction",
        values = function() return (Opt.ListMap(UntrackedFactions())) end,
        sorting = UntrackedFactions,
        get = function() return adding end,
        set = function(_, value) adding = value end,
    },
    add = {
        type = "execute", order = 23, name = "Add faction",
        disabled = function() return adding == "" or Sheet().renown[adding] ~= nil end,
        func = function()
            Sheet().renown[adding] = 0
            adding = ""
            ns.RebuildOptions()
            Opt.Changed()
            -- Nothing to grant at 0; the perks follow once the score is set.
        end,
    },
}

-- One checkbox per language, so the unticked ones can grey out at the limit.
for index, language in ipairs(R.ALL_LANGUAGES) do
    args.languages.args["language" .. index] = {
        type = "toggle", order = index, width = 1.2, name = language,
        disabled = function()
            return not Sheet().languages[language] and #RPSheet:Languages() >= LanguageLimit()
        end,
        get = function() return Sheet().languages[language] or false end,
        set = function(info, value) SetLanguage(info, language, value) end,
    }
end

Opt.custom.origin = { type = "group", order = 7, name = "Lineage, languages, renown", args = args }

-- The renown rows follow the sheet, so they are rebuilt with the list tabs.
table.insert(Opt.rebuilders, function()
    for key in pairs(args) do
        if key:find("^renownRow") then args[key] = nil end
    end
    local order = 30
    for _, faction in ipairs(R.ALL_FACTIONS) do
        if Sheet().renown[faction] ~= nil then
            order = order + 1
            args["renownRow" .. order] = RenownRow(faction, order)
        end
    end
end)
