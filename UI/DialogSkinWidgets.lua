-- The dialog skin's controls: what the theme changes on each kind of part the options
-- library puts in a window. Kinds that are not listed here are left as they are.
--
-- Text that stands on the window's background takes the theme's colours. Text inside
-- a box of the game's own dark art (the value in a dropdown) only takes the font, so
-- it stays readable in a light theme; what is typed in an edit box or beside a slider
-- is not touched at all.
local _, ns = ...
local Skin = ns.DialogSkin
local styles = Skin.styles

-- A control's name: accent like a heading, muted while the control is switched off.
local function NameColor(widget, theme)
    return widget.disabled and theme.muted or theme.accent
end

-- Descriptions and summaries. A label works out its own height from its text, so it
-- is asked to do that again once the font has changed.
local function Label(widget, theme)
    Skin.Font(widget, widget.label, widget.disabled and theme.muted or theme.text, theme)
    if type(widget.OnWidthSet) == "function" and widget.frame and widget.frame.GetWidth then
        widget:OnWidthSet(widget.frame:GetWidth())
    end
end
styles.Label = Label
styles.InteractiveLabel = Label
styles.RPSheetTermLabel = Label

-- A heading line: its text and the rule on either side in the accent colour.
styles.Heading = function(widget, theme)
    Skin.Font(widget, widget.label, theme.accent, theme)
    Skin.Tint(widget, widget.left, theme.accent)
    Skin.Tint(widget, widget.right, theme.accent)
end

-- The box and its tick keep the game's look, which reads on any background.
styles.CheckBox = function(widget, theme)
    Skin.Font(widget, widget.text, widget.disabled and theme.muted or theme.text, theme)
    Skin.Font(widget, widget.desc, theme.muted, theme)
end

local function Slider(widget, theme)
    local ends = widget.disabled and theme.muted or theme.text
    Skin.Font(widget, widget.label, NameColor(widget, theme), theme)
    Skin.Font(widget, widget.lowtext, ends, theme)
    Skin.Font(widget, widget.hightext, ends, theme)
end
styles.Slider = Slider
styles.RPSheetSlider = Slider

styles.Dropdown = function(widget, theme)
    Skin.Font(widget, widget.label, NameColor(widget, theme), theme)
    Skin.Font(widget, widget.text, nil, theme)
end

-- One line of typing, with its small confirm button.
styles.EditBox = function(widget, theme)
    Skin.Font(widget, widget.label, NameColor(widget, theme), theme)
    Skin.Button(widget, widget.button, theme)
end

-- Several lines of typing, with the Accept button under them.
styles.MultiLineEditBox = function(widget, theme)
    Skin.Font(widget, widget.label, NameColor(widget, theme), theme)
    Skin.Button(widget, widget.button, theme)
end

-- A titled box around a group of controls. The box is the frame around the group's
-- contents, which the part does not name.
styles.InlineGroup = function(widget, theme)
    local accent = theme.accent
    Skin.Font(widget, widget.titletext, accent, theme)
    local box = widget.content and widget.content.GetParent and widget.content:GetParent()
    if box and box ~= widget.frame then
        Skin.Backdrop(widget, box, { accent[1], accent[2], accent[3], 0.06 }, theme.border)
    end
end
