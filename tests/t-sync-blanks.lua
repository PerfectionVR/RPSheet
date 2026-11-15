-- A sheet that holds no character is not saved, and one that holds anything is never
-- thrown away: made, wizard skipped, half made by hand, from an old version, and the
-- blank entries earlier versions left behind for every key they looked at.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local function Sheets(saved) return saved and saved.global and saved.global.sheets or {} end
local function Keys(saved)
    local list = {}
    for key in pairs(Sheets(saved)) do list[#list + 1] = key end
    table.sort(list)
    return table.concat(list, " ")
end
local function CloseWizard(client) client.opened.RPSheetWizard = nil; client.ns.Wizard.draft = nil end
local function Offered(client) return client.opened.RPSheetWizard == true and client.ns.Wizard.draft ~= nil end

Section("a key that was only looked at", function()
    local world = NewWorld()
    local anna = world:AddClient({ name = "Anna" }):Login()
    world:Advance(5)
    Check(Offered(anna), "the wizard is offered")
    CloseWizard(anna)
    -- looked at in every way that doesn't make a character
    anna:Do(anna.addon.Populate, anna.addon)
    anna:Do(anna.ns.RebuildOptions)
    anna:Do(anna.addon.GetStatData, anna.addon)
    anna:Do(anna.ns.OpenWizard)
    world:Advance(1)
    CloseWizard(anna)
    Check(anna.ns.IsBlankState(anna.addon:State()), "the sheet in use is blank")
    anna:Logout()
    Eq(Keys(anna.saved), "", "nothing is saved for it")
    anna:Login()
    Eq(anna.addon:Sheet().class, "", "the next login starts blank again")
    Eq(anna.addon:Sheet().level, 1, "with a sheet in shape")
    world:Advance(5)
    Check(Offered(anna), "and is offered the wizard again")
    CloseWizard(anna)
    anna:Logout()
    Eq(Keys(anna.saved), "", "still nothing saved")
    world:CheckClean("looked at")
end)

Section("what earlier versions left behind", function()
    -- a login of a version without the clean-up: the blank entry is saved
    local world = NewWorld()
    local anna = world:AddClient({ name = "Anna", trp3 = { profiles = { p1 = { profileName = "One" }, p2 = { profileName = "Two" }, p3 = { profileName = "Three" } }, current = "p1" } }):Login()
    world:Advance(5)
    CloseWizard(anna)
    anna:Build("WARRIOR", "", 5)
    anna.addon:TakeDamage(7)
    anna:Do(anna.env.TRP3_API.profile.selectProfile, "p2")
    world:Advance(5)
    CloseWizard(anna)
    anna:Do(anna.env.TRP3_API.profile.selectProfile, "p3")
    world:Advance(5)
    CloseWizard(anna)
    anna.ns.DropBlankSheets = function() return 0 end
    anna:Logout()
    Eq(Keys(anna.saved), "trp3:p1 trp3:p2 trp3:p3", "an earlier version saved an entry for every profile it saw")
    local bytes = 0
    local function Size(value)
        if type(value) ~= "table" then bytes = bytes + #tostring(value) + 1 return end
        for key, inner in pairs(value) do bytes = bytes + #tostring(key) + 4; Size(inner) end
    end
    Size(Sheets(anna.saved)["trp3:p2"])
    Check(bytes > 300, "and a blank one is not nothing: about " .. bytes .. " bytes")
    -- the same for an alt, and for the character's own key of a day Total RP 3 started late
    local sheets = Sheets(anna.saved)
    sheets["char:Alt-Realm"] = CopyTable(sheets["trp3:p2"])
    sheets["char:Anna-Realm"] = CopyTable(sheets["trp3:p3"])
    sheets["trp3:gone"] = { hp = 7, hitDice = 1, sheet = { levels = {} } } -- as a much older version left it
    -- this version: one login and logout, on a profile that has no character
    anna.trp3.current = "p3"
    anna:Login()
    Eq(anna.addon:Sheet().class, "", "the blank profile is blank")
    anna:Logout()
    Eq(Keys(anna.saved), "trp3:p1", "after one logout only the character is left")
    anna.trp3.current = "p1"
    anna:Login()
    Eq(anna.addon:Sheet().class, "WARRIOR", "which is whole")
    Eq(anna.addon:State().hp, anna.addon:MaxHP() - 7, "with its hit points")
    world:Advance(5)
    Check(not Offered(anna), "and no wizard")
    world:CheckClean("left behind")
end)

Section("what is never thrown away", function()
    local world = NewWorld()
    -- Each of these is done to a blank sheet by hand; after a reload it must still be there.
    local changes = {
        { "the wizard was skipped", function(state) state.created = true end, function(state) return state.created == true end },
        { "a class picked by hand", function(state) state.sheet.class = "MAGE" end, function(state) return state.sheet.class == "MAGE" end },
        { "a species", function(state) state.sheet.species = "HUMAN" end, function(state) return state.sheet.species == "HUMAN" end },
        { "a level", function(state) state.sheet.level = 4 end, function(state) return state.sheet.level == 4 end },
        { "an ability score", function(state) state.sheet.base.STR = 15 end, function(state) return state.sheet.base.STR == 15 end },
        { "a bonus", function(state) state.sheet.bonus.CHA = 1 end, function(state) return state.sheet.bonus.CHA == 1 end },
        { "an alignment", function(state) state.sheet.alignment = "Chaotic Good" end, function(state) return state.sheet.alignment == "Chaotic Good" end },
        { "armor", function(state) state.sheet.armor = "LEATHER" end, function(state) return state.sheet.armor == "LEATHER" end },
        { "a skill", function(state) state.sheet.skills.Stealth = 1 end, function(state) return state.sheet.skills.Stealth == 1 end },
        { "a language", function(state) state.sheet.languages.Common = true end, function(state) return state.sheet.languages.Common == true end },
        { "a weapon", function(state) state.sheet.weapons[1] = { name = "Stick", dice = 1, sides = 4 } end, function(state) return state.sheet.weapons[1] and state.sheet.weapons[1].name == "Stick" end },
        { "a passive", function(state) state.sheet.passives[1] = { name = "Lucky", desc = "x" } end, function(state) return state.sheet.passives[1] and state.sheet.passives[1].name == "Lucky" end },
        { "an item", function(state) state.sheet.items[1] = { name = "Rope" } end, function(state) return state.sheet.items[1] and state.sheet.items[1].name == "Rope" end },
        { "a coin", function(state) state.sheet.coins.gp = 3 end, function(state) return state.sheet.coins.gp == 3 end },
        { "renown", function(state) state.sheet.renown.Stormwind = 5 end, function(state) return state.sheet.renown.Stormwind == 5 end },
        { "a hit point adjustment", function(state) state.sheet.hpAdjust = 2 end, function(state) return state.sheet.hpAdjust == 2 end },
        { "a condition", function(state) state.conditions.Prone = true end, function(state) return state.conditions.Prone == true end },
        { "exhaustion", function(state) state.exhaustion = 2 end, function(state) return state.exhaustion == 2 end },
        { "temporary hit points", function(state) state.tempHP = 4 end, function(state) return state.tempHP == 4 end },
        { "inspiration", function(state) state.inspiration = true end, function(state) return state.inspiration == true end },
        { "a field this version doesn't know", function(state) state.sheet.somethingNew = "kept" end, function(state) return state.sheet.somethingNew == "kept" end },
    }
    for index, change in ipairs(changes) do
        local client = world:AddClient({ name = "Half" .. index }):Login()
        world:Advance(4)
        CloseWizard(client)
        change[2](client.addon:State())
        Check(not client.ns.IsBlankState(client.addon:State()), change[1] .. ": not blank")
        client:Reload()
        Eq(Keys(client.saved), "char:Half" .. index .. "-Realm", change[1] .. ": saved")
        Check(change[3](client.addon:State()), change[1] .. ": still there after a reload")
        client:Reload()
        Check(change[3](client.addon:State()), change[1] .. ": and after another")
        client:Logout()
    end
    world:CheckClean("half made")

    -- a sheet of the first version of the addon (another shape altogether)
    local old = world:AddClient({ name = "Olaf" }):Login()
    old:Logout()
    old.saved = old.saved or {}
    old.saved.global = { sheets = { ["char:Olaf-Realm"] = { initialized = true, hp = 9, resource = 2, sheet = {
        version = 1, size = "LARGE", armor = "MAIL", shield = "SMALL", resourceName = "Rage", resourceStat = "STR",
        base = { STR = 15, DEX = 10, CON = 14, INT = 8, WIS = 10, CHA = 8 } } } } }
    old:Login()
    Eq(old.addon:Sheet().armor, "CHAINMAIL", "a sheet of the first version is converted")
    Eq(old.addon:Sheet().base.STR, 15, "with its scores")
    old:Reload()
    Eq(Keys(old.saved), "char:Olaf-Realm", "and kept")
    Eq(old.addon:Sheet().base.STR, 15, "whole")
    -- such a sheet under a key that isn't looked at this session stays as it is
    old:Logout()
    local sheets = Sheets(old.saved)
    sheets["char:Other-Realm"] = { initialized = true, hp = 9, sheet = { version = 1, resourceStat = "STR", base = { STR = 12 } } }
    sheets["trp3:odd1"] = "not a sheet"
    sheets["trp3:odd2"] = { sheet = "not a sheet either" }
    sheets["trp3:odd3"] = { sheet = { class = 5 } }
    sheets["trp3:made"] = { created = true }
    sheets["trp3:classonly"] = { sheet = { class = "ROGUE" } }
    local olaf = old:Login()
    olaf:Logout()
    Eq(Keys(old.saved), "char:Olaf-Realm char:Other-Realm trp3:classonly trp3:made trp3:odd1 trp3:odd2 trp3:odd3",
        "entries of other keys that hold anything, or can't be read, are left alone")
    Eq(Sheets(old.saved)["char:Other-Realm"].sheet.resourceStat, "STR", "the unconverted one untouched")
    world:CheckClean("old")
end)

Section("Total RP 3 that starts late, day after day", function()
    local world = NewWorld()
    local trp3 = { profiles = { main = { profileName = "Main" }, alt = { profileName = "Alt" } }, current = "main", ready = false }
    local dora = world:AddClient({ name = "Dora", trp3 = trp3 }):Login()
    Eq(dora.addon.sheetKey, "char:Dora-Realm", "before the profile is known the character's own key is used")
    dora:Do(dora.env.TRP3_API.profile.selectProfile, "main")
    world:Advance(4)
    CloseWizard(dora)
    dora:Build("HUNTER", "", 4)
    for day = 1, 3 do
        dora:Logout()
        Eq(Keys(dora.saved), "trp3:main", "day " .. day .. ": only the character is saved, not the key of the first moment")
        trp3.ready, trp3.current = false, day == 2 and "alt" or "main"
        dora:Login()
        Eq(dora.addon:Sheet().class, "", "day " .. day .. ": blank for the moment before the profile is known")
        dora:Do(dora.env.TRP3_API.profile.selectProfile, trp3.current)
        Eq(dora.addon:Sheet().class, day == 2 and "" or "HUNTER", "day " .. day .. ": then the profile's own sheet")
        world:Advance(4)
        Eq(Offered(dora), day == 2, "day " .. day .. ": the wizard only for the profile without a character")
        CloseWizard(dora)
        dora:Do(dora.env.TRP3_API.profile.selectProfile, "main")
        Eq(dora.addon:Sheet().class, "HUNTER", "day " .. day .. ": the character is where it was")
    end
    -- a character made on a day without Total RP 3 stays the character's own when a
    -- profile already has one, also when Total RP 3 is late and the profile has nothing saved
    dora:Logout()
    local kept = dora.trp3
    dora.trp3 = false
    dora:Login()
    world:Advance(4)
    CloseWizard(dora)
    dora:Build("ROGUE", "", 2)
    dora:Logout()
    dora.trp3 = kept
    kept.ready, kept.current = false, "alt"
    dora:Login()
    Eq(dora.addon:Sheet().class, "ROGUE", "the character's own sheet for the first moment")
    dora:Do(dora.env.TRP3_API.profile.selectProfile, "alt")
    Eq(dora.addon:Sheet().class, "", "the empty profile stays empty")
    dora:Logout()
    Eq(Keys(dora.saved), "char:Dora-Realm trp3:main", "and both characters are saved where they were")
    world:CheckClean("late")
end)

Summary("t-sync-blanks")
