-- Helpers for the tests that work a window of the options library (settings, wizard,
-- level dialog) the way a player does: finding the control of an option, ticking,
-- choosing from a dropdown's list, dragging a slider, typing, pressing buttons and
-- answering the "are you sure" box. Loaded after t-test-windows-base.lua.
Dialog = { count = { toggles = 0, selects = 0, ranges = 0, inputs = 0, executes = 0, colors = 0, confirms = 0, refused = 0, disabled = 0 } }
local D = Dialog
local count = D.count

function D.Options(app) return REGISTRY:GetOptionsTable(app)("dialog", "AceConfigDialog-3.0") end
function D.Root(app) return AceConfigDialog.OpenFrames[app] end
function D.Shown(app)
    local root = D.Root(app)
    return root ~= nil and root.frame:IsShown()
end

-- Every control of the open window that stands for an option, in the order shown.
function D.Controls(app)
    local list = {}
    local root = D.Root(app)
    if not root then return list end
    for _, part in ipairs(Parts(root)) do
        if part ~= root and part:GetUserData("option") then list[#list + 1] = part end
    end
    return list
end
-- The control of one option (of one of its values, for a list of tick boxes).
function D.Control(app, option, value)
    for _, part in ipairs(D.Controls(app)) do
        if part:GetUserData("option") == option and (value == nil or part:GetUserData("value") == value) then return part end
    end
end

-- The library's own "are you sure" and "that isn't valid" box.
function D.PopupShown() return AceConfigDialog.popup and AceConfigDialog.popup:IsShown() end
-- Answers it: accept (or cancel) a question, close a refusal. Returns what it said.
function D.AnswerPopup(accept)
    local popup = AceConfigDialog.popup
    if not D.PopupShown() then return nil end
    local text = popup.text:GetText()
    CheckText("confirm box", text)
    if F.Plain(text or ""):match("^%s*$") then Problem("the confirm box asks nothing") end
    if popup.cancel:IsShown() and popup.cancel:GetScript("OnClick") then
        count.confirms = count.confirms + 1
        F.Click(accept == false and popup.cancel or popup.accept)
    else
        count.refused = count.refused + 1
        if popup.accept:GetScript("OnClick") then F.Click(popup.accept) end
    end
    if popup:IsShown() then popup:Hide() end
    return text
end

local function After(where)
    Try(where .. " (settle)", F.Settle)
    if D.PopupShown() then D.AnswerPopup(true) Try(where .. " (settle)", F.Settle) end
    if F.popup then F.PopupCancel() end
    F.menu = nil
    RPSheet.busy = false
    CheckHidden(where)
end
D.After = After

-- Mouse over a control: the library's tooltip must name it.
function D.Hover(where, control)
    local frame = control.frame
    if not frame:IsVisible() then return end
    Try(where .. " OnEnter", F.Enter, frame)
    local tip = AceConfigDialog.tooltip
    if tip:IsShown() then
        local lines = F.TooltipLines(tip)
        if not lines or F.Plain(lines[1].text):match("^%s*$") then Problem(where .. ": tooltip without a title") end
        for _, line in ipairs(lines or {}) do CheckText(where .. " tooltip", line.text) end
    end
    Try(where .. " OnLeave", F.Leave, frame)
    if tip:IsShown() then Problem(where .. ": the tooltip stays open") tip:Hide() end
    if GameTooltip:IsShown() then GameTooltip:Hide() end
end

-- The words in a text that can be hovered (glossary terms): each must explain itself.
function D.HoverTerms(where, control)
    local frame = control.frame
    local text = PartText(control)
    if not frame:GetScript("OnHyperlinkEnter") then return 0 end
    local seen = 0
    for link, word in text:gmatch("|H(.-)|h(.-)|h") do
        seen = seen + 1
        Try(where .. " term " .. word, F.Fire, frame, "OnHyperlinkEnter", link, word)
        local lines = F.TooltipLines()
        if not lines then
            Problem(where .. ": the word '" .. F.Plain(word) .. "' can be hovered but explains nothing")
        elseif not lines[2] or F.Plain(lines[2].text):match("^%s*$") then
            Problem(where .. ": the explanation of '" .. F.Plain(word) .. "' is empty")
        end
        Try(where .. " term leave", F.Fire, frame, "OnHyperlinkLeave")
        if GameTooltip:IsShown() then Problem(where .. ": the explanation of '" .. F.Plain(word) .. "' stays open") GameTooltip:Hide() end
    end
    return seen
end

---------------------------------------------------------------------------
-- Working one control
---------------------------------------------------------------------------
local function Disabled(control)
    if control.disabled then return true end
    if control.frame.IsEnabled and not control.frame:IsEnabled() then return true end
    return false
end

-- A tick box: clicked on and off again.
function D.Toggle(app, option, where, value)
    for _ = 1, 2 do
        local control = D.Control(app, option, value)
        if not control or control.type ~= "CheckBox" then return end
        if Disabled(control) then count.disabled = count.disabled + 1 return end
        count.toggles = count.toggles + 1
        Try(where .. " click", F.Click, control.frame)
        After(where)
    end
end

-- A dropdown: its list is opened and a line clicked, for every value (at most `most`,
-- spread over the list), then the value it had is chosen again.
function D.Select(app, option, where, most)
    local control = D.Control(app, option)
    if not control then return end
    if control.type ~= "Dropdown" then
        -- radio buttons: one tick box per value
        local values = {}
        for _, part in ipairs(D.Controls(app)) do
            if part:GetUserData("option") == option then values[#values + 1] = part:GetUserData("value") end
        end
        for _, value in ipairs(values) do
            local radio = D.Control(app, option, value)
            if radio and not Disabled(radio) then
                count.selects = count.selects + 1
                Try(where .. " radio " .. tostring(value), F.Click, radio.frame)
                After(where .. " radio " .. tostring(value))
            end
        end
        return
    end
    if Disabled(control) then count.disabled = count.disabled + 1 return end
    local original = control:GetValue()
    local keys = {}
    for key in pairs(control.list or {}) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local chosen = keys
    most = most or 40
    if #keys > most then
        chosen = {}
        for index = 1, most do chosen[index] = keys[math.floor((index - 1) * (#keys - 1) / (most - 1)) + 1] end
    end
    local function Choose(key)
        local now = D.Control(app, option)
        if not now or now.type ~= "Dropdown" or Disabled(now) then return false end
        if control.multiselect then
            now:Fire("OnValueChanged", key, true)
            now:Fire("OnValueChanged", key, false)
            return true
        end
        Try(where .. " open list", F.Click, now.button_cover)
        if not now.open then Problem(where .. ": the dropdown's list doesn't open") return false end
        local line
        for _, item in now.pullout:IterateItems() do
            if item.userdata.value == key then line = item end
        end
        if not line then
            now.pullout:Close()
            return false
        end
        CheckText(where .. " list", line:GetText())
        Try(where .. " choose " .. tostring(key), F.Click, line.frame)
        if now.open then now.pullout:Close() end
        return true
    end
    for _, key in ipairs(chosen) do
        if Choose(key) then
            count.selects = count.selects + 1
            After(where .. " = " .. tostring(key))
        end
    end
    if original ~= nil then
        Choose(original)
        After(where .. " back to " .. tostring(original))
    end
end

-- A slider: dragged to its lowest and highest, a number typed, and back.
function D.Range(app, option, where)
    local control = D.Control(app, option)
    if not control or not control.slider then return end
    if Disabled(control) then count.disabled = count.disabled + 1 return end
    local original = control:GetValue()
    local low, high = control.min, control.max
    for _, value in ipairs({ low, high, (low + high) / 2 }) do
        local now = D.Control(app, option)
        if not now or not now.slider or Disabled(now) then return end
        count.ranges = count.ranges + 1
        Try(where .. " drag to " .. tostring(value), F.Drag, now.slider, value)
        After(where .. " drag to " .. tostring(value))
    end
    local now = D.Control(app, option)
    if now and now.editbox and original and not Disabled(now) then
        Try(where .. " type " .. tostring(original), F.Type, now.editbox, tostring(original), true)
        After(where .. " type")
    end
end

-- A text box: a text typed and Enter (or its Accept button), then the old text back.
function D.Input(app, option, where, text)
    local control = D.Control(app, option)
    if not control then return end
    local function Enter(value)
        local now = D.Control(app, option)
        if not now then return false end
        if now.type == "MultiLineEditBox" then
            if not now.editBox:IsEnabled() then count.disabled = count.disabled + 1 return false end
            Try(where .. " type", F.Type, now.editBox, value)
            if now.button:IsEnabled() then Try(where .. " accept", F.Click, now.button) end
        elseif now.editbox then
            if Disabled(now) then count.disabled = count.disabled + 1 return false end
            Try(where .. " type", F.Type, now.editbox, value, true)
        else
            return false
        end
        After(where .. " = " .. tostring(value):sub(1, 20))
        return true
    end
    local original = control.GetText and control:GetText() or ""
    if text == nil then
        text = tonumber(original) and "7" or "Test text"
    end
    if Enter(text) then
        count.inputs = count.inputs + 1
        Enter(original or "")
    end
end

-- A button: clicked; a question is answered with yes (or first with no, then yes).
function D.Execute(app, option, where, refuseFirst)
    local control = D.Control(app, option)
    if not control or control.type ~= "Button" then return false end
    if Disabled(control) then count.disabled = count.disabled + 1 return false end
    count.executes = count.executes + 1
    Try(where .. " click", F.Click, control.frame)
    if D.PopupShown() and refuseFirst then
        D.AnswerPopup(false)
        Try(where .. " (settle)", F.Settle)
        local again = D.Control(app, option)
        if again and not Disabled(again) then Try(where .. " click again", F.Click, again.frame) end
    end
    if D.PopupShown() then D.AnswerPopup(true) end
    After(where)
    return true
end

-- A colour: the picker is opened, another colour picked, and the old one again.
function D.Color(app, option, where)
    local control = D.Control(app, option)
    if not control or control.type ~= "ColorPicker" then return end
    if Disabled(control) then count.disabled = count.disabled + 1 return end
    local r, g, b, a = control.r, control.g, control.b, control.a
    count.colors = count.colors + 1
    Try(where .. " open picker", F.Click, control.frame)
    if not F.colorPicker then Problem(where .. ": the colour picker doesn't open") return end
    Try(where .. " pick", F.PickColor, 0.25, 0.5, 0.75, 0.5)
    After(where .. " picked")
    local now = D.Control(app, option)
    if now and r then
        Try(where .. " open picker", F.Click, now.frame)
        Try(where .. " pick back", F.PickColor, r, g, b, a or 1)
        After(where .. " back")
    end
end

-- Works a control whatever it is. `most` caps the values tried of a long dropdown.
function D.Work(app, option, where, most)
    local kind = option.type
    if kind == "toggle" then
        D.Toggle(app, option, where)
    elseif kind == "select" then
        D.Select(app, option, where, most)
    elseif kind == "multiselect" then
        local control = D.Control(app, option)
        if control and control.type == "Dropdown" then
            D.Select(app, option, where, most)
        else
            local values = {}
            for _, part in ipairs(D.Controls(app)) do
                if part:GetUserData("option") == option and part.type == "CheckBox" then values[#values + 1] = part:GetUserData("value") end
            end
            for index, value in ipairs(values) do
                if not most or index <= most then D.Toggle(app, option, where .. " [" .. tostring(value) .. "]", value) end
            end
        end
    elseif kind == "range" then
        D.Range(app, option, where)
    elseif kind == "input" then
        D.Input(app, option, where)
    elseif kind == "execute" then
        D.Execute(app, option, where)
    elseif kind == "color" then
        D.Color(app, option, where)
    end
end

---------------------------------------------------------------------------
-- Pages
---------------------------------------------------------------------------
local function Member(option, key, info)
    local value = option[key]
    if type(value) == "function" then
        local ok, result = pcall(value, info)
        return ok and result or nil
    end
    return value
end
D.Member = Member

local function Sorted(group, info)
    local keys = {}
    for key in pairs(group.args or {}) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b)
        local oa, ob = Member(group.args[a], "order", info) or 100, Member(group.args[b], "order", info) or 100
        if oa ~= ob then return oa < ob end
        return tostring(a) < tostring(b)
    end)
    return keys
end
D.Sorted = Sorted

-- What the library hands an option's functions: the path to it and the option itself.
function D.Info(app, option, path)
    local info = { options = D.Options(app), option = option, arg = option.arg, handler = option.handler, type = option.type,
        uiType = "dialog", uiName = "AceConfigDialog-3.0", appName = app }
    for index, key in ipairs(path) do info[index] = key end
    return info
end
local function With(path, key)
    local longer = {}
    for index, part in ipairs(path) do longer[index] = part end
    longer[#longer + 1] = key
    return longer
end
D.With = With
function D.Hidden(app, option, path)
    if option.dialogHidden ~= nil then return option.dialogHidden end
    if option.guiHidden ~= nil then return option.guiHidden end
    return Member(option, "hidden", D.Info(app, option, path)) and true or false
end
local function Boxed(option)
    return option.inline or option.dialogInline or option.guiInline
end

-- The pages below a group: the paths of every sub-group that has a page of its own.
function D.Pages(app, group, path, out)
    out = out or {}
    path = path or {}
    for _, key in ipairs(Sorted(group)) do
        local option = group.args[key]
        local here = With(path, key)
        if option.type == "group" and not Boxed(option) and not D.Hidden(app, option, here) then
            out[#out + 1] = { path = here, group = option }
            D.Pages(app, option, here, out)
        end
    end
    return out
end

-- The options shown on a page, each { key, option, path, hidden }: its own, and those
-- of the boxed groups on it. An option in a hidden box counts as hidden.
function D.PageOptions(app, group, path, out, boxHidden, box)
    out = out or {}
    for _, key in ipairs(Sorted(group)) do
        local option = group.args[key]
        local here = With(path, key)
        local hidden = boxHidden or D.Hidden(app, option, here)
        if option.type ~= "group" then
            out[#out + 1] = { key = key, option = option, path = here, hidden = hidden, box = box }
        elseif Boxed(option) then
            local name = not hidden and Member(option, "name", D.Info(app, option, here)) or nil
            D.PageOptions(app, option, here, out, hidden, type(name) == "string" and name or box)
        end
    end
    return out
end

-- Opens a page of the window by its path.
function D.Open(app, path)
    if not D.Shown(app) then
        AceConfigDialog:Open(app)
        F.Settle()
    end
    AceConfigDialog:SelectGroup(app, unpack(path))
    F.Settle()
end

---------------------------------------------------------------------------
-- Setting one value, as a player fills in a form
---------------------------------------------------------------------------
-- The option with this key, anywhere in the window's tree.
function D.Find(app, key, group)
    group = group or D.Options(app)
    for name, option in pairs(group.args or {}) do
        if name == key then return option end
        if option.type == "group" then
            local found = D.Find(app, key, option)
            if found then return found end
        end
    end
end

-- Sets the option `key` to `value` through its control: a line of a dropdown's list
-- is clicked, a tick box clicked if it shows the other state, a slider dragged, a
-- text typed. Returns false when the control isn't there or is greyed out.
function D.Set(app, key, value, where)
    where = where or (app .. " " .. tostring(key))
    local option = type(key) == "table" and key or D.Find(app, key)
    if not option then Problem(where .. ": no such option") return false end
    local control = D.Control(app, option)
    if not control then Problem(where .. ": the option has no control on this page") return false end
    if control.disabled or (control.frame.IsEnabled and not control.frame:IsEnabled()) then return false end
    if control.type == "Dropdown" then
        Try(where .. " open list", F.Click, control.button_cover)
        if not control.open then Problem(where .. ": the dropdown's list doesn't open") return false end
        local line
        for _, item in control.pullout:IterateItems() do
            if item.userdata.value == value then line = item end
        end
        if not line then
            control.pullout:Close()
            Problem(where .. ": the list has no line for " .. tostring(value))
            return false
        end
        Try(where .. " choose " .. tostring(value), F.Click, line.frame)
        if control.open then control.pullout:Close() end
        count.selects = count.selects + 1
    elseif control.type == "CheckBox" then
        if (control:GetValue() and true or false) ~= (value and true or false) then
            Try(where .. " click", F.Click, control.frame)
            count.toggles = count.toggles + 1
        end
    elseif control.slider then
        Try(where .. " drag to " .. tostring(value), F.Drag, control.slider, value)
        count.ranges = count.ranges + 1
    elseif control.type == "MultiLineEditBox" then
        Try(where .. " type", F.Type, control.editBox, value)
        Try(where .. " accept", F.Click, control.button)
        count.inputs = count.inputs + 1
    elseif control.editbox then
        Try(where .. " type", F.Type, control.editbox, value, true)
        count.inputs = count.inputs + 1
    else
        Problem(where .. ": a " .. tostring(control.type) .. " can't be set")
        return false
    end
    After(where)
    return true
end

-- Presses the button of the option `key`. Returns false when it isn't there or greyed.
function D.Press(app, key, where)
    local option = type(key) == "table" and key or D.Find(app, key)
    if not option then Problem((where or tostring(key)) .. ": no such button") return false end
    return D.Execute(app, option, where or (app .. " " .. tostring(key)))
end

-- What a control shows now.
function D.Value(app, key)
    local option = type(key) == "table" and key or D.Find(app, key)
    local control = option and D.Control(app, option)
    if not control then return nil end
    if control.GetValue then return control:GetValue() end
    if control.GetText then return control:GetText() end
end

-- Looks over everything a window shows: every shown option has a control with sound
-- text, a tooltip that names it, and words that explain themselves when hovered.
-- Returns the options that are shown, by key.
function D.Look(app, where)
    if rawget(_G, "PROGRESS") then print(("%.1fs look %s"):format(os.clock(), where)) io.stdout:flush() end
    local root = D.Root(app)
    local shown = {}
    if not root then Problem(where .. ": the window isn't open") return shown end
    for _, part in ipairs(Parts(root)) do
        CheckText(where, PartText(part))
        if part.type == "Dropdown" then
            for _, text in pairs(part.list or {}) do CheckText(where .. " dropdown", text) end
        end
    end
    local options = D.PageOptions(app, D.Options(app), {})
    for _, entry in ipairs(options) do
        local control = D.Control(app, entry.option)
        if not entry.hidden and not control then
            Problem(("%s: the option %s (%s) has no control"):format(where, entry.key, tostring(entry.option.type)))
        elseif entry.hidden and control then
            Problem(("%s: the hidden option %s is shown"):format(where, entry.key))
        elseif control then
            shown[entry.key] = entry
            D.Hover(where .. " " .. entry.key, control)
            D.HoverTerms(where .. " " .. entry.key, control)
        end
    end
    CheckHidden(where)
    return shown
end
