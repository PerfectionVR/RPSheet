-- The one question about a saving throw that the sheet rolls by itself: the save to
-- keep a spell after taking damage, for a character with an advantage that only
-- counts for some spells (one that was extended). What any other saving throw is
-- against is asked in Actions/RollQuestions.lua.
local _, ns = ...
local RPSheet = ns.addon

-- Opens the menu for the save to keep concentrating and returns true; false when
-- there is nothing to ask, and the save is rolled as it is (RPSheet:RollConcentration).
function RPSheet:AskConcentration(damage)
    local choices = self:ConcentrationChoices()
    if #choices == 0 then return false end
    -- Advantage that is there anyway, or that something would cancel out: nothing to ask.
    local plain = self:ResolveMode("CON save", self:ConcentrationAdvantage() and "ADV" or nil)
    if plain == self:ResolveMode("CON save", "ADV") then return false end
    -- Not asked (no menu, or the question stopped for this character): rolled without it.
    if not (MenuUtil and MenuUtil.CreateContextMenu) or self:RollQuiet("holding") then
        self:Print(("The save to keep your spell was rolled without advantage: you have it for %s (%s)."):format(choices[1].about, choices[1].from))
        return false
    end
    MenuUtil.CreateContextMenu(UIParent, function(_, root)
        root:CreateTitle(("Took %d damage: which spell are you holding?"):format(damage))
        for _, choice in ipairs(choices) do
            local text = choice.about:sub(1, 1):upper() .. choice.about:sub(2)
            local button = root:CreateButton(("%s |cff909090(advantage)|r"):format(text), function() self:RollConcentration(damage, true) end)
            button:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, "Advantage")
                GameTooltip_AddNormalLine(tooltip, ("From %s, on the save to keep that spell."):format(choice.from), true)
            end)
        end
        root:CreateButton("Another spell", function() self:RollConcentration(damage, false) end)
        root:CreateDivider()
        root:CreateButton("Don't ask again for this character", function()
            self:SetRollQuiet("holding", true)
            self:Print("The sheet won't ask this again for this character. Customize > Proficiencies turns the question back on.")
            self:Print(("The save to keep your spell was rolled without advantage: you have it for %s (%s)."):format(choices[1].about, choices[1].from))
            self:RollConcentration(damage, false)
        end)
    end)
    return true
end
