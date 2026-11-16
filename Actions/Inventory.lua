-- What the player does with items and coins from the sheet: equipping, attuning,
-- using one up, and the small box that adds or spends money. These hold to the rules;
-- the Customize > Inventory page can set anything directly.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- An item's effects can change hit points and other tracked numbers.
local function Changed(self)
    self:ClampState()
    self:PopulateSoon()
end

function RPSheet:ToggleEquipped(item)
    self:SetEquipped(item, not item.equipped)
    Changed(self)
end

-- Attunes to an item or ends the attunement. No more than three at a time. An item
-- that asks for none says so, since a right-click on its row does nothing else.
function RPSheet:ToggleAttuned(item)
    if not item.attune then
        self:Print(("%s needs no attunement. A right-click attunes to a magic item that asks for it, or ends that attunement."):format(item.name))
        return
    end
    if not item.attuned and #self:AttunedItems() >= R.ATTUNE_LIMIT then
        self:Print(("You are already attuned to %d items. End one attunement first (right-click an attuned item)."):format(R.ATTUNE_LIMIT))
        return
    end
    item.attuned = not item.attuned
    self:Print(item.attuned and ("You are now attuned to %s. Attuning takes a short rest spent with the item."):format(item.name)
        or ("Your attunement to %s has ended."):format(item.name))
    Changed(self)
end

-- Something drunk: a potion, an elixir, a philter. Drinking one is a bonus action.
local function Drunk(item)
    local name = (item.name or ""):lower()
    return name:find("potion") or name:find("elixir") or name:find("philter") or (item.desc or ""):find("^Drinking") ~= nil
end

-- Uses one up: a potion drunk, a torch burnt, a ration eaten. The last one takes the
-- entry off the list. A spell scroll is read instead, which casts its spell and says
-- so itself (Actions/Scrolls.lua); it is kept when the casting can't go ahead.
-- Using anything takes an action or a bonus action (a potion), which an incapacitated
-- character has none of; someone else may still give it one.
function RPSheet:UseItem(item)
    if item.qty <= 0 then return end
    local drunk = Drunk(item)
    -- (a scroll says so itself when it is read)
    if not ns.ScrollSpell(item) and self:CantAct((drunk and "drink " or "use ") .. item.name) then
        if drunk then
            self:Print("Someone else can give it to you with a bonus action: then take it off with Remove in the item browser.")
        end
        return
    end
    if ns.ScrollSpell(item) then
        if not self:ReadScroll(item) then return end
        item.qty = item.qty - 1
    else
        item.qty = item.qty - 1
        self:Announce(("uses %s"):format(ns.Mark(item.name)))
    end
    if item.qty == 0 then
        if item.equipped then self:SetEquipped(item, false) end
        local items = self:Sheet().items
        for index, other in ipairs(items) do
            if other == item then
                table.remove(items, index)
                ns.RebuildOptions() -- its page under Customize is gone too
                break
            end
        end
    end
    Changed(self)
end

-- The carried entry of that name, if there is one.
function RPSheet:CarriedItem(name)
    for _, item in ipairs(self:Sheet().items) do
        if item.name == name then return item end
    end
end

-- Takes one off the list without a word; the last one takes the entry with it.
function RPSheet:DropItem(item)
    if item.qty > 1 then
        item.qty = item.qty - 1
        return
    end
    if item.equipped then self:SetEquipped(item, false) end
    local items = self:Sheet().items
    for index, other in ipairs(items) do
        if other == item then
            table.remove(items, index)
            break
        end
    end
end

---------------------------------------------------------------------------
-- Adding and spending coins from the sheet
---------------------------------------------------------------------------
local DIALOG = "RPSHEET_COINS"

-- The game has named the box's text field differently over time.
local function Box(dialog)
    return dialog.GetEditBox and dialog:GetEditBox() or dialog.EditBox or dialog.editBox
end

local function Apply(dialog)
    local box = Box(dialog)
    local copper = ns.ParseCoins(box and box:GetText())
    if not copper then
        RPSheet:Print("That doesn't read as money. Write it like 5 gp 3 sp, or just a number for gold.")
    elseif dialog.data and dialog.data.spend then
        RPSheet:SpendCoins(copper)
    else
        RPSheet:AddCoins(copper)
    end
end

StaticPopupDialogs[DIALOG] = {
    text = "%s", button1 = ACCEPT, button2 = CANCEL,
    hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
    OnShow = function(dialog)
        local box = Box(dialog)
        if box then box:SetText(""); box:SetFocus() end
    end,
    OnAccept = function(dialog) Apply(dialog) end,
    EditBoxOnEnterPressed = function(box)
        local dialog = box:GetParent()
        Apply(dialog)
        dialog:Hide()
    end,
    EditBoxOnEscapePressed = function(box) box:GetParent():Hide() end,
}

-- `spend` true asks for an amount to pay, otherwise for an amount gained.
function RPSheet:CoinDialog(spend)
    local text = spend and "Spend how much? You have %s.\nFor example: 5 gp 3 sp" or "Add how much? You have %s.\nFor example: 5 gp 3 sp"
    StaticPopup_Show(DIALOG, text:format(ns.CoinText(self:Coins())), nil, { spend = spend })
end
