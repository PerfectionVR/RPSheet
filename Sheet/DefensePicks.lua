-- Resistances that need a word from the player (data in Data/SpellWards.lua):
--   * a passive whose damage types are chosen each time it starts (Heavenly Spirit):
--     switching it on asks which, and sheet.defensePicks[<passive>] keeps the answer;
--   * a feat's resistance that holds only in a situation (Boon of the Night Spirit):
--     a passive of its own, marked auto = "defense:<name>", off until switched on.
-- Sheet/Defenses.lua counts both while their passive is on.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local PREFIX = "defense:"

-- The damage types picked for a passive, as far as its list allows them. The menu on
-- the sheet keeps to the count; the page under Customize only warns.
function ns.DefensePicks(sheet, name)
    local rule, picked = R.DEFENSE_PICKS[name], {}
    local saved = rule and type(sheet.defensePicks) == "table" and sheet.defensePicks[name]
    if type(saved) ~= "table" then return picked end
    for _, allowed in ipairs(rule.from) do
        for _, each in ipairs(saved) do
            if each == allowed then
                picked[#picked + 1] = allowed
                break
            end
        end
    end
    return picked
end

-- Every way to choose `count` of the types, each as a list.
local function Combinations(from, count, start, chosen, found)
    if #chosen == count then
        found[#found + 1] = { unpack(chosen) }
        return found
    end
    for index = start, #from do
        chosen[#chosen + 1] = from[index]
        Combinations(from, count, index + 1, chosen, found)
        chosen[#chosen] = nil
    end
    return found
end

-- A menu at the cursor with the choices for a passive that has just been switched on.
function RPSheet:AskDefensePicks(name)
    local rule = R.DEFENSE_PICKS[name]
    if not rule then return end
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        self:Print(("Choose the damage types of %s under Customize, Defense."):format(name))
        return
    end
    local sheet = self:Sheet()
    if type(sheet.defensePicks) ~= "table" then sheet.defensePicks = {} end
    MenuUtil.CreateContextMenu(UIParent, function(_, root)
        root:CreateTitle(name .. ": resist which damage?")
        for _, list in ipairs(Combinations(rule.from, rule.count, 1, {}, {})) do
            root:CreateButton(table.concat(list, " and "), function()
                sheet.defensePicks[name] = list
                self:PopulateSoon()
            end)
        end
    end)
end

-- Switching such a passive on asks for its damage types; anything else a passive does
-- when it starts (Sheet/Metamorphosis.lua) stays as it was.
local PassiveSwitchedOn = RPSheet.PassiveSwitchedOn
function RPSheet:PassiveSwitchedOn(passive)
    PassiveSwitchedOn(self, passive)
    if R.DEFENSE_PICKS[passive.name] then self:AskDefensePicks(passive.name) end
end

-- Sheet upkeep, called from ns.ApplyWards: the situation passive of each feat the
-- character has, and none for a feat it hasn't. One deleted in the editor stays away.
function ns.ApplyDefenseSwitches(sheet)
    local has, wanted = {}, {}
    for _, passive in ipairs(sheet.passives) do has[passive.name] = true end
    for _, switch in ipairs(R.DEFENSE_SWITCHES) do
        local key = PREFIX .. switch.name
        if has[switch.feat] and not (sheet.dismissed or {})[key] then
            wanted[key] = true
            local entry
            for _, passive in ipairs(sheet.passives) do
                if passive.auto == key then entry = passive end
            end
            if not entry then
                entry = { auto = key, enabled = false, effects = {} }
                sheet.passives[#sheet.passives + 1] = entry
            end
            entry.name = switch.name
            entry.desc = ("%s. %s"):format(switch.feat, switch.desc)
            entry.resist = CopyTable(switch.resist)
        end
    end
    for at = #sheet.passives, 1, -1 do
        local auto = sheet.passives[at].auto or ""
        if auto:find("^" .. PREFIX) and not wanted[auto] then table.remove(sheet.passives, at) end
    end
end
