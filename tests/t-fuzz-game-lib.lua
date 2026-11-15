-- The random-play tester's hold on the game around the addon: chat that is checked,
-- dice that can be kept back, and the options tables (settings, wizard, level
-- dialog) read and set the way the dialog library does it.
local Z = FUZZ

-- Text a player should never see.
function Z.OddText(text)
    if type(text) ~= "string" then return "a " .. type(text) end
    local plain = F.Plain(text)
    if plain:find("<stub") or plain:find("table: 0x") or plain:find("function: 0x") or plain:find("userdata: 0x")
        or plain:find("%f[%a]nil%f[%A]") or plain:find("%%[sd]") or plain:find("%f[%a]nan%f[%A]") or plain:find("%-?%f[%a]inf%f[%A]") then
        return plain:sub(1, 200)
    end
end

-- Runs after the base file loaded the addon, before the addon starts.
function Z.InstallGame()
    Z.hold, Z.held, Z.waiting = false, {}, false
    Z.printMark = 0
    -- what the test helpers find is collected, not printed
    function Problem(text) Z.Report("error", (tostring(text):gsub("%S*RPSheet/", ""):gsub("%S*wt%-[%w-]+/", ""))) end
    SENT = {}
    C_ChatInfo = { SendChatMessage = function(message, channel)
        SENT[#SENT + 1] = message
        if type(message) ~= "string" then Z.Report("chat", "a chat line is a " .. type(message))
        elseif #message > 255 then Z.Report("chat", "a chat line of " .. #message .. " bytes: " .. message:sub(1, 80))
        elseif message:find("|") or message:find("[\r\n]") then Z.Report("chat", "a chat line with a pipe or line break: " .. message:sub(1, 200))
        elseif Z.OddText(message) then Z.Report("text", "chat: " .. Z.OddText(message)) end
    end }
    function RandomRoll(low, high)
        if Z.hold then
            Z.held[#Z.held + 1] = { low, high }
            Z.waiting = true
            return
        end
        Z.Land(low, high)
    end
end

-- The game's line for a roll reaches the addon.
function Z.Land(low, high, value)
    local line = ("Tester rolls %d (%d-%d)"):format(value or math.random(low, high), low, high)
    Try("roll result", function() RPSheet:CHAT_MSG_SYSTEM(nil, line) end)
end

-- Lines printed to the player since the last call.
function Z.NewPrints()
    local lines = {}
    for index = Z.printMark + 1, #PRINTED do lines[#lines + 1] = PRINTED[index] end
    Z.printMark = #PRINTED
    return lines
end

---------------------------------------------------------------------------
-- Options tables
---------------------------------------------------------------------------
function Z.Options(app) return REGISTRY:GetOptionsTable(app)("dialog", "AceConfigDialog-3.0") end

local function Member(option, key, path, ...)
    local value = option[key]
    if type(value) == "function" then
        return Try(path .. "." .. key, value, { path:match("[^.]+$"), option = option, type = option.type }, ...)
    end
    return value
end
Z.Member = Member

-- Every option below `group` that is shown, as the dialog would work it out:
-- { path, key, option, kind, name, disabled, values, current }. Hidden groups hide
-- what is in them; a disabled group disables it.
function Z.Rows(group, path, out, off)
    out = out or {}
    path = path or "options"
    local keys = {}
    for key in pairs(group.args) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local option = group.args[key]
        local p = path .. "." .. key
        if not Member(option, "hidden", p) then
            local kind = option.type
            local row = { path = p, key = key, option = option, kind = kind, parent = path }
            row.name = Member(option, "name", p)
            if type(row.name) ~= "string" then Z.Report("text", p .. ": the name is a " .. type(row.name))
            elseif Z.OddText(row.name) then Z.Report("text", p .. ": " .. Z.OddText(row.name)) end
            local desc = Member(option, "desc", p)
            if desc ~= nil and Z.OddText(desc) then Z.Report("text", p .. " (description): " .. Z.OddText(desc)) end
            row.disabled = off or Member(option, "disabled", p) or false
            out[#out + 1] = row
            if kind == "group" then
                Z.Rows(option, p, out, row.disabled)
            elseif kind == "select" or kind == "multiselect" then
                row.values = Member(option, "values", p)
                if type(row.values) ~= "table" then
                    Z.Report("error", p .. ": the values are a " .. type(row.values))
                    row.values = {}
                end
                if kind == "select" then row.current = Member(option, "get", p) end
            elseif kind == "range" or kind == "toggle" or kind == "input" then
                row.current = Member(option, "get", p)
                if kind == "range" and type(row.current) ~= "number" then Z.Report("error", p .. ": a slider's value is a " .. type(row.current)) end
            end
        end
    end
    return out
end
function Z.ByKey(rows)
    local byKey = {}
    for _, row in ipairs(rows) do byKey[row.key] = row end
    return byKey
end

local GREY = "|cff888888"
-- What a dropdown offers a player: not the empty line, not a greyed one.
function Z.Candidates(row, avoid)
    local names = {}
    for key, text in pairs(row.values or {}) do
        if key ~= "" and not (type(text) == "string" and text:find(GREY, 1, true)) and not (avoid and avoid[key]) then names[#names + 1] = key end
    end
    table.sort(names, function(a, b) return tostring(a) < tostring(b) end)
    return names
end

-- Sets an option as a click would. Returns false when it is greyed out or the value
-- isn't one of its own.
function Z.Set(row, value, ...)
    if row.disabled then return false end
    local option = row.option
    if row.kind == "execute" then
        Try(row.path .. ".func", option.func, { row.key, option = option, type = "execute" })
    else
        if row.kind == "select" and row.values[value] == nil then return false end
        if row.kind == "range" then
            local low, high = option.min, option.max
            if type(low) == "number" and value < low or type(high) == "number" and value > high then return false end
        end
        Try(row.path .. ".set", option.set, { row.key, option = option, type = row.kind }, value, ...)
    end
    return true
end

---------------------------------------------------------------------------
-- Windows
---------------------------------------------------------------------------
-- The addon's own windows that are open: the sheet and its companions.
function Z.Windows()
    local list = {}
    for _, key in ipairs({ "window", "itemWindow", "bookWindow", "preparedWindow" }) do
        local window = RPSheet[key]
        if window and not IsStub(window) and window.frame and window.frame:IsShown() then list[#list + 1] = { key = key, window = window } end
    end
    return list
end

-- Answers whatever is in the way: the library's question box, a popup, a menu.
function Z.Dismiss()
    local popup = AceConfigDialog.popup
    if popup and popup:IsShown() then popup:Hide() end
    if F.popup then Try("popup cancel", F.PopupCancel) end
    F.menu = nil
end
