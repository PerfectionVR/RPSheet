-- The companion's part of the sheet window: its strike, the strike's mastery, and
-- its own ability checks and saving throws (see Actions/Pet.lua).
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local Signed = ns.Util.Signed

local BOND = "Your companion adds your proficiency bonus to every ability check and saving throw it makes."

-- The strike row, and under it the mastery pick and the cleave it can allow.
local function StrikeRows(self, body, pet, block)
    local toHit, flat = self:PetStrikeMods()
    local masteryName, mastery = self:PetMastery()
    local help = { "Left-click: roll to hit, then damage. A natural 20 doubles the damage dice." }
    if block.charge then
        help[#help + 1] = ("Right-click: the same after it moved 20 feet straight at the target. Rolls 1d%d more, and a Large or smaller target is knocked prone."):format(block.charge)
    end
    if block.grapple then
        help[#help + 1] = ("A hit grapples the target; it escapes against DC %d."):format(self:PetGrappleDC())
    end
    help[#help + 1] = ns.ROLL_MODE_HELP
    if masteryName then help[#help + 1] = ("\n%s%s|r: %s"):format(UI.ACCENT, masteryName, mastery.desc) end
    UI.AddLabel(body, 1, ("Beast's Strike  %s%s to hit, 1d%d %s damage%s|r"):format(
        UI.GREY, Signed(toHit), block.die, Signed(flat), masteryName and (", " .. masteryName) or ""),
        function(button) self:PetStrike(ns.RollMode(), button == "RightButton" and "charge" or nil) end,
        "Beast's Strike", table.concat(help, "\n"))

    -- Bestial Fury: the beast strikes twice when commanded.
    if self:Sheet().level >= 11 then
        UI.AddLabel(body, 1, ("Beast's Strike twice  %sboth strikes in one click|r"):format(UI.GREY),
            function(button) self:PetStrike(ns.RollMode(), button == "RightButton" and "charge" or nil, true) end,
            "Bestial Fury", "Rolls two strikes one after the other. Right-click when the first one follows a charge.\n" .. ns.ROLL_MODE_HELP)
    end

    if not pet or not self:HasWeaponMastery() then return end
    UI.AddLabel(body, 1, ("Strike mastery: %s%s|r %s"):format(UI.ACCENT, pet.mastery, masteryName and "(in use)" or (UI.GREY .. "(not picked)|r")),
        function()
            if self:TogglePetMastery() then self:PopulateSoon() end
        end, "Strike mastery: " .. pet.mastery,
        ("%s\n\nYour companion's family can be one of your Weapon Mastery picks (%d of %d used); its strike then has this mastery. You choose when you gain the companion and after a long rest.\n\nClick to %s."):format(
            R.MASTERIES[pet.mastery].desc, self:MasteriesUsed(), self:MasteryLimit(), masteryName and "take the pick off" or "pick it"))
    if masteryName == "Cleave" then
        UI.AddLabel(body, 1, ("Cleave: second target  %s%s to hit, 1d%d %s damage|r"):format(
            UI.GREY, Signed(toHit), block.die, Signed(block.flat + math.min(0, self:Mod("WIS")))),
            function() self:PetStrike(ns.RollMode(), "cleave") end,
            "Cleave", "After a strike hits, once per turn: your companion attacks a second creature within 5 feet of the first. Your Wisdom modifier isn't added to this damage.\n" .. ns.ROLL_MODE_HELP)
    end
end

-- Six rows of one kind: "check" or "save".
local function RollRows(self, body, kind)
    local scores = R.PetBlock(self:Sheet()).scores
    local long = kind == "save" and "saving throw" or "check"
    for _, stat in ipairs(R.STATS) do
        local mod = self:PetRollMod(stat)
        local text = kind == "save" and ("%s save %s%s|r"):format(stat, UI.GREY, Signed(mod))
            or ("%s %d %s(%s)|r"):format(stat, scores[stat], UI.GREY, Signed(mod))
        UI.AddLabel(body, 0.33, text,
            function() self:PetCheck(stat, kind, ns.RollMode()) end,
            ("Companion: %s %s"):format(R.STAT_NAMES[stat], long),
            ("%s\n\nClick to roll your companion's %s %s. A skill it uses rolls as a check of that skill's ability.\n%s"):format(
                BOND, R.STAT_NAMES[stat], long, ns.ROLL_MODE_HELP),
            function() self:Print(self:ExplainPetTerm(("companion %s %s"):format(stat, kind))) end)
    end
end

-- Only for a character who has a companion.
function UI.PetSection(self, body)
    if not self:HasPet() then return end
    local sheet = self:Sheet()
    local pet, block = R.Pet(sheet), R.PetBlock(sheet)
    UI.AddHeading(body, pet and ("Companion: " .. pet.name) or "Companion")
    UI.AddLabel(body, 1, ("AC %s%d|r  %sspeed %s, darkvision %d feet|r"):format(UI.ACCENT, self:PetAC(), UI.GREY, block.speed, block.darkvision),
        nil, "Companion", ("A %s %s. Its Armor Class is 13 plus your Wisdom modifier. Its passive Perception is %d."):format(
            block.size, block.name, 10 + self:PetRollMod("WIS")))
    StrikeRows(self, body, pet, block)
    RollRows(self, body, "check")
    RollRows(self, body, "save")
end
