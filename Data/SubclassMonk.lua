-- Subclass features of the Monk. See SubclassFeatures.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus
local F = R.SUBCLASS_FEATURES

F["Warrior of Mercy"] = {
    Passive(3, "Implements of Mercy", "Proficiency in Insight and Medicine and with the herbalism kit.", nil,
        { skills = { "Insight", "Medicine" }, tools = { "Herbalism Kit" } }),
    Ability(3, "Hand of Harm", "Once per turn when you hit with an unarmed strike: extra necrotic damage.",
        function(level) return { Spend("Focus Points"), Dice(1, Kit.MartialDie(level), "WIS") } end),
    Ability(3, "Hand of Healing", "Magic action: touch a creature to heal it. In place of a Flurry of Blows strike it costs nothing: use Hand of Healing: with Flurry.",
        function(level) return { Spend("Focus Points"), Dice(1, Kit.MartialDie(level), "WIS", "HEALING") } end),
    Ability(3, "Hand of Healing: with Flurry", "In place of one strike of your Flurry of Blows: the same healing, without spending focus.",
        function(level) return { Dice(1, Kit.MartialDie(level), "WIS", "HEALING") } end),
    Passive(6, "Physician's Touch", "Hand of Harm can also poison its target until the end of your next turn. Hand of Healing can also end one of blinded, deafened, paralyzed, poisoned or stunned."),
    Limited(11, "Flurry of Healing and Harm", "With Flurry of Blows, each strike can be a free Hand of Healing, and one damaging strike can use Hand of Harm without spending focus. Uses equal to your Wisdom modifier per long rest.",
        { stat = "WIS" }),
    Limited(17, "Hand of Ultimate Mercy", "Magic action: touch a creature that died within a day. It returns to life with hit points equal to the roll, and several conditions removed. Once per long rest.",
        1, { Spend("Focus Points", 5), Dice(4, 10, "WIS", "HEALING") }),
}
F["Warrior of Mystic Brews"] = {
    Passive(3, "Bonus Proficiencies", "Proficiency in Performance and with brewer's supplies.", nil,
        { skills = { "Performance" }, tools = { "Brewer's Supplies" } }),
    Passive(3, "Drunken Technique", "When you spend focus on Patient Defense, your speed rises by 10 feet for the turn and you can make one unarmed strike."),
    Passive(6, "Mystic Brew", function(level)
        return ("After a short or long rest with brewer's supplies you make one magical beverage, which only you can drink (1 minute). Its benefit lasts an hour, or 8 hours if you spend 1 Focus Point, or until you drink another. Brews: Cinnamon Dragon, Heavenly Spirit, Refreshing Dip%s. Switch on the brew you drank."):format(
            level >= 11 and ", Blue Lightning, Drunkard's Luck, Stumbling Monk" or "")
    end),
    Ability(6, "Cinnamon Dragon", function(_, sheet)
        return ("Brew. Magic action: toxic flames in a 30-foot cone. Fire damage and poisoned until the end of its next turn; half damage only on a successful Dexterity save, DC %d."):format(Kit.DC(sheet, "WIS"))
    end, function(level) return { Dice(4, Kit.MartialDie(level)) } end),
    Passive(6, "Heavenly Spirit", "Brew. Resistance to two of cold, necrotic, psychic and radiant damage, your choice: switching this on asks which two.", nil, true),
    Ability(6, "Refreshing Dip", "Brew. Whenever you regain hit points, spend a die from the pool to regain that much more. The pool is your Wisdom modifier plus half your level, and is full again with each new brew, so after every rest.",
        function(level) return { Spend("Refreshing Dip Dice"), Dice(1, Kit.MartialDie(level), "", "SELFHEAL") } end),
    Passive(6, "Tipsy Sway", "You can stand up from prone for 5 feet of movement."),
    Ability(6, "Redirect Attack", "Reaction when an enemy misses you with a melee attack: it hits another creature of your choice within 5 feet of you, other than the attacker.",
        { Spend("Focus Points") }),
    Passive(11, "Blue Lightning", "Brew. Whenever you take a reaction that isn't an opportunity attack or a spell, you can make one unarmed strike as part of it.", nil, true),
    Passive(11, "Drunkard's Luck", "Brew. You gain Heroic Inspiration, and can give it to yourself whenever you make a check or save without it.", nil, true),
    Passive(11, "Stumbling Monk", "Brew. After any bonus action other than Patient Defense you can also use Patient Defense.", nil, true),
    Passive(17, "Intoxicated Frenzy", function(_, sheet)
        return ("Right after Patient Defense you can move up to your speed, making an unarmed strike against each creature you pass (once each). A creature hit falls prone unless it passes a Dexterity save, DC %d."):format(Kit.DC(sheet, "WIS"))
    end),
    Passive(17, "Master Brewer", "One beverage can carry the effects of two different brews."),
}
F["Warrior of the Open Hand"] = {
    Passive(3, "Open Hand Technique", function(_, sheet)
        return ("When a Flurry of Blows strike hits you can add one effect: Addle (no opportunity attacks until its next turn), Push (Strength save or pushed 15 feet) or Topple (Dexterity save or prone). Save DC %d."):format(Kit.DC(sheet, "WIS"))
    end),
    Limited(6, "Wholeness of Body", "Bonus action: heal yourself by the roll. Uses equal to your Wisdom modifier per long rest.",
        { stat = "WIS" }, function(level) return { Dice(1, Kit.MartialDie(level), "WIS", "SELFHEAL") } end),
    Passive(11, "Fleet Step", "After any bonus action other than Step of the Wind you can also use Step of the Wind."),
    Ability(17, "Quivering Palm", function(_, sheet)
        return ("When you hit with an unarmed strike: set up lethal vibrations that last a number of days equal to your level. Later, as an action or in place of an attack, end them: the target takes the roll as force damage, half on a successful Constitution save, DC %d. This click sets them up and spends the focus; Quivering Palm: end rolls the damage."):format(Kit.DC(sheet, "WIS"))
    end, { Spend("Focus Points", 4) }),
    Ability(17, "Quivering Palm: end", function(_, sheet)
        return ("As an action, or in place of an attack: end the vibrations you set up. The target takes the roll as force damage, half on a successful Constitution save, DC %d."):format(Kit.DC(sheet, "WIS"))
    end, { Dice(10, 12) }),
}
