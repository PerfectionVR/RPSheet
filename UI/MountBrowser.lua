-- The stable: the item browser (UI/ItemBrowser.lua) on the character's mounts,
-- vehicles and companion creatures. What is owned, every listed one, and adding,
-- buying, riding, calling and removing.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- The Customize > Mounts and companions page, behind the cog of the stable.
function ns.OpenMountOptions()
    AceConfigDialog:Open(ADDON)
    AceConfigDialog:SelectGroup(ADDON, "customize", "mounts")
end

-- After a button changed the list: on the next frame, because the button is part of
-- what gets rebuilt. Rebuilding the sheet rebuilds the stable too.
local function Changed(self)
    C_Timer.After(0, function()
        ns.RebuildOptions() -- an entry's page under Customize may have come or gone
        self:SheetChanged()
    end)
end

local STABLE = {
    first = { name = "Owned", tip = "Every mount, vehicle and companion creature you have." },
    kinds = {
        { name = "Mounts", kind = "Mounts" }, { name = "Drawn", kind = "Drawn vehicles" },
        { name = "Powered", kind = "Powered vehicles" }, { name = "Ships", kind = "Ships" },
        { name = "Companions", kind = "Companions" },
    },
    empty = "You own no mount, vehicle or companion creature yet. Open another tab to add or buy one.",
    title = function(self) return ("%s - Stable"):format(self:GetCharacterName()) end,
    class = function() return nil end,
    find = function(self, name) return self:OwnedMount(name) end,
    names = function(kind) return R.MOUNT_NAMES[kind] end,
    lines = function(self, entry) return UI.MountLines(self, entry.name, entry.item) end,
    options = function() ns.OpenMountOptions() end,
}

function STABLE.standing(self)
    local riding, companion = self:Riding(), self:Companion()
    return ("Money %s%s|r     On %s%s|r     Companion out %s%s|r\n%sBuy pays the price from your coins and asks for the seller's standing; Add takes it for nothing, for a gift or a reward. Saddles, feed and fuel are in the item browser, under Gear.|r"):format(
        UI.ACCENT, ns.CoinText(self:Coins()), UI.ACCENT, riding and riding.name or "foot",
        UI.ACCENT, companion and companion.name or "none", UI.GREY)
end

function STABLE.own(self)
    local entries = {}
    for _, entry in ipairs(self:Sheet().mounts or {}) do
        if entry.name ~= "" then entries[#entries + 1] = { name = entry.name, item = entry } end
    end
    return entries
end

function STABLE.marks(_, entry)
    local owned, marks = entry.item, {}
    if not owned then return marks end
    marks[#marks + 1] = "owned"
    if owned.riding then marks[#marks + 1] = owned.kind == "VEHICLE" and "aboard" or "riding" end
    if owned.called then marks[#marks + 1] = "out" end
    return marks
end

function STABLE.buttons(self, card, entry, first)
    local name, owned = entry.name, entry.item
    if not first then
        local known = R.MOUNTS[name]
        local label = known.unsold and "Not for sale" or (known.cost or 0) > 0 and ("Buy  " .. ns.CoinText(known.cost)) or "No price"
        UI.AddItemButton(card, 0.35, "Add", true, function()
            self:AddMount(name)
            Changed(self)
        end)
        UI.AddItemButton(card, 0.6, label, not self:MountNotSold(name) and self:CanAfford(known.cost), function()
            if self:BuyMount(name) then Changed(self) end
        end)
        return
    end
    if owned.kind == "COMPANION" then
        UI.AddItemButton(card, 0.5, owned.called and "Dismiss" or "Call", true, function() self:ToggleCompanion(owned) end)
    else
        local label = owned.riding and "Get off" or (owned.kind == "VEHICLE" and "Get aboard" or "Ride")
        UI.AddItemButton(card, 0.5, label, owned.riding or not self:MountRefusal(owned), function() self:ToggleRiding(owned) end)
    end
    UI.AddItemButton(card, 0.45, "Remove", true, function()
        self:RemoveMount(owned)
        Changed(self)
    end)
end

function RPSheet:ToggleMountBrowser()
    self:ShowItemBrowser(STABLE)
end
