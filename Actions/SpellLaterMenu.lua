-- The right-click menu of a spell with later rolls (Data/SpellLater.lua): each roll,
-- a ritual casting when the spell is one, casting it again and ending it. Also the
-- lines its tooltip gets and the words its row shows while it runs.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Ends the running spell and casts it anew, spending a slot as usual.
local function Recast(self, spell, mode)
    self:State().spellLater[spell.name] = nil
    self:CastSpell(spell, mode)
end

function RPSheet:SpellLaterMenu(spell, mode)
    local running = self:SpellLaterRunning(spell)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        -- No menu: the first roll, or the ritual for a ritual spell.
        if spell.ritual and not running then return self:CastSpell(spell, mode, true, false) end
        return self:RollSpellLater(spell, nil, mode)
    end
    MenuUtil.CreateContextMenu(UIParent, function(_, root)
        root:CreateTitle(spell.name .. (running and ": running" or ""))
        for _, index in ipairs(self:SpellLaterRolls(spell)) do
            local roll = R.SPELL_LATER[spell.name].rolls[index]
            local text = self:SpellLaterText(spell, index)
            if roll.levels then
                -- Once per level of the spell cast: pick the level.
                for level = 1, 9 do
                    root:CreateButton(("%s (%s level)"):format(roll.label, R.ORDINALS[level]),
                        function() self:RollSpellLater(spell, index, mode, level) end)
                end
            else
                local button = root:CreateButton(roll.label:sub(1, 1):upper() .. roll.label:sub(2), function() self:RollSpellLater(spell, index, mode) end)
                button:SetTooltip(function(tooltip)
                    GameTooltip_SetTitle(tooltip, spell.name)
                    GameTooltip_AddNormalLine(tooltip, text, true)
                end)
            end
        end
        -- (false: the casting goes on past this menu, see RPSheet:CastSpell)
        if spell.ritual then root:CreateButton("Cast it as a ritual", function() self:CastSpell(spell, mode, true, false) end) end
        if running then
            root:CreateButton("Cast it again (this casting ends)", function() Recast(self, spell, mode) end)
            root:CreateButton("End it", function() self:EndSpellLater(spell) end)
        else
            root:CreateButton("Cast it", function() self:CastSpell(spell, mode) end)
        end
    end)
end

-- What the row shows after the spell's usual words while it runs.
function RPSheet:SpellLaterRowNote(spell)
    if not self:SpellLaterRunning(spell) then return end
    local run = self:SpellLaterRun(spell)
    return ("running (%s slot)"):format(R.ORDINALS[run.slot] or run.slot)
end

-- The tooltip's lines about the later rolls.
function RPSheet:SpellLaterHelp(spell)
    local lines = {}
    local later = R.SPELL_LATER[spell.name]
    if not later then return lines end
    for _, index in ipairs(self:SpellLaterRolls(spell)) do lines[#lines + 1] = "Later: " .. self:SpellLaterText(spell, index) .. "." end
    if self:SpellLaterRunning(spell) then
        lines[#lines + 1] = "It is running. Left-click: the first roll above, without a slot. Right-click: every roll, casting it again, or ending it. It ends with a rest that outlasts it"
            .. (self:SpellLaterRun(spell).conc and ", or when your concentration does." or ".")
    elseif later.hours then
        lines[#lines + 1] = "After casting, left-click it for the first roll above, without a slot; right-click offers every roll and ends it."
    else
        lines[#lines + 1] = "Right-click: the rolls above, without a slot, with the slot of your last casting."
    end
    if later.quiet then lines[#lines + 1] = "Casting it rolls no dice: they come later." end
    return lines
end
