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
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON)
        ns.OfferWizard()
    end
    if TRP3_API and TRP3_API.RegisterCallback and TRP3_Addon and TRP3_Addon.Events then
        pcall(TRP3_API.RegisterCallback, TRP3_Addon, TRP3_Addon.Events.REGISTER_PROFILES_LOADED, OnProfileChanged)
    end
    -- Total RP 3 may finish loading its profile after us; catch up once shortly after
    -- login, then offer the creation wizard if this profile has no character yet.
    C_Timer.After(3, OnProfileChanged)
end

-- /sheet            show or hide the sheet
-- /sheet config     settings and character editor
-- /sheet new        creation wizard
-- /sheet lock       lock or unlock the window
-- /sheet rest       long rest
function RPSheet:SlashCommand(input)
    local command = input:trim():lower()
    if command == "config" then
        AceConfigDialog:Open(ADDON)
    elseif command == "lock" then
        self:ToggleLock()
    elseif command == "new" then
        ns.OpenWizard()
    elseif command == "rest" then
        self:LongRest()
    else
        self:ToggleWindow()
    end
end
