-- The dropdowns of the "Class and origin" page under Customize (Options/Identity.lua).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet, With = Opt.Sheet, Opt.With

-- Changing class, species or background hands out what they grant (saving throws,
-- skills, traits, origin feat). Nothing already on the sheet is removed.
local function Granting(option, key)
    option.get = function() return Sheet()[key] end
    option.set = function(_, value)
        local sheet = Sheet()
        sheet[key] = value
        if key == "class" then sheet.subclass, sheet.spec = "", "" end
        if key == "species" then sheet.lineage = "" end
        ns.ApplyGrants(sheet)
        ns.NormalizeState(RPSheet:State())
        ns.RebuildOptions()
        Opt.Changed()
    end
    return option
end

-- Dropdown of the current class's subclasses or specializations.
local function ClassList(option, field)
    option.values = function()
        local class = RPSheet:ClassData()
        return (Opt.ListMap(class and class[field], true))
    end
    option.sorting = function()
        local class = RPSheet:ClassData()
        return (select(2, Opt.ListMap(class and class[field], true)))
    end
    return option
end

-- Dropdown for the first or second Fighting Style, shown once the feature is there.
local function StylePicker(slot, order, name)
    local field = ns.STYLE_FIELDS[slot]
    return {
        type = "select", order = order, name = name,
        desc = function()
            local lines = {}
            for _, style in ipairs(R.FIGHTING_STYLE_ORDER) do
                lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, style, R.FIGHTING_STYLES[style].desc)
            end
            return table.concat(lines, "\n\n")
        end,
        hidden = function() return not ns.HasStyleSlot(Sheet(), slot) end,
        -- Every style is offered here; the wizards only offer the ones the class may take.
        values = function() return (Opt.ListMap(R.FIGHTING_STYLE_ORDER, true)) end,
        sorting = function() return (select(2, Opt.ListMap(R.FIGHTING_STYLE_ORDER, true))) end,
        get = function() return Sheet()[field] end,
        set = function(_, value) Sheet()[field] = value; Opt.Regrant() end,
    }
end

-- Dropdown for the index-th class or subclass feature that offers options.
local function OptionPicker(index)
    local function Feature() return ns.OptionFeatures(Sheet())[index] end
    return {
        type = "select", order = 7.3 + index / 100,
        name = function() return Feature() and Feature().name or "" end,
        desc = function()
            local feature, lines = Feature(), {}
            -- A long list (pet families) shows only the one picked.
            local options = feature and feature.options or {}
            local picked = feature and Sheet().featureOptions[feature.name]
            for _, option in ipairs(options) do
                if #options <= 8 or option.name == picked then
                    local desc = option.desc
                    if type(desc) == "function" then desc = desc(Sheet().level, Sheet()) end -- some follow the level
                    lines[#lines + 1] = ("%s%s|r: %s"):format(Opt.GOLD, option.name, desc)
                end
            end
            if #lines == 0 then return "Pick one to read what it gives." end
            return table.concat(lines, "\n\n")
        end,
        hidden = function() return Feature() == nil end,
        values = function()
            local values = { [""] = "None" }
            for _, option in ipairs(Feature() and Feature().options or {}) do values[option.name] = option.name end
            return values
        end,
        get = function() return Feature() and Sheet().featureOptions[Feature().name] or "" end,
        set = function(_, value)
            Sheet().featureOptions[Feature().name] = value ~= "" and value or nil
            Opt.Regrant()
        end,
    }
end

Opt.IdentityPickers = { Granting = Granting, ClassList = ClassList, StylePicker = StylePicker, OptionPicker = OptionPicker }
