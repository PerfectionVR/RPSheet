-- STUB (belongs in env.lua): a serializer that really makes text, the same text for the
-- same data, and an encoding without spaces. env.lua's returns "SER" for anything, so
-- two exports could never be compared and an import gave back the very same table.
local function Dump(value, out)
    local kind = type(value)
    if kind == "table" then
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b)
            if type(a) ~= type(b) then return type(a) < type(b) end
            return a < b
        end)
        out[#out + 1] = "{"
        for _, key in ipairs(keys) do
            out[#out + 1] = "["; Dump(key, out); out[#out + 1] = "]="; Dump(value[key], out); out[#out + 1] = ","
        end
        out[#out + 1] = "}"
    elseif kind == "string" then
        out[#out + 1] = (("%q"):format(value):gsub("\\\n", "\\n"))
    else
        out[#out + 1] = tostring(value)
    end
end
local lib = LibStub("LibSerialize")
function lib:Serialize(...)
    local out = {}
    Dump({ n = select("#", ...), ... }, out)
    return table.concat(out)
end
function lib:Deserialize(text)
    local fn = loadstring("return " .. text)
    if not fn then return false end
    local ok, packed = pcall(setfenv(fn, {}))
    if not ok or type(packed) ~= "table" then return false end
    return true, unpack(packed, 1, packed.n)
end
local deflate = LibStub("LibDeflate")
function deflate:EncodeForPrint(text) return (text:gsub(".", function(c) return ("%02x"):format(c:byte()) end)) end
function deflate:DecodeForPrint(text)
    if #text % 2 ~= 0 or text:find("%X") then return nil end
    return (text:gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end))
end
