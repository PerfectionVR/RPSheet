-- The dialog skin's tree: the list of pages on the left of Customize, the page beside
-- it and the bar between them that changes the list's width.
--
-- The rows are buttons the tree keeps for itself. It sets them up again every time
-- the list is scrolled, opened or clicked, so their look is given again after each.
local _, ns = ...
local Skin = ns.DialogSkin

-- Top entries in the accent colour, the entries below them in the text colour.
local function Fonts(theme)
    return Skin.StateFont("RPSheetDialogTreeFont", GameFontNormal, theme, theme.text),
        Skin.StateFont("RPSheetDialogTreeHoverFont", GameFontHighlight, theme, theme.text),
        Skin.StateFont("RPSheetDialogTreeSubFont", GameFontHighlightSmall, theme, ns.Tokens(theme).dim)
end

local function Rows(widget, theme)
    if type(widget.buttons) ~= "table" then return end
    local top, hover, sub = Fonts(theme)
    for _, row in ipairs(widget.buttons) do
        if type(row) == "table" and row.GetRegions then
            local first = row.level == 1
            Skin.ButtonFonts(widget, row, { Normal = first and top or sub, Highlight = first and hover or sub })
            -- The glow under the mouse, which also marks the open page.
            Skin.Flat(widget, row.GetHighlightTexture and row:GetHighlightTexture(), theme.highlight)
            local toggle = row.toggle -- the plus or minus before an entry with pages below it
            if toggle and toggle.GetNormalTexture and toggle.GetPushedTexture then
                Skin.Grey(widget, toggle:GetNormalTexture(), theme.muted)
                Skin.Grey(widget, toggle:GetPushedTexture(), theme.muted)
            end
            Skin.Recolor(widget, row.text, theme)
        end
    end
end

local function RowsAgain(widget)
    local theme = Skin.Theme()
    if theme then Rows(widget, theme) end
end

-- The bar between list and page shows while the mouse is on it; the library hides
-- it again on its own.
local function BarLit(bar)
    local theme = Skin.Theme()
    if not (theme and bar.SetBackdropColor) then return end
    bar:SetBackdropColor(theme.text[1], theme.text[2], theme.text[3], 0.2)
end

Skin.styles.TreeGroup = function(widget, theme)
    Skin.Pane(widget, widget.treeframe, theme)
    Skin.Pane(widget, widget.border, theme, 0)
    Skin.ScrollBar(widget, widget.scrollbar, theme)
    Rows(widget, theme)
    Skin.After(widget, "RefreshTree", RowsAgain)

    local bar = widget.dragger
    if bar and bar.SetBackdropColor then
        Skin.Hook(widget, bar, "OnEnter", BarLit)
        if Skin.First(widget, "bar", bar) then
            Skin.Undo(widget, function() bar:SetBackdropColor(1, 1, 1, 0) end) -- as the library leaves it
        end
    end
end
