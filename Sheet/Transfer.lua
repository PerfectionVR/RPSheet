-- Exporting a character as a text string and importing one.
-- An imported string comes from someone else, so nothing in it is trusted: a fresh
-- sheet is built field by field, keeping only known fields of the right type, with
-- text stripped of colour codes and numbers kept inside sane limits.
-- The cleaning is in Sheet/TransferClean.lua, TransferSheet.lua and TransferChoices.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Codec = ns.Codec
local Text = ns.TransferKit.Text
local CleanSheet = ns.TransferKit.CleanSheet

local PREFIX = "!RPS1!" -- marks an RP Sheet export, format 1

-- The active character as one line of text. Current HP and resources are not included.
function RPSheet:ExportSheet()
    return PREFIX .. Codec.Pack("print", { format = 1, name = self:GetCharacterName(), sheet = self:Sheet() })
end

-- Reads an export string. Returns a clean sheet and the exported name, or nil and
-- a message saying what is wrong with the text.
function RPSheet:DecodeSheet(text)
    text = (text or ""):gsub("%s+", "")
    if text == "" then return nil, "Paste an export string first." end
    if text:sub(1, #PREFIX) ~= PREFIX then
        return nil, "This is not an RP Sheet export string. It should start with " .. PREFIX
    end
    local ok, payload = Codec.Unpack("print", text:sub(#PREFIX + 1))
    if not ok or type(payload) ~= "table" or type(payload.sheet) ~= "table" then
        return nil, "The string is damaged or incomplete. Copy the whole thing and try again."
    end
    if payload.format ~= 1 then
        return nil, "This string was made by a newer version of RP Sheet. Update the addon to import it."
    end
    return CleanSheet(payload.sheet), Text(payload.name, 40)
end

-- One line describing a sheet that isn't the active one, e.g. "Level 3 Rogue, Human".
function RPSheet:DescribeSheet(sheet)
    local class, species = R.CLASSES[sheet.class], R.SPECIES[sheet.species]
    local parts = { ("Level %d %s"):format(sheet.level, class and class.name or "character without a class") }
    if ns.IsMulticlass(sheet) then parts[1] = ns.ClassLine(sheet) end
    if species then parts[#parts + 1] = species.name end
    parts[#parts + 1] = ("%d abilities, %d passives"):format(#sheet.abilities, #sheet.passives)
    return table.concat(parts, ", ")
end
