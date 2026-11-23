-- The differences between the games the addon runs in, kept in this one file so the
-- rest of the addon never asks which game it is in.
--
--   Retail       a character is "Name" on a realm; players are told apart as
--                "Name-Realm". UnitName returns the name and, for another realm, the realm.
--   WoW Forever  names are unique across the region and have two parts, "Given Family".
--                There is no realm in a name: UnitName returns the given name and the
--                family name where retail returns the realm, and chat shows both parts.
--
-- Everywhere else a player is known by their key (Game.UnitKey, Game.SenderKey): the
-- same string Total RP 3 uses for them in that game, so the two can be matched.
local _, ns = ...

local Game = {}
ns.Game = Game

local SEPARATORS = Constants and Constants.CharacterNameSeparatorConsts
local function Text(value, fallback) return type(value) == "string" and value ~= "" and value or fallback end
local SURNAME = Text(type(SEPARATORS) == "table" and SEPARATORS.CHARACTERNAME_SURNAME_SEPARATOR, " ")
local REALM = Text(type(SEPARATORS) == "table" and SEPARATORS.CHARACTERNAME_REALMNAME_SEPARATOR, "-")

local function Secret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

-- True in a game with region-wide two-part names (WoW Forever).
function Game.RegionalNames()
    return type(RegionalUniqueNamesEnabled) == "function" and RegionalUniqueNamesEnabled() and true or false
end

-- The key of a unit ("player", "party2", "mouseover"), or nil while it isn't known.
function Game.UnitKey(unit)
    -- (In Forever the plain UnitName can leave your own family name out, by a setting.)
    local name, second = (Game.RegionalNames() and UnitNameUnmodified or UnitName)(unit)
    if type(name) ~= "string" or Secret(name) or name == "" or name == UNKNOWNOBJECT then return end
    if Secret(second) or second == "" then second = nil end
    if Game.RegionalNames() then
        -- Your own name can come back with both parts already in it.
        if second and not name:find(SURNAME, 1, true) then name = name .. SURNAME .. second end
        return name
    end
    second = second or GetNormalizedRealmName()
    return second and (name .. REALM .. second)
end

-- The key of a player named in a chat line or an addon message, or nil when it can't
-- be told (retail, right after login, before the realm is known).
function Game.SenderKey(name)
    if type(name) ~= "string" or Secret(name) or name == "" then return end
    if Game.RegionalNames() then
        return (name:match("^(.-)" .. REALM:gsub("%p", "%%%0")) or name)
    end
    if name:find(REALM, 1, true) then return name end
    local realm = GetNormalizedRealmName()
    return realm and (name .. REALM .. realm)
end

-- True when `name`, from chat or an addon message, is the player.
function Game.IsPlayer(name)
    local key = Game.SenderKey(name)
    return key ~= nil and key == Game.UnitKey("player")
end

-- A key as a player reads it: "Name" in retail, "Given Family" in Forever.
function Game.ShortName(key)
    if Game.RegionalNames() then return key end
    return (key:match("^(.-)" .. REALM:gsub("%p", "%%%0")) or key)
end

-- The player's own name as shown in the game.
function Game.PlayerName()
    local key = Game.UnitKey("player")
    return key and Game.ShortName(key) or UnitName("player")
end

-- What a sheet is saved under when Total RP 3 isn't there. Retail keeps the key it
-- always had ("char:Name-Realm"); in Forever two characters can share a given name,
-- so the whole name is used.
function Game.CharacterKey()
    if Game.RegionalNames() then
        return "char:" .. (Game.UnitKey("player") or UnitName("player"))
    end
    return ("char:%s-%s"):format(UnitName("player"), GetNormalizedRealmName() or "")
end

---------------------------------------------------------------------------
-- Chat only from a click
---------------------------------------------------------------------------
-- WoW Forever lets an addon put a line in chat only straight from a click or a key
-- press: not when an event comes in (the game's roll line) and not from a timer.
-- Retail allows it for the channels the addon uses. Should a game refuse a line
-- anyway, Actions/AnnounceHeld.lua reports it here and the addon works the Forever
-- way from then on.
local refused = false

-- True in WoW Forever (its interface numbers are those of the original game).
function Game.IsForever()
    local _, _, _, interface = GetBuildInfo()
    return type(interface) == "number" and interface < 20000
end

-- True when announcements must go out during the click that made them: the dice are
-- then rolled by the addon at once instead of with the game's /roll (Actions/Dice.lua).
function Game.ChatNeedsClick()
    return refused or Game.IsForever()
end

function Game.ChatRefused()
    refused = true
end

---------------------------------------------------------------------------
-- The /roll line
---------------------------------------------------------------------------
-- The game's "<name> rolls <n> (<low>-<high>)" line as a Lua pattern. The name is
-- anything (Forever names have a space; another realm's carry "-Realm"), and a
-- translation may number its fields ("%1$s").
local rollPattern
local function RollPattern()
    if not rollPattern then
        rollPattern = "^" .. RANDOM_ROLL_RESULT
            :gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
            :gsub("%%%d?%%?%$?s", "(.+)")
            :gsub("%%%d?%%?%$?d", "(%%d+)") .. "$"
    end
    return rollPattern
end

-- Who rolled, the result, and the range from a system message, or nil when it isn't
-- a roll line.
function Game.ParseRoll(message)
    if type(message) ~= "string" or Secret(message) then return end
    local name, roll, low, high = message:match(RollPattern())
    if name then return name, tonumber(roll), tonumber(low), tonumber(high) end
end
