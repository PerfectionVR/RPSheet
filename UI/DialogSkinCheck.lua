-- The dialog skin's tick box: a flat box in the theme's border colour with a tick in
-- the accent colour. A box that is one choice out of several (the round kind) is a
-- smaller box that fills with the accent colour instead.
--
-- The game's box, tick and glow are only made invisible: the library keeps showing
-- and hiding its tick as before, and ours follows it.
local _, ns = ...
local Skin = ns.DialogSkin

local TICK = 130751 -- the game's tick picture, as the library names it

Skin.styles.CheckBox = function(widget, theme)
    local off = widget.disabled
    Skin.Font(widget, widget.text, off and theme.muted or theme.text, theme)
    Skin.Font(widget, widget.desc, theme.muted, theme)

    local frame, place, tick = widget.frame, widget.checkbg, widget.check
    if not (frame and frame.CreateTexture and place and place.GetWidth and tick and tick.IsShown) then return end
    Skin.Fade(widget, place)
    Skin.Fade(widget, tick)
    Skin.Fade(widget, widget.highlight)

    -- The round kind is drawn in a smaller square than the tick box.
    local round = (place:GetWidth() or 24) < 20
    local box = Skin.BoxAt(widget, frame, "check", place, round and 2 or 4,
        Skin.Wash(theme), off and theme.muted or Skin.EdgeColor(theme))
    local glow = Skin.Texture(widget, frame, "checkGlow", "HIGHLIGHT")
    glow:SetAllPoints(box)
    glow:SetColorTexture(unpack(theme.highlight))

    -- Muted while switched off, and for the third state: neither yes nor no.
    local color = (off or (widget.tristate and widget.checked == nil)) and theme.muted or theme.accent
    local mark = Skin.Texture(widget, frame, "checkMark", "ARTWORK")
    mark:ClearAllPoints()
    if round then
        mark:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
        mark:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
        mark:SetDesaturated(false)
        mark:SetVertexColor(1, 1, 1, 1)
        mark:SetColorTexture(color[1], color[2], color[3], 1)
    else
        mark:SetAllPoints(place)
        mark:SetTexture(TICK)
        mark:SetDesaturated(true)
        mark:SetVertexColor(color[1], color[2], color[3], 1)
    end
    mark:SetShown(tick:IsShown())

    -- Clicking changes the tick and resets the colours without the window being
    -- built again; every such change ends in SetDisabled.
    Skin.After(widget, "SetDisabled", Skin.Restyle)
end
