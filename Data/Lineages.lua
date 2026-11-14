-- Lineages: the choice some species make within their lineage trait.
-- Summaries are brief and in our own words. Spells gained at levels 3 and 5 can each
-- be cast once per long rest without a slot.
--   skills      skill proficiencies the lineage grants
--   darkvision  replaces the species' darkvision range
--   effects     passive effects (see Data/Effects.lua)
--   renown      subfaction the lineage starts with renown in (see Data/Factions.lua)
local _, ns = ...
local R = ns.Rules

local SPELLS = " Level 3: %s. Level 5: %s."

-- A Tauren lineage's save DC: 8 + proficiency + the Strength, Constitution or Wisdom
-- modifier. The rules let the player choose one; the sheet takes the highest.
local function TaurenDC(sheet)
    local Kit = ns.FeatureKit
    return 8 + Kit.Prof(sheet.level) + math.max(Kit.Mod(sheet, "STR"), Kit.Mod(sheet, "CON"), Kit.Mod(sheet, "WIS"))
end

R.LINEAGES = {
    ELF = {
        trait = "Elven Lineage",
        options = {
            { name = "Blood Elf", renown = "Silvermoon City",
              desc = "You know Prestidigitation and can swap it for another Wizard cantrip after a long rest." .. SPELLS:format("Detect Magic", "Arcane Vigor"), spells = { "Detect Magic", "Arcane Vigor" } },
            { name = "High Elf",
              desc = "You know Prestidigitation and can swap it for another Wizard cantrip after a long rest." .. SPELLS:format("Detect Magic", "Misty Step"), spells = { "Detect Magic", "Misty Step" } },
            { name = "Night Elf", renown = "Darnassus", skills = { "Stealth" },
              desc = "Proficiency in Stealth, and in dim light or darkness you can Hide as a bonus action." .. SPELLS:format("Longstrider", "Pass without Trace"), spells = { "Longstrider", "Pass without Trace" } },
            { name = "Nightborne", darkvision = 120,
              desc = "Darkvision out to 120 feet, and you know the Arcane Pulse cantrip." .. SPELLS:format("Faerie Fire", "Darkness"), spells = { "Faerie Fire", "Darkness" } },
            { name = "Void Elf", darkvision = 120,
              desc = "Darkvision out to 120 feet, and you know the Mind Sliver cantrip." .. SPELLS:format("Entropic Embrace", "Misty Step"), spells = { "Entropic Embrace", "Misty Step" } },
        },
    },
    DRAENEI = {
        trait = "Eredar Lineage",
        options = {
            { name = "Draenei", renown = "Exodar",
              desc = "Resistance to necrotic damage, and you know the Spare the Dying cantrip." .. SPELLS:format("Healing Word", "Prayer of Healing"), spells = { "Healing Word", "Prayer of Healing" } },
            { name = "Krokul",
              desc = "Resistance to poison damage, and you know the Poison Spray cantrip." .. SPELLS:format("Ray of Sickness", "Hold Person"), spells = { "Ray of Sickness", "Hold Person" } },
            { name = "Lightforged",
              desc = "Resistance to radiant damage, and you know the Sacred Flame cantrip." .. SPELLS:format("Guiding Bolt", "Aid"), spells = { "Guiding Bolt", "Aid" } },
            { name = "Man'ari",
              desc = "Resistance to fire damage, and you know the Fire Bolt cantrip." .. SPELLS:format("Hellish Rebuke", "Darkness"), spells = { "Hellish Rebuke", "Darkness" } },
        },
    },
    TAUREN = {
        trait = "Tauren Lineage",
        options = {
            { name = "Mulgore Tauren", renown = "Thunder Bluff",
              desc = "War stomp: in place of one attack, creatures of your choice within 5 feet make a Constitution save or are stunned until the end of your turn. Not while prone, flying, climbing or swimming.",
              detail = function(sheet) return ("Save DC %d."):format(TaurenDC(sheet)) end },
            { name = "Highmountain Tauren",
              desc = "Bull rush: as an action, move up to your speed through other creatures without provoking opportunity attacks. Medium or smaller creatures in your path make a Strength save or take damage and fall prone.",
              detail = function(sheet)
                  local Kit = ns.FeatureKit
                  return ("Save DC %d, %d damage (proficiency bonus plus Strength modifier), once per turn for each creature."):format(
                      TaurenDC(sheet), math.max(0, Kit.Prof(sheet.level) + Kit.Mod(sheet, "STR")))
              end },
            { name = "Taunka",
              desc = "A shaggy hide: +1 to Armor Class and resistance to cold damage.",
              effects = { { target = "AC", flat = 1, stat = "", times = 1 } } },
        },
    },
    TROLL = {
        trait = "Troll Lineage",
        options = {
            { name = "Amani Troll", desc = "Whenever you spend Heroic Inspiration you regain one spent hit die." },
            { name = "Darkspear Troll", renown = "Darkspear Tribe",
              desc = "When you Dash, ice, rubble, snow and undergrowth don't slow you for the rest of the turn." },
            { name = "Zandalari Troll", desc = "When you roll a 1 on a d20, you gain Heroic Inspiration at the end of the turn." },
        },
    },
}

-- The lineage table for a species and the chosen option, if any.
function R.Lineage(speciesKey, lineageName)
    local lineages = R.LINEAGES[speciesKey]
    if not lineages then return end
    for _, option in ipairs(lineages.options) do
        if option.name == lineageName then return lineages, option end
    end
    return lineages
end
