-- The starting closet as a source for the item browser (UI/ItemBrowser.lua): the same
-- blocks as the inventory's browser, but taking and equipping change the wizard's
-- draft (Wizard/Closet.lua) instead of a character.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local W = ns.Wizard

-- After a button changed the draft: the wizard's page and the browser both show it.
-- On the next frame, because the button is part of what gets rebuilt.
function W.ClosetChanged()
    C_Timer.After(0, function()
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON .. "Wizard")
        RPSheet:PopulateItemBrowser()
    end)
end

local CLOSET = {
    first = { name = "Taken", tip = "What you have taken so far." },
    kinds = {
        { name = "Weapons", kind = "Weapons and ammunition" }, { name = "Armor", kind = "Armor and shields" },
        { name = "Gear", kind = "Adventuring gear" }, { name = "Packs", kind = "Packs" },
        { name = "Focuses", kind = "Spellcasting focuses" }, { name = "Tools", kind = "Tools and instruments" },
    },
    empty = "Nothing taken yet. Open another tab and take what your character owns.",
    title = function() return "Starting gear" end,
    class = function() return W.draft.class end,
    find = function() return nil end, -- nothing is carried yet; the draft only counts
    gone = function() return W.draft == nil end,
}

function CLOSET.standing()
    local cost, weight, capacity = W.ClosetTotals()
    return ("Taken: worth %s%s|r, weighing %s%s of %d lb.|r"):format(
        UI.ACCENT, ns.CoinText(cost), weight > capacity and "|cffff5555" or UI.ACCENT, weight, capacity)
end

function CLOSET.own()
    local entries = {}
    for _, kind in ipairs(R.CLOSET_KINDS) do
        for _, name in ipairs(W.Taken(kind)) do entries[#entries + 1] = { name = name } end
    end
    return entries
end

function CLOSET.marks(_, entry)
    local count, marks = W.draft.closet[entry.name] or 0, {}
    if count > 0 then marks[#marks + 1] = "taken " .. count end
    if W.draft.worn[entry.name] then marks[#marks + 1] = "equipped" end
    return marks
end

function CLOSET.buttons(_, card, entry)
    local name = entry.name
    local taken, worn = (W.draft.closet[name] or 0) > 0, W.draft.worn[name] == true
    local wearable = ns.ItemSlot(entry) ~= nil
    UI.AddItemButton(card, 0.3, taken and "Take another" or "Take", true, function()
        W.TakeItem(name, 1)
        W.ClosetChanged()
    end)
    UI.AddItemButton(card, 0.3, "Put back", taken, function()
        W.TakeItem(name, -1)
        W.ClosetChanged()
    end)
    -- Equipping something takes it first.
    UI.AddItemButton(card, 0.4, wearable and (worn and "Put away" or "Equip") or "Can't be equipped", wearable, function()
        if not taken then W.TakeItem(name, 1) end
        W.WearItem(name, not worn)
        W.ClosetChanged()
    end)
end

function W.OpenCloset()
    RPSheet:ShowItemBrowser(CLOSET)
end

function W.CloseCloset()
    RPSheet:HideItemBrowser(CLOSET)
end
