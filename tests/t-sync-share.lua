-- Sharing sheets between players: what one client sends reaches the others, is kept
-- under the right name and reads the same in their Total RP 3 tooltip as on the
-- sender's own; nothing leaves a client that is alone or has sharing off; late
-- joiners, reloads, realms, factions, and players without the addon or without TRP3.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local anna = world:AddClient({ name = "Anna" }):Login():OpenSheet()                -- no Total RP 3
local bert = world:AddClient({ name = "Bert", trp3 = {} }):Login():OpenSheet()
local cara = world:AddClient({ name = "Cara", trp3 = {}, oldChatFilters = true }):Login():OpenSheet()

-- What `from` shows of itself, as lines.
local function Own(from) return from.addon:GetStatLines(from.addon:GetStatData()) end
-- `to` holds a copy of `from`'s stats that reads exactly as `from`'s own.
local function Synced(from, to, label)
    local copy = to.addon:GetCachedStats(from.full)
    if not Check(copy ~= nil, ("%s: %s has nothing from %s"):format(label, to.name, from.name)) then return {} end
    local own, got = Own(from), to.addon:GetStatLines(copy)
    Eq(table.concat(got, " / "), table.concat(own, " / "), ("%s: %s's copy of %s"):format(label, to.name, from.name))
    for _, line in ipairs(got) do Check(Plain(line), label .. ": a line that isn't plain text: " .. line) end
    if to.trp3 then
        to:Hover(from, true)
        local shown = to:TooltipStats()
        Eq(shown and table.concat(shown, " / "), table.concat(own, " / "), ("%s: %s's tooltip of %s"):format(label, to.name, from.name))
        to:Hover(nil)
    end
    return got
end
local function Has(lines, piece, label)
    local text = table.concat(lines or {}, " / ")
    Check(text:find(piece, 1, true) ~= nil, ("%s: expected \"%s\" in: %s"):format(label, piece, text))
end

Section("alone", function()
    world:Advance(10)
    anna:Build("WARRIOR", "", 5)
    bert:Build("MAGE", "", 3)
    cara:Build("ROGUE", "", 4)
    anna.addon:TakeDamage(3); anna.addon:Heal(3); anna.addon:ToggleCondition("Prone"); anna.addon:ToggleCondition("Prone")
    world:Advance(10)
    Eq(#world.wire, 0, "addon messages sent by players who are alone")
    Eq(#anna.refused, 0, "messages the game refused for want of a group")
end)

Section("a party of two", function()
    world:Group({ anna, bert })
    world:Advance(3)
    Eq(#world.wire, 2, "messages after forming a party (one each)")
    Eq(world.wire[1] and world.wire[1].chatType, "PARTY", "sent to")
    local lines = Synced(anna, bert, "single class")
    Has(lines, "Level 5 Arms Warrior - Human", "single class")
    Has(lines, "HP 44/44", "single class")
    Synced(bert, anna, "single class")
    Eq(anna:Tooltip(), nil, "a client without Total RP 3 has no such tooltip")
end)

Section("0 hit points and conditions", function()
    local before = #world.wire
    anna.addon:TakeDamage(44)
    world:Advance(3)
    local lines = Synced(anna, bert, "at 0 HP")
    Has(lines, "HP 0/44", "at 0 HP")
    anna.addon:Heal(10)
    anna.addon:ToggleCondition("Poisoned")
    anna.addon:ToggleCondition("Frightened")
    anna.addon:ChangeExhaustion(2)
    world:Advance(3)
    lines = Synced(anna, bert, "conditions")
    Has(lines, "HP 10/44", "healed")
    Has(lines, "Frightened, Poisoned, Exhaustion 2", "conditions")
    anna.addon:ToggleCondition("Poisoned"); anna.addon:ToggleCondition("Frightened"); anna.addon:ChangeExhaustion(-2)
    world:Advance(3)
    lines = Synced(anna, bert, "conditions gone")
    Check(not table.concat(lines, "/"):find("Exhaustion"), "conditions gone: still listed")
    Check(world:Traffic(anna, before) <= 3, "three bursts of changes are at most three messages, got " .. world:Traffic(anna, before))
end)

Section("the tooltip that is open follows", function()
    bert:Hover(anna)
    world:Advance(1)
    anna.addon:Heal(5)
    world:Advance(3)
    local shown = bert:TooltipStats()
    Has(shown, "HP 15/44", "open tooltip after a change")
    bert:Hover(nil)
    Eq(bert:Tooltip(), nil, "tooltip closed")
    -- the player's own tooltip shows the player's own sheet
    bert:Hover(bert)
    Eq(table.concat(bert:TooltipStats() or {}, " / "), table.concat(Own(bert), " / "), "own tooltip")
    bert.addon.db.profile.tooltip = false
    bert:Hover(bert)
    Eq(bert:TooltipStats(), nil, "the Stats section with the tooltip setting off")
    Check(bert:Tooltip() ~= nil, "Total RP 3's own tooltip still shows")
    bert.addon.db.profile.tooltip = true
    bert:Hover(nil)
end)

Section("several classes", function()
    anna:Build("HUNTER", "", 12, { spec = "Beast Mastery", lineage = "", alignment = "Chaotic Good",
        extras = { { class = "DRUID", level = 4 }, { class = "PALADIN", level = 3 } } })
    world:Advance(3)
    local lines = Synced(anna, bert, "three classes")
    Has(lines, "Level 12", "three classes")
    Has(lines, "Chaotic Good", "three classes: the end of a long summary")
end)

Section("a beast form and a mount", function()
    local R = anna.ns.Rules
    anna:Build("DRUID", "Circle of the Land", 4, { base = { STR = 8, DEX = 12, CON = 14, INT = 10, WIS = 16, CHA = 10 },
        setup = function(sheet) sheet.picks.forms = { Wolf = true } end })
    world:Advance(3)
    Synced(anna, bert, "druid")
    local use
    for _, ability in ipairs(anna.addon:Sheet().abilities) do if ability.name == "Wild Shape: Wolf" then use = ability end end
    if Check(use ~= nil, "the druid has Wild Shape: Wolf") then
        anna.addon:UseAbility(use)
        world:Advance(3)
        Check(anna.addon:Form() ~= nil, "in a form")
        local lines = Synced(anna, bert, "in a beast form")
        Has(lines, ("STR %d"):format(R.BEASTS.Wolf.str), "in a beast form: the wolf's Strength")
        anna.addon:LeaveForms("test")
        anna.addon:PopulateSoon()
        world:Advance(3)
        Has(Synced(anna, bert, "out of the form"), "STR 8", "out of the form")
    end
    local name
    for candidate, mount in pairs(R.MOUNTS or {}) do
        if not name and type(mount) == "table" and mount.kind ~= "VEHICLE" and mount.kind ~= "COMPANION" then
            local entry = anna.addon:AddMount(candidate)
            if entry and not anna.addon:MountRefusal(entry) then name = candidate
            elseif entry then anna.addon:RemoveMount(entry) end
        end
    end
    if Check(name ~= nil, "a mount the druid can ride") then
        anna.addon:ToggleRiding(anna.addon:OwnedMount(name))
        world:Advance(3)
        Check(anna.addon:Riding() ~= nil, "riding " .. tostring(name))
        Synced(anna, bert, "riding")
    end
end)

Section("sharing switched off", function()
    local before = #world.wire
    anna.addon.db.profile.share = false
    anna.addon:QueueBroadcast() -- what the setting's switch does
    anna.addon:TakeDamage(2)
    world:Advance(5)
    Eq(world:Traffic(anna, before), 0, "messages from a client with sharing off")
    -- it is not answered for either, by whisper
    anna:LeaveGroup()
    world:Advance(40)
    before = #world.wire
    bert:Hover(anna)
    world:Advance(3)
    Eq(world:Traffic(bert, before), 1, "the hover asks once")
    Eq(world:Traffic(anna, before), 0, "no answer with sharing off")
    bert:Hover(nil)
    anna.addon.db.profile.share = true
end)

Section("asking by hover and by target", function()
    world:Advance(40) -- the cooldown of asking the same player
    anna:Build("WARRIOR", "", 5)
    local before = #world.wire
    bert:Hover(anna)
    world:Advance(1)
    Eq(world:Traffic(bert, before), 1, "one question")
    Eq(world:Traffic(anna, before), 1, "one answer")
    Eq(world.wire[#world.wire].chatType, "WHISPER", "the answer is whispered")
    Eq(world.wire[#world.wire].target, bert.full, "to the one who asked")
    Has(bert:TooltipStats(), "Level 5 Arms Warrior", "the tooltip filled in when the answer came")
    bert:Hover(nil); bert:Hover(anna); bert:Target(anna); bert:Hover(nil); bert:Hover(anna)
    world:Advance(5)
    Eq(world:Traffic(nil, before), 2, "hovering again within the cooldown asks nothing")
    bert:Hover(nil)
    world:Advance(31)
    bert:Target(anna)
    world:Advance(1)
    Eq(world:Traffic(nil, before), 4, "after the cooldown a target asks again")
    Synced(anna, bert, "asked")
    -- a player of the other faction can't be whispered: nothing is sent
    local orc = world:AddClient({ name = "Grok", faction = "Horde" }):Login()
    before = #world.wire
    bert:Hover(orc); bert:Target(orc)
    world:Advance(2)
    Eq(world:Traffic(nil, before), 0, "nothing is asked of the other faction")
    -- a player without the addon is asked, and nothing comes back
    local plain = world:AddClient({ name = "Nobody" }):Bare()
    bert:Hover(plain)
    world:Advance(2)
    Eq(world:Traffic(nil, before), 1, "a player without the addon is asked once")
    Eq(bert:TooltipStats(), nil, "and shows no Stats")
    -- someone who logged off is not asked
    plain.online = false
    world:Advance(31)
    before = #world.wire
    bert:Target(plain)
    world:Advance(1)
    Eq(world:Traffic(nil, before), 0, "an offline player is not asked")
    Eq(#bert.system, 0, "no 'No player named' line for the player")
    bert:Hover(nil); bert:Target(nil)
    orc:Logout()
end)

Section("a late joiner", function()
    world:Group({ anna, bert })
    world:Advance(3)
    Eq(cara.addon:GetCachedStats(anna.full), nil, "outside the party nothing is heard")
    local before = #world.wire
    world:Join(cara, anna)
    world:Advance(3)
    Synced(anna, cara, "late joiner"); Synced(bert, cara, "late joiner")
    Synced(cara, anna, "late joiner"); Synced(cara, bert, "late joiner")
    Eq(world:Traffic(nil, before), 3, "messages when a third joins (one each)")
end)

Section("a reload", function()
    bert.addon:TakeDamage(1)
    world:Advance(3)
    bert:Reload():OpenSheet()
    Check(type(bert.saved) == "table", "saved variables written")
    Eq(bert.addon:GetCachedStats(anna.full), nil, "what was received is gone after a reload")
    Eq(bert.addon:State().hp, bert.addon:MaxHP() - 1, "the sheet's own hit points survive the reload")
    world:Advance(6)
    Synced(bert, anna, "after the reload"); Synced(bert, cara, "after the reload")
    -- the group answers the one who came back, without being hovered
    Synced(anna, bert, "back from the reload"); Synced(cara, bert, "back from the reload")
end)

Section("a raid", function()
    local before = #world.wire
    world:Group({ anna, bert, cara }, true)
    world:Advance(3)
    Eq(world:Traffic(nil, before), 3, "messages on becoming a raid")
    Eq(world.wire[#world.wire].chatType, "RAID", "sent to")
    cara:LeaveGroup(); bert:LeaveGroup()
    world:Advance(3)
end)

Section("realms", function()
    -- the same name on another realm, a realm whose name has a space, senders that
    -- arrive without their realm
    local twin = world:AddClient({ name = "Anna", realm = "ArgentDawn", realmTitle = "Argent Dawn", trp3 = {} }):Login():OpenSheet()
    twin:Build("MAGE", "", 7)
    anna:Build("WARRIOR", "", 5)
    world:Group({ anna, bert, twin })
    world:Advance(3)
    local first, second = bert.addon:GetCachedStats("Anna-Realm"), bert.addon:GetCachedStats("Anna-ArgentDawn")
    Check(first and second and first ~= second, "two Annas are kept apart")
    Has(Synced(anna, bert, "Anna of this realm"), "Warrior", "Anna of this realm")
    Has(Synced(twin, bert, "Anna of the other realm"), "Mage", "Anna of the other realm")
    Synced(bert, twin, "across realms"); Synced(anna, twin, "across realms")
    Eq(twin.addon:GetCachedStats(twin.full), nil, "a client keeps no copy of itself")
    world.bareSenders = true
    bert.addon:TakeDamage(2); twin.addon:TakeDamage(2)
    world:Advance(3)
    Synced(bert, anna, "sender without a realm"); Synced(twin, anna, "sender with a realm")
    Eq(anna.addon:GetCachedStats("Bert"), nil, "nothing is kept under a bare name")
    world.bareSenders = false
    -- for a moment after login the realm isn't known: nothing is kept under half a name
    local early = world:AddClient({ name = "Dora" }):Login({ realmLate = true })
    world:Join(early, anna)
    world:Advance(3)
    Eq(early.addon:GetCachedStats("Bert-"), nil, "nothing is kept under a name without its realm")
    early:RealmKnown()
    bert.addon:Heal(1)
    world:Advance(3)
    Synced(bert, early, "once the realm is known")
    early:Logout(); twin:Logout()
end)

Section("the game blocks addon messages", function()
    world:Group({ anna, bert })
    world:Advance(40)
    local before = #world.wire
    anna.lockdown = true
    anna.addon:TakeDamage(1)
    bert:Hover(anna)
    world:Advance(3)
    Eq(world:Traffic(anna, before), 0, "nothing is sent, also no answer")
    anna.lockdown = false
    bert:Hover(nil)
end)

world:CheckClean("share")
Summary("t-sync-share")
