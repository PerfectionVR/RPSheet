dofile(ARG3 .. "/env.lua")
local files = LoadAddon()
print("loaded", #files)
local names = {}
for k, v in pairs(LOG.globalsRead) do names[#names + 1] = k .. "(" .. v .. ")" end
table.sort(names)
print("UNKNOWN GLOBALS READ: " .. table.concat(names, " "))
names = {}
for k, v in pairs(LOG.globalsWritten) do names[#names + 1] = k .. "<-" .. v end
table.sort(names)
print("GLOBALS WRITTEN: " .. table.concat(names, " "))
io.stdout:flush()
