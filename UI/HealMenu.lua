-- The "Heal" row's menu: an amount to type, the character's own last healing roll, or
-- a healing spell someone else cast (its spell, then its slot, then the caster's
-- modifier when the spell adds it). The rules are in Actions/HealReceived.lua.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The slots a spell can be cast with, then the roll.
function RPSheet:OpenHealSlotMenu(owner, name)
    local spell = R.SPELLS[name]
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle(name .. ": cast with which slot?")
        for level = spell.level, 9 do
            local count, sides, flat = self:HealingAt(name, level)
            local dice = ("%dd%d"):format(count, sides)
            if flat > 0 then dice = ("%s + %d"):format(dice, flat) end
            if spell.addMod then dice = dice .. " + their modifier" end
            root:CreateButton(("%s slot: %s"):format(R.SPELL_LEVELS[level], dice), function()
                if not spell.addMod then return self:HealFromSpell(name, level, 0) end
                self:AskAmount({ prompt = ("%s adds the caster's spellcasting modifier. What is it? (for example 3)"):format(name),
                    run = function(text) self:HealFromSpell(name, level, tonumber((text or ""):match("%-?%d+")) or 0) end })
            end)
        end
    end)
end

function RPSheet:OpenHealSpellMenu(owner)
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Which healing spell was cast on you?")
        for _, name in ipairs(self:HealingSpells()) do
            local spell = R.SPELLS[name]
            root:CreateButton(("%s (%s)"):format(name, R.SPELL_LEVELS[spell.level]), function() self:OpenHealSlotMenu(owner, name) end)
        end
    end)
end

function RPSheet:OpenHealMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return self:AskAmount({ heal = true }) end
    local last = self:LastHealing()
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Regain hit points from what?")
        root:CreateButton("Type the amount", function() self:AskAmount({ heal = true }) end)
        if last then
            local button = root:CreateButton(("Your own %s on yourself: %d"):format(last.from or "healing roll", last.amount), function() self:HealFromLastRoll() end)
            button:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, last.from or "Healing")
                GameTooltip_AddNormalLine(tooltip, "The healing you rolled last, for when you cast it on yourself. It can be used once.", true)
            end)
        end
        root:CreateButton("A healing spell someone else cast", function() self:OpenHealSpellMenu(owner) end)
    end)
end
