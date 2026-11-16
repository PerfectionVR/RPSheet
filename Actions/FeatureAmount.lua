-- A small box that asks a class feature for a number: the points of Lay on Hands to
-- spend, the necrotic damage Rune Strike dealt. It opens with a suggestion filled in.
local _, ns = ...

local POPUP = "RPSHEET_FEATURE_AMOUNT"
local BoxOf = ns.PopupEditBox -- Actions/PopupBox.lua

local function Apply(dialog, request)
    local box = BoxOf(dialog)
    local amount = tonumber(((box and box:GetText()) or ""):match("%d+"))
    if type(request) == "table" and amount then request.go(amount) end
end

StaticPopupDialogs[POPUP] = {
    text = "%s", button1 = ACCEPT, button2 = CANCEL,
    hasEditBox = true, maxLetters = 4, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    OnShow = function(dialog)
        local box = BoxOf(dialog)
        local request = dialog.data
        if box then
            box:SetText(type(request) == "table" and request.default and tostring(request.default) or "")
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

-- Asks for a number and calls go(number). `default` is filled in.
function ns.AskFeatureAmount(prompt, default, go)
    StaticPopup_Show(POPUP, prompt, nil, { default = default, go = go })
end
