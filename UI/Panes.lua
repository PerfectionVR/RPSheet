-- A window in three parts that each keep their place, for the combat windows: `head`
-- on top, as tall as its rows up to a share of the window; `log` at the bottom, which
-- stays at its last line; and `main` in the room between them. Each part scrolls by
-- itself when its rows don't fit.
--
--   local window, panes = UI.NewPanedWindow(status, onShow)
--   panes.head, panes.main, panes.log   the parts, each a flow of rows
--   panes:Clear()    releases every part's rows, before they are made again
--   panes:SetOut()   lays the rows and the parts out, after they were made
local ADDON, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local GAP = 9 -- between two parts, with a thin line in the middle of it
local HEAD_SHARE, LOG_SHARE, LOG_LEAST = 0.45, 0.3, 58

-- The height a part's rows need.
local function Needs(pane)
    if #pane.children == 0 then return 0 end
    return pane.content:GetHeight() or 0
end

local function Place(pane, content, top, width, height)
    local frame = pane.frame
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -top)
    pane:SetWidth(width)
    pane:SetHeight(math.max(1, height))
    frame:SetShown(height > 0)
end

-- The window's layout: its three children are the parts, in order.
AceGUI:RegisterLayout("RPSheetPanes", function(content, children)
    local head, main, log = children[1], children[2], children[3]
    if not log then return end
    local panes = head:GetUserData("panes")
    local width, height = content.width or content:GetWidth() or 0, content.height or content:GetHeight() or 0
    for _, pane in ipairs(children) do
        -- (a part's rows wrap by its width, so its height is asked for after this)
        if pane.frame:GetWidth() ~= width then
            pane:SetWidth(width)
            pane:DoLayout()
        end
    end
    local headNeeds, mainNeeds, logNeeds = Needs(head), Needs(main), Needs(log)
    local others = (mainNeeds > 0 and 1 or 0) + (logNeeds > 0 and 1 or 0)
    local headHeight = math.min(headNeeds, others > 0 and math.floor(height * HEAD_SHARE) or height)
    local rest = math.max(0, height - headHeight - (headHeight > 0 and others > 0 and GAP or 0))
    local logHeight = 0
    if logNeeds > 0 and mainNeeds == 0 then
        logHeight = rest
    elseif logNeeds > 0 then
        -- its share, and whatever the middle part leaves free
        local share = math.max(LOG_LEAST, math.floor(height * LOG_SHARE), rest - GAP - mainNeeds)
        logHeight = math.min(logNeeds, share, rest)
    end
    local mainHeight = mainNeeds > 0 and math.max(0, rest - logHeight - (logHeight > 0 and GAP or 0)) or 0
    local mainTop = headHeight + (headHeight > 0 and GAP or 0)
    local logTop = height - logHeight
    Place(head, content, 0, width, headHeight)
    Place(main, content, mainTop, width, mainHeight)
    Place(log, content, logTop, width, logHeight)
    -- the thin lines between the parts
    local line = ns.Tokens(RPSheet.db.profile.theme).line
    local function Line(texture, top, shown)
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(top - math.floor(GAP / 2) - 1))
        texture:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(top - math.floor(GAP / 2) - 1))
        texture:SetHeight(1)
        texture:SetColorTexture(line[1], line[2], line[3], line[4])
        texture:SetShown(shown)
    end
    if panes then
        Line(panes.lines[1], mainTop, headHeight > 0 and mainHeight > 0)
        Line(panes.lines[2], logTop, logHeight > 0 and (headHeight > 0 or mainHeight > 0))
    end
    for _, pane in ipairs(children) do pane:FixScroll() end
end)

local methods = {}

function methods:Clear()
    -- The log follows its last line unless the player scrolled back up in it.
    local log = self.log
    local status = log.status or log.localstatus
    local at = status.scrollvalue
    self.follow = not log.scrollBarShown or type(at) ~= "number" or at >= 990
    for _, pane in ipairs(self) do
        pane:PauseLayout()
        pane:ReleaseChildren()
    end
end

function methods:SetOut()
    for _, pane in ipairs(self) do
        pane:ResumeLayout()
        pane:DoLayout()
        pane:DoLayout()
    end
    self.window:DoLayout()
    -- (a part's height changed: its rows are set out for the height it has now)
    for _, pane in ipairs(self) do
        pane:DoLayout()
        UI.SkinScroll(pane)
    end
    local log = self.log
    if self.follow ~= false and #log.children > 0 then
        local status = log.status or log.localstatus
        status.offset = math.max(0, (log.content:GetHeight() or 0) - (log.scrollframe:GetHeight() or 0))
        log:FixScroll()
    end
end

-- A themed window with the three parts. `status` keeps its place and size; `onShow`
-- is called when it is shown again.
function UI.NewPanedWindow(status, onShow)
    local window = AceGUI:Create("RPSheetWindow")
    window:SetStatusTable(status)
    window:SetLayout("RPSheetPanes")
    window:SetCallback("OnLockClick", function() window:SetLocked(not window.locked) end)
    window:SetCallback("OnMinimizeClick", function() window:SetMinimized(not window.minimized) end)
    window:SetCallback("OnEditClick", function() AceConfigDialog:Open(ADDON) end)
    window:SetCallback("OnShow", onShow)

    local panes = { window = window, lines = {} }
    for name, method in pairs(methods) do panes[name] = method end
    window:PauseLayout()
    for index, name in ipairs({ "head", "main", "log" }) do
        local pane = AceGUI:Create("ScrollFrame")
        pane:SetLayout("Flow")
        pane:SetUserData("panes", panes)
        window:AddChild(pane)
        panes[index], panes[name] = pane, pane
    end
    for index = 1, 2 do
        panes.lines[index] = window.content:CreateTexture(nil, "ARTWORK")
        panes.lines[index]:Hide()
    end
    window:ResumeLayout()
    return window, panes
end
