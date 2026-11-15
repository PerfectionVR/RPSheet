-- The smaller things professions do from the sheet: the box that adds or takes
-- gathered materials, an enchanter turning a magic item into residue, and a cook's
-- great feast.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

---------------------------------------------------------------------------
-- Materials
---------------------------------------------------------------------------
local DIALOG = "RPSHEET_MATERIALS"

-- The game has named the box's text field differently over time.
local function Box(dialog)
    return dialog.GetEditBox and dialog:GetEditBox() or dialog.EditBox or dialog.editBox
end

local function Apply(dialog)
    local box, request = Box(dialog), dialog.data
    local copper = ns.ParseCoins(box and box:GetText())
    if type(request) ~= "table" then return end
    if not copper then
        RPSheet:Print("That doesn't read as a worth. Write it like 50 gp, or just a number for gold.")
    else
        RPSheet:AddMaterials(request.kind, request.take and -copper or copper)
    end
end

StaticPopupDialogs[DIALOG] = {
    text = "%s", button1 = ACCEPT, button2 = CANCEL,
    hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
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

-- Asks for a worth to add to the materials of a kind, or with `take` to remove.
function RPSheet:MaterialDialog(kind, take)
    local text = take and "Take how much worth from your %s? You have %s.\nFor example: 50 gp" or "Add how much worth to your %s? You have %s.\nFor example: 50 gp"
    StaticPopup_Show(DIALOG, text:format(R.MATERIALS[kind]:lower(), ns.CoinText(self:Trade().materials[kind])), nil, { kind = kind, take = take })
end

---------------------------------------------------------------------------
-- Disenchanting
---------------------------------------------------------------------------
local ENCHANTING, COOKING = R.PROFESSIONS.enchanting, R.PROFESSIONS.cooking

-- The carried items the character can disenchant: lasting magic items whose rarity
-- its skill reaches.
function RPSheet:Disenchantable()
    local list, level = {}, self:ProfessionLevel()
    if not self:CanPractise(ENCHANTING) then return list end
    for _, item in ipairs(self:Sheet().items or {}) do
        local row = item.magic and not R.CONSUMABLES[item.name] and R.DISENCHANT[item.rarity]
        if item.name ~= "" and row and level >= row.level then list[#list + 1] = item end
    end
    return list
end

-- Takes the magic out of one carried item and keeps it as residue. It takes an hour.
function RPSheet:Disenchant(item)
    local row = R.DISENCHANT[item.rarity]
    if not row then return end
    local name = item.name
    self:DropItem(item)
    self:Trade().materials.residue = self:Trade().materials.residue + row.worth
    self:Announce(("spends an hour disenchanting %s into magical residue worth %s."):format(ns.Mark(name), ns.CoinText(row.worth)))
    ns.RebuildOptions() -- the item's page under Customize may be gone
    self:SheetChanged()
end

-- A menu at the cursor with the items that can be disenchanted.
function RPSheet:OpenDisenchantMenu(owner)
    local items = self:Disenchantable()
    if #items == 0 then
        self:Print("You carry no magic item your enchanting can take apart. Potions and the like, legendary items and artifacts can't be.")
        return
    end
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        self:Print("The menu isn't available in this version of the game.")
        return
    end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Disenchant which item? It is destroyed.")
        for _, item in ipairs(items) do
            root:CreateButton(("%s |cff909090(%s, residue worth %s)|r"):format(item.name, item.rarity:lower(), ns.CoinText(R.DISENCHANT[item.rarity].worth)),
                function() self:Disenchant(item) end)
        end
    end)
end

---------------------------------------------------------------------------
-- The great feast
---------------------------------------------------------------------------
function RPSheet:CookFeast()
    if not self:CanPractise(COOKING) or self:ProfessionLevel() < R.FEAST_LEVEL then
        self:Print(("A great feast takes a cook of %s skill."):format(R.PROFESSION_LEVELS[R.FEAST_LEVEL].name:lower()))
        return
    end
    if not self:PayWithMaterials(COOKING, R.FEAST_COST, "a great feast") then return end
    self:Announce(("spends an hour cooking a great feast, which works as %s."):format(ns.Mark("Heroes' Feast")))
end
