-- What a Beast Master's companion rolls: its own checks and saving throws, and its
-- strike with what the strike does on top of its damage (numbers in Sheet/Pet.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local RollText = ns.RollText

-- " (wolf)" after the name of a roll, so the line says whose roll it is.
local function Whose(self, detail)
    local word = self:PetWord()
    if word and detail then return (" (%s, %s)"):format(word, detail) end
    if word or detail then return (" (%s)"):format(word or detail) end
    return ""
end

-- An ability check or saving throw of the companion. `kind` is "check" or "save".
-- The character's own conditions and features don't touch it: `mode` is used as given.
function RPSheet:PetCheck(stat, kind, mode)
    if self.busy or self:IsRolling() then return end
    local label = ns.Mark(("companion %s %s"):format(stat, kind)) .. Whose(self)
    local mod = self:PetRollMod(stat)
    self:RollD20(mode, function(d20, note)
        self:Announce("rolls " .. RollText.Check(label, d20, mod, note))
    end)
end

-- The companion's strike: to hit, then damage, doubled on a natural 20. `how` is
--   "charge"  a beast of the land ran 20 feet straight at the target: one more die,
--             and the target can be knocked prone
--   "cleave"  the second attack the Cleave mastery allows: no Wisdom in the damage
-- What a hit does besides damage is said after the numbers.
function RPSheet:PetStrike(mode, how)
    if self.busy or self:IsRolling() then return end
    local block = R.PetBlock(self:Sheet())
    local toHit, flat = self:PetStrikeMods()
    local riders = {}
    if how == "cleave" then
        if self:PetMastery() ~= "Cleave" then
            self:Print("Your companion's strike doesn't have the Cleave mastery right now.")
            return
        end
        -- Only a negative modifier still counts for a cleave's damage.
        flat = block.flat + math.min(0, self:Mod("WIS"))
    else
        if how == "charge" and not block.charge then how = nil end
        if how == "charge" then
            riders[#riders + 1] = ("On a hit: %s if Large or smaller"):format(ns.Mark("Prone"))
        end
        riders[#riders + 1] = self:PetMasteryNote()
    end
    if block.grapple then
        riders[#riders + 1] = ("On a hit: %s, escape DC %d"):format(ns.Mark("Grappled"), self:PetGrappleDC())
    end

    self.busy = true
    self:RollD20(mode, function(d20, note)
        local crit = d20 == 20
        self:RollDice(crit and 2 or 1, block.die, function(rolls)
            local text = ("uses %s%s - %s, %s"):format(
                ns.Mark("Beast's Strike"), Whose(self, how == "charge" and "after a charge" or (how == "cleave" and "cleaving") or nil),
                RollText.Check("to hit", d20, toHit, note),
                RollText.Dice(crit and "critical damage" or "damage", rolls, block.die, flat))
            local function Finish()
                if #riders > 0 then text = text .. ". " .. table.concat(riders, ". ") end
                self.busy = false
                self:Announce(text)
                self:Refresh()
            end
            if how ~= "charge" then return Finish() end
            self:RollDice(crit and 2 or 1, block.charge, function(extra)
                text = text .. ", " .. RollText.Dice("charge", extra, block.charge, 0)
                Finish()
            end)
        end)
    end)
end

-- The strike abilities on the sheet go through PetStrike, so they roll and say the
-- same as the companion's own rows. Returns true when `ability` was one of them.
local STRIKES = { ["Beast's Strike"] = "plain", ["Beast's Strike: charge"] = "charge" }
function ns.PetAbility(self, ability, mode)
    local how = STRIKES[ability.name]
    if not how or not self:HasPet() then return false end
    self:PetStrike(mode, how)
    return true
end
