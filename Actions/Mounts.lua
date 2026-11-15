-- What the player does with mounts, vehicles and companion creatures from the sheet:
-- getting on and off, calling and dismissing a companion, and its loyalty going up
-- and down. These hold to the rules; the Customize page can set anything directly.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- A loyal companion's gift can change skills, speed and what follows from them.
local function Changed(self)
    self:ClampState()
    self:PopulateSoon()
end

-- Gets on a mount or aboard a vehicle, or off the one the character is on. Getting on
-- another one gets off the first.
function RPSheet:ToggleRiding(entry)
    local vehicle = entry.kind == "VEHICLE"
    if entry.riding then
        entry.riding = false
        self:Announce((vehicle and "gets out of the %s" or "dismounts from the %s"):format(entry.name))
        Changed(self)
        return
    end
    local why = self:MountRefusal(entry)
    local stuck = self:Immobile()
    if not why and stuck then why = ("you are %s and can't move"):format(stuck) end
    if why then
        self:Print(("You can't get on %s: %s."):format(entry.name, why))
        return
    end
    for _, other in ipairs(self:Mounts()) do other.riding = false end
    entry.riding = true
    self:Announce((vehicle and "gets aboard the %s" or "mounts the %s"):format(entry.name))
    Changed(self)
end

-- Calls a companion creature to the character's side or sends it away. Calling one
-- sends away the one that was out.
function RPSheet:ToggleCompanion(entry)
    if entry.kind ~= "COMPANION" then return end
    local out = not entry.called
    for _, other in ipairs(self:Mounts()) do other.called = false end
    entry.called = out
    self:Announce((out and "calls %s to their side" or "dismisses %s"):format(entry.name))
    Changed(self)
end

-- The companion was treated particularly well (the DM decides when): its loyalty goes
-- up by a die, as far as the owner's Charisma score allows.
function RPSheet:TreatCompanion(entry)
    if entry.kind ~= "COMPANION" then return end
    local cap = self:LoyaltyCap()
    if entry.loyalty >= cap then
        self:Print(("%s can't grow more loyal: its loyalty can't go above your Charisma score (%d)."):format(entry.name, cap))
        return
    end
    self:Roll(R.LOYALTY_TREAT, function(rolled)
        local before = entry.loyalty
        entry.loyalty = math.min(cap, before + rolled)
        self:Print(("%s was treated well: loyalty %d + %d (1d%d) = %d%s."):format(entry.name, before, rolled, R.LOYALTY_TREAT, entry.loyalty,
            before + rolled > cap and (", held at your Charisma score of %d"):format(cap) or ""))
        if before < R.LOYALTY_GIFT and entry.loyalty >= R.LOYALTY_GIFT then
            local family = R.COMPANIONS[entry.family]
            self:Print(("It is loyal enough to give its gift while it is out%s"):format(family and (": " .. family.gift) or "."))
        end
        Changed(self)
    end)
end

-- The companion took damage: it is gone until called again and loses 1 loyalty.
function RPSheet:HurtCompanion(entry)
    if entry.kind ~= "COMPANION" or not entry.called then
        self:Print(("%s is not out, so nothing can have hurt it."):format(entry.name))
        return
    end
    entry.called = false
    entry.loyalty = math.max(0, entry.loyalty - 1)
    self:Announce(("loses %s to the damage; it is gone until called again"):format(entry.name))
    self:Print(("%s's loyalty drops to %d."):format(entry.name, entry.loyalty))
    Changed(self)
end
