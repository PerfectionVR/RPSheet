-- Which saved sheet is active, and access to it.
-- A sheet belongs to the current Total RP 3 profile, or to the WoW character without TRP3.
local _, ns = ...
local RPSheet = ns.addon
local Util = ns.Util

local function CharacterKey()
    return ("char:%s-%s"):format(UnitName("player"), GetNormalizedRealmName() or "")
end

local function CurrentSheetKey()
    local getID = TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfileID
    if getID then
        local ok, id = pcall(getID)
        if ok and type(id) == "string" and id ~= "" then
            return "trp3:" .. id
        end
    end
    return CharacterKey()
end

-- A saved sheet that holds a character (the wizard was finished or skipped, or a class
-- was chosen by hand), as opposed to the blank one every new key starts with.
local function Made(state)
    return type(state) == "table" and (state.created or (type(state.sheet) == "table" and (state.sheet.class or "") ~= "")) and true or false
end

local function AnyProfileMade(sheets)
    for key, state in pairs(sheets) do
        if type(key) == "string" and key:find("^trp3:") and Made(state) then return true end
    end
    return false
end

-- Name of the linked Total RP 3 profile, or nil when the sheet is tied to the WoW character.
function RPSheet:GetLinkedProfileName()
    if not self.sheetKey or not self.sheetKey:find("^trp3:") then return end
    local ok, profile = pcall(TRP3_API.profile.getPlayerCurrentProfile)
    return ok and type(profile) == "table" and profile.profileName or "?"
end

-- Switches to the sheet of the current TRP3 profile if it changed. Returns true on a switch.
function RPSheet:UpdateSheetKey()
    local key = CurrentSheetKey()
    local previous = self.sheetKey
    if key == previous then return false end
    self.sheetKey = key

    local sheets, old = self.db.global.sheets, self.db.char
    local blank = ns.defaults.global.sheets["*"]
    if rawget(old, "sheet") and not rawget(sheets, key) then
        -- A sheet made before sheets were linked to profiles moves to the first profile seen.
        sheets[key] = Util.FillDefaults(
            { sheet = old.sheet, hp = old.hp, resource = old.resource, counter = old.counter, weapon = old.weapon, initialized = true },
            blank)
        old.sheet, old.hp, old.resource, old.counter, old.weapon = nil, nil, nil, nil, nil
    elseif previous and previous:find("^char:") and key:find("^trp3:")
        and rawget(sheets, previous) and not ns.IsBlankState(rawget(sheets, previous))
        and (not rawget(sheets, key) or ns.IsBlankState(rawget(sheets, key))) and not AnyProfileMade(sheets) then
        -- Total RP 3 became available: the character's own sheet becomes the profile's
        -- sheet. Like at a login (below) only while no profile has a character, and
        -- whether or not a blank entry for the profile happens to be saved: those are
        -- not kept (Sheet/Blank.lua).
        sheets[key] = Util.FillDefaults(rawget(sheets, previous), blank)
        sheets[previous] = nil
    elseif not previous and key:find("^trp3:") and not Made(rawget(sheets, key)) and Made(rawget(sheets, CharacterKey()))
        and not AnyProfileMade(sheets) then
        -- The same at a login: Total RP 3 was installed after the character was made, and
        -- has its profile ready before this addon starts. Only while no profile has a
        -- character yet, so a sheet made on a day without Total RP 3 isn't handed to
        -- whichever profile is made next.
        local own = CharacterKey()
        sheets[key] = Util.FillDefaults(rawget(sheets, own), blank)
        sheets[own] = nil
    end

    ns.NormalizeState(sheets[key])
    -- Brings class features in line with the current version of the addon.
    if sheets[key].created then
        ns.ApplyClassFeatures(sheets[key].sheet)
        ns.ApplyLineageSpells(sheets[key].sheet)
        ns.ApplyTraits(sheets[key].sheet)
        ns.ApplyFeatChoices(sheets[key].sheet) -- once more for a trait's feat (see ns.ApplyGrants)
        ns.ApplyFeatSpells(sheets[key].sheet)
        ns.NormalizeState(sheets[key]) -- features added just now get their full shape
    end
    self:ClampState()
    ns.RebuildOptions()
    self:Populate()
    return true
end

-- Current values (hp, resources, slots) and the sheet itself for the active profile.
function RPSheet:State()
    return self.db.global.sheets[self.sheetKey]
end

function RPSheet:Sheet()
    return self:State().sheet
end

-- Makes `sheet` the active profile's character (wizard, import, example), rested and
-- with the window and editor rebuilt. `keepResourceValues` leaves the current values
-- of the player's own resources alone, for when the resource list was carried over.
function RPSheet:ReplaceSheet(sheet, keepResourceValues)
    local state = self:State()
    state.sheet = sheet -- (one that names only part of the fields, like the example, is made whole by ns.NormalizeState)
    state.created, state.weapon, state.hp = true, 1, nil
    if not keepResourceValues then wipe(state.res) end
    wipe(state.pool)
    wipe(state.slots)
    if type(state.pactSlots) == "table" then wipe(state.pactSlots) end
    if type(state.hitDiceMore) == "table" then wipe(state.hitDiceMore) end
    state.conditions, state.exhaustion = {}, 0
    -- What the character before left behind, as after a long rest (Actions/Rest.lua):
    -- temporary hit points, death saves, a spell that was running, and the marks that
    -- say the prepared spells and mastery picks were already changed since a rest.
    state.tempHP, state.deathPass, state.deathFail, state.growing = 0, 0, 0, {}
    state.prepareClosed, state.prepareSwap, state.cantripSwap, state.petMasteryChanged = nil, nil, nil, nil
    ns.NormalizeState(state)
    ns.ApplyClassFeatures(sheet) -- an imported sheet may come from an older version
    ns.ApplyLineageSpells(sheet)
    ns.ApplyTraits(sheet)
    -- Once more for a feat a trait put on the sheet, as in ns.ApplyGrants: its text
    -- says what was chosen for it.
    ns.ApplyFeatChoices(sheet)
    ns.ApplyFeatSpells(sheet)
    ns.NormalizeState(state)
    self:ClampState(true)
    ns.RebuildOptions()
    self:Populate()
end

-- Called after any change to the character.
function RPSheet:SheetChanged()
    self:ClampState()
    self:Populate()
end
