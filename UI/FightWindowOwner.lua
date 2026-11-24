-- The combat window's rows for the session's owner: calling for initiative, moving
-- the turn on, adding combatants of their own (Integrations/FightCreatures.lua), and
-- what they do to the row they picked (Integrations/FightOwnerTools.lua).
local _, ns = ...
local UI = ns.UI
local F = ns.Fight

local function Row(body, text, tip, run)
    UI.AddLabel(body, 1, UI.ACCENT .. text .. "|r", run, text, tip)
end

-- The rows about the combatant whose row the owner clicked.
local function AddPicked(body, session)
    local key = F.target
    local member = key and session.members[key]
    if not member then
        UI.AddLabel(body, 1, UI.GREY .. "Click a combatant's row above to ask them for a saving throw, deal damage, heal, or hand the session over.|r")
        return
    end
    UI.AddLabel(body, 1, ("For %s%s|r:"):format(UI.ACCENT, member.name))
    Row(body, "Ask for a saving throw",
        member.npc and "Type the ability, the DC and its bonus, for example DEX 15 +2. Your game rolls it and says how it went."
            or ("Type the ability and the DC, for example DEX 15. %s is told and rolls it on their own sheet; your game says whether it meets the DC."):format(member.name),
        function() ns.AskFightText(("A saving throw from %s: ability and DC%s"):format(member.name, member.npc and ", and its bonus" or ""),
            member.npc and "DEX 15 +0" or "DEX 15", F.AskSave) end)
    Row(body, "Deal damage",
        member.npc and "Type the amount, and the damage type if you like, for example 12 fire. It comes off its hit points as typed."
            or ("Type the amount, and the damage type if it has one, for example 12 fire. %s's own sheet takes it, with its resistances and everything else \"Take damage\" does."):format(member.name),
        function() ns.AskFightText(("Damage to %s: amount and type"):format(member.name), "", F.DealDamage) end)
    Row(body, "Heal", ("Type the hit points %s gets back."):format(member.name),
        function() ns.AskFightText(("Hit points back for %s"):format(member.name), "", F.HealTarget) end)
    if member.npc then
        Row(body, "Remove from the fight", ("%s leaves the session and the order."):format(member.name), function() F.RemoveCreature(key) end)
    elseif key ~= F.Me() then
        Row(body, "Hand the session over", ("%s owns the session from now on: their game keeps it and announces it, and they get these buttons. You stay in the fight, and the combatants you ran go with the session."):format(member.name),
            function() F.HandOver() end)
    end
end

function UI.AddFightOwner(self, body, session)
    UI.AddHeading(body, "Your session")
    local holder = session.phase == "RUN" and session.members[session.turn or ""]
    if holder and holder.npc and UI.AddCreatureTurn(body, holder) then
        -- its own attacks and saves are listed (UI/FightWindowCreatures.lua)
    elseif holder and holder.npc then
        Row(body, ("Roll an attack for %s"):format(holder.name),
            "Type its attack bonus, for example +5. Your game rolls the d20; with a combatant's row picked it also says whether the attack hits. Deal the damage with \"Deal damage\".",
            function() ns.AskFightText(("%s attacks: its attack bonus"):format(holder.name), "+0", function(text) F.CreatureAttack(text) end) end)
    end
    if session.phase == "LOBBY" then
        Row(body, "Call for initiative", "Everyone who joined rolls initiative, a Dexterity check, for their own character; your game rolls for the combatants you run. The turns start when all have rolled.",
            function() F.CallInitiative() end)
    elseif session.phase == "ROLL" then
        Row(body, "Start without the rest", "Starts the turns with those who have rolled. Whoever rolls later takes that place in the order.", function() F.Begin() end)
    else
        Row(body, "Next turn", "Ends the turn that is running and gives it to the next in the order: for a combatant you run, or someone who can't end theirs.", function() F.NextTurn() end)
        Row(body, "Call for initiative again", "A new fight in the same session: everyone rolls again.", function() F.CallInitiative() end)
    end
    Row(body, "Add a creature from the list", "The creatures of Azeroth with their numbers: Armor Class, hit points, saves, attacks and what they resist. One you add knows its attacks, so on its turn you click them instead of typing.",
        function()
            F.picking = true
            F.Changed()
        end)
    Row(body, "Add a combatant you run",
        "A creature, or a player without the addon. Type its name, Armor Class and hit points, and its initiative bonus if it has one, for example Gnoll 13 22 +1. It gets a row like everyone; your game rolls its initiative, and you roll its attacks and saves and keep its hit points from here.",
        function() ns.AskFightText("A combatant you run: name, Armor Class, hit points, initiative bonus", "", F.AddCreature) end)
    AddPicked(body, session)
    Row(body, "End the session", "The fight is over for everyone.", function() F.End() end)
end
