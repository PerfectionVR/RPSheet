-- Eldritch Invocations that let a Warlock cast a spell without a slot
-- (Sheet/InvocationSpells.lua puts the spell on the list and casts it).
--   spell    the spell
--   once     true: once per long rest without a slot, then with slots
--   maxDice  true: the casting without a slot takes each die's highest number
--   note     when it can be cast that way, said on the spell's row
local _, ns = ...
local R = ns.Rules

R.INVOCATION_SPELLS = {
    ["Armor of Shadows"] = { spell = "Mage Armor", note = "on yourself" },
    ["Ascendant Step"] = { spell = "Levitate", note = "on yourself" },
    ["Fiendish Vigor"] = { spell = "False Life", maxDice = true, note = "on yourself, with the highest number on each die" },
    ["Gift of the Depths"] = { spell = "Water Breathing", once = true },
    ["Legion Summoning"] = { spell = "Planar Binding", once = true, note = "to bind a Felguard, Felhound, Incubus or Succubus you summon with it" },
    ["Mask of Many Faces"] = { spell = "Disguise Self" },
    ["Master of Myriad Forms"] = { spell = "Alter Self" },
    ["Misty Visions"] = { spell = "Silent Image" },
    ["One with Shadows"] = { spell = "Invisibility", note = "on yourself, while in dim light or darkness" },
    ["Otherworldly Leap"] = { spell = "Jump", note = "on yourself" },
    ["Visions of Distant Realms"] = { spell = "Arcane Eye" },
    ["Whispers of the Grave"] = { spell = "Speak with Dead" },
    ["Pact of the Chain"] = { spell = "Find Familiar", note = "as a Magic action, with the special forms to choose from" },
    ["Pact of the Legion"] = { spell = "Find Familiar", note = "as a Magic action, summoning a Fel Imp" },
}
