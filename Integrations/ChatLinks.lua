-- Rule terms in chat that can be hovered and clicked.
--
-- The game doesn't let an addon send its own links through chat, so announcements
-- carry a term in plain square brackets, such as "[Vex]" or "attacks with [Rapier]".
-- Each player's own copy of the addon turns those into links when the line is shown.
-- Without the addon the brackets are simply text.
--
--   hover  what the term means, from the rules data everyone with the addon has
--   click  the maths behind it: your own at once, another player's by asking their
--          addon (see Integrations/Sync.lua)
--
-- A link reads  |Haddon:rpsheet:<Name-Realm>:<term>|h[term]|h . The "addon:" link
-- type is one the game leaves for addons to handle.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local LINK = "addon:rpsheet"
local COLOR = "|cff71d5ff"

-- Puts a term in the plain form that gets linked. Used when announcing.
function ns.Mark(term)
    return "[" .. term .. "]"
end

function ns.PlayerFullName()
    return ("%s-%s"):format(UnitName("player"), GetNormalizedRealmName() or "")
end

---------------------------------------------------------------------------
-- What a term means
---------------------------------------------------------------------------
-- Returns a title and a list of lines, or nil for a term the rules data doesn't know
-- (a player's own ability, for instance).
function ns.TermInfo(term)
    if R.MASTERIES[term] then return term, { "Weapon mastery.", R.MASTERIES[term].desc } end
    for _, condition in ipairs(R.CONDITIONS) do
        if condition.name == term then return term, { "Condition.", condition.desc } end
    end
    local weapon = R.WEAPONS[term]
    if weapon then
        local lines = { ("%s weapon, %s."):format(weapon.category == "SIMPLE" and "Simple" or "Martial", R.WeaponSummary(term)) }
        for _, prop in ipairs(R.WEAPON_PROPERTY_ORDER) do
            if weapon.props[prop] then
                lines[#lines + 1] = ("%s: %s"):format(R.WEAPON_PROPERTIES[prop].name, R.WEAPON_PROPERTIES[prop].desc)
            end
        end
        lines[#lines + 1] = ("Mastery, %s: %s"):format(weapon.mastery, R.MASTERIES[weapon.mastery].desc)
        return term, lines
    end
    local spell = R.SPELLS[term]
    if spell then return term, { R.SPELL_LEVELS[spell.level] .. (spell.concentration and ", concentration." or "."), spell.desc } end
    if R.FEATS[term] then return term, { "Feat.", R.FEATS[term].desc } end
    if R.FIGHTING_STYLES[term] then return term, { "Fighting Style.", R.FIGHTING_STYLES[term].desc } end
    if R.TRAITS[term] and R.TRAITS[term].desc then return term, { R.TRAITS[term].desc } end
    -- "STR check" and "STR save" read as the ability; so does a companion's own roll.
    local stat, kind = (term:gsub("^companion ", "")):match("^(%u%u%u) (%l+)$")
    if stat and R.STAT_NAMES[stat] then
        local lines = { ns.Glossary[stat] }
        if kind == "save" then lines[#lines + 1] = ns.Glossary["Saving throw"] end
        return ("%s %s"):format(R.STAT_NAMES[stat], kind == "save" and "saving throw" or "check"), lines
    end
    if ns.Glossary[term] then return term, { ns.Glossary[term] } end
end

---------------------------------------------------------------------------
-- Turning marked terms into links
---------------------------------------------------------------------------
-- Lines the addon itself announces start with one of these after the character's name.
local OURS = { "rolls %[", "attacks with %[", "uses %[", "casts %[", "is now %[", "is no longer %[" }

-- Links every marked term in `text` that the rules data knows; in a line that reads
-- like one of ours, the others too (a player's own ability can be asked about).
function ns.LinkTerms(text, sender)
    local ours = false
    for _, pattern in ipairs(OURS) do
        ours = ours or text:find(pattern) ~= nil
    end
    return (text:gsub("%[([^%[%]|]+)%]", function(term)
        if ours or ns.TermInfo(term) then
            return ("|H%s:%s:%s|h%s[%s]|r|h"):format(LINK, sender, term, COLOR, term)
        end
    end))
end

-- Sender and term of one of our links, or nil.
local function ParseLink(link)
    if type(link) ~= "string" or link:sub(1, #LINK + 1) ~= LINK .. ":" then return end
    return link:sub(#LINK + 2):match("^([^:]+):(.+)$")
end

local function Filter(_, _, message, author, ...)
    -- In some places the game hides chat text from addons; such lines are left alone.
    if issecretvalue and (issecretvalue(message) or issecretvalue(author)) then return false end
    if type(message) ~= "string" or type(author) ~= "string" or not message:find("[", 1, true) then return false end
    if not author:find("-", 1, true) then author = author .. "-" .. (GetNormalizedRealmName() or "") end
    local linked = ns.LinkTerms(message, author)
    if linked == message then return false end
    return false, linked, author, ...
end

---------------------------------------------------------------------------
-- Hovering and clicking
---------------------------------------------------------------------------
local function OnEnter(frame, link)
    local sender, term = ParseLink(link)
    if not term then return end
    local title, lines = ns.TermInfo(term)
    GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
    GameTooltip:AddLine(title or term)
    for _, line in ipairs(lines or {}) do GameTooltip:AddLine(line, 1, 1, 1, true) end
    local mine = sender == ns.PlayerFullName()
    GameTooltip:AddLine(mine and "Click to see how your number is worked out."
        or ("Click to ask %s's sheet about it."):format(sender:match("^[^-]+")), 0.56, 0.56, 0.56, true)
    GameTooltip:Show()
    frame.rpSheetLinkTooltip = true
end

local function OnLeave(frame)
    if frame.rpSheetLinkTooltip then
        frame.rpSheetLinkTooltip = nil
        GameTooltip:Hide()
    end
end

-- Plain lines for a term nothing can be worked out for.
local function PrintInfo(term)
    local title, lines = ns.TermInfo(term)
    if title then RPSheet:Print(("%s: %s"):format(title, table.concat(lines, " "))) end
    return title ~= nil
end

local function OnClick(link)
    local sender, term = ParseLink(link)
    if not term or IsModifiedClick("CHATLINK") then return end
    if sender == ns.PlayerFullName() then
        local text = RPSheet:ExplainTerm(term)
        if text then RPSheet:Print(text) elseif not PrintInfo(term) then
            RPSheet:Print(("Nothing more is known about %s."):format(term))
        end
    elseif not RPSheet:RequestExplanation(sender, term) then
        -- Couldn't ask (another faction, or sharing is off): show what the rules say.
        if not PrintInfo(term) then RPSheet:Print(("Couldn't ask %s about %s."):format(sender:match("^[^-]+"), term)) end
    end
end

function ns.EnableChatLinks()
    for _, event in ipairs({ "CHAT_MSG_EMOTE", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER" }) do
        ChatFrame_AddMessageEventFilter(event, Filter)
    end
    for index = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. index]
        if frame then
            pcall(frame.HookScript, frame, "OnHyperlinkEnter", OnEnter)
            pcall(frame.HookScript, frame, "OnHyperlinkLeave", OnLeave)
        end
    end
    hooksecurefunc("SetItemRef", function(link) pcall(OnClick, link) end)
end
