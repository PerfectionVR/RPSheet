-- Assembles the settings window from the tab files:
--   Character   overview, the creation wizard and levelling (Options/Character.lua)
--   Customize   every page that edits the character directly, in a tree on the left:
--               the pages in Opt.custom and the lists in Opt.lists
--   the other tabs in Opt.tabs (General, Appearance, Import / Export)
-- It also keeps the list pages in step with the active sheet.
local ADDON, ns = ...
local Opt = ns.Opt

local customize = {
    type = "group", order = 2, name = "Customize", childGroups = "tree",
    args = {
        intro = {
            type = "description", order = 0, fontSize = "medium",
            name = "Change any part of the character directly. Pick a page on the left.\n\nThe creation wizard and the level dialog follow the rules. These pages don't hold you to them: anything can be set, for a DM's ruling, a house rule or an experiment. Where a choice goes beyond what the rules allow, the page says so in red.\n",
        },
    },
}

ns.options = {
    type = "group",
    name = "RP Sheet",
    childGroups = "tab",
    args = { customize = customize },
}
for key, tab in pairs(Opt.tabs) do
    ns.options.args[key] = tab
end
for key, page in pairs(Opt.custom) do
    customize.args[key] = page
end
-- A list page has its entries as branches below it; its contents are filled in below.
for key, list in pairs(Opt.lists) do
    customize.args[key] = { type = "group", order = list.order, name = list.title, childGroups = "tree", args = {} }
end

-- One list page: help text, an Add button, and a page per entry with a Delete button.
local function RebuildList(key, list)
    local args = customize.args[key].args
    wipe(args)
    args.help = { type = "description", order = 0, name = list.help }
    args.add = {
        type = "execute", order = 1, name = list.extra and ("Add an empty " .. list.noun) or ("Add " .. list.noun),
        func = function()
            local entries = Opt.Sheet()[key]
            local entry = CopyTable(list.template)
            entry.name = ("New %s %d"):format(list.noun, #entries + 1)
            entries[#entries + 1] = entry
            ns.RebuildOptions()
            Opt.Changed()
        end,
    }
    if list.extra then list.extra(args) end
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
    ns.SnapSliders(ns.options)
    LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON)
end
