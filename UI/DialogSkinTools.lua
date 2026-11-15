-- The few kinds of change the dialog skin makes to a borrowed part, each with its undo
-- (see DialogSkin.lua): a text's font and colour, a picture's tint or visibility, a
-- panel's colours, and flat pictures of our own laid over the part.
--
-- Every function does nothing when the thing it is given is missing or lacks what it
-- needs: the parts differ between kinds and between versions of the library.
local _, ns = ...
local Skin = ns.DialogSkin

-- Theme font and colour on a text, at the size it already has so the layout the
-- window was sized for still fits. Without a colour the text keeps its own (texts
-- that sit inside a dark box of the game's own art must stay light).
function Skin.Font(widget, text, color, theme)
    if not (text and text.GetFont and text.SetFont and text.GetTextColor and text.SetTextColor) then return end
    if Skin.First(widget, "font", text) then
        local object = text.GetFontObject and text:GetFontObject()
        local file, size, flags = text:GetFont()
        local r, g, b, a = text:GetTextColor()
        local shadowR, shadowG, shadowB, shadowA, shadowX, shadowY
        if text.GetShadowColor and text.GetShadowOffset then
            shadowR, shadowG, shadowB, shadowA = text:GetShadowColor()
            shadowX, shadowY = text:GetShadowOffset()
        end
        Skin.Undo(widget, function()
            if object and text.SetFontObject then
                text:SetFontObject(object)
            elseif file then
                text:SetFont(file, size, flags)
            end
            if r then text:SetTextColor(r, g, b, a) end
            if shadowR and text.SetShadowColor then text:SetShadowColor(shadowR, shadowG, shadowB, shadowA) end
            if shadowX and text.SetShadowOffset then text:SetShadowOffset(shadowX, shadowY) end
        end)
    end
    local _, size = text:GetFont()
    if size then text:SetFont(ns.ThemeFont(theme), size, "") end
    if color then text:SetTextColor(color[1], color[2], color[3]) end
    if text.SetShadowOffset and text.SetShadowColor then
        text:SetShadowOffset(1, -1)
        text:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
    end
end

-- Makes a piece of the library's or the game's art invisible.
function Skin.Fade(widget, region)
    if not (region and region.GetAlpha and region.SetAlpha) then return end
    if Skin.First(widget, "alpha", region) then
        local alpha = region:GetAlpha()
        Skin.Undo(widget, function() region:SetAlpha(alpha or 1) end)
    end
    region:SetAlpha(0)
end

-- Colours a grey piece of art.
function Skin.Tint(widget, texture, color)
    if not (texture and texture.GetVertexColor and texture.SetVertexColor) then return end
    if Skin.First(widget, "tint", texture) then
        local r, g, b, a = texture:GetVertexColor()
        Skin.Undo(widget, function() texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1) end)
    end
    texture:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
end

-- Colours of a panel's background and edge.
function Skin.Backdrop(widget, panel, bg, border)
    if not (panel and panel.GetBackdropColor and panel.SetBackdropColor
        and panel.GetBackdropBorderColor and panel.SetBackdropBorderColor) then return end
    if Skin.First(widget, "backdrop", panel) then
        local r, g, b, a = panel:GetBackdropColor()
        local edgeR, edgeG, edgeB, edgeA = panel:GetBackdropBorderColor()
        Skin.Undo(widget, function()
            if r then panel:SetBackdropColor(r, g, b, a) end
            if edgeR then panel:SetBackdropBorderColor(edgeR, edgeG, edgeB, edgeA) end
        end)
    end
    panel:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    panel:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local owned = {} -- frame -> our pictures on it, by name
local ours = {}  -- every picture made here

function Skin.IsOurs(region)
    return ours[region] == true
end

-- A picture of our own on one of a part's frames. It is made once and stays with the
-- frame; it shows while the part is skinned and is hidden when the part is handed back.
function Skin.Texture(widget, holder, name, layer)
    local set = owned[holder]
    if not set then
        set = {}
        owned[holder] = set
    end
    local texture = set[name]
    if not texture then
        texture = holder:CreateTexture(nil, layer)
        set[name] = texture
        ours[texture] = true
    end
    if Skin.First(widget, "own", texture) then
        Skin.Undo(widget, function() texture:Hide() end)
    end
    texture:Show()
    return texture
end

local SIDES = {
    { "TOPLEFT", "TOPRIGHT", flat = true }, { "BOTTOMLEFT", "BOTTOMRIGHT", flat = true },
    { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" },
}

-- A flat box over a frame, `inset` pixels inside it: a fill and a one pixel edge in
-- one colour. Returns the fill, for anchoring other things to.
function Skin.Box(widget, holder, color, fillAlpha, edgeAlpha, inset)
    if not (holder and holder.CreateTexture) then return end
    inset = inset or 0
    local fill = Skin.Texture(widget, holder, "fill", "BACKGROUND")
    fill:ClearAllPoints()
    fill:SetPoint("TOPLEFT", inset, -inset)
    fill:SetPoint("BOTTOMRIGHT", -inset, inset)
    fill:SetColorTexture(color[1], color[2], color[3], fillAlpha)
    for index, side in ipairs(SIDES) do
        local edge = Skin.Texture(widget, holder, "edge" .. index, "BORDER")
        edge:ClearAllPoints()
        edge:SetPoint(side[1], fill, side[1])
        edge:SetPoint(side[2], fill, side[2])
        if side.flat then edge:SetHeight(1) else edge:SetWidth(1) end
        edge:SetColorTexture(color[1], color[2], color[3], edgeAlpha)
    end
    return fill
end
