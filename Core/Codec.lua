-- Turns data into compact text and back (LibSerialize + LibDeflate).
-- Two flavours of text: "print" survives copy and paste (export strings), "addon"
-- is safe for the hidden addon channel (syncing between players).
local _, ns = ...
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

local Codec = {}
ns.Codec = Codec

local ENCODE = { print = "EncodeForPrint", addon = "EncodeForWoWAddonChannel" }
local DECODE = { print = "DecodeForPrint", addon = "DecodeForWoWAddonChannel" }

function Codec.Pack(flavour, ...)
    local compressed = LibDeflate:CompressDeflate(LibSerialize:Serialize(...), { level = 9 })
    return LibDeflate[ENCODE[flavour]](LibDeflate, compressed)
end

-- Returns true and the packed values, or false when the text isn't valid.
-- The values come from outside (another player, a pasted string): treat them as untrusted.
function Codec.Unpack(flavour, text)
    if type(text) ~= "string" then return false end
    local compressed = LibDeflate[DECODE[flavour]](LibDeflate, text)
    if not compressed then return false end
    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then return false end
    return LibSerialize:Deserialize(serialized)
end

-- The first `length` bytes of `text` at most, without cutting a character of several
-- bytes (an accented letter) in half: half a character is not valid text for the game.
function Codec.Cut(text, length)
    if #text <= length then return text end
    text = text:sub(1, length)
    local lead, tail = text:match("([\192-\255])([\128-\191]*)$")
    if lead then
        local byte = lead:byte()
        local more = (byte >= 240 and 3) or (byte >= 224 and 2) or 1
        if #tail < more then text = text:sub(1, -(#tail + 2)) end
    end
    return text
end

-- The characters of several bytes in a run of bytes above 127; bytes that don't form
-- one are left out.
local function Characters(run)
    local kept, at = {}, 1
    while at <= #run do
        local byte = run:byte(at)
        local more = (byte >= 240 and byte < 245 and 3) or (byte >= 224 and byte < 240 and 2) or (byte >= 194 and byte < 224 and 1)
        local character = more and run:sub(at, at + more)
        if character and #character == more + 1 and not character:find("[^\128-\191]", 2) then
            kept[#kept + 1] = character
            at = at + more + 1
        else
            at = at + 1
        end
    end
    return table.concat(kept)
end

-- Text from outside made safe to show or to send to chat: no escape codes (colours,
-- links, textures), no control characters, no broken characters.
function Codec.PlainText(text)
    return (text:gsub("[|%c]", ""):gsub("[\128-\255]+", Characters))
end
