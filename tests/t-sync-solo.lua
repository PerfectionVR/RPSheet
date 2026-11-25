-- A session played alone, the way it is tried out: one player, in no group, starts a
-- session, adds creatures from the list, and runs them against their own character.
-- The creature's attack is rolled against the character's Armor Class and its damage
-- lands on the sheet; a save it forces is rolled on the sheet and the damage follows
-- the result; damage to the creature meets its resistances; and the creature list
-- itself is held against the site's facts (tests/data/site-creatures.txt).
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local maren = world:AddClient({ name = "Maren" }):Login():OpenSheet()
world:Advance(10)
maren:Build("WARRIOR", "", 5)
world:Advance(5)

local F, R, addon = maren.ns.Fight, maren.ns.Rules, maren.addon

-- The owner's client rolls its creatures' dice with math.random: the test says what comes up.
local realRandom, dice = math.random, {}
math.random = function(low, high)
    if high and #dice > 0 then return math.min(high, math.max(low, table.remove(dice, 1))) end
    return realRandom(low, high)
end

local function SaidSince(from, needle)
    for index = from + 1, #maren.said do
        if maren.said[index].text:find(needle, 1, true) then return maren.said[index].text end
    end
end
local function Key(name)
    for key, member in pairs(F.session.members) do
        if member.name == name then return key, member end
    end
end
local function HP() return addon:State().hp or addon:MaxHP() end

Section("the list of creatures", function()
    local count = 0
    for line in io.lines(ARG3 .. "/data/site-creatures.txt") do
        if not line:find("^#") and line ~= "" then
            count = count + 1
            local f = {}
            for field in (line .. "|"):gmatch("([^|]*)|") do f[#f + 1] = field end
            local mine = R.CREATURES[f[1]]
            if not mine then
                Check(false, "the list has " .. f[1])
            else
                local attacks, forces = 0, 0
                for _ in f[15]:gmatch("[^;]+") do attacks = attacks + 1 end
                for _ in f[16]:gmatch("[^;]+") do forces = forces + 1 end
                local same = mine.ac == tonumber(f[5]) and mine.hp == tonumber(f[6]) and mine.init == tonumber(f[7]) and mine.cr == f[4]
                    and #mine.attacks == attacks and #mine.forces == forces
                if not same then Check(false, f[1] .. " has the site's numbers") end
                for _, attack in ipairs(mine.attacks) do
                    local text = R.DamagePartsText(attack.parts):gsub(" %+ (%d+) ", "+%1 "):gsub(" %+ (%d+)$", "+%1"):gsub(" %+ ", "+")
                    if not f[15]:gsub("%+%d+d%d+ chosen", "+4d8"):find(attack.name .. "~" .. attack.reach .. "~" .. attack.hit .. "~" .. text, 1, true) then
                        Check(false, ("%s: %s reads back as the site has it (%s)"):format(f[1], attack.name, text))
                    end
                end
            end
        end
    end
    Eq(count, 84, "the site's file has 84 creatures")
    Eq(#R.CREATURE_ORDER, 84, "and so has the list")
    local felguard = R.CREATURES["Felguard"]
    Eq(felguard.saves.DEX, 2, "a save without a listed bonus is the ability's modifier")
    Eq(R.CREATURES["Felhound"].saves.DEX, 6, "a listed bonus is taken as it is")
    Check(felguard.immune.poison and felguard.resist.fire, "immunities and resistances are known")
    Eq(R.DamagePartsText(felguard.attacks[1].parts), "2d8 + 3 slashing + 2d6 fire", "damage is said in dice")
    Eq(R.CREATURE_ORDER[1], "Mechanostrider", "the list goes by challenge, then by name")
    Eq(R.FindCreature("  felguard "), felguard, "a name finds its creature whatever its capitals")
    Eq(#F.CreatureMatches("dragonflight"), 15, "part of a name narrows the list")
    Check(F.CreatureSummary(felguard):find("Fel Battleaxe: +5 to hit, 2d8 + 3 slashing + 2d6 fire.", 1, true), "its tooltip lists its attacks")
    -- every way of sorting the list holds every creature once
    for _, grouping in ipairs(R.CREATURE_GROUPINGS) do
        local seen, total = {}, 0
        for _, group in ipairs(R.CreatureGroups(grouping.key)) do
            for _, name in ipairs(group.list) do
                total = total + 1
                if seen[name] or not R.CREATURES[name] then Check(false, name .. " is once under " .. grouping.name) end
                seen[name] = true
            end
        end
        Eq(total, 84, "sorted by " .. grouping.name:lower() .. " the list holds all 84")
    end
    local function Group(key, name)
        for _, group in ipairs(R.CreatureGroups(key)) do
            if group.name == name then return #group.list end
        end
    end
    Eq(Group("kind", "Dragon"), 15, "by type: the dragons")
    Eq(Group("side", "Burning Legion"), 13, "by side: the Burning Legion")
    Eq(Group("people", "Nerubians"), 6, "by people: the nerubians")
    Eq(R.CreatureGroups("side")[#R.CreatureGroups("side")].name, "Others", "what belongs nowhere comes last")
end)

Section("alone in a session", function()
    maren:Do(F.Start)
    world:Advance(2)
    Check(F.IsOwner() and F.Mine(), "a player without a group starts a session and is in it")
    maren:Do(F.AddCreature, "Felguard")
    maren:Do(F.AddCreature, "felguard")
    world:Advance(2)
    local key, felguard = Key("Felguard")
    Check(felguard and felguard.npc and felguard.template == "Felguard", "a creature's name alone adds it from the list")
    Eq(felguard.ac, 17, "with its Armor Class")
    Eq(felguard.max, 60, "and hit points")
    Check(Key("Felguard 2"), "a second one is numbered")
    maren:Do(F.RemoveCreature, (Key("Felguard 2")))
    dice = { 10 }
    maren:Do(F.CallInitiative)
    world:Advance(2)
    Eq(F.session.members[key].init, 12, "its initiative is rolled with its own bonus")
    maren.rolls = { 2 }
    maren:Do(F.RollInitiative)
    world:Advance(2)
    Eq(F.session.phase, "RUN", "the turns start when the player has rolled too")
    Eq(F.session.turn, key, "and the creature, higher, goes first")
end)

Section("the creature attacks", function()
    local key = Key("Felguard")
    F.target = F.Me()
    local hp, said = HP(), #maren.said
    dice = { 2 } -- 2 + 5 = 7: a miss
    maren:Do(F.CreatureStrike, 1)
    world:Advance(3)
    Check(SaidSince(said, "Felguard attacks with Fel Battleaxe: 2 + 5 = 7 - misses Maren"), "a low roll misses, and is said: " .. tostring(SaidSince(said, "Felguard attacks")))
    Eq(HP(), hp, "a miss deals nothing")
    said = #maren.said
    dice = { 19, 4, 4, 3, 3 } -- hits; 2d8 + 3 = 11 slashing, 2d6 = 6 fire
    maren:Do(F.CreatureStrike, 1)
    world:Advance(6)
    Check(SaidSince(said, "for 11 slashing + 6 fire damage"), "a hit rolls the attack's damage: " .. tostring(SaidSince(said, "Felguard attacks")))
    Eq(HP(), hp - 17, "which the character's own sheet takes, one type after the other")
    hp, said = HP(), #maren.said
    dice = { 20, 1, 1, 1, 1, 1, 1, 1, 1 } -- a natural 20: 4d8 + 3 and 4d6
    maren:Do(F.CreatureStrike, 1)
    world:Advance(6)
    Check(SaidSince(said, "a critical hit on Maren for 7 slashing + 4 fire damage"), "a natural 20 doubles the dice: " .. tostring(SaidSince(said, "Felguard attacks")))
    Eq(HP(), hp - 11, "and that lands too")
    -- with no one picked it is aimed at its only opponent
    F.target = nil
    Eq(F.CreatureTarget(key), F.Me(), "alone with one opponent, the creature is aimed at them")
    hp, said = HP(), #maren.said
    dice = { 15, 2, 2, 2, 2 }
    maren:Do(F.CreatureStrike, 1)
    world:Advance(6)
    Check(SaidSince(said, "= 20 - hits Maren"), "so its attack is held against them without a click: " .. tostring(SaidSince(said, "Felguard attacks")))
    Eq(HP(), hp - 11, "and lands")
    local logged = false
    for _, line in ipairs(F.LogLines()) do logged = logged or line:find("Felguard attacks with Fel Battleaxe: 15 + 5 = 20 - hits Maren", 1, true) ~= nil end
    Check(logged, "what the session says is kept in the fight's log")
    Check(F.LogText("Felguard attacks: 20 - hits Maren (AC 16)"):find("|cffff7777", 1, true), "a hit is red in the log")
    Check(F.LogText("{star} Maren regains 4 hit points."):find("UI-RaidTargetingIcon_1", 1, true), "and a group's mark is its icon")
    Eq(F.Template(F.session.members[key]).name, "Felguard", "the combatant knows its template")
end)

Section("damage to the creature", function()
    local key = Key("Felguard")
    F.target = key
    local said = #maren.said
    maren:Do(F.DealDamage, "10 fire")
    world:Advance(2)
    Eq(F.session.members[key].hp, 55, "it resists fire: half")
    Check(SaidSince(said, "Felguard takes 5 fire damage (resisted)."), "which is said")
    maren:Do(F.DealDamage, "30 poison")
    world:Advance(2)
    Eq(F.session.members[key].hp, 55, "it is immune to poison: nothing")
    Check(SaidSince(said, "Felguard takes no damage (immune)."), "said too")
    maren:Do(F.DealDamage, "5 slashing")
    Eq(F.session.members[key].hp, 50, "other damage lands whole")
    said = #maren.said
    dice = { 9 }
    maren:Do(F.AskSave, "DEX 12")
    Check(SaidSince(said, "Felguard rolls a DEX save: 9 + 2 = 11 - fails against DC 12"), "a save asked of it uses its own bonus: " .. tostring(SaidSince(said, "Felguard rolls")))
end)

Section("a save the creature forces", function()
    maren:Do(F.AddCreature, "Felhound") -- Drink Magic: CON save, DC 13, 3d6 necrotic
    world:Advance(2)
    local key = Key("Felhound")
    local printed = #maren.printed
    addon:State().hp = addon:MaxHP()
    F.target = nil
    Eq(F.CreatureTarget(key), nil, "with two opponents the creature is aimed at no one until one is picked")
    maren:Do(F.CreatureForce, 1, key)
    local told = false
    for index = printed + 1, #maren.printed do told = told or tostring(maren.printed[index]):find("Click the health bar of who has to save", 1, true) ~= nil end
    Check(told, "it needs someone to save")
    local hp, said = HP(), #maren.said
    dice = { 15, 2, 2, 2 }
    maren:Do(F.CreatureStrike, 1, key)
    world:Advance(3)
    Check(SaidSince(said, ", for "), "and its attack and damage are only announced: " .. tostring(SaidSince(said, "Felhound attacks")))
    Eq(HP(), hp, "nobody takes it")
    F.target = F.Me()
    hp, said = HP(), #maren.said
    dice = { 4, 4, 4 }
    maren:Do(F.CreatureForce, 1, key)
    world:Advance(2)
    Check(SaidSince(said, "Felhound uses Drink Magic: Maren makes a Constitution saving throw, DC 13."), "the save is asked of the picked row")
    Check(F.owedSave and F.owedSave.dc == 13 and F.owedSave.stat == "CON", "the player owes it")
    Eq(HP(), hp, "nothing is taken before the roll")
    maren.rolls = { 2 }
    addon.busy = false
    maren:Do(function() addon:RollCheck("CON save", addon:SaveMod("CON"), nil, false, {}) end)
    world:Advance(6)
    Check(SaidSince(said, "fails against DC 13"), "a low roll fails")
    Check(SaidSince(said, "Maren takes 12 necrotic damage from Drink Magic."), "and the damage that waited follows")
    Eq(HP(), hp - 12, "on the sheet")
    -- against one of the owner's own: rolled here
    F.target = Key("Felguard")
    local before = F.session.members[F.target].hp
    said = #maren.said
    dice = { 1 } -- the save; the damage of this turn is the same 12
    maren:Do(F.CreatureForce, 1, key)
    world:Advance(2)
    Check(SaidSince(said, "Felguard rolls a CON save: 1 + 3 = 4 - fails against DC 13"), "a creature's save is rolled by the owner's game: " .. tostring(SaidSince(said, "Drink Magic")))
    Eq(F.session.members[F.target].hp, before - 12, "and the same damage lands on it")
end)

Section("half on a success", function()
    maren:Do(F.AddCreature, "Doomguard") -- War Stomp: STR save, DC 17, 9d8 thunder, half on a success
    world:Advance(2)
    local key = Key("Doomguard")
    F.target = F.Me()
    addon:State().hp = addon:MaxHP()
    local hp, said = HP(), #maren.said
    dice = { 2, 2, 2, 2, 2, 2, 2, 2, 2 } -- 18 thunder
    maren:Do(F.CreatureForce, 1, key)
    world:Advance(2)
    maren.rolls = { 20 }
    addon.busy = false
    maren:Do(function() addon:RollCheck("STR save", addon:SaveMod("STR"), nil, false, {}) end)
    world:Advance(6)
    Check(SaidSince(said, "succeeds against DC 17"), "a high roll succeeds")
    Check(SaidSince(said, "Maren takes 9 thunder damage from War Stomp (half)."), "and takes half")
    Eq(HP(), hp - 9, "on the sheet")
end)

Section("a reload", function()
    maren:Reload():OpenSheet()
    world:Advance(8)
    F, R, addon = maren.ns.Fight, maren.ns.Rules, maren.addon
    local _, felguard = Key("Felguard")
    Check(F.IsOwner() and felguard and F.Template(felguard), "the session and its creatures, with their templates, are back")
    maren:Do(F.End)
    world:Advance(2)
    Check(not F.session, "and the session ends")
end)

math.random = realRandom
world:CheckClean("solo")
Summary("t-sync-solo")
