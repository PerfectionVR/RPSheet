-- The dialog skin's tabs, in the look of the sheet's own (UI/Tab.lua): the open tab is
-- a box filled and edged in the accent colour, the others are dim boxes with muted
-- names that light up under the mouse.
--
-- The tabs are buttons the tab group keeps for itself, so they are undone with it.
-- The library sets them up again whenever the group changes width or another tab is
-- picked; the look follows each time.
local _, ns = ...
local Skin = ns.DialogSkin

local SIDE = 6 -- neighbouring tabs overlap by ten pixels; this leaves a gap between the boxes
local EDGES = {
    { "TOPLEFT", "TOPRIGHT", flat = true }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" },
    { "BOTTOMLEFT", "BOTTOMRIGHT", flat = true },
}

local function Fonts(theme)
    local base = GameFontNormalSmall
    return Skin.StateFont("RPSheetDialogTabFont", base, theme, theme.muted),
        Skin.StateFont("RPSheetDialogTabHoverFont", base, theme, theme.text),
        Skin.StateFont("RPSheetDialogTabOpenFont", base, theme, theme.accent)
end

local function Tab(widget, tab, theme, closed, hover, opened)
    if not (type(tab) == "table" and tab.GetRegions and tab.CreateTexture) then return end
    local open, accent = tab.selected and not tab.disabled, theme.accent
    Skin.FadeArt(widget, tab)
    Skin.Fade(widget, tab.HighlightTexture)

    local fill = Skin.Texture(widget, tab, "tabFill", "BACKGROUND")
    fill:ClearAllPoints()
    -- The library sets a tab's name a little under its middle; the box sits around the
    -- name and ends on the top line of the page below.
    fill:SetPoint("TOPLEFT", SIDE, -5)
    fill:SetPoint("BOTTOMRIGHT", -SIDE, -1)
    fill:SetColorTexture(accent[1], accent[2], accent[3], open and 0.22 or 0.06)
    for index, side in ipairs(EDGES) do
        local edge = Skin.Texture(widget, tab, "tabEdge" .. index, "BORDER")
        edge:ClearAllPoints()
        edge:SetPoint(side[1], fill, side[1])
        edge:SetPoint(side[2], fill, side[2])
        if side.flat then edge:SetHeight(1) else edge:SetWidth(1) end
        edge:SetColorTexture(accent[1], accent[2], accent[3], open and 1 or 0.3)
        -- No line under the open tab: it reads as joined to the page below.
        if index == 4 then edge:SetShown(not open) end
    end
    local glow = Skin.Texture(widget, tab, "tabGlow", "HIGHLIGHT")
    glow:SetAllPoints(fill)
    glow:SetColorTexture(unpack(theme.highlight))

    -- The open tab is a switched-off button to the library, as is one that cannot be picked.
    Skin.ButtonFonts(widget, tab, { Normal = closed, Highlight = hover, Disabled = open and opened or closed })
    Skin.Recolor(widget, tab.GetFontString and tab:GetFontString(), theme)
end

Skin.styles.TabGroup = function(widget, theme)
    Skin.Font(widget, widget.titletext, theme.accent, theme)
    Skin.Pane(widget, widget.border, theme, 0)
    if type(widget.tabs) == "table" then
        local closed, hover, opened = Fonts(theme)
        for _, tab in ipairs(widget.tabs) do
            Tab(widget, tab, theme, closed, hover, opened)
        end
    end
    Skin.After(widget, "BuildTabs", Skin.Restyle)
end
