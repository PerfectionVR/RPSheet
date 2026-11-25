-- The combat window's tab for the session's owner: the rolls of the combatant whose
-- turn it is (UI/FightWindowCreatures.lua), what they do to the row they picked
-- (Integrations/FightOwnerTools.lua), adding combatants of their own
-- (Integrations/FightCreatures.lua), and ending the session. Moving the turn on is
-- above the tabs (UI/FightWindowTurn.lua).
local _, ns = ...
local UI = ns.UI
local F = ns.Fight

local function Button(body, text, tip, run, width)
    UI.AddButton(body, width or 0.5, text, run, text, tip)
end

-- The buttons about the combatant the owner picked.
local function AddPicked(body, session)
    local key = F.target
    local member = key and session.members[key]
    if not member then
        UI.AddLabel(body, 1, UI.GREY .. "Click a combatant's health bar above to ask them for a saving throw, deal damage, heal, or hand the session over.|r")
        return
    end
    UI.AddLabel(body, 1, ("For %s%s|r:"):format(UI.ACCENT, member.name))
    Button(body, "Deal damage",
        member.npc and "Type the amount, and the damage type if you like, for example 12 fire. It comes off its hit points; a creature from the list halves what it resists, ignores what it is immune to and doubles what it is vulnerable to."
            or ("Type the amount, and the damage type if it has one, for example 12 fire. %s's own sheet takes it, with its resistances and everything else \"Take damage\" does."):format(member.name),
        function() ns.AskFightText(("Damage to %s: amount and type"):format(member.name), "", F.DealDamage) end)
    Button(body, "Heal", ("Type the hit points %s gets back."):format(member.name),
        function() ns.AskFightText(("Hit points back for %s"):format(member.name), "", F.HealTarget) end)
    Button(body, "Ask for a saving throw",
        member.npc and "Type the ability, the DC and its bonus, for example DEX 15 +2. Your game rolls it and says how it went."
            or ("Type the ability and the DC, for example DEX 15. %s is told and rolls it on their own sheet; your game says whether it meets the DC."):format(member.name),
        function() ns.AskFightText(("A saving throw from %s: ability and DC%s"):format(member.name, member.npc and ", and its bonus" or ""),
            member.npc and "DEX 15 +0" or "DEX 15", F.AskSave) end)
    if member.npc then
        Button(body, "Remove from the fight", ("%s leaves the session and the order."):format(member.name), function() F.RemoveCreature(key) end)
    elseif key ~= F.Me() then
        Button(body, "Hand the session over", ("%s owns the session from now on: their game keeps it and announces it, and they get these buttons. You stay in the fight, and the combatants you ran go with the session."):format(member.name),
            function() F.HandOver() end)
    end
end

function UI.AddFightOwner(self, body, session)
    local holder = session.phase == "RUN" and session.members[session.turn or ""]
    if holder and holder.npc and UI.AddCreatureTurn(body, holder) then
        -- its own attacks and saves are listed (UI/FightWindowCreatures.lua)
    elseif holder and holder.npc then
        Button(body, ("Roll an attack for %s"):format(holder.name),
            "Type its attack bonus, for example +5. Your game rolls the d20; with a combatant picked it also says whether the attack hits. Deal the damage with \"Deal damage\".",
            function() ns.AskFightText(("%s attacks: its attack bonus"):format(holder.name), "+0", function(text) F.CreatureAttack(text) end) end, 1)
    end
    AddPicked(body, session)
    UI.AddLabel(body, 1, UI.GREY .. "The fight:|r")
    Button(body, "Add a creature from the list", "The creatures of Azeroth with their numbers: Armor Class, hit points, saves, attacks and what they resist. One you add knows its attacks, so on its turn you click them instead of typing.",
        function()
            F.picking = true
            F.Changed()
        end)
    Button(body, "Add a combatant you run",
        "A creature, or a player without the addon. Type its name, Armor Class and hit points, and its initiative bonus if it has one, for example Gnoll 13 22 +1. It gets a row like everyone; your game rolls its initiative, and you roll its attacks and saves and keep its hit points from here.",
        function() ns.AskFightText("A combatant you run: name, Armor Class, hit points, initiative bonus", "", F.AddCreature) end)
    if session.phase == "RUN" then
        Button(body, "Call for initiative again", "A new fight in the same session: everyone rolls again.", function() F.CallInitiative() end)
    end
    Button(body, "End the session", "The fight is over for everyone.", function() F.End() end)
end
