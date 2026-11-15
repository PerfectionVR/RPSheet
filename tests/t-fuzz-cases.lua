-- Faults the random-play tester (t-fuzz-play.lua) found in the addon, each kept as the
-- shortest list of steps that showed it. A case is played from a fresh login and
-- every invariant is asked after every step; it must end without a problem.
--
-- A step names its action and what it chose (t-fuzz-lib.lua); what it doesn't name
-- is chosen from its seed. To add a case, paste the scenario a PROBLEM printed.
--   run.sh t-fuzz-cases.lua [part of a case's name]
dofile(ARG3 .. "/t-fuzz-lib.lua")
local Z = FUZZ
local only = rawget(_G, "ARG4")

local CASES = {
    -- A slot made from Sorcery Points above the usual number: the row read "5/4",
    { name = "made slot above the usual", steps = {
        { a = "make", seed = 1502097047, p = { ["#1"] = "FEAT", ["#2"] = "Poisoner", ["#3"] = "Lightning", alignment = "Lawful Neutral", allegiance = "ALLIANCE", background = "MERCHANT", backgroundGear = true, class = "EVOKER", classGear = false, classSkill1 = "skill11", classSkill2 = "skill9", closet = true, extras = 0, level = 7, plusOne = "INT", plusTwo = "CON", scores = "15 15 15 8 8 8", spec = "Preservation", species = "WORGEN", spread = false, subclass = "Draconic Sorcery" } },
        { a = "ability", seed = 1446132986, p = { ability = "Font of Magic: points to slot", mode = "none" } },
        -- ... and "4/5" once the made slot was spent again
        { a = "cast", seed = 459551487, p = { mode = "none", ritual = false, slotClicks = 6, spell = "Chromatic Orb" } },
    } },
    -- A cantrip picked that the subclass also gives: it stood on the spell list twice
    -- when the subclass's copy was there first (a character made above level 3).
    { name = "cantrip picked and always prepared", steps = {
        { a = "make", seed = 785744743, p = { ["#1"] = "ASI", ["#2"] = "Magician", tick = "Starry Wisp", alignment = "Chaotic Neutral", allegiance = "NEUTRAL", background = "SOLDIER", backgroundGear = true, class = "DRUID", classGear = true, classSkill1 = "skill8", classSkill2 = "skill9", closet = true, extras = 3, gearChoicebackground1 = "Dice Set", level = 4, plusOne = "CON", plusTwo = "DEX", scores = "15 15 15 8 8 8", spec = "Balance", species = "ORC", spread = false, subclass = "Circle of the Moon" } },
    }, check = function()
        local count = 0
        for _, spell in ipairs(RPSheet:Sheet().spells) do if spell.name == "Starry Wisp" then count = count + 1 end end
        if count ~= 1 then return "Starry Wisp is on the spell list " .. count .. " times" end
    end },
    -- An always-prepared spell renamed under Customize: the upkeep added it again.
    { name = "always-prepared spell renamed", steps = {
        { a = "make", seed = 1354584614, p = { ["#1"] = "FEAT", ["#2"] = "Piercer", ["#3"] = "ASI", ["#4"] = "FEAT", ["#5"] = "Poisoner", alignment = "Neutral", allegiance = "ALLIANCE", background = "SOLDIER", backgroundGear = false, class = "PALADIN", classGear = true, classSkill1 = "skill12", classSkill2 = "skill11", closet = false, extras = 4, gearChoiceclass1 = "Emblem", level = 13, plusOne = "DEX", plusTwo = "CON", scores = "15 15 15 8 8 8", spec = "Holy", species = "FORSAKEN", spread = false, subclass = "Oath of Devotion" } },
        { a = "customize", seed = 1742088915, p = { option = "options.customize.spells.item8.name", text = "1" } },
        { a = "final", seed = 1438017031, p = {} },
    } },
    -- A spell's roll still on its way when a new character is made: the result
    -- landed on the new character and raised an error.
    { name = "roll lands on the next character", steps = {
        { a = "make", seed = 1, p = { class = "EVOKER", level = 7, extras = 0, tick = "Fireball" } },
        { a = "hold rolls", seed = 562202533, p = {} },
        { a = "cast", seed = 450439724, p = { mode = "none", ritual = false, slotClicks = 6, spell = "Fireball" } },
        { a = "wizard open", seed = 1183392276, p = {} },
        { a = "make", seed = 2, p = { class = "WARRIOR", level = 6, extras = 0 } },
        { a = "land rolls", seed = 1558605604, p = { stop = true } },
    }, check = function()
        if FUZZ.cast ~= "Fireball" then return "the case didn't cast its spell (" .. tostring(FUZZ.cast) .. ")" end
    end },
    -- The window for changing prepared spells open, then the first spell after a
    -- rest is cast: the window went on saying the list could still be changed.
    { name = "prepared window after the first spell", steps = {
        { a = "make", seed = 3, p = { class = "DRUID", level = 10, extras = 0, tick = "Starry Wisp" } },
        { a = "click", seed = 1528399239, p = { button = "LeftButton", keys = "", mark = false, row = "window: InteractiveLabel Change prepared spells" } },
        { a = "cast", seed = 1070505899, p = { mode = "none", ritual = false, slotClicks = 6, spell = "Starry Wisp" } },
    }, check = function()
        if FUZZ.cast ~= "Starry Wisp" then return "the case didn't cast its spell (" .. tostring(FUZZ.cast) .. ")" end
        if not RPSheet.preparedWindow or not RPSheet.preparedWindow.frame:IsShown() then return "the case didn't open the window" end
    end },
    -- A beast form that runs out during a short rest: the sheet went on showing
    -- the form's Armor Class and attacks.
    { name = "form ends during a short rest", steps = {
        { a = "make", seed = 1874223803, p = { ["#1"] = "Warden", alignment = "Lawful Good", allegiance = "NEUTRAL", background = "GUARD", backgroundGear = true, class = "ROGUE", classGear = true, classSkill1 = "skill2", classSkill2 = "skill3", classSkill3 = "skill18", classSkill4 = "skill4", closet = false, extras = 2, gearChoicebackground1 = "Three-Dragon Ante Set", level = 4, moreClass1 = "DRUID", moreClass2 = "DEMONHUNTER", moreLevel1 = 2, moreLevel2 = 1, moreSkill2 = "Survival", moreSpec1 = "Guardian", moreSpec2 = "Devourer", plusOne = "WIS", plusTwo = "STR", scores = "14 14 13 13 8 8", spec = "Assassination", species = "PANDAREN", spread = false } },
        { a = "wild shape", seed = 1530802240, p = {} },
        { a = "short rest", seed = 1787215230, p = {} },
    } },
    -- Down at 0 hit points, then healed by an ability: the death save row stayed.
    { name = "death save row after an ability heals", steps = {
        { a = "make", seed = 490778005, p = { alignment = "Lawful Evil", allegiance = "ALLIANCE", background = "GUARD", backgroundGear = true, class = "WARRIOR", classGear = false, classSkill1 = "skill18", classSkill2 = "skill11", closet = true, extras = 0, gearChoicebackground1 = "Playing Cards", level = 3, lineage = "Mulgore Tauren", plusOne = "STR", plusTwo = "WIS", scores = "15 15 13 10 8 8", spec = "Arms", species = "TAUREN", spread = false, subclass = "Champion" } },
        { a = "damage", seed = 957245857, p = { amount = "400", type = "lightning" } },
        { a = "ability", seed = 185821877, p = { ability = "Second Wind", mode = "none" } },
    }, check = function()
        if RPSheet:IsDown() then return "the case didn't heal the character" end
    end },
}

local played, problems = 0, 0
for _, case in ipairs(CASES) do
    if not only or case.name:find(only, 1, true) then
        played = played + 1
        local problem, at = Z.Replay(case.steps, nil, true)
        if problem then
            problems = problems + 1
            print(("PROBLEM %s: step %d (%s): %s: %s"):format(case.name, at, case.steps[at].a, problem.kind, problem.text))
        end
        if case.check then
            local ok, why = Z.pcall(case.check)
            if not ok or why then
                problems = problems + 1
                print(("PROBLEM %s: %s"):format(case.name, tostring(why)))
            end
        end
    end
end
print(("fuzz cases: %d cases, %d problems"):format(played, problems))
