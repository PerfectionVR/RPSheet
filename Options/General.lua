-- "General" tab: name, announcing, tooltip and sharing, window, and character shortcuts.
local _, ns = ...
local RPSheet = ns.addon
local Opt = ns.Opt

local function Profile() return RPSheet.db.profile end

local function LoadExample()
    RPSheet:ReplaceSheet(CopyTable(ns.ExampleCharacter))
end

Opt.tabs.general = {
    type = "group", order = 1, name = "General",
    args = {
        current = {
            type = "description", order = 1, fontSize = "medium",
            name = function()
                local profile = RPSheet:GetLinkedProfileName()
                local link = profile and ("Total RP 3 profile " .. Opt.GOLD .. profile .. "|r")
                    or ("this WoW character " .. Opt.GOLD .. "(Total RP 3 profile not found)|r")
                return ("Announcing as: %s%s|r\nThis sheet belongs to: %s\n"):format(Opt.GOLD, RPSheet:GetCharacterName(), link)
            end,
        },
        useTRP3 = {
            type = "toggle", order = 2, width = "full",
            name = "Use my Total RP 3 name",
            desc = "Use the first name from your Total RP 3 profile when it is available.",
            get = function() return Profile().useTRP3 end,
            set = function(_, value) Profile().useTRP3 = value; RPSheet:Refresh() end,
        },
        name = {
            type = "input", order = 3, width = "double",
            name = "Fallback name",
            desc = "Used when there is no Total RP 3 name. Leave empty to use your WoW character's name. Saved per character.",
            get = function() return RPSheet.db.char.name end,
            set = function(_, value) RPSheet.db.char.name = value:trim(); RPSheet:Refresh() end,
        },
        channel = {
            type = "select", order = 4,
            name = "Announce to",
            values = ns.CHANNEL_LABEL,
            get = function() return Profile().channel end,
            set = function(_, value) Profile().channel = value; RPSheet:Refresh() end,
        },
        tooltip = {
            type = "toggle", order = 5, width = "full",
            name = "Show stats in Total RP 3 tooltips",
            desc = "Adds a Stats section below the OOC block of Total RP 3 tooltips: your own, and other RP Sheet users'.",
            get = function() return Profile().tooltip end,
            set = function(_, value) Profile().tooltip = value end,
        },
        share = {
            type = "toggle", order = 6, width = "full",
            name = "Share my stats with other RP Sheet users",
            desc = "Sends your stats to your party or raid, and to RP Sheet users who hover or target you.",
            get = function() return Profile().share end,
            set = function(_, value) Profile().share = value; RPSheet:QueueBroadcast() end,
        },
        locked = {
            type = "toggle", order = 7, width = "full",
            name = "Lock the sheet window",
            desc = "The window can't be moved or resized, and clicks on its title bar, background and edges go through to the game. The rows stay clickable.",
            get = function() return Profile().locked end,
            set = function() RPSheet:ToggleLock() end,
        },
        minimap = {
            type = "toggle", order = 8, width = "full",
            name = "Show minimap icon",
            get = function() return not Profile().minimap.hide end,
            set = function(_, value) RPSheet:SetMinimapIconShown(value) end,
        },
        characterHeader = { type = "header", order = 10, name = "Character" },
        wizard = {
            type = "execute", order = 11, width = "double",
            name = "Create character step by step",
            desc = "Opens the creation wizard: class, origin, ability scores, alignment and details. You can keep your existing abilities and passives.",
            func = function() ns.OpenWizard() end,
        },
        example = {
            type = "execute", order = 12, width = "double",
            name = "Load example character",
            desc = "Replaces this sheet with a finished example, to see how resources, abilities and passives are set up.",
            confirm = true,
            confirmText = "Replace this sheet with the example?",
            func = LoadExample,
        },
    },
}
