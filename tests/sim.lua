-- Shared pieces for simulations: start the addon, feed an options tree the way the
-- dialog does, report problems.
dofile(ARG3 .. "/env.lua")
LoadAddon()
ns = NS
R, RPSheet, W, Opt = ns.Rules, ns.addon, ns.Wizard, ns.Opt
PROBLEMS = {}
function Problem(text)
    if not PROBLEMS[text] then PROBLEMS[text] = true; print("PROBLEM: " .. text) end
end
function Try(label, fn, ...)
    local res = { xpcall(fn, function(m) return debug.traceback(m, 2) end, ...) }
    if not res[1] then Problem(label .. ": " .. tostring(res[2]):sub(1, 900)) return nil end
    return unpack(res, 2)
end

local function Member(option, key, path, info)
    local value = option[key]
    if type(value) == "function" then
        return Try(path .. "." .. key, value, info)
    end
    return value
end

-- Evaluates every member of every visible option below `group`, like AceConfigDialog.
function Feed(group, path, out)
    out = out or {}
    for key, option in pairs(group.args) do
        local p = path .. "." .. key
        local info = { key, option = option, type = option.type }
        local hidden = Member(option, "hidden", p, info)
        local name = Member(option, "name", p, info)
        if type(name) ~= "string" then Problem(p .. ".name is " .. type(name)) end
        if not hidden then
            local desc = Member(option, "desc", p, info)
            if desc ~= nil and type(desc) ~= "string" then Problem(p .. ".desc is " .. type(desc)) end
            local disabled = Member(option, "disabled", p, info)
            out[#out + 1] = { path = p, option = option, name = name, disabled = disabled }
            local kind = option.type
            if kind == "group" then
                Feed(option, p, out)
            elseif kind == "select" or kind == "multiselect" then
                local values = Member(option, "values", p, info)
                if type(values) ~= "table" then Problem(p .. ".values is " .. type(values)) values = {} end
                for k, v in pairs(values) do
                    if type(v) ~= "string" then Problem(p .. ".values[" .. tostring(k) .. "] is " .. type(v)) end
                end
                local sorting = Member(option, "sorting", p, info)
                if sorting then
                    local seen = {}
                    for _, k in ipairs(sorting) do
                        if values[k] == nil then Problem(p .. ".sorting names " .. tostring(k) .. " which values lacks") end
                        if seen[k] then Problem(p .. ".sorting lists " .. tostring(k) .. " twice") end
                        seen[k] = true
                    end
                    for k in pairs(values) do
                        if not seen[k] and k ~= "SLOTS" then Problem(p .. ".sorting leaves out " .. tostring(k)) end
                    end
                end
                if kind == "select" then
                    local current = Member(option, "get", p, info)
                    if current ~= nil and values[current] == nil then
                        out[#out].stray = current
                    end
                    out[#out].values, out[#out].current = values, current
                else
                    for k in pairs(values) do
                        if option.get then Try(p .. ".get", option.get, info, k) end
                    end
                end
            elseif kind == "range" then
                local current = Member(option, "get", p, info)
                if type(current) ~= "number" then Problem(p .. ".get gives " .. type(current)) end
                if type(option.min) ~= "number" or type(option.max) ~= "number" then Problem(p .. " has no min/max")
                elseif type(current) == "number" and (current < option.min or current > option.max) then
                    Problem(("%s value %s outside %s..%s"):format(p, current, option.min, option.max))
                end
                out[#out].current = current
            elseif kind == "toggle" or kind == "input" or kind == "color" then
                local current = Member(option, "get", p, info)
                if kind == "input" and current ~= nil and type(current) ~= "string" then Problem(p .. ".get gives " .. type(current)) end
                out[#out].current = current
            elseif kind == "description" or kind == "header" or kind == "execute" then
            else
                Problem(p .. " has type " .. tostring(kind))
            end
        end
    end
    return out
end

function Start()
    Try("OnInitialize", function() RPSheet:OnInitialize() end)
    -- The window is made of stubs: leave drawing out, keep the rest.
    RPSheet.BuildWindow = function() end
    RPSheet.BuildMinimapIcon = function() end
    Try("OnEnable", function() RPSheet:OnEnable() end)
end
