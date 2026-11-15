-- Shared pieces of the t-test-play-*.lua scripts: a chat that records, dice that
-- give what the test asks for, a menu stub whose buttons can be clicked, and helpers
-- to put a character on a fresh sheet.
NUM_CHAT_WINDOWS = 10
RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"
SENT = {}
C_ChatInfo = { SendChatMessage = function(msg, channel)
    SENT[#SENT + 1] = msg
    if type(msg) ~= "string" then Problem("chat message is " .. type(msg))
    elseif #msg > 255 then Problem("chat message over 255: " .. msg:sub(1, 80))
    elseif msg:find("|") or msg:find("\n") then Problem("chat message with a pipe or line break: " .. msg:sub(1, 200)) end
end }

-- MenuUtil: a context menu is built at once and kept in MENUS; MENU is the last one.
--   MENU.title, MENU.items = { { text, click = function, checked = function } }
MENUS, MENU = {}, false -- (a global that was never set reads as a stub in env.lua, so everything starts as false)
local function Element() return { SetTooltip = function() end, SetEnabled = function() end, AddInitializer = function() end } end
MenuUtil = { CreateContextMenu = function(owner, build)
    local menu = { items = {} }
    local root = {}
    function root:CreateTitle(text) menu.title = text end
    function root:CreateButton(text, click) menu.items[#menu.items + 1] = { text = text, click = click } return Element() end
    function root:CreateCheckbox(text, checked, click) menu.items[#menu.items + 1] = { text = text, click = click, checked = checked } return Element() end
    function root:CreateDivider() end
    function root:CreateRadio(text, checked, click) menu.items[#menu.items + 1] = { text = text, click = click, checked = checked } return Element() end
    build(owner, root)
    MENUS[#MENUS + 1] = menu
    MENU = menu
end }
function GameTooltip_SetTitle() end
function GameTooltip_AddNormalLine() end

dofile(ARG3 .. "/sim.lua")

-- Dice: ROLLS is a queue of results for the next rolls; when it is empty a die gives
-- DEFAULT_ROLL (or half its sides, rounded up). HOLD_ROLLS keeps the answers back
-- until LandRolls() is called, as the game's chat does for a moment.
ROLLS, DEFAULT_ROLL, HOLD_ROLLS, HELD, ROLLED = {}, false, false, {}, {}
local function Land(low, high)
    local value = table.remove(ROLLS, 1) or DEFAULT_ROLL or math.ceil(high / 2)
    value = math.max(low, math.min(high, value))
    ROLLED[#ROLLED + 1] = { sides = high, value = value }
    RPSheet:CHAT_MSG_SYSTEM(nil, ("Tester rolls %d (%d-%d)"):format(value, low, high))
end
function RandomRoll(low, high)
    if low ~= 1 or high ~= math.floor(high) or high < 1 then Problem("odd roll " .. tostring(low) .. "-" .. tostring(high)) end
    if HOLD_ROLLS then HELD[#HELD + 1] = { low, high } return end
    Land(low, high)
end
function LandRolls()
    local n = 0
    while #HELD > 0 and n < 200 do
        local roll = table.remove(HELD, 1)
        Land(roll[1], roll[2])
        n = n + 1
    end
end
function Rolls(...) ROLLS = { ... } end

Start()

CHECKS, FAILED = 0, 0
function Check(ok, text)
    CHECKS = CHECKS + 1
    if not ok then FAILED = FAILED + 1; print("PROBLEM: " .. text) end
    return ok
end
function Eq(got, want, text)
    return Check(got == want, ("%s: got %s, expected %s"):format(text, tostring(got), tostring(want)))
end
-- The last chat line / printed line contains `piece` (plain text).
function Said(piece, text)
    local last = SENT[#SENT] or ""
    return Check(last:find(piece, 1, true) ~= nil, ("%s: last chat line is \"%s\", expected it to hold \"%s\""):format(text or "chat", last, piece))
end
function AnySaid(piece, from)
    for i = (from or 0) + 1, #SENT do if SENT[i]:find(piece, 1, true) then return true end end
    return false
end
function AnyPrinted(piece, from)
    for i = (from or 0) + 1, #PRINTED do if PRINTED[i]:find(piece, 1, true) then return true end end
    return false
end
function Printed(piece, text)
    local last = PRINTED[#PRINTED] or ""
    return Check(last:find(piece, 1, true) ~= nil, ("%s: last printed line is \"%s\", expected it to hold \"%s\""):format(text or "print", last, piece))
end
function Summary(name)
    for text in pairs(PROBLEMS) do FAILED = FAILED + 1 end
    print(("%s: %d checks, %d problems"):format(name, CHECKS, FAILED))
    io.stdout:flush()
end
-- Runs a block; an error is a problem and the script goes on.
function Section(label, fn)
    SECTION = label
    MENU = false
    RPSheet.busy = false
    ROLLS, HELD, HOLD_ROLLS, DEFAULT_ROLL = {}, {}, false, false
    local ok, err = xpcall(fn, function(m) return debug.traceback(m, 2) end)
    if not ok then FAILED = FAILED + 1; CHECKS = CHECKS + 1; print("PROBLEM: [" .. label .. "] error: " .. tostring(err):sub(1, 900)) end
    if RPSheet.busy then Check(false, "[" .. label .. "] the sheet is still busy afterwards") RPSheet.busy = false end
    if RPSheet:IsRolling() then Check(false, "[" .. label .. "] a roll is still waiting afterwards") HOLD_ROLLS = false; FlushTimers() end
    TIMERS = {}
end

-- A character on a fresh sheet. opts: species, lineage, background, base (scores),
-- extras = { { class, level, subclass } }, spec, skills = { names }, setup(sheet)
function Build(key, subclass, level, opts)
    opts = opts or {}
    local sheet = ns.NewSheet()
    for _, list in ipairs(R.PICK_LIST_ORDER) do sheet.picks[list] = {} end
    local class = R.CLASSES[key]
    sheet.class, sheet.subclass, sheet.level = key, subclass or "", level
    sheet.spec = opts.spec or class.specs[1] or ""
    sheet.species = opts.species or "HUMAN"
    if not R.SPECIES[sheet.species] then sheet.species = R.SPECIES_ORDER[1] end
    sheet.background = opts.background or R.BACKGROUND_ORDER[1]
    sheet.allegiance = R.ALLEGIANCE_ORDER[1]
    sheet.lineage = opts.lineage or ""
    sheet.base = opts.base or { STR = 14, DEX = 14, CON = 14, INT = 14, WIS = 14, CHA = 14 }
    for index = 1, class.skillCount do sheet.skills[class.skills[index]] = 1 end
    for _, name in ipairs(opts.skills or {}) do sheet.skills[name] = 1 end
    for _, extra in ipairs(opts.extras or {}) do
        sheet.classes[extra.class] = { level = extra.level, subclass = extra.subclass or "", spec = R.CLASSES[extra.class].specs[1] or "", skill = "" }
    end
    if opts.setup then opts.setup(sheet) end
    ns.ApplyGrants(sheet)
    RPSheet:ReplaceSheet(sheet)
    RPSheet.db.profile.channel = "EMOTE"
    RPSheet.busy, RPSheet.rollMode, RPSheet.rollModeLocked, RPSheet.castLevel = false, nil, false, nil
    RPSheet.refunds = nil
    return RPSheet:Sheet()
end

function Named(list, name)
    for _, entry in ipairs(list) do if entry.name == name then return entry end end
end
function Passive(name) return Named(RPSheet:Sheet().passives, name) end
function Ability(name) return Named(RPSheet:Sheet().abilities, name) end
function Spell(name) return Named(RPSheet:Sheet().spells, name) end
-- Puts a listed spell on the sheet (as the Spells page does) and returns it.
function Learn(name, class)
    local sheet = RPSheet:Sheet()
    local spell = Spell(name)
    if not spell then
        if not R.SPELLS[name] then error("no listed spell " .. name) end
        spell = CopyTable(R.SPELLS[name])
        spell.free = true
        sheet.spells[#sheet.spells + 1] = spell
    end
    if class then spell.class = class end
    ns.Util.NormalizeList(sheet.spells, R.TEMPLATES.spell)
    return Spell(name)
end
function Slot(level, pact)
    for _, tracker in ipairs(RPSheet:GetTrackers()) do
        if tracker.kind == "slot" and tracker.level == level and (tracker.pact or false) == (pact or false) then return tracker end
    end
end
function Tracker(label) return RPSheet:FindTracker(label) end
function Click(menu, piece)
    for _, item in ipairs(menu and menu.items or {}) do
        if item.text:find(piece, 1, true) then item.click() return true end
    end
    Check(false, ("menu \"%s\" has no row with \"%s\""):format(tostring(menu and menu.title), piece))
    return false
end
function HP() return RPSheet:State().hp end
