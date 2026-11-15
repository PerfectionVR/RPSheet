-- The Inventory part of the sheet window: coins, attuned items, the weight carried
-- against what the character can carry, and (when opened) every item as a row.
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

local function ItemRow(self, body, item)
    local active, why = self:ItemActive(item)
    local lines, marks = {}, {}
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
    end

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
    end, item.name, table.concat(lines, "\n"))
end

function UI.InventorySection(self, body)
    local items = Util.Named(self:Sheet().items or {})
    UI.AddHeading(body, "Inventory")
    UI.AddLabel(body, 1, "Coins  " .. ns.PurseText(self:Purse(), UI.ACCENT),
        function(button) self:CoinDialog(button == "RightButton") end, "Coins",
        ("Worth %s in all.\nPlatinum is 10 gold, gold is 10 silver, silver is 10 copper; an electrum piece is half a gold piece.\n\nLeft-click: add coins.\nRight-click: spend coins. Coins that fit the price are paid first, a larger one is broken for change when you run short of small ones, and you can't spend more than you have."):format(
            ns.CoinText(self:Coins())))

    local attuned, names = self:AttunedItems(), {}
    for _, item in ipairs(attuned) do names[#names + 1] = item.name end
    if #attuned > 0 then
        UI.AddLabel(body, 1, ("Attuned %s%d/%d|r  %s%s|r"):format(#attuned > R.ATTUNE_LIMIT and RED or UI.ACCENT, #attuned, R.ATTUNE_LIMIT,
            UI.GREY, table.concat(names, ", ")), nil, "Attunement", ATTUNE_HELP)
    end

    local open = self.db.char.inventoryOpen
    local weight, capacity = self:CarriedWeight(), self:CarryCapacity()
    local over = weight > capacity
    UI.AddLabel(body, 1, ("Carried %s%s/%d lb.|r%s  %s%d %s, click to %s|r"):format(
            over and RED or UI.ACCENT, Pounds(weight), capacity, over and (RED .. " over the limit|r") or "",
            UI.GREY, #items, #items == 1 and "item" or "items", open and "hide" or "show"),
        function()
            self.db.char.inventoryOpen = not open
            self:PopulateSoon()
        end, "Carrying capacity",
        ("You can carry your Strength score times %d in pounds: %d lb. Fifty coins weigh a pound.%s\n\nClick to %s the list of items. Items are added and bought under Customize > Inventory."):format(
            R.CARRY_PER_STRENGTH[self:Sheet().size] or R.CARRY_PER_STRENGTH.M, capacity,
            over and ("\n\n" .. RED .. "You are carrying more than that. Hauling a load over your limit slows you to a speed of 5 feet.|r") or "",
            open and "hide" or "show"))
    if not open then return end
    for _, item in ipairs(items) do ItemRow(self, body, item) end
end
