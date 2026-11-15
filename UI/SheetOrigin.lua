-- The sheet's languages and renown, when the character has any.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI

-- Languages and renown, when the character has any.
function UI.OriginSection(self, body)
    local languages = self:Languages()
    local renown = {}
    for _, faction in ipairs(R.ALL_FACTIONS) do
        -- The score with what the rules add to it (Sheet/RenownRules.lua).
        local score, added = ns.RenownScore(self:Sheet(), faction)
        if score > 0 then
            local tier = R.RenownTier(score)
            if #added > 0 then tier = tier .. ", partly by rule" end
            if ns.RenownRival(self:Sheet(), faction) then tier = tier .. " |cffff5555(rival)" end
            -- The perks of every tier reached and the next one (Sheet/RenownSummary.lua).
            renown[#renown + 1] = {
                text = ("%s %s%d%s|r"):format(faction, UI.GREY, score, tier ~= "" and (" " .. tier) or ""),
                tip = "Standing with a faction. Friendly at 3, Honored at 10, Revered at 25, Exalted at 50.\n\n"
                    .. ns.RenownSummary(self:Sheet(), faction, UI.ACCENT),
            }
        end
    end
    if #languages == 0 and #renown == 0 then return end

    UI.AddHeading(body, "Languages and renown")
    if #languages > 0 then
        UI.AddLabel(body, 1, table.concat(languages, ", "))
    end
    for _, line in ipairs(renown) do
        UI.AddLabel(body, 0.5, line.text, nil, "Renown", line.tip)
    end
end
