-- What arrives from other players is not trusted: broken, hostile, old and newer
-- payloads, and messages that are cut, doubled, out of order or from strangers. None
-- may raise an error, and nothing of theirs is shown that isn't plain text.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local PREFIX = "RPSheet4"
local world = NewWorld()
local vic = world:AddClient({ name = "Vic", trp3 = {} }):Login():OpenSheet()
local mal = world:AddClient({ name = "Mallory" }):Login():OpenSheet()
local friend = world:AddClient({ name = "Fred" }):Login():OpenSheet()
world:Advance(5)
vic:Build("WARRIOR", "", 5); mal:Build("ROGUE", "", 5); friend:Build("MAGE", "", 5)
world:Group({ vic, friend })
world:Advance(5)
local Pack = function(...) return (mal.ns.Codec.Pack("addon", ...)) end -- one value: the packed text

local function Int(value, low, high) return type(value) == "number" and value == math.floor(value) and value >= low and value <= high end
-- What Vic keeps of a sender is in the shape the tooltip counts on.
local function CheckCopy(label, sender)
    local copy = vic.addon:GetCachedStats(sender or mal.full)
    if not copy then return end
    local ok = type(copy.summary) == "string" and Plain(copy.summary, 160) and Int(copy.ac, -999, 999) and type(copy.stats) == "table"
        and type(copy.trackers) == "table" and #copy.trackers <= 4
    for i = 1, 6 do ok = ok and Int(copy.stats[i], -999, 999) end
    for _, tracker in ipairs(ok and copy.trackers or {}) do
        ok = ok and type(tracker[1]) == "string" and Plain(tracker[1], 40) and Int(tracker[2], -999, 999) and Int(tracker[3], -999, 999)
    end
    if copy.conditions ~= nil then
        ok = ok and type(copy.conditions) == "table" and #copy.conditions <= 16
        for _, name in ipairs(ok and copy.conditions or {}) do ok = ok and type(name) == "string" and Plain(name, 40) end
    end
    if copy.weapon ~= nil then ok = ok and type(copy.weapon) == "string" and Plain(copy.weapon, 40) and Int(copy.dice, -999, 999) and Int(copy.sides, -999, 999) end
    for key in pairs(copy) do
        ok = ok and (key == "summary" or key == "ac" or key == "stats" or key == "trackers" or key == "conditions" or key == "weapon" or key == "dice" or key == "sides")
    end
    Check(ok, label .. ": the copy kept is not clean")
    local fine, lines = pcall(vic.addon.GetStatLines, vic.addon, copy)
    if Check(fine, label .. ": the tooltip lines fail: " .. tostring(lines)) then
        for _, line in ipairs(lines) do Check(Plain(line, 400), label .. ": a tooltip line that isn't plain: " .. line:sub(1, 80)) end
    end
    vic:Hover(mal, true)
    for _, line in ipairs(vic:Tooltip() or {}) do Check(Plain(line, 400), label .. ": shown in the tooltip: " .. line:sub(1, 80)) end
    vic:Hover(nil)
end
local function Clean(label)
    for _, problem in ipairs(vic.errors) do Check(false, label .. ": error: " .. problem:sub(1, 500)) end
    vic.errors = {}
end
-- Hands Vic a message as the comm library would, from Mallory by whisper.
local function Give(label, message, distribution, sender)
    vic:Do(vic.addon.OnCommReceived, vic.addon, PREFIX, message, distribution or "WHISPER", sender == nil and mal.full or sender)
    Clean(label)
    CheckCopy(label)
end

local good = { summary = "Level 5 Rogue", ac = 15, stats = { 10, 16, 12, 10, 12, 8 }, trackers = { { "HP", 30, 38 } } }
local function With(changes)
    local data = CopyTable(good)
    for key, value in pairs(changes) do data[key] = value end
    return data
end
local deep = {}
do local at = deep for _ = 1, 300 do at.x = {} at = at.x end end
local big = ("x"):rep(20000)
local nasty = "|cffff0000red|r |Hitem:1:2|h[Sword]|h |TInterface\\Icons\\x:64|t |n line\nbreak\r\ttab \127 ||"

Section("wrong shapes", function()
    local payloads = {
        { "no data" }, { "a number", 5 }, { "a string", "stats" }, { "true", true }, { "an empty table", {} },
        { "stats a string", With({ stats = "x" }) }, { "stats a number", With({ stats = 5 }) },
        { "stats of strings", With({ stats = { "a", "b", "c", "d", "e", "f" } }) },
        { "stats of tables", With({ stats = { {}, {}, {}, {}, {}, {} } }) },
        { "stats huge", With({ stats = { 1e308, -1e308, math.huge, -math.huge, 2 ^ 53, 12.7 } }) },
        { "stats of number strings", With({ stats = { "12", "0x10", "1e400", "-5", " 7 ", "" } }) },
        { "a hundred stats", With({ stats = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 } }) },
        { "three stats", With({ stats = { 1, 2, 3 } }) },
        { "ac a table", With({ ac = {} }) }, { "ac a string", With({ ac = nasty }) }, { "ac huge", With({ ac = 1e300 }) },
        { "ac negative", With({ ac = -50000 }) }, { "ac a fraction", With({ ac = 15.5 }) }, { "ac missing", With({ ac = false }) },
        { "summary huge", With({ summary = big }) }, { "summary with escapes", With({ summary = nasty }) },
        { "summary a table", With({ summary = { nasty } }) }, { "summary a number", With({ summary = 12 }) },
        { "summary of control characters", With({ summary = "\1\2\3\4\5\6\7\8\9\10\11\12\13\14\15\16\27\31 end" }) },
        { "summary cut inside a character", With({ summary = ("\195\169"):rep(120) }) },
        { "summary of broken characters", With({ summary = "\255\254\192\128 \237\160\128 \240\159" }) },
        { "trackers a string", With({ trackers = "x" }) }, { "trackers of strings", With({ trackers = { "a", "b" } }) },
        { "a thousand trackers", With({ trackers = (function() local list = {} for i = 1, 1000 do list[i] = { "T" .. i, i, i } end return list end)() }) },
        { "tracker of tables", With({ trackers = { { {}, {}, {} } } }) },
        { "tracker with escapes", With({ trackers = { { nasty, "x", {} }, { big, 1e99, -1e99 } } }) },
        { "tracker without a name", With({ trackers = { { nil, 3, 4 } } }) },
        { "trackers with gaps", With({ trackers = { [1] = { "HP", 1, 2 }, [3] = { "Ki", 1, 2 }, [900] = { "X", 1, 2 }, name = "x" } }) },
        { "conditions a string", With({ conditions = nasty }) },
        { "a thousand conditions", With({ conditions = (function() local list = {} for i = 1, 1000 do list[i] = "C" .. i end return list end)() }) },
        { "conditions of everything", With({ conditions = { nasty, 5, {}, true, "", big, "Prone" } }) },
        { "weapon with escapes", With({ weapon = nasty, dice = "x", sides = {} }) },
        { "weapon huge", With({ weapon = big, dice = 1e99, sides = -1e99 }) },
        { "weapon without dice", With({ weapon = "Rapier" }) }, { "weapon a table", With({ weapon = {}, dice = 1, sides = 8 }) },
        { "nested deep", With({ summary = deep, trackers = deep, conditions = deep, more = deep }) },
        { "stats nested deep", { stats = deep } },
        { "keys that are tables", With({ [{}] = 1, [1.5] = 2, [true] = 3 }) },
    }
    for _, payload in ipairs(payloads) do
        local ok, message = pcall(Pack, "D", payload[2])
        if Check(ok, payload[1] .. ": can't be packed for the test: " .. tostring(message)) then Give(payload[1], message) end
    end
    local copy = vic.addon:GetCachedStats(mal.full)
    Check(copy ~= nil, "some of these are kept (cleaned)")
end)

Section("kinds and versions", function()
    vic:Do(vic.addon.OnCommReceived, vic.addon, PREFIX, Pack("D", good), "WHISPER", mal.full)
    local kept = vic.addon:GetCachedStats(mal.full)
    for _, kind in ipairs({ "Z", "d", "", 5, true, {}, "DD", "D\0" }) do
        Give("kind " .. tostring(kind), Pack(kind, With({ summary = "changed" })))
    end
    Give("no kind", Pack())
    Give("a table only", Pack(good))
    Eq(vic.addon:GetCachedStats(mal.full), kept, "an unknown kind changes nothing")
    -- an older client: no conditions, no weapon; a newer one: fields this one doesn't know
    Give("older client", Pack("D", { summary = "Level 2 Mage", ac = 11, stats = { 8, 14, 12, 16, 10, 10 }, trackers = {} }))
    local copy = vic.addon:GetCachedStats(mal.full)
    Eq(copy and copy.summary, "Level 2 Mage", "an older client's data is kept")
    Eq(copy and table.concat(vic.addon:GetStatLines(copy), " / "), "Level 2 Mage / AC 11 / STR 8 (-1)  \194\183  DEX 14 (+2)  \194\183  CON 12 (+1) / INT 16 (+3)  \194\183  WIS 10 (+0)  \194\183  CHA 10 (+0)", "an older client's lines")
    Give("older still: no trackers", Pack("D", { summary = "Level 2 Mage", ac = 11, stats = { 8, 14, 12, 16, 10, 10 } }))
    Check(vic.addon:GetCachedStats(mal.full) ~= copy, "data without trackers is kept too")
    Give("newer client", Pack("D", With({ version = 99, pet = { name = nasty, hp = 5 }, mount = "Horse", form = "Wolf", stats = { 10, 16, 12, 10, 12, 8, 99, 99 } }), "extra", { more = true }))
    copy = vic.addon:GetCachedStats(mal.full)
    Eq(copy and copy.summary, "Level 5 Rogue", "a newer client's data is kept")
    Check(copy and copy.pet == nil and copy.version == nil and copy.stats[7] == nil, "and what isn't known is dropped")
    -- another version of the addon talks on another prefix, which this one doesn't hear
    local before = #vic.errors
    mal.env.C_ChatInfo.SendAddonMessage("RPSheet5", Pack("D", With({ summary = "from the future" })), "WHISPER", vic.full)
    mal.env.C_ChatInfo.SendAddonMessage("RPSheet3", "anything at all", "WHISPER", vic.full)
    world:Advance(1)
    Eq(vic.addon:GetCachedStats(mal.full), copy, "another version's prefix is not heard")
    Eq(#vic.errors, before, "and raises nothing")
end)

Section("not a message at all", function()
    local valid = Pack("D", good)
    Give("empty", ""); Give("a space", " "); Give("zero bytes", "\0\0\0"); Give("text", "hello there")
    Give("not a string", 5); Give("nil", nil); Give("a table", {})
    for cut = 1, #valid - 1 do Give("cut after " .. cut, valid:sub(1, cut)) end
    for cut = 2, #valid do Give("cut before " .. cut, valid:sub(cut)) end
    math.randomseed(7)
    for round = 1, 300 do
        local at = math.random(1, #valid)
        Give("one byte changed #" .. round, valid:sub(1, at - 1) .. string.char(math.random(0, 255)) .. valid:sub(at + 1))
    end
    for round = 1, 200 do
        local bytes = {}
        for i = 1, math.random(1, 300) do bytes[i] = string.char(math.random(0, 255)) end
        Give("random bytes #" .. round, table.concat(bytes))
    end
    -- valid packing of something that is not ours
    local codec = mal.ns.Codec
    Give("print flavour", codec.Pack("print", "D", good))
    -- senders the game wouldn't give
    vic:Do(vic.addon.OnCommReceived, vic.addon, PREFIX, valid, "WHISPER", nil); Clean("no sender")
    vic:Do(vic.addon.OnCommReceived, vic.addon, PREFIX, valid, "WHISPER", 5); Clean("a number as sender")
    vic:Do(vic.addon.OnCommReceived, vic.addon, PREFIX, valid, nil, "Odd-Realm"); Clean("no distribution")
    vic:Do(vic.addon.OnCommReceived, vic.addon, PREFIX, valid, "WHISPER", ""); Clean("an empty sender")
    Eq(vic.addon:GetCachedStats("-Realm"), nil, "nothing is kept for a sender without a name")
end)

Section("something huge", function()
    -- Text that packs small and unpacks huge: over the size ours can have it is not unpacked.
    local bomb = Pack("D", With({ summary = ("\0"):rep(8 * 1024 * 1024) }))
    Check(#bomb > 1024, ("the test's bomb is %d bytes on the wire"):format(#bomb))
    local start = os.clock()
    Give("an 8 MB bomb", bomb)
    Check(os.clock() - start < 0.05, ("a message too long to be ours took %.3f s"):format(os.clock() - start))
    -- the largest that still passes
    local size, fits = 64 * 1024, nil
    while size <= 4 * 1024 * 1024 do
        local packed = Pack("D", With({ summary = ("\0"):rep(size) }))
        if #packed > 1024 then break end
        fits, size = packed, size * 2
    end
    if Check(fits ~= nil, "a bomb under the limit for the test") then
        start = os.clock()
        Give("a bomb under the limit", fits)
        local took = os.clock() - start
        Check(took < 0.5, ("the largest message that is unpacked took %.3f s"):format(took))
        print(("  (a %d-byte message unpacking to %d KB took %.3f s)"):format(#fits, size / 2 / 1024, took))
    end
    -- a long but honest message still arrives: an explanation is the longest of ours
    local long = Pack("X", "Athletics", ("Athletics: d20 + 2 (Strength) + 3 (proficiency). "):rep(10))
    Check(#long <= 1024, ("an answer of 500 letters is %d bytes"):format(#long))
end)

Section("strangers and names", function()
    -- Mallory is not in Vic's party: what she whispers is kept under her own name only.
    local fred = vic.addon:GetCachedStats(friend.full)
    Check(fred ~= nil, "Vic has Fred's stats from the party")
    mal.addon:SendCommMessage(PREFIX, Pack("D", With({ summary = "I am Fred", name = friend.full, sender = friend.full })), "WHISPER", vic.full)
    world:Advance(2)
    Eq(vic.addon:GetCachedStats(friend.full), fred, "a stranger can't replace a party member's stats")
    Eq((vic.addon:GetCachedStats(mal.full) or {}).summary, "I am Fred", "her message is kept under her own name")
    -- a party message from someone who is not in the party can't happen in the game;
    -- the addon takes the game's word for the sender either way
    Give("claims to be a party message", Pack("D", good), "PARTY")
    Eq(vic.addon:GetCachedStats(friend.full), fred, "still Fred's own")
    -- her questions are answered at most once in a while
    local before = #world.wire
    for _ = 1, 30 do mal.env.C_ChatInfo.SendAddonMessage(PREFIX, Pack("Q"), "WHISPER", vic.full) end
    world:Advance(4)
    Eq(world:Traffic(vic, before), 1, "answers to a flood of questions")
    Check(mal.throttled > 0, "the game itself throttled the flood")
    -- a question on the party channel makes the party send again, once
    world:Advance(10)
    before = #world.wire
    for _ = 1, 8 do friend.env.C_ChatInfo.SendAddonMessage(PREFIX, friend.ns.Codec.Pack("addon", "Q"), "PARTY") end
    world:Advance(8)
    Eq(world:Traffic(vic, before), 1, "broadcasts after a flood of party questions")
end)

Section("the wire: doubled, out of order, parts lost", function()
    world:Join(mal, vic)
    world:Advance(5)
    -- every message twice
    world.tamper = function(message) return { message, message } end
    mal.addon:TakeDamage(3)
    world:Advance(3)
    Clean("doubled"); CheckCopy("doubled")
    Eq((vic.addon:GetCachedStats(mal.full) or {}).trackers[1][2], mal.addon:State().hp, "doubled: hit points")
    -- two changes that arrive the wrong way round: the later arrival is what is kept
    local held
    world.tamper = function(message)
        if message.from ~= mal then return { message } end
        if not held then held = message return {} end
        local first = held
        held = nil
        return { message, first }
    end
    mal.addon:TakeDamage(1); world:Advance(3)
    mal.addon:TakeDamage(1); world:Advance(3)
    Clean("out of order"); CheckCopy("out of order")
    world.tamper = false
    mal.addon:TakeDamage(1); world:Advance(3)
    Eq((vic.addon:GetCachedStats(mal.full) or {}).trackers[1][2], mal.addon:State().hp, "the next change puts it right")
    -- a long message in parts: with every part, without the first, the middle, the last
    local letters = {}
    for i = 1, 800 do letters[i] = string.char(math.random(33, 123)) end
    local long = Pack("X", "Athletics", table.concat(letters))
    local function Parts(drop)
        local count = 0
        world.tamper = function(message)
            if message.from ~= mal then return { message } end
            count = count + 1
            if count == drop then return {} end
            return { message }
        end
        local warned = #vic.printed
        mal.addon:SendCommMessage(PREFIX, long, "PARTY")
        world:Advance(8)
        Clean("parts, dropping " .. tostring(drop))
        world.tamper = false
        return count, #vic.printed - warned
    end
    Check(#long > 255 * 2, "the test message takes three parts")
    local count = Parts(nil)
    Eq(count, 3, "parts sent")
    for drop = 1, 3 do Parts(drop) end
    Parts(nil)
    -- stray parts that belong to nothing
    for _, control in ipairs({ "\001", "\002", "\003", "\004", "\005", "\009" }) do
        mal.env.C_ChatInfo.SendAddonMessage(PREFIX, control .. Pack("D", good), "PARTY")
        mal.env.C_ChatInfo.SendAddonMessage(PREFIX, control, "PARTY")
    end
    world:Advance(15)
    Clean("stray parts"); CheckCopy("stray parts")
    -- The comm library says nothing to the player about parts that don't add up (a
    -- stranger could fill the chat with such lines otherwise).
    local warnings = 0
    for _, line in ipairs(vic.printed) do
        if line:find("lost network data", 1, true) then warnings = warnings + 1 end
    end
    Eq(warnings, 0, "lines the comm library printed about lost parts")
    mal:LeaveGroup()
    world:Advance(3)
end)

Section("questions about terms", function()
    -- Every way a term can be asked about, with sharing on and off: no error on the
    -- side that answers, and the answer is plain text of bounded length.
    local terms = { "Athletics", "STR check", "DEX save", "initiative", "spell attack", "", " ", nasty, big, "%", "%d", "(", "[", "]]", "%f[%w]",
        ("a"):rep(60), "companion STR check", "companion", "\0", "Second Wind", "Longsword", ".", "^$", "STR  check", "XXX check", "AAA save" }
    for _, weapon in ipairs(vic.addon:Sheet().weapons) do terms[#terms + 1] = weapon.name end
    for _, ability in ipairs(vic.addon:Sheet().abilities) do terms[#terms + 1] = ability.name end
    for _, passive in ipairs(vic.addon:Sheet().passives) do terms[#terms + 1] = passive.name end
    for _, skill in ipairs(vic.ns.Rules.SKILLS) do terms[#terms + 1] = skill.name end
    local answered = 0
    for _, term in ipairs(terms) do
        world:Advance(1.1) -- past the cooldown per asker
        local before = #world.wire
        Give("asked about " .. tostring(term):sub(1, 20), Pack("E", term))
        world:Advance(0.5)
        for i = before + 1, #world.wire do
            local sent = world.wire[i]
            if sent.from == vic then
                answered = answered + 1
                Eq(sent.chatType, "WHISPER", "an answer is whispered")
                Eq(sent.target, mal.full, "to the asker")
            end
        end
    end
    Check(answered >= 20, "most questions are answered, got " .. answered)
    for _, term in ipairs({ 5, true, {}, { "Athletics" } }) do Give("asked about a " .. type(term), Pack("E", term)) end
    -- what comes back to the asker
    local codec = vic.ns.Codec
    local ok, kind, term, text = codec.Unpack("addon", world.wire[#world.wire].text)
    Check(ok and kind == "X" and type(text) == "string" and #text <= 500, "the last answer is a short text")
    -- a flood of questions from one player gets one answer a second
    world:Advance(2)
    local before = #world.wire
    for _ = 1, 20 do vic:Do(vic.addon.OnCommReceived, vic.addon, PREFIX, Pack("E", "Athletics"), "WHISPER", mal.full) end
    world:Advance(0.5)
    Eq(world:Traffic(vic, before), 1, "answers to twenty questions at once")
    -- on the party channel, or with sharing off, nothing is said
    world:Advance(2)
    before = #world.wire
    Give("asked on the party channel", Pack("E", "Athletics"), "PARTY")
    vic.addon.db.profile.share = false
    Give("asked with sharing off", Pack("E", "Athletics"))
    world:Advance(1)
    Eq(world:Traffic(vic, before), 0, "answers on the party channel or with sharing off")
    vic.addon.db.profile.share = true
end)

Section("answers nobody asked for", function()
    local function Shown(from)
        local list = {}
        for i = from + 1, #vic.printed do list[#list + 1] = vic.printed[i] end
        return list
    end
    local before = #vic.printed
    Give("an answer out of the blue", Pack("X", "Athletics", "Buy gold at |Hurl:evil|h[evil.example]|h"))
    Give("an answer with odd types", Pack("X", {}, {}))
    Give("an answer with nothing", Pack("X"))
    Eq(#Shown(before), 0, "lines shown for answers that were not asked for")
    -- Vic asks Mallory; the answer that comes is hers to word, and is shown as plain text
    Check(vic.addon:RequestExplanation(mal.full, "Athletics"), "the question is sent")
    before = #vic.printed
    Give("the wrong term", Pack("X", "Stealth", "not what was asked"))
    Eq(#Shown(before), 0, "an answer about another term is not shown")
    Give("another player answers", Pack("X", "Athletics", "I am not Mallory"), "WHISPER", friend.full)
    Eq(#Shown(before), 0, "an answer from someone who wasn't asked is not shown")
    Give("the hostile answer", Pack("X", "Athletics", nasty .. big))
    local lines = Shown(before)
    Eq(#lines, 1, "the answer is shown once")
    local body = (lines[1] or ""):gsub("^|cff33ff99RPSheet|r: ", "")
    Check(Plain(body, 520), "the answer shown is not plain text: " .. body:sub(1, 120))
    Give("the same answer again", Pack("X", "Athletics", "again"))
    Eq(#Shown(before), 1, "a second answer to one question is not shown")
    -- a question that is never answered ends with a line saying so
    Check(vic.addon:RequestExplanation(mal.full, "Stealth"), "a second question")
    before = #vic.printed
    world:Advance(6)
    lines = Shown(before)
    Check(#lines == 1 and lines[1]:find("didn't answer", 1, true), "an unanswered question is closed with a line: " .. tostring(lines[1]))
    Give("an answer after the wait", Pack("X", "Stealth", "late"))
    Eq(#Shown(before), 1, "an answer after the wait is not shown")
end)

world:CheckClean("hostile")
Summary("t-sync-hostile")
