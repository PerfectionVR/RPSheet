-- The dialog skin's typing boxes: a flat box, with what is typed in the theme's text
-- colour. The typed text keeps the game's chat font, which has every script's letters.
local _, ns = ...
local Skin = ns.DialogSkin
local styles = Skin.styles

local BOX_INSET = { -4, 0, 0, 0 } -- the game's box starts a little left of the typing area

-- One line of typing, with its small confirm button.
styles.EditBox = function(widget, theme)
    local off = widget.disabled
    Skin.Font(widget, widget.label, Skin.NameColor(widget, theme), theme)
    local box = widget.editbox
    if box and box.GetRegions and box.CreateTexture then
        Skin.FadeArt(widget, box)
        Skin.BoxAt(widget, box, "edit", box, BOX_INSET, Skin.Wash(theme), Skin.EdgeColor(theme))
        Skin.Color(widget, box, off and theme.muted or theme.text)
    end
    Skin.Button(widget, widget.button, theme)
end

-- Several lines of typing, with the Accept button under them. This kind does not
-- note whether it is switched off; its typing area then ignores the mouse.
styles.MultiLineEditBox = function(widget, theme)
    local box = widget.editBox
    local off = box and box.IsMouseEnabled and not box:IsMouseEnabled()
    Skin.Font(widget, widget.label, off and theme.muted or theme.accent, theme)
    Skin.Backdrop(widget, widget.scrollBG, Skin.Wash(theme), Skin.EdgeColor(theme))
    -- Only when the box can be ours: in the game's dark one, dark typing would not show.
    if widget.scrollBG and widget.scrollBG.SetBackdropColor then
        Skin.Color(widget, box, off and theme.muted or theme.text)
    end
    Skin.ScrollBar(widget, widget.scrollBar, theme)
    Skin.Button(widget, widget.button, theme)
end
