-- The sheet's combat numbers (AC, initiative, speeds, spell numbers, senses, defenses)
-- and the weapon in hand.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local Signed = ns.Util.Signed

function UI.CombatSection(self, body)
    local sheet = self:Sheet()
    UI.AddHeading(body, "Combat")

    -- The numbers are tiles, four to a row: a small label over the number. One that is
    -- clicked (initiative, spell attack) is a roll: a right-click explains it
    -- (UI.AddRollLabel).
    local function Number(label, value, onClick, tip, explain)
        local text = ("%s\n%s"):format(label, value)
        if onClick and explain then
            UI.AddRollLabel(body, 0.25, text, onClick, tip and label, tip, explain, "tile")
        else
            UI.AddLabel(body, 0.25, text, onClick, tip and label, tip, explain, "tile")
        end
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
    elseif not self:HasUnarmedRow() then
        -- Without a weapon in hand the row is the Unarmed Strike everyone can make
        -- (Actions/UnarmedAttack.lua).
        self.attackLabel = UI.AddLabel(body, 1, "", function(button)
            if button == "RightButton" then
                self.db.char.sheetTab = "Items"
                self:PopulateSoon()
            else
                self:UnarmedAttack(ns.RollMode())
            end
        end, "Unarmed Strike", function()
            return ("A punch, kick or headbutt: Strength and proficiency to hit, 1 + Strength bludgeoning damage.\nIn place of the damage you can grapple or shove a creature no more than one size larger than you. That takes no attack roll: the target makes a Strength or Dexterity save (its choice) against DC %d. Grappled, it is held; shoved, it is pushed 5 feet or knocked prone.\nLeft-click: roll to hit.\nRight-click: open the Items tab to equip a weapon; this row then attacks with it.\n"):format(self:UnarmedDC()) .. ns.ROLL_MODE_HELP
        end,
            function() self:ExplainUnarmed() end)
    else
        -- The sheet's own Unarmed Strike row (a feat, a style, Martial Arts) is the one to use.
        UI.AddLabel(body, 1, "|cff999999Attack: no weapon equipped (Unarmed Strike is on the Actions tab)|r", function()
            self.db.char.sheetTab = "Items"
            self:PopulateSoon()
        end, "Attack", "Equip a weapon on the Items tab, or add one under Customize > Weapons, and the attack row appears here. Click to open the Items tab.")
    end

    -- Turn-based combat with the group (Integrations/Fight.lua, UI/FightWindow.lua).
    local F = ns.Fight
    local session = F.session
    local standing = "none"
    if session then
        standing = ("%s's%s"):format(ns.Game.ShortName(session.owner),
            (F.MyTurn() and ", your turn") or (session.phase == "RUN" and (", round " .. session.round)) or (F.Mine() and "" or ", not joined"))
    end
    UI.AddLabel(body, 1, ("Combat session  %s%s|r"):format(UI.ACCENT, standing), function() F.ToggleWindow() end, "Combat session",
        "Turn-based combat with your party or raid. One of you starts a session and the others join; everyone rolls initiative for their own character, and the turns go round in that order. On your turn the combat window lists what you can do. Click to open or close it.")
end
