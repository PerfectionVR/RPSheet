-- Wizard step 5: starting money, what to carry over, and the closet of starting gear.
local _, ns = ...
local R = ns.Rules
local W = ns.Wizard
local Field, Page, DraftClass = W.DraftField, W.Page, W.DraftClass

local detailsArgs = {
    help = {
        type = "description", order = 1, fontSize = "medium",
        name = "Hit points, Armor Class, proficiency bonus, saving throws, spell slots and class resources are worked out for you. Weapons of your own, abilities and passives can be added in the editor afterwards.\n",
    },
    goldHeader = { type = "header", order = 14, name = "Starting money" },
    gold = Field({
        type = "range", order = 15, min = 0, max = 1000, softMax = 250, step = 1, name = "Gold pieces",
        desc = function()
            local class = DraftClass()
            return ("Your class and your background each offer a set of starting gear with a little gold left over, or gold alone to buy your own: %d gp from your class and %d gp from your background. Enter the gold you start with, next to what you took from the closet. More gear is bought under Customize > Inventory afterwards."):format(
                class and R.START_GOLD[class.base] or 0, R.BACKGROUND_GOLD)
        end,
    }, "gold"),
    goldAll = {
        type = "execute", order = 16, name = "Full starting gold",
        desc = "Sets the gold to what your class and background give when you take no starting gear from either. What you take from the closet isn't paid for from it.",
        func = function()
            local class = DraftClass()
            W.draft.gold = (class and R.START_GOLD[class.base] or 0) + R.BACKGROUND_GOLD
        end,
    },
    keepLists = Field({
        type = "toggle", order = 20, width = "full",
        name = "Carry over the weapons, spells, resources, abilities, passives, items and coins I made or gathered myself",
        desc = "Off: the new character starts clean. On: entries you added by hand on the current character are kept. What its class, species, background and levels gave is never carried over.",
        hidden = function() return not W.draft.hasContent end,
    }, "keepLists"),
}
W.AddClosetArgs(detailsArgs)
local detailsPage = Page(5, detailsArgs)

W.pages[5] = detailsPage
