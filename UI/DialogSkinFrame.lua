-- The dialog skin's window: the options library's ornate frame and title plate make
-- way for a one pixel edge in the theme's border colour and a title bar like the
-- sheet's. The background itself is the panel from DialogBacking.lua.
local _, ns = ...
local Skin = ns.DialogSkin

local INSET = 6        -- where DialogBacking's panel ends, inside the frame
local BAR_HEIGHT = 20  -- the library keeps 27 pixels free above the contents
local CLEAR = { 0, 0, 0, 0 }

-- The title sits on the library's plate, half above the window. It moves onto our bar,
-- and goes back to exactly where it was.
local function MoveTitle(widget, title, bar)
    if not (title and title.GetNumPoints and title.GetPoint and title.ClearAllPoints and title.SetPoint) then return end
    if Skin.First(widget, "points", title) then
        local points = {}
        for index = 1, title:GetNumPoints() do
            local point, relativeTo, relativePoint, x, y = title:GetPoint(index)
            points[index] = { point, relativeTo, relativePoint, x, y }
        end
        Skin.Undo(widget, function()
            title:ClearAllPoints()
            for _, p in ipairs(points) do
                title:SetPoint(p[1], p[2], p[3], p[4], p[5])
            end
        end)
    end
    title:ClearAllPoints()
    title:SetPoint("CENTER", bar, "CENTER", 0, 0)
end

Skin.styles.Frame = function(widget, theme)
    local frame = widget.frame
    if not (frame and frame.GetRegions and frame.CreateTexture) then return end
    local accent, border = theme.accent, theme.border

    -- The title plate is the frame's only art on its top layer; the ornate edge and
    -- the stone behind it are the frame's backdrop.
    for _, region in ipairs({ frame:GetRegions() }) do
        if region.IsObjectType and region:IsObjectType("Texture") and not Skin.IsOurs(region)
            and region.GetDrawLayer and region:GetDrawLayer() == "OVERLAY" then
            Skin.Fade(widget, region)
        end
    end
    Skin.Backdrop(widget, frame, CLEAR, CLEAR)
    Skin.Box(widget, frame, border, 0, border[4] or 1, INSET)

    local bar = Skin.Texture(widget, frame, "titleBar", "BORDER")
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", INSET + 1, -(INSET + 1))
    bar:SetPoint("TOPRIGHT", -(INSET + 1), -(INSET + 1))
    bar:SetHeight(BAR_HEIGHT)
    bar:SetColorTexture(accent[1], accent[2], accent[3], 0.15)
    MoveTitle(widget, widget.titletext, bar)
    Skin.Font(widget, widget.titletext, accent, theme)

    -- The Close button and the status line under the contents are not named on the
    -- part; they are the two buttons among the frame's children that point back at it.
    if frame.GetChildren then
        for _, child in ipairs({ frame:GetChildren() }) do
            if child.obj == widget and child.IsObjectType and child:IsObjectType("Button") then
                if child.GetFontString and child:GetFontString() then
                    Skin.Button(widget, child, theme)
                else
                    Skin.Backdrop(widget, child, { accent[1], accent[2], accent[3], 0.06 }, border)
                end
            end
        end
    end
    Skin.Font(widget, widget.statustext, theme.muted, theme)

    -- The resize grip in the corner.
    local grip = widget.sizer_se
    if grip and grip.GetRegions then
        for _, region in ipairs({ grip:GetRegions() }) do
            if region.IsObjectType and region:IsObjectType("Texture") then
                Skin.Tint(widget, region, accent)
            end
        end
    end
end
