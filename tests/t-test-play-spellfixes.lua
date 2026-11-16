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

Summary("t-test-play-spellfixes")
