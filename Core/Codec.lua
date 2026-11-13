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
