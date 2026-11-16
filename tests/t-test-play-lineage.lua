-- The spells of a species or lineage (Sheet/LineageSpells.lua, LineageCasting.lua):
-- its cantrips are on the spell list from level 1 as always prepared and castable,
-- the spells of levels 3 and 5 too, each cast once per long rest without a slot; all
-- are cast with the ability chosen with the lineage, which the wizard and the level
-- dialog ask for and Customize changes freely. An elf's Prestidigitation can be
-- exchanged for another Wizard cantrip; a class cantrip of the same name makes way.
dofile(ARG3 .. "/t-test-play-lib.lua")

local SCORES = { STR = 10, DEX = 14, CON = 12, INT = 16, WIS = 12, CHA = 8 }
local function Lineage(class, level, species, lineage, stat, setup)
    return Build(class, "", level, { species = species, lineage = lineage, base = SCORES,
        setup = function(sheet) sheet.lineageStat = stat or ""; if setup then setup(sheet) end end })
end

Section("a lineage's cantrip and spells", function()
    Lineage("WARRIOR", 5, "DRAENEI", "Lightforged", "WIS")
    local flame = Spell("Sacred Flame")
    Check(flame and flame.free and flame.auto == "species:Sacred Flame", "the cantrip is on the spell list, not counting")
    Eq(RPSheet:CastStat(flame), "WIS", "cast with the chosen ability, not the class's")
    Eq(RPSheet:SpellDC(flame), 8 + RPSheet:ProficiencyBonus() + RPSheet:Mod("WIS"), "its save DC uses it")
    local sent = #SENT
    RPSheet:CastSpell(flame)
    Check(#SENT > sent, "a Warrior casts the cantrip")
    -- levels 3 and 5
    local bolt, aid = Spell("Guiding Bolt"), Spell("Aid")
    Check(bolt and aid and bolt.free and aid.free, "the level 3 and 5 spells are on the list, not counting")
    Check(not Ability("Guiding Bolt") and not Tracker("Guiding Bolt"), "they are no longer abilities with a bar")
    Eq(RPSheet:SpellAttack(bolt), RPSheet:ProficiencyBonus() + RPSheet:Mod("WIS"), "Guiding Bolt's attack uses the chosen ability")
    local how = RPSheet:ChosenCasting(bolt)
    Check(how and how.once and how.feature == "Eredar Lineage", "cast once without a slot")
    Rolls(15)
    RPSheet:CastSpell(bolt)
    FlushTimers()
    Check(RPSheet:State().spellUsed["Guiding Bolt"], "the free casting is spent")
    local before = #PRINTED
    sent = #SENT
    RPSheet:CastSpell(bolt)
    Check(#SENT == sent, "a Warrior without slots can't cast it again")
    RPSheet:LongRest()
    Check(not RPSheet:State().spellUsed["Guiding Bolt"], "a long rest brings it back")
    -- below level 3 only the cantrip
    Lineage("WARRIOR", 2, "DRAENEI", "Lightforged", "WIS")
    Check(Spell("Sacred Flame") and not Spell("Guiding Bolt"), "at level 2 only the cantrip")
    -- an old sheet's abilities make way
    local sheet = RPSheet:Sheet()
    sheet.level = 5
    table.insert(sheet.abilities, { name = "Guiding Bolt", auto = "lineagespell:Guiding Bolt", desc = "", actions = {} })
    ns.ApplyLineageSpells(sheet)
    Check(not Ability("Guiding Bolt") and Spell("Guiding Bolt"), "the ability an older version made becomes the spell")
end)

Section("the ability: chosen, missing, asked", function()
    Lineage("PRIEST", 1, "ELF", "Void Elf", "")
    local sliver = Spell("Mind Sliver")
    Check(sliver ~= nil, "a void elf knows Mind Sliver")
    Check(ns.LineageStatMissing(RPSheet:Sheet()), "the ability is missing")
    Eq(RPSheet:CastStat(sliver), "INT", "until chosen: the best of the three")
    RPSheet:Sheet().lineageStat = "CHA"
    Eq(RPSheet:CastStat(sliver), "CHA", "chosen: Charisma, even for a Priest")
    -- a lineage without spells asks nothing
    Lineage("WARRIOR", 1, "TAUREN", "Taunka", "")
    Check(not ns.LineageStatMissing(RPSheet:Sheet()), "a Taunka has no spells to cast")
    -- the wizard asks
    ns.OpenWizard(); FlushTimers()
    W.draft.step, W.draft.species, W.draft.lineage, W.draft.background = 2, "ELF", "Nightborne", R.BACKGROUND_ORDER[1]
    local problem = W.StepProblem()
    Check(problem and problem:find("ability your lineage's spells", 1, true), "the wizard asks for the ability: " .. tostring(problem))
    W.draft.lineageStat = "INT"
    problem = W.StepProblem()
    Check(not (problem or ""):find("lineage's spells", 1, true), "and is content once it is chosen")
    W.draft = nil
    -- the level dialog asks a character made before
    Lineage("WARRIOR", 3, "GNOME", "", "")
    Check(Spell("Mending") and Spell("Prestidigitation"), "a gnome knows Mending and Prestidigitation")
    ns.OpenLevelDialog(nil, false); FlushTimers()
    local L = ns.LevelDialog
    if Check(L.draft, "the level dialog opens") then
        problem = L.Problem()
        Check(problem and problem:find("lineage's spells", 1, true), "the level dialog asks for the ability: " .. tostring(problem))
        Check(not L.args.lineageStat.hidden(), "with a dropdown")
        L.args.lineageStat.set(nil, "WIS")
        Check(not (L.Problem() or ""):find("lineage's spells", 1, true), "and is content once it is chosen")
        L.args.confirm.func()
        FlushTimers()
        Eq(RPSheet:Sheet().lineageStat, "WIS", "the choice is kept")
        L.draft = nil
    end
    -- export and import keep it
    local sheet = RPSheet:DecodeSheet(RPSheet:ExportSheet())
    Eq(sheet and sheet.lineageStat, "WIS", "an exported sheet keeps the ability")
end)

Section("an elf's exchanged cantrip, and a class cantrip of the same name", function()
    Lineage("MAGE", 1, "ELF", "High Elf", "INT")
    local sheet = RPSheet:Sheet()
    Check(Spell("Prestidigitation") and Spell("Prestidigitation").auto == "species:Prestidigitation", "a high elf knows Prestidigitation")
    sheet.lineageCantrip = "Light"
    ns.ApplyGrants(sheet)
    Check(Spell("Light") and Spell("Light").auto == "species:Light" and not Spell("Prestidigitation"), "exchanged for Light")
    sheet.lineageCantrip = "Cure Wounds" -- not a Wizard cantrip
    ns.ApplyGrants(sheet)
    Check(Spell("Prestidigitation"), "something else than a Wizard cantrip falls back to Prestidigitation")
    -- a Mage who picked Fire Bolt as a Man'ari gets the pick back
    Lineage("MAGE", 1, "DRAENEI", "Man'ari", "INT", function(s) s.picks[R.CANTRIP_LISTS.Wizard] = { ["Fire Bolt"] = true } end)
    sheet = RPSheet:Sheet()
    Check(not sheet.picks[R.CANTRIP_LISTS.Wizard]["Fire Bolt"], "the class pick of Fire Bolt is freed")
    local count = 0
    for _, spell in ipairs(sheet.spells) do if spell.name == "Fire Bolt" then count = count + 1 end end
    Eq(count, 1, "Fire Bolt is on the list once")
    Check(Spell("Fire Bolt").free, "and doesn't count against the cantrips")
    -- Haranir: the species' own
    Lineage("WARRIOR", 3, "HARANIR", "", "WIS")
    Check(Spell("Druidcraft") and Spell("Thorn Whip") and Spell("Entangle"), "a haranir knows Druidcraft, Thorn Whip and Entangle")
    Check(RPSheet:ChosenCasting(Spell("Entangle")), "Entangle is cast once without a slot")
end)

Summary("t-test-play-lineage")
