-- Subclass features of the Hunter (Ranger). See SubclassFeatures.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus
local AlwaysPrepared = ns.SubclassKit.AlwaysPrepared
local F = R.SUBCLASS_FEATURES

-- Marks a feature as there only while `test(sheet)` is true.
local function When(test, feature)
    feature.when = test
    return feature
end

-- True for a companion of that specialization: "C", "F" or "T" (see Data/Pets.lua).
local function PetSpec(spec)
    return function(sheet)
        local pet = R.Pet(sheet)
        return pet ~= nil and pet.spec == spec
    end
end

-- One option per pet family for the Primal Companion choice.
local function PetOptions()
    local options = {}
    for _, name in ipairs(R.PET_FAMILY_ORDER) do
        local pet = R.PET_FAMILIES[name]
        local block = R.PET_BLOCKS[pet.block]
        options[#options + 1] = Kit.Option(name, function(level, sheet)
            local text = ("Your companion is a %s: a %s %s. Speed %s. Its strike deals 1d%d + %d + your Wisdom modifier. Specialization: %s. Mastery: %s.%s"):format(
                name:lower(), block.size, block.name, block.speed, block.die, block.flat, R.PET_SPECS[pet.spec], pet.mastery,
                pet.unusual and " An unusual family: taming one takes a special ability." or "")
            if sheet and sheet.base then
                text = ("%s Armor Class %d, %d hit points."):format(text, 13 + Kit.Mod(sheet, "WIS"), R.PetHP({ featureOptions = { [R.PET_FEATURE] = name } }, level))
            end
            return text
        end)
    end
    return options
end

F["Path of the Berserker"] = {
    Ability(3, "Frenzy", "While raging, if you attacked recklessly: extra damage on the first target you hit this turn with a Strength-based attack, of the same type as the weapon.",
        function(level) return { Dice(Kit.RageDamage(level), 6) } end),
    Passive(6, "Mindless Rage", "While raging you can't be charmed or frightened, and entering a rage ends those conditions on you.", nil,
        { conditionImmune = { "Charmed", "Frightened" }, whileOn = "Raging" }),
    Passive(10, "Retaliation", "Reaction when a creature within 5 feet damages you: one melee attack against it with a weapon or an unarmed strike."),
    Limited(14, "Intimidating Presence", function(_, sheet)
        return ("Bonus action. Creatures you choose within 30 feet make a Wisdom save, DC %d, or are frightened for a minute; they repeat the save at the end of each of their turns. Once per long rest, or again by spending a Rage use."):format(Kit.DC(sheet, "STR"))
    end, 1),
}
F["War Domain"] = {
    AlwaysPrepared("War Domain", { { 3, "Guiding Bolt, Magic Weapon, Shield of Faith, Spiritual Weapon" }, { 5, "Crusader's Mantle, Spirit Guardians" }, { 7, "Fire Shield, Freedom of Movement" }, { 9, "Hold Monster, Steel Wind Strike" } }),
    Ability(3, "Guided Strike", "When you, or a creature within 30 feet, miss with an attack roll: add 10 to that roll. For another creature it takes your reaction.",
        { Spend("Channel Divinity") }),
    Limited(3, "War Priest", "Bonus action: one attack with a weapon or an unarmed strike; use your weapon row for it. Uses equal to your Wisdom modifier, all back on a short or long rest.",
        { stat = "WIS" }, nil, "ALL"),
    Ability(6, "War God's Blessing", "Cast Shield of Faith or Spiritual Weapon with a Channel Divinity use instead of a slot. It then needs no concentration and lasts a minute.",
        { Spend("Channel Divinity") }),
    Passive(17, "Avatar of Battle", "You have resistance to bludgeoning, piercing and slashing damage.", nil, { resist = R.WEAPON_DAMAGE }),
}
F["Beast Master"] = {
    Kit.Choice(3, R.PET_FEATURE, "You summon a primal beast of a pet family you choose; you can summon another after a long rest. It acts on your turn: it Dodges unless you spend a bonus action, or give up one of your attacks, to command it. If it dies you can bring it back with a spell slot.", PetOptions()),
    Ability(3, "Beast's Strike", function(level, sheet)
        local pet, block = R.Pet(sheet), R.PetBlock(sheet)
        return ("Your companion's attack, with your spell attack modifier.%s %s%s"):format(
            level >= 11 and " It strikes twice when commanded: click once for each." or "", block.strike,
            pet and (" If the family is one of your Weapon Mastery picks (set under Companion on the Actions tab of the sheet), the strike has %s and says so when it rolls."):format(pet.mastery) or "")
    end, function(_, sheet)
        local block = R.PetBlock(sheet)
        return { Roll("SPELL", "WIS"), Dice(1, block.die, "WIS", "DAMAGE", block.flat) }
    end),
    When(function(sheet) return R.PetBlock(sheet) == R.PET_BLOCKS.Land end,
        Ability(3, "Beast's Strike: charge", "Use this in place of Beast's Strike when a beast of the land moved 20 feet straight at the target: the whole strike is rolled with this much more damage, and a Large or smaller target is knocked prone.",
            { Dice(1, 6) })),
    Passive(6, "Pet Specialization: Cunning", "While your companion is within 60 feet, your speed and its speeds are 10 feet higher. Switch this off while it is farther away.",
        { Bonus("SPEED", 10) }, { when = PetSpec("C") }),
    When(PetSpec("C"), Limited(6, "Companion: Freedom of Movement", "Your companion uses its action to cast Freedom of Movement on itself and on you. Once per long rest.", 1)),
    When(PetSpec("F"), Ability(6, "Pet Specialization: Ferocity", "While your companion is within 60 feet: when it is Bloodied and hits with its strike, you and it each regain hit points equal to your Wisdom modifier. Clicking heals you; raise the Pet HP bar by the same amount.",
        { Dice(0, 4, "WIS", "SELFHEAL") })),
    When(PetSpec("F"), Limited(6, "Companion: Haste", "Your companion uses its action to cast Haste on itself and on you. Once per long rest.", 1)),
    Passive(6, "Pet Specialization: Tenacity", "While your companion is within 60 feet, your hit point maximum is higher by your Hunter level, and so is your companion's (its bar counts it already). Switch this off while it is farther away.",
        { Bonus("HP", 0, "LEVEL") }, { when = PetSpec("T") }),
    When(PetSpec("T"), Limited(6, "Companion: Stoneskin", "Your companion uses its action to cast Stoneskin on itself and on you. Once per long rest.", 1)),
    Passive(7, "Exceptional Training", "When you command your beast with a bonus action it can also Dash, Disengage, Dodge or Help as its own bonus action, and its attacks can deal force damage."),
    Passive(11, "Bestial Fury", "Your beast can strike twice when commanded. The first time each turn it hits the creature under your Hunter's Mark, it deals that spell's extra damage too."),
    Passive(15, "Share Spells", "A spell you cast on yourself can also affect your beast if it is within 30 feet."),
}
F["Hunter"] = {
    Passive(3, "Hunter's Lore", "You know the immunities, resistances and vulnerabilities of the creature marked by your Hunter's Mark."),
    Kit.Choice(3, "Hunter's Prey", "How you bring down your quarry. You can swap after a short or long rest.", {
        Kit.Option("Colossus Slayer", "Once per turn, extra damage when your weapon hits a creature that is missing hit points. Use the Colossus Slayer ability."),
        Kit.Option("Horde Breaker", "Once per turn, after attacking a creature, make another attack with the same weapon against a different creature within 5 feet of it."),
    }),
    Kit.For("Hunter's Prey", "Colossus Slayer", Ability(3, "Colossus Slayer", "Once per turn, extra damage when your weapon hits a creature that is missing hit points.",
        { Dice(1, 8) })),
    Kit.Choice(7, "Defensive Tactics", "How you guard yourself. You can swap after a short or long rest.", {
        Kit.Option("Escape the Horde", "Opportunity attacks have disadvantage against you."),
        Kit.Option("Multiattack Defense", "A creature that hits you has disadvantage on its other attacks against you this turn."),
    }),
    Passive(11, "Superior Hunter's Prey", "Once per turn, when you damage the creature under your Hunter's Mark, the spell's extra damage can also hit a different creature within 30 feet of it."),
    Passive(15, "Superior Hunter's Defense", "Reaction when you take damage: resistance to that damage, and any other of the same type, until the end of the turn."),
}
