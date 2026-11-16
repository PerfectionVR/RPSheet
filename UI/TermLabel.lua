-- "RPSheetTermLabel": a text block whose glossary terms (see Data/Glossary.lua) show
-- an explanation when hovered. Used for the summaries in the wizard and the editor,
-- by setting dialogControl = "RPSheetTermLabel" on an AceConfig description, and
-- through ns.EnableTermLinks for the blocks of the item browsers.
local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")
local Type, Version = "RPSheetTermLabel", 1

local function OnTermEnter(frame, link, text)
    local name = link:match("^rpsheet:(.+)$")
    local explanation = name and ns.Glossary[name]
    if not explanation then return end
    GameTooltip:SetOwner(frame, "ANCHOR_CURSOR_RIGHT")
    GameTooltip:AddLine(name)
    GameTooltip:AddLine(explanation, 1, 1, 1, true)
    GameTooltip:Show()
end

-- Switches the same hover links on for a label made elsewhere (an item browser's
-- block, say). AceGUI hands the widget to someone else once it is released, so the
-- links go off again then.
local function TermsOff(widget)
    widget.frame:SetHyperlinksEnabled(false)
    widget.frame:SetScript("OnHyperlinkEnter", nil)
    widget.frame:SetScript("OnHyperlinkLeave", nil)
end
function ns.EnableTermLinks(label)
    local frame = label.frame
    frame:SetHyperlinksEnabled(true)
    frame:SetScript("OnHyperlinkEnter", OnTermEnter)
    frame:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
    label:SetCallback("OnRelease", TermsOff)
    return label
end

local function Constructor()
    -- An ordinary AceGUI label, with hover links switched on for its text.
    local label = AceGUI:Create("Label")
    label.type = Type

    local frame = label.frame
    frame:EnableMouse(true)
    frame:SetHyperlinksEnabled(true)
    frame:SetScript("OnHyperlinkEnter", OnTermEnter)
    frame:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
    return label
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
