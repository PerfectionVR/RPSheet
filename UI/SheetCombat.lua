-- The sheet's combat numbers (AC, initiative, speeds, spell numbers, senses, defenses)
-- and the weapon in hand.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local Signed = ns.Util.Signed

function UI.CombatSection(self, body)
    local sheet = self:Sheet()
    UI.AddHeading(body, "Combat")

    local function Number(label, value, onClick, tip, explain)
        UI.AddLabel(body, 0.33, ("%s %s%s|r"):format(label, UI.ACCENT, value), onClick, tip and label, tip, explain)
    end
    -- In a form the Armor Class is the form's own.
    local form = self:Form()
    local acTip = form and ("%s: the form's own Armor Class. Your armor and shield don't count while you are in it."):format(form.beast and (form.name .. " form") or form.name)
        or (R.ARMOR[sheet.armor].name .. (sheet.shield and ", shield" or ""))
    Number(form and "AC (form)" or "AC", self:AC(), nil, acTip,
        function() self:ExplainAC() end)
    Number("Initiative", Signed(self:Initiative()),
        function() self:RollCheck("initiative", self:Initiative(), ns.RollMode()) end,
        "Click to roll initiative.\n" .. ns.ROLL_MODE_HELP, function() self:ExplainInitiative() end)
    Number("Speed", self:Speed() .. " ft" .. UI.RidingMark(self), nil, function() return UI.SpeedTip(self) end, function() self:ExplainSpeed() end)
    -- Swimming, climbing and flying speeds, only when the character has one (Sheet/MoveSpeeds.lua).
    for _, kind in ipairs(R.MOVE_KINDS) do
        local feet = self:MoveSpeed(kind)
        if feet then
            Number(R.MOVE_LABELS[kind], feet .. " ft", nil, R.MOVE_TIPS[kind], function() self:ExplainMoveSpeed(kind) end)
        end
    end
    Number("Proficiency", Signed(self:ProficiencyBonus()), nil, ns.Glossary["Proficiency bonus"])
    Number("Passive Perc.", self:PassivePerception(), nil, "Passive Perception: 10 + Perception modifier.",
        function() self:ExplainPassivePerception() end)
    -- Senses and what the character shrugs off get rows of their own, after the numbers.
    local senses = self:Senses()
    local function After()
        if #senses > 0 then
            UI.AddLabel(body, 1, ("Senses %s%s|r"):format(UI.ACCENT, table.concat(senses, ", ")), nil, "Senses",
                "Darkvision comes from your species or beast form. The others are read from the passives that are switched on.")
        end
        UI.AddDefenseRows(self, body)
    end
    if self:CastStat() then
        Number("Spell DC", self:SpellDC(), nil, "Spell save DC: 8 + proficiency + " .. R.STAT_NAMES[self:CastStat()] .. " modifier.",
            function() self:ExplainSpellDC() end)
        Number("Spell attack", Signed(self:SpellAttack()),
            function() self:RollCheck("spell attack", self:SpellAttack(), ns.RollMode()) end,
            "Click to roll a spell attack.\n" .. ns.ROLL_MODE_HELP, function() self:ExplainSpellAttack() end)
    end
    After()

    self.attackLabel = nil
    local weapon = self:GetWeapon()
    if weapon then
        -- The weapon's properties and mastery, put together when the row is hovered.
        local function Help()
            local help = "Left-click: roll to hit, then damage. A natural 20 doubles the damage dice.\nRight-click: swap to the next weapon.\n" .. ns.ROLL_MODE_HELP
            local properties = ns.WeaponPropertyLines(weapon)
            if #properties > 0 then help = help .. "\n\n" .. table.concat(properties, "\n") end
            local name, mastery = self:WeaponMastery(weapon)
            if name then help = help .. ("\n\n%s%s|r: %s"):format(UI.ACCENT, name, mastery.desc) end
            return help
        end
        self.attackLabel = UI.AddLabel(body, 1, "", function(button)
            if button == "RightButton" then
                self:SwapWeapon()
                self:PopulateSoon() -- the tooltip follows the weapon
            else
                self:Attack(ns.RollMode())
            end
        end, "Attack", Help, function()
            local current = self:GetWeapon()
            if current then self:ExplainWeapon(current) end
        end)
    end
end
