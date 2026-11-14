-- The part of the level dialog that asks for the choices inside feats (data in
-- Data/FeatChoices.lua, rules in Sheet/FeatChoices.lua): one dropdown per pick, under
-- a heading per feat. The same for every feat and every kind of choice.
local _, ns = ...
local Opt = ns.Opt

local SLOT_LIMIT = 36 -- dropdowns built ahead; more picks than this are not expected

-- Where a feat on the sheet comes from, to tell two of the same feat apart.
local function Source(instance)
    local level = instance.id:match("^level:(%d+)$")
    if level then return "level " .. level end
    return instance.id:match("^trait:(.+)$") or "origin"
end

-- An inline group for the dialog. `Context` returns the character, the picks being
-- made, the feats they are for and the level (see ns.FeatInstances), or nothing while
-- the dialog is closed.
function Opt.FeatChoiceGroup(order, Context)
    -- The dropdowns to show right now, with the picks brought in line first: a pick
    -- that followed another (a spell of a list) goes when that one changes.
    local function Slots()
        local sheet, store, instances, level = Context()
        if not sheet then return {} end
        ns.NormalizeFeatChoices(store, instances, level)
        return ns.FeatChoiceSlots(store, instances, level), sheet, store, instances
    end

    local group = {
        type = "group", inline = true, order = order, args = {},
        name = function()
            local sheet, store, instances, level = Context()
            if not sheet then return "Choices of your feats" end
            local made, total = ns.FeatChoiceProgress(store, instances, level)
            return ("Choices of your feats (%d of %d made)"):format(made, total)
        end,
        hidden = function() return #Slots() == 0 end,
    }

    for index = 1, SLOT_LIMIT do
        local function Slot()
            local slots, sheet, store, instances = Slots()
            return slots[index], sheet, store, instances, slots[index - 1]
        end
        -- A heading where the picks of another feat start.
        group.args["feat" .. index] = {
            type = "header", order = index * 2 - 1,
            name = function()
                local slot = Slot()
                return slot and ("%s (%s)"):format(slot.instance.name, Source(slot.instance)) or ""
            end,
            hidden = function()
                local slot, _, _, _, before = Slot()
                return slot == nil or (before ~= nil and before.instance == slot.instance)
            end,
        }
        group.args["pick" .. index] = {
            type = "select", order = index * 2, width = 1.5,
            name = function()
                local slot = Slot()
                if not slot then return "" end
                return slot.count > 1 and ("%s %d"):format(slot.choice.title, slot.index) or slot.choice.title
            end,
            desc = function()
                local slot = Slot()
                return slot and slot.choice.desc or ""
            end,
            hidden = function() return (Slot()) == nil end,
            values = function()
                local slot, sheet, store, instances = Slot()
                local values = { [""] = "Not chosen" }
                for _, value in ipairs(slot and ns.FeatChoiceValues(sheet, store, instances, slot) or {}) do values[value] = value end
                return values
            end,
            sorting = function()
                local slot, sheet, store, instances = Slot()
                local sorted = { "" }
                for _, value in ipairs(slot and ns.FeatChoiceValues(sheet, store, instances, slot) or {}) do sorted[#sorted + 1] = value end
                return sorted
            end,
            get = function()
                local slot = Slot()
                return slot and slot.picked[slot.index] or ""
            end,
            set = function(_, value)
                local slot = Slot()
                if slot then slot.picked[slot.index] = value ~= "" and value or nil end
            end,
        }
    end
    return group
end
