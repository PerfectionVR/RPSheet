-- Which saved sheet is active, and access to it.
-- A sheet belongs to the current Total RP 3 profile, or to the WoW character without TRP3.
local _, ns = ...
local RPSheet = ns.addon
local Util = ns.Util

local function CurrentSheetKey()
    local getID = TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfileID
    if getID then
        local ok, id = pcall(getID)
        if ok and type(id) == "string" and id ~= "" then
            return "trp3:" .. id
        end
    end
    return ("char:%s-%s"):format(UnitName("player"), GetNormalizedRealmName() or "")
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
    elseif previous and previous:find("^char:") and key:find("^trp3:") and rawget(sheets, previous) and not rawget(sheets, key) then
        -- Total RP 3 became available: the character's own sheet becomes the profile's sheet.
        sheets[key] = Util.FillDefaults(rawget(sheets, previous), blank)
        sheets[previous] = nil
    end

    ns.NormalizeState(sheets[key])
    -- Brings class features in line with the current version of the addon.
    if sheets[key].created then ns.ApplyClassFeatures(sheets[key].sheet) end
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
    state.sheet = sheet
    state.created, state.weapon, state.hp = true, 1, nil
    if not keepResourceValues then wipe(state.res) end
    wipe(state.pool)
    wipe(state.slots)
    ns.NormalizeState(state)
    ns.ApplyClassFeatures(sheet) -- an imported sheet may come from an older version
    self:ClampState(true)
    ns.RebuildOptions()
    self:Populate()
end

-- Called after any change to the character.
function RPSheet:SheetChanged()
    self:ClampState()
    self:Populate()
end
