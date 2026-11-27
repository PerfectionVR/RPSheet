-- Helpers for the window tests (loaded by t-test-windows-base.lua): hovering and
-- clicking every row of a window, and checking how a flow layout came out.
COUNT = { rows = 0, clicks = 0, tips = 0, explains = 0 }

-- What a part reads as.
function PartText(part)
    -- (a row's button keeps its whole text; its two halves are drawn apart)
    if part.type == "RPSheetButton" then return part:GetText() or "" end
    for _, key in ipairs({ "label", "text", "titletext" }) do
        local region = part[key]
        if type(region) == "table" and region.GetText then
            local text = region:GetText()
            if text and text ~= "" then return text end
        end
    end
    if part.frame and part.frame.GetText then return part.frame:GetText() or "" end
    return ""
end

-- Text the player should never see: a value that wasn't there, a table, a stub, a
-- format code that was never filled in.
function CheckText(where, text)
    if type(text) ~= "string" then return end
    local plain = F.Plain(text)
    if plain:find("<stub") or plain:find("table: 0x") or plain:find("function: 0x") or plain:find("%f[%a]nil%f[%A]")
        or plain:find("%%[sd]") or plain:find("%f[%a]nan%f[%A]") or plain:find("%-?%f[%a]inf%f[%A]") then
        Problem(("%s: odd text: %s"):format(where, plain:sub(1, 200)))
    end
end

-- Closes what a click may have opened, so the next click starts clean.
function Dismiss()
    if F.popup then F.PopupCancel() end
    F.menu = nil
    RPSheet.busy = false
    if AceConfigDialog.popup and AceConfigDialog.popup:IsShown() then AceConfigDialog.popup:Hide() end
end

-- Mouse over a part and away again: the tooltip must build, have a title, and close.
function HoverPart(where, part)
    local frame = part.frame
    if not Try(where .. " OnEnter", F.Enter, frame) then
        if not frame:IsVisible() then Problem(where .. ": the row is not visible") end
    end
    local lines = F.TooltipLines()
    if lines then
        COUNT.tips = COUNT.tips + 1
        if F.Plain(lines[1].text):match("^%s*$") then Problem(where .. ": tooltip with an empty title") end
        for _, line in ipairs(lines) do CheckText(where .. " tooltip", line.text) end
    end
    Try(where .. " OnLeave", F.Leave, frame)
    if GameTooltip:IsShown() then
        Problem(where .. ": the tooltip stays open after the mouse left")
        GameTooltip:Hide()
    end
    return lines
end

-- One click on a part. `mark` clicks the "?" part in front of a row's button.
function ClickPart(where, part, button, shift, ctrl, alt, mark)
    F.SetKeys(shift, ctrl, alt)
    local frame = part.frame
    if mark then
        if not (part.mark and part.mark:IsShown()) then Problem(where .. ": the row explains a number and has no ? part") end
        frame = part.mark or frame
    end
    F.MoveMouse(frame, 0.5, 0.5, 0)
    COUNT.clicks = COUNT.clicks + 1
    Try(where, F.Click, frame, button)
    F.SetKeys(false, false, false)
    F.MoveMouse(nil)
    Try(where .. " (after)", F.Settle)
    CheckHidden(where)
end

local VARIANTS = {
    { "LeftButton" }, { "RightButton" }, { "LeftButton", true }, { "LeftButton", false, true }, { "LeftButton", false, false, true },
    { "RightButton", true }, { "RightButton", false, true }, { "RightButton", false, false, true },
}
local NAMES = { "left", "right", "shift-left", "ctrl-left", "alt-left", "shift-right", "ctrl-right", "alt-right" }

local function Clickable(part)
    if part.type == "RPSheetBar" then return part.events and part.events.OnClick ~= nil end
    if part.type == "RPSheetButton" then return not part.disabled and part.events and part.events.OnClick ~= nil end
    if part.type == "Button" then return part.frame:IsEnabled() end
    return false
end

-- The rule of every window: what reacts to a click is a button, a tab or a bar.
-- Text that does is a problem.
function CheckNoClickableText(where, part)
    if (part.type == "InteractiveLabel" or part.type == "Label") and part.events and part.events.OnClick then
        Problem(where .. ": plain text that reacts to a click")
    end
end

CLICKED = {}
-- Hovers every row `rows()` gives and clicks the ones that can be clicked, with both
-- mouse buttons and with Shift, Ctrl and Alt. The rows are read again after every
-- click, since a click may rebuild them. options:
--   key      rows already clicked under the same key and text are only hovered
--   skip     part types that are hovered but not clicked
--   after()  runs after every click
--   printed  explanations must print something (a list that grows, like PRINTED)
--   variants how many of the click variants to use (all eight when left out)
function WalkRows(rows, where, options)
    options = options or {}
    local index = 0
    while true do
        index = index + 1
        local part = rows()[index]
        if not part then break end
        local kind, text = part.type, PartText(part)
        local name = ("%s [%s] '%s'"):format(where, tostring(kind), F.Plain(text):gsub("\n", " "):sub(1, 50))
        COUNT.rows = COUNT.rows + 1
        CheckText(name, text)
        CheckNoClickableText(name, part)
        if part.frame:IsMouseEnabled() or (part.events and (part.events.OnEnter or part.events.OnClick)) then
            HoverPart(name, part)
        end
        local key = options.key and (options.key .. "|" .. tostring(kind) .. "|" .. F.Plain(text):gsub("%d+", "#"))
        if Clickable(part) and not (options.skip and options.skip[kind]) and not (key and CLICKED[key]) then
            if key then CLICKED[key] = true end
            local explains = part.GetUserData and part:GetUserData("explain") ~= nil
            for v, variant in ipairs(VARIANTS) do
                if options.variants and v > options.variants then break end
                local now = rows()[index]
                if not now or now.type ~= kind or not Clickable(now) then break end
                ClickPart(name .. " " .. NAMES[v] .. "-click", now, variant[1], variant[2], variant[3], variant[4])
                Dismiss()
                if options.after then options.after() end
            end
            local now = rows()[index]
            if explains and now and now.type == kind and now:GetUserData("explain") then
                local before = options.printed and #options.printed
                ClickPart(name .. " click on [?]", now, "LeftButton", false, false, false, true)
                COUNT.explains = COUNT.explains + 1
                if before and #options.printed == before then Problem(name .. ": clicking the [?] printed nothing") end
                Dismiss()
                if options.after then options.after() end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Layout checks
---------------------------------------------------------------------------
-- True when two parts stand on the same row.
function SameRow(a, b)
    local topA, bottomA, topB, bottomB = a.frame:GetTop(), a.frame:GetBottom(), b.frame:GetTop(), b.frame:GetBottom()
    if not (topA and topB) then return false end
    return topA > bottomB + 0.01 and topB > bottomA + 0.01
end

-- The children of a flow container whose relative widths add up to a full row must
-- stand on one row: none may be pushed to the next by rounding. Returns how many
-- rows were looked at.
function CheckFlowRows(container, where)
    local checked = 0
    local row, used = {}, 0
    local function Close()
        if #row > 1 then
            checked = checked + 1
            for i = 2, #row do
                if not SameRow(row[1], row[i]) then
                    Problem(("%s: '%s' wrapped off the row of '%s' at width %d"):format(where,
                        F.Plain(PartText(row[i])):sub(1, 30), F.Plain(PartText(row[1])):sub(1, 30), math.floor(container.content:GetWidth() + 0.5)))
                    break
                end
            end
        end
        row, used = {}, 0
    end
    for _, child in ipairs(container.children) do
        local share = child.relWidth
        if child.width == "fill" or not share then
            Close()
        else
            if used + share > 1.0005 then Close() end
            row[#row + 1] = child
            used = used + share
        end
    end
    Close()
    return checked
end

-- Rows must not lie on top of each other, and a row with text must have a height.
function CheckOverlap(container, where)
    local previous
    for _, child in ipairs(container.children) do
        local frame = child.frame
        local top, bottom = frame:GetTop(), frame:GetBottom()
        if not top then
            Problem(where .. ": a row was never placed: " .. F.Plain(PartText(child)):sub(1, 40))
        else
            if F.Plain(PartText(child)):match("%S") and top - bottom < 1 then
                Problem(where .. ": a row with text has no height: " .. F.Plain(PartText(child)):sub(1, 40))
            end
            if previous and SameRow(previous, child) and frame:GetLeft() < previous.frame:GetRight() - 0.5
                and previous.frame:GetLeft() < frame:GetRight() - 0.5 then
                Problem(("%s: '%s' lies over '%s'"):format(where, F.Plain(PartText(child)):sub(1, 30), F.Plain(PartText(previous)):sub(1, 30)))
            end
            previous = child
        end
    end
end
