-- Lua 5.1's string.format: %s takes only a string or a number (LuaJIT takes anything).
local realFormat = string.format
local NUMERIC = { d = true, i = true, u = true, c = true, x = true, X = true, o = true, e = true, E = true, f = true, g = true, G = true }
string.format = function(fmt, ...)
    if type(fmt) ~= "string" and type(fmt) ~= "number" then
        error("bad argument #1 to 'format' (string expected, got " .. type(fmt) .. ")", 2)
    end
    local n, count = 0, select("#", ...)
    for flags, spec in tostring(fmt):gmatch("%%([%-%+ #0]*%d*%.?%d*)([%a%%])") do
        if spec ~= "%" then
            n = n + 1
            local v = select(n, ...)
            if spec == "s" or spec == "q" then
                if type(v) ~= "string" and type(v) ~= "number" then
                    error(("bad argument #%d to 'format' (string expected, got %s)"):gsub("%%d", tostring(n + 1)):gsub("%%s", n > count and "no value" or type(v)), 2)
                end
            elseif NUMERIC[spec] then
                if type(v) ~= "number" and not (type(v) == "string" and tonumber(v)) then
                    error(("bad argument #%d to 'format' (number expected, got %s)"):gsub("%%d", tostring(n + 1)):gsub("%%s", n > count and "no value" or type(v)), 2)
                end
            else
                error("invalid option '%" .. spec .. "' to 'format'", 2)
            end
        end
    end
    return realFormat(fmt, ...)
end
format = string.format
