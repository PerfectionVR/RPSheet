-- What a Death Knight's rune does with Runic Power and Runic Mastery (Oath of the Ebon
-- Blade, Data/ClassOverrides.lua): the steps of each, by rune. While Aspect of the
-- Horsemen is on, either can use any rune's effect (Actions/RuneFlows.lua).
local _, ns = ...
local Kit = ns.FeatureKit

ns.RUNES = { "Blood", "Frost", "Unholy" }

-- The steps after the Channel Divinity use Runic Power spends. Blood heals by the
-- necrotic damage the Rune Strike dealt: `healed`, which the sheet asks for.
function ns.RunicPowerSteps(rune, healed)
    if rune == "Blood" then return healed and { Kit.Dice(0, 4, "", "SELFHEAL", healed) } or {} end
    if rune == "Frost" then return { Kit.Dice(2, 6) } end
    if rune == "Unholy" then return { Kit.Dice(1, 6, "", "OTHER") } end
    return {}
end

-- The steps of Runic Mastery for a rune, at a Death Knight level: Blood reduces the
-- damage by the level and costs as many hit points.
function ns.RunicMasterySteps(rune, level)
    if rune == "Blood" then return { Kit.Dice(0, 4, "", "OTHER", level), { type = "LOSEHP", amount = level } } end
    if rune == "Frost" then return { Kit.Dice(8, 6) } end
    if rune == "Unholy" then return { Kit.Dice(0, 4, "", "DAMAGE", math.ceil(level / 2)) } end
    return {}
end
