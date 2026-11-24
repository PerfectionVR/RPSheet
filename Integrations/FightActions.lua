-- Combat sessions, part 8: what the combat window offers this character right now.
-- On its turn: its attack, its abilities, its prepared spells and the actions everyone
-- has. On someone else's turn only what can be done then: reactions, and what takes no
-- action. What the character has but can't use at the moment is listed with the
-- reason (`why`), for the window to grey out. What it doesn't have isn't listed.
local _, ns = ...
local RPSheet = ns.addon
local F = ns.Fight
local Util = ns.Util

-- The actions everyone has besides Attack and Magic, with what they do in our words.
F.COMMON = {
    { "Dash", "You gain extra movement this turn equal to your speed." },
    { "Disengage", "Your movement doesn't provoke opportunity attacks for the rest of the turn." },
    { "Dodge", "Until your next turn attacks against you have disadvantage if you can see the attacker, and you have advantage on Dexterity saves. It ends if you are incapacitated or your speed is 0." },
    { "Help", "Help with an ability check, or distract an enemy within 5 feet so that an ally's next attack against it has advantage." },
    { "Hide", "Out of sight, make a DC 15 Stealth check: roll Stealth on your sheet. On a success you are invisible while hidden." },
    { "Influence", "Make a Deception, Intimidation, Performance, Persuasion or Animal Handling check to change a creature's attitude: roll the skill on your sheet." },
    { "Ready", "Hold an action for a trigger you name; when it happens before your next turn, you take it with your reaction." },
    { "Search", "Make a Wisdom check to notice something: roll Insight, Medicine, Perception or Survival on your sheet." },
    { "Study", "Make an Intelligence check about something you examine or recall: roll the skill on your sheet." },
    { "Utilize", "Use an object that isn't a magic item." },
}

local COST_LABEL = { ACTION = "action", ATTACK = "attack", BONUS = "bonus action", REACTION = "reaction", FREE = "no action" }

-- Why the ability's own costs can't be paid, in the words the sheet would print, or nil.
local function CantPay(self, ability)
    local said
    local print = self.Print
    self.Print = function(_, text) said = text end
    local ok, costs = pcall(ns.AbilityKit.CollectCosts, self, ability)
    self.Print = print
    if ok and not costs then return said or "It can't be paid for right now." end
end

-- Why no slot can pay for the spell, or nil.
local function NoSlot(self, spell)
    if spell.level <= 0 then return nil end
    for _, tracker in ipairs(self:GetTrackers()) do
        if tracker.kind == "slot" and tracker.level >= spell.level and tracker.get() > 0 then return nil end
    end
    return ("No spell slot of level %d or higher is left."):format(spell.level)
end

-- A list of { section, name, info, cost, costLabel, why, tip, run }.
function F.Actions()
    local self, list = RPSheet, {}
    if not F.Running() then return list end
    local sheet, mine = self:Sheet(), F.MyTurn()
    local held = self:Incapacitated()
    local heldWhy = held and ("You are %s: no actions, bonus actions or reactions."):format(held:lower()) or nil

    local function Add(section, name, info, cost, slot, tip, run, own)
        if not mine and cost ~= "REACTION" and cost ~= "FREE" then return end
        list[#list + 1] = {
            section = section, name = name, info = info, cost = cost, costLabel = COST_LABEL[cost],
            why = (cost ~= "FREE" and heldWhy) or F.Why(cost, slot) or own, tip = tip, run = run,
        }
    end

    if mine and self:IsDown() then
        Add("At 0 hit points", "Death save", "", "FREE", false, "At the start of your turn at 0 hit points you roll a death save.",
            function() self:RollDeathSave() end)
    end

    local weapon = self:GetWeapon()
    if weapon then
        Add("Attack", weapon.name, self:WeaponText(weapon), "ATTACK", false,
            "One attack of your Attack action with the weapon in hand: to hit, then damage.", function() self:Attack(ns.RollMode()) end)
    elseif not self:HasUnarmedRow() then
        Add("Attack", "Unarmed Strike", self:UnarmedText(), "ATTACK", false,
            "One attack of your Attack action: a punch, kick or headbutt.", function() self:UnarmedAttack(ns.RollMode()) end)
    end

    for _, ability in ipairs(Util.Named(sheet.abilities)) do
        local desc = type(ability.desc) == "string" and ability.desc or ""
        Add("Abilities", ability.name, "", F.AbilityCost(ability), false, desc,
            function() self:UseAbility(ability, ns.RollMode()) end, CantPay(self, ability))
    end

    local spells = Util.Named(sheet.spells)
    table.sort(spells, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)
    for _, spell in ipairs(spells) do
        local cost = F.SpellCost(spell)
        -- A spell that takes a minute or more to cast isn't something for a turn.
        if cost ~= "LONG" then
            Add(spell.level == 0 and "Cantrips" or "Spells", spell.name, self:SpellText(spell), cost, spell.level > 0,
                type(spell.desc) == "string" and spell.desc or "",
                function() self:CastSpell(spell, ns.RollMode()) end, self:FormBlocksSpell(spell) or NoSlot(self, spell))
        end
    end

    for _, action in ipairs(F.COMMON) do
        Add("Actions everyone has", action[1], "", "ACTION", false, action[2], function() F.TakeAction(action[1]) end)
    end
    return list
end
