-- t-conform-classes.lua: the features a sheet gains at each level against the site's
-- list, and the spells a class or subclass always has prepared.
local C = Conform
local Build = C.Build

-- True when an entry of the sheet is the site's feature, or one of its named parts:
-- the same name, or the name followed by ":" or a space and more.
local function Starts(name, with)
    return name == with or name:sub(1, #with + 1) == with .. ":" or name:sub(1, #with + 1) == with .. " "
end
local function IsFeature(name, feature)
    if Starts(name, feature.name) then return true end
    for _, kid in ipairs(feature.kids) do if Starts(name, kid) then return true end end
    return false
end

-- The first entry of a name map for a feature: under "<label>/<name>@<level>",
-- "<label>/<name>", "<name>@<level>" or "<name>"; the label is the class key, its
-- core class, or the subclass.
local function Lookup(map, labels, name, level)
    for _, label in ipairs(labels) do
        local found = map[("%s/%s@%d"):format(label, name, level)] or map[label .. "/" .. name]
        if found then return found end
    end
    return map[("%s@%d"):format(name, level)] or map[name]
end

-- The features the sheet gains at each level against the site's list for that level.
-- `kind` is "class" or "subclass": which of the sheet's entries are looked at.
function C.Features(key, label, site, sheets, kind)
    local labels = kind == "class" and { key, R.CLASSES[key].base } or { label:match("/(.*)$") }
    local function Named(level, name)
        for _, entry in pairs(sheets.entries[level] or {}) do if entry.name == name then return entry end end
    end
    for level = 1, R.MAX_LEVEL do
        local gained, explained = {}, {}
        for auto, entry in pairs(sheets.entries[level]) do
            if auto:find("^" .. kind .. ":") and not (sheets.entries[level - 1] or {})[auto] then gained[#gained + 1] = entry end
        end
        table.sort(gained, function(a, b) return a.name < b.name end)
        local onSite = {}
        for _, feature in ipairs(site.features[level]) do
            onSite[feature.name] = true
            local id = ("%s L%d site feature %s"):format(label, level, feature.name)
            if not feature.subclass and not Names.STRUCTURE[feature.name] then
                C.features = C.features + 1
                local found = false
                for _, entry in ipairs(gained) do
                    if IsFeature(entry.name, feature) then found, explained[entry] = true, true end
                end
                -- named again at a later level: the entry of that name has to grow there
                local now, before = Named(level, feature.name), Named(level - 1, feature.name)
                if not found and now and before and now.sig ~= before.sig then found = true; C.grown = C.grown + 1 end
                local merged = not found and Lookup(Names.MERGED, labels, feature.name, level)
                if merged and merged.counted then
                    C.merged = C.merged + 1 -- a number of its own is compared under that name
                elseif merged then
                    C.merged = C.merged + 1
                    -- merged into another entry: that entry has to be there, and new or
                    -- different at this level
                    now, before = Named(level, merged.to), Named(level - 1, merged.to)
                    if not now then
                        C.Differs(id, ("said to be part of %s, which isn't on the sheet"):format(merged.to))
                    elseif before and before.sig == now.sig and not merged.same then
                        C.Differs(id, ("said to be part of %s, which doesn't change at this level"):format(merged.to))
                    end
                    for _, entry in ipairs(gained) do if entry.name == merged.to then explained[entry] = true end end
                elseif not found then
                    C.Differs(id, "not on the sheet at this level")
                end
            end
        end
        for _, entry in ipairs(gained) do
            if not explained[entry] then
                local id = ("%s L%d addon feature %s"):format(label, level, entry.name)
                local extra = Lookup(Names.EXTRA, labels, entry.name, level)
                C.extras = C.extras + 1
                local spell = false
                for _, step in ipairs(site.spells) do
                    for _, name in ipairs(step.level == level and step.names or {}) do spell = spell or (extra and name == extra.spell) end
                end
                if not extra then
                    C.Differs(id, "the site lists no such feature at this level")
                elseif extra.spell then
                    if not spell then C.Differs(id, ("said to belong to the spell %s, which the site doesn't give at this level"):format(extra.spell)) end
                elseif not onSite[extra.of] then
                    C.Differs(id, ("said to belong to %s, which the site doesn't list at this level"):format(extra.of))
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Spells a class or subclass always has
---------------------------------------------------------------------------
local function Descriptions(sheet)
    local text = {}
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for _, entry in ipairs(list) do text[#text + 1] = tostring(entry.desc):lower() end
    end
    return table.concat(text, "\n")
end

-- The site's lists of always-prepared spells, by level and (for some) by
-- specialization or by an option of a feature. A list the addon puts on the spell
-- list is compared there; the others have to be named in a feature's text.
function C.Spells(key, label, site, subclass)
    local class = R.CLASSES[key]
    local specs = {}
    for _, spec in ipairs(class.specs) do specs[spec] = true end
    for _, step in ipairs(site.spells) do
        if #step.names > 0 then
            local spec = specs[step.block] and step.block or class.specs[1]
            local function At(level)
                local sheet = Build(key, (level >= R.SUBCLASS_LEVEL or class.hero) and subclass or "", spec, level)
                -- an option named like the block ("Arid" for "Arid Land")
                for _, feature in ipairs(ns.OptionFeatures(sheet)) do
                    for _, option in ipairs(feature.options) do
                        if step.block:sub(1, #option.name) == option.name then sheet.featureOptions[feature.name] = option.name end
                    end
                end
                ns.ApplyGrants(sheet) -- again, with the option chosen
                sheet = C.Use(sheet)
                local prepared = {}
                for name in pairs(ns.AlwaysPrepared(sheet)) do prepared[name:lower()] = true end
                return prepared, Descriptions(sheet)
            end
            local now, text = At(step.level)
            local before = step.level > 1 and At(step.level - 1) or {}
            for _, name in ipairs(step.names) do
                local id = ("%s L%d %s spell %s%s"):format(label, step.level, step.kind, name, step.block ~= "0" and " (" .. step.block .. ")" or "")
                C.compared = C.compared + 1
                if step.kind == "prepared" and now[name] then
                    if before[name] then C.Differs(id, "always prepared before this level") end
                elseif not text:find(name, 1, true) then
                    C.Differs(id, step.kind == "prepared" and "not always prepared at this level, and not named in a feature" or "not named in a feature of this level")
                elseif step.kind == "prepared" then
                    C.Differs(id .. " in text only", "named in a feature's text, but not put on the spell list")
                end
            end
        end
    end
end
