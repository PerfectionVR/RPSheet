-- A slider whose handle jumps from step to step while it is dragged. The standard one
-- already rounds its value to the step, but its handle glides in between.
--
-- It is the standard slider with one setting changed, registered under its own name
-- so that other addons' sliders are left as they are.
local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")

local TYPE = "RPSheetSlider"

AceGUI:RegisterWidgetType(TYPE, function()
    local widget = AceGUI.WidgetRegistry["Slider"]()
    widget.type = TYPE -- reused only for our own sliders
    widget.slider:SetObeyStepOnDrag(true)
    return widget
end, 1)

-- Makes every slider in an options table (and the groups inside it) use it.
function ns.SnapSliders(option)
    if option.type == "range" then
        option.dialogControl = TYPE
    end
    for _, child in pairs(option.args or {}) do
        ns.SnapSliders(child)
    end
end
