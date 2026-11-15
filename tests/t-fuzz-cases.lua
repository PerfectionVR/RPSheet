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
    -- A slot made from Sorcery Points above the usual number: the row read "5/4".
    { name = "made slot above the usual", steps = {
        { a = "make", seed = 1502097047, p = { ["#1"] = "FEAT", ["#2"] = "Poisoner", ["#3"] = "Lightning", alignment = "Lawful Neutral", allegiance = "ALLIANCE", background = "MERCHANT", backgroundGear = true, class = "EVOKER", classGear = false, classSkill1 = "skill11", classSkill2 = "skill9", closet = true, extras = 0, level = 7, plusOne = "INT", plusTwo = "CON", scores = "15 15 15 8 8 8", spec = "Preservation", species = "WORGEN", spread = false, subclass = "Draconic Sorcery" } },
        { a = "ability", seed = 1446132986, p = { ability = "Font of Magic: points to slot", mode = "none" } },
    } },
}

local played, problems = 0, 0
for _, case in ipairs(CASES) do
    if not only or case.name:find(only, 1, true) then
        played = played + 1
        local problem, at = Z.Replay(case.steps)
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
