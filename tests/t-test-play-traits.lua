-- Species traits, invocations, Metamagic and renown perks the sheet applies by itself:
-- Bloodied Frenzy, Draconic Flight's flying speed, the Tauren lineage's chosen DC
-- ability, the troll lineages and Heroic Presence with Heroic Inspiration, the
-- mechagnome's two tools, the invocations' spells without a slot, Agonizing Blast,
-- the pact weapon, Empowered and Seeking Spell, Tushui Meditation and Gilneas'
-- skinning bonus.
dofile(ARG3 .. "/t-test-play-lib.lua")

Section("Bloodied Frenzy", function()
    Build("WARRIOR", "", 3, { species = "TROLL", lineage = "Darkspear Troll" })
    local state = RPSheet:State()
    state.hp = RPSheet:MaxHP()
    Eq(RPSheet:ResolveMode("attack", nil), nil, "at full hit points no advantage")
    state.hp = math.floor(RPSheet:MaxHP() / 2)
    Eq(RPSheet:ResolveMode("attack", nil), "ADV", "Bloodied: advantage on attack rolls")
    Eq(RPSheet:ResolveMode("spell attack", nil), "ADV", "spell attacks too")
    Eq(RPSheet:ResolveMode("STR check", nil), nil, "but not on checks")
    Build("WARRIOR", "", 3, { species = "HUMAN" })
    RPSheet:State().hp = 1
    Eq(RPSheet:ResolveMode("attack", nil), nil, "a human doesn't have it")
end)

Section("Draconic Flight", function()
    Build("WARRIOR", "", 5, { species = "DRACTHYR" })
    Eq(RPSheet:MoveSpeed("fly"), nil, "no flying speed before the trait is used")
    RPSheet:UseAbility(Ability("Draconic Flight"))
    Eq(Tracker("Draconic Flight").get(), 0, "once per long rest")
    Eq(RPSheet:MoveSpeed("fly"), RPSheet:Speed(true), "a flying speed equal to the walking speed")
    RPSheet:ShortRest()
    Eq(RPSheet:MoveSpeed("fly"), nil, "a rest ends it")
end)

Section("the Tauren lineage's DC ability", function()
    local sheet = Build("WARRIOR", "", 3, { species = "TAUREN", lineage = "Mulgore Tauren",
        base = { STR = 16, DEX = 10, CON = 12, INT = 10, WIS = 14, CHA = 10 } })
    Check(ns.LineageStatMissing(sheet), "the ability is to be chosen")
    Eq(ns.LineageCastStat(sheet), "STR", "until then the best of Strength, Constitution and Wisdom")
    sheet.lineageStat = "WIS"
    ns.ApplyGrants(sheet)
    Check(not ns.LineageStatMissing(sheet), "chosen: Wisdom")
    local passive = Passive("Mulgore Tauren")
    Check(passive and passive.desc:find(("Save DC %d."):format(8 + RPSheet:ProficiencyBonus() + RPSheet:Mod("WIS")), 1, true), "the DC uses Wisdom: " .. tostring(passive and passive.desc))
    Check(passive.desc:find("Its save DC uses Wisdom", 1, true) ~= nil, "and says so")
    sheet.lineageStat = "INT"
    Check(ns.LineageStatMissing(sheet), "Intelligence isn't one of the three")
    -- the wizard asks
    ns.OpenWizard(); FlushTimers()
    local W = ns.Wizard
    W.draft.step, W.draft.species, W.draft.lineage, W.draft.background = 2, "TAUREN", "Highmountain Tauren", R.BACKGROUND_ORDER[1]
    W.draft.lineageStat = ""
    local problem = W.StepProblem()
    Check(problem and problem:find("save DC", 1, true), "the wizard asks for the DC's ability: " .. tostring(problem))
    W.draft.lineageStat = "CON"
    problem = W.StepProblem()
    Check(not (problem or ""):find("save DC", 1, true), "and is content once it is chosen")
    W.draft.lineage = "Taunka"
    W.draft.lineageStat = ""
    problem = W.StepProblem()
    Check(not (problem or ""):find("save DC", 1, true), "a Taunka has nothing to choose")
end)

Section("Heroic Inspiration: trolls and draenei", function()
    Build("WARRIOR", "", 3, { species = "TROLL", lineage = "Amani Troll" })
    local dice = Tracker("Hit Dice")
    dice.set(dice.max - 2)
    local state = RPSheet:State()
    state.inspiration = true
    RPSheet:ToggleInspiration()
    Check(not state.inspiration, "inspiration spent")
    Eq(Tracker("Hit Dice").get(), dice.max - 1, "an Amani troll regains a Hit Die")
    -- Zandalari: a natural 1
    Build("WARRIOR", "", 3, { species = "TROLL", lineage = "Zandalari Troll" })
    state = RPSheet:State()
    state.inspiration = false
    Rolls(1)
    RPSheet:RollCheck("STR check", 0, nil)
    Check(state.inspiration, "a Zandalari troll gains Heroic Inspiration on a 1")
    Build("WARRIOR", "", 3, { species = "TROLL", lineage = "Darkspear Troll" })
    RPSheet:State().inspiration = false
    Rolls(1)
    RPSheet:RollCheck("STR check", 0, nil)
    Check(not RPSheet:State().inspiration, "a Darkspear troll doesn't")
    -- Heroic Presence
    Build("WARRIOR", "", 3, { species = "DRAENEI", lineage = "Lightforged", setup = function(s) s.lineageStat = "WIS" end })
    state = RPSheet:State()
    state.inspiration = false
    RPSheet:CastSpell(Spell("Sacred Flame"))
    Check(state.inspiration, "casting a lineage spell gives Heroic Inspiration")
    Eq(Tracker("Heroic Presence").get(), 0, "and spends Heroic Presence")
    state.inspiration = false
    RPSheet:CastSpell(Spell("Sacred Flame"))
    Check(not state.inspiration, "only once per rest")
    RPSheet:ShortRest()
    RPSheet:CastSpell(Spell("Sacred Flame"))
    Check(state.inspiration, "a short rest brings it back")
end)

Section("Specialized Design", function()
    local sheet = Build("WARRIOR", "", 1, { species = "MECHAGNOME" })
    local open = ns.OpenTraitChoices(sheet)
    Eq(#open, 2, "two tools to choose")
    sheet.traitChoices["Specialized Design"] = "Tinker's Tools"
    local options = ns.TraitOptions(sheet, "Specialized Design 2")
    local has = false
    for _, name in ipairs(options) do has = has or name == "Tinker's Tools" end
    Check(not has, "the second pick leaves out the first")
    sheet.traitChoices["Specialized Design 2"] = "Brewer's Supplies"
    ns.ApplyGrants(sheet)
    Eq(RPSheet:ToolSource("Tinker's Tools"), "species", "proficient with the first tool")
    Eq(RPSheet:ToolSource("Brewer's Supplies"), "species", "and the second")
    Eq(#ns.OpenTraitChoices(sheet), 0, "nothing left to choose")
    local passive = Passive("Specialized Design")
    Check(passive and passive.desc:find("Tinker's Tools and Brewer's Supplies", 1, true), "the trait names both: " .. tostring(passive and passive.desc))
    sheet.species = "HUMAN"
    Eq(RPSheet:ToolSource("Tinker's Tools"), nil, "another species doesn't keep them")
end)

Section("invocations", function()
    local sheet = Build("WARLOCK", "", 5, { setup = function(s)
        s.picks.invocations = { ["Mask of Many Faces"] = true, ["Gift of the Depths"] = true, ["Fiendish Vigor"] = true, ["Pact of the Blade"] = true, ["Agonizing Blast"] = true }
    end })
    local disguise = Spell("Disguise Self")
    Check(disguise and disguise.auto == "invocation:Disguise Self" and disguise.free, "Disguise Self is on the list, not counting")
    Eq(RPSheet:CastStat(disguise), "CHA", "cast with Charisma")
    local slots = Slot(Slot(1) and 1 or 3)
    local before = slots and slots.get()
    RPSheet:CastSpell(disguise)
    RPSheet:CastSpell(disguise)
    Eq(slots and slots.get(), before, "Mask of Many Faces casts it without a slot, again and again")
    local breathing = Spell("Water Breathing")
    Check(breathing and RPSheet:ChosenCasting(breathing).once, "Water Breathing once per long rest")
    RPSheet:CastSpell(breathing)
    Check(RPSheet:State().spellUsed["Water Breathing"], "spent")
    RPSheet:LongRest()
    Check(not RPSheet:State().spellUsed["Water Breathing"], "back after a long rest")
    -- Fiendish Vigor: the highest number on each die
    RPSheet:State().tempHP = 0
    Rolls(1, 1)
    RPSheet:CastSpell(Spell("False Life"))
    Eq(RPSheet:State().tempHP, 8 + (RPSheet:SlotGrowth(Spell("False Life")).flat or 0), "False Life takes the highest numbers")
    -- Agonizing Blast on Eldritch Blast
    local blast = Learn("Eldritch Blast")
    ns.ApplyClassFeatures(sheet)
    Check(Spell("Eldritch Blast").addMod, "Agonizing Blast adds Charisma to Eldritch Blast")
    sheet.picks.invocations["Agonizing Blast"] = nil
    ns.ApplyClassFeatures(sheet)
    Check(not Spell("Eldritch Blast").addMod, "and stops when the invocation is exchanged")
    Check(blast ~= nil, "the cantrip was learned")
    -- the pact weapon
    sheet.base.CHA = 18
    sheet.base.STR = 10
    sheet.weapons[1] = ns.NewBasicWeapon("Longsword", function(stat) return RPSheet:Mod(stat) end, false, false)
    local sword = sheet.weapons[1]
    Eq(RPSheet:WeaponStat(sword), "STR", "an ordinary longsword uses Strength")
    sword.pact = true
    Eq(RPSheet:WeaponStat(sword), "CHA", "the pact weapon uses Charisma")
    sheet.picks.invocations["Pact of the Blade"] = nil
    Eq(RPSheet:WeaponStat(sword), "STR", "not without Pact of the Blade")
    -- Pact of the Chain: Find Familiar
    sheet.picks.invocations["Pact of the Chain"] = true
    ns.ApplyClassFeatures(sheet)
    Check(Spell("Find Familiar") and RPSheet:ChosenCasting(Spell("Find Familiar")), "Pact of the Chain: Find Familiar without a slot")
end)

Section("Lessons of the First Ones", function()
    local sheet = Build("WARLOCK", "", 5, { setup = function(s)
        s.picks.invocations = { ["Lessons of the First Ones"] = true, ["Lessons of the First Ones (second)"] = true }
    end })
    Eq(#ns.OpenLessons(sheet), 2, "two origin feats to choose")
    local options = ns.LessonOptions(sheet, "Lessons of the First Ones")
    local tough, alert = false, false
    for _, name in ipairs(options) do tough, alert = tough or name == "Tough", alert or name == "Alert" end
    Check(tough and alert, "origin feats are offered")
    local before = RPSheet:MaxHP()
    sheet.featureOptions["Lessons of the First Ones"] = "Tough"
    sheet.featureOptions["Lessons of the First Ones (second)"] = "Magic Initiate"
    ns.ApplyGrants(sheet)
    Check(Passive("Tough") and Passive("Tough").auto == "lessons:Lessons of the First Ones", "Tough is on the sheet from the invocation")
    Eq(RPSheet:MaxHP(), before + 2 * sheet.level, "and counts")
    Eq(#ns.OpenLessons(sheet), 0, "nothing left to choose")
    local magic = false
    for _, instance in ipairs(ns.FeatInstances(sheet)) do magic = magic or instance.id == "lessons:Lessons of the First Ones (second)" end
    Check(magic, "Magic Initiate's own choices are asked for like any feat's")
    options = ns.LessonOptions(sheet, "Lessons of the First Ones (second)")
    tough = false
    for _, name in ipairs(options) do tough = tough or name == "Tough" end
    Check(not tough, "a feat taken already isn't offered again")
    sheet.picks.invocations["Lessons of the First Ones"] = nil
    ns.ApplyGrants(sheet)
    Check(not Passive("Tough"), "exchanged, the invocation's feat goes")
end)

Section("Empowered and Seeking Spell", function()
    local sheet = Build("EVOKER", "", 5, { base = { STR = 8, DEX = 14, CON = 14, INT = 10, WIS = 10, CHA = 16 },
        setup = function(s) s.picks.metamagic = { ["Empowered Spell"] = true, ["Seeking Spell"] = true } end })
    local points = Tracker("Sorcery Points")
    local before = points and points.get()
    local sent = #SENT
    RPSheet:UseAbility(Ability("Empowered Spell"))
    Eq(#SENT, sent, "nothing to reroll before a spell: nothing happens")
    Eq(Tracker("Sorcery Points").get(), before, "and no point is spent")
    Learn("Fire Bolt")
    Rolls(15, 1, 8) -- (two d10 at level 5)
    RPSheet:CastSpell(Spell("Fire Bolt"), nil, nil, nil, {})
    Rolls(9)
    RPSheet:UseAbility(Ability("Empowered Spell"))
    Said("1 die rerolled", "Empowered Spell rerolls only the die below average")
    Said("= 17", "the new total")
    Eq(Tracker("Sorcery Points").get(), before - 1, "a Sorcery Point is spent")
    Rolls(17)
    RPSheet:UseAbility(Ability("Seeking Spell"))
    Said("Fire Bolt attack rerolled: 17", "Seeking Spell rerolls the attack")
    sent = #SENT
    RPSheet:UseAbility(Ability("Seeking Spell"))
    Eq(#SENT, sent, "only once for that attack")
    Check(sheet ~= nil, "built")
end)

Section("Tushui Meditation and Gilneas' skinning", function()
    local sheet = Build("WARRIOR", "", 3, { species = "PANDAREN", setup = function(s) s.renown = { Tushui = 10 } end })
    Check(Passive("Tushui Meditation"), "Honored with the Tushui: Tushui Meditation")
    RPSheet:State().inspiration = false
    RPSheet:ShortRest()
    Check(RPSheet:State().inspiration, "a short rest gives Heroic Inspiration")
    sheet = Build("WARRIOR", "", 3, { species = "WORGEN", setup = function(s) s.renown = { Gilneas = 10 } end })
    local with = RPSheet:GatherMod({ key = "skinning" })
    sheet.renown.Gilneas = 0
    ns.ApplyGrants(sheet)
    Eq(RPSheet:GatherMod({ key = "skinning" }), with - 2, "Honored with Gilneas: +2 to skin a creature")
end)

Summary("t-test-play-traits")
