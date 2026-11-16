-- What a casting does besides its own roll, once it has gone off (called from the end
-- of RPSheet:CastSpell, Actions/Spells.lua): a spell rolled again later starts running
-- (Actions/SpellLater.lua), and a few spells change the sheet or roll something of
-- the caster's own after the casting is announced.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local RollText = ns.RollText

-- The tracker of that label, or nil.
local function Tracker(self, label)
    for _, tracker in ipairs(self:GetTrackers()) do
        if tracker.label == label then return tracker end
    end
end

-- Innervate: you regain a use of Wild Shape; a level 4 slot goes to whoever you choose.
local function Innervate(self)
    local wild = Tracker(self, "Wild Shape")
    local note
    if wild and wild.get() < wild.max then
        wild.set(wild.get() + 1)
        note = "you regain a use of Wild Shape"
    end
    return note, function()
        if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
        MenuUtil.CreateContextMenu(UIParent, function(_, root)
            root:CreateTitle("Innervate: who gains the level 4 slot?")
            root:CreateButton("Yourself", function()
                local slots = self:State().slots
                slots[4] = (type(slots[4]) == "number" and slots[4] or 0) + 1
                self:Announce(("%s - gains a 4th-level slot until it is spent or a long rest"):format(ns.Mark("Innervate")))
                self:Refresh()
            end)
            root:CreateButton("Someone else", function() end)
        end)
    end
end

-- Contact Other Plane: your own Intelligence save against DC 15; on a failure you take
-- the psychic damage and are incapacitated until a long rest.
local function ContactOtherPlane(self, spell)
    return nil, function()
        local mod = self:SaveMod("INT")
        local mode = self:ResolveMode("INT save")
        self:RollTest(mode, function(d20, note, extra)
            local total = d20 + mod + (extra and extra.value or 0)
            local text = RollText.Check(ns.Mark("INT save") .. " against DC 15", d20, mod, note, extra)
            if total >= 15 then
                return self:Announce(("%s - %s: the entity answers up to five questions"):format(ns.Mark(spell.name), text))
            end
            self:RollDice(spell.count, spell.sides, function(rolls)
                local damage = 0
                for _, value in ipairs(rolls) do damage = damage + value end
                self:Announce(("%s - %s: failed, %s, and incapacitated until a long rest"):format(ns.Mark(spell.name), text,
                    RollText.Dice("psychic damage to you", rolls, spell.sides, 0)))
                self:TakeDamage(damage, "psychic")
                if not self:State().conditions.Incapacitated then self:ToggleCondition("Incapacitated") end
            end)
        end)
    end
end

local SELF_SAVE -- (below)
local AFTER = {
    ["True Strike"] = function(self, spell) return self:ReadyTrueStrike(spell) end,
    ["Innervate"] = Innervate,
    ["Contact Other Plane"] = ContactOtherPlane,
}
R.SPELLS_AFTER_CAST = AFTER

-- Returns words for the casting's announcement, or nil, and a function to call once
-- it is announced, or nil.
function RPSheet:AfterSpellCast(spell, level, dealt, noConcentration)
    local later = self:StartSpellLater(spell, level, dealt, noConcentration)
    -- (a spell the player changed under Customize keeps to what they made of it)
    local hook = not (spell.edited and SELF_SAVE[spell.name]) and AFTER[spell.name]
    if not hook then return later end
    local note, followUp = hook(self, spell, level)
    if later and note then note = later .. ", " .. note end
    return note or later, followUp
end

-- Contact Other Plane's save is the caster's own: casting it rolls nothing of the
-- usual kind (no save against your DC, no damage dealt), and its row says so.
SELF_SAVE = { ["Contact Other Plane"] = "your own INT save against DC 15, %dd%d psychic damage to you on a failure" }

local Quiet = RPSheet.SpellLaterQuiet
function RPSheet:SpellLaterQuiet(spell)
    return (SELF_SAVE[spell.name] ~= nil and not spell.edited) or Quiet(self, spell)
end

local SpellText = RPSheet.SpellText
function RPSheet:SpellText(spell)
    local words = SELF_SAVE[spell.name]
    if not words or spell.edited then return SpellText(self, spell) end
    return words:format(spell.count, spell.sides)
end

local CastSpell = RPSheet.CastSpell
function RPSheet:CastSpell(spell, mode, ritual, benefit, answers)
    if SELF_SAVE[spell.name] and spell.kind == "SAVE" and not spell.edited then
        local copy = CopyTable(spell)
        copy.kind = "NONE"
        return CastSpell(self, copy, mode, ritual, benefit, answers)
    end
    return CastSpell(self, spell, mode, ritual, benefit, answers)
end
