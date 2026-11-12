local ADDON, ns = ...
local R = ns.Rules

local RPSheet = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local CHANNELS = { "EMOTE", "PARTY", "RAID", "SELF" }
local CHANNEL_LABEL = { EMOTE = "Emote", PARTY = "Party", RAID = "Raid", SELF = "Self only" }
ns.CHANNEL_LABEL = CHANNEL_LABEL
-- Colour codes for secondary and highlighted text; set from the theme in ApplyTheme.
local GREY, ACCENT = "|cff909090", "|cffffd100"

local function HexCode(color)
    return ("|cff%02x%02x%02x"):format(color[1] * 255, color[2] * 255, color[3] * 255)
end

-- A new character: every stat at 8, cloth armor, nothing else (a plain STR weapon is added on first use).
local defaults = {
    profile = {
        channel = "EMOTE",
        useTRP3 = true,
        tooltip = true,
        share = true,
        locked = false,
        minimap = { hide = false },
        themePreset = "DARK",
        theme = CopyTable(ns.Themes.DARK),
        window = { width = 280, height = 480 },
    },
    char = {
        name = "",
        shown = true,
    },
    -- One entry per Total RP 3 profile ("trp3:<profile id>"), shared by the whole account
    -- like TRP3's own profiles. Without TRP3 the key is "char:<Name-Realm>".
    -- "*" is AceDB's wildcard: any key that doesn't exist yet starts from these values.
    global = {
        sheets = {
            ["*"] = {
                weapon = 1,
                counter = 0,
                initialized = false,
                -- hp and resource start out nil and are filled to their maximum on first use
                sheet = {
                    base = { STR = 8, DEX = 8, CON = 8, INT = 8, WIS = 8, CHA = 8 },
                    bonus = { STR = 0, DEX = 0, CON = 0, INT = 0, WIS = 0, CHA = 0 },
                    size = "MEDIUM", armor = "CLOTH", shield = "NONE",
                    resourceName = "Energy", resourceStat = "STR",
                    counterName = "", counterMax = 0,
                    -- Lists of any length; entries follow R.TEMPLATES.
                    weapons = {},
                    abilities = {},
                    passives = {},
                },
            },
        },
    },
}

local function Signed(n)
    return (n >= 0 and "+" or "") .. n
end

local function ScoreMod(score)
    return math.floor((score - 10) / 2)
end

---------------------------------------------------------------------------
-- Derived values (all computed from the saved sheet)
---------------------------------------------------------------------------
-- Copies every value missing from `target` out of `template` (saved data only holds
-- what differs from the defaults, so a moved sheet needs them filled back in).
local function FillDefaults(target, template)
    for key, value in pairs(template) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            FillDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

-- Turns a saved list into a clean array: drops unnamed entries and fills missing fields.
local function NormalizeList(list, template)
    local keys = {}
    for key, entry in pairs(list) do
        if type(key) == "number" and type(entry) == "table" and (entry.name or "") ~= "" then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)
    local entries = {}
    for i, key in ipairs(keys) do entries[i] = FillDefaults(list[key], template) end
    wipe(list)
    for i, entry in ipairs(entries) do list[i] = entry end
end

-- Brings a sheet saved by any earlier version into the current shape.
local function NormalizeSheet(sheet)
    NormalizeList(sheet.weapons, R.TEMPLATES.weapon)
    NormalizeList(sheet.abilities, R.TEMPLATES.ability)
    NormalizeList(sheet.passives, R.TEMPLATES.passive)
    for _, passive in ipairs(sheet.passives) do
        -- Older versions: one optional skill bonus per passive.
        if (passive.skill or "") ~= "" and R.STAT_NAMES[passive.stat] then
            table.insert(passive.effects, { target = "SKILL:" .. passive.skill, flat = 0, stat = passive.stat, times = 1 })
        end
        passive.skill, passive.stat = nil, nil
        for i = #passive.effects, 1, -1 do
            local effect = passive.effects[i]
            if type(effect) ~= "table" then
                table.remove(passive.effects, i)
            else
                FillDefaults(effect, R.TEMPLATES.effect)
                if not R.EFFECT_TARGETS[effect.target] then effect.target = "AC" end
            end
        end
    end
    -- Older versions: a single "AC bonus from passives" number.
    local acBonus = rawget(sheet, "acBonus")
    if type(acBonus) == "number" and acBonus ~= 0 then
        table.insert(sheet.passives, {
            name = "AC bonus", desc = "", enabled = true,
            effects = { { target = "AC", flat = acBonus, stat = "", times = 1 } },
        })
    end
    sheet.acBonus = nil
end

-- Which saved sheet is active: the current Total RP 3 profile, else this WoW character.
local function CurrentSheetKey()
    local getID = TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfileID
    if getID then
        local ok, id = pcall(getID)
        if ok and type(id) == "string" and id ~= "" then
            return "trp3:" .. id
        end
    end
    return ("char:%s-%s"):format(UnitName("player"), GetNormalizedRealmName() or "")
end

-- Name of the linked Total RP 3 profile, or nil when the sheet is tied to the WoW character.
function RPSheet:GetLinkedProfileName()
    if not self.sheetKey or not self.sheetKey:find("^trp3:") then return end
    local ok, profile = pcall(TRP3_API.profile.getPlayerCurrentProfile)
    return ok and type(profile) == "table" and profile.profileName or "?"
end

-- Switches to the sheet of the current TRP3 profile if it changed. Returns true on a switch.
function RPSheet:UpdateSheetKey()
    local key = CurrentSheetKey()
    local previous = self.sheetKey
    if key == previous then return false end
    self.sheetKey = key

    local sheets, old = self.db.global.sheets, self.db.char
    if rawget(old, "sheet") and not rawget(sheets, key) then
        -- A sheet made before sheets were linked to profiles moves to the first profile seen.
        sheets[key] = FillDefaults(
            { sheet = old.sheet, hp = old.hp, resource = old.resource, counter = old.counter, weapon = old.weapon },
            defaults.global.sheets["*"])
        old.sheet, old.hp, old.resource, old.counter, old.weapon = nil, nil, nil, nil, nil
    elseif previous and previous:find("^char:") and key:find("^trp3:") and rawget(sheets, previous) and not rawget(sheets, key) then
        -- Total RP 3 became available: the character's own sheet becomes the profile's sheet.
        sheets[key] = FillDefaults(rawget(sheets, previous), defaults.global.sheets["*"])
        sheets[previous] = nil
    end

    local state = sheets[key]
    NormalizeSheet(state.sheet)
    if not state.initialized then
        if #state.sheet.weapons == 0 then
            local weapon = CopyTable(R.TEMPLATES.weapon)
            weapon.name = "Weapon"
            state.sheet.weapons[1] = weapon
        end
        state.initialized = true
    end
    if ns.RebuildOptions then ns.RebuildOptions() end

    self:ClampState()
    self:Populate()
    return true
end

-- Trackers (hp, resource, counter, weapon) and the sheet itself for the active profile.
function RPSheet:State()
    return self.db.global.sheets[self.sheetKey]
end

function RPSheet:Sheet()
    return self:State().sheet
end

function RPSheet:Score(stat)
    local sheet = self:Sheet()
    return (sheet.base[stat] or R.BASE_MIN) + (sheet.bonus[stat] or 0)
end

-- Modifier of a stat; an empty or unknown stat counts as +0.
function RPSheet:Mod(stat)
    if not R.STAT_NAMES[stat] then return 0 end
    return ScoreMod(self:Score(stat))
end

function RPSheet:PointsSpent()
    local total = 0
    for _, stat in ipairs(R.STATS) do
        total = total + (R.COST[self:Sheet().base[stat]] or 0)
    end
    return total
end

function RPSheet:BonusSpent()
    local total = 0
    for _, stat in ipairs(R.STATS) do
        total = total + self:Sheet().bonus[stat]
    end
    return total
end

-- What one passive effect is worth right now: flat + times x stat modifier.
function RPSheet:EffectValue(effect)
    return effect.flat + effect.times * self:Mod(effect.stat)
end

-- Total of every switched-on passive effect aimed at `target` (see R.EFFECT_TARGETS).
function RPSheet:Bonus(target)
    local total = 0
    for _, passive in ipairs(self:Sheet().passives) do
        if passive.enabled and passive.name ~= "" then
            for _, effect in ipairs(passive.effects) do
                if effect.target == target then
                    total = total + self:EffectValue(effect)
                end
            end
        end
    end
    return total
end

-- e.g. "+3 +2x DEX to Armor Class (now +9)"
function RPSheet:EffectText(effect)
    local parts = {}
    if effect.flat ~= 0 then parts[#parts + 1] = Signed(effect.flat) end
    if R.STAT_NAMES[effect.stat] then
        parts[#parts + 1] = "+" .. (effect.times > 1 and (effect.times .. "x ") or "") .. effect.stat
    end
    if #parts == 0 then parts[1] = "+0" end
    return ("%s to %s (now %s)"):format(
        table.concat(parts, " "), R.EFFECT_TARGETS[effect.target] or effect.target, Signed(self:EffectValue(effect)))
end

function RPSheet:MaxHP()
    return math.max(1, R.SIZES[self:Sheet().size].hp + 2 * self:Mod("CON") + self:Bonus("HP"))
end

function RPSheet:AC()
    local sheet = self:Sheet()
    return R.ARMOR[sheet.armor].ac + self:Mod("DEX") + R.SHIELDS[sheet.shield].ac + self:Bonus("AC")
end

-- Class resource: main stat modifier x CON modifier x 2
function RPSheet:MaxResource()
    local base = math.max(0, self:Mod(self:Sheet().resourceStat) * self:Mod("CON") * 2)
    return math.max(0, base + self:Bonus("RESOURCE"))
end

-- Stat modifier plus passive effects on this skill or on all skills.
function RPSheet:SkillMod(skill)
    return self:Mod(skill.stat) + self:Bonus("SKILL:" .. skill.name) + self:Bonus("SKILLS")
end

local function Named(list)
    local result = {}
    for _, entry in ipairs(list) do
        if entry.name ~= "" then result[#result + 1] = entry end
    end
    return result
end

function RPSheet:GetWeapon()
    local weapons = Named(self:Sheet().weapons)
    return weapons[self:State().weapon] or weapons[1]
end

function RPSheet:SwapWeapon()
    local count = #Named(self:Sheet().weapons)
    if count == 0 then return end
    self:State().weapon = self:State().weapon % count + 1
    self:Refresh()
end

-- Returns dice count, die size, and whether this is a healing roll.
function RPSheet:WeaponDice(weapon)
    local kind = R.WEAPON_KINDS[weapon.kind] or R.WEAPON_KINDS.ONE
    return kind.dice or weapon.dice, kind.sides or weapon.sides, kind.heal
end

-- Keeps the trackers inside their limits. `refill` sets HP and resource back to full.
function RPSheet:ClampState(refill)
    local state = self:State()
    local hpMax, resourceMax = self:MaxHP(), self:MaxResource()
    state.hp = refill and hpMax or math.min(state.hp or hpMax, hpMax)
    state.resource = refill and resourceMax or math.min(state.resource or resourceMax, resourceMax)
    state.counter = math.min(state.counter, self:Sheet().counterMax)
end

-- Called by the settings after any change to the character.
function RPSheet:SheetChanged()
    self:ClampState(true)
    self:Populate()
end

---------------------------------------------------------------------------
-- Name: Total RP 3 first name -> name from settings -> WoW character name
---------------------------------------------------------------------------
function RPSheet:GetCharacterName()
    if self.db.profile.useTRP3 and AddOn_TotalRP3 and AddOn_TotalRP3.Player then
        local ok, name = pcall(function()
            return AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
        end)
        if ok and type(name) == "string" and name:trim() ~= "" then
            return name
        end
    end
    local custom = self.db.char.name
    if custom and custom:trim() ~= "" then
        return custom
    end
    return UnitName("player")
end

---------------------------------------------------------------------------
-- Stats snapshot: shown in the tooltip and sent to other RP Sheet users
---------------------------------------------------------------------------
function RPSheet:GetStatData()
    local state, sheet = self:State(), self:Sheet()
    local data = {
        hp = state.hp, hpMax = self:MaxHP(),
        ac = self:AC(),
        resource = state.resource, resourceMax = self:MaxResource(), resourceName = sheet.resourceName,
        stats = {},
    }
    for i, stat in ipairs(R.STATS) do
        data.stats[i] = self:Score(stat)
    end
    if sheet.counterMax > 0 then
        data.counter, data.counterMax, data.counterName = state.counter, sheet.counterMax, sheet.counterName
    end
    local weapon = self:GetWeapon()
    if weapon then
        data.weapon = weapon.name
        data.dice, data.sides = self:WeaponDice(weapon)
    end
    return data
end

-- Lines for the "Stats" section in the Total RP 3 tooltip, from a GetStatData snapshot.
function RPSheet:GetStatLines(data)
    local SEP = "  \194\183  " -- middle dot
    local vitals = { ("HP %d/%d"):format(data.hp, data.hpMax), "AC " .. data.ac }
    if data.resourceMax > 0 then
        vitals[#vitals + 1] = ("%s %d/%d"):format(data.resourceName, data.resource, data.resourceMax)
    end
    if data.counterMax then
        vitals[#vitals + 1] = ("%s %d/%d"):format(data.counterName, data.counter, data.counterMax)
    end
    local lines = { table.concat(vitals, SEP) }
    for row = 0, 1 do
        local parts = {}
        for i = 1, 3 do
            local index = row * 3 + i
            local score = data.stats[index]
            parts[i] = ("%s %d (%s)"):format(R.STATS[index], score, Signed(ScoreMod(score)))
        end
        lines[#lines + 1] = table.concat(parts, SEP)
    end
    if data.weapon then
        lines[#lines + 1] = ("%s (%dd%d)"):format(data.weapon, data.dice, data.sides)
    end
    return lines
end

---------------------------------------------------------------------------
-- Announcing
---------------------------------------------------------------------------
function RPSheet:Announce(text)
    local channel = self.db.profile.channel
    if (channel == "PARTY" and not IsInGroup()) or (channel == "RAID" and not IsInRaid()) then
        channel = "SELF"
    end
    if channel ~= "SELF" and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        channel = "SELF"
    end
    if channel == "SELF" then
        self:Print(self:GetCharacterName() .. " " .. text)
        return
    end
    -- Emotes are already prefixed with the character's name by the game.
    local msg = channel == "EMOTE" and text or (self:GetCharacterName() .. " " .. text)
    local send = C_ChatInfo.SendChatMessage or SendChatMessage
    send(msg, channel)
end

---------------------------------------------------------------------------
-- Rolling: uses the real /roll so others can verify it, then reads the result.
---------------------------------------------------------------------------
local pending
local rollPattern = "^" .. RANDOM_ROLL_RESULT
    :gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
    :gsub("%%s", "(.+)")
    :gsub("%%d", "(%%d+)") .. "$"

function RPSheet:Roll(sides, callback)
    if self.db.profile.channel == "SELF" then
        callback(math.random(1, sides))
        return
    end
    if pending then return end
    local request = { sides = tostring(sides), callback = callback }
    pending = request
    RandomRoll(1, sides)
    C_Timer.After(3, function()
        if pending == request then
            pending = nil
            self:Print("Couldn't read the roll result from chat. Nothing was announced.")
        end
    end)
end

-- Rolls `count` dice one after another and passes the list of results on.
function RPSheet:RollDice(count, sides, callback, results)
    results = results or {}
    if #results >= count then
        callback(results)
        return
    end
    self:Roll(sides, function(value)
        results[#results + 1] = value
        self:RollDice(count, sides, callback, results)
    end)
end

function RPSheet:CHAT_MSG_SYSTEM(_, msg)
    if not pending or (issecretvalue and issecretvalue(msg)) then return end
    local name, roll, low, high = msg:match(rollPattern)
    if name == UnitName("player") and low == "1" and high == pending.sides then
        local callback = pending.callback
        pending = nil
        callback(tonumber(roll))
    end
end

local function CheckText(label, d20, mod)
    local text = ("%s: %d %s %d = %d"):format(label, d20, mod >= 0 and "+" or "-", math.abs(mod), d20 + mod)
    if d20 == 20 then
        text = text .. " (NATURAL 20!)"
    elseif d20 == 1 then
        text = text .. " (natural 1)"
    end
    return text
end

-- e.g. "damage 1d4 + 3: 2 + 3 = 5"
local function DiceText(label, rolls, sides, mod)
    local sum = 0
    for _, value in ipairs(rolls) do sum = sum + value end
    local dice = table.concat(rolls, " + ")
    if #rolls > 1 then dice = "(" .. dice .. ")" end
    local sign = mod >= 0 and "+" or "-"
    return ("%s %dd%d %s %d: %s %s %d = %d"):format(label, #rolls, sides, sign, math.abs(mod), dice, sign, math.abs(mod), sum + mod)
end

function RPSheet:RollCheck(label, mod)
    self:Roll(20, function(d20)
        self:Announce("rolls " .. CheckText(label, d20, mod))
    end)
end

-- Attack: d20 + weapon stat, then the weapon's dice + the same modifier.
-- Healing "weapons" skip the d20 and only roll their dice.
function RPSheet:Attack()
    local weapon = self:GetWeapon()
    if not weapon then return end
    local dice, sides, heal = self:WeaponDice(weapon)
    local mod = self:Mod(weapon.stat)
    if heal then
        self:RollDice(dice, sides, function(rolls)
            self:Announce(("uses %s - %s"):format(weapon.name, DiceText("healing", rolls, sides, mod + self:Bonus("HEALING"))))
        end)
        return
    end
    local attackBonus, damageBonus = self:Bonus("ATTACK"), self:Bonus("DAMAGE")
    local label = "d20 + " .. weapon.stat .. (attackBonus ~= 0 and " + passives" or "")
    self:Roll(20, function(d20)
        self:RollDice(dice, sides, function(rolls)
            self:Announce(("attacks with %s - %s, %s"):format(
                weapon.name, CheckText(label, d20, mod + attackBonus), DiceText("damage", rolls, sides, mod + damageBonus)))
        end)
    end)
end

function RPSheet:UseAbility(ability)
    local state, sheet = self:State(), self:Sheet()
    local counterFull = ability.usesCounter and sheet.counterMax > 0 and state.counter >= sheet.counterMax
    local cost = counterFull and 0 or ability.cost
    if cost > state.resource then
        self:Print(("Not enough %s for %s (%d needed, %d left)."):format(sheet.resourceName, ability.name, cost, state.resource))
        return
    end

    local stats = {}
    if R.STAT_NAMES[ability.stat1] then stats[#stats + 1] = ability.stat1 end
    if R.STAT_NAMES[ability.stat2] then stats[#stats + 1] = ability.stat2 end
    local weapon = ability.weaponDamage > 0 and self:GetWeapon()

    local function finish(d20, diceRolls)
        state.resource = state.resource - cost
        local text = "uses " .. ability.name
        if counterFull then
            text = text .. (" (free, %d %s)"):format(state.counter, sheet.counterName)
        elseif cost > 0 then
            text = text .. (" (%d %s)"):format(cost, sheet.resourceName)
        end
        if ability.usesCounter then state.counter = 0 end
        if d20 then
            -- An ability that also rolls weapon dice counts as an attack for passive bonuses.
            local mod = weapon and self:Bonus("ATTACK") or 0
            local label = "d20 + " .. table.concat(stats, " + ") .. (mod ~= 0 and " + passives" or "")
            for _, stat in ipairs(stats) do mod = mod + self:Mod(stat) end
            text = text .. " - " .. CheckText(label, d20, mod)
        end
        if diceRolls then
            local _, sides, heal = self:WeaponDice(weapon)
            local mod = self:Mod(weapon.stat) + self:Bonus(heal and "HEALING" or "DAMAGE")
            text = text .. (d20 and ", " or " - ") .. DiceText(heal and "healing" or "damage", diceRolls, sides, mod)
        end
        self:Announce(text)
        self:Refresh()
    end

    local function afterD20(d20)
        if weapon then
            local dice, sides = self:WeaponDice(weapon)
            self:RollDice(ability.weaponDamage * dice, sides, function(rolls) finish(d20, rolls) end)
        else
            finish(d20)
        end
    end

    if #stats > 0 then self:Roll(20, afterD20) else afterD20() end
end

---------------------------------------------------------------------------
-- Window (AceGUI)
---------------------------------------------------------------------------
-- Font, colours and shadow from the theme. AceGUI resets all of these when it reuses a label.
local function StyleLabel(label, color, sizeOffset)
    local theme = RPSheet.db.profile.theme
    label:SetFont(theme.font, theme.fontSize + (sizeOffset or 0), "")
    label.label:SetTextColor(color[1], color[2], color[3])
    label.label:SetShadowOffset(1, -1)
    label.label:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
end

local function AddLabel(parent, relWidth, text, onClick, tipTitle, tipBody)
    local theme = RPSheet.db.profile.theme
    local label = AceGUI:Create("InteractiveLabel")
    StyleLabel(label, theme.text)
    label:SetRelativeWidth(relWidth)
    label:SetText(text)
    if onClick then
        label.highlight:SetColorTexture(unpack(theme.highlight))
        label:SetCallback("OnClick", function(_, _, button) onClick(button) end)
    end
    if tipTitle then
        label:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
            GameTooltip:AddLine(tipTitle)
            if tipBody and tipBody ~= "" then GameTooltip:AddLine(tipBody, 1, 1, 1, true) end
            GameTooltip:Show()
        end)
        label:SetCallback("OnLeave", GameTooltip_Hide)
    end
    parent:AddChild(label)
    return label
end

local function AddHeading(parent, text)
    local heading = AceGUI:Create("InteractiveLabel")
    StyleLabel(heading, RPSheet.db.profile.theme.accent, 1)
    heading.frame:EnableMouse(false)
    heading:SetFullWidth(true)
    heading:SetText("\n" .. text)
    parent:AddChild(heading)
end

function RPSheet:BuildWindow()
    local state = self.db.char

    local theme = self.db.profile.theme
    GREY, ACCENT = HexCode(theme.muted), HexCode(theme.accent)

    local window = AceGUI:Create("RPSheetWindow")
    window:SetStatusTable(self.db.profile.window)
    window:SetLayout("Fill")
    window:SetTheme(theme)
    window:SetCallback("OnLockClick", function() self:ToggleLock() end)
    window:SetCallback("OnEditClick", function() AceConfigDialog:Open(ADDON) end)
    window:SetCallback("OnClose", function() state.shown = false end)
    window:SetCallback("OnShow", function() state.shown = true; self:Refresh() end)
    self.window = window

    local body = AceGUI:Create("ScrollFrame")
    body:SetLayout("Flow")
    window:AddChild(body)
    self.body = body

    self:Populate()
    self:ApplyLock()
    if not state.shown then window:Hide() end
end

function RPSheet:ToggleWindow()
    if self.window.frame:IsShown() then self.window:Hide() else self.window:Show() end
end

-- Locked: the window can't be moved or resized, and its title bar, background and
-- edges let clicks through to the game. The rows on the sheet stay clickable.
function RPSheet:ApplyLock()
    self.window:SetLocked(self.db.profile.locked)
end

-- Re-skins the window after a theme change (see Themes.lua).
function RPSheet:ApplyTheme()
    local theme = self.db.profile.theme
    GREY, ACCENT = HexCode(theme.muted), HexCode(theme.accent)
    self.window:SetTheme(theme)
    self:Populate()
end

-- Replaces the saved theme with a preset; every value can be changed afterwards.
function RPSheet:LoadThemePreset(key)
    local preset = ns.Themes[key]
    if not preset then return end
    local theme = self.db.profile.theme
    for field, value in pairs(preset) do
        theme[field] = type(value) == "table" and CopyTable(value) or value
    end
    self.db.profile.themePreset = key
    self:ApplyTheme()
end

function RPSheet:ToggleLock()
    self.db.profile.locked = not self.db.profile.locked
    self:ApplyLock()
    self:Refresh()
end

function RPSheet:BuildMinimapIcon()
    local broker = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON, {
        type = "launcher",
        text = "RP Sheet",
        icon = "Interface\\ICONS\\INV_Misc_Dice_02",
        OnClick = function(_, button)
            if button == "RightButton" then
                AceConfigDialog:Open(ADDON)
            elseif IsShiftKeyDown() then
                self:ToggleLock()
            else
                self:ToggleWindow()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("RP Sheet")
            tooltip:AddLine("Left-click: show or hide the sheet", 1, 1, 1)
            tooltip:AddLine("Shift-click: lock or unlock the sheet", 1, 1, 1)
            tooltip:AddLine("Right-click: settings", 1, 1, 1)
        end,
    })
    LibStub("LibDBIcon-1.0"):Register(ADDON, broker, self.db.profile.minimap)
end

-- Rebuilds the window contents from the saved sheet.
function RPSheet:Populate()
    local body = self.body
    if not body then return end
    local state, sheet = self:State(), self:Sheet()

    body:PauseLayout()
    body:ReleaseChildren()

    self.channelLabel = AddLabel(body, 1, "", function()
        local profile = self.db.profile
        for i, name in ipairs(CHANNELS) do
            if name == profile.channel then
                profile.channel = CHANNELS[i % #CHANNELS + 1]
                break
            end
        end
        self:Refresh()
    end, "Announce to", "Click to switch between Emote, Party, Raid and Self only.\nSelf only rolls privately; the others use a real /roll.")

    -- Trackers
    self.trackers = {}
    local theme = self.db.profile.theme
    local function AddTracker(key, label, max, reset, color)
        local bar = AceGUI:Create("RPSheetBar")
        bar:SetStyle(theme, color)
        bar:SetRelativeWidth(0.5)
        bar:SetCallback("OnClick", function(_, _, button)
            if IsShiftKeyDown() then
                state[key] = reset
            else
                local delta = button == "LeftButton" and 1 or -1
                state[key] = math.max(0, math.min(max, state[key] + delta))
            end
            self:Refresh()
        end)
        bar:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
            GameTooltip:AddLine(label)
            GameTooltip:AddLine("Left-click: +1\nRight-click: -1\nShift-click: reset", 1, 1, 1)
            GameTooltip:Show()
        end)
        bar:SetCallback("OnLeave", GameTooltip_Hide)
        body:AddChild(bar)
        self.trackers[#self.trackers + 1] = { widget = bar, key = key, label = label, max = max }
    end
    AddTracker("hp", "HP", self:MaxHP(), self:MaxHP(), theme.barHP)
    AddLabel(body, 0.5, ("  AC %s%d|r"):format(ACCENT, self:AC()))
    if self:MaxResource() > 0 then
        AddTracker("resource", sheet.resourceName, self:MaxResource(), self:MaxResource(), theme.barResource)
    end
    if sheet.counterMax > 0 then
        AddTracker("counter", sheet.counterName, sheet.counterMax, 0, theme.barCounter)
    end

    self.attackLabel = nil
    if self:GetWeapon() then
        AddHeading(body, "Attack")
        self.attackLabel = AddLabel(body, 1, "", function(button)
            if button == "RightButton" then self:SwapWeapon() else self:Attack() end
        end, "Attack", "Left-click: roll d20 + modifier, then weapon damage.\nRight-click: swap to the next weapon.")
    end

    AddHeading(body, "Stats")
    for _, stat in ipairs(R.STATS) do
        local mod = self:Mod(stat)
        AddLabel(body, 0.33, ("%s %d %s(%s)|r"):format(stat, self:Score(stat), GREY, Signed(mod)),
            function() self:RollCheck(stat, mod) end)
    end

    local abilities = Named(sheet.abilities)
    if #abilities > 0 then
        AddHeading(body, "Abilities")
        for _, ability in ipairs(abilities) do
            local text = ability.name
            if ability.cost > 0 then
                text = ("%s  %s%d %s|r"):format(text, GREY, ability.cost, sheet.resourceName)
            end
            AddLabel(body, 1, text, function() self:UseAbility(ability) end, ability.name, ability.desc)
        end
    end

    local passives = Named(sheet.passives)
    if #passives > 0 then
        AddHeading(body, "Passives")
        for _, passive in ipairs(passives) do
            local lines = {}
            if passive.desc ~= "" then lines[#lines + 1] = passive.desc end
            for _, effect in ipairs(passive.effects) do
                lines[#lines + 1] = "|cff80ff80" .. self:EffectText(effect) .. "|r"
            end
            lines[#lines + 1] = GREY .. "Click to switch " .. (passive.enabled and "off" or "on") .. "|r"
            local text = passive.enabled and passive.name or (GREY .. passive.name .. " (off)|r")
            AddLabel(body, 0.5, text, function()
                passive.enabled = not passive.enabled
                self:ClampState()
                -- Rebuilt on the next frame: this label is part of what gets rebuilt.
                C_Timer.After(0, function() self:Populate() end)
            end, passive.name, table.concat(lines, "\n"))
        end
    end

    AddHeading(body, "Skills")
    for _, skill in ipairs(R.SKILLS) do
        local mod = self:SkillMod(skill)
        AddLabel(body, 0.5, ("%s %s%s|r"):format(skill.name, GREY, Signed(mod)),
            function() self:RollCheck(skill.name, mod) end,
            skill.name, ("d20 %s (%s)"):format(Signed(mod), skill.stat))
    end

    -- Fill in the rows whose text comes from Refresh before laying out: a row that is
    -- still empty has no height, and the rows below it would be placed on top of it.
    self:Refresh()
    body:ResumeLayout()
    body:DoLayout()
end

function RPSheet:Refresh()
    if not self.window or not self.channelLabel then return end
    self:QueueBroadcast()
    local state = self:State()
    self.window:SetTitle(self:GetCharacterName())
    self.channelLabel:SetText(("Announce to: %s%s|r"):format(ACCENT, CHANNEL_LABEL[self.db.profile.channel]))    local weapon = self:GetWeapon()
    if weapon and self.attackLabel then
        local dice, sides, heal = self:WeaponDice(weapon)
        self.attackLabel:SetText(("%s  %s%s %s, %dd%d %s|r"):format(
            weapon.name, GREY, weapon.stat, Signed(self:Mod(weapon.stat)), dice, sides, heal and "healing" or "damage"))
    end
    for _, t in ipairs(self.trackers) do
        t.widget:SetValue(state[t.key], t.max)
        t.widget:SetText(("%s %d/%d"):format(t.label, state[t.key], t.max))
    end
end

---------------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------------
function RPSheet:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("RPSheetDB", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON, ns.options)
    AceConfigDialog:SetDefaultSize(ADDON, 640, 560)
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

    -- Follow Total RP 3: when its profile loads or the player switches profile,
    -- switch to that profile's sheet and refresh the name.
    local function OnProfileChanged()
        if not self:UpdateSheetKey() then self:Refresh() end
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON)
    end
    if TRP3_API and TRP3_API.RegisterCallback and TRP3_Addon and TRP3_Addon.Events then
        pcall(TRP3_API.RegisterCallback, TRP3_Addon, TRP3_Addon.Events.REGISTER_PROFILES_LOADED, OnProfileChanged)
    end
    -- Total RP 3 may finish loading its profile after us; catch up once shortly after login.
    C_Timer.After(3, OnProfileChanged)
end

function RPSheet:SlashCommand(input)
    local command = input:trim():lower()
    if command == "config" then
        AceConfigDialog:Open(ADDON)
    elseif command == "lock" then
        self:ToggleLock()
    else
        self:ToggleWindow()
    end
end
