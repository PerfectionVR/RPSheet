-- Spells that change how Armor Class is worked out rather than add to it, through
-- flags on the passive their casting switches on (Data/SpellWardEffects.lua):
--   mageArmor = 13   without armor, a base of 13 + Dexterity in place of 10 +
--                    Dexterity (or Unarmored Defense, when that comes to more)
--   acFloor = 17     Armor Class at least 17
-- RPSheet:AC (Sheet/DerivedDefense.lua) and its explanation (Sheet/ExplainDefense.lua)
-- are wrapped here, so this file loads after both.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- How much Mage Armor adds over the usual base, and the passive that gives it.
local function MageArmor(self)
    local base = self:FeatureFlag("mageArmor")
    local sheet = self:Sheet()
    if type(base) ~= "number" or self:Form() or sheet.armor ~= "NONE" then return 0 end
    local armor = R.ARMOR[sheet.armor]
    return math.max(0, base - armor.ac - (self:UnarmoredDefense()))
end

local AC = RPSheet.AC
function RPSheet:AC()
    local ac = AC(self) + MageArmor(self)
    local floor = self:FeatureFlag("acFloor")
    if type(floor) == "number" and floor > ac then ac = floor end
    return ac
end

-- Explanations are printed for the player, or collected when another player asked
-- (as in Sheet/Explain.lua).
local function Out(self, text)
    if self.explainCapture then
        self.explainCapture[#self.explainCapture + 1] = text
    else
        self:Print(text)
    end
end

local ExplainAC = RPSheet.ExplainAC
function RPSheet:ExplainAC()
    local raised = MageArmor(self)
    if raised == 0 and self:FeatureFlag("acFloor") == nil then return ExplainAC(self) end
    local before = AC(self)
    ExplainAC(self)
    if raised > 0 then
        Out(self, ("Mage Armor: a base of %d + Dexterity counts in place of that base, %d more: |cffffd100%d|r."):format(self:FeatureFlag("mageArmor"), raised, before + raised))
    end
    local floor = self:FeatureFlag("acFloor")
    if type(floor) == "number" and floor > before + raised then
        Out(self, ("Barkskin: your Armor Class is |cffffd100%d|r while it is lower than that."):format(floor))
    end
end
