-- "Defense" tab: protection another character's spell puts on you. One dropdown lists
-- every protective spell that can be cast on someone else (Data/SpellWards.lua,
-- Data/SpellWardRolls.lua) with each of its options, and a button puts the chosen one
-- on the sheet as a passive, the same one a casting of your own would make. You click
-- it off when the spell ends; a rest that outlasts the spell ends it too.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Sheet = Opt.Sheet

-- Every option someone else can cast on you: { key, spell, index, label }, by name.
-- Left out: spells that are always on their caster, and the caster's side of a bond.
local choices, byKey, order = {}, {}, {}
for spell, ward in pairs(R.SPELL_WARDS) do
    for index, option in ipairs(ward) do
        if not ward.own and (not ward.cast or ward.cast ~= index) then
            local key = R.WardKey(spell, index)
            local label = (option.label and not option.byHand) and ("%s (%s)"):format(spell, option.label) or spell
            choices[#choices + 1] = { key = key, spell = spell, index = index, label = label, option = option }
        end
    end
end
table.sort(choices, function(a, b)
    if a.spell ~= b.spell then return a.spell < b.spell end
    return a.index < b.index
end)
for _, choice in ipairs(choices) do
    byKey[choice.key], order[#order + 1] = choice, choice.key
end

local picked = "" -- the key chosen in the dropdown

local function Find(key)
    for at, passive in ipairs(Sheet().passives) do
        if passive.auto == key then return at end
    end
end

local args = Opt.custom.defense.args
args.wardHeader = { type = "header", order = 41, name = "A spell someone else cast on you" }
args.wardPick = {
    type = "select", order = 42, width = "double", name = "Protective spell",
    desc = "The spells that protect the one they are cast on, with the choice their caster makes. Pick the one that is on you.",
    values = function()
        local values = {}
        for _, choice in ipairs(choices) do values[choice.key] = choice.label end
        return values
    end,
    sorting = order,
    get = function() return picked end,
    set = function(_, value) picked = value end,
}
args.wardAdd = {
    type = "execute", order = 43, name = "Add it to my sheet",
    desc = "Puts the spell's protection on the sheet as a passive that is on. Click the passive off when the spell ends.",
    disabled = function() return not byKey[picked] end,
    func = function()
        local choice = byKey[picked]
        RPSheet:StartWard(choice.spell, choice.index, true)
        ns.RebuildOptions() -- the Passives tab has a page more
        Opt.Changed()
    end,
}
args.wardRemove = {
    type = "execute", order = 44, name = "Take it off",
    desc = "Removes the spell's passive from the sheet.",
    disabled = function() return not (byKey[picked] and Find(picked)) end,
    func = function()
        local at = Find(picked)
        if at then table.remove(Sheet().passives, at) end
        ns.RebuildOptions()
        Opt.Changed()
    end,
}
args.wardNote = {
    type = "description", order = 45,
    name = function()
        local choice = byKey[picked]
        if not choice then return "" end
        return ("%s: %s.%s\n"):format(choice.label, ns.WardText(choice.option),
            Find(picked) and (" " .. Opt.GREEN .. "It is on your sheet.|r") or "")
    end,
}
