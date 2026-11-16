-- Fixes to what spells and blessings do on the sheet: a blessing's immunities, the
-- summaries of the 1st-level core spells, and spells that change the character while
-- they last.
dofile(ARG3 .. "/t-test-play-lib.lua")

Section("Blessing of Argent Fortitude", function()
    local sheet = Build("WARRIOR", "", 5)
    sheet.renown["Argent Dawn"] = 25
    ns.ApplyClassFeatures(sheet)
    local blessing = Passive("Blessing of Argent Fortitude")
    if not Check(blessing ~= nil, "Revered with the Argent Dawn gives the blessing") then return end
    local defenses = RPSheet:Defenses()
    Check(defenses.immune.poison ~= nil, "immune to poison damage")
    Check(defenses.conditionImmune.Poisoned ~= nil, "immune to being poisoned")
    sheet.renown["Argent Dawn"] = 10
    ns.ApplyClassFeatures(sheet)
    Check(RPSheet:Defenses().immune.poison == nil, "below 25 renown the immunity goes with the blessing")
end)

Section("1st-level summaries", function()
    for _, name in ipairs({ "Alarm", "Animal Friendship", "Color Spray", "Comprehend Languages", "Create or Destroy Water",
        "Detect Evil and Good", "Detect Poison and Disease", "Disguise Self", "Expeditious Retreat", "Grease", "Identify",
        "Illusory Script", "Purify Food and Drink", "Silent Image", "Tenser's Floating Disk", "Unseen Servant" }) do
        local spell = R.SPELLS[name]
        Check(spell and R.SPELL_SUMMARIES[name] == spell.desc, name .. " shows its summary")
        Check(R.SPELL_FACT_LINES[name] ~= nil, name .. " keeps its line of facts for saved copies")
        Eq(R.FreshSpellSummary({ name = name, level = 1, desc = R.SPELL_FACT_LINES[name] }), spell.desc, name .. ": a saved copy is brought up to date")
    end
end)

local function Dice(from)
    local list = {}
    for i = (from or 0) + 1, #ROLLED do list[#list + 1] = ROLLED[i].sides end
    return table.concat(list, ",")
end

Section("what the target is: the casting asks", function()
    Build("PALADIN", "", 5)
    local smite = Learn("Divine Smite")
    local slot = Slot(1)
    local left = slot.get()
    RPSheet:CastSpell(smite)
    Check(MENU and MENU.title == "Divine Smite: what did you hit?", "Divine Smite asks what was hit")
    Eq(slot.get(), left, "nothing is spent before the answer")
    local at = #ROLLED
    Click(MENU, "A fiend or an undead")
    Eq(Dice(at), "8,8,8", "a fiend or undead: one die more")
    Eq(slot.get(), left - 1, "the slot is spent")
    Build("PRIEST", "", 5)
    local toll = Learn("Toll the Dead")
    RPSheet:CastSpell(toll)
    at = #ROLLED
    Click(MENU, "Yes: d12s")
    Eq(Dice(at), "12,12", "a wounded target at level 5: 2d12")
    local flame = Learn("Living Flame")
    RPSheet:CastSpell(flame)
    at = #ROLLED
    Click(MENU, "Healing Flames")
    Eq(Dice(at), "6,6", "Healing Flames: 2d6, no attack roll")
    Said("healing 2d6", "it is healing")
end)

Section("dice that add dice, dice told apart, five attacks", function()
    Build("EVOKER", "", 1, { base = { STR = 10, DEX = 10, CON = 14, INT = 10, WIS = 10, CHA = 16 } })
    local burst = Learn("Sorcerous Burst")
    local at = #ROLLED
    Rolls(15, 8, 8, 2)
    RPSheet:CastSpell(burst)
    Eq(Dice(at), "20,8,8,8", "an 8 adds a d8, and that 8 another")
    Said("2 more for dice at 8", "the extra dice are named")
    Build("WARLOCK", "", 5)
    local hand = Learn("Hand of Gul'dan")
    Rolls(1, 2, 3, 4)
    RPSheet:CastSpell(hand)
    Said("(fire 3, necrotic 7)", "fire and necrotic told apart")
    Build("MAGE", "", 9)
    local missile = Learn("Magic Missile")
    Rolls(1, 2, 3)
    RPSheet:CastSpell(missile)
    Said("(darts 2, 3, 4)", "each dart with its 1")
    local wind = Learn("Steel Wind Strike")
    Eq(RPSheet:SpellHits(wind), 5, "Steel Wind Strike attacks five times")
end)

Section("spells with something more on the casting", function()
    Build("MAGE", "", 9)
    local contact = Learn("Contact Other Plane")
    Check(RPSheet:SpellText(contact):find("your own INT save against DC 15", 1, true) ~= nil, "the row names your own save")
    RPSheet:State().hp = RPSheet:MaxHP()
    local at = #ROLLED
    Rolls(2, 3, 3, 3, 3, 3, 3)
    RPSheet:CastSpell(contact, nil, true)
    Eq(Dice(at), "20,6,6,6,6,6,6", "a failed save: 6d6 to you")
    Check(RPSheet:State().conditions.Incapacitated, "and incapacitated")
    Eq(HP(), RPSheet:MaxHP() - 18, "the damage is taken")
    Build("DRUID", "", 9)
    local wild = Tracker("Wild Shape")
    wild.set(0)
    local s4 = Slot(4)
    local four = s4.get()
    RPSheet:CastSpell(Learn("Innervate"))
    Eq(wild.get(), 1, "Innervate: a use of Wild Shape back")
    Click(MENU, "Yourself")
    Eq(Slot(4).get(), four + 1, "and a 4th-level slot")
    Build("MAGE", "", 9)
    RPSheet:State().hp = 1
    Rolls(1, 1, 1, 1, 2, 2, 2, 2)
    RPSheet:CastSpell(Learn("Bonestorm"))
    Eq(HP(), 9, "Bonestorm heals you by the 4d6")
end)

Section("temporary hit points from the menu", function()
    Build("DEMONHUNTER", "", 5)
    local soul = Learn("Consume Soul")
    RPSheet:State().tempHP = 0
    Rolls(4, 4, 4, 4)
    RPSheet:CastSpell(soul)
    RPSheet:CastSpell(soul, nil, true)
    Click(MENU, "You gain temporary hit points")
    Eq(RPSheet:State().tempHP, 8, "half of 16")
    Build("MAGE", "", 13)
    RPSheet:State().tempHP = 0
    local fortify = Learn("Power Word Fortify")
    RPSheet:CastSpell(fortify)
    RPSheet:CastSpell(fortify, nil, true)
    Click(MENU, "Your share: 40")
    Eq(RPSheet:State().tempHP, 40, "a third of the 120")
end)

Summary("t-test-play-spellfixes")
