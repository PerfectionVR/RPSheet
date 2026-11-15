-- Fake frame API, part 1: regions, anchors and sizes, visibility, scripts, textures,
-- font strings and font objects. Loaded by t-test-windows-ui.lua.
--
-- Objects are strict like the game's: a method the real object type doesn't have is
-- nil here too, so calling it is an error, and a feature test (`if text.GetFont`) gives
-- the answer the game would. Each object's state is kept beside it in S, never on the
-- object, because addons and AceGUI put fields of their own on frames.
UIFAKE = rawget(_G, "UIFAKE") or {}
local F = UIFAKE
F.screenWidth, F.screenHeight = 1600, 900
F.mouse = { x = -5000, y = -5000 } -- where the cursor is; F.MoveMouse sets it
F.charWidth = 0.5                  -- width of one letter, as a share of the font size
F.frames = {}                      -- every frame made, for OnUpdate
F.classes = {}
F.unknownTemplates = {}

local S = {} -- object -> its state
F.S = S

local function class(name, parent)
    local c = { __type = name, __parent = parent }
    if parent then setmetatable(c, { __index = parent }) end
    c.__mt = { __index = c }
    F.classes[name] = c
    return c
end
F.class = class

local function need(value, kind, what)
    if type(value) ~= kind then error(("%s: %s expected, got %s"):format(what, kind, type(value)), 3) end
end

local PARENT, SCREEN = "<parent>", "<screen>"
local PX = { LEFT = 0, CENTER = 0.5, RIGHT = 1, TOPLEFT = 0, TOP = 0.5, TOPRIGHT = 1, BOTTOMLEFT = 0, BOTTOM = 0.5, BOTTOMRIGHT = 1 }
local PY = { TOP = 1, TOPLEFT = 1, TOPRIGHT = 1, LEFT = 0.5, CENTER = 0.5, RIGHT = 0.5, BOTTOMLEFT = 0, BOTTOM = 0, BOTTOMRIGHT = 0 }

---------------------------------------------------------------------------
-- Geometry
---------------------------------------------------------------------------
-- Left, bottom, width, height of an object, and whether it is really placed (an
-- object without anchors is worked out as if it sat at the screen's corner, so the
-- sizes of what is anchored inside it can still be told).
local realpcall = pcall -- the tests listen in on the global one
local visiting = {}
F.cycles = {} -- anchor loops that were met: the game would refuse or misplace these
local rectInner
-- Worked-out rectangles are kept until anything that can move or resize a region
-- changes (`touch`): frames in a chain that each hang on the one before by two anchors
-- would otherwise be worked out again and again.
local version = 0
local function touch() version = version + 1 end
F.Touch = touch
local function rect(obj)
    local s = S[obj]
    if s.rv == version then return s.r1, s.r2, s.r3, s.r4, s.r5, s.r6, s.r7 end
    if visiting[obj] then
        if #F.cycles < 20 then
            local parts = {}
            for other in pairs(visiting) do
                local s = S[other]
                local points = {}
                for _, p in ipairs(s.points) do
                    points[#points + 1] = p.point .. ">" .. (S[p.rel] and (S[p.rel].name or S[p.rel].type) or tostring(p.rel)) .. "." .. p.relPoint
                end
                parts[#parts + 1] = ("%s%s(%s)"):format(other == obj and "*" or "", tostring(s.name or s.type), table.concat(points, " "))
            end
            F.cycles[#F.cycles + 1] = table.concat(parts, "; ")
        end
        return 0, 0, 0, 0, false
    end
    visiting[obj] = true
    local ok, l, b, w, h, placed, fromX, fromY = realpcall(rectInner, obj)
    visiting[obj] = nil
    if not ok then error(l, 0) end
    s.rv, s.r1, s.r2, s.r3, s.r4, s.r5, s.r6, s.r7 = version, l, b, w, h, placed, fromX, fromY
    return l, b, w, h, placed, fromX, fromY
end
function rectInner(obj)
    local s = S[obj]
    local xl, xr, xc, yt, yb, yc
    local placed = #s.points > 0
    for _, p in ipairs(s.points) do
        local rel = p.rel
        if rel == PARENT then rel = s.parent or SCREEN end
        local rl, rb, rw, rh, rok
        if rel == SCREEN then
            rl, rb, rw, rh, rok = 0, 0, F.screenWidth, F.screenHeight, true
        else
            rl, rb, rw, rh, rok = rect(rel)
        end
        placed = placed and rok
        local x, y = rl + rw * PX[p.relPoint] + p.x, rb + rh * PY[p.relPoint] + p.y
        local fx, fy = PX[p.point], PY[p.point]
        if fx == 0 then xl = x elseif fx == 1 then xr = x else xc = x end
        if fy == 1 then yt = y elseif fy == 0 then yb = y else yc = y end
    end
    local w, h
    if xl and xr then w = math.max(0, xr - xl) else w = (s.w and s.w > 0) and s.w or (obj.__naturalWidth and obj:__naturalWidth() or 0) end
    if yt and yb then h = math.max(0, yt - yb) else h = (s.h and s.h > 0) and s.h or (obj.__naturalHeight and obj:__naturalHeight(w) or 0) end
    local left = xl or (xr and xr - w) or (xc and xc - w / 2) or 0
    local bottom = yb or (yt and yt - h) or (yc and yc - h / 2) or 0
    return left, bottom, w, h, placed, (xl and xr) and true or false, (yt and yb) and true or false
end
F.Rect = rect

-- The size the game reports. A size that comes from two anchors is only known once
-- the frame is really placed on the screen; until then it is 0, as in the game.
local function size(obj)
    local _, _, w, h, placed, fromX, fromY = rect(obj)
    if not placed then
        if fromX then w = 0 end
        if fromY then h = 0 end
    end
    return w, h, placed, fromX, fromY
end
F.Size = size

-- Sizes and OnSizeChanged. A frame whose own size is set hears of it at once. A frame
-- whose size hangs on another (two anchors) hears later: the game works such sizes out
-- again before it draws the next frame, so moving a frame by clearing and setting its
-- anchors is not seen as a change, and handlers can't call each other in a circle
-- within one step. Those frames wait in `dirty` until F.FlushLayout (called by
-- F.Update, F.Settle and before every mouse action).
local dirty, isDirty = {}, {}
local function moved(obj)
    if S[obj].isFrame and not isDirty[obj] then
        isDirty[obj] = true
        dirty[#dirty + 1] = obj
    end
end

F.sizeLoops = {} -- frames that kept resizing each other; the tests report them
local function resized(obj)
    local s = S[obj]
    if not s.isFrame then return end
    local w, h, placed, fromX, fromY = size(obj)
    -- a size from anchors that can't be worked out yet is no news
    if not placed and (fromX or fromY) then
        if fromX then w = s.cw end
        if fromY then h = s.ch end
    end
    if w == s.cw and h == s.ch then return end
    s.cw, s.ch = w, h
    for _, child in ipairs(s.children) do
        if #S[child].points >= 2 then moved(child) end
    end
    for dep in pairs(s.deps) do
        if S[dep].parent ~= obj and #S[dep].points >= 2 then moved(dep) end
    end
    local fn = s.scripts.OnSizeChanged
    if fn then fn(obj, w, h) end
end

function F.FlushLayout()
    if F.flushing then return end
    F.flushing = true
    local last
    for _ = 1, 60 do
        if #dirty == 0 then break end
        local list = dirty
        dirty, isDirty = {}, {}
        for _, obj in ipairs(list) do
            local ok, problem = realpcall(resized, obj)
            if not ok then
                F.flushing = false
                error(problem, 0)
            end
            last = obj
        end
    end
    F.flushing = false
    if #dirty > 0 then
        -- still not settled: in the game this would be a layout redone on every frame
        if #F.sizeLoops < 5 then
            local s = S[last]
            F.sizeLoops[#F.sizeLoops + 1] = ("%s %s %gx%g"):format(s.type, tostring(s.name or (last.obj and last.obj.type) or ""), s.cw, s.ch)
        end
        dirty, isDirty = {}, {}
    end
end

-- A size was set on the object itself. Where two anchors decide that side instead,
-- the number set changes nothing by itself.
local function explicit(obj, width, height)
    if not S[obj].isFrame then return end
    local _, _, _, fromX, fromY = size(obj)
    if (width and not fromX) or (height and not fromY) then resized(obj) else moved(obj) end
end

local function visible(obj)
    local s = S[obj]
    while s do
        if not s.shown then return false end
        if not s.parent then return true end
        s = S[s.parent]
    end
    return true
end

local function fire(obj, name, ...)
    local fn = S[obj].scripts[name]
    if fn then fn(obj, ...) return true end
    return false
end
F.Fire = fire

local function shownChanged(obj, script)
    fire(obj, script)
    local s = S[obj]
    if not s.isFrame then return end
    -- a copy: a handler may make or move frames
    local list = {}
    for i, child in ipairs(s.children) do list[i] = child end
    for _, child in ipairs(list) do
        if S[child].shown and S[child].parent == obj then shownChanged(child, script) end
    end
end

---------------------------------------------------------------------------
-- Region: what frames, textures and font strings share
---------------------------------------------------------------------------
local Region = class("Region")

function Region:GetName() return S[self].name end
function Region:GetDebugName() return S[self].name or S[self].type end
function Region:GetObjectType() return S[self].type end
function Region:IsObjectType(kind)
    local c = F.classes[S[self].type]
    while c do
        if c.__type == kind then return true end
        c = c.__parent
    end
    return false
end
function Region:IsForbidden() return false end
function Region:IsProtected() return false, false end
function Region:CanChangeProtectedState() return true end
function Region:GetParent() return S[self].parent end

local function unlist(list, obj)
    for i = #list, 1, -1 do
        if list[i] == obj then table.remove(list, i) end
    end
end

function Region:SetParent(parent)
    if type(parent) == "string" then parent = rawget(_G, parent) end
    if parent ~= nil and not S[parent] then error("SetParent: not a frame: " .. tostring(parent), 2) end
    local s = S[self]
    if s.parent == parent then return end
    local was = visible(self)
    if s.parent then
        unlist(s.isFrame and S[s.parent].children or S[s.parent].regions, self)
    end
    s.parent = parent
    touch()
    if parent then
        local list = s.isFrame and S[parent].children or S[parent].regions
        list[#list + 1] = self
    end
    local now = visible(self)
    if was ~= now then shownChanged(self, now and "OnShow" or "OnHide") end
    moved(self)
end

function Region:ClearAllPoints()
    local s = S[self]
    for _, p in ipairs(s.points) do
        if S[p.rel] then S[p.rel].deps[self] = nil end
    end
    s.points = {}
    touch()
    moved(self)
end

function Region:SetPoint(point, ...)
    need(point, "string", "SetPoint")
    point = point:upper()
    if not PX[point] then error("SetPoint: unknown point " .. point, 2) end
    local n = select("#", ...)
    local a, b, c, d = ...
    local rel, relPoint, x, y
    if n == 0 then
        rel, relPoint, x, y = PARENT, point, 0, 0
    elseif type(a) == "number" then
        rel, relPoint, x, y = PARENT, point, a, b or 0
    else
        rel = a
        if type(rel) == "string" then
            rel = rawget(_G, rel)
            if not rel then error("SetPoint: no frame named " .. tostring(a), 2) end
        end
        if rel == nil then rel = SCREEN end
        if type(b) == "number" then
            relPoint, x, y = point, b, c or 0
        else
            relPoint, x, y = b or point, c or 0, d or 0
        end
    end
    if rel ~= PARENT and rel ~= SCREEN and not S[rel] then error("SetPoint: not a region: " .. tostring(rel), 2) end
    if rel == self then error("SetPoint: a region can't be anchored to itself", 2) end
    need(relPoint, "string", "SetPoint relativePoint")
    relPoint = relPoint:upper()
    if not PX[relPoint] then error("SetPoint: unknown point " .. relPoint, 2) end
    need(x, "number", "SetPoint x")
    need(y, "number", "SetPoint y")
    local s = S[self]
    local entry = { point = point, rel = rel, relPoint = relPoint, x = x, y = y }
    local replaced = false
    for i, p in ipairs(s.points) do
        if p.point == point then s.points[i] = entry; replaced = true end
    end
    if not replaced then s.points[#s.points + 1] = entry end
    if S[rel] then S[rel].deps[self] = true end
    touch()
    moved(self)
end

function Region:SetAllPoints(rel)
    self:ClearAllPoints()
    if rel == nil then
        self:SetPoint("TOPLEFT")
        self:SetPoint("BOTTOMRIGHT")
    else
        self:SetPoint("TOPLEFT", rel, "TOPLEFT", 0, 0)
        self:SetPoint("BOTTOMRIGHT", rel, "BOTTOMRIGHT", 0, 0)
    end
end

function Region:GetNumPoints() return #S[self].points end
function Region:GetPoint(index)
    local s = S[self]
    local p = s.points[index or 1]
    if not p then return nil end
    local rel = p.rel
    if rel == PARENT then rel = s.parent elseif rel == SCREEN then rel = nil end
    return p.point, rel, p.relPoint, p.x, p.y
end

function Region:SetWidth(width)
    need(width, "number", "SetWidth")
    S[self].w = width
    touch()
    explicit(self, true, false)
end
function Region:SetHeight(height)
    need(height, "number", "SetHeight")
    S[self].h = height
    touch()
    explicit(self, false, true)
end
function Region:SetSize(width, height)
    need(width, "number", "SetSize")
    need(height, "number", "SetSize")
    S[self].w, S[self].h = width, height
    touch()
    explicit(self, true, true)
end
function Region:GetWidth() return (size(self)) end
function Region:GetHeight() local _, h = size(self) return h end
function Region:GetSize() local w, h = size(self) return w, h end
function Region:GetLeft() local l, _, _, _, ok = rect(self) if ok then return l end end
function Region:GetBottom() local _, b, _, _, ok = rect(self) if ok then return b end end
function Region:GetRight() local l, _, w, _, ok = rect(self) if ok then return l + w end end
function Region:GetTop() local _, b, _, h, ok = rect(self) if ok then return b + h end end
function Region:GetCenter() local l, b, w, h, ok = rect(self) if ok then return l + w / 2, b + h / 2 end end
function Region:GetRect() local l, b, w, h, ok = rect(self) if ok then return l, b, w, h end end
function Region:GetScaledRect() return self:GetRect() end

function Region:Show()
    local s = S[self]
    if s.shown then return end
    s.shown = true
    if visible(self) then shownChanged(self, "OnShow") end
end
function Region:Hide()
    local s = S[self]
    if not s.shown then return end
    local was = visible(self)
    s.shown = false
    if was then shownChanged(self, "OnHide") end
end
function Region:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Region:IsShown() return S[self].shown end
function Region:IsVisible() return visible(self) end

function Region:SetAlpha(alpha) need(alpha, "number", "SetAlpha") S[self].alpha = alpha end
function Region:GetAlpha() return S[self].alpha end
function Region:GetEffectiveAlpha()
    local alpha, s = 1, S[self]
    while s do alpha = alpha * s.alpha; s = s.parent and S[s.parent] end
    return alpha
end
function Region:SetScale(scale)
    need(scale, "number", "SetScale")
    if scale <= 0 then error("SetScale: scale must be above 0", 2) end
    S[self].scale = scale
end
function Region:GetScale() return S[self].scale end
function Region:GetEffectiveScale()
    local scale, s = 1, S[self]
    while s do scale = scale * s.scale; s = s.parent and S[s.parent] end
    return scale
end
function Region:SetIgnoreParentAlpha() end
function Region:SetIgnoreParentScale() end

function Region:IsMouseOver()
    local l, b, w, h, ok = rect(self)
    if not ok or not visible(self) then return false end
    local scale = self:GetEffectiveScale()
    local x, y = F.mouse.x / scale, F.mouse.y / scale
    return x >= l and x <= l + w and y >= b and y <= b + h
end
function Region:EnableMouse(on) S[self].mouse = on and true or false end
function Region:IsMouseEnabled() return S[self].mouse end
function Region:SetMouseClickEnabled(on) S[self].mouse = on and true or false end
function Region:SetMouseMotionEnabled(on) S[self].mouseMotion = on and true or false end
function Region:IsMouseClickEnabled() return S[self].mouse end
function Region:IsMouseMotionEnabled() return S[self].mouse or S[self].mouseMotion or false end
function Region:SetPassThroughButtons() end
function Region:SetPropagateMouseClicks() end
function Region:SetPropagateMouseMotion() end

-- Scripts. A script the object type doesn't have is an error, as in the game.
local COMMON = { "OnShow", "OnHide", "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp", "OnMouseWheel" }
function F.Scripts(c, names)
    c.__scripts = c.__scripts or {}
    for _, name in ipairs(names) do c.__scripts[name] = true end
end
F.Scripts(Region, COMMON)

local function hasScript(self, name)
    local c = F.classes[S[self].type]
    while c do
        local own = rawget(c, "__scripts")
        if own and own[name] then return true end
        c = c.__parent
    end
    return false
end
function Region:HasScript(name) return hasScript(self, name) end
function Region:SetScript(name, fn)
    if not hasScript(self, name) then error(("%s doesn't have a \"%s\" script"):format(S[self].type, tostring(name)), 2) end
    if fn ~= nil and type(fn) ~= "function" then error("SetScript: function expected, got " .. type(fn), 2) end
    S[self].scripts[name] = fn
end
function Region:GetScript(name)
    if not hasScript(self, name) then error(("%s doesn't have a \"%s\" script"):format(S[self].type, tostring(name)), 2) end
    return S[self].scripts[name]
end
function Region:HookScript(name, fn)
    if not hasScript(self, name) then error(("%s doesn't have a \"%s\" script"):format(S[self].type, tostring(name)), 2) end
    need(fn, "function", "HookScript")
    local old = S[self].scripts[name]
    if old then
        S[self].scripts[name] = function(...) old(...); fn(...) end
    else
        S[self].scripts[name] = fn
    end
end
function Region:CreateAnimationGroup()
    local group = {}
    local function nothing() end
    return setmetatable(group, { __index = function(_, key)
        if key == "CreateAnimation" then return function() return setmetatable({}, { __index = function() return nothing end }) end end
        if key == "IsPlaying" then return function() return false end end
        return nothing
    end })
end

-- Draw layers, for textures and font strings.
local Layered = class("LayeredRegion", Region)
function Layered:SetDrawLayer(layer, sublevel)
    need(layer, "string", "SetDrawLayer")
    S[self].layer, S[self].sublevel = layer:upper(), sublevel or 0
end
function Layered:GetDrawLayer() return S[self].layer, S[self].sublevel end
function Layered:SetVertexColor(r, g, b, a)
    need(r, "number", "SetVertexColor"); need(g, "number", "SetVertexColor"); need(b, "number", "SetVertexColor")
    S[self].vertex = { r, g, b, a or 1 }
end
function Layered:GetVertexColor() local v = S[self].vertex return v[1], v[2], v[3], v[4] end

local function newState(kind, name, parent)
    return {
        type = kind, name = name, parent = parent, points = {}, deps = {}, scripts = {},
        shown = true, alpha = 1, scale = 1, mouse = false, vertex = { 1, 1, 1, 1 },
    }
end
F.newState = newState

---------------------------------------------------------------------------
-- Texture
---------------------------------------------------------------------------
local Texture = class("Texture", Layered)

function Texture:SetTexture(file)
    if file ~= nil and type(file) ~= "string" and type(file) ~= "number" then
        error("SetTexture: file expected, got " .. type(file), 2)
    end
    local s = S[self]
    s.file, s.atlas, s.color = file, nil, nil
    return true
end
function Texture:GetTexture() return S[self].file end
function Texture:GetTextureFileID() return S[self].file end
function Texture:GetTextureFilePath() return S[self].file end
function Texture:SetAtlas(atlas, useSize)
    if atlas ~= nil then need(atlas, "string", "SetAtlas") end
    local s = S[self]
    s.atlas, s.file, s.color = atlas, atlas and ("atlas:" .. atlas) or nil, nil
end
function Texture:GetAtlas() return S[self].atlas end
function Texture:SetColorTexture(r, g, b, a)
    need(r, "number", "SetColorTexture"); need(g, "number", "SetColorTexture"); need(b, "number", "SetColorTexture")
    if a ~= nil then need(a, "number", "SetColorTexture") end
    local s = S[self]
    s.color, s.file, s.atlas = { r, g, b, a or 1 }, nil, nil
end
function Texture:SetTexCoord(...) S[self].coords = { ... } end
function Texture:GetTexCoord() return unpack(S[self].coords or { 0, 0, 0, 1, 1, 0, 1, 1 }) end
function Texture:SetBlendMode(mode) need(mode, "string", "SetBlendMode") S[self].blend = mode:upper() end
function Texture:GetBlendMode() return S[self].blend or "BLEND" end
function Texture:SetDesaturated(on) S[self].desaturated = on and true or false end
function Texture:IsDesaturated() return S[self].desaturated or false end
function Texture:SetDesaturation(amount) S[self].desaturated = (amount or 0) > 0 end
function Texture:GetDesaturation() return S[self].desaturated and 1 or 0 end
function Texture:SetGradient() end
function Texture:SetRotation() end
function Texture:SetHorizTile() end
function Texture:SetVertTile() end
function Texture:SetSnapToPixelGrid() end
function Texture:SetTexelSnappingBias() end
function Texture:SetMask() end
function Texture:AddMaskTexture() end
function Texture:SetTextureSliceMargins() end
function Texture:SetTextureSliceMode() end

---------------------------------------------------------------------------
-- Fonts: what font strings, edit boxes and font objects share
---------------------------------------------------------------------------
-- A property comes from the thing itself if it was set there, otherwise from its font
-- object, otherwise it isn't there.
local function fontProp(self, key)
    local s = S[self]
    local seen = 0
    while s do
        if s[key] ~= nil then return s[key] end
        s = s.fontObject and S[s.fontObject]
        seen = seen + 1
        if seen > 20 then return nil end
    end
end
F.fontProp = fontProp

local FontMethods = {}
function FontMethods:SetFont(file, size, flags)
    if type(file) ~= "string" then error("SetFont: font file expected, got " .. type(file), 2) end
    need(size, "number", "SetFont size")
    if size <= 0 then error("SetFont: font height must be above 0", 2) end
    if flags ~= nil then need(flags, "string", "SetFont flags") end
    local s = S[self]
    -- Its own font: the rest of what the font object gave is kept, the object is let go.
    if s.fontObject then
        for _, key in ipairs({ "textColor", "shadowColor", "shadowOffset", "justifyH", "justifyV", "spacing" }) do
            if s[key] == nil then s[key] = fontProp(self, key) end
        end
        s.fontObject = nil
    end
    s.font = { file, size, flags or "" }
    touch()
    return true
end
function FontMethods:GetFont()
    local font = fontProp(self, "font")
    if font then return font[1], font[2], font[3] end
end
function FontMethods:SetFontObject(object)
    if type(object) == "string" then object = _G[object] end
    if object ~= nil and not (S[object] and S[object].type == "Font") then error("SetFontObject: font object expected", 2) end
    local s = S[self]
    s.fontObject = object
    touch()
    s.font, s.textColor, s.shadowColor, s.shadowOffset, s.justifyH, s.justifyV, s.spacing = nil, nil, nil, nil, nil, nil, nil
end
function FontMethods:GetFontObject() return S[self].fontObject end
function FontMethods:SetTextColor(r, g, b, a)
    need(r, "number", "SetTextColor"); need(g, "number", "SetTextColor"); need(b, "number", "SetTextColor")
    if a ~= nil then need(a, "number", "SetTextColor") end
    S[self].textColor = { r, g, b, a or 1 }
end
function FontMethods:GetTextColor()
    local c = fontProp(self, "textColor") or { 1, 1, 1, 1 }
    return c[1], c[2], c[3], c[4]
end
function FontMethods:SetShadowColor(r, g, b, a)
    need(r, "number", "SetShadowColor"); need(g, "number", "SetShadowColor"); need(b, "number", "SetShadowColor")
    if a ~= nil then need(a, "number", "SetShadowColor") end
    S[self].shadowColor = { r, g, b, a or 1 }
end
function FontMethods:GetShadowColor()
    local c = fontProp(self, "shadowColor") or { 0, 0, 0, 0 }
    return c[1], c[2], c[3], c[4]
end
function FontMethods:SetShadowOffset(x, y)
    need(x, "number", "SetShadowOffset"); need(y, "number", "SetShadowOffset")
    S[self].shadowOffset = { x, y }
end
function FontMethods:GetShadowOffset()
    local o = fontProp(self, "shadowOffset") or { 0, 0 }
    return o[1], o[2]
end
function FontMethods:SetJustifyH(how) need(how, "string", "SetJustifyH") S[self].justifyH = how:upper() end
function FontMethods:GetJustifyH() return fontProp(self, "justifyH") or "CENTER" end
function FontMethods:SetJustifyV(how) need(how, "string", "SetJustifyV") S[self].justifyV = how:upper() end
function FontMethods:GetJustifyV() return fontProp(self, "justifyV") or "MIDDLE" end
function FontMethods:SetSpacing(spacing) need(spacing, "number", "SetSpacing") S[self].spacing = spacing; touch() end
function FontMethods:GetSpacing() return fontProp(self, "spacing") or 0 end
function FontMethods:SetIndentedWordWrap() end
function FontMethods:GetIndentedWordWrap() return false end
F.FontMethods = FontMethods

-- Font objects (GameFontNormal and the ones made with CreateFont).
local Font = class("Font")
for name, method in pairs(FontMethods) do Font[name] = method end
function Font:GetName() return S[self].name end
function Font:GetObjectType() return "Font" end
function Font:IsObjectType(kind) return kind == "Font" end
function Font:CopyFontObject(other)
    if type(other) == "string" then other = _G[other] end
    if not (S[other] and S[other].type == "Font") then error("CopyFontObject: font object expected", 2) end
    local s = S[self]
    for _, key in ipairs({ "font", "textColor", "shadowColor", "shadowOffset", "justifyH", "justifyV", "spacing" }) do
        local value = fontProp(other, key)
        s[key] = type(value) == "table" and { unpack(value) } or value
    end
    touch()
end
function Font:SetAlpha() end
function Font:GetAlpha() return 1 end

function F.NewFont(name, file, size, r, g, b)
    local font = setmetatable({}, Font.__mt)
    S[font] = { type = "Font", name = name }
    if file then
        S[font].font = { file, size, "" }
        S[font].textColor = { r or 1, g or 1, b or 1, 1 }
    end
    if name then rawset(_G, name, font) end
    return font
end

-- The game's own fonts, made the first time one is asked for by name.
function F.GameFont(name)
    if type(name) ~= "string" then return nil end
    if not (name:find("^GameFont") or name:find("^ChatFont") or name:find("^NumberFont") or name:find("^SystemFont")
        or name:find("^GameTooltip.*Text") or name:find("^Tooltip.*Font") or name:find("^QuestFont") or name:find("^Friends.*Font")) then
        return nil
    end
    local size = (name:find("Small") and 10) or (name:find("Huge") and 20) or (name:find("Large") and 16) or (name:find("Med") and 14) or 12
    if name:find("^ChatFont") then size = name:find("Small") and 12 or 14 end
    local r, g, b = 1, 0.82, 0
    if name:find("Highlight") or name:find("White") or name:find("^Chat") or name:find("^Number") then r, g, b = 1, 1, 1 end
    if name:find("Disable") then r, g, b = 0.5, 0.5, 0.5 end
    if name:find("Red") then r, g, b = 1, 0.1, 0.1 end
    if name:find("Green") then r, g, b = 0.1, 1, 0.1 end
    return F.NewFont(name, "Fonts\\FRIZQT__.TTF", size, r, g, b)
end

---------------------------------------------------------------------------
-- Text measuring: an estimate from the number of letters
---------------------------------------------------------------------------
-- The text as it reads on screen, without colour codes and links.
function F.Plain(text)
    text = tostring(text or "")
    text = text:gsub("||", "\1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "\2"):gsub("|A.-|a", "\2")
    text = text:gsub("|H.-|h", ""):gsub("|h", ""):gsub("|n", "\n"):gsub("\1", "|")
    return text
end

-- How many lines `text` takes at `size` when wrapped at `width` (0 or nil: no wrapping),
-- and the width of its longest line.
function F.Measure(text, size, width, wrap)
    local plain = F.Plain(text)
    if plain == "" then return 0, 0 end
    local unit = size * F.charWidth
    local lines, widest = 0, 0
    for line in (plain .. "\n"):gmatch("(.-)\n") do
        local full = #line * unit
        if wrap and width and width > 0 and full > width then
            local used = 0
            lines = lines + 1
            for word, gap in line:gmatch("(%S*)(%s*)") do
                local w = #word * unit
                if used > 0 and used + w > width then
                    lines = lines + 1
                    used = 0
                end
                -- a word longer than the line is broken over several
                while w > width do
                    lines = lines + 1
                    w = w - width
                end
                used = used + w + #gap * unit
                widest = math.max(widest, math.min(width, used))
            end
        else
            lines = lines + 1
            widest = math.max(widest, full)
        end
    end
    return lines, widest
end

---------------------------------------------------------------------------
-- FontString
---------------------------------------------------------------------------
local FontString = class("FontString", Layered)
for name, method in pairs(FontMethods) do FontString[name] = method end

local function fontSize(self)
    local font = fontProp(self, "font")
    return font and font[2] or nil
end

function FontString:SetText(text)
    if text ~= nil and type(text) ~= "string" and type(text) ~= "number" then
        error("SetText: text expected, got " .. type(text) .. " (" .. tostring(text) .. ")", 2)
    end
    if not fontSize(self) then error("FontString:SetText(): Font not set", 2) end
    S[self].text = text ~= nil and tostring(text) or nil
    touch()
end
function FontString:SetFormattedText(fmt, ...) self:SetText(fmt:format(...)) end
function FontString:ClearText() S[self].text = nil; touch() end
function FontString:GetText() return S[self].text end
function FontString:SetWordWrap(on) S[self].noWrap = not on; touch() end
function FontString:CanWordWrap() return not S[self].noWrap end
function FontString:SetNonSpaceWrap() end
function FontString:CanNonSpaceWrap() return false end
function FontString:SetMaxLines(count) S[self].maxLines = count; touch() end
function FontString:GetMaxLines() return S[self].maxLines or 0 end
function FontString:SetTextHeight() end
function FontString:SetTextScale() end
function FontString:SetRotation() end
function FontString:IsTruncated() return false end
function FontString:GetLineHeight() return fontSize(self) or 0 end

-- The width the text is wrapped at: what was set or what the anchors give.
local function wrapWidth(self)
    local s = S[self]
    local left, right
    for _, p in ipairs(s.points) do
        if PX[p.point] == 0 then left = true elseif PX[p.point] == 1 then right = true end
    end
    if left and right then
        local _, _, w = rect(self)
        return w
    end
    return (s.w and s.w > 0) and s.w or 0
end

local function measure(self, width)
    local s = S[self]
    local size = fontSize(self) or 12
    local lines, widest = F.Measure(s.text, size, width, not s.noWrap)
    if s.noWrap and lines > 1 then lines = 1 end
    if s.maxLines and s.maxLines > 0 then lines = math.min(lines, s.maxLines) end
    return lines, widest, size
end

function FontString:GetStringWidth()
    local _, widest = measure(self, wrapWidth(self))
    return widest
end
function FontString:GetUnboundedStringWidth()
    local _, widest = measure(self, 0)
    return widest
end
function FontString:GetWrappedWidth() return self:GetStringWidth() end
function FontString:GetNumLines()
    return (measure(self, wrapWidth(self)))
end
function FontString:GetStringHeight()
    local lines, _, size = measure(self, wrapWidth(self))
    if lines == 0 then return 0 end
    return lines * size + (lines - 1) * self:GetSpacing()
end
function FontString:__naturalWidth()
    local _, widest = measure(self, 0)
    return widest
end
function FontString:__naturalHeight(width)
    local lines, _, size = measure(self, width)
    if lines == 0 then return 0 end
    return lines * size + (lines - 1) * self:GetSpacing()
end

---------------------------------------------------------------------------
-- Making regions
---------------------------------------------------------------------------
function F.NewRegion(c, parent, name, layer)
    local obj = setmetatable({}, c.__mt)
    local s = newState(c.__type, name, parent)
    s.layer, s.sublevel = layer and layer:upper() or "ARTWORK", 0
    S[obj] = s
    if parent then
        local list = S[parent].regions
        list[#list + 1] = obj
    end
    if name then rawset(_G, name, obj) end
    return obj
end

F.PARENT, F.SCREEN = PARENT, SCREEN
F.visible, F.resized, F.need = visible, resized, need
