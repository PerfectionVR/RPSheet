-- Taking a rest back: "/sheet undo" puts the play state back as it was just before the
-- last rest, tells the channel, and the group sees the old numbers again; it works
-- until the next roll, spell, damage or rest, and never over a change to the character.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local anna = world:AddClient({ name = "Anna" }):Login():OpenSheet()
local bert = world:AddClient({ name = "Bert" }):Login():OpenSheet()
world:Advance(5)
anna.opened, anna.ns.Wizard.draft = {}, nil
anna:Build("WARRIOR", "Champion", 8, { extras = { { class = "MAGE", level = 3, subclass = "Evoker" } } })
bert:Build("MAGE", "", 3)
world:Group({ anna, bert })
world:Advance(4)
local addon = anna.addon
addon.db.profile.channel = "PARTY"

local function Printed(from)
    local list = {}
    for i = from + 1, #anna.printed do list[#list + 1] = anna.printed[i] end
    return table.concat(list, "\n")
end
local function Said(from)
    local list = {}
    for i = from + 1, #anna.said do list[#list + 1] = anna.said[i].text end
    return table.concat(list, "\n")
end
local function Tracker(label)
    for _, tracker in ipairs(addon:GetTrackers()) do
        if tracker.label == label then return tracker end
    end
end
-- Everything a rest touches, as one line of text.
local function Picture()
    local state, parts = addon:State(), {}
    for _, tracker in ipairs(addon:GetTrackers()) do parts[#parts + 1] = ("%s %s/%s"):format(tracker.label, tostring(tracker.get()), tostring(tracker.max)) end
    local conditions = {}
    for name in pairs(state.conditions) do conditions[#conditions + 1] = name end
    table.sort(conditions)
    parts[#parts + 1] = "conditions " .. table.concat(conditions, ",")
    parts[#parts + 1] = ("temp %d exhaustion %d death %d/%d inspiration %s"):format(state.tempHP, state.exhaustion, state.deathPass, state.deathFail, tostring(state.inspiration))
    parts[#parts + 1] = ("marks %s %s %s %s"):format(tostring(state.prepareClosed), tostring(state.prepareSwap), tostring(state.cantripSwap), tostring(state.petMasteryChanged))
    local on = {}
    for _, passive in ipairs(addon:Sheet().passives) do if passive.enabled then on[#on + 1] = passive.name end end
    table.sort(on)
    parts[#parts + 1] = "on " .. table.concat(on, ",")
    return table.concat(parts, "; ")
end
-- A character in the middle of a day: wounded, things spent, a ward running.
local function Spend()
    local state = addon:State()
    for _, tracker in ipairs(addon:GetTrackers()) do
        if tracker.kind ~= "hp" and tracker.label ~= "HP" then tracker.set(0) end
    end
    state.hp, state.tempHP, state.exhaustion = 7, 6, 2
    state.conditions.Concentrating, state.conditions.Poisoned = true, true
    state.deathPass, state.deathFail = 2, 1
    state.prepareClosed, state.prepareSwap = true, true
    addon:StartWard("Protection from Poison", 1)
    addon:ClampState()
end
local function BertSees() local copy = bert.addon:GetCachedStats(anna.full) return copy and copy.trackers[1] and copy.trackers[1][2] end

Section("a long rest taken back", function()
    Spend()
    addon:QueueBroadcast()
    world:Advance(3)
    local before, printed, said = Picture(), #anna.printed, #anna.said
    Eq(BertSees(), 7, "the group sees the wounded character")
    anna:Do(addon.LongRest, addon)
    world:Advance(3)
    Check(Picture() ~= before, "the rest changed things")
    Eq(addon:State().hp, addon:MaxHP(), "hit points are full")
    Eq(BertSees(), addon:MaxHP(), "and the group sees that")
    Check(Said(said):find("Anna finishes a long rest.", 1, true), "the rest is announced: " .. Said(said))
    Check(Printed(printed):find("/sheet undo", 1, true), "the player is told how to take it back: " .. Printed(printed))
    Eq(bert.printed[#bert.printed] and bert.printed[#bert.printed]:find("/sheet undo", 1, true), nil, "nobody else is")

    said = #anna.said
    Check(anna:Slash("/sheet undo"), "the command exists")
    world:Advance(3)
    Eq(Picture(), before, "everything is as before the rest")
    Check(Said(said):find("Anna takes back the long rest", 1, true), "the group is told on the same channel: " .. Said(said))
    Eq(bert.chat[#bert.chat] and bert.chat[#bert.chat].text:find("takes back the long rest", 1, true) ~= nil, true, "and reads it")
    Eq(BertSees(), 7, "and sees the old hit points again")
    -- only once
    printed, said = #anna.printed, #anna.said
    anna:Slash("/sheet undo")
    world:Advance(1)
    Check(Printed(printed):find("There is no rest to take back", 1, true), "a second undo says there is nothing: " .. Printed(printed))
    Eq(#anna.said, said, "and announces nothing")
    Eq(Picture(), before, "and changes nothing")
end)

Section("a short rest taken back", function()
    Spend()
    local before, said = Picture(), #anna.said
    anna:Slash("/sheet short")
    world:Advance(1)
    Check(Said(said):find("finishes a short rest", 1, true), "\"/sheet short\" is a short rest: " .. Said(said))
    Check(Picture() ~= before, "which gave something back")
    Eq(addon:State().hp, 7, "but no hit points")
    Check(addon:UndoRest(), "it can be taken back")
    world:Advance(1)
    Eq(Picture(), before, "everything is as before it")
    Check(Said(said):find("takes back the short rest", 1, true), "and the group is told")
    -- the other spelling
    said = #anna.said
    anna:Slash("/sheet rest short")
    world:Advance(1)
    Check(Said(said):find("finishes a short rest", 1, true), "\"/sheet rest short\" too")
    Check(addon:UndoRest(), "taken back")
    world:Advance(1)
    Eq(Picture(), before, "as before")
end)

Section("until the next roll, spell, damage or rest", function()
    local function Settled(label, act)
        Spend()
        anna:Do(addon.LongRest, addon)
        world:Advance(1)
        local after = nil
        anna:Do(act)
        world:Advance(4)
        after = Picture()
        local printed = #anna.printed
        Eq(addon:UndoRest(), false, label .. ": the rest can't be taken back any more")
        Check(Printed(printed):find("no rest to take back", 1, true), label .. ": and the player is told")
        Eq(Picture(), after, label .. ": nothing changed")
    end
    Settled("a roll", function() addon:RollCheck("Stealth", 5) end)
    Settled("a hit die", function() addon:State().hp = 10; addon:SpendHitDie() end)
    Settled("damage", function() addon:TakeDamage(3, "fire") end)
    Settled("healing", function() addon:State().hp = 10; addon:Heal(3) end)
    Settled("a condition", function() addon:ToggleCondition("Prone") end)
    Settled("a spell", function()
        for _, spell in ipairs(addon:Sheet().spells) do
            if spell.level and spell.level >= 1 then return addon:CastSpell(spell) end
        end
        addon:Announce("casts something.")
    end)
    Settled("a roll on Self only", function()
        addon.db.profile.channel = "SELF"
        addon:RollCheck("Stealth", 5)
        addon.db.profile.channel = "PARTY"
    end)
    -- another rest: only that one is taken back
    Spend()
    local first = Picture()
    anna:Do(addon.ShortRest, addon)
    local second = Picture()
    anna:Do(addon.LongRest, addon)
    Check(addon:UndoRest(), "after two rests the last one is taken back")
    Eq(Picture(), second, "to where the first rest left things")
    Eq(addon:UndoRest(), false, "and the first one stays")
    Check(Picture() ~= first, "as it was")
    world:Advance(3)
end)

Section("never over a change to the character", function()
    local function Changed(label, act, still)
        Spend()
        anna:Do(addon.LongRest, addon)
        world:Advance(1)
        anna:Do(act)
        world:Advance(1)
        local printed = #anna.printed
        Eq(addon:UndoRest(), false, label .. ": the rest can't be taken back")
        Check(Printed(printed):find("was changed since the rest", 1, true) or Printed(printed):find("no rest to take back", 1, true), label .. ": and the player is told why: " .. Printed(printed))
        Check(still(), label .. ": the change is still there")
        Eq(addon:State().hp, addon:MaxHP(), label .. ": and so is the rest")
    end
    Changed("an item added", function() addon:AddItem("Rope", 1) end, function()
        for _, item in ipairs(addon:Sheet().items) do if item.name == "Rope" then return true end end
    end)
    Changed("coins", function() addon:Sheet().coins.gp = (addon:Sheet().coins.gp or 0) + 5 end, function() return addon:Sheet().coins.gp >= 5 end)
    Changed("an edit under Customize", function() addon:Sheet().alignment = "Lawful Good"; addon:SheetChanged() end, function() return addon:Sheet().alignment == "Lawful Good" end)
    Changed("a level", function() addon:SetLevel(addon:Sheet().level + 1) end, function() return addon:Sheet().level == 9 end)
    -- another character on the sheet, or another sheet altogether
    Spend()
    anna:Do(addon.LongRest, addon)
    anna:Build("ROGUE", "", 4)
    Eq(addon:UndoRest(), false, "a rest of the character before is not taken back onto a new one")
    Eq(addon:Sheet().class, "ROGUE", "which stays")
    -- while a roll is still on its way
    anna:Build("WARRIOR", "Champion", 8)
    Spend()
    anna:Do(addon.LongRest, addon)
    addon.busy = true
    local printed = #anna.printed
    Eq(addon:UndoRest(), false, "not in the middle of a roll")
    Check(Printed(printed):find("Wait for the roll", 1, true), "said so")
    addon.busy = false
    Check(addon:UndoRest(), "afterwards it can")
    world:Advance(3)
end)

Section("what is kept is not saved", function()
    Spend()
    anna:Do(addon.LongRest, addon)
    anna:Reload():OpenSheet()
    addon = anna.addon
    local text = {}
    local function Walk(value, depth)
        if type(value) ~= "table" or depth > 12 then return end
        for key, inner in pairs(value) do
            if type(key) == "string" then text[key] = true end
            Walk(inner, depth + 1)
        end
    end
    Walk(anna.saved, 0)
    Check(not text.kept and not text.before and not text.after and not text.undo, "nothing of the undo is in the saved variables")
    Eq(addon:UndoRest(), false, "after a reload there is nothing to take back")
    Eq(addon:State().hp, addon:MaxHP(), "the rest stands")
    -- the channel the undo is announced on is the one in use then; alone it is shown to the player only
    anna:LeaveGroup()
    world:Advance(3)
    addon.db.profile.channel = "PARTY"
    addon:State().hp = 5
    anna:Do(addon.LongRest, addon)
    local printed, said = #anna.printed, #anna.said
    Check(addon:UndoRest(), "taken back outside a party")
    Eq(#anna.said, said, "nothing is sent to a party that isn't there")
    Check(Printed(printed):find("takes back the long rest", 1, true) and Printed(printed):find("only you see this", 1, true), "the line is shown to the player: " .. Printed(printed))
    Eq(addon:State().hp, 5, "hit points as before the rest")
end)

world:CheckClean("rest")
Summary("t-sync-rest")
