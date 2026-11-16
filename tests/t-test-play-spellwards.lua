-- Spells cast on yourself that change your numbers while they last
-- (Data/SpellWardEffects.lua, Data/SpellWardBoons.lua, Data/SpellWardWeapons.lua):
-- Armor Class, hit points, temporary hit points, speeds, dice and advantage on rolls,
-- and weapon attacks.
dofile(ARG3 .. "/t-test-play-lib.lua")

local function Dice(from)
    local list = {}
    for i = (from or 0) + 1, #ROLLED do list[#list + 1] = ROLLED[i].sides end
    return table.concat(list, ",")
end
-- Casts the spell on yourself: picks "Yourself" (with that option) when asked.
local function OnSelf(spell, option)
    MENU = false
    RPSheet:CastSpell(spell)
    if MENU then Click(MENU, option or "Yourself") end
end
local function Refill()
    for _, tracker in ipairs(RPSheet:GetTrackers()) do if tracker.kind == "slot" then tracker.set(tracker.max) end end
end

Section("Armor Class", function()
    local sheet = Build("MAGE", "", 11, { base = { STR = 10, DEX = 16, CON = 14, INT = 16, WIS = 10, CHA = 10 } })
    sheet.armor = "NONE"
    Eq(RPSheet:AC(), 13, "10 + Dexterity without armor")
    OnSelf(Learn("Mage Armor"))
    Eq(RPSheet:AC(), 16, "Mage Armor: 13 + Dexterity")
    Check(Passive("Mage Armor (spell)") ~= nil, "its passive is on")
    OnSelf(Learn("Shield"))
    Eq(RPSheet:AC(), 21, "Shield adds 5")
    Passive("Shield (spell)").enabled = false
    ns.ApplyClassFeatures(sheet)
    Eq(RPSheet:AC(), 16, "clicked off, the 5 are gone")
    sheet.armor = R.ARMOR_ORDER and R.ARMOR_ORDER[2] or sheet.armor
    Check(RPSheet:AC() ~= 16 or sheet.armor == "NONE", "in armor Mage Armor no longer counts")
    sheet.armor = "NONE"
    Refill()
    OnSelf(Learn("Haste"))
    Eq(RPSheet:AC(), 18, "Haste: +2")
    Eq(RPSheet:Speed(), 60, "Haste doubles the speed")
    Eq(RPSheet:ResolveMode("DEX save"), "ADV", "and gives advantage on Dexterity saves")
    RPSheet:EndWards(nil, true)
    Eq(RPSheet:AC(), 16, "concentration ends: Haste's bonus goes, Mage Armor stays")
    Build("DRUID", "", 5)
    OnSelf(Learn("Barkskin"))
    Check(RPSheet:AC() >= 17, "Barkskin: at least 17")
end)

Section("hit points", function()
    Build("PRIEST", "", 5)
    local max = RPSheet:MaxHP()
    RPSheet:State().hp = max
    RPSheet.castLevel = 3
    OnSelf(Learn("Aid"))
    Eq(RPSheet:MaxHP(), max + 10, "Aid with a 3rd-level slot: 10 more maximum hit points")
    Eq(HP(), max + 10, "and as many current ones")
    Said("10 hit points more", "the casting says so")
    RPSheet:EndWards(8)
    Eq(RPSheet:MaxHP(), max, "a long rest's eight hours end it")
    Build("WARLOCK", "", 5)
    RPSheet:State().tempHP = 0
    OnSelf(Learn("Armor of Agathys"))
    Check((RPSheet:State().tempHP or 0) >= 5, "Armor of Agathys: temporary hit points")
    local pact
    for _, tracker in ipairs(RPSheet:GetTrackers()) do if tracker.kind == "slot" then pact = tracker end end
    Eq(RPSheet:State().tempHP, 5 * pact.level, "5 for each level of the slot")
    Build("MAGE", "", 11)
    max = RPSheet:MaxHP()
    RPSheet:AddItem("Jeweled bowl (1000 gp)", 1)
    Rolls(4, 6)
    OnSelf(Learn("Heroes' Feast"))
    Eq(RPSheet:MaxHP(), max + 10, "Heroes' Feast: the 2d10 rolled raise the maximum")
end)

Section("speeds", function()
    Build("MAGE", "", 7)
    OnSelf(Learn("Longstrider"))
    Eq(RPSheet:Speed(), 40, "Longstrider: +10 feet")
    OnSelf(Learn("Fly"))
    Eq(RPSheet:MoveSpeed("fly"), 60, "Fly: a flying speed of 60")
    OnSelf(Learn("Spider Climb"))
    Eq(RPSheet:MoveSpeed("climb"), 40, "Spider Climb: climbing as fast as walking")
    Check(RPSheet:MoveSpeed("fly") == nil, "Fly ended with concentration")
end)

Section("dice and advantage on rolls", function()
    Build("PRIEST", "", 5)
    RPSheet:AddItem("Emblem", 1)
    OnSelf(Learn("Bless"))
    local at = #ROLLED
    Rolls(10, 3)
    RPSheet:RollCheck("WIS save", 2, nil, false)
    Eq(Dice(at), "20,4", "Bless adds a d4 to a save")
    Said("1d4 Bless (spell)", "and names it")
    at = #ROLLED
    RPSheet:RollCheck("Athletics", 2, nil, false)
    Eq(Dice(at), "20", "but not to a check")
    RPSheet:EndWards(nil, true)
    OnSelf(Learn("Guidance"), "Stealth")
    at = #ROLLED
    RPSheet:RollCheck("Stealth", 2, nil, false)
    Eq(Dice(at), "20,4", "Guidance adds a d4 to the chosen skill")
    RPSheet:EndWards(nil, true)
    Refill()
    OnSelf(Learn("Enhance Ability"), "Strength")
    Eq(RPSheet:ResolveMode("Athletics"), "ADV", "Enhance Ability: advantage on Strength checks")
    Eq(RPSheet:ResolveMode("Stealth"), nil, "and only those")
    OnSelf(Learn("Enlarge/Reduce"), "reduced")
    Eq(RPSheet:ResolveMode("STR save"), "DIS", "reduced: disadvantage on Strength saves")
    Build("MAGE", "", 17)
    OnSelf(Learn("Glibness"))
    Rolls(3)
    RPSheet:RollCheck("Persuasion", 2, nil, false)
    Said("counts as 15", "Glibness: a low roll counts as 15")
    Build("PRIEST", "", 5)
    OnSelf(Learn("Pass without Trace"))
    Check(RPSheet:Bonus("SKILL:Stealth") >= 10, "Pass without Trace: +10 to Stealth")
end)

Section("weapons", function()
    local sheet = Build("DRUID", "", 5, { base = { STR = 8, DEX = 10, CON = 14, INT = 10, WIS = 16, CHA = 10 } })
    sheet.weapons = { { name = "Staff", base = "Quarterstaff", stat = "STR", dice = 1, sides = 6, proficient = true } }
    ns.Util.NormalizeList(sheet.weapons, R.TEMPLATES.weapon)
    local staff = sheet.weapons[1]
    Eq(RPSheet:WeaponStat(staff), "STR", "a quarterstaff goes by Strength")
    OnSelf(Learn("Shillelagh"))
    Eq(RPSheet:WeaponStat(staff), "WIS", "Shillelagh: by Wisdom")
    local count, sides = RPSheet:WeaponDice(staff)
    Eq(sides, 10, "a d10 at level 5")
    Build("MAGE", "", 5)
    sheet = RPSheet:Sheet()
    sheet.weapons = { { name = "Sword", base = "Longsword", stat = "STR", dice = 1, sides = 8, proficient = true } }
    ns.Util.NormalizeList(sheet.weapons, R.TEMPLATES.weapon)
    local sword = sheet.weapons[1]
    local plain = RPSheet:WeaponStyle(sword)
    RPSheet.castLevel = 3
    OnSelf(Learn("Magic Weapon"))
    Eq((RPSheet:WeaponStyle(sword)), plain + 2, "Magic Weapon with a 3rd-level slot: +2")
    RPSheet:CastSpell(Learn("True Strike"))
    Eq(RPSheet:WeaponStat(sword), "INT", "True Strike: the next attack uses Intelligence")
    local at = #ROLLED
    Rolls(15)
    RPSheet:Attack(nil, {})
    Eq(Dice(at), "20,8,6", "the attack, its die and True Strike's d6")
    Eq(RPSheet:WeaponStat(sword), "STR", "only that attack")
    Build("PALADIN", "", 9)
    sheet = RPSheet:Sheet()
    sheet.weapons = { { name = "Bow", base = "Longbow", stat = "DEX", dice = 1, sides = 8, proficient = true } }
    ns.Util.NormalizeList(sheet.weapons, R.TEMPLATES.weapon)
    OnSelf(Learn("Crusader's Mantle"))
    at = #ROLLED
    RPSheet:Attack(nil, {})
    Eq(Dice(at), "20,8,4", "Crusader's Mantle adds a d4 to a ranged hit too")
end)

Section("advantage used up by one roll", function()
    Build("PRIEST", "", 5)
    OnSelf(Learn("Guided Prayer"))
    Eq(RPSheet:ResolveMode("attack"), "ADV", "Guided Prayer: advantage on the next attack")
    RPSheet:RollTest("ADV", function() end)
    ns.ApplyClassFeatures(RPSheet:Sheet())
    Eq(RPSheet:ResolveMode("attack"), nil, "used up by that attack")
end)

Section("shapes", function()
    local sheet = Build("DRUID", "Circle of the Moon", 5)
    RPSheet:State().tempHP = 0
    RPSheet:CastSpell(Learn("Feral Prowl"))
    Check(MENU and MENU.title == "Feral Prowl: which form?", "Feral Prowl asks which form")
    Click(MENU, "Cat Form")
    Check(Passive("Cat Form active").enabled, "the Cat Form is on")
    Eq(RPSheet:State().tempHP, 15, "with the Moon's temporary hit points")
    Check(RPSheet:State().conditions.Invisible, "and invisible")
    Check(RPSheet:Form() ~= nil, "the sheet uses the form's numbers")
    Build("DRUID", "", 17)
    local ac = RPSheet:AC()
    OnSelf(Learn("Tree of Life"))
    Eq(RPSheet:AC(), ac + 2, "Tree of Life: +2 Armor Class")
    Eq(RPSheet:State().tempHP, 10, "and 10 temporary hit points")
end)

Summary("t-test-play-spellwards")
