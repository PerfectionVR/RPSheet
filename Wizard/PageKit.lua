-- What the creation wizard's pages share. The wizard follows the book's steps:
-- 1 class, 2 origin (species and background), 3 ability scores, 4 alignment, 5 details.
-- Each page is an AceConfig group that is only shown on its step (Wizard/Page*.lua).
local _, ns = ...
local R = ns.Rules
local W = ns.Wizard

-- hidden unless the wizard is on step `n`
local function Step(n)
    return function() return not W.draft or W.draft.step ~= n end
end

-- Binds an option to a field of the draft.
local function Field(option, key)
    option.get = function() return W.draft[key] end
    option.set = function(_, value) W.draft[key] = value end
    return option
end

local function Page(order, args)
    return { type = "group", inline = true, order = order * 10, name = "", hidden = Step(order), args = args }
end

local function DraftClass()
    return R.CLASSES[W.draft.class]
end

W.DraftField, W.Page, W.DraftClass = Field, Page, DraftClass
W.pages = {} -- filled by the page files, by step number
