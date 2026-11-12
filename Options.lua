-- Settings and the in-game character editor (AceConfig). Open with /sheet config.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = LibStub("AceAddon-3.0"):GetAddon(ADDON)

local RED, GOLD, GREEN = "|cffff5555", "|cffffd100", "|cff80ff80"

local function Sheet() return RPSheet:Sheet() end
local function Changed() RPSheet:SheetChanged() end

-- Dropdown lists
local function NameList(source, order)
    local values = {}
    for _, key in ipairs(order) do values[key] = source[key].name end
    return values
end

local STAT_VALUES, STAT_OR_NONE, STAT_OR_NONE_ORDER = {}, { [""] = "None" }, { "" }
for _, stat in ipairs(R.STATS) do
    STAT_VALUES[stat] = R.STAT_NAMES[stat]
    STAT_OR_NONE[stat] = R.STAT_NAMES[stat]
    STAT_OR_NONE_ORDER[#STAT_OR_NONE_ORDER + 1] = stat
end

-- Adds get/set to an option for a plain field of the table returned by `source()`.
local function With(option, source, key, isText)
    option.get = function() return source()[key] end
    option.set = function(_, value)
        if isText then value = value:trim():gsub("[|\n\r]", "") end
        source()[key] = value
        Changed()
    end
    return option
end

---------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------
local general = {
    type = "group", order = 1, name = "General",
    args = {
        current = {
            type = "description", order = 1, fontSize = "medium",
            name = function()
                local profile = RPSheet:GetLinkedProfileName()
                local link = profile and ("Total RP 3 profile " .. GOLD .. profile .. "|r")
                    or ("this WoW character " .. GOLD .. "(Total RP 3 profile not found)|r")
                return ("Announcing as: %s%s|r\nThis sheet belongs to: %s\n"):format(GOLD, RPSheet:GetCharacterName(), link)
            end,
        },
        useTRP3 = {
            type = "toggle", order = 2, width = "full",
            name = "Use my Total RP 3 name",
            desc = "Use the first name from your Total RP 3 profile when it is available.",
            get = function() return RPSheet.db.profile.useTRP3 end,
            set = function(_, value) RPSheet.db.profile.useTRP3 = value; RPSheet:Refresh() end,
        },
        name = {
            type = "input", order = 3, width = "double",
            name = "Fallback name",
            desc = "Used when there is no Total RP 3 name. Leave empty to use your WoW character's name. Saved per character.",
            get = function() return RPSheet.db.char.name end,
            set = function(_, value) RPSheet.db.char.name = value:trim(); RPSheet:Refresh() end,
        },
        channel = {
            type = "select", order = 4,
            name = "Announce to",
            values = ns.CHANNEL_LABEL,
            get = function() return RPSheet.db.profile.channel end,
            set = function(_, value) RPSheet.db.profile.channel = value; RPSheet:Refresh() end,
        },
        tooltip = {
            type = "toggle", order = 5, width = "full",
            name = "Show stats in Total RP 3 tooltips",
            desc = "Adds a Stats section below the OOC block of Total RP 3 tooltips: your own, and other RP Sheet users'.",
            get = function() return RPSheet.db.profile.tooltip end,
            set = function(_, value) RPSheet.db.profile.tooltip = value end,
        },
        share = {
            type = "toggle", order = 6, width = "full",
            name = "Share my stats with other RP Sheet users",
            desc = "Sends your stats to your party or raid, and to RP Sheet users who hover or target you.",
            get = function() return RPSheet.db.profile.share end,
            set = function(_, value) RPSheet.db.profile.share = value; RPSheet:QueueBroadcast() end,
        },
        locked = {
            type = "toggle", order = 7, width = "full",
            name = "Lock the sheet window",
            desc = "The window can't be moved or resized, and clicks on its title bar, background and edges go through to the game. The rows stay clickable.",
            get = function() return RPSheet.db.profile.locked end,
            set = function() RPSheet:ToggleLock() end,
        },
        minimap = {
            type = "toggle", order = 8, width = "full",
            name = "Show minimap icon",
            get = function() return not RPSheet.db.profile.minimap.hide end,
            set = function(_, value)
                RPSheet.db.profile.minimap.hide = not value
                local icon = LibStub("LibDBIcon-1.0")
                if value then icon:Show(ADDON) else icon:Hide(ADDON) end
            end,
        },
        exampleHeader = { type = "header", order = 10, name = "Example" },
        example = {
            type = "execute", order = 11, width = "double",
            name = "Load example character (Laura)",
            desc = "Replaces this sheet with a finished example, to see how weapons, abilities and passives are set up.",
            confirm = true,
            confirmText = "Replace this sheet with the example?",
            func = function()
                local state = RPSheet:State()
                state.sheet = CopyTable(ns.ExampleCharacter)
                state.weapon, state.counter = 1, 0
                ns.RebuildOptions()
                Changed()
            end,
        },
    },
}

---------------------------------------------------------------------------
-- Stats (27 point buy + bonus points)
---------------------------------------------------------------------------
local stats = {
    type = "group", order = 2, name = "Stats",
    args = {
        summary = {
            type = "description", order = 1, fontSize = "medium",
            name = function()
                local lines = {
                    ("Points spent: %s%d / %d|r     Bonus points: %s%d / %d|r"):format(
                        GOLD, RPSheet:PointsSpent(), R.POINTS, GOLD, RPSheet:BonusSpent(), R.BONUS_TOTAL),
                    "Every stat starts at 8 and can be bought up to 15. Going to 14 or 15 costs 2 points per step, everything below costs 1.",
                    "Bonus points are added on top afterwards: +2 and +1, or +1 to three stats.",
                    "",
                }
                local totals = {}
                for _, stat in ipairs(R.STATS) do
                    local mod = RPSheet:Mod(stat)
                    totals[#totals + 1] = ("%s %s%d|r (%s%d)"):format(stat, GOLD, RPSheet:Score(stat), mod >= 0 and "+" or "", mod)
                end
                lines[#lines + 1] = table.concat(totals, "    ")
                return table.concat(lines, "\n") .. "\n"
            end,
        },
        reset = {
            type = "execute", order = 100, name = "Reset stats",
            desc = "Puts every stat back to 8 and removes the bonus points.",
            confirm = true,
            func = function()
                for _, stat in ipairs(R.STATS) do
                    Sheet().base[stat], Sheet().bonus[stat] = R.BASE_MIN, 0
                end
                Changed()
            end,
        },
    },
}

for i, stat in ipairs(R.STATS) do
    stats.args["base" .. stat] = {
        type = "range", order = i * 10, min = R.BASE_MIN, max = R.BASE_MAX, step = 1,
        name = R.STAT_NAMES[stat],
        desc = "Bought with points.",
        get = function() return Sheet().base[stat] end,
        set = function(_, value)
            local old = Sheet().base[stat]
            Sheet().base[stat] = value
            if RPSheet:PointsSpent() > R.POINTS then
                Sheet().base[stat] = old
                RPSheet:Print(("Not enough points for %s %d."):format(R.STAT_NAMES[stat], value))
                return
            end
            Changed()
        end,
    }
    stats.args["bonus" .. stat] = {
        type = "range", order = i * 10 + 1, min = 0, max = R.BONUS_MAX, step = 1,
        name = R.STAT_NAMES[stat] .. " bonus",
        desc = "Bonus points added after the point buy.",
        get = function() return Sheet().bonus[stat] end,
        set = function(_, value)
            local old = Sheet().bonus[stat]
            Sheet().bonus[stat] = value
            if RPSheet:BonusSpent() > R.BONUS_TOTAL then
                Sheet().bonus[stat] = old
                RPSheet:Print(("Only %d bonus points in total."):format(R.BONUS_TOTAL))
                return
            end
            Changed()
        end,
    }
    stats.args["break" .. stat] = { type = "description", order = i * 10 + 2, name = "" }
end

---------------------------------------------------------------------------
-- Health & Defense: size, armor, class resource, counter
---------------------------------------------------------------------------
local body = {
    type = "group", order = 3, name = "Health & Defense",
    args = {
        summary = {
            type = "description", order = 1, fontSize = "medium",
            name = function()
                local sheet = Sheet()
                local text = ("HP %s%d|r     AC %s%d|r     %s %s%d|r\n"):format(
                    GOLD, RPSheet:MaxHP(), GOLD, RPSheet:AC(), sheet.resourceName, GOLD, RPSheet:MaxResource())
                local minStr = R.ARMOR[sheet.armor].minStr
                if minStr and RPSheet:Score("STR") < minStr then
                    text = text .. ("%s%s armor needs at least %d Strength.|r\n"):format(RED, R.ARMOR[sheet.armor].name, minStr)
                end
                return text .. "These totals include your switched-on passives. Add bonuses on the Passives tab.\n"
            end,
        },
        size = With({
            type = "select", order = 2, name = "Race size",
            desc = "HP = 6 (small), 8 (medium) or 10 (large) + 2 x CON modifier.",
            values = NameList(R.SIZES, R.SIZE_ORDER), sorting = R.SIZE_ORDER,
        }, Sheet, "size"),
        armor = With({
            type = "select", order = 3, name = "Armor",
            desc = "AC = 5 (cloth), 6 (leather), 7 (mail) or 8 (plate) + DEX modifier.",
            values = NameList(R.ARMOR, R.ARMOR_ORDER), sorting = R.ARMOR_ORDER,
        }, Sheet, "armor"),
        shield = With({
            type = "select", order = 4, name = "Shield",
            desc = "+1 AC for a small shield, +2 for a large one.",
            values = NameList(R.SHIELDS, R.SHIELD_ORDER), sorting = R.SHIELD_ORDER,
        }, Sheet, "shield"),

        resourceHeader = { type = "header", order = 10, name = "Class resource" },
        resourceName = With({
            type = "input", order = 11, name = "Resource name",
            desc = "Mana, Energy, Rage, Runic Power...",
        }, Sheet, "resourceName", true),
        resourceStat = With({
            type = "select", order = 12, name = "Main class stat",
            desc = "Resource = main stat modifier x CON modifier x 2.",
            values = STAT_VALUES, sorting = R.STATS,
        }, Sheet, "resourceStat"),

        counterHeader = { type = "header", order = 20, name = "Custom counter (optional)" },
        counterHelp = {
            type = "description", order = 21,
            name = "A stack you track by hand, like Fatal Marks or combo points. Abilities can be set to be free when it is full.",
        },
        counterName = With({ type = "input", order = 22, name = "Counter name" }, Sheet, "counterName", true),
        counterMax = With({
            type = "range", order = 23, min = 0, max = 10, step = 1,
            name = "Counter maximum", desc = "0 hides the counter.",
        }, Sheet, "counterMax"),
    },
}

---------------------------------------------------------------------------
-- Weapons, abilities, passives: lists of any length.
-- Their option tables are rebuilt from the sheet whenever an entry is added or
-- removed, or another sheet becomes active (ns.RebuildOptions).
---------------------------------------------------------------------------
local function WeaponOptions(weapon)
    local function self() return weapon end
    return {
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        kind = With({
            type = "select", order = 2, name = "Type",
            values = NameList(R.WEAPON_KINDS, R.WEAPON_KIND_ORDER), sorting = R.WEAPON_KIND_ORDER,
        }, self, "kind"),
        stat = With({
            type = "select", order = 3, name = "Stat",
            desc = "Strength by default. Healing uses Intelligence, Wisdom or Charisma.",
            values = STAT_VALUES, sorting = R.STATS,
        }, self, "stat"),
        dice = With({
            type = "range", order = 4, min = 1, max = 6, step = 1, name = "Number of dice",
            hidden = function() return weapon.kind ~= "CUSTOM" end,
        }, self, "dice"),
        sides = With({
            type = "range", order = 5, min = 2, max = 20, step = 1, name = "Die size",
            desc = "3 for d3, 8 for d8...",
            hidden = function() return weapon.kind ~= "CUSTOM" end,
        }, self, "sides"),
    }
end

local function AbilityOptions(ability)
    local function self() return ability end
    return {
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        cost = With({
            type = "range", order = 2, min = 0, max = 20, step = 1, name = "Resource cost",
        }, self, "cost"),
        stat1 = With({
            type = "select", order = 3, name = "Roll d20 +",
            desc = "None = no d20 roll; the ability is only announced.",
            values = STAT_OR_NONE, sorting = STAT_OR_NONE_ORDER,
        }, self, "stat1"),
        stat2 = With({
            type = "select", order = 4, name = "+ second stat",
            values = STAT_OR_NONE, sorting = STAT_OR_NONE_ORDER,
        }, self, "stat2"),
        weaponDamage = With({
            type = "range", order = 5, min = 0, max = 4, step = 1, name = "Weapon dice multiplier",
            desc = "Also roll the equipped weapon's dice this many times, plus its stat modifier. 0 = no damage roll. An ability with a damage roll counts as an attack for passive bonuses.",
        }, self, "weaponDamage"),
        usesCounter = With({
            type = "toggle", order = 6, name = "Uses the counter",
            desc = "Free when your custom counter is full. Using the ability resets the counter to 0.",
        }, self, "usesCounter"),
        desc = With({
            type = "input", order = 7, width = "full", multiline = 3, name = "Description",
        }, self, "desc", true),
    }
end

local function PassiveOptions(passive)
    local function self() return passive end
    local args = {
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        enabled = With({
            type = "toggle", order = 2, name = "Switched on",
            desc = "Effects only count while the passive is on. You can also click the passive on the sheet, which is handy for stances and other temporary bonuses.",
        }, self, "enabled"),
        desc = With({
            type = "input", order = 3, width = "full", multiline = 3, name = "Description",
        }, self, "desc", true),
        effectsHeader = { type = "header", order = 10, name = "Effects" },
        effectsHelp = {
            type = "description", order = 11,
            name = "Each effect adds a flat number, a stat modifier, or both to one thing. A passive can have as many effects as you like, and effects from different passives add up.",
        },
        addEffect = {
            type = "execute", order = 1000, name = "Add effect",
            func = function()
                table.insert(passive.effects, CopyTable(R.TEMPLATES.effect))
                ns.RebuildOptions()
                Changed()
            end,
        },
    }
    for j, effect in ipairs(passive.effects) do
        local function this() return effect end
        args["effect" .. j] = {
            type = "group", inline = true, order = 20 + j,
            name = function() return GREEN .. RPSheet:EffectText(effect) .. "|r" end,
            args = {
                target = With({
                    type = "select", order = 1, name = "Adds to",
                    values = R.EFFECT_TARGETS, sorting = R.EFFECT_TARGET_ORDER,
                }, this, "target"),
                flat = With({
                    type = "range", order = 2, min = -10, max = 10, step = 1, name = "Flat amount",
                    desc = "A fixed bonus (or penalty), for example +3.",
                }, this, "flat"),
                stat = With({
                    type = "select", order = 3, name = "Plus modifier of",
                    desc = "Adds this stat's modifier, for example your Wisdom modifier.",
                    values = STAT_OR_NONE, sorting = STAT_OR_NONE_ORDER,
                }, this, "stat"),
                times = With({
                    type = "range", order = 4, min = 1, max = 3, step = 1, name = "Modifier counted",
                    desc = "How many times the stat modifier is added. 2 = twice the modifier.",
                    hidden = function() return effect.stat == "" end,
                }, this, "times"),
                remove = {
                    type = "execute", order = 5, name = "Remove effect",
                    func = function()
                        table.remove(passive.effects, j)
                        ns.RebuildOptions()
                        Changed()
                    end,
                },
            },
        }
    end
    return args
end

local LISTS = {
    {
        key = "weapons", order = 4, title = "Weapons", noun = "weapon", template = R.TEMPLATES.weapon, build = WeaponOptions,
        help = "Attack = d20 + stat modifier, then damage dice + the same modifier. Right-click the Attack row on the sheet to swap weapons.\n",
    },
    {
        key = "abilities", order = 5, title = "Abilities", noun = "ability", template = R.TEMPLATES.ability, build = AbilityOptions,
        help = "Active abilities. Clicking one on the sheet spends its cost, rolls, and announces it. The rules suggest 4; the number is up to you and your DM.\n",
    },
    {
        key = "passives", order = 6, title = "Passives", noun = "passive", template = R.TEMPLATES.passive, build = PassiveOptions,
        help = "Passives with working effects: bonuses to AC, HP, resource, attack, damage, healing or skills. The rules suggest 4; the number is up to you and your DM.\n",
    },
}

---------------------------------------------------------------------------
-- Appearance: theme presets plus every individual value (see Themes.lua)
---------------------------------------------------------------------------
local function Theme() return RPSheet.db.profile.theme end

-- Any manual change turns the current look into a custom one.
local function ThemeTouched()
    RPSheet.db.profile.themePreset = "CUSTOM"
    RPSheet:ApplyTheme()
end

local function ThemeColor(order, key, name, desc, hasAlpha)
    return {
        type = "color", order = order, name = name, desc = desc, hasAlpha = hasAlpha,
        get = function()
            local color = Theme()[key]
            return color[1], color[2], color[3], color[4]
        end,
        set = function(_, r, g, b, a)
            local color = Theme()[key]
            color[1], color[2], color[3], color[4] = r, g, b, hasAlpha and a or 1
            ThemeTouched()
        end,
    }
end

local function ThemeValue(option, key)
    option.get = function() return Theme()[key] end
    option.set = function(_, value)
        Theme()[key] = value
        ThemeTouched()
    end
    return option
end

local PRESET_VALUES, PRESET_ORDER = { CUSTOM = "Custom" }, {}
for _, key in ipairs(ns.THEME_ORDER) do
    PRESET_VALUES[key] = ns.Themes[key].name
    PRESET_ORDER[#PRESET_ORDER + 1] = key
end
PRESET_ORDER[#PRESET_ORDER + 1] = "CUSTOM"

local appearance = {
    type = "group", order = 7, name = "Appearance",
    args = {
        preset = {
            type = "select", order = 1, name = "Theme",
            desc = "Pick a ready-made look. You can change any colour, the font or the size afterwards.",
            values = PRESET_VALUES, sorting = PRESET_ORDER,
            get = function() return RPSheet.db.profile.themePreset end,
            set = function(_, key)
                if key ~= "CUSTOM" then RPSheet:LoadThemePreset(key) end
            end,
        },
        colorHeader = { type = "header", order = 10, name = "Colours" },
        bg = ThemeColor(11, "bg", "Background", "Window background. The opacity slider makes it see-through.", true),
        border = ThemeColor(12, "border", "Border", "The thin edge of the window. Set opacity to 0 to hide it.", true),
        accent = ThemeColor(13, "accent", "Accent", "Title, section headings and highlighted words."),
        text = ThemeColor(14, "text", "Text", "Normal text."),
        muted = ThemeColor(15, "muted", "Secondary text", "Modifiers, costs and switched-off passives."),
        highlight = ThemeColor(16, "highlight", "Row highlight", "Glow under the row your mouse is on.", true),

        barHP = ThemeColor(17, "barHP", "HP bar", "Fill colour of the HP bar.", true),
        barResource = ThemeColor(18, "barResource", "Resource bar", "Fill colour of the class resource bar (Energy, Mana...).", true),
        barCounter = ThemeColor(19, "barCounter", "Counter bar", "Fill colour of the custom counter bar.", true),

        textHeader = { type = "header", order = 20, name = "Text and size" },
        font = ThemeValue({
            type = "select", order = 21, name = "Font", values = ns.Fonts,
        }, "font"),
        fontSize = ThemeValue({
            type = "range", order = 22, min = 8, max = 18, step = 1, name = "Font size",
        }, "fontSize"),
        scale = ThemeValue({
            type = "range", order = 23, min = 0.6, max = 1.6, step = 0.05, name = "Window scale",
            desc = "Scales the whole window. Changing it can shift the window slightly.",
        }, "scale"),
        shadow = ThemeValue({
            type = "toggle", order = 24, name = "Text shadow",
            desc = "A dark outline behind the text. Best on dark or see-through backgrounds.",
        }, "shadow"),
    },
}

ns.options = {
    type = "group",
    name = "RP Sheet",
    childGroups = "tab",
    args = { general = general, stats = stats, body = body, appearance = appearance },
}
for _, list in ipairs(LISTS) do
    ns.options.args[list.key] = { type = "group", order = list.order, name = list.title, childGroups = "tree", args = {} }
end

function ns.RebuildOptions()
    for _, list in ipairs(LISTS) do
        local args = ns.options.args[list.key].args
        wipe(args)
        args.help = { type = "description", order = 0, name = list.help }
        args.add = {
            type = "execute", order = 1, name = "Add " .. list.noun,
            func = function()
                local entries = Sheet()[list.key]
                local entry = CopyTable(list.template)
                entry.name = ("New %s %d"):format(list.noun, #entries + 1)
                entries[#entries + 1] = entry
                ns.RebuildOptions()
                Changed()
            end,
        }
        for i, entry in ipairs(Sheet()[list.key]) do
            local item = {
                type = "group", order = i + 1,
                name = function() return entry.name ~= "" and entry.name or "(unnamed)" end,
                args = list.build(entry),
            }
            item.args.delete = {
                type = "execute", order = 2000, name = "Delete this " .. list.noun,
                confirm = true,
                func = function()
                    table.remove(Sheet()[list.key], i)
                    ns.RebuildOptions()
                    Changed()
                end,
            }
            args["item" .. i] = item
        end
    end
    LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON)
end
