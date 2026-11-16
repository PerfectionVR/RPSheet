-- Falling: 1d6 bludgeoning damage for every 10 feet, 20d6 at most, and Prone on
-- landing unless no damage was taken. The sheet rolls it from the distance, then
-- takes it as damage from a fall (Actions/DamageSteps.lua: Bouncy, Slow Fall).
local _, ns = ...
local RPSheet = ns.addon

local MAX_DICE = 20

-- Falls `feet`; `slowFall` true spends the reaction on Slow Fall.
function RPSheet:Fall(feet, slowFall)
    feet = math.floor(tonumber(feet) or 0)
    local count = math.min(MAX_DICE, math.floor(feet / 10))
    if count <= 0 then
        self:Print("A fall of less than 10 feet does no damage.")
        return
    end
    if self.busy or self:IsRolling() then
        self:Print("Another roll is still going. Take the fall again when it is done.")
        return
    end
    self.busy = true
    self:RollDice(count, 6, function(rolls)
        self.busy = false
        local sum = 0
        for _, value in ipairs(rolls) do sum = sum + value end
        local said = ns.RollText.Dice(("a fall of %d feet"):format(feet), rolls, 6, 0)
        self:TakeDamage(sum, "bludgeoning", nil, nil, false, { fall = true, slowFall = slowFall, said = said })
    end)
end

-- Asks how far, after asking about Slow Fall when the reaction is there to spend.
function RPSheet:AskFall(owner)
    local function Ask(slowFall)
        self:AskAmount({ prompt = "How many feet did you fall?\nThe sheet rolls 1d6 bludgeoning damage for every 10 feet (20d6 at most).",
            run = function(text) self:Fall(tonumber((text or ""):match("%d+")) or 0, slowFall) end })
    end
    local slow = self:DamageOptions().slowFall
    if not slow or not (MenuUtil and MenuUtil.CreateContextMenu) then return Ask(false) end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Use Slow Fall?")
        root:CreateButton(("Slow Fall: %d less damage (uses your reaction)"):format(slow), function() Ask(true) end)
        root:CreateButton("Without Slow Fall", function() Ask(false) end)
    end)
end
