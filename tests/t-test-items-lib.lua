-- Shared by the t-test-items-*.lua scripts: the addon started, dice that can be set,
-- chat that is checked, a quick character, and counting checks.
NUM_CHAT_WINDOWS = 10
RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"
SENT = {}
C_ChatInfo = { SendChatMessage = function(msg)
    SENT[#SENT + 1] = msg
    if type(msg) ~= "string" then Problem("chat message is " .. type(msg))
    elseif #msg > 255 then Problem("chat message over 255: " .. msg:sub(1, 80))
    elseif msg:find("|") or msg:find("\n") then Problem("chat message with a pipe or line break: " .. msg:sub(1, 200)) end
end }
-- A script that has loaded the addon already (through wiz2.lua, say) sets SKIP_SIM.
if not rawget(_G, "SKIP_SIM") then dofile(ARG3 .. "/sim.lua") end

-- Stubs this round needed (candidates for env.lua).
SHOWN_POPUPS = {}
function StaticPopup_Show(which, text, _, data)
    SHOWN_POPUPS[#SHOWN_POPUPS + 1] = { which = which, text = text, data = data }
    if type(text) ~= "string" then Problem("popup " .. tostring(which) .. " text is " .. type(text)) end
end
-- A popup as the game hands it to the dialog's functions: an edit box holding `typed`.
function FakePopup(typed, data)
    local box = { text = typed }
    function box:GetText() return self.text end
    function box:SetText(text) self.text = text end
    function box:SetFocus() end
    local dialog = { data = data, hidden = false }
    function dialog:GetEditBox() return box end
    function dialog:Hide() self.hidden = true end
    function box:GetParent() return dialog end
    return dialog, box
end
MENUS = {}
MenuUtil = { CreateContextMenu = function(owner, build)
    local menu = { titles = {}, buttons = {} }
    local root = {}
    function root:CreateTitle(text) menu.titles[#menu.titles + 1] = text end
    function root:CreateButton(text, fn) menu.buttons[#menu.buttons + 1] = { text = text, click = fn }; return root end
    function root:CreateDivider() end
    build(owner, root)
    MENUS[#MENUS + 1] = menu
    return menu
end }

-- Dice: the next results, first in first out; anything beyond them is random.
DICE, ROLLED = {}, {}
function RandomRoll(low, high)
    local value = table.remove(DICE, 1) or math.random(low, high)
    ROLLED[#ROLLED + 1] = { value = value, high = high }
    local ok, err = pcall(function() RPSheet:CHAT_MSG_SYSTEM(nil, ("Tester rolls %d (%d-%d)"):format(value, low, high)) end)
    if not ok then Problem("roll callback: " .. tostring(err)) end
end
if not rawget(_G, "SKIP_SIM") then Start() end

CHECKS = 0
function Check(cond, text)
    CHECKS = CHECKS + 1
    if not cond then Problem(text) end
    return cond
end
function Eq(got, want, text)
    CHECKS = CHECKS + 1
    if got ~= want then Problem(("%s: got %s, expected %s"):format(text, tostring(got), tostring(want))) end
    return got == want
end
-- Runs fn; an error is a problem. Returns what fn returns.
function Run(label, fn, ...)
    CHECKS = CHECKS + 1
    return Try(label, fn, ...)
end

-- A character on the active sheet. scores: { STR = 15, ... } (default 15 14 13 12 10 8).
function NewChar(class, level, opts)
    opts = opts or {}
    local sheet = ns.NewSheet()
    for _, list in ipairs(R.PICK_LIST_ORDER) do sheet.picks[list] = {} end
    local data = R.CLASSES[class]
    sheet.class, sheet.level = class, level or 1
    sheet.subclass = opts.subclass or (((level or 1) >= 3 or data.hero) and data.subclasses[1] or "")
    sheet.spec = opts.spec or data.specs[1]
    sheet.species, sheet.background = opts.species or "HUMAN", opts.background or "SOLDIER"
    sheet.allegiance = opts.allegiance or R.ALLEGIANCE_ORDER[1]
    sheet.size = opts.size or "M"
    sheet.base = opts.scores or { STR = 15, DEX = 14, CON = 13, INT = 12, WIS = 10, CHA = 8 }
    for index = 1, data.skillCount do sheet.skills[data.skills[index]] = 1 end
    ns.ApplyGrants(sheet)
    RPSheet:ReplaceSheet(sheet)
    FlushTimers()
    RPSheet.busy = false
    return RPSheet:Sheet()
end

-- What was printed to the player since `mark` (a number from #PRINTED), as one text.
function PrintedSince(mark)
    local lines = {}
    for index = mark + 1, #PRINTED do lines[#lines + 1] = PRINTED[index] end
    return table.concat(lines, "\n")
end
function SentSince(mark)
    local lines = {}
    for index = mark + 1, #SENT do lines[#lines + 1] = SENT[index] end
    return table.concat(lines, "\n")
end

function Done(name)
    local count = 0
    for _ in pairs(PROBLEMS) do count = count + 1 end
    print(("%s: %d checks, %d problems"):format(name, CHECKS, count))
    io.stdout:flush()
end
