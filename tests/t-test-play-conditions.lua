-- Death saves, conditions and exhaustion, the "Next roll" row, and saving throws
-- with the "what is it against" menu.
dofile(ARG3 .. "/t-test-play-lib.lua")

-- Runs fn and returns how many d20s it rolled.
local function D20s(fn)
    local before = #ROLLED
    fn()
    local count = 0
    for i = before + 1, #ROLLED do if ROLLED[i].sides == 20 then count = count + 1 end end
    return count
end
local function Give(fields)
    local passive = { name = fields.name or "Test passive", desc = "", auto = "test", enabled = true, effects = {} }
    for k, v in pairs(fields) do passive[k] = v end
    table.insert(RPSheet:Sheet().passives, passive)
    return passive
end
local function Skill(name)
    for _, skill in ipairs(R.SKILLS) do if skill.name == name then return skill end end
end

Section("death saves", function()
    Build("WARRIOR", "", 5)
    local state = RPSheet:State()
    Eq(D20s(function() RPSheet:RollDeathSave() end), 0, "no death save while up")
    state.hp = 0
    Check(RPSheet:IsDown(), "down at 0")
    Rolls(10); RPSheet:RollDeathSave()
    Eq(state.deathPass, 1, "10 passes")
    Said("rolls a death save: 10 (passed - 1 passed, 0 failed).", "pass line")
    Rolls(9); RPSheet:RollDeathSave()
    Eq(state.deathFail, 1, "9 fails")
    Rolls(1); RPSheet:RollDeathSave()
    Eq(state.deathFail, 3, "a natural 1 is two failures")
    Said("natural 1, two failures - 1 passed, 3 failed. Dead", "dead line")
    local before = #PRINTED
    Eq(D20s(function() RPSheet:RollDeathSave() end), 0, "the dead roll no more")
    Check(AnyPrinted("is dead", before), "says the character is dead")
    RPSheet:ClearDeathSaves()
    Rolls(15); RPSheet:RollDeathSave(); Rolls(15); RPSheet:RollDeathSave(); Rolls(15); RPSheet:RollDeathSave()
    Eq(state.deathPass, 3, "three passes")
    Said("Stable", "stable line")
    Eq(HP(), 0, "stable stays at 0")
    before = #PRINTED
    Eq(D20s(function() RPSheet:RollDeathSave() end), 0, "the stable roll no more")
    Check(AnyPrinted("stable", before), "says the character is stable")
    RPSheet:ClearDeathSaves()
    state.deathFail = 2
    Rolls(20); RPSheet:RollDeathSave()
    Eq(HP(), 1, "a natural 20: back with 1 HP")
    Eq(state.deathFail, 0, "saves cleared")
    Said("NATURAL 20! Back up with 1 HP", "nat 20 line")
    -- exhaustion weighs on it; a natural 20 doesn't care
    state.hp, state.exhaustion = 0, 1
    Rolls(11); RPSheet:RollDeathSave()
    Eq(state.deathFail, 1, "11 - 2 for exhaustion fails")
    Said("11 - 2 for exhaustion (failed", "exhaustion in the line")
    Rolls(12); RPSheet:RollDeathSave()
    Eq(state.deathPass, 1, "12 - 2 passes")
    Rolls(20); RPSheet:RollDeathSave()
    Eq(HP(), 1, "a natural 20 with exhaustion")
    state.exhaustion = 0
    -- Durable: advantage
    state.hp = 0
    Give({ name = "Durable" })
    Rolls(3, 14)
    Eq(D20s(function() RPSheet:RollDeathSave() end), 2, "Durable rolls two dice")
    Eq(state.deathPass, 1, "the higher one counts")
    table.remove(RPSheet:Sheet().passives)
    -- an undead companion
    local entry = RPSheet:AddMount("Undead companion")
    entry.called, entry.loyalty = true, 10
    Eq(D20s(function() RPSheet:RollDeathSave() end), 2, "a loyal undead companion gives advantage")
    entry.called = false
    Eq(D20s(function() RPSheet:RollDeathSave() end), 1, "not when it isn't out")
    -- the Next roll row is not a death save's to use up
    RPSheet:ClearDeathSaves()
    RPSheet.rollMode = "DIS"
    Eq(D20s(function() RPSheet:RollDeathSave() end), 1, "the Next roll row doesn't touch a death save")
    Eq(RPSheet.rollMode, "DIS", "and a death save doesn't use the row up")
    RPSheet.rollMode = nil

    -- Survivor: advantage, 18 and 19 count as 20
    Build("WARRIOR", "Champion", 18)
    state = RPSheet:State()
    Check(Passive("Survivor") ~= nil, "a level 18 Champion has Survivor")
    state.hp = 0
    Rolls(18, 2)
    Eq(D20s(function() RPSheet:RollDeathSave() end), 2, "Survivor rolls two dice")
    Eq(HP(), 1, "18 counts as a 20")
    Said("counts as a 20", "survivor line")
end)

Section("conditions and rolls", function()
    Build("WARRIOR", "", 5)
    local state = RPSheet:State()
    local on = state.conditions
    local function Only(...)
        for name in pairs(on) do on[name] = nil end
        for _, name in ipairs({ ... }) do on[name] = true end
    end
    local function Mode(label, mode) return RPSheet:ResolveMode(label, mode) end
    -- what each condition does to the kinds of roll: A attack, S spell attack, C check (a skill), I initiative, D DEX save
    local expect = {
        Blinded = { attack = "DIS" }, Charmed = {}, Deafened = {},
        Grappled = { attack = "DIS" }, -- unless the sheet is told it is against the grappler (t-test-play-questions.lua)
        Frightened = { attack = "DIS", check = "DIS", initiative = "DIS" },
        Incapacitated = { initiative = "DIS" },
        Invisible = { attack = "ADV", initiative = "ADV" },
        Paralyzed = { initiative = "DIS" }, Petrified = { initiative = "DIS" }, Stunned = { initiative = "DIS" },
        Poisoned = { attack = "DIS", check = "DIS", initiative = "DIS" },
        Prone = { attack = "DIS" },
        Restrained = { attack = "DIS", dex = "DIS" },
        Unconscious = { attack = "DIS", initiative = "DIS" },
    }
    for _, condition in ipairs(R.CONDITIONS) do
        local want = expect[condition.name]
        if condition.name ~= "Concentrating" then
            Check(want ~= nil, "the test knows " .. condition.name)
            Only(condition.name)
            want = want or {}
            Eq(Mode("attack"), want.attack, condition.name .. " on an attack")
            Eq(Mode("spell attack"), want.attack, condition.name .. " on a spell attack")
            Eq(Mode("Athletics"), want.check, condition.name .. " on a skill")
            Eq(Mode("STR check"), want.check, condition.name .. " on an ability check")
            Eq(Mode("initiative"), want.initiative, condition.name .. " on initiative")
            Eq(Mode("DEX save"), want.dex, condition.name .. " on a DEX save")
            Eq(Mode("WIS save"), nil, condition.name .. " on a WIS save")
        end
    end
    -- speed
    Only()
    local speed = RPSheet:Speed()
    Check(speed > 0, "a speed to begin with")
    for _, name in ipairs({ "Grappled", "Paralyzed", "Petrified", "Restrained", "Unconscious" }) do
        Only(name)
        Eq(RPSheet:Speed(), 0, name .. " leaves a speed of 0")
    end
    for _, name in ipairs({ "Blinded", "Charmed", "Deafened", "Frightened", "Incapacitated", "Invisible", "Poisoned", "Prone", "Stunned" }) do
        Only(name)
        Eq(RPSheet:Speed(), speed, name .. " leaves the speed alone")
    end
    -- saves that fail
    for _, name in ipairs({ "Paralyzed", "Petrified", "Stunned", "Unconscious" }) do
        Only(name)
        Eq(RPSheet:AutoFail("STR save"), name, name .. " fails STR saves")
        Eq(RPSheet:AutoFail("DEX save"), name, name .. " fails DEX saves")
        Eq(RPSheet:AutoFail("CON save"), nil, name .. " leaves CON saves")
        Eq(D20s(function() RPSheet:RollCheck("DEX save", 2) end), 0, name .. ": no die for a DEX save")
        Said("fails the [DEX save] without a roll ([" .. name .. "]).", name .. " auto-fail line")
    end
    for _, name in ipairs({ "Incapacitated", "Restrained", "Prone", "Grappled" }) do
        Only(name)
        Eq(RPSheet:AutoFail("DEX save"), nil, name .. " doesn't fail DEX saves")
    end
    -- cancelling out
    Only("Poisoned")
    Eq(Mode("attack", "ADV"), nil, "advantage and Poisoned cancel")
    Only("Poisoned", "Prone", "Blinded")
    Eq(Mode("attack", "ADV"), nil, "any number of disadvantages cancel with one advantage")
    Only("Invisible", "Poisoned")
    Eq(Mode("attack"), nil, "Invisible and Poisoned cancel")
    Eq(Mode("attack", "DIS"), nil, "and a chosen disadvantage changes nothing")
    -- turned to stone, poison does nothing
    Only("Poisoned", "Petrified")
    Eq(Mode("Athletics"), nil, "a petrified character isn't poisoned")
    -- really rolled
    Only("Poisoned")
    Rolls(15, 4)
    Eq(D20s(function() RPSheet:RollCheck("Athletics", 5) end), 2, "a poisoned skill check rolls two dice")
    Said("[Athletics]: 4 [disadvantage: 15, 4] + 5 = 9", "the lower die counts")
    Only()
    Rolls(15)
    Eq(D20s(function() RPSheet:RollCheck("Athletics", 5, "ADV") end), 2, "advantage rolls two dice")
    Said("[advantage: 15, 10]", "advantage note")

    -- Unconscious brings Prone, which stays
    Only()
    RPSheet:ToggleCondition("Unconscious")
    Check(on.Unconscious and on.Prone, "Unconscious adds Prone")
    Said("is now [Unconscious] and [Prone].", "unconscious line")
    RPSheet:ToggleCondition("Unconscious")
    Check(not on.Unconscious and on.Prone, "Prone stays after coming to")
    RPSheet:ToggleCondition("Prone")
    Said("is no longer [Prone].", "off line")
    -- already prone
    on.Prone = true
    RPSheet:ToggleCondition("Unconscious")
    Said("is now [Unconscious].", "already prone: only Unconscious is said")
    Eq(table.concat(RPSheet:Conditions(), ","), "Prone,Unconscious", "the list of conditions")
    Only()

    -- the condition menu
    RPSheet:OpenConditionMenu(UIParent)
    Check(MENU and MENU.title == "Conditions", "the condition menu opens")
    Eq(MENU and #MENU.items, #R.CONDITIONS, "one row per condition")
    Click(MENU, "Blinded")
    Check(on.Blinded, "clicking a row sets the condition")
    Check(MENU.items[1].checked(), "the row is ticked")
    Click(MENU, "Blinded")
    Check(not on.Blinded, "and clears it")
end)

Section("exhaustion", function()
    Build("MAGE", "", 5)
    local state = RPSheet:State()
    local speed, check, save, init, attack, dc = RPSheet:Speed(), RPSheet:CheckMod("STR"), RPSheet:SaveMod("WIS"), RPSheet:Initiative(), RPSheet:SpellAttack(), RPSheet:SpellDC()
    local arcana = RPSheet:SkillMod(Skill("Arcana"))
    RPSheet:ChangeExhaustion(1); RPSheet:ChangeExhaustion(1)
    Eq(RPSheet:Exhaustion(), 2, "two levels")
    Said("is at exhaustion level 2.", "exhaustion line")
    Eq(RPSheet:Speed(), speed - 10, "5 feet a level")
    Eq(RPSheet:CheckMod("STR"), check - 4, "2 off checks a level")
    Eq(RPSheet:SaveMod("WIS"), save - 4, "2 off saves a level")
    Eq(RPSheet:Initiative(), init - 4, "2 off initiative a level")
    Eq(RPSheet:SpellAttack(), attack - 4, "2 off spell attacks a level")
    Eq(RPSheet:SkillMod(Skill("Arcana")), arcana - 4, "2 off skills a level")
    Eq(RPSheet:SpellDC(), dc, "the spell save DC is no d20 roll")
    Eq(table.concat(RPSheet:ConditionSummary(), ","), "Exhaustion 2", "summary for others")
    RPSheet:LongRest()
    Eq(RPSheet:Exhaustion(), 1, "a long rest takes one level off")
    RPSheet:ChangeExhaustion(-1)
    Said("is no longer exhausted.", "no longer exhausted")
    local sent = #SENT
    RPSheet:ChangeExhaustion(-1)
    Eq(#SENT, sent, "nothing below 0")
    for _ = 1, 8 do RPSheet:ChangeExhaustion(1) end
    Eq(RPSheet:Exhaustion(), 6, "six at most")
    Check(AnySaid("is at exhaustion level 6 and dies of it.", sent), "the sixth level kills")
    Eq(RPSheet:Speed(), math.max(0, speed - 30), "speed never below 0")
end)

Section("Next roll row", function()
    Build("WARRIOR", "", 5)
    local on = RPSheet:State().conditions
    RPSheet:CycleRollMode()
    Eq(RPSheet.rollMode, "ADV", "first click: advantage")
    Eq(ns.RollMode(), "ADV", "the row decides without a key")
    Eq(D20s(function() RPSheet:RollCheck("Athletics", 5, ns.RollMode()) end), 2, "rolled with advantage")
    Eq(RPSheet.rollMode, nil, "used up by the roll")
    RPSheet:CycleRollMode(); RPSheet:CycleRollMode()
    Eq(RPSheet.rollMode, "DIS", "second click: disadvantage")
    RPSheet:CycleRollMode()
    Eq(RPSheet.rollMode, nil, "third click: normal")
    -- locked: stays
    RPSheet:CycleRollMode(true)
    Check(RPSheet.rollMode == "ADV" and RPSheet.rollModeLocked, "locking starts from advantage")
    RPSheet:RollCheck("Athletics", 5, ns.RollMode())
    Eq(RPSheet.rollMode, "ADV", "a locked row stays")
    RPSheet:CycleRollMode(true)
    Check(not RPSheet.rollModeLocked, "unlocked again")
    -- cancelled out by a condition: the row was still the choice for this roll
    RPSheet.rollMode = "ADV"
    on.Poisoned = true
    Eq(D20s(function() RPSheet:RollCheck("Athletics", 5, ns.RollMode()) end), 1, "advantage and Poisoned: one die")
    Eq(RPSheet.rollMode, nil, "the row is used up by a roll it was cancelled on")
    on.Poisoned = nil
    -- an ability without a d20 leaves it
    RPSheet.rollMode = "ADV"
    local wind = Ability("Second Wind")
    Check(wind ~= nil, "a Warrior has Second Wind")
    if wind then RPSheet:UseAbility(wind, ns.RollMode()) end
    Eq(RPSheet.rollMode, "ADV", "an ability that rolls no d20 leaves the row")
    -- an attack uses it
    local item = RPSheet:AddItem("Longsword", 1); RPSheet:SetEquipped(item, true); RPSheet:SheetChanged()
    Eq(D20s(function() RPSheet:Attack(ns.RollMode()) end), 2, "an attack with the row's advantage")
    Eq(RPSheet.rollMode, nil, "used up by the attack")
    -- an auto-failed save rolls nothing and leaves it
    RPSheet.rollMode = "ADV"
    on.Stunned = true
    RPSheet:RollCheck("DEX save", 2, ns.RollMode())
    Eq(RPSheet.rollMode, "ADV", "a save that fails without a roll leaves the row")
    on.Stunned = nil
    RPSheet.rollMode = nil
end)

Section("saving throws: what is it against", function()
    -- an elf: advantage against being Charmed
    local sheet = Build("WARRIOR", "", 5, { species = "ELF" })
    local always, asked = RPSheet:SaveAdvantages("WIS save")
    if not Check(#asked > 0, "an elf has an advantage that is asked about (Fey Ancestry)") then return end
    local mod = RPSheet:SaveMod("WIS")
    MENU = false
    Eq(D20s(function() RPSheet:RollCheck("WIS save", mod) end), 0, "the menu comes before the roll")
    Check(MENU and MENU.title == "WIS save: what is it against?", "the menu's title")
    Eq(MENU and #MENU.items, 3, "one row for Charmed, one for something else, and the one to stop asking")
    Rolls(4, 16)
    Eq(D20s(function() Click(MENU, "being Charmed") end), 2, "against being Charmed: advantage")
    Said("rolls [WIS save] against being Charmed: 16 [advantage: 4, 16]", "the line says what it is against")
    Eq(D20s(function() Click(MENU, "Something else") end), 1, "something else: a plain roll")
    Check(not (SENT[#SENT] or ""):find("against"), "a plain save names nothing")
    -- every ability asks: the trait covers all saves
    MENU = false
    RPSheet:RollCheck("STR save", 1)
    Check(MENU and MENU.title == "STR save: what is it against?", "a STR save asks too")
    -- advantage chosen already: no menu
    MENU = false
    Eq(D20s(function() RPSheet:RollCheck("WIS save", mod, "ADV") end), 2, "with advantage chosen there is nothing to ask")
    Check(not MENU, "no menu with advantage chosen")
    -- disadvantage chosen: the menu, and the pick cancels it
    Eq(D20s(function() RPSheet:RollCheck("WIS save", mod, "DIS") end), 0, "with disadvantage it still asks")
    Eq(D20s(function() Click(MENU, "being Charmed") end), 1, "advantage against it cancels the disadvantage")
    Eq(D20s(function() Click(MENU, "Something else") end), 2, "something else: disadvantage stays")
    -- a check is never asked about
    MENU = false
    Eq(D20s(function() RPSheet:RollCheck("WIS check", 1) end), 1, "an ability check rolls at once")
    Check(not MENU, "no menu for a check")
    -- a save that fails by itself doesn't ask
    RPSheet:State().conditions.Paralyzed = true
    MENU = false
    RPSheet:RollCheck("DEX save", 1)
    Check(not MENU, "no menu for a save that fails without a roll")
    RPSheet:State().conditions.Paralyzed = nil
    -- the tooltip line
    local text = RPSheet:SaveAdvantageText("WIS")
    Check(text and text:find("Advantage against being Charmed %(Fey Ancestry%)"), "the save's tooltip names it")
    -- two sources for one thing share a row
    local entry = RPSheet:AddMount("Dragonkin companion")
    entry.called, entry.loyalty = true, 10
    MENU = false
    RPSheet:RollCheck("WIS save", mod)
    Eq(MENU and #MENU.items, 4, "a Dragonkin companion adds a row for Frightened")
    Eq(D20s(function() Click(MENU, "being Frightened") end), 2, "advantage against being Frightened")
    -- without the game's menu: a line, and the roll goes on
    local keep = MenuUtil
    MenuUtil = false
    local before = #PRINTED
    Eq(D20s(function() RPSheet:RollCheck("WIS save", mod) end), 1, "without a menu the save is rolled plainly")
    Check(AnyPrinted("You have advantage on this save if it is against being Charmed (Fey Ancestry); being Frightened (Dragonkin companion)", before), "and a line says what would give advantage")
    MenuUtil = keep

    -- a gnome: always, on three abilities, without asking
    Build("WARRIOR", "", 5, { species = "GNOME" })
    always, asked = RPSheet:SaveAdvantages("INT save")
    if Check(#always > 0, "a gnome has advantage on INT saves (Gnomish Cunning)") then
        MENU = false
        Eq(D20s(function() RPSheet:RollCheck("INT save", 1) end), 2, "an INT save with advantage")
        Check(not MENU, "without a question")
        Eq(D20s(function() RPSheet:RollCheck("WIS save", 1) end), 2, "a WIS save too")
        Eq(D20s(function() RPSheet:RollCheck("STR save", 1) end), 1, "not a STR save")
        Eq(D20s(function() RPSheet:RollCheck("INT check", 1) end), 1, "not an INT check")
        Eq(D20s(function() RPSheet:RollCheck("INT save", 1, "DIS") end), 1, "disadvantage cancels it")
    end

    -- Danger Sense: not while incapacitated
    Build("SHAMAN", "", 5)
    if Check(Passive("Danger Sense") ~= nil, "a level 5 Shaman has Danger Sense") then
        Eq(RPSheet:ResolveMode("DEX save"), "ADV", "Danger Sense gives advantage on DEX saves")
        RPSheet:State().conditions.Incapacitated = true
        Eq(RPSheet:ResolveMode("DEX save"), nil, "not while incapacitated")
        Eq(RPSheet:ResolveMode("DEX save", "ADV"), "ADV", "advantage chosen by hand still counts")
        RPSheet:State().conditions.Incapacitated = nil
        RPSheet:State().conditions.Restrained = true
        Eq(RPSheet:ResolveMode("DEX save"), nil, "Restrained cancels it")
    end

    -- Reliable Talent
    Build("ROGUE", "", 7)
    local name
    for skill, rank in pairs(RPSheet:Sheet().skills) do if rank >= 1 then name = name or skill end end
    if Check(RPSheet:FeatureFlag("reliable"), "a level 7 Rogue has Reliable Talent") and name then
        Rolls(3)
        RPSheet:RollCheck(name, 4)
        Said("[rolled 3, counts as 10] + 4 = 14", "a low die counts as 10")
        Rolls(3)
        RPSheet:RollCheck("STR save", 4)
        Said("3 + 4 = 7", "not on a save")
    end
end)

Section("armor and the announce channel", function()
    local sheet = Build("WARRIOR", "", 5, { base = { STR = 12, DEX = 14, CON = 14, INT = 10, WIS = 10, CHA = 10 } })
    local speed = RPSheet:Speed()
    Eq(RPSheet:ResolveMode("Stealth"), nil, "no armor: Stealth as usual")
    sheet.armor = "CHAINMAIL"
    Eq(RPSheet:DisadvantageFrom("Stealth"), "armor", "chain mail gives disadvantage on Stealth")
    Eq(RPSheet:ResolveMode("Stealth", "ADV"), nil, "which advantage cancels")
    Eq(RPSheet:ResolveMode("Athletics"), nil, "and no other skill")
    Check(RPSheet:Score("STR") < 13, "Strength below what chain mail asks for")
    Eq(RPSheet:Speed(), speed - 10, "armor too heavy costs 10 feet")
    sheet.armor = "LEATHER"
    Eq(RPSheet:ResolveMode("Stealth"), nil, "leather is quiet")
    Eq(RPSheet:Speed(), speed, "and light")
    sheet.armor = "NONE"
    -- Self only: printed, with dice of the addon's own
    local profile = RPSheet.db.profile
    profile.channel = "SELF"
    local sent, before, rolled = #SENT, #PRINTED, #ROLLED
    RPSheet:RollCheck("Athletics", 5)
    Check(#SENT == sent and #PRINTED > before, "Self only: printed, not sent")
    Eq(#ROLLED, rolled, "and no /roll in chat")
    -- Party without a party: printed with the reason
    profile.channel = "PARTY"
    before = #PRINTED
    RPSheet:TakeDamage(1)
    Check(#SENT == sent and AnyPrinted("only you see this: you are not in a party", before), "Party without a party: shown to the player alone, with the reason")
    profile.channel = "EMOTE"
    RPSheet:CycleChannel()
    Eq(profile.channel, "PARTY", "the channel row goes to the next channel")
    profile.channel = "EMOTE"
end)

Summary("t-test-play-conditions")
