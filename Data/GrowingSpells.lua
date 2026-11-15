-- Spells whose die grows while they last: the target saves again each turn, takes the
-- damage either way, and every failed save makes the die one size larger.
-- R.GROWING_SPELLS[<spell name>] = the die sizes in order, starting with the spell's own.
local _, ns = ...
local R = ns.Rules

R.GROWING_SPELLS = {
    ["Curse of Agony"] = { 4, 6, 8, 10, 12 },
}
