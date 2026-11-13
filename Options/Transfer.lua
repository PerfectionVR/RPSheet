-- "Import / Export" tab: share a character as a text string.
local _, ns = ...
local RPSheet = ns.addon
local Opt = ns.Opt

-- What was pasted into the import box, and what it decoded to.
local pasted, decoded, decodedName, problem = "", nil, nil, nil

local function SetPasted(_, text)
    pasted = text or ""
    decoded, decodedName = RPSheet:DecodeSheet(pasted)
    problem = not decoded and decodedName or nil
end

local function ImportStatus()
    if pasted == "" then return "" end
    if not decoded then return Opt.RED .. problem .. "|r\n" end
    local name = decodedName ~= "" and (decodedName .. ": ") or ""
    return ("%sReady to import: %s%s|r\n"):format(Opt.GREEN, name, RPSheet:DescribeSheet(decoded))
end

local function Import()
    RPSheet:ReplaceSheet(decoded)
    pasted, decoded, decodedName, problem = "", nil, nil, nil
    RPSheet:Print("Character imported.")
end

Opt.tabs.transfer = {
    type = "group", order = 11, name = "Import / Export",
    args = {
        exportHeader = { type = "header", order = 1, name = "Export" },
        exportHelp = {
            type = "description", order = 2,
            name = "This text is your whole character: class, origin, scores, proficiencies, gear, resources, abilities and passives. Click in the box, press Ctrl+A then Ctrl+C, and paste it anywhere: a note, Discord, a friend. Current HP and resource values are not included.\n",
        },
        export = {
            type = "input", order = 3, width = "full", multiline = 4, name = "Export string",
            get = function() return RPSheet:ExportSheet() end,
            set = function() end, -- read-only: edits are discarded
        },
        importHeader = { type = "header", order = 10, name = "Import" },
        importHelp = {
            type = "description", order = 11,
            name = "Paste an export string and press Accept to check it. Importing replaces the character on this sheet; your settings and theme are not touched.\n",
        },
        import = {
            type = "input", order = 12, width = "full", multiline = 4, name = "Import string",
            get = function() return pasted end,
            set = SetPasted,
        },
        status = { type = "description", order = 13, fontSize = "medium", name = ImportStatus },
        apply = {
            type = "execute", order = 14, name = "Import character",
            disabled = function() return not decoded end,
            confirm = true,
            confirmText = "Replace the character on this sheet with the imported one?",
            func = Import,
        },
    },
}
