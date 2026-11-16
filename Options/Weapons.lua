-- "Weapons" tab.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local With = Opt.With

-- True for a basic weapon from the rules' list, whose dice and properties are fixed.
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
        ranged = With({
            type = "toggle", order = 4.6, name = "Ranged weapon",
            desc = "Tick for a bow, a gun or the like; leave it for a melee weapon. Some spells need a melee weapon as a component.",
            hidden = function() return IsBasic(weapon) or weapon.heal end,
        }, self, "ranged"),
        worth = {
            type = "input", order = 4.7, width = 0.8, name = "Worth",
            desc = "What the weapon is worth, written like 5 gp 3 sp. A spell that needs a weapon as a component asks for one worth a few coins at least, so a weapon without a worth (claws, a bite) doesn't serve.",
            hidden = function() return IsBasic(weapon) or weapon.heal end,
            get = function() return (weapon.cost or 0) > 0 and ns.CoinText(weapon.cost) or "" end,
            set = function(_, value)
                weapon.cost = ns.ParseCoins(value) or 0
                Opt.Changed()
            end,
        },
        custom = {
            type = "execute", order = 9, name = "Make it my own",
            desc = "Turns this into a weapon of your own, so its dice can be changed. It keeps its numbers but loses its properties.",
            hidden = function() return not IsBasic(weapon) end,
            func = function()
                local _, sides = RPSheet:WeaponDice(weapon)
                weapon.stat = RPSheet:WeaponStat(weapon) -- the ability it was using
                -- It stays the kind of weapon it was, worth what that one costs.
                local data, listed = ns.WeaponData(weapon), R.ITEMS[weapon.base]
                weapon.ranged = data ~= nil and data.ranged == true
                if (weapon.cost or 0) == 0 then weapon.cost = listed and listed.cost or 0 end
                weapon.sides, weapon.base, weapon.twoHands = sides, "", false
                Opt.Changed()
            end,
        },
        proficient = With({
            type = "toggle", order = 5, name = "Proficient",
            desc = "Adds your proficiency bonus to the attack roll.",
        }, self, "proficient"),
        magic = With({
            type = "range", order = 5.5, min = 0, max = 3, step = 1, name = "Magic bonus",
            desc = "A magic weapon adds this to attack and damage rolls made with it: 1, 2 or 3. It counts for this weapon only.",
            hidden = function() return weapon.heal end,
        }, self, "magic"),
        pact = {
            type = "toggle", order = 5.6, name = "Pact weapon",
            desc = "The weapon bonded by your Pact of the Blade: you are proficient with it, and it can attack with Charisma when that is your best. Tick one melee weapon.",
            hidden = function() return weapon.heal or not ns.HasPactBlade(RPSheet:Sheet()) end,
            get = function() return weapon.pact == true end,
            set = function(_, value)
                -- One bond at a time: ticking this weapon ends the bond with any other.
                for _, other in ipairs(RPSheet:Sheet().weapons) do other.pact = false end
                weapon.pact = value
                if value then weapon.proficient = true end
                Opt.Changed()
            end,
        },
        stowed = With({
            type = "toggle", order = 5.7, name = "Put away",
            desc = "A weapon that is put away is kept but isn't on the sheet. Equipping a basic weapon in your inventory readies it again.",
        }, self, "stowed"),
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
                return ("Mastery (%s%d of %d used|r)"):format((used > limit or RPSheet:MasteryOver()) and Opt.RED or "", used, limit)
            end,
            desc = function()
                local lines = { "The mastery property of this kind of weapon. You need the Weapon Mastery feature, or the Weapon Master feat for the one kind of weapon chosen for it. Your class allows the mastery of a set number of weapons, and the feat's pick is only for its own kind; the count turns red when you go over either." }
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
        store = Opt.StoreWeaponButton(weapon),
    }
end

---------------------------------------------------------------------------
-- Adding a basic weapon from the rules' list (Data/Weapons.lua). The player's own
-- armoury is added below it by Options/WeaponStore.lua.
---------------------------------------------------------------------------
local picked = "" -- the weapon chosen in the dropdown

local function Extra(args)
    args.basicList = {
        type = "select", order = 0.5, name = "Basic weapons", width = "double",
        desc = "Every simple and martial weapon with its damage, properties and mastery. Ones your class isn't proficient with are marked.",
        values = function()
            local sheet, values = Opt.Sheet(), {}
            for _, name in ipairs(R.WEAPON_ORDER) do
                values[name] = ("%s - %s%s"):format(name, R.WeaponSummary(name),
                    ns.SheetWeaponProficient(sheet, name) and "" or " |cffff5555(not proficient)|r")
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
            local mastery = RPSheet:MasteryRoom(picked)
            sheet.weapons[#sheet.weapons + 1] = ns.NewBasicWeapon(picked,
                function(stat) return RPSheet:Mod(stat) end, ns.SheetWeaponProficient(sheet, picked), mastery)
            picked = ""
            ns.RebuildOptions()
            Opt.Changed()
        end,
    }
    args.breakBasic = { type = "description", order = 0.7, name = "" }
    Opt.StoredWeaponPicker(args)
end

Opt.lists.weapons = {
    extra = Extra,
    order = 1, title = "Weapons", noun = "weapon", template = R.TEMPLATES.weapon, build = Build,
    help = "Pick a basic weapon from the list, take one from your armoury, or add an empty one and set it up yourself. Attack = d20 + ability modifier + proficiency bonus, then damage dice + ability modifier. A natural 20 doubles the dice. Right-click the weapon row on the sheet to swap weapons.\n",
}
