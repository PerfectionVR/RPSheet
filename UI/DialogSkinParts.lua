-- More of the dialog skin's reversible changes (see DialogSkinTools.lua), for the
-- controls: a text's colour alone, a picture swapped for a flat colour or greyed and
-- tinted, a frame's art faded, a script that is followed while the part is ours, and
-- an arrow drawn from flat lines.
local _, ns = ...
local Skin = ns.DialogSkin

-- The colour of a control's box. A theme without a visible border (the see-through
-- one) still needs boxes that can be seen.
function Skin.EdgeColor(theme)
    local text = theme.text
    return { text[1], text[2], text[3], 0.18 }
end

-- A faint wash of the accent colour: the inside of a box.
function Skin.Wash(theme, alpha)
    local text = theme.text
    return { text[1], text[2], text[3], alpha or 0.06 }
end

-- Only the colour of a text; for what is typed, whose font is left to the library.
function Skin.Color(widget, text, color)
    if not (text and text.GetTextColor and text.SetTextColor) then return end
    if Skin.First(widget, "color", text) then
        local r, g, b, a = text:GetTextColor()
        Skin.Undo(widget, function()
            if r then text:SetTextColor(r, g, b, a) end
        end)
    end
    text:SetTextColor(color[1], color[2], color[3])
end

-- Swaps a picture for a flat colour (a glow that would not show on a light theme).
function Skin.Flat(widget, texture, color)
    if not (texture and texture.GetTexture and texture.SetTexture and texture.SetColorTexture
        and texture.GetBlendMode and texture.SetBlendMode
        and texture.GetVertexColor and texture.SetVertexColor) then return end
    if Skin.First(widget, "flat", texture) then
        local atlas = texture.GetAtlas and texture:GetAtlas()
        local file, blend = texture:GetTexture(), texture:GetBlendMode()
        local r, g, b, a = texture:GetVertexColor()
        Skin.Undo(widget, function()
            if atlas and texture.SetAtlas then texture:SetAtlas(atlas) else texture:SetTexture(file) end
            if blend then texture:SetBlendMode(blend) end
            texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
        end)
    end
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    texture:SetVertexColor(1, 1, 1, 1)
    texture:SetBlendMode("BLEND")
end

-- Greys a coloured picture, then tints it: a gold tick becomes one in the theme's colour.
function Skin.Grey(widget, texture, color)
    if not (texture and texture.IsDesaturated and texture.SetDesaturated) then return end
    if Skin.First(widget, "grey", texture) then
        local was = texture:IsDesaturated() and true or false
        Skin.Undo(widget, function() texture:SetDesaturated(was) end)
    end
    texture:SetDesaturated(true)
    Skin.Tint(widget, texture, color)
end

-- Makes all of a frame's own art invisible, to make way for ours.
function Skin.FadeArt(widget, frame)
    if not (frame and frame.GetRegions) then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region.IsObjectType and region:IsObjectType("Texture") and not Skin.IsOurs(region) then
            Skin.Fade(widget, region)
        end
    end
end

local hooks = {} -- frame -> script -> { run = what to do now, or nil }

-- Follows one of a frame's scripts with `run` while the part is ours. A script cannot
-- be unhooked, so the hook stays on the frame and does nothing once the part is back.
function Skin.Hook(widget, frame, script, run)
    if not (frame and frame.HookScript and frame.HasScript and frame:HasScript(script)) then return end
    local set = hooks[frame]
    if not set then
        set = {}
        hooks[frame] = set
    end
    local state = set[script]
    if not state then
        state = {}
        set[script] = state
        frame:HookScript(script, function(...)
            if state.run then pcall(state.run, ...) end
        end)
    end
    state.run = run
    if Skin.First(widget, "hook", state) then
        Skin.Undo(widget, function() state.run = nil end)
    end
end

local ROWS = 5

-- A small arrow in the middle of a frame, pointing down unless `up`.
function Skin.Arrow(widget, holder, key, color, up)
    if not (holder and holder.CreateTexture) then return end
    for row = 1, ROWS do
        local line = Skin.Texture(widget, holder, key .. row, "OVERLAY")
        line:ClearAllPoints()
        line:SetSize(2 * (ROWS - row) + 1, 1)
        line:SetPoint("CENTER", holder, "CENTER", 0, (up and -1 or 1) * (3 - row))
        line:SetColorTexture(color[1], color[2], color[3], 1)
    end
end

local STATES = { "Normal", "Highlight", "Disabled" }
local fonts = {}
local isOurs = {} -- the fonts made here
local kept = setmetatable({}, { __mode = "k" }) -- button -> state -> the font to put back

-- A font of our own for one state of a button: the theme's font and `color`, at the
-- size and spacing of the game's font `base`.
function Skin.StateFont(name, base, theme, color)
    local font = fonts[name]
    if not font then
        font = CreateFont(name)
        font:CopyFontObject(base)
        fonts[name] = font
        isOurs[font] = true
    end
    local _, size = base:GetFont()
    font:SetFont(ns.ThemeFont(theme), size or 12, "")
    font:SetTextColor(color[1], color[2], color[3])
    font:SetShadowOffset(1, -1)
    font:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
    return font
end

-- Gives a button our fonts, by state: { Normal = , Highlight = , Disabled = }. A state
-- the button has no font for is left alone: it could not be put back afterwards.
function Skin.ButtonFonts(widget, button, wanted)
    for _, state in ipairs(STATES) do
        local get, set = button["Get" .. state .. "FontObject"], button["Set" .. state .. "FontObject"]
        local was = wanted[state] and get and set and get(button)
        if was then
            -- The font to put back is the last one that wasn't ours: the library gives
            -- a line of a tree another font when the line takes another place.
            local own = kept[button]
            if not own then
                own = {}
                kept[button] = own
            end
            if not isOurs[was] then own[state] = was end
            if Skin.First(widget, "font" .. state, button) then
                Skin.Undo(widget, function()
                    if own[state] then set(button, own[state]) end
                end)
            end
            set(button, wanted[state])
        end
    end
end
