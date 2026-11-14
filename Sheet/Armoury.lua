-- Basic weapons on a character (data in Data/Weapons.lua): which ones a class is
-- proficient with, making a sheet entry from one, and what its properties mean for
-- its dice and for Fighting Styles.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- True if the class is proficient with a basic weapon. The class's training reads
-- like "...; simple weapons and finesse or light martial weapons".
function ns.WeaponProficient(classKey, name)
    local class, weapon = R.CLASSES[classKey], R.WEAPONS[name]
    if not class or not weapon then return false end
    local text = (class.training:match(";(.*)$") or ""):lower()
    if weapon.category == "SIMPLE" then return text:find("simple") ~= nil end
    if text:find("light martial") then
        -- Only some martial weapons: light ones, and finesse ones where it says so.
        return weapon.props.L == true or (text:find("finesse") ~= nil and weapon.props.F == true)
    end
    return text:find("martial") ~= nil
end

-- Basic weapons a class is proficient with, in the usual order.
function ns.ProficientWeapons(classKey)
    local names = {}
    for _, name in ipairs(R.WEAPON_ORDER) do
        if ns.WeaponProficient(classKey, name) then names[#names + 1] = name end
    end
    return names
end

-- A sheet entry for a basic weapon. `modifier(stat)` gives the character's ability
-- modifiers, to pick the better of Strength and Dexterity for a finesse weapon.
-- `mastery` true also sets the weapon's mastery.
function ns.NewBasicWeapon(name, modifier, proficient, mastery)
    local data = R.WEAPONS[name]
    local stat = "STR"
    if data.props.F then
        stat = modifier("DEX") > modifier("STR") and "DEX" or "STR"
    elseif data.ranged then
        stat = "DEX"
    end
    local weapon = CopyTable(R.TEMPLATES.weapon)
    weapon.name, weapon.base, weapon.stat = name, name, stat
    weapon.dice, weapon.sides = data.dice[1], data.dice[2]
    weapon.proficient = proficient
    weapon.mastery = mastery and data.mastery or ""
    return weapon
end

-- The basic weapon behind a sheet entry, or nil for the player's own.
function ns.WeaponData(weapon)
    return R.WEAPONS[weapon.base]
end

-- The abilities a basic weapon can attack with, and why.
--   melee: Strength          ranged: Dexterity          finesse: either
--   a Monk's Martial Arts: either, for simple melee and light martial melee weapons,
--   without armor or a shield
-- No weapon adds two abilities at once; where there is a choice the higher one is used.
function ns.WeaponAbilities(data, sheet)
    if data.props.F then return { "STR", "DEX" }, "finesse" end
    if data.ranged then return { "DEX" }, "ranged" end
    local monkWeapon = data.category == "SIMPLE" or data.props.L
    if monkWeapon and sheet and ns.HasFeature(sheet, "Martial Arts") and ns.Unarmored(sheet) then return { "STR", "DEX" }, "Martial Arts" end
    return { "STR" }, "melee"
end

-- The ability a weapon attacks with. A basic weapon uses what its kind allows, the
-- higher one when there is a choice; the player's own weapons use the one set on them.
function RPSheet:WeaponStat(weapon)
    local data = ns.WeaponData(weapon)
    if not data then return weapon.stat end
    local best
    for _, stat in ipairs((ns.WeaponAbilities(data, self:Sheet()))) do
        if not best or self:Mod(stat) > self:Mod(best) then best = stat end
    end
    return best
end

-- Number and size of a weapon's damage dice. A versatile weapon held in two hands
-- uses its larger die.
function RPSheet:WeaponDice(weapon)
    local data = ns.WeaponData(weapon)
    local count, sides = weapon.dice, weapon.sides
    if data and data.versatile and weapon.twoHands then sides = data.versatile end
    -- Martial Arts: a monk weapon rolls the Martial Arts die when that is the larger one.
    local sheet = self:Sheet()
    if data and count == 1 and not data.ranged and (data.category == "SIMPLE" or data.props.L) and ns.HasFeature(sheet, "Martial Arts") and ns.Unarmored(sheet) then
        sides = math.max(sides, ns.FeatureKit.MartialDie(sheet.level))
    end
    return count, sides
end

-- "slashing damage" for a basic weapon, plain "damage" otherwise.
function ns.DamageWord(weapon)
    local data = ns.WeaponData(weapon)
    return data and (data.damage .. " damage") or "damage"
end

-- True if a Fighting Style's weapon bonus applies. A basic weapon is judged by its
-- properties; the player's own weapons by their "Fighting Style applies" tick box.
--   RANGED   ranged weapons           ONEHAND  melee, held in one hand
--   THROWN   weapons with Thrown      TWOHAND  melee, held in two hands
function ns.FitsStyle(weapon, style)
    local data = ns.WeaponData(weapon)
    if not data or not style.fit then return weapon.style == true end
    local twoHands = data.props["2H"] or (data.props.V and weapon.twoHands)
    if style.fit == "RANGED" then return data.ranged end
    if style.fit == "THROWN" then return data.props.T == true end
    if style.fit == "ONEHAND" then return not data.ranged and not twoHands end
    if style.fit == "TWOHAND" then return not data.ranged and twoHands == true end
    return false
end

-- Lines describing a basic weapon's properties, for a tooltip.
function ns.WeaponPropertyLines(weapon)
    local data, lines = ns.WeaponData(weapon), {}
    if not data then return lines end
    lines[#lines + 1] = ("%s weapon, %s."):format(data.category == "SIMPLE" and "Simple" or "Martial", R.WeaponSummary(data.name))
    local abilities, why = ns.WeaponAbilities(data, RPSheet:Sheet())
    if #abilities > 1 then
        lines[#lines + 1] = ("Attacks with %s, the higher of your Strength and Dexterity (%s)."):format(R.STAT_NAMES[RPSheet:WeaponStat(weapon)], why)
    else
        lines[#lines + 1] = ("Attacks with %s (%s weapon)."):format(R.STAT_NAMES[abilities[1]], why)
    end
    for _, prop in ipairs(R.WEAPON_PROPERTY_ORDER) do
        if data.props[prop] then
            lines[#lines + 1] = ("%s: %s"):format(R.WEAPON_PROPERTIES[prop].name, R.WEAPON_PROPERTIES[prop].desc)
        end
    end
    return lines
end
