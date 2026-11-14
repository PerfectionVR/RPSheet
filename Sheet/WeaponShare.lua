-- Sharing one weapon from the armoury (Sheet/WeaponStore.lua) as a text string.
-- Like a character string (Sheet/Transfer.lua) it comes from someone else, so the
-- weapon is rebuilt field by field and every choice checked against the rules data.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Codec = ns.Codec

local PREFIX = "!RPW1!" -- marks an RP Sheet weapon, format 1

-- A stored weapon as one line of text.
function RPSheet:ExportStoredWeapon(index)
    local weapon = self:StoredWeapons()[index]
    if not weapon then return "" end
    return PREFIX .. Codec.Pack("print", { format = 1, weapon = weapon })
end

-- Reads a weapon string. Returns a clean weapon, or nil and a message saying what
-- is wrong with the text.
function RPSheet:DecodeWeapon(text)
    text = (text or ""):gsub("%s+", "")
    if text == "" then return nil, "Paste a weapon string first." end
    if text:sub(1, #PREFIX) ~= PREFIX then
        return nil, "This is not an RP Sheet weapon string. It should start with " .. PREFIX
    end
    local ok, payload = Codec.Unpack("print", text:sub(#PREFIX + 1))
    if not ok or type(payload) ~= "table" or type(payload.weapon) ~= "table" then
        return nil, "The string is damaged or incomplete. Copy the whole thing and try again."
    end
    if payload.format ~= 1 then
        return nil, "This string was made by a newer version of RP Sheet. Update the addon to import it."
    end
    local weapon = ns.CleanWeapon(payload.weapon)
    weapon.name = weapon.name:trim()
    if weapon.name == "" then return nil, "The weapon in this string has no name." end
    if not R.STAT_NAMES[weapon.stat] then weapon.stat = "STR" end
    if not R.MASTERIES[weapon.mastery] then weapon.mastery = "" end
    local data = R.WEAPONS[weapon.base]
    if data then
        -- A basic weapon's dice are the rules' own, whatever the string says.
        weapon.dice, weapon.sides = data.dice[1], data.dice[2]
    else
        weapon.base, weapon.twoHands = "", false
    end
    return weapon
end
