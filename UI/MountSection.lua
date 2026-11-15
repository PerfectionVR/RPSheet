-- The mounts part of the sheet window's Items tab: what the character is riding and
-- what it carries, then every owned mount, vehicle and companion creature as a row.
-- Also the two bits of the Speed row that follow the mount.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local Util = ns.Util

local RED = "|cffff5555"
local RIDE_HELP = "A trained mount moves on your turn as you direct it, and can only Dash, Disengage or Dodge. If something moves it against its will, or you or it are knocked prone, you make a DC 10 Dexterity save or fall off and land prone."
local KEEP_HELP = ("A day's feed costs %s and a day's stabling %s. Armor made for a mount costs %d times the price and weighs twice as much."):format(
    ns.CoinText(R.FEED_COPPER), ns.CoinText(R.STABLE_COPPER), R.BARDING_COST)

-- After the Speed row's number while riding: how the mount moves, if not on the ground.
function UI.RidingMark(self)
    local mount = self:RiddenMount()
    if not mount or self:Immobile() then return "" end
    local _, mode = ns.MountPace(mount)
    return mode ~= "" and (" " .. mode) or ""
end

function UI.SpeedTip(self)
    local mount = self:RiddenMount()
    if not mount then return "How far you can move on your turn." end
    return ("How far you can move on your turn. You are riding %s, so this is its speed and not your own (%d ft on foot)."):format(mount.name, self:Speed(true))
end

-- What the character is on right now, with the load it takes.
local function RidingRow(self, body, entry)
    if entry.kind == "VEHICLE" then
        UI.AddLabel(body, 1, ("Aboard %s%s|r  %s%s|r"):format(UI.ACCENT, entry.name, UI.GREY, entry.travel),
            function() self:ToggleRiding(entry) end, "Aboard " .. entry.name,
            "On a journey you move at the vehicle's pace and don't choose a travel pace of your own. Your speed on a turn stays your own.\n\nClick to get out.")
        return
    end
    local feet, mode = ns.MountPace(entry)
    local gear, half = self:CarriedWeight(), math.floor(self:Speed(true) / 2)
    UI.AddLabel(body, 1, ("Riding %s%s|r  %s%d ft%s, carries %s%d lb.|r"):format(UI.ACCENT, entry.name, UI.GREY, feet,
            mode ~= "" and (" " .. mode) or "", gear > entry.capacity and RED or "", entry.capacity),
        function() self:ToggleRiding(entry) end, "Riding " .. entry.name,
        function()
            return ("Its speed counts in place of your own; the Speed row shows it.\n\nIt carries %d lb.: you and everything on you. Your gear weighs %.1f lb.; your own weight comes on top, which the DM judges.%s\n\nGetting on or off costs half your speed: %d feet of your movement.\n\n%s\n\nClick to dismount."):format(
                entry.capacity, gear, gear > entry.capacity and ("\n" .. RED .. "Your gear alone is more than it can carry.|r") or "", half, RIDE_HELP)
        end)
end

-- What an owned mount, vehicle or companion creature's tooltip says: what it is, and
-- how it is clicked. Worked out when it is hovered.
local function RowTip(self, entry)
    local lines = UI.MountLines(self, entry.name, entry)
    if entry.kind == "COMPANION" then
        lines[#lines + 1] = "\n" .. R.COMPANION_HELP .. "\n\n" .. R.LOYALTY_HELP
        lines[#lines + 1] = ("\nLeft-click: %s.\nRight-click: it was treated particularly well (rolls 1d%d for loyalty).\nShift-click: it took damage."):format(
            entry.called and "dismiss it" or "call it", R.LOYALTY_TREAT)
    else
        local why = self:MountRefusal(entry)
        if entry.kind == "MOUNT" then lines[#lines + 1] = "\n" .. RIDE_HELP .. "\n\n" .. KEEP_HELP end
        if entry.riding then
            lines[#lines + 1] = "\nClick to get off."
        elseif why then
            lines[#lines + 1] = ("\n%sYou can't get on: %s.|r"):format(UI.GREY, why)
        else
            lines[#lines + 1] = "\nClick to get on."
        end
    end
    return table.concat(lines, "\n")
end

local function Row(self, body, entry)
    local text, onClick
    if entry.kind == "COMPANION" then
        local family = R.COMPANIONS[entry.family]
        text = ("%s  %s%s, loyalty %d%s|r"):format(entry.name, UI.GREY, family and entry.family:lower() or "companion", entry.loyalty, entry.called and " (out)" or "")
        onClick = function(button)
            if IsShiftKeyDown() then
                self:HurtCompanion(entry)
            elseif button == "RightButton" then
                self:TreatCompanion(entry)
            else
                self:ToggleCompanion(entry)
            end
        end
    else
        local speeds = ns.MountSpeeds(entry)
        local parts = {}
        if speeds ~= "" then parts[#parts + 1] = speeds end
        if entry.capacity > 0 then parts[#parts + 1] = entry.capacity .. " lb." end
        if entry.riding then parts[#parts + 1] = entry.kind == "VEHICLE" and "(aboard)" or "(riding)" end
        text = ("%s  %s%s|r"):format(entry.name, UI.GREY, table.concat(parts, ", "))
        onClick = function() self:ToggleRiding(entry) end
    end
    UI.AddLabel(body, 1, text, onClick, entry.name, function() return RowTip(self, entry) end)
end

function UI.MountSection(self, body)
    local owned = Util.Named(self:Sheet().mounts or {})
    UI.AddHeading(body, "Mounts and companions")
    UI.AddLabel(body, 1, UI.ACCENT .. "Browse the stable|r", function() self:ToggleMountBrowser() end, "Stable",
        "Opens a window with the mounts, vehicles and companion creatures you own and every listed one as a block: what it is and does, with buttons to add, buy, ride and remove it.")
    local riding = self:Riding()
    if riding then RidingRow(self, body, riding) end
    for _, entry in ipairs(owned) do Row(self, body, entry) end
end
