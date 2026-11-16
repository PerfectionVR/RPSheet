-- What the sheet can't know about a d20 and so asks, in a small menu, before it is
-- rolled: what a saving throw is against (some advantages only count against one
-- thing), whom a Grappled character attacks, whether what a Frightened character
-- fears is in sight. A question is only asked when its answer changes how the die is
-- rolled, and before anything is spent, so a menu that is closed costs nothing.
-- Each menu has a row to stop asking for this character: the sheet then takes the
-- cautious answer and says so with the roll. Customize > Proficiencies turns a
-- question back on.
local _, ns = ...
local RPSheet = ns.addon

local GREY = "|cff909090"

-- key      the field of `answers` it fills in (see RPSheet:ResolveMode)
-- fits     true when the question can come up for a roll of this label
-- options  the rows of the menu: { text, answer }
-- cautious the answer taken without asking; reminder = what is then said with the roll
ns.ROLL_QUESTIONS = {
    { key = "about", setting = "Ask what a saving throw is against",
      help = "Some of your advantages on saving throws only count against one thing, such as being charmed or a spell. Ticked, the sheet asks when you roll such a save. Unticked, it rolls without them and reminds you to Shift-click when one applies." },
    { key = "Grappled", setting = "Ask whom you attack while Grappled", title = "Grappled: whom do you attack?",
      fits = function(self, label) return ns.IsAttackRoll(label) and self:State().conditions.Grappled end,
      options = { { "Your grappler", false }, { "Someone else " .. GREY .. "(disadvantage)|r", true } },
      cautious = true,
      reminder = "Grappled: rolled with disadvantage, as against anyone but your grappler. Shift-click an attack on the grappler to cancel it out.",
      help = "While Grappled you have disadvantage on attacks against anyone but the grappler. Ticked, the sheet asks whom you attack. Unticked, it rolls with disadvantage and says so." },
    { key = "Frightened", setting = "Ask whether what you fear is in sight", title = "Frightened: is the source of your fear in sight?",
      fits = function(self, label)
          return (ns.IsAttackRoll(label) or ns.IsCheckRoll(label)) and self:State().conditions.Frightened
      end,
      options = { { "Its source is in sight " .. GREY .. "(disadvantage)|r", true }, { "Not in sight", false } },
      cautious = true,
      reminder = "Frightened: rolled with disadvantage, as with the source of your fear in sight. Shift-click when it is out of sight, to cancel it out.",
      help = "While Frightened you have disadvantage on attacks and ability checks as long as the source of your fear is in line of sight. Ticked, the sheet asks. Unticked, it rolls with disadvantage and says so." },
    -- Asked by the sheet itself when damage calls for the save to keep a spell
    -- (Actions/SaveAdvantages.lua), never before a d20 the player rolls.
    { key = "holding", setting = "Ask which spell you hold when damage calls for a save",
      fits = function() return false end,
      help = "Some advantages on the save to keep concentrating only count for some spells, such as one you extended. Ticked, the sheet asks which spell you hold when you take damage. Unticked, it rolls without that advantage and says so." },
}

-- The questions this character has stopped: state.quiet[key] = true.
function RPSheet:RollQuiet(key)
    local quiet = self:State().quiet
    return type(quiet) == "table" and quiet[key] == true
end

function RPSheet:SetRollQuiet(key, on)
    local state = self:State()
    if type(state.quiet) ~= "table" then state.quiet = {} end
    state.quiet[key] = on and true or nil
    self:PopulateSoon() -- the save rows' tooltips say whether the sheet asks
end

-- What a save of this label can be against, for the menu and the reminder:
-- { { about = "being Charmed", from = "Fey Ancestry, Arathi Heritage" } }.
local function SaveChoices(self, label)
    local _, asked = self:SaveAdvantages(label)
    local order, sources = {}, {}
    for _, entry in ipairs(asked) do
        if not sources[entry.about] then
            sources[entry.about] = {}
            order[#order + 1] = entry.about
        end
        table.insert(sources[entry.about], entry.from)
    end
    for index, about in ipairs(order) do order[index] = { about = about, from = table.concat(sources[about], ", ") } end
    return order
end

-- The questions still open for this roll, in the order they are asked.
local function Open(self, label, answers)
    local open = {}
    for _, question in ipairs(ns.ROLL_QUESTIONS) do
        if answers[question.key] == nil then
            if question.key == "about" then
                if #SaveChoices(self, label) > 0 then open[#open + 1] = question end
            elseif question.fits(self, label) then
                open[#open + 1] = question
            end
        end
    end
    return open
end

-- True when the answer changes how the die is rolled, whatever the questions after
-- it are answered with.
local function Matters(self, label, mode, also, answers, open, at)
    local others = #open - at
    for mask = 0, 2 ^ others - 1 do
        local try = {}
        for key, value in pairs(answers) do try[key] = value end
        for index = 1, others do
            try[open[at + index].key] = math.floor(mask / 2 ^ (index - 1)) % 2 == 1
        end
        try[open[at].key] = true
        local with = self:ResolveMode(label, mode, also, nil, try)
        try[open[at].key] = false
        if with ~= self:ResolveMode(label, mode, also, nil, try) then return true end
    end
    return false
end

local function SaveReminder(choices)
    local parts = {}
    for _, choice in ipairs(choices) do parts[#parts + 1] = ("%s (%s)"):format(choice.about, choice.from) end
    return ("You have advantage on this save if it is against %s: Shift-click to roll it that way."):format(table.concat(parts, "; "))
end

-- Asks what the roll of this label needs to know, then calls go(answers); at once
-- when there is nothing to ask. `mode` is the player's own choice ("ADV", "DIS" or
-- nil), `also` a second label the roll goes by, `answers` what is known already.
function RPSheet:AskRoll(label, mode, also, go, answers)
    answers = answers or {}
    local open = Open(self, label, answers)
    local menus = MenuUtil and MenuUtil.CreateContextMenu
    for at, question in ipairs(open) do
        if answers[question.key] == nil and Matters(self, label, mode, also, answers, open, at) then
            local key, save = question.key, question.key == "about"
            local choices = save and SaveChoices(self, label)
            if not menus or self:RollQuiet(key) then
                -- Not asked: the cautious answer, and a line that says what was assumed.
                answers[key] = not save and question.cautious
                self:Print(save and SaveReminder(choices) or question.reminder)
            else
                local function Answer(value)
                    answers[key] = value
                    self:AskRoll(label, mode, also, go, answers)
                end
                MenuUtil.CreateContextMenu(UIParent, function(_, root)
                    root:CreateTitle(save and ("%s: what is it against?"):format(label) or question.title)
                    for _, choice in ipairs(choices or {}) do
                        local button = root:CreateButton(("Against %s %s(advantage)|r"):format(choice.about, GREY),
                            function() Answer(choice.about) end)
                        button:SetTooltip(function(tooltip)
                            GameTooltip_SetTitle(tooltip, "Advantage")
                            GameTooltip_AddNormalLine(tooltip, ("From %s. Disadvantage from anything else cancels it out."):format(choice.from), true)
                        end)
                    end
                    if save then root:CreateButton("Something else", function() Answer(false) end) end
                    for _, option in ipairs(question.options or {}) do
                        root:CreateButton(option[1], function() Answer(option[2]) end)
                    end
                    root:CreateDivider()
                    root:CreateButton("Don't ask again for this character", function()
                        self:SetRollQuiet(key, true)
                        self:Print("The sheet won't ask this again for this character. Customize > Proficiencies turns the question back on.")
                        self:AskRoll(label, mode, also, go, answers) -- rolls now, with the cautious answer
                    end)
                end)
                return
            end
        end
    end
    go(answers)
end
