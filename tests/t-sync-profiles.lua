-- Which sheet belongs to whom, with the real saved-variables library: a first login,
-- the wizard offer, a reload, two characters on one account, Total RP 3 absent,
-- present, arriving late and switching profile during play, and what the group is
-- told when the profile changes.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local WIZARD = "RPSheetWizard"
local function Class(client) return client.addon:Sheet().class end
local function Offered(client) return client.opened[WIZARD] == true and client.ns.Wizard.draft ~= nil end
local function CloseWizard(client) client.opened[WIZARD] = nil; client.ns.Wizard.draft = nil end
-- The saved sheets that hold a character. (After a reload the table read here is the
-- one in use again, where the key being looked at has its blank entry for as long as
-- the session lasts: counted in BLANKS. That none is written out: t-sync-blanks.lua.)
local BLANKS = 0
local function Keys(saved)
    local list = {}
    for key, state in pairs(saved and saved.global and saved.global.sheets or {}) do
        if state.created or (state.sheet and (state.sheet.class or "") ~= "") then list[#list + 1] = key else BLANKS = BLANKS + 1 end
    end
    table.sort(list)
    return table.concat(list, " ")
end

Section("without Total RP 3", function()
    local world = NewWorld()
    local anna = world:AddClient({ name = "Anna" }):Login()
    Eq(anna.addon.sheetKey, "char:Anna-Realm", "the sheet of a character without Total RP 3")
    Eq(anna.addon:GetLinkedProfileName(), nil, "no linked profile")
    Eq(anna.addon:GetCharacterName(), "Anna", "the name is the character's")
    Eq(Class(anna), "", "a first login starts blank")
    Check(not Offered(anna), "the wizard isn't opened in the first moment")
    world:Advance(4)
    Check(Offered(anna), "the wizard is offered shortly after a first login")
    CloseWizard(anna)
    anna:Fire("GROUP_ROSTER_UPDATE"); world:Advance(10)
    Check(not Offered(anna), "the wizard is offered once")
    anna:Build("WARRIOR", "", 5)
    anna.addon:TakeDamage(7)
    anna.addon.db.char.name = "  Annabel  "
    Eq(anna.addon:GetCharacterName(), "  Annabel  ", "the name from the settings is used as typed")
    anna.addon.db.char.name = "Annabel"
    world:Advance(3)

    anna:Reload()
    Eq(Keys(anna.saved), "char:Anna-Realm", "sheets saved")
    Eq(Class(anna), "WARRIOR", "the character is there after a reload")
    Eq(anna.addon:State().hp, anna.addon:MaxHP() - 7, "with its hit points")
    Eq(anna.addon:GetCharacterName(), "Annabel", "and its name")
    world:Advance(5)
    Check(not Offered(anna), "no wizard for a character that exists")

    -- another character of the same account reads the same saved variables
    anna:Logout()
    local zed = world:AddClient({ name = "Zed", saved = anna.saved }):Login()
    Eq(zed.addon.sheetKey, "char:Zed-Realm", "the second character's sheet")
    Eq(Class(zed), "", "is its own, and blank")
    Eq(zed.addon:GetCharacterName(), "Zed", "its name is its own")
    world:Advance(4)
    Check(Offered(zed), "the wizard is offered to the second character")
    CloseWizard(zed)
    zed:Build("MAGE", "", 3)
    zed:Logout()
    -- the same name on another realm
    local other = world:AddClient({ name = "Anna", realm = "ArgentDawn", realmTitle = "Argent Dawn", saved = zed.saved }):Login()
    Eq(other.addon.sheetKey, "char:Anna-ArgentDawn", "the same name on another realm")
    Eq(Class(other), "", "is another character")
    other:Logout()
    Eq(Keys(other.saved), "char:Anna-Realm char:Zed-Realm", "the characters saved")
    anna.saved = other.saved
    anna:Login()
    Eq(Class(anna), "WARRIOR", "the first character is untouched by the others")
    world:CheckClean("without Total RP 3")
end)

Section("a wizard offer and combat", function()
    local world = NewWorld()
    local anna = world:AddClient({ name = "Anna" })
    anna.combat = true
    anna:Login()
    anna.combat = true
    world:Advance(5)
    Check(not Offered(anna), "no wizard in combat")
    anna.combat = false
    anna:Fire("PLAYER_REGEN_ENABLED")
    world:Advance(1)
    Check(Offered(anna), "it is offered when the fight is over")
    CloseWizard(anna)
    anna.combat = true; anna:Fire("PLAYER_REGEN_DISABLED"); anna.combat = false; anna:Fire("PLAYER_REGEN_ENABLED")
    world:Advance(1)
    Check(not Offered(anna), "and not after every fight")
    world:CheckClean("combat")
end)

Section("with Total RP 3", function()
    local world = NewWorld()
    local profiles = { p1 = { profileName = "Sir Bert", firstName = "Bertram" }, p2 = { profileName = "Bert the Alt", firstName = "" },
        p3 = { profileName = "Odd", firstName = "Bo|cffff0000b\nby" } }
    local bert = world:AddClient({ name = "Bert", trp3 = { profiles = profiles, current = "p1" } }):Login()
    local anna = world:AddClient({ name = "Anna" }):Login()
    Eq(bert.addon.sheetKey, "trp3:p1", "the sheet of the Total RP 3 profile")
    Eq(bert.addon:GetLinkedProfileName(), "Sir Bert", "the linked profile's name")
    Eq(bert.addon:GetCharacterName(), "Bertram", "the name comes from the profile")
    bert.addon.db.profile.useTRP3 = false
    Eq(bert.addon:GetCharacterName(), "Bert", "with that setting off it is the character's")
    bert.addon.db.profile.useTRP3 = true
    world:Advance(4)
    Check(Offered(bert), "the wizard is offered for a profile without a character")
    CloseWizard(bert)
    bert:Build("PALADIN", "", 6)
    bert.addon:TakeDamage(9)
    world:Group({ bert, anna })
    world:Advance(3)
    Check((anna.addon:GetCachedStats(bert.full) or {}).summary:find("Paladin"), "the group has the first profile's character")

    -- switching profile during play (the sheet window is closed)
    local before = #world.wire
    bert:Do(bert.env.TRP3_API.profile.selectProfile, "p2")
    Eq(bert.addon.sheetKey, "trp3:p2", "the sheet follows the profile")
    Eq(Class(bert), "", "a new profile has no character")
    Eq(bert.addon:GetCharacterName(), "Bert", "a profile without a first name falls back to the character's name")
    Eq(bert.addon:GetLinkedProfileName(), "Bert the Alt", "the linked profile's name follows")
    world:Advance(3)
    Check(Offered(bert), "the wizard is offered for the new profile")
    CloseWizard(bert)
    Check(world:Traffic(bert, before) >= 1, "the group is told when the profile changes")
    Eq((anna.addon:GetCachedStats(bert.full) or {}).summary, bert.addon:Summary() or "", "and no longer shows the first profile's character")
    bert:Build("ROGUE", "", 2)
    world:Advance(3)

    bert:Do(bert.env.TRP3_API.profile.selectProfile, "p1")
    Eq(Class(bert), "PALADIN", "back on the first profile its character is back")
    Eq(bert.addon:State().hp, bert.addon:MaxHP() - 9, "with its own hit points")
    world:Advance(3)
    Check(not Offered(bert), "no wizard for a profile that has a character")
    Check((anna.addon:GetCachedStats(bert.full) or {}).summary:find("Paladin"), "the group sees the first profile's character again")
    bert:Do(bert.env.TRP3_API.profile.selectProfile, "p2")
    Eq(Class(bert), "ROGUE", "and the second profile kept its own")
    world:Advance(3)
    Check(not Offered(bert), "the wizard is offered once per profile")

    -- a first name with escape codes in it never reaches chat as such
    bert:Do(bert.env.TRP3_API.profile.selectProfile, "p3")
    world:Advance(3)
    CloseWizard(bert)
    bert.addon.db.profile.channel = "PARTY"
    bert.addon:Announce("waves.")
    world:Advance(1)
    local line = anna.chat[#anna.chat]
    Check(line and Plain(line.text), "an announcement under that name is plain text: " .. tostring(line and line.text))

    bert:Do(bert.env.TRP3_API.profile.selectProfile, "p1")
    world:Advance(3)
    bert:Reload()
    Eq(Keys(bert.saved), "trp3:p1 trp3:p2", "characters saved per profile")
    Eq(bert.addon.sheetKey, "trp3:p1", "after a reload the profile's sheet")
    Eq(Class(bert), "PALADIN", "is the same character")
    world:CheckClean("with Total RP 3")
end)

Section("Total RP 3 installed later, or ready late", function()
    local world = NewWorld()
    -- a character made without Total RP 3 ...
    local cara = world:AddClient({ name = "Cara" }):Login()
    world:Advance(4)
    cara:Build("DRUID", "", 4)
    cara:Logout()
    -- ... logs in with Total RP 3 installed: its sheet becomes the profile's
    cara.trp3 = { profiles = { main = { profileName = "Cara" }, alt = { profileName = "Alt" } }, current = "main" }
    cara:Login()
    Eq(cara.addon.sheetKey, "trp3:main", "the profile's sheet")
    world:Advance(4)
    Eq(Class(cara), "DRUID", "the character made before Total RP 3 was installed is the profile's")
    Check(not Offered(cara), "no wizard")
    cara:Do(cara.env.TRP3_API.profile.selectProfile, "alt")
    Eq(Class(cara), "", "a second profile starts blank")
    cara:Reload()
    Eq(Keys(cara.saved), "trp3:main", "the character is saved under the first profile")
    cara:Logout()

    -- someone who met the blank profile before this was put right (a blank entry for
    -- the profile is saved) gets the character back too
    local eve = world:AddClient({ name = "Eve" }):Login()
    world:Advance(4)
    eve:Build("MONK", "", 4)
    eve:Logout()
    eve.saved.global.sheets["trp3:main"] = { hp = 7, hitDice = 1, sheet = { levels = {} } }
    eve.trp3 = { profiles = { main = { profileName = "Eve" } }, current = "main" }
    eve:Login()
    Eq(Class(eve), "MONK", "a blank entry for the profile doesn't keep the character away")
    eve:Logout()

    -- but a sheet made on a day without Total RP 3 is not handed to a new profile
    -- when another profile already has a character
    local finn = world:AddClient({ name = "Finn", trp3 = { profiles = { main = { profileName = "Finn" }, alt = { profileName = "Alt" } }, current = "main" } }):Login()
    world:Advance(4)
    finn:Build("PRIEST", "", 4)
    finn:Logout()
    local trp3 = finn.trp3
    finn.trp3 = false
    finn:Login()
    world:Advance(4)
    Eq(finn.addon.sheetKey, "char:Finn-Realm", "with Total RP 3 switched off the character's own sheet is used")
    finn:Build("ROGUE", "", 2)
    finn:Logout()
    finn.trp3 = trp3
    trp3.current = "alt"
    finn:Login()
    Eq(Class(finn), "", "a new profile stays blank")
    world:Advance(4)
    Check(Offered(finn), "and is offered the wizard")
    finn:Do(finn.env.TRP3_API.profile.selectProfile, "main")
    Eq(Class(finn), "PRIEST", "the first profile's character is untouched")
    finn:Logout()
    Eq(Keys(finn.saved), "char:Finn-Realm trp3:main", "and the sheet made without Total RP 3 is still there")

    -- the profile becomes known only after the addon started
    local dora = world:AddClient({ name = "Dora" }):Login()
    world:Advance(4)
    dora:Build("HUNTER", "", 4)
    dora:Logout()
    dora.trp3 = { profiles = { main = { profileName = "Dora" }, alt = { profileName = "Alt" } }, current = "main", ready = false }
    dora:Login()
    Eq(dora.addon.sheetKey, "char:Dora-Realm", "until the profile is known the character's own sheet is used")
    Eq(Class(dora), "HUNTER", "which is the character made earlier")
    Eq(dora.addon:GetLinkedProfileName(), nil, "no linked profile yet")
    dora:Do(dora.env.TRP3_API.profile.selectProfile, "main")
    Eq(dora.addon.sheetKey, "trp3:main", "then the profile's")
    Eq(Class(dora), "HUNTER", "the character moves to the profile")
    world:Advance(4)
    Check(not Offered(dora), "no wizard")
    dora:Do(dora.env.TRP3_API.profile.selectProfile, "alt")
    Eq(Class(dora), "", "another profile starts blank")
    dora:Do(dora.env.TRP3_API.profile.selectProfile, "main")
    Eq(Class(dora), "HUNTER", "and the first keeps the character")
    dora:Reload({})
    Eq(Keys(dora.saved), "trp3:main", "the character is saved under the profile only")

    -- late again, now that the profile has its sheet: nothing is moved or lost
    dora:Logout()
    dora.trp3.ready, dora.trp3.current = false, "main"
    dora:Login()
    Eq(Class(dora), "", "before the profile is known the character's own (blank) sheet shows")
    world:Advance(1)
    dora:Do(dora.env.TRP3_API.profile.selectProfile, "main")
    Eq(Class(dora), "HUNTER", "then the profile's character")
    world:Advance(4)
    Check(not Offered(dora), "and the wizard was not offered for the moment in between")
    world:CheckClean("late")
end)

Section("a sheet saved per character by an old version", function()
    local world = NewWorld()
    local old = world:AddClient({ name = "Olaf" }):Login()
    world:Advance(4)
    old:Build("WARRIOR", "", 3)
    old:Logout()
    -- put the saved sheet where versions before the profile link kept it
    local saved = old.saved
    local state = saved.global.sheets["char:Olaf-Realm"]
    saved.global.sheets = nil
    saved.char = saved.char or {}
    saved.char["Olaf - Realm"] = saved.char["Olaf - Realm"] or {}
    saved.char["Olaf - Realm"].sheet = state.sheet
    saved.char["Olaf - Realm"].hp = 11
    old:Login()
    Eq(Class(old), "WARRIOR", "the old sheet is the character's sheet")
    Eq(rawget(old.addon.db.char, "sheet"), nil, "and is no longer kept in the old place")
    world:Advance(4)
    Check(not Offered(old), "no wizard for it")
    world:CheckClean("old")
end)

print(("  (%d times the sheet in use was a blank one for a key that never got a character)"):format(BLANKS))
Summary("t-sync-profiles")
