-- The boxes the damage menu shows for the character's own features that change damage
-- (rules in Actions/DamageSteps.lua). Each is only there when the character has the
-- feature and can use it now: a reaction that is spent, or a feature that doesn't work
-- while incapacitated, is left out. The answers fill `how`, which goes with the type.
local _, ns = ...
local UI = ns.UI

local function Box(root, text, title, body, isOn, toggle)
    local box = root:CreateCheckbox(text, isOn, toggle)
    box:SetTooltip(function(tooltip)
        GameTooltip_SetTitle(tooltip, title)
        GameTooltip_AddNormalLine(tooltip, body, true)
    end)
end

-- Adds the boxes to the menu `root`; `how` is filled as they are ticked.
function UI.AddDamageReactions(addon, root, how)
    local can = addon:DamageOptions()
    if can.armor then
        how.attack = true -- most such damage comes from an attack: the box starts ticked
        Box(root, ("Hit by an attack (Heavy Armor Master: %d off)"):format(can.armor), "Heavy Armor Master",
            ("While you wear heavy armor, bludgeoning, piercing and slashing damage from an attack that hits you is reduced by %d (your proficiency bonus). Untick this for damage that came from something else, such as a fall or a saving throw."):format(can.armor),
            function() return how.attack end, function() how.attack = not how.attack end)
    end
    if can.evasion then
        Box(root, "A Dexterity save for half: passed (Evasion: none)", "Evasion",
            "Tick when the damage allowed a Dexterity save for half and you passed it: you take none of it. Type the damage as rolled.",
            function() return how.dexSave == "pass" end,
            function() how.dexSave = how.dexSave ~= "pass" and "pass" or nil; how.dodge = nil end)
        Box(root, "A Dexterity save for half: failed (Evasion: half)", "Evasion",
            "Tick when the damage allowed a Dexterity save for half and you failed it: you take half. Type the damage as rolled.",
            function() return how.dexSave == "fail" end,
            function() how.dexSave = how.dexSave ~= "fail" and "fail" or nil; how.dodge = nil end)
    end
    if can.dodge then
        Box(root, "Uncanny Dodge: halve it (uses your reaction)", "Uncanny Dodge",
            "Only when an attacker you can see hits you with an attack roll: your reaction halves the damage (rounded down). Your reaction is spent until you say it is back, at the next initiative or after a rest.",
            function() return how.dodge end,
            function() how.dodge = not how.dodge or nil; how.hunter = nil; how.dexSave = nil end)
    end
    if can.hunter then
        Box(root, "Superior Hunter's Defense: resist it (uses your reaction)", "Superior Hunter's Defense",
            "Your reaction gives you resistance to this damage and to any other of the same type until the end of the turn: a passive keeps it until you click it off. Not for damage without a type.",
            function() return how.hunter end,
            function() how.hunter = not how.hunter or nil; how.dodge = nil end)
    end
    if can.nose then
        if how.nose == nil then how.nose = addon:State().noseReady == true end
        Box(root, ("Nose for Trouble: first damage since initiative (%d off)"):format(can.nose), "Nose for Trouble",
            "The first damage you take after rolling initiative is reduced by your level. The box is ticked by itself after you roll initiative on the sheet, and the first damage uses it up.",
            function() return how.nose end, function() how.nose = not how.nose end)
    end
end
