-- The sheet's "Take damage" and "Heal" rows: a menu of damage types, then a small box
-- for the amount. The rules are applied in Actions/Damage.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI

local POPUP = "RPSHEET_DAMAGE_AMOUNT"

local BoxOf = ns.PopupEditBox -- Actions/PopupBox.lua

-- `request` is { heal = true } or { damageType = "fire" } (no type: an empty table).
-- ward = false leaves the dice of a protective spell out; prompt = a question of its
-- own; crit = true: the hit was a critical one.
local function Apply(dialog, request)
    local box = BoxOf(dialog)
    local amount = tonumber(((box and box:GetText()) or ""):match("%d+")) or 0
    if type(request) ~= "table" then return end
    if request.heal then
        RPSheet:Heal(amount)
    else
        RPSheet:TakeDamage(amount, request.damageType, nil, request.ward, request.crit)
    end
end

StaticPopupDialogs[POPUP] = {
    text = "%s", button1 = ACCEPT, button2 = CANCEL,
    hasEditBox = true, maxLetters = 4, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    OnShow = function(dialog)
        local box = BoxOf(dialog)
        if box then
            box:SetText("")
            box:SetFocus()
        end
    end,
    OnAccept = function(dialog, request) Apply(dialog, request) end,
    EditBoxOnEnterPressed = function(box)
        local dialog = box:GetParent()
        Apply(dialog, dialog.data)
        dialog:Hide()
    end,
    EditBoxOnEscapePressed = function(box) box:GetParent():Hide() end,
}

-- Asks for the amount, then heals or deals the damage.
function RPSheet:AskAmount(request)
    local prompt = "How many hit points do you regain?"
    if request.prompt then
        prompt = request.prompt
    elseif not request.heal then
        prompt = ("How much %sdamage do you take?\nType the amount as rolled: the sheet halves, doubles or ignores it as your resistances say."):format(
            request.damageType and (request.damageType .. " ") or "")
    end
    StaticPopup_Show(POPUP, prompt, nil, request)
end

-- What the character does with a damage type, for the menu: "immune", "resisted", ...
local function Standing(defenses, name)
    if defenses.immune[name] then return "immune" end
    local parts = {}
    if defenses.resist[name] then parts[#parts + 1] = "resisted" end
    if defenses.vulnerable[name] then parts[#parts + 1] = "vulnerable" end
    return #parts > 0 and table.concat(parts, ", ") or nil
end

-- A menu at the cursor with the damage types.
function RPSheet:OpenDamageMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        self:Print("The damage menu isn't available in this version of the game. Type /sheet damage 14 fire instead.")
        return
    end
    local defenses = self:Defenses()
    -- A critical hit only matters to the sheet at 0 hit points, where it is two
    -- failed death saves: the row to say so is only there then.
    local down, crit = self:IsDown() and (self:State().deathFail or 0) < 3, false
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Take damage of which type?")
        if down then
            local box = root:CreateCheckbox("It was a critical hit", function() return crit end, function() crit = not crit end)
            box:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, "Critical hit")
                GameTooltip_AddNormalLine(tooltip, "Tick this first when the hit was a critical one: at 0 hit points it counts as two failed death saves.", true)
            end)
        end
        for _, name in ipairs(R.DAMAGE_TYPES) do
            local standing = Standing(defenses, name)
            local label = name:sub(1, 1):upper() .. name:sub(2)
            if standing then label = ("%s |cff909090(%s)|r"):format(label, standing) end
            root:CreateButton(label, function() self:AskAmount({ damageType = name, crit = crit }) end)
        end
        root:CreateButton("No type", function() self:AskAmount({ crit = crit }) end)
        -- What the protective spells that are on call for (Actions/WardDamage.lua).
        for _, extra in ipairs(self:DamageExtras()) do
            root:CreateButton(extra.label, function()
                if extra.run then extra.run() else self:AskAmount(extra.request) end
            end)
        end
    end)
end

-- The two rows under the bars.
function UI.AddDamageRows(addon, body)
    local label
    label = UI.AddLabel(body, 0.5, UI.ACCENT .. "Take damage|r", function() addon:OpenDamageMenu(label.frame) end,
        "Take damage", "Pick the damage type, then type the amount as it was rolled. Immunity leaves nothing, resistance halves it (rounded down), vulnerability doubles it. Temporary HP is used up first, and a spell you concentrate on gets its saving throw. A spell on you that takes dice off the damage is rolled first; it has a row of its own for when it was already used this turn. At 0 hit points damage is a failed death save, and the menu has a box to tick for a critical hit, which is two.\n\nOr type /sheet damage 14 fire, with the word crit after it for a critical hit. To change HP without the rules, click the HP bar.")
    UI.AddLabel(body, 0.5, UI.ACCENT .. "Heal|r", function() addon:AskAmount({ heal = true }) end,
        "Heal", "Type the hit points you regain. They stop at your maximum.\n\nOr type /sheet heal 8.")
end
