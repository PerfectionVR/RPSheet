-- Loads saved data, wires everything together at login, and handles /sheet.
-- This is the last file to load, so everything it calls already exists.
local ADDON, ns = ...
local RPSheet = ns.addon
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function RPSheet:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("RPSheetDB", ns.defaults, true)

    -- "Settings profiles" tab (AceDBOptions): copy, reset or switch the general settings
    -- and theme. Characters are not part of these profiles; they follow Total RP 3.
    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    profiles.order, profiles.name = 12, "Settings profiles"
    ns.options.args.profiles = profiles
    local function SettingsChanged() self:SettingsChanged() end
    self.db.RegisterCallback(self, "OnProfileChanged", SettingsChanged)
    self.db.RegisterCallback(self, "OnProfileCopied", SettingsChanged)
    self.db.RegisterCallback(self, "OnProfileReset", SettingsChanged)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON, ns.options)
    AceConfigDialog:SetDefaultSize(ADDON, 700, 600)
    AceConfigDialog:AddToBlizOptions(ADDON, "RP Sheet")
    self:RegisterChatCommand("sheet", "SlashCommand")
    self:RegisterChatCommand("rpsheet", "SlashCommand")
end

function RPSheet:OnEnable()
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self:UpdateSheetKey()
    self:BuildWindow()
    self:BuildMinimapIcon()
    ns.HookTRP3Tooltip(self)
    self:EnableSync()
    ns.EnableChatLinks()

    -- Follow Total RP 3: when its profile loads or the player switches profile,
    -- switch to that profile's sheet and refresh the name.
    local function OnProfileChanged()
        if not self:UpdateSheetKey() then self:Refresh() end
        self:QueueBroadcast() -- another character now, also while the sheet window is closed
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON)
        ns.OfferWizard()
    end
    if TRP3_API and TRP3_API.RegisterCallback and TRP3_Addon and TRP3_Addon.Events then
        pcall(TRP3_API.RegisterCallback, TRP3_Addon, TRP3_Addon.Events.REGISTER_PROFILES_LOADED, OnProfileChanged)
    end
    -- Total RP 3 may finish loading its profile after us; catch up once shortly after
    -- login, then offer the creation wizard if this profile has no character yet.
    C_Timer.After(3, OnProfileChanged)
    -- The wizard isn't opened in combat: offer it when the fight is over.
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() ns.OfferWizard() end)
end

local USAGE = {
    "/sheet - show or hide the sheet",
    "/sheet config - settings and character editor",
    "/sheet new - creation wizard",
    "/sheet lock - lock or unlock the window",
    "/sheet rest - long rest",
    "/sheet damage 14 fire - take damage of a type (the type can be left out)",
    "/sheet heal 8 - regain hit points",
}

function RPSheet:SlashCommand(input)
    local command = (input or ""):trim():lower()
    local verb, rest = command:match("^(%a+)%s*(.*)$")
    if command == "" then
        self:ToggleWindow()
    elseif command == "config" then
        AceConfigDialog:Open(ADDON)
    elseif command == "lock" then
        self:ToggleLock()
    elseif command == "new" then
        ns.OpenWizard()
    elseif command == "rest" then
        self:LongRest()
    elseif verb == "damage" or verb == "heal" then
        self:DamageCommand(verb, rest)
    else
        -- A mistyped word says so, instead of opening or closing the window without one.
        if command ~= "help" then
            self:Print(("\"%s\" is not something /sheet knows."):format(ns.Codec.Cut(ns.Codec.PlainText(command), 40)))
        end
        for _, line in ipairs(USAGE) do self:Print(line) end
    end
end
