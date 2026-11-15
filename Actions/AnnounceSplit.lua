-- Splits an announcement that is too long for one chat message into two or more, so
-- that the result at its end isn't lost. A line is broken between its parts (after a
-- dash, a full stop, a comma), else between words; never inside a [marked term], which
-- becomes a link on the other side, and never inside a letter of several bytes.
local _, ns = ...

-- The first message ends with MORE; the next starts with ON. An emote is shown after
-- the character's name, and "Name (continued) damage 7" still reads as theirs. (The
-- chat links know a line that starts so as one of ours: Integrations/ChatLinks.lua.)
local MORE, ON = " ...", "(continued) "

-- Where a line may break, the best first: { text, bytes of it that stay with the part
-- before }. Each is tried in the second half of the room first, so parts aren't tiny.
local BREAKS = { { " - ", 0 }, { ". ", 1 }, { "; ", 1 }, { ", ", 1 }, { ": ", 1 }, { " ", 0 } }

-- True when no [term] is open at the end of `text`.
local function Closed(text)
    local open = text:match(".*()%[")
    if not open then return true end
    local close = text:match(".*()%]")
    return close ~= nil and close > open
end

-- The last place `separator` stands in text[from..upto] outside a marked term.
local function LastBreak(text, separator, from, upto)
    local found
    local at = text:find(separator, from, true)
    while at and at + #separator - 1 <= upto do
        if Closed(text:sub(1, at - 1)) then found = at end
        at = text:find(separator, at + 1, true)
    end
    return found
end

-- Cuts `text` in two: a first part of at most `room` bytes, and the rest.
local function Break(text, room)
    for _, low in ipairs({ math.floor(room / 2), 1 }) do
        for _, kind in ipairs(BREAKS) do
            local at = LastBreak(text, kind[1], math.max(low, 2), room + #kind[1] - kind[2])
            if at then
                return text:sub(1, at - 1 + kind[2]), text:sub(at + #kind[1])
            end
        end
    end
    -- One long word: cut it, but not through a letter.
    local first = ns.Codec.Cut(text, room)
    return first, text:sub(#first + 1)
end

-- `text` as a list of at most `most` messages of at most `limit` bytes each. What still
-- doesn't fit in the last one is cut off with "...".
function ns.SplitChat(text, limit, most)
    local parts, lead = {}, ""
    while #lead + #text > limit and #parts < most - 1 do
        local first, rest = Break(text, limit - #lead - #MORE)
        if first == "" then break end -- (no room at all: never with the limits in use)
        parts[#parts + 1] = lead .. first:gsub("%s+$", "") .. MORE
        text, lead = rest:gsub("^%s+", ""), ON
    end
    local last = lead .. text
    if #last > limit then last = ns.Codec.Cut(last, limit - 3) .. "..." end
    if text ~= "" or #parts == 0 then parts[#parts + 1] = last end
    return parts
end
