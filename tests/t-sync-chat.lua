-- Announcements and the terms in them: every channel choice, what is sent when the
-- channel can't be used, long lines, text the chat would refuse; then the links other
-- clients make of the marked terms: every term of the rules data gets a tooltip,
-- clicking asks the right sheet, and chat text can't smuggle in a link.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local anna = world:AddClient({ name = "Anna" }):Login():OpenSheet()
local bert = world:AddClient({ name = "Bert", oldChatFilters = true }):Login():OpenSheet()
local cara = world:AddClient({ name = "Cara", realm = "ArgentDawn" }):Login():OpenSheet()
world:Advance(5)
anna:Build("WARRIOR", "", 5); bert:Build("MAGE", "", 5); cara:Build("ROGUE", "", 5)
world:Advance(3)

local OPEN, CLOSE = "|Haddon:rpsheet:[^|:]+:[^|]*|h|cff71d5ff", "|r|h"
-- A shown line with the links this addon made taken off again.
local function Unlinked(text) return (text:gsub(OPEN, ""):gsub(CLOSE, "")) end
local function Last(client) return client.chat[#client.chat] end
local function Printed(client, from)
    local list = {}
    for i = from + 1, #client.printed do list[#list + 1] = client.printed[i] end
    return table.concat(list, "\n")
end
local function Say(client, channel, text)
    client.addon.db.profile.channel = channel
    local chat, printed = #world.chatLog, #client.printed
    client:Do(client.addon.Announce, client.addon, text)
    world:Advance(0.2)
    return world.chatLog[chat + 1], Printed(client, printed), #world.chatLog - chat
end

Section("channels", function()
    Eq(table.concat(anna.ns.CHANNELS, " "), "EMOTE PARTY RAID SELF", "the channels offered")
    -- alone
    local sent, printed = Say(anna, "EMOTE", "waves.")
    Check(sent and sent.chatType == "EMOTE" and sent.text == "waves.", "an emote carries the text alone (the game puts the name in front)")
    Eq(Last(bert) and Last(bert).event, "CHAT_MSG_EMOTE", "others nearby see the emote")
    sent, printed = Say(anna, "PARTY", "waves.")
    Check(not sent and printed:find("Anna waves.", 1, true) and printed:find("not in a party", 1, true), "party without a party: shown to the player only, with the reason: " .. printed)
    sent, printed = Say(anna, "RAID", "waves.")
    Check(not sent and printed:find("not in a raid", 1, true), "raid without a raid: " .. printed)
    sent, printed = Say(anna, "SELF", "waves.")
    Check(not sent and printed:find("Anna waves.", 1, true) and not printed:find("only you", 1, true), "self only: " .. printed)
    -- in a party
    world:Group({ anna, bert })
    world:Advance(3)
    sent = Say(anna, "PARTY", "waves.")
    Check(sent and sent.chatType == "PARTY" and sent.text == "Anna waves.", "a party line starts with the character's name")
    Eq(Last(bert) and Last(bert).text, "Anna waves.", "the party sees it")
    Check(Last(cara).text ~= "Anna waves.", "others don't")
    sent, printed = Say(anna, "RAID", "waves.")
    Check(not sent and printed:find("not in a raid", 1, true), "raid from a party: " .. printed)
    -- in a raid
    world:Group({ anna, bert }, true)
    world:Advance(3)
    sent = Say(anna, "RAID", "waves.")
    Check(sent and sent.chatType == "RAID" and sent.text == "Anna waves.", "a raid line")
    sent = Say(anna, "PARTY", "waves.")
    Check(sent and sent.chatType == "PARTY", "the party channel works in a raid too")
    -- the game blocks addon chat
    anna.lockdown = true
    for _, channel in ipairs({ "EMOTE", "PARTY", "RAID" }) do
        sent, printed = Say(anna, channel, "waves.")
        Check(not sent and printed:find("blocks addon chat", 1, true), channel .. " while the game blocks it: " .. printed)
    end
    sent, printed = Say(anna, "SELF", "waves.")
    Check(not sent and not printed:find("only you", 1, true), "self only is as ever")
    anna.lockdown = false
    -- cycling, also from a saved value that is not a channel
    local seen = {}
    anna.addon.db.profile.channel = "EMOTE"
    for _ = 1, 4 do anna.addon:CycleChannel(); seen[#seen + 1] = anna.addon.db.profile.channel end
    Eq(table.concat(seen, " "), "PARTY RAID SELF EMOTE", "the channel row cycles")
    anna.addon.db.profile.channel = "SAY"
    sent, printed = Say(anna, "SAY", "waves.")
    Check(not sent and printed:find("Anna waves.", 1, true), "a saved channel that is none of them is not sent anywhere")
    anna.addon:CycleChannel()
    Eq(anna.addon.db.profile.channel, "EMOTE", "and the row gets out of it")
    world:Group({ anna, bert })
    world:Advance(3)
end)

Section("long lines and text the chat refuses", function()
    for _, channel in ipairs({ "EMOTE", "PARTY" }) do
        for length = 240, 262 do
            local sent = Say(anna, channel, ("x"):rep(length - 1) .. ".")
            Check(sent and #sent.text <= 255, ("%s: a line of %d letters is sent with %d"):format(channel, length, sent and #sent.text or -1))
        end
        -- an accented letter at every place the cut can fall
        for shift = 0, 5 do
            local sent = Say(anna, channel, ("a"):rep(shift) .. ("\195\169"):rep(200))
            Check(sent and #sent.text <= 255 and VALID_UTF8(sent.text) and sent.text:sub(-3) == "...", ("%s: accented letters, shift %d"):format(channel, shift))
            sent = Say(anna, channel, ("a"):rep(shift) .. ("\240\159\152\128"):rep(100))
            Check(sent and #sent.text <= 255 and VALID_UTF8(sent.text), ("%s: four-byte characters, shift %d"):format(channel, shift))
        end
        -- a long line of marked terms: cut wherever, it is still plain text
        local sent = Say(anna, channel, "attacks with " .. (anna.ns.Mark("Greatsword") .. " and "):rep(30))
        Check(sent and #sent.text <= 255 and not sent.text:find("|", 1, true), channel .. ": a long line of terms")
        local shown = Last(bert).text
        Eq(Unlinked(shown), sent.text, channel .. ": the links change nothing else of a cut line")
        -- what the player typed into a name
        sent = Say(anna, channel, "uses [Sword |cffff0000of|r Doom]\nand |Hitem:1|h[cheats]|h\tand ||more|n.")
        Check(sent and Plain(sent.text, 255), channel .. ": pipes and line breaks are left out: " .. tostring(sent and sent.text))
        Check(sent and sent.text:find("Doom] and", 1, true), channel .. ": a line break becomes a space: " .. tostring(sent and sent.text))
    end
    -- a short line is sent as it is
    local sent = Say(anna, "PARTY", "rolls [Stealth]: 14 + 5 = 19")
    Eq(sent and sent.text, "Anna rolls [Stealth]: 14 + 5 = 19", "a short line")
    -- the name: from the settings, with things in it chat refuses
    anna.addon.db.char.name = "An|cffff0000na\n the |TInterface\\Icons\\x:16|t Bold"
    sent = Say(anna, "PARTY", "waves.")
    Check(sent and Plain(sent.text, 255) and sent.text:find("waves.", 1, true), "a name with codes in it: " .. tostring(sent and sent.text))
    local _, printed = Say(anna, "SELF", "waves.")
    Check(not Unlinked(printed:gsub("^|cff33ff99RPSheet|r: ", "")):find("|", 1, true), "the same name, shown to the player only: " .. printed)
    anna.addon.db.char.name = ("N"):rep(300)
    sent = Say(anna, "PARTY", "waves.")
    Check(sent and #sent.text <= 255, "a name longer than a chat line")
    anna.addon.db.char.name = ""
    Eq(#world.violations, 0, "lines the game would have refused")
end)

Section("what play really announces", function()
    -- every kind of click, on every channel that goes out: each line is one the game takes
    local longest = 0
    for _, client in ipairs({ anna, bert, cara }) do
        local addon, sheet = client.addon, client.addon:Sheet()
        addon.db.profile.channel = "EMOTE"
        local before = #client.said
        addon:RollCheck("Stealth", 5); addon:RollCheck("STR check", 2); addon:RollCheck("DEX save", 2, nil, false)
        addon:RollCheck("initiative", 2); addon:Attack(); addon:TakeDamage(3, "fire"); addon:Heal(3)
        addon:ToggleCondition("Poisoned"); addon:ToggleCondition("Poisoned"); addon:ToggleCondition("Unconscious"); addon:ToggleCondition("Unconscious")
        addon:ToggleCondition("Prone"); addon:ChangeExhaustion(1); addon:ChangeExhaustion(-1)
        for _, ability in ipairs(sheet.abilities) do client:Do(addon.UseAbility, addon, ability) world:Advance(0.1) end
        for _, spell in ipairs(sheet.spells) do client:Do(addon.CastSpell, addon, spell) world:Advance(0.1) end
        addon:LongRest()
        world:Advance(3)
        Check(#client.said - before >= 12, client.name .. ": lines announced: " .. (#client.said - before))
        for i = before + 1, #client.said do longest = math.max(longest, #tostring(client.said[i].text)) end
    end
    print(("  the longest line of this play was %d bytes"):format(longest))
    Eq(#world.violations, 0, "lines the game would have refused")
    world:CheckClean("play")
end)

Section("every term has a tooltip", function()
    local R, ns = bert.ns.Rules, bert.ns
    local lists, missing, unlinkable, total = {}, {}, {}, 0
    local function Add(kind, name) lists[#lists + 1] = { kind, name } end
    for name in pairs(R.MASTERIES) do Add("mastery", name) end
    for _, condition in ipairs(R.CONDITIONS) do Add("condition", condition.name) end
    for name in pairs(R.WEAPONS) do Add("weapon", name) end
    for name in pairs(R.SPELLS) do Add("spell", name) end
    for name in pairs(R.FEATS) do Add("feat", name) end
    for name in pairs(R.FIGHTING_STYLES) do Add("fighting style", name) end
    for name, trait in pairs(R.TRAITS) do if type(trait) == "table" and trait.desc then Add("trait", name) end end
    for name in pairs(ns.Glossary) do Add("glossary", name) end
    for _, skill in ipairs(R.SKILLS) do Add("skill", skill.name) end
    for _, stat in ipairs(R.STATS) do
        Add("check", stat .. " check"); Add("save", stat .. " save"); Add("companion", "companion " .. stat .. " check"); Add("companion", "companion " .. stat .. " save")
    end
    for _, entry in ipairs(lists) do
        local kind, term = entry[1], entry[2]
        total = total + 1
        local ok, title, lines = pcall(ns.TermInfo, term)
        if not Check(ok, ("%s %s: TermInfo fails: %s"):format(kind, term, tostring(title))) then
        elseif not title then
            missing[kind] = (missing[kind] or "") .. " [" .. term .. "]"
        else
            local fine = type(title) == "string" and title ~= "" and type(lines) == "table" and #lines >= 1
            for _, line in ipairs(fine and lines or {}) do fine = fine and type(line) == "string" and line ~= "" end
            Check(fine, ("%s %s: a title and lines of text"):format(kind, term))
            if term:find("[%[%]|]") then
                unlinkable[#unlinkable + 1] = term
            else
                -- as it stands in a line of someone who has no such addon line: linked because it is known
                local text = ("Someone says [%s] here"):format(term)
                local linked = ns.LinkTerms(text, "Cara-ArgentDawn")
                local links = Links(linked)
                if Check(#links == 1 and links[1].link == "addon:rpsheet:Cara-ArgentDawn:" .. term, ("%s %s: linked as %s"):format(kind, term, linked)) then
                    Eq(Unlinked(linked), text, kind .. " " .. term .. ": the text around the link")
                    local shown = bert:HoverLink(links[1].link)
                    Check(#shown >= 3 and shown[1] == title and shown[#shown]:find("Click to ask Cara", 1, true),
                        ("%s %s: the tooltip has %d lines"):format(kind, term, #shown))
                    for _, line in ipairs(shown) do Check(type(line) == "string" and line ~= "", kind .. " " .. term .. ": an empty tooltip line") end
                end
            end
        end
    end
    print(("  %d terms of the rules data checked"):format(total))
    for kind, names in pairs(missing) do Check(false, ("%s terms without a tooltip:%s"):format(kind, names:sub(1, 600))) end
    Eq(#unlinkable, 0, "terms that can't be linked because of a bracket or pipe in the name: " .. table.concat(unlinkable, ", "))
    -- what the addon marks that is not in the rules data: linked in a line of ours, with the term as the title
    for _, term in ipairs({ "initiative", "spell attack", "My Own Trick", "Beast's Strike" }) do
        local linked = ns.LinkTerms(("Anna rolls [%s]: 12"):format(term), "Anna-Realm")
        local links = Links(linked)
        if Check(#links == 1, term .. ": linked in a line of ours: " .. linked) then
            local shown = bert:HoverLink(links[1].link)
            Check(#shown >= 2 and shown[#shown]:find("Click to ask Anna", 1, true), term .. ": its tooltip says whose sheet to ask")
        end
        Eq(#Links(ns.LinkTerms(("Someone says [%s] here"):format(term), "Anna-Realm")), ns.TermInfo(term) and 1 or 0, term .. ": outside a line of ours")
    end
    world:CheckClean("terms")
end)

Section("links in chat as others see them", function()
    local sent = Say(anna, "PARTY", "rolls " .. anna.ns.Mark("Athletics") .. ": 14 + 5 = 19")
    local line = Last(bert)
    Eq(line and Unlinked(line.text), sent and sent.text, "the line others see reads the same")
    local links = Links(line.text)
    Eq(links[1] and links[1].link, "addon:rpsheet:Anna-Realm:Athletics", "the term is a link to the sender's sheet")
    Eq(links[1] and links[1].text, "|cff71d5ff[Athletics]|r", "and looks like one")
    -- hovering: what the term means; clicking: Anna's sheet is asked and answers
    local shown = bert:HoverLink(links[1].link)
    Check(shown[1] == "Athletics" and #shown >= 3, "hovering shows the term")
    bert.env.ChatFrame1:Run("OnHyperlinkLeave")
    Check(not bert.env.GameTooltip:IsShown(), "and leaving hides it")
    local before, wire = #bert.printed, #world.wire
    bert:ClickLink(links[1].link)
    world:Advance(1)
    local printed = Printed(bert, before)
    Check(printed:find("Asking Anna's sheet about Athletics", 1, true), "clicking says it is asking: " .. printed)
    Check(printed:find("Anna - Athletics", 1, true) and printed:find("Strength", 1, true), "and the answer is shown: " .. printed)
    Eq(world:Traffic(nil, wire), 2, "a question and an answer")
    world:Advance(6)
    Check(not Printed(bert, before):find("didn't answer", 1, true), "an answered question is not called unanswered")
    -- the same line in Anna's own chat: her own number, at once
    line = Last(anna)
    before, wire = #anna.printed, #world.wire
    anna:ClickLink(Links(line.text)[1].link)
    Check(Printed(anna, before):find("Athletics", 1, true), "clicking your own term explains it")
    Eq(world:Traffic(nil, wire), 0, "without asking anyone")
    Check(anna:HoverLink(Links(line.text)[1].link)[#anna.env.GameTooltip.lines]:find("your number", 1, true), "your own term says so")
    -- a modified click (to paste the link) and other addons' links are left alone
    before = #bert.printed
    bert.env.IsModifiedClick = function() return true end
    bert:ClickLink(links[1].link)
    bert.env.IsModifiedClick = function() return false end
    for _, link in ipairs({ "item:1234", "addon:other:Anna-Realm:Athletics", "addon:rpsheet", "addon:rpsheet:", "addon:rpsheet:Anna-Realm", "addon:rpsheet::", "player:Anna", "" }) do
        bert:ClickLink(link); bert:HoverLink(link)
    end
    bert:Do(bert.env.SetItemRef, nil); bert:Do(bert.env.SetItemRef, 5)
    world:Advance(1)
    Eq(Printed(bert, before), "", "nothing happens for those")
    -- with sharing off the rules text is shown instead of asking
    bert.addon.db.profile.share = false
    before, wire = #bert.printed, #world.wire
    bert:ClickLink(links[1].link)
    world:Advance(1)
    Check(Printed(bert, before):find("Athletics:", 1, true) and world:Traffic(nil, wire) == 0, "with sharing off the term's meaning is printed: " .. Printed(bert, before))
    bert.addon.db.profile.share = true
    -- someone who can't answer (sharing off on their side): the wait ends with a line
    anna.addon.db.profile.share = false
    before = #bert.printed
    bert:ClickLink(links[1].link)
    world:Advance(6)
    Check(Printed(bert, before):find("Anna's sheet didn't answer", 1, true), "no answer: " .. Printed(bert, before))
    anna.addon.db.profile.share = true
    -- an emote from another realm, seen by someone outside the party
    sent = Say(cara, "EMOTE", "attacks with " .. cara.ns.Mark("Dagger") .. " - to hit: 12")
    line = Last(bert)
    Eq(Links(line.text)[1] and Links(line.text)[1].link, "addon:rpsheet:Cara-ArgentDawn:Dagger", "an emote from another realm links to that player")
    world.bareSenders = true
    Say(anna, "EMOTE", "is now " .. anna.ns.Mark("Prone") .. ".")
    Eq(Links(Last(bert).text)[1] and Links(Last(bert).text)[1].link, "addon:rpsheet:Anna-Realm:Prone", "an author without a realm gets the player's own")
    world.bareSenders = false
    world:CheckClean("links")
end)

Section("chat can't smuggle in a link", function()
    local ns = bert.ns
    -- What a player can type arrives without escape codes (the game sees to that), so
    -- all that can be tried is brackets. Whatever is in them, taking this addon's own
    -- wrapping off again gives back the line as it was typed.
    math.randomseed(11)
    local pieces = { "[", "]", "[[", "]]", ":", "addon:rpsheet:", "Vic-Realm", "Athletics", "rolls ", "uses ", "casts ", "is now ", "h", "H", "%", "%s", "%1", " ",
        "Fireball", "Prone", "\195\169", "-", "[Prone]", "[x]", "attacks with ", "[]", "[ ]", "r", "cff71d5ff" }
    for round = 1, 3000 do
        local parts = {}
        for i = 1, math.random(1, 12) do parts[i] = pieces[math.random(#pieces)] end
        local text = table.concat(parts)
        local ok, linked = pcall(ns.LinkTerms, text, "Mallory-Realm")
        if Check(ok, "LinkTerms fails on: " .. text .. ": " .. tostring(linked)) then
            if Unlinked(linked) ~= text then Check(false, ("round %d: \"%s\" became \"%s\""):format(round, text, linked)) end
            for _, link in ipairs(Links(linked)) do
                if link.link:sub(1, 28) ~= "addon:rpsheet:Mallory-Realm:" then Check(false, "a link that doesn't name the author: " .. link.link) end
            end
        end
    end
    CHECKS = CHECKS + 3000
    -- a link the game made (an item, a spell) keeps its name to itself
    local item = "look: |cffffffff|Hitem:2140::::::::70:::::|h[Dagger]|h|r and |cff71d5ff|Hspell:133:0|h[Fireball]|h|r then [Prone]"
    bert:ShowChat("CHAT_MSG_PARTY", item, "Mallory-Realm")
    local shown = Last(bert).text
    Eq(shown, item:gsub("%[Prone%]", "|Haddon:rpsheet:Mallory-Realm:Prone|h|cff71d5ff[Prone]|r|h"), "an item link and a spell link stay as they are")
    bert:ShowChat("CHAT_MSG_PARTY", "Mallory casts |cff71d5ff|Hspell:133:0|h[Fireball]|h|r", "Mallory-Realm")
    Eq(#Links(Last(bert).text), 1, "also in a line that reads like one of ours")
    -- lines without brackets, and things that are not text, pass untouched
    for _, text in ipairs({ "hello", "", "a ] b [ c", "[", "]", "[]" }) do
        bert:ShowChat("CHAT_MSG_PARTY", text, "Mallory-Realm")
        Eq(Last(bert).text, text, "untouched: " .. text)
    end
    bert:ShowChat("CHAT_MSG_PARTY", nil, "Mallory-Realm"); bert:ShowChat("CHAT_MSG_PARTY", "[Prone]", nil); bert:ShowChat("CHAT_MSG_PARTY", 5, 5)
    -- other chat (say, whispers, channels) is not touched at all
    bert:ShowChat("CHAT_MSG_SAY", "I am [Prone]", "Mallory-Realm")
    Eq(Last(bert).text, "I am [Prone]", "a line said aloud is left alone")
    -- the term of a link is shown as plain text in the tooltip, whatever it is
    local shownTip = bert:HoverLink("addon:rpsheet:Mallory-Realm:Gold for sale: evil.example")
    Check(shownTip[1] == "Gold for sale: evil.example" and shownTip[2]:find("Click to ask Mallory", 1, true), "an unknown term shows as itself")
    world:CheckClean("smuggle")
end)

Section("text the game keeps from addons", function()
    -- In some places the game hands addons values they may not look into; anything
    -- done with one is an error there. Such lines and senders are passed by.
    local function Touched() error("a secret value was looked into") end
    local SECRET = setmetatable({}, { __index = Touched, __concat = Touched, __len = Touched, __tostring = Touched })
    bert.env.issecretvalue = function(value) return rawequal(value, SECRET) end
    bert:ShowChat("CHAT_MSG_PARTY", SECRET, "Mallory-Realm")
    Check(rawequal(Last(bert).text, SECRET), "a secret line is left as it is")
    bert:ShowChat("CHAT_MSG_PARTY", "I am [Prone]", SECRET)
    Eq(Last(bert).text, "I am [Prone]", "a line from a secret author is left as it is")
    bert:Do(bert.addon.OnCommReceived, bert.addon, "RPSheet4", bert.ns.Codec.Pack("addon", "Q"), "WHISPER", SECRET)
    bert.addon:Roll(20, function() end)
    bert:Fire("CHAT_MSG_SYSTEM", SECRET)
    bert:Fire("CHAT_MSG_SYSTEM", "Bert rolls 7 (1-20)")
    local unitName = bert.env.UnitName
    bert.env.UnitName = function(unit) if unit == "mouseover" then return SECRET end return unitName(unit) end
    bert:Hover(anna)
    bert.env.UnitName = unitName
    bert.env.issecretvalue = nil
    bert:Hover(nil)
    world:Advance(1)
    world:CheckClean("secret")
end)

Eq(#world.violations, 0, "lines the game would have refused, in all")
world:CheckClean("chat")
Summary("t-sync-chat")
