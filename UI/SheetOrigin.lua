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
            -- What stands after the score. Below Friendly there is no tier to name, so
            -- the words are joined only where there are two.
            local notes = {}
            if R.RenownTier(score) ~= "" then notes[#notes + 1] = R.RenownTier(score) end
            if #added > 0 then notes[#notes + 1] = "partly by rule" end
            local tier = table.concat(notes, ", ")
            if ns.RenownRival(self:Sheet(), faction) then tier = (tier ~= "" and tier .. " " or "") .. "|cffff5555(rival)" end
            -- The perks of every tier reached and the next one (Sheet/RenownSummary.lua).
            -- (put together when the row is hovered)
            renown[#renown + 1] = {
                text = ("%s %s%d%s|r"):format(faction, UI.GREY, score, tier ~= "" and (" " .. tier) or ""),
                tip = function()
                    return "Standing with a faction. Friendly at 3, Honored at 10, Revered at 25, Exalted at 50.\n\n"
                        .. ns.RenownSummary(self:Sheet(), faction, UI.ACCENT)
                end,
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
