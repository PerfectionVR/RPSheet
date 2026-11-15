-- "Defense" tab: protection another character's spell puts on you (Warding Bond; the
-- options marked byHand in Data/SpellWardRolls.lua). A tick puts its passive on the
-- sheet, where it is switched on and off like any other; a rest switches it off.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet = Opt.Sheet

local function Find(key)
    for at, passive in ipairs(Sheet().passives) do
        if passive.auto == key then return at end
    end
end

local spells = {}
for spell in pairs(R.SPELL_WARDS) do spells[#spells + 1] = spell end
table.sort(spells)

local order = 40
for _, spell in ipairs(spells) do
    for index, option in ipairs(R.SPELL_WARDS[spell]) do
        if option.byHand then
            order = order + 1
            local key = R.WardKey(spell, index)
            Opt.custom.defense.args["ward" .. order] = {
                type = "toggle", order = order, width = "full", name = ("%s is on you (cast by someone else)"):format(spell),
                desc = ("Tick when another character's %s guards you: %s. It becomes a passive on the sheet that you switch off when the spell ends and on when it is cast again."):format(
                    spell, ns.WardText(option)),
                get = function() return Find(key) ~= nil end,
                set = function(_, value)
                    local at = Find(key)
                    if value then
                        RPSheet:StartWard(spell, index)
                    elseif at then
                        table.remove(Sheet().passives, at)
                    end
                    ns.RebuildOptions() -- the Passives tab has a page more or less
                    Opt.Changed()
                end,
            }
        end
    end
end
