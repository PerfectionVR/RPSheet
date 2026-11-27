-- The dialog skin's texts and boxes: labels, headings, the colour picker's name and
-- the titled boxes around groups of controls. The controls themselves are in
-- DialogSkinCheck.lua, DialogSkinSlider.lua, DialogSkinDropdown.lua and
-- DialogSkinEdit.lua; tabs and the tree in DialogSkinTabs.lua and DialogSkinTree.lua.
-- Kinds of part that no file lists are left as they are.
local _, ns = ...
local Skin = ns.DialogSkin
local styles = Skin.styles

-- A control's name: accent like a heading, muted while the control is switched off.
function Skin.NameColor(widget, theme)
    return widget.disabled and theme.muted or ns.Tokens(theme).dim
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
    Skin.Font(widget, widget.label, theme.muted, theme)
    Skin.Tint(widget, widget.left, Skin.EdgeColor(theme))
    Skin.Tint(widget, widget.right, Skin.EdgeColor(theme))
end

-- The swatch shows the picked colour and stays as it is.
styles.ColorPicker = function(widget, theme)
    Skin.Font(widget, widget.text, widget.disabled and theme.muted or theme.text, theme)
end

-- The edge and inside of a group's box, which keeps its rounded shape.
function Skin.Pane(widget, panel, theme, wash)
    Skin.Backdrop(widget, panel, Skin.Wash(theme, wash), ns.Tokens(theme).line)
end

-- A titled box around a group of controls. The box is the frame around the group's
-- contents, which the part does not name.
styles.InlineGroup = function(widget, theme)
    Skin.Font(widget, widget.titletext, theme.text, theme)
    local box = widget.content and widget.content.GetParent and widget.content:GetParent()
    if box and box ~= widget.frame then Skin.Pane(widget, box, theme) end
end

-- A group whose pages are picked from a dropdown above it. That dropdown is a part
-- the group keeps for itself, so it is styled, and undone, as a piece of the group.
styles.DropdownGroup = function(widget, theme)
    Skin.Font(widget, widget.titletext, theme.text, theme)
    Skin.Pane(widget, widget.border, theme, 0)
    if type(widget.dropdown) == "table" then Skin.Dropdown(widget, widget.dropdown, theme) end
end
