-- Wizard step 4: alignment and allegiance.
local _, ns = ...
local R = ns.Rules
local Opt = ns.Opt
local W = ns.Wizard
local Field, Page = W.DraftField, W.Page

local alignmentPage = Page(4, {
    help = {
        type = "description", order = 1, fontSize = "medium",
        name = "Alignment is a short description of your character's moral outlook. The peoples of the Alliance lean Lawful Good and those of the Horde Chaotic Good, but the choice is yours.\n",
    },
    alignment = Field({
        type = "select", order = 2, name = "Alignment",
        values = Opt.ALIGNMENT_VALUES, sorting = Opt.ALIGNMENT_ORDER,
    }, "alignment"),
    allegianceHelp = {
        type = "description", order = 3, fontSize = "medium",
        name = "\nAllegiance is the side your character stands with. It decides your common tongue (Common or Orcish) and, for some species, which faction you start with renown in.\n",
    },
    allegiance = Field({
        type = "select", order = 4, name = "Allegiance",
        values = R.ALLEGIANCES, sorting = R.ALLEGIANCE_ORDER,
    }, "allegiance"),
})

W.pages[4] = alignmentPage
