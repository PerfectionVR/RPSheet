-- What a taken set of starting gear leaves to choose (a holy symbol, an instrument, a
-- kind of artisan's tools, a gaming set): one dropdown per choice on the wizard's last
-- page. The thing chosen goes into the closet with the rest of the set, is swapped when
-- the choice changes and goes back with the set (Wizard/StartingGear.lua keeps it in
-- draft.gear[half].picks). Where the rules make it the tool the class or background
-- trains the character in, the new character is proficient with it too.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard

local HALVES = { "class", "background" }
local MOST = 2 -- choices one set can have; the sets as they are have one at most

-- Choice `index` of a half's taken set and that set's record, or nil.
local function Choice(half, index)
    local record, set = W.GearTaken(half)
    local choice = record and set.choices and set.choices[index]
    if choice then return choice, record end
end

-- "a holy symbol and a gaming set" for what a set leaves to choose; nil when nothing.
function W.GearChoiceText(set)
    local parts = {}
    for _, choice in ipairs(set.choices or {}) do
        parts[#parts + 1] = R.GEAR_CHOICES[choice.kind].name:lower()
    end
    if #parts > 0 then return table.concat(parts, " and ") end
end

-- A line for the note under the buttons while a taken set still has something to choose.
function W.GearOpenNote()
    local open = {}
    for _, half in ipairs(HALVES) do
        for index = 1, MOST do
            local choice, record = Choice(half, index)
            if choice and not (record.picks and record.picks[index]) then
                open[#open + 1] = R.GEAR_CHOICES[choice.kind].name:lower()
            end
        end
    end
    if #open == 0 then return "" end
    return ("\n%sStill to choose below:|r %s."):format(Opt.GOLD, table.concat(open, ", "))
end

-- Makes the choice: the old pick goes back, the new one comes into the closet.
function W.PickGear(half, index, name)
    local choice, record = Choice(half, index)
    if not choice then return end
    record.picks = record.picks or {}
    if record.picks[index] then W.TakeItem(record.picks[index], -1) end
    record.picks[index] = R.ITEMS[name] and name or nil
    if record.picks[index] then W.TakeItem(name, 1) end
    W.ClosetChanged()
end

-- The new character is proficient with a chosen tool where the choice stands for the
-- tool its class or background trains it in.
function W.GrantGearTools(sheet)
    for _, half in ipairs(HALVES) do
        for index = 1, MOST do
            local choice, record = Choice(half, index)
            local name = choice and choice.trained and record.picks and record.picks[index]
            if name and R.TOOLS[name] then sheet.tools[name] = true end
        end
    end
end

local function Picker(half, index, order)
    local function Names()
        local choice = W.draft and Choice(half, index)
        return choice and R.GearChoiceNames(choice.kind) or {}
    end
    return {
        type = "select", order = order, width = 1.5,
        name = function()
            local choice = W.draft and Choice(half, index)
            return choice and ("%s (from your %s)"):format(R.GEAR_CHOICES[choice.kind].name, half) or ""
        end,
        desc = function()
            local choice = W.draft and Choice(half, index)
            if not choice then return "" end
            local text = "Part of the set you took: the one you choose goes into the closet with the rest, and goes back with it."
            if choice.trained then
                text = text .. "\n\nIt is also the tool your " .. half .. " trains you in: your character will be proficient with it."
            end
            return text
        end,
        hidden = function() return not W.draft or Choice(half, index) == nil end,
        values = function()
            local values = { [""] = "Not chosen yet" }
            for _, name in ipairs(Names()) do
                local summary = R.ItemSummary(R.ITEMS[name].cost, R.ITEMS[name].weight)
                values[name] = summary ~= "" and ("%s (%s)"):format(name, summary) or name
            end
            return values
        end,
        sorting = function()
            local order = Names()
            table.insert(order, 1, "")
            return order
        end,
        get = function()
            local _, record = Choice(half, index)
            return record and record.picks and record.picks[index] or ""
        end,
        set = function(_, value) W.PickGear(half, index, value) end,
    }
end

-- Adds the dropdowns to the options of the wizard's last page, under the set buttons.
function W.AddGearChoiceArgs(args)
    for place, half in ipairs(HALVES) do
        for index = 1, MOST do
            args["gearChoice" .. half .. index] = Picker(half, index, 2.16 + place * 0.01 + index * 0.001)
        end
    end
end
