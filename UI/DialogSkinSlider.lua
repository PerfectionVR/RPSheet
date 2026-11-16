-- The dialog skin's sliders and scroll bars: a thin flat track with a flat handle in
-- the accent colour. The game's handle is made invisible and ours rides on it, so it
-- is always where the library put the handle.
local _, ns = ...
local Skin = ns.DialogSkin
local styles = Skin.styles

local CLEAR = { 0, 0, 0, 0 }
local TRACK = 4 -- how thick the track is

-- Track and handle on the game's slider frame; `upright` for one that runs top to bottom.
function Skin.Bar(widget, slider, theme, upright, off)
    if not (slider and slider.CreateTexture and slider.GetThumbTexture) then return end
    local thumb = slider:GetThumbTexture()
    if not thumb then return end
    Skin.Backdrop(widget, slider, CLEAR, CLEAR) -- the groove, where the slider has one
    Skin.Fade(widget, thumb)

    local edge = Skin.EdgeColor(theme)
    local track = Skin.Texture(widget, slider, "track", "BACKGROUND")
    track:ClearAllPoints()
    if upright then
        track:SetPoint("TOP")
        track:SetPoint("BOTTOM")
        track:SetWidth(TRACK)
    else
        track:SetPoint("LEFT")
        track:SetPoint("RIGHT")
        track:SetHeight(TRACK)
    end
    track:SetColorTexture(edge[1], edge[2], edge[3], 0.5)

    local color = off and theme.muted or theme.accent
    local knob = Skin.Texture(widget, slider, "knob", "ARTWORK")
    knob:ClearAllPoints()
    knob:SetPoint("CENTER", thumb, "CENTER")
    knob:SetSize(8, upright and 20 or 14)
    knob:SetColorTexture(color[1], color[2], color[3], 1)
end

local ARROWS = { ScrollUpButton = true, ScrollDownButton = false } -- name -> points up

-- A scroll bar of the game's older kind: the bar itself and its two arrow buttons.
function Skin.ScrollBar(widget, bar, theme)
    if not (bar and bar.GetRegions and bar.GetThumbTexture) then return end
    Skin.FadeArt(widget, bar)
    Skin.Bar(widget, bar, theme, true)
    local name = bar.GetName and bar:GetName()
    for key, up in pairs(ARROWS) do
        local button = bar[key] or (name and _G[name .. key])
        if type(button) == "table" and button.GetRegions and button.CreateTexture then
            Skin.FadeArt(widget, button)
            Skin.Arrow(widget, button, "arrow", theme.accent, up)
        end
    end
end

styles.ScrollFrame = function(widget, theme)
    Skin.ScrollBar(widget, widget.scrollbar, theme)
end

-- The small box under a slider, where its number can be typed, lights up under the
-- mouse; the library does that with greys of its own, which ours follow.
local function BoxEdge(lit)
    return function(box)
        local theme = Skin.Theme()
        if not (theme and box.SetBackdropBorderColor) then return end
        local color = lit and theme.accent or Skin.EdgeColor(theme)
        box:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
    end
end
local Lit, Unlit = BoxEdge(true), BoxEdge(false)

local function Slider(widget, theme)
    local off = widget.disabled
    local ends = off and theme.muted or theme.text
    Skin.Font(widget, widget.label, Skin.NameColor(widget, theme), theme)
    Skin.Font(widget, widget.lowtext, ends, theme)
    Skin.Font(widget, widget.hightext, ends, theme)
    Skin.Bar(widget, widget.slider, theme, false, off)

    -- The number keeps its font: the library works around a loading fault there.
    local box = widget.editbox
    if box and box.GetBackdropColor then
        Skin.Backdrop(widget, box, Skin.Wash(theme), Skin.EdgeColor(theme))
        Skin.Color(widget, box, ends)
        Skin.Hook(widget, box, "OnEnter", Lit)
        Skin.Hook(widget, box, "OnLeave", Unlit)
    end
end
styles.Slider = Slider
styles.RPSheetSlider = Slider
