-- Shapes a character can take that replace some of its numbers while they last: a
-- Circle of the Moon druid's Cat Form and Bear Form. A form is in effect while the
-- passive of that name is switched on (see Sheet/Forms.lua).
--
-- R.FORMS[<passive name>] = {
--     ac      Armor Class before the ability modifier
--     acStat  ability whose modifier is added to it
--     speed   walking speed in feet
--     scores  { STR = "WIS", ... }: abilities that take another ability's score,
--             or { STR = 16, ... }: a beast's own score (hit points never follow it)
--     darkvision  feet; senses = { Blindsight = 10, ... } for a beast's own senses
--     skills  skills the form is proficient in
-- }
local _, ns = ...
local R = ns.Rules

R.FORMS = {
    ["Cat Form active"] = {
        name = "Cat Form", ac = 13, acStat = "WIS", speed = 40, darkvision = 60,
        scores = { STR = "WIS", DEX = "WIS" }, skills = { "Stealth" },
    },
    ["Bear Form active"] = {
        name = "Bear Form", ac = 15, acStat = "WIS", speed = 30, darkvision = 60,
        scores = { STR = "WIS", DEX = "WIS" }, skills = {},
    },
}
R.FORM_ORDER = { "Cat Form active", "Bear Form active" }
