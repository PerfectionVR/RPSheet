-- A short description of one step of an ability (see Rules.ACTIONS).
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Short description of one step, for tooltips and the editor.
function RPSheet:ActionText(action)
    local kind = action.type
    if kind == "ROLL" then
        local parts = { "d20" }
        if R.STAT_NAMES[action.stat] then parts[#parts + 1] = action.stat end
        if R.STAT_NAMES[action.stat2] then parts[#parts + 1] = action.stat2 end
        if action.proficient then parts[#parts + 1] = "proficiency" end
        if (action.rollFlat or 0) ~= 0 then parts[#parts + 1] = tostring(action.rollFlat) end
        return ("%s: %s"):format(R.ROLL_KINDS[action.kind] or "Roll", table.concat(parts, " + "))
    elseif kind == "DICE" then
        local text = R.DICE_KINDS[action.dice] or "Dice"
        text = action.count > 0 and ("%s: %dd%d"):format(text, action.count, action.sides) or (text .. ":")
        if (action.flat or 0) ~= 0 then text = text .. (action.flat < 0 and " - " or " + ") .. math.abs(action.flat) end
        if action.perSlot then text = text .. " per slot level" end
        if (action.strain or "") ~= "" then text = text .. ", more with each use" end
        if (action.slotAdd or 0) > 0 then text = text .. (", +%dd%d per slot level above 1st"):format(action.slotAdd, action.sides) end
        if R.AMOUNT_SOURCES[action.stat] and action.stat ~= "" then
            text = text .. " + " .. (R.AMOUNT_SHORT[action.stat] or action.stat)
        end
        return text
    elseif kind == "WEAPON" then
        return ("Weapon dice x%d"):format(action.times)
    elseif kind == "SPEND" then
        local text = ("Spend %d %s"):format(action.amount, action.resource)
        if action.freeIfFull ~= "" then text = text .. (" (free when %s is full)"):format(action.freeIfFull) end
        if action.firstFree then text = text .. " (free the first time after a long rest)" end
        if (action.otherwise or "") ~= "" then text = text .. (", or %d %s once that is used up"):format(action.otherwiseAmount, action.otherwise) end
        if (action.refund or "") ~= "" then text = text .. (" (right-click to take it back if %s)"):format(action.refund) end
        return text
    elseif kind == "GAIN" then
        return ("Regain %d %s"):format(action.amount, action.resource)
    elseif kind == "EMPTY" then
        return ("Empty %s"):format(action.resource)
    elseif kind == "TOGGLE" then
        return ("%s: %s"):format(R.TOGGLE_MODES[action.mode] or "Flip", action.passive)
    elseif kind == "SLOTS" then
        return ns.SLOT_ACTION_TEXT[action.mode] or "Spell slots"
    elseif kind == "NEXTROLL" then
        return ("Next roll: %s"):format(action.mode == "DIS" and "disadvantage" or "advantage")
    end
    return "?"
end
