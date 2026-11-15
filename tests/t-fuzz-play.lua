-- Plays the addon at random and checks after every action that the character is
-- still sane (see t-fuzz-lib.lua for how, t-fuzz-checks-lib.lua for what is checked).
--
--   run.sh t-fuzz-play.lua                    the regression run: fixed seeds, about a minute
--   run.sh t-fuzz-play.lua 5000 400           a soak: 5000 characters x 400 actions
--   run.sh t-fuzz-play.lua 5000 400 77        the same from seed 77 on (several at once: give each its own)
--   run.sh t-fuzz-play.lua seed 1234 400      one character again, from the seed a PROBLEM printed
--
-- A problem prints PROBLEM with the seed, the character and the last 15 actions, then
-- the shortest list of actions found that still ends in it, as a scenario that can be
-- pasted into t-fuzz-cases.lua.
dofile(ARG3 .. "/t-fuzz-lib.lua")
local Z = FUZZ
local function Arg(index) return rawget(_G, "ARG" .. index) end

local characters, actions, first = tonumber(Arg(4)) or 36, tonumber(Arg(5)) or 60, tonumber(Arg(6)) or 1
local one = Arg(4) == "seed"
if one then characters, first, actions = 1, tonumber(Arg(5)) or 1, tonumber(Arg(6)) or 60 end
local soak = not one and Arg(4) ~= nil
local budget = soak and 120 or 60 -- replays spent on making a failing list shorter

local began, played, problems, seen = os.clock(), 0, 0, {}
for seed = first, first + characters - 1 do
    local steps, problem = Z.Play(seed, actions, seen)
    played = played + #steps
    if problem then
        local signature = Z.Signature(problem)
        if not seen[signature] then
            seen[signature] = true
            problems = problems + 1
            local who = Z.pcall(Z.Describe) and Z.Describe() or "no character"
            print(("PROBLEM seed %d (%d actions): %s: %s"):format(seed, actions, problem.kind, problem.text))
            print("  character: " .. who)
            print("  last actions:")
            for index = math.max(1, #steps - 14), #steps do print("    " .. Z.StepText(steps[index])) end
            io.stdout:flush()
            local short, again, replays = Z.Shrink(steps, problem, budget)
            if again then
                print(("  shortest found (%d steps, after %d replays); replay: bash tests/run.sh t-fuzz-play.lua seed %d %d"):format(#short, replays, seed, actions))
                print(Z.ScenarioText(short))
            else
                print(("  it did not happen again when the steps were replayed; replay: bash tests/run.sh t-fuzz-play.lua seed %d %d"):format(seed, actions))
            end
            io.stdout:flush()
        end
    end
    if soak and (seed - first + 1) % 50 == 0 then
        print(("... %d characters, %d actions, %d problems, %.0fs"):format(seed - first + 1, played, problems, os.clock() - began))
        io.stdout:flush()
    end
end
if Arg(7) == "timing" or Arg(8) == "timing" then
    local names = {}
    for name in pairs(Z.timing) do names[#names + 1] = name end
    table.sort(names, function(a, b) return Z.timing[a][1] > Z.timing[b][1] end)
    for index = 1, math.min(25, #names) do
        local entry = Z.timing[names[index]]
        print(("  %-28s %6.2fs %6d calls %7.2f ms each"):format(names[index], entry[1], entry[2], entry[1] / entry[2] * 1000))
    end
end
print(("fuzz play: %d characters from seed %d, %d actions played, %.0fs; %d problems"):format(characters, first, played, os.clock() - began, problems))
