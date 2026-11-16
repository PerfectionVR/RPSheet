-- Sharing stats, part 5: questions about a term. A player who clicks another's term in
-- chat asks that player's addon how the number is worked out, and gets plain text back.
local _, ns = ...
local RPSheet = ns.addon
local S = ns.Sync

local EXPLAIN_COOLDOWN = 1  -- seconds before explaining to the same player again
local ASK_TIMEOUT = 5       -- seconds an explanation is waited for

local lastExplain, asked = {}, {} -- per player: last answer given, and the question we asked

-- Drops the cooldowns that are over (see S.ForgetOld).
function S.ForgetExplained()
    local now = GetTime()
    for name, at in pairs(lastExplain) do
        if now - at >= EXPLAIN_COOLDOWN then lastExplain[name] = nil end
    end
end

-- Asks another player's addon how one of their numbers is worked out (a term clicked
-- in chat). Returns false when the question can't be sent.
function RPSheet:RequestExplanation(fullName, term)
    if not S.Sharing() or not S.CanSend() then return false end
    local question = { term = term }
    asked[fullName] = question
    self:SendCommMessage(S.PREFIX, ns.Codec.Pack("addon", "E", term), "WHISPER", fullName)
    local name = fullName:match("^[^-]+")
    self:Print(("Asking %s's sheet about %s..."):format(name, term))
    -- No answer comes from the other faction, from someone who has sharing off or who
    -- has left: say so instead of leaving the player waiting.
    C_Timer.After(ASK_TIMEOUT, function()
        if asked[fullName] ~= question then return end
        asked[fullName] = nil
        self:Print(("%s's sheet didn't answer."):format(name))
    end)
    return true
end

-- Someone clicked one of our terms in chat and asks how it is worked out.
function S.handlers.E(self, sender, distribution, data)
    local now = GetTime()
    local term = S.Text(data, nil, 60)
    if term and distribution == "WHISPER" and S.CanSend()
        and now - (lastExplain[sender] or -EXPLAIN_COOLDOWN) >= EXPLAIN_COOLDOWN then
        lastExplain[sender] = now
        -- The term is whatever the other player sent: an error stays here.
        local ok, text = pcall(self.ExplainTerm, self, term)
        if not ok or type(text) ~= "string" then text, self.explainCapture = "", nil end
        -- Colour codes can't travel; the receiver strips them anyway, and keeps no
        -- more than this.
        text = ns.Codec.Cut(ns.Codec.PlainText(text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")), 500)
        self:SendCommMessage(S.PREFIX, ns.Codec.Pack("addon", "X", term, text), "WHISPER", sender)
    end
end

-- The answer to a question we asked. Anything else is ignored.
function S.handlers.X(self, sender, _, data, extra)
    local term, text = S.Text(data, nil, 60), S.Text(extra, "", 500)
    if term and asked[sender] and asked[sender].term == term then
        asked[sender] = nil
        local name = sender:match("^[^-]+")
        if text ~= "" then
            self:Print(("%s - %s"):format(name, text))
        else
            self:Print(("%s's sheet has nothing to work out for %s."):format(name, term))
        end
    end
end
