-- Subclass features of the Evoker (Sorcerer). See SubclassFeatures.lua.
local _, ns = ...
local R = ns.Rules
local Kit = ns.FeatureKit
local AtLevel, Passive, Ability, Limited = Kit.AtLevel, Kit.Passive, Kit.Ability, Kit.Limited
local Spend, SwitchOn, Dice, Roll, Bonus = Kit.Spend, Kit.SwitchOn, Kit.Dice, Kit.Roll, Kit.Bonus
local F = R.SUBCLASS_FEATURES

-- An Evoker's always-prepared spells: the shared ones at each step, plus the set of
-- the specialization. They take the place of the usual draconic spells.
local EVOKER_ALL = { { 3, "Chromatic Orb, Dragon's Breath" }, { 5, "Fly" }, { 7, "Arcane Eye" }, { 9, "Summon Dragon" } }
local EVOKER_SET = {
    Augmentation = { "Ebon Might, Eruption", "Blistering Scales", "Upheaval", "Breath of Eons" },
    Devastation = { "Azure Strike, Scorching Ray", "Fireball", "Emberstorm", "Shattering Star" },
    Preservation = { "Dream Breath, Living Flame", "Emerald Blossom", "Time Dilation", "Dream Flight" },
}

F["Draconic Sorcery"] = {
    Passive(3, "Draconic Resilience", "Your maximum hit points increase by 1 for every Sorcerer level.", { Bonus("HP", 0, "LEVEL") }),
    Passive(3, "Draconic Scales", "Without armor your AC is 10 + Dexterity + Charisma modifiers. Switch this off while you wear armor.", { Bonus("AC", 0, "CHA") }),
    Passive(3, "Evoker Spells", function(level, sheet)
        local known = {}
        for index, step in ipairs(EVOKER_ALL) do
            if level >= step[1] then
                known[#known + 1] = step[2]
                if EVOKER_SET[sheet.spec] then known[#known + 1] = EVOKER_SET[sheet.spec][index] end
            end
        end
        return "Always prepared, and not counted against the number you can prepare: " .. table.concat(known, ", ")
            .. (EVOKER_SET[sheet.spec] and "." or ". Choosing a specialization adds its set of spells.")
            .. " They are on your spell list already."
    end, nil, { prepared = function(sheet)
        local steps = {}
        for index, step in ipairs(EVOKER_ALL) do
            local names = step[2]
            if EVOKER_SET[sheet.spec] then names = names .. ", " .. EVOKER_SET[sheet.spec][index] end
            steps[index] = { step[1], names }
        end
        return steps
    end }),
    Kit.Choice(6, "Elemental Affinity", "The damage type your draconic magic is attuned to. You resist it, and add your Charisma modifier to one damage roll of a spell that deals it.", {
        Kit.Option("Acid", "You resist acid damage, and add your Charisma modifier to one damage roll of a spell that deals acid damage.", { resist = { "acid" } }),
        Kit.Option("Cold", "You resist cold damage, and add your Charisma modifier to one damage roll of a spell that deals cold damage.", { resist = { "cold" } }),
        Kit.Option("Fire", "You resist fire damage, and add your Charisma modifier to one damage roll of a spell that deals fire damage.", { resist = { "fire" } }),
        Kit.Option("Lightning", "You resist lightning damage, and add your Charisma modifier to one damage roll of a spell that deals lightning damage.", { resist = { "lightning" } }),
        Kit.Option("Poison", "You resist poison damage, and add your Charisma modifier to one damage roll of a spell that deals poison damage.", { resist = { "poison" } }),
    }),
    Limited(14, "Dragon Wings", "Bonus action: wings give you a flying speed of 60 feet for an hour. Once per long rest; after that it costs 3 Sorcery Points, spent on their bar by hand.", 1),
    Limited(18, "Dragon Companion", "You can cast Summon Dragon without its material component and make it last a minute without concentration. Once per long rest you can cast it without a slot.", 1),
}
