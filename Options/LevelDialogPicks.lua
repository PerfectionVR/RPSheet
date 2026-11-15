-- The level dialog: the pick lists (Data/Picks.lua): Metamagic, Invocations, prepared
-- spells, the spells a feature lets the character choose.
local _, ns = ...
local R = ns.Rules
local L = ns.LevelDialog
local args = L.args

-- A group of checkboxes per pick list. An option greys out at the limit, below its
-- level, or without the pick it builds on.
for listIndex, key in ipairs(R.PICK_LIST_ORDER) do
    local list = R.PICK_LISTS[key]
    local group = {
        type = "group", inline = true, order = 12.5 + listIndex / 10, args = {},
        name = function()
            local swaps = L.draft and ns.PickSwapNote(key, L.draft.before, L.draft.picks, L.Picking()) or ""
            return ("%s (%d of %d chosen%s)"):format(list.title, L.draft and L.PicksChosen(key) or 0, L.PickLimit(key), swaps)
        end,
        hidden = function() return L.PickLimit(key) == 0 end,
    }
    -- A long list leaves out what the character can't pick yet.
    local function Hidden(name)
        return list.hideBlocked == true and L.draft ~= nil and not L.draft.picks[key][name]
            and L.Blocked(key, name) ~= nil
    end
    local section
    for index, name in ipairs(list.order) do
        -- Items that carry a group get a heading where a new group starts.
        local itemGroup = list.items[name].group
        if itemGroup and itemGroup ~= section then
            section = itemGroup
            group.args["head" .. index] = {
                type = "header", order = index - 0.5, name = itemGroup,
                hidden = function()
                    for _, other in ipairs(list.order) do
                        if list.items[other].group == itemGroup and not Hidden(other) then return false end
                    end
                    return true
                end,
            }
        end
        group.args["pick" .. index] = {
            type = "toggle", order = index, width = 1.5,
            name = function()
                local blocked = L.draft and not L.draft.picks[key][name] and L.Blocked(key, name)
                -- A spell shows its level behind the name.
                local tag = list.items[name].tag
                local shown = tag and ("%s |cff888888(%s)|r"):format(name, tag) or name
                return blocked and ("|cff888888%s (%s)|r"):format(name, blocked) or shown
            end,
            hidden = function() return Hidden(name) end,
            desc = list.items[name].desc,
            disabled = function()
                if L.draft.picks[key][name] then return L.SwapLocked(key, name) end
                return L.PicksChosen(key) >= L.PickLimit(key) or L.Blocked(key, name) ~= nil
            end,
            get = function() return L.draft.picks[key][name] or false end,
            set = function(_, value)
                local picked = L.draft.picks[key]
                picked[name] = value or nil
                -- Dropping a pick drops the ones that build on it.
                local dropped = not value
                while dropped do
                    dropped = false
                    for other in pairs(picked) do
                        local needs = list.items[other] and list.items[other].needs
                        if needs and not picked[needs] then
                            picked[other] = nil
                            dropped = true
                            break
                        end
                    end
                end
                if not value then L.DropUnfollowed() end
            end,
        }
    end
    args["picks" .. key] = group
end
