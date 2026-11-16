-- Spells that shape-shift you as Wild Shape does, without spending a use: Feral Prowl
-- and Roar of Ursoc. Once the casting is announced the sheet asks which of your forms
-- (a beast you know, or a Circle of the Moon's Cat or Bear Form) and switches it on,
-- with Wild Shape's temporary hit points. Hooked into Actions/SpellAfterCast.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The passives of the forms the character can take, by name.
local function Forms(self)
    local list = {}
    for _, passive in ipairs(self:Sheet().passives) do
        if (passive.auto or ""):find("^form:.+:on$") or R.FORMS[passive.name] then list[#list + 1] = passive end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- Wild Shape's temporary hit points: the druid's level, three times it in the Circle
-- of the Moon.
local function TempHP(self)
    local view = ns.ListView(self:Sheet(), "forms") or self:Sheet()
    return (view.level or self:Level()) * (view.subclass == "Circle of the Moon" and 3 or 1)
end

local function TakeForm(self, spell, passive)
    for _, other in ipairs(Forms(self)) do other.enabled = false end
    passive.enabled = true
    local state, amount = self:State(), TempHP(self)
    state.tempHP = math.max(state.tempHP or 0, amount)
    local text = ("%s - takes %s, with %d temporary hit points"):format(ns.Mark(spell.name), passive.name, amount)
    if spell.name == "Feral Prowl" and not state.conditions.Invisible then
        state.conditions.Invisible = true
        text = text .. (" and %s until it attacks, deals damage or casts a spell"):format(ns.Mark("Invisible"))
    end
    self:Announce(text)
    self:Refresh()
end

-- The follow-up of the casting: the question, or a line when there is no form to take.
local function Shift(self, spell)
    return nil, function()
        local forms = Forms(self)
        if #forms == 0 then
            return self:Print(("%s: you know no beast form to take. Choose your forms when you level, or switch a form of your own on under Customize, Passives."):format(spell.name))
        end
        if not (MenuUtil and MenuUtil.CreateContextMenu) then return TakeForm(self, spell, forms[1]) end
        MenuUtil.CreateContextMenu(UIParent, function(_, root)
            root:CreateTitle(spell.name .. ": which form?")
            for _, passive in ipairs(forms) do
                root:CreateButton(passive.name, function() TakeForm(self, spell, passive) end)
            end
        end)
    end
end

R.SPELLS_AFTER_CAST["Feral Prowl"] = Shift
R.SPELLS_AFTER_CAST["Roar of Ursoc"] = Shift
