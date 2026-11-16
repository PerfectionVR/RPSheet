-- Death Ward as a protective spell (form of the entries: see Data/SpellWards.lua). Cast
-- on yourself from the sheet, or put there under Customize, Defense when someone else
-- cast it, it is a passive that "Take damage" reads: the first time the damage would
-- drop you to 0 hit points you keep 1 instead, and the passive goes (Actions/DamageZero.lua).
local _, ns = ...
local R = ns.Rules

R.SPELL_WARDS["Death Ward"] = { hours = 8,
    { deathWard = true,
      text = "the first time damage would drop you to 0 hit points you drop to 1 instead, and the spell ends",
      desc = "On while Death Ward protects you: the first time damage would drop you to 0 hit points, \"Take damage\" leaves you at 1 and ends the spell. An effect that would kill you outright without damage fails instead: click this off then. A rest doesn't end it unless it is as long as the spell (8 hours); click it off when the spell ends." },
}
