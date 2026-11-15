-- /sheet and /rpsheet: what each word after the command does.
-- (Registered in Core/Startup.lua; this file loads just before it.)
local ADDON, ns = ...
local RPSheet = ns.addon
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local USAGE = {
    "/sheet - show or hide the sheet",
    "/sheet config - settings and character editor",
    "/sheet new - creation wizard",
    "/sheet level - take the next level",
    "/sheet tab items - open a tab of the sheet (actions, checks, skills, traits, items, trade)",
    "/sheet items - show or hide the item browser",
    "/sheet lock - lock or unlock the window",
    "/sheet rest - long rest",
    "/sheet short - short rest (also /sheet rest short)",
    "/sheet undo - take the last rest back",
    "/sheet damage 14 fire - take damage of a type (the type can be left out)",
    "/sheet heal 8 - regain hit points",
}

-- The tabs of the sheet (UI/SheetContent.lua), as their names are saved.
local TABS = { "Actions", "Checks", "Skills", "Traits", "Items", "Trade" }

-- The tab a typed word means: its name, or the start of it when only one starts so.
local function TabNamed(word)
    local found, count = nil, 0
    for _, name in ipairs(TABS) do
        if name:lower() == word then return name end
        if word ~= "" and name:lower():sub(1, #word) == word then found, count = name, count + 1 end
    end
    return count == 1 and found or nil
end

local function OpenTab(self, word)
    local name = TabNamed(word)
    if not name then
        self:Print("Which tab? " .. table.concat(TABS, ", ") .. ". For example: /sheet tab " .. TABS[5]:lower())
        return
    end
    self.db.char.sheetTab = name
    if not self.window.frame:IsShown() then self.window:Show() end
    self:Populate()
end

-- The "Take level" button of the Character tab, with what it would say when greyed.
local function TakeLevel(self)
    local button = ns.Opt.tabs.character.args.levelUp
    if not self:ClassData() then
        self:Print("There is no character to level yet. /sheet new makes one.")
    elseif button.disabled() then
        self:Print("This character is at the highest level.")
    else
        button.func()
    end
end

-- One word, nothing after it.
local WORDS = {
    config = function() AceConfigDialog:Open(ADDON) end,
    lock = function(self) self:ToggleLock() end,
    new = function() ns.OpenWizard() end,
    rest = function(self) self:LongRest() end,
    short = function(self) self:ShortRest() end,
    undo = function(self) self:UndoRest() end,
    items = function(self) self:ToggleItemBrowser() end,
    level = TakeLevel,
}
WORDS["rest long"], WORDS["rest short"] = WORDS.rest, WORDS.short

function RPSheet:SlashCommand(input)
    local command = (input or ""):trim():lower():gsub("%s+", " ")
    local verb, rest = command:match("^(%a+)%s*(.*)$")
    if command == "" then
        self:ToggleWindow()
    elseif WORDS[command] then
        WORDS[command](self)
    elseif verb == "damage" or verb == "heal" then
        self:DamageCommand(verb, rest)
    elseif verb == "tab" and not rest:find("[^%a]") then
        OpenTab(self, rest)
    else
        -- A mistyped word says so, instead of opening or closing the window without one.
        if command ~= "help" then
            self:Print(("\"%s\" is not something /sheet knows."):format(ns.Codec.Cut(ns.Codec.PlainText(command), 40)))
        end
        for _, line in ipairs(USAGE) do self:Print(line) end
    end
end
