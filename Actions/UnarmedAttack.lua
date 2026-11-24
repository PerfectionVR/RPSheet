-- The Unarmed Strike everyone can make: the attack row's action while no weapon is in
-- hand (UI/SheetCombat.lua). A punch, kick or headbutt: Strength + proficiency to hit,
-- 1 + Strength bludgeoning damage. There is no damage die, so a critical hit deals the
-- same. In place of the damage the strike can grapple or shove: the target then saves
-- against 8 + Strength + proficiency. A character whose feats or class improve the strike has an Unarmed Strike row
-- of its own instead (Sheet/UnarmedStrike.lua, a Monk's Martial Arts).
local _, ns = ...
local RPSheet = ns.addon
local Signed = ns.Util.Signed

local NAME = "Unarmed Strike"

function RPSheet:UnarmedNumbers()
    local mod = self:Mod("STR")
    local toHit = mod + self:ProficiencyBonus() + self:Bonus("ATTACK")
    local damage = math.max(0, 1 + mod + self:DamageBonus("STR"))
    return toHit, damage
end

-- What a target saves against (Strength or Dexterity, its choice) when the strike is
-- used to grapple or shove instead of dealing damage.
function RPSheet:UnarmedDC()
    return 8 + self:Mod("STR") + self:ProficiencyBonus()
end

-- True when the sheet has an Unarmed Strike row of its own, which then takes over.
function RPSheet:HasUnarmedRow()
    for _, ability in ipairs(self:Sheet().abilities or {}) do
        if ability.name == NAME then return true end
    end
    return false
end

-- e.g. "+5 to hit, 4 bludgeoning damage"
function RPSheet:UnarmedText()
    local toHit, damage = self:UnarmedNumbers()
    return ("%s to hit, %d bludgeoning damage"):format(Signed(toHit), damage)
end

function RPSheet:UnarmedAttack(mode, answers)
    if self:CantAct("attack") then return end
    if not answers then
        return self:AskRoll("attack", mode, "STR attack", function(found) self:UnarmedAttack(mode, found) end)
    end
    mode = self:ResolveMode("attack", mode, "STR attack", nil, answers)
    local toHit, damage = self:UnarmedNumbers()
    self:RollTest(mode, function(d20, note, extra)
        local crit = d20 >= self:CritFrom()
        self:Announce(("attacks with %s - %s, %d bludgeoning damage%s"):format(ns.Mark(NAME),
            ns.RollText.Check("to hit", d20, toHit, note, extra), damage, crit and " (a critical hit: no die to double)" or ""))
    end)
end

-- Right-click: how the numbers are worked out.
function RPSheet:ExplainUnarmed()
    local mod, proficiency, attack = self:Mod("STR"), self:ProficiencyBonus(), self:Bonus("ATTACK")
    local toHit, damage = self:UnarmedNumbers()
    local hit = ("To hit %s = Strength %s + proficiency %s"):format(Signed(toHit), Signed(mod), Signed(proficiency))
    if attack ~= 0 then hit = hit .. " + attack bonuses " .. Signed(attack) end
    local hurt = ("Damage %d = 1 + Strength %s"):format(damage, Signed(mod))
    local more = self:DamageBonus("STR")
    if more ~= 0 then hurt = hurt .. " + damage bonuses " .. Signed(more) end
    self:Print(("%s: %s. %s bludgeoning. Grapple or shove DC %d = 8 + Strength %s + proficiency %s."):format(
        NAME, hit, hurt, self:UnarmedDC(), Signed(mod), Signed(proficiency)))
end
