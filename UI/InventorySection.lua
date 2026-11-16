-- The Inventory part of the sheet window: coins, attuned items, the weight carried
-- against what the character can carry, and every item as a row.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI
local Util = ns.Util

local RED = "|cffff5555"
local ATTUNE_HELP = ("Some magic items only work once you are attuned to them, which takes a short rest spent with the item. You can be attuned to %d items at a time."):format(R.ATTUNE_LIMIT)
local SLOT_HELP = {
    armor = "Equipping it puts the armor on; you wear one suit at a time.",
    shield = "Equipping it raises the shield.",
    weapon = "Equipping it readies the weapon: it joins the ones you swap between on the weapon row.",
}
local ITEM_HELP = "Left-click: equip it or put it away.\nShift-click: use one up."

-- 12.5 -> "12.5", 12 -> "12"
local function Pounds(weight)
    return (("%.1f"):format(weight):gsub("%.0$", ""))
end

-- What an item's tooltip says: what it is and adds, whether that counts now, and how
-- it is clicked. Worked out when it is hovered.
local function ItemTip(self, item)
    local active, why = self:ItemActive(item)
    local lines = {}
    if item.magic then
        local color = R.RARITY_COLORS[item.rarity] or UI.ACCENT
        lines[#lines + 1] = ("%sMagic item%s|r"):format(color, item.rarity ~= "" and (", " .. item.rarity:lower()) or "")
    end
    if item.desc ~= "" then lines[#lines + 1] = item.desc end
    for _, effect in ipairs(item.effects) do
        lines[#lines + 1] = (active and UI.GREEN or UI.GREY) .. self:EffectText(effect) .. "|r"
    end
    if #item.effects > 0 and not active then lines[#lines + 1] = ("Not counted now: %s."):format(why) end
    local summary = R.ItemSummary(item.cost, item.weight)
    if summary ~= "" then lines[#lines + 1] = UI.GREY .. summary .. " each|r" end
    lines[#lines + 1] = "\n" .. ITEM_HELP
    local slot = ns.ItemSlot(item)
    if slot then lines[#lines + 1] = SLOT_HELP[slot] end
    if item.attune then
        lines[#lines + 1] = "Right-click: " .. (item.attuned and "end the attunement." or "attune to it.")
        lines[#lines + 1] = "\n" .. ATTUNE_HELP
    else
        lines[#lines + 1] = UI.GREY .. "Right-click attunes to a magic item that asks for it; this one doesn't.|r"
    end
    return table.concat(lines, "\n")
end

local function ItemRow(self, body, item)
    local marks = {}
    if item.equipped then marks[#marks + 1] = "equipped" end
    if item.attune then marks[#marks + 1] = item.attuned and "attuned" or (RED .. "needs attunement|r" .. UI.GREY) end
    local name = item.magic and ((R.RARITY_COLORS[item.rarity] or UI.ACCENT) .. item.name .. "|r") or item.name
    local text = ("%s%s  %s%s%s|r"):format(name, item.qty ~= 1 and (" x" .. item.qty) or "", UI.GREY,
        item.weight > 0 and (Pounds(item.qty * item.weight) .. " lb. ") or "",
        #marks > 0 and ("(" .. table.concat(marks, ", ") .. ")") or "")
    UI.AddLabel(body, 1, text, function(button)
        if button == "RightButton" then
            self:ToggleAttuned(item)
        elseif IsShiftKeyDown() then
            self:UseItem(item)
        else
            self:ToggleEquipped(item)
        end
    end, item.name, function() return ItemTip(self, item) end)
end

function UI.InventorySection(self, body)
    local items = Util.Named(self:Sheet().items or {})
    UI.AddHeading(body, "Inventory")
    UI.AddLabel(body, 1, UI.ACCENT .. "Browse items|r", function() self:ToggleItemBrowser() end, "Item browser",
        "Opens a window with what you carry and every listed item as a block: what it is and does, with buttons to add, buy, equip and remove it.")
    UI.AddLabel(body, 1, "Coins  " .. ns.PurseText(self:Purse(), UI.ACCENT),
        function(button) self:CoinDialog(button == "RightButton") end, "Coins",
        function()
            return ("Worth %s in all.\nPlatinum is 10 gold, gold is 10 silver, silver is 10 copper; an electrum piece is half a gold piece.\n\nLeft-click: add coins.\nRight-click: spend coins. Coins that fit the price are paid first, a larger one is broken for change when you run short of small ones, and you can't spend more than you have."):format(
                ns.CoinText(self:Coins()))
        end)

    local attuned, names = self:AttunedItems(), {}
    for _, item in ipairs(attuned) do names[#names + 1] = item.name end
    if #attuned > 0 then
        UI.AddLabel(body, 1, ("Attuned %s%d/%d|r  %s%s|r"):format(#attuned > R.ATTUNE_LIMIT and RED or UI.ACCENT, #attuned, R.ATTUNE_LIMIT,
            UI.GREY, table.concat(names, ", ")), nil, "Attunement", ATTUNE_HELP)
    end

    local weight, capacity = self:CarriedWeight(), self:CarryCapacity()
    local over = weight > capacity
    UI.AddLabel(body, 1, ("Carried %s%s/%d lb.|r%s  %s%d %s|r"):format(
            over and RED or UI.ACCENT, Pounds(weight), capacity, over and (RED .. " over the limit|r") or "",
            UI.GREY, #items, #items == 1 and "item" or "items"),
        nil, "Carrying capacity",
        function()
            return ("You can carry your Strength score times %d in pounds: %d lb. Fifty coins weigh a pound.%s\n\nItems are added and bought in the item browser (Browse items, above)."):format(
                R.CARRY_PER_STRENGTH[self:Sheet().size] or R.CARRY_PER_STRENGTH.M, capacity,
                over and ("\n\n" .. RED .. "You are carrying more than that, which holds your speed to 5 feet. The Speed row shows it.|r") or "")
        end)
    for _, item in ipairs(items) do ItemRow(self, body, item) end
end
