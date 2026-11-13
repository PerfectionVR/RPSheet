-- Assembles the settings window from the tab files, and keeps the list tabs
-- (resources, weapons, abilities, passives) in step with the active sheet.
local ADDON, ns = ...
local Opt = ns.Opt

ns.options = {
    type = "group",
    name = "RP Sheet",
    childGroups = "tab",
    args = {},
}
for key, tab in pairs(Opt.tabs) do
    ns.options.args[key] = tab
end
-- A list tab shows its entries in a tree on the left; its contents are filled in below.
for key, list in pairs(Opt.lists) do
    ns.options.args[key] = { type = "group", order = list.order, name = list.title, childGroups = "tree", args = {} }
end

-- One list tab: help text, an Add button, and a page per entry with a Delete button.
local function RebuildList(key, list)
    local args = ns.options.args[key].args
    wipe(args)
    args.help = { type = "description", order = 0, name = list.help }
    args.add = {
        type = "execute", order = 1, name = "Add " .. list.noun,
        func = function()
            local entries = Opt.Sheet()[key]
            local entry = CopyTable(list.template)
            entry.name = ("New %s %d"):format(list.noun, #entries + 1)
            entries[#entries + 1] = entry
            ns.RebuildOptions()
            Opt.Changed()
        end,
    }
    for index, entry in ipairs(Opt.Sheet()[key]) do
        local page = {
            type = "group", order = index + 1,
            name = function() return entry.name ~= "" and entry.name or "(unnamed)" end,
            args = list.build(entry),
        }
        page.args.delete = {
            type = "execute", order = 2000, name = "Delete this " .. list.noun,
            confirm = true,
            func = function()
                ns.DismissAuto(Opt.Sheet(), entry)
                table.remove(Opt.Sheet()[key], index)
                ns.RebuildOptions()
                Opt.Changed()
            end,
        }
        args["item" .. index] = page
    end
end

-- Call after an entry is added or removed, or when another sheet becomes active.
function ns.RebuildOptions()
    for key, list in pairs(Opt.lists) do
        RebuildList(key, list)
    end
    for _, rebuild in ipairs(Opt.rebuilders) do
        rebuild()
    end
    LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON)
end
