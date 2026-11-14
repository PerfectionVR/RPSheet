-- "Weapons" tab.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local With = Opt.With

-- True for a basic weapon from the armoury, whose dice and properties are fixed.
local function IsBasic(weapon)
    return ns.WeaponData(weapon) ~= nil
end

local function Build(weapon)
    local function self() return weapon end
    return {
        basic = {
            type = "description", order = 0.5, fontSize = "medium",
            hidden = function() return not IsBasic(weapon) end,
            name = function()
                if not IsBasic(weapon) then return "" end
                return table.concat(ns.WeaponPropertyLines(weapon), "\n") .. "\n"
            end,
        },
        name = With({ type = "input", order = 1, name = "Name" }, self, "name", true),
        stat = With({
            type = "select", order = 2, name = "Ability",
            desc = "Strength for most melee weapons, Dexterity for ranged and finesse weapons. A basic weapon works this out by itself.",
            hidden = function() return IsBasic(weapon) end,
            values = Opt.STAT_VALUES, sorting = R.STATS,
        }, self, "stat"),
        dice = With({
            type = "range", order = 3, min = 1, max = 10, step = 1, name = "Number of dice",
            hidden = function() return IsBasic(weapon) end,
        }, self, "dice"),
        sides = With({
            type = "select", order = 4, name = "Die", values = Opt.DIE_VALUES, sorting = Opt.DIE_ORDER,
            hidden = function() return IsBasic(weapon) end,
        }, self, "sides"),
        twoHands = With({
            type = "toggle", order = 4.5, name = "Held in two hands",
            desc = "A versatile weapon deals more damage in two hands, and then counts as two-handed for Fighting Styles.",
            hidden = function()
                local data = ns.WeaponData(weapon)
                return not (data and data.versatile)
            end,
        }, self, "twoHands"),
        custom = {
            type = "execute", order = 9, name = "Make it my own",
            desc = "Turns this into a weapon of your own, so its dice can be changed. It keeps its numbers but loses its properties.",
            hidden = function() return not IsBasic(weapon) end,
            func = function()
                local _, sides = RPSheet:WeaponDice(weapon)
                weapon.stat = RPSheet:WeaponStat(weapon) -- the ability it was using
                weapon.sides, weapon.base, weapon.twoHands = sides, "", false
                Opt.Changed()
            end,
        },
        proficient = With({
            type = "toggle", order = 5, name = "Proficient",
            desc = "Adds your proficiency bonus to the attack roll.",
        }, self, "proficient"),
        heal = With({
            type = "toggle", order = 6, name = "Healing, no attack roll",
            desc = "Rolls the dice as healing and skips the d20.",
        }, self, "heal"),
        style = With({
            type = "toggle", order = 7, name = "Fighting Style applies",
            desc = "Adds your Fighting Style's bonus to this weapon. Untick it for weapons the style doesn't cover, such as a melee weapon with Archery.",
            hidden = function() return IsBasic(weapon) or not RPSheet:StyleAffectsWeapons() end,
        }, self, "style"),
        mastery = With({
            type = "select", order = 8,
            name = function()
                local limit = RPSheet:MasteryLimit()
                local used = RPSheet:MasteriesUsed()
                if limit == 0 then return "Mastery" end
                return ("Mastery (%s%d of %d used|r)"):format(used > limit and Opt.RED or "", used, limit)
            end,
            desc = function()
                local lines = { "The mastery property of this kind of weapon. You need the Weapon Mastery feature. Your class allows the mastery of a set number of weapons; the count turns red when you go over it." }
                for _, name in ipairs(R.MASTERY_ORDER) do
                    if name ~= "" then lines[#lines + 1] = ("|cffffd100%s|r: %s"):format(name, R.MASTERIES[name].desc) end
                end
                return table.concat(lines, "\n\n")
            end,
            values = function()
                local values = { [""] = "None" }
                for _, name in ipairs(R.MASTERY_ORDER) do
                    if name ~= "" then values[name] = name end
                end
                return values
            end,
            sorting = R.MASTERY_ORDER,
        }, self, "mastery"),
    }
end

---------------------------------------------------------------------------
-- Adding a basic weapon from the armoury (Data/Weapons.lua)
---------------------------------------------------------------------------
local picked = "" -- the weapon chosen in the dropdown

local function Extra(args)
    args.armoury = {
        type = "select", order = 0.5, name = "Basic weapons", width = "double",
        desc = "Every simple and martial weapon with its damage, properties and mastery. Ones your class isn't proficient with are marked.",
        values = function()
            local class, values = Opt.Sheet().class, {}
            for _, name in ipairs(R.WEAPON_ORDER) do
                values[name] = ("%s - %s%s"):format(name, R.WeaponSummary(name),
                    ns.WeaponProficient(class, name) and "" or " |cffff5555(not proficient)|r")
            end
            return values
        end,
        sorting = R.WEAPON_ORDER,
        get = function() return picked end,
        set = function(_, value) picked = value end,
    }
    args.addBasic = {
        type = "execute", order = 0.6, name = "Add this weapon",
        disabled = function() return not R.WEAPONS[picked] end,
        func = function()
            local sheet = Opt.Sheet()
            local mastery = RPSheet:MasteriesUsed() < RPSheet:MasteryLimit()
            sheet.weapons[#sheet.weapons + 1] = ns.NewBasicWeapon(picked,
                function(stat) return RPSheet:Mod(stat) end, ns.WeaponProficient(sheet.class, picked), mastery)
            picked = ""
            ns.RebuildOptions()
            Opt.Changed()
        end,
    }
    args.breakBasic = { type = "description", order = 0.7, name = "" }
end

Opt.lists.weapons = {
    extra = Extra,
    order = 1, title = "Weapons", noun = "weapon", template = R.TEMPLATES.weapon, build = Build,
    help = "Pick a basic weapon from the list, or add an empty one and set it up yourself. Attack = d20 + ability modifier + proficiency bonus, then damage dice + ability modifier. A natural 20 doubles the dice. Right-click the weapon row on the sheet to swap weapons.\n",
}
