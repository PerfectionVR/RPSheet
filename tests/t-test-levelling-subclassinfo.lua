-- Every listed subclass has an explanation where it is chosen; the Mage's Evoker says
-- it is not the Evoker class.
NUM_CHAT_WINDOWS = 10
RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"
dofile(ARG3 .. "/sim.lua")
Start()
local checks, problems = 0, 0
local function Expect(label, ok)
    checks = checks + 1
    if not ok then problems = problems + 1 print("PROBLEM: " .. label) end
end
for key, class in pairs(R.CLASSES) do
    for _, subclass in ipairs(class.subclasses) do
        local text = ns.SubclassSummary(subclass)
        Expect(("%s / %s has an explanation"):format(key, subclass), text:find("Level %d") ~= nil)
        Expect(("%s / %s: no odd text in its explanation"):format(key, subclass),
            not (text:find("%f[%a]nil%f[%A]") or text:find("function: 0x") or text:find("table: 0x") or text:find("%%[sd]")))
    end
end
Expect("the Mage's Evoker is told apart from the Evoker class", ns.SubclassSummary("Evoker"):find("Evoker class") ~= nil)
Expect("an unknown subclass gives nothing", ns.SubclassSummary("Nonesuch") == "" and ns.SubclassSummary("") == "")
print(("subclass explanations: %d checks, %d problems"):format(checks, problems))
