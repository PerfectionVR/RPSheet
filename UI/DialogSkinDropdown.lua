-- The dialog skin's dropdown: a flat box with a small arrow, and the list that opens
-- under it as a flat panel in the theme's background colour.
--
-- The list is a part of its own that the dropdown holds from the start and hands back
-- together with itself; its lines are parts too, handed back whenever the list is
-- filled again. So the list is styled as a piece of the dropdown, and every line as
-- a part in its own right.
local _, ns = ...
local Skin = ns.DialogSkin
local styles = Skin.styles

local CLEAR = { 0, 0, 0, 0 }
local LIST_INSET = { 4, 4, 8, 8 } -- about where the game's ornate edge ran
local BOX_INSET = { 1, 1, 0, 2 }  -- the game's box inside the strip that takes the clicks

-- One line of an open list.
local function Line(widget, theme)
    local color = widget.disabled and theme.muted
        or widget.type == "Dropdown-Item-Header" and theme.muted or theme.text
    Skin.Font(widget, widget.text, color, theme)
    Skin.Flat(widget, widget.highlight, theme.highlight)
    Skin.Grey(widget, widget.check, theme.accent)
    Skin.Grey(widget, widget.sub, theme.accent)
end
for _, kind in ipairs({ "Toggle", "Execute", "Header", "Menu" }) do
    styles["Dropdown-Item-" .. kind] = Line
end

local function List(owner, list, theme)
    local frame = list.frame
    if frame and frame.CreateTexture and frame.GetBackdropColor then
        local bg = theme.bg
        Skin.Backdrop(owner, frame, CLEAR, CLEAR)
        Skin.BoxAt(owner, frame, "list", frame, LIST_INSET,
            { bg[1], bg[2], bg[3], math.max(0.95, bg[4] or 1) }, Skin.EdgeColor(theme))
    end
    Skin.Bar(owner, list.slider, theme, true) -- shown when the list is too long
    if type(list.items) ~= "table" then return end
    for _, item in ipairs(list.items) do
        if type(item) == "table" then Skin.Style(item, theme) end
    end
end

-- `owner` is the part whose handing back undoes it all: the dropdown itself, or the
-- group that keeps this dropdown for itself.
function Skin.Dropdown(owner, widget, theme)
    local off = widget.disabled
    Skin.Font(owner, widget.label, off and theme.muted or ns.Tokens(theme).dim, theme)

    local holder, strip, boxed = widget.dropdown, widget.button_cover, false
    if holder and holder.GetRegions and holder.CreateTexture and strip then
        Skin.FadeArt(owner, holder)
        boxed = Skin.BoxAt(owner, holder, "drop", strip, BOX_INSET,
            Skin.Wash(theme), off and theme.muted or Skin.EdgeColor(theme))
    end
    -- Without our box the value still stands in the game's dark one, and stays light.
    Skin.Font(owner, widget.text, boxed and (off and theme.muted or theme.text) or nil, theme)

    local button = widget.button
    if boxed and button and button.GetRegions and button.CreateTexture then
        Skin.FadeArt(owner, button)
        Skin.Arrow(owner, button, "arrow", off and theme.muted or ns.Tokens(theme).dim)
        local glow = Skin.Texture(owner, button, "glow", "HIGHLIGHT")
        glow:SetAllPoints(boxed)
        glow:SetColorTexture(unpack(theme.highlight))
    end
    if type(widget.pullout) == "table" then List(owner, widget.pullout, theme) end
end

styles.Dropdown = function(widget, theme)
    Skin.Dropdown(widget, widget, theme)
end
