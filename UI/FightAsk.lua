-- A small box the session's owner types a few words into: a new combatant
-- ("Gnoll 13 22 +1"), a saving throw ("DEX 15"), damage ("12 fire").
local _, ns = ...

local POPUP = "RPSHEET_FIGHT_ASK"
local BoxOf = ns.PopupEditBox -- Actions/PopupBox.lua

local function Apply(dialog, request)
    local box = BoxOf(dialog)
    local text = ((box and box:GetText()) or ""):trim()
    if type(request) == "table" and text ~= "" then request.go(text) end
end

StaticPopupDialogs[POPUP] = {
    text = "%s", button1 = ACCEPT, button2 = CANCEL,
    hasEditBox = true, maxLetters = 60, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    OnShow = function(dialog)
        local box = BoxOf(dialog)
        local request = dialog.data
        if box then
            box:SetText(type(request) == "table" and request.default or "")
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

-- Asks for a line of text and calls go(text). `default` is filled in.
function ns.AskFightText(prompt, default, go)
    StaticPopup_Show(POPUP, prompt, nil, { default = default, go = go })
end
