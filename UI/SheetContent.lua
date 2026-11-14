-- What the sheet window shows. Populate rebuilds every row from the saved sheet, one
-- section at a time; Refresh only updates the text that changes during play.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local UI = ns.UI
local Util = ns.Util
local Signed = Util.Signed

local TRACKER_HELP = "Left-click: +1\nRight-click: -1\nShift-click: reset"
local HIT_DICE_HELP = "Left-click: spend one to heal (rolls the die and adds your Constitution modifier)\nRight-click: give one back\nShift-click: reset"

-- Rebuilds the rows on the next frame. Used from a row's own click, because that row
-- is part of what gets rebuilt.
function RPSheet:PopulateSoon()
    C_Timer.After(0, function() self:Populate() end)
end
local function PopulateSoon(self) self:PopulateSoon() end

---------------------------------------------------------------------------
-- Sections (each adds its rows to `body`)
---------------------------------------------------------------------------
local function HeaderSection(self, body)
    local summary = self:Summary()
    if summary then
        UI.AddLabel(body, 1, UI.GREY .. summary .. "|r")
    else
        UI.AddLabel(body, 1, UI.ACCENT .. "No class chosen yet - click here to create your character|r", function()
            ns.OpenWizard()
        end)
    end

    self.channelLabel = UI.AddLabel(body, 1, "", function() self:CycleChannel() end,
        "Announce to", "Click to switch between Emote, Party, Raid and Self only.\nSelf only rolls privately; the others use a real /roll.")

    self.rollModeLabel = UI.AddLabel(body, 1, "", function(button) self:CycleRollMode(button == "RightButton") end,
        "Next roll", "How your next d20 is rolled: normally, with advantage (two dice, the higher counts) or with disadvantage (the lower counts).\n\nLeft-click: switch between normal, advantage and disadvantage. It goes back to normal after one roll.\nRight-click: keep it for every roll until you change it, for a condition that lasts.\n\nHolding Shift or Ctrl while clicking a roll still works, and takes priority.")

    -- Only for a character with spell slots of more than one level.
    self.castLevelLabel = nil
    local slotLevels = 0
    for _, count in pairs(self:SpellSlots()) do
        if count > 0 then slotLevels = slotLevels + 1 end
    end
    if slotLevels > 1 then
        self.castLevelLabel = UI.AddLabel(body, 1, "", function() self:CycleCastLevel() end,
            "Cast at", "The slot your next spell uses. Normally the lowest free slot that fits. Click to pick a higher level: spells that grow with the slot roll more dice. It goes back to the lowest after one spell.")
    end

    UI.AddLabel(body, 0.5, UI.ACCENT .. "Short rest|r", function() self:ShortRest() end,
        "Short rest", "Gives back what recharges on a short rest. To heal, click the Hit Dice bar.")
    UI.AddLabel(body, 0.5, UI.ACCENT .. "Long rest|r", function() self:LongRest() end,
        "Long rest", "Restores HP, hit dice, class resources, your own resources and spell slots.")
end

-- Bars for HP, hit dice and resources, then temporary HP, inspiration, death saves
-- (only at 0 HP), and spell slots as compact rows.
local function TrackerSection(self, body)
    local theme, state = self.db.profile.theme, self:State()
    local barColors = { hp = theme.barHP, hitdice = theme.barHP, pool = theme.barResource, resource = theme.barCounter }
    local trackers = self:GetTrackers()
    self.trackerRows = {}

    local function Change(tracker, button)
        local wasDown = self:IsDown()
        if IsShiftKeyDown() then
            tracker.set(tracker.reset)
        elseif tracker.kind == "hitdice" and button == "LeftButton" then
            self:SpendHitDie()
            return
        else
            tracker.set(tracker.get() + (button == "LeftButton" and 1 or -1))
            if tracker.kind == "hp" and button ~= "LeftButton" then self:DamageTaken(1) end
        end
        if tracker.kind == "hp" and wasDown ~= self:IsDown() then
            -- Dropping to 0 shows the death save row; getting back up removes it.
            self:ClearDeathSaves()
            if self:IsDown() then
                self:EndConcentration("at 0 hit points")
                self:LeaveForms("at 0 hit points")
            end
            PopulateSoon(self)
        end
        self:Refresh()
    end

    for _, tracker in ipairs(trackers) do
        if tracker.kind ~= "slot" then
            local bar = UI.AddBar(body, barColors[tracker.kind], function(button) Change(tracker, button) end,
                tracker.label, tracker.kind == "hitdice" and HIT_DICE_HELP or TRACKER_HELP)
            self.trackerRows[#self.trackerRows + 1] = { widget = bar, tracker = tracker, bar = true }
        end
    end

    self.tempLabel = UI.AddLabel(body, 0.5, "", function(button)
        if IsShiftKeyDown() then
            state.tempHP = 0
        else
            state.tempHP = math.max(0, state.tempHP + (button == "LeftButton" and 1 or -1))
        end
        self:Refresh()
    end, "Temporary HP", "A buffer that is lost before your real hit points. It doesn't stack and a long rest removes it.\n\n" .. TRACKER_HELP)

    self.inspirationLabel = UI.AddLabel(body, 0.5, "", function()
        state.inspiration = not state.inspiration
        self:Refresh()
    end, "Heroic Inspiration", ns.Glossary["Heroic Inspiration"] .. "\n\nClick to gain or spend it.")

    self.deathLabel = nil
    if self:IsDown() then
        self.deathLabel = UI.AddLabel(body, 1, "", function(button)
            if button == "RightButton" then
                -- Stable but hurt again: the count starts over.
                self:ClearDeathSaves()
                self:Refresh()
            else
                self:RollDeathSave()
            end
        end, "Death saving throw", "You are at 0 HP. Roll a d20 at the start of each turn: 10 or higher passes. Three passes and you are stable: still at 0 HP and unconscious, but no longer rolling. Three failures and you die. A natural 20 puts you back on 1 HP; a natural 1 counts as two failures.\n\nRight-click to start the count over, for when a stable character takes damage.")
    end

    local hasSlots = false
    for _, tracker in ipairs(trackers) do
        if tracker.kind == "slot" then
            if not hasSlots then
                UI.AddHeading(body, "Spell slots")
                hasSlots = true
            end
            local label = UI.AddLabel(body, 0.33, "", function(button) Change(tracker, button) end, tracker.label, TRACKER_HELP)
            self.trackerRows[#self.trackerRows + 1] = { widget = label, tracker = tracker }
        end
    end
end

-- What the character is under: conditions (a menu of tick boxes) and exhaustion.
local function ConditionSection(self, body)
    local active = self:Conditions()
    local lines = {}
    for _, condition in ipairs(R.CONDITIONS) do
        if self:State().conditions[condition.name] then
            lines[#lines + 1] = ("%s%s|r: %s"):format(UI.ACCENT, condition.name, condition.desc)
        end
    end
    lines[#lines + 1] = "Click to choose the conditions you are under."
    local label
    label = UI.AddLabel(body, 1,
        ("Conditions %s%s|r"):format(UI.ACCENT, #active > 0 and table.concat(active, ", ") or "none"),
        function() self:OpenConditionMenu(label.frame) end, "Conditions", table.concat(lines, "\n\n"))

    local exhaustion = self:Exhaustion()
    UI.AddLabel(body, 1, ("Exhaustion %s%d|r"):format(exhaustion > 0 and "|cffff5555" or UI.ACCENT, exhaustion),
        function(button) self:ChangeExhaustion(button == "RightButton" and -1 or 1) end,
        "Exhaustion", R.EXHAUSTION_HELP .. "\n\nLeft-click +1, right-click -1.")
end

local function CombatSection(self, body)
    local sheet = self:Sheet()
    UI.AddHeading(body, "Combat")

    local function Number(label, value, onClick, tip, explain)
        UI.AddLabel(body, 0.33, ("%s %s%s|r"):format(label, UI.ACCENT, value), onClick, tip and label, tip, explain)
    end
    -- In a form the Armor Class is the form's own.
    local form = self:Form()
    local acTip = form and ("%s: the form's own Armor Class. Your armor and shield don't count while you are in it."):format(form.beast and (form.name .. " form") or form.name)
        or (R.ARMOR[sheet.armor].name .. (sheet.shield and ", shield" or ""))
    Number(form and "AC (form)" or "AC", self:AC(), nil, acTip,
        function() self:ExplainAC() end)
    Number("Initiative", Signed(self:Initiative()),
        function() self:RollCheck("initiative", self:Initiative(), ns.RollMode()) end,
        "Click to roll initiative.\n" .. ns.ROLL_MODE_HELP, function() self:ExplainInitiative() end)
    Number("Speed", self:Speed() .. " ft", nil, "How far you can move on your turn.", function() self:ExplainSpeed() end)
    Number("Proficiency", Signed(self:ProficiencyBonus()), nil, ns.Glossary["Proficiency bonus"])
    Number("Passive Perc.", self:PassivePerception(), nil, "Passive Perception: 10 + Perception modifier.",
        function() self:ExplainPassivePerception() end)
    -- Senses and resistances get a row each, after the numbers.
    local senses, resistances = self:Senses(), self:Resistances()
    local function After()
        if #senses > 0 then
            UI.AddLabel(body, 1, ("Senses %s%s|r"):format(UI.ACCENT, table.concat(senses, ", ")), nil, "Senses",
                "Darkvision comes from your species or beast form. The others are read from the passives that are switched on.")
        end
        if #resistances > 0 then
            UI.AddLabel(body, 1, ("Resists %s%s|r"):format(UI.ACCENT, table.concat(resistances, ", ")), nil, "Resistances",
                "You take half damage of these types. Read from the passives that are switched on: switch one off, or write \"resistance to fire damage\" in a passive of your own, and the row follows.")
        end
    end
    if self:CastStat() then
        Number("Spell DC", self:SpellDC(), nil, "Spell save DC: 8 + proficiency + " .. R.STAT_NAMES[self:CastStat()] .. " modifier.",
            function() self:ExplainSpellDC() end)
        Number("Spell attack", Signed(self:SpellAttack()),
            function() self:RollCheck("spell attack", self:SpellAttack(), ns.RollMode()) end,
            "Click to roll a spell attack.\n" .. ns.ROLL_MODE_HELP, function() self:ExplainSpellAttack() end)
    end
    After()

    self.attackLabel = nil
    local weapon = self:GetWeapon()
    if weapon then
        local help = "Left-click: roll to hit, then damage. A natural 20 doubles the damage dice.\nRight-click: swap to the next weapon.\n" .. ns.ROLL_MODE_HELP
        local properties = ns.WeaponPropertyLines(weapon)
        if #properties > 0 then help = help .. "\n\n" .. table.concat(properties, "\n") end
        local name, mastery = self:WeaponMastery(weapon)
        if name then help = help .. ("\n\n%s%s|r: %s"):format(UI.ACCENT, name, mastery.desc) end
        self.attackLabel = UI.AddLabel(body, 1, "", function(button)
            if button == "RightButton" then
                self:SwapWeapon()
                self:PopulateSoon() -- the tooltip follows the weapon
            else
                self:Attack(ns.RollMode())
            end
        end, "Attack", help, function()
            local current = self:GetWeapon()
            if current then self:ExplainWeapon(current) end
        end)
    end
end

local function CheckSection(self, body)
    UI.AddHeading(body, "Ability checks")
    for _, stat in ipairs(R.STATS) do
        local mod = self:CheckMod(stat)
        UI.AddLabel(body, 0.33, ("%s %d %s(%s)|r"):format(stat, self:Score(stat), UI.GREY, Signed(mod)),
            function() self:RollCheck(stat .. " check", mod, ns.RollMode()) end,
            R.STAT_NAMES[stat], ("%s\n\nClick to roll a %s check.\n%s"):format(ns.Glossary[stat], R.STAT_NAMES[stat], ns.ROLL_MODE_HELP),
            function() self:ExplainCheck(stat) end)
    end
end

local function SaveSection(self, body)
    local saves = self:Sheet().saves
    UI.AddHeading(body, "Saving throws")
    for _, stat in ipairs(R.STATS) do
        local mod = self:SaveMod(stat)
        local name = saves[stat] and (UI.ACCENT .. stat .. "|r") or stat
        UI.AddLabel(body, 0.33, ("%s %s%s|r"):format(name, UI.GREY, Signed(mod)),
            function() self:RollCheck(stat .. " save", mod, ns.RollMode()) end,
            R.STAT_NAMES[stat] .. " saving throw",
            ("%s\n\n%s\n\n%s"):format(saves[stat] and "Proficient." or "Not proficient.", ns.Glossary["Saving throw"], ns.ROLL_MODE_HELP),
            function() self:ExplainSave(stat) end)
    end
end

local function AbilitySection(self, body)
    local abilities = Util.Named(self:Sheet().abilities)
    if #abilities == 0 then return end
    UI.AddHeading(body, "Abilities")
    for _, ability in ipairs(abilities) do
        local lines = {}
        if ability.desc ~= "" then lines[#lines + 1] = ability.desc end
        for _, action in ipairs(ability.actions) do
            lines[#lines + 1] = UI.GREEN .. self:ActionText(action) .. "|r"
        end
        UI.AddLabel(body, 1, ability.name, function(button)
            -- A right-click takes back a cost that turned out not to be spent, if one is open.
            if button == "RightButton" and self:TakeBack(ability.name) then return end
            self:UseAbility(ability, ns.RollMode())
        end, ability.name, table.concat(lines, "\n"))
    end
end

-- The spell list, cantrips first, then by level.
local function SpellSection(self, body)
    local spells = Util.Named(self:Sheet().spells)
    local book = ns.HasSpellbook(self:Sheet())
    if #spells == 0 and not book then return end
    table.sort(spells, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)

    UI.AddHeading(body, "Spells")
    self.sheetSlotLabels = {}
    if book then
        UI.AddLabel(body, 1, UI.ACCENT .. "Open spellbook|r", function() self:ToggleSpellbook() end, "Spellbook",
            "Every spell in your book. Cast from it, and choose which spells are prepared. The spells listed below are the prepared ones and your cantrips.")
    end
    local shown -- the spell level whose line was added last
    for _, spell in ipairs(spells) do
        -- A line per spell level, with the slots left of that level.
        if spell.level ~= shown then
            shown = spell.level
            self:AddLevelLabel(body, shown, self.sheetSlotLabels)
        end
        local info = self:SpellText(spell)
        local lines = {}
        if spell.desc ~= "" then lines[#lines + 1] = spell.desc end
        lines[#lines + 1] = spell.level == 0 and "A cantrip: no spell slot needed."
            or ("Uses your lowest free slot of %s level or higher, or the level set at \"Cast at\".%s"):format(R.ORDINALS[spell.level],
                (spell.up or 0) > 0 and (" Each slot level above adds %dd%d."):format(spell.up, spell.sides) or "")
        local casting = R.SpellCastingNote(spell)
        if casting then lines[#lines + 1] = casting end
        if spell.ritual then lines[#lines + 1] = "Right-click: cast it as a ritual. It takes ten minutes longer and uses no slot." end
        if spell.kind == "ATTACK" then lines[#lines + 1] = ns.ROLL_MODE_HELP end
        if R.GROWING_SPELLS[spell.name] then
            lines[#lines + 1] = self:GrowingSides(spell)
                and "It is running. Left-click when the target fails its save again: the die grows and the damage is rolled, without a slot. Right-click when it succeeds or the spell runs out: that ends it."
                or "After casting, click it again each time the target fails its save: the die grows and the damage is rolled, without a slot."
        end
        UI.AddLabel(body, 1, ("%s  %s%s|r"):format(spell.name, UI.GREY, info),
            function(button) self:CastSpell(spell, ns.RollMode(), button == "RightButton") end, spell.name, table.concat(lines, "\n"),
            function() self:ExplainSpell(spell) end)
    end
end

local function PassiveSection(self, body)
    local passives = Util.Named(self:Sheet().passives)
    if #passives == 0 then return end
    UI.AddHeading(body, "Passives and traits")
    for _, passive in ipairs(passives) do
        local lines = {}
        if passive.desc ~= "" then lines[#lines + 1] = passive.desc end
        for _, effect in ipairs(passive.effects) do
            lines[#lines + 1] = UI.GREEN .. self:EffectText(effect) .. "|r"
        end
        local stopped = self:PassiveBlocked(passive)
        if stopped then lines[#lines + 1] = ("Not counted now: you have %s on."):format(stopped) end
        lines[#lines + 1] = "|cff909090Click to switch " .. (passive.enabled and "off" or "on") .. "|r"
        local text = passive.enabled and passive.name or (UI.GREY .. passive.name .. " (off)|r")
        UI.AddLabel(body, 0.5, text, function()
            passive.enabled = not passive.enabled
            if passive.enabled then self:PassiveSwitchedOn(passive) end -- some end others
            self:ClampState()
            PopulateSoon(self)
        end, passive.name, table.concat(lines, "\n"))
    end
end

local function SkillSection(self, body)
    local ranks = self:Sheet().skills
    UI.AddHeading(body, "Skills")
    for _, skill in ipairs(R.SKILLS) do
        local mod = self:SkillMod(skill)
        local rank = ranks[skill.name] or 0
        local name = rank > 0 and (UI.ACCENT .. skill.name .. (rank > 1 and "*" or "") .. "|r") or skill.name
        UI.AddLabel(body, 0.5, ("%s %s%s|r"):format(name, UI.GREY, Signed(mod)),
            function() self:RollCheck(skill.name, mod, ns.RollMode()) end,
            skill.name, ("%s\n\n%s (%s), %s\n\n%s"):format(
                ns.Glossary[skill.name], R.STAT_NAMES[skill.stat], Signed(mod), R.PROFICIENCY_NAMES[rank]:lower(), ns.ROLL_MODE_HELP),
            function() self:ExplainSkill(skill) end)
    end
end

-- The tools the character is proficient with, each a check to click.
local function ToolSection(self, body)
    local tools = self:Tools()
    if #tools == 0 then return end
    UI.AddHeading(body, "Tools")
    for _, tool in ipairs(tools) do
        local mod = self:ToolMod(tool)
        UI.AddLabel(body, 0.5, ("%s%s|r %s%s|r"):format(UI.ACCENT, tool.name, UI.GREY, Signed(mod)),
            function() self:RollCheck(tool.name, mod, ns.RollMode()) end,
            tool.name, ("%s. A check with it uses %s and your proficiency bonus (%s). The DM can ask for another ability.\n\n%s"):format(
                R.TOOL_KINDS[tool.kind], R.STAT_NAMES[tool.stat], Signed(mod), ns.ROLL_MODE_HELP))
    end
end

-- Languages and renown, when the character has any.
local function OriginSection(self, body)
    local languages = self:Languages()
    local renown = {}
    for _, faction in ipairs(R.ALL_FACTIONS) do
        local score = self:Sheet().renown[faction] or 0
        if score > 0 then
            local tier = R.RenownTier(score)
            -- The perks of every tier reached, lowest first.
            local perks = {}
            for index = #R.RENOWN_TIERS, 1, -1 do
                local step = R.RENOWN_TIERS[index]
                if score >= step[1] then perks[#perks + 1] = ("%s%s|r: %s"):format(UI.ACCENT, step[2], R.RENOWN_PERKS[step[2]]) end
            end
            renown[#renown + 1] = {
                text = ("%s %s%d%s|r"):format(faction, UI.GREY, score, tier ~= "" and (" " .. tier) or ""),
                tip = "Standing with a faction. Friendly at 3, Honored at 10, Revered at 25, Exalted at 50."
                    .. (#perks > 0 and ("\n\n" .. table.concat(perks, "\n")) or "") .. "\n\nThe faction's own perks come on top of these.",
            }
        end
    end
    if #languages == 0 and #renown == 0 then return end

    UI.AddHeading(body, "Languages and renown")
    if #languages > 0 then
        UI.AddLabel(body, 1, table.concat(languages, ", "))
    end
    for _, line in ipairs(renown) do
        UI.AddLabel(body, 0.5, line.text, nil, "Renown", line.tip)
    end
end

local SECTIONS = {
    HeaderSection, TrackerSection, ConditionSection, CombatSection, CheckSection, SaveSection,
    UI.PetSection, -- a Beast Master's companion (UI/PetSection.lua)
    AbilitySection, SpellSection, PassiveSection, SkillSection, ToolSection, OriginSection,
}

---------------------------------------------------------------------------
-- Populate and Refresh
---------------------------------------------------------------------------
function RPSheet:Populate()
    local body = self.body
    if not body then return end

    body:PauseLayout()
    body:ReleaseChildren()
    self.sheetSlotLabels = {} -- the old lines are gone with the rows
    for _, section in ipairs(SECTIONS) do
        section(self, body)
    end
    -- Fill in the rows whose text comes from Refresh before laying out: a row that is
    -- still empty has no height, and the rows below it would be placed on top of it.
    self:Refresh()
    body:ResumeLayout()
    body:DoLayout()
    self:PopulateSpellbook() -- the open spellbook follows the sheet
end

function RPSheet:Refresh()
    if not self.window or not self.channelLabel then return end
    self:RefreshSlotLabels()
    self:QueueBroadcast()
    local state = self:State()
    self.window:SetTitle(self:GetCharacterName())
    self.channelLabel:SetText(("Announce to: %s%s|r"):format(UI.ACCENT, ns.CHANNEL_LABEL[self.db.profile.channel]))
    if self.rollModeLabel then
        local mode = self.rollMode
        local text = (mode == "ADV" and "|cff80ff80Advantage|r") or (mode == "DIS" and "|cffff5555Disadvantage|r") or (UI.ACCENT .. "Normal|r")
        if mode and self.rollModeLocked then text = text .. " (every roll)" end
        self.rollModeLabel:SetText(("Next roll: %s"):format(text))
    end

    if self.castLevelLabel then
        self.castLevelLabel:SetText(("Cast at: %s%s|r"):format(UI.ACCENT, self.castLevel and (R.ORDINALS[self.castLevel] .. " level") or "lowest slot"))
    end

    local weapon = self:GetWeapon()
    if weapon and self.attackLabel then
        UI.SetText(self.attackLabel, ("%s  %s%s|r"):format(weapon.name, UI.GREY, self:WeaponText(weapon)))
    end

    for _, row in ipairs(self.trackerRows) do
        local tracker = row.tracker
        local value = tracker.get() or 0
        if row.bar then
            local text = ("%s %d/%d"):format(tracker.label, value, tracker.max)
            if tracker.kind == "hp" and state.tempHP > 0 then text = text .. (" (+%d)"):format(state.tempHP) end
            row.widget:SetValue(value, tracker.max)
            row.widget:SetText(text)
        else
            local short = tracker.label:gsub("%-level slot", "")
            row.widget:SetText(("%s %s%d/%d|r"):format(short, UI.ACCENT, value, tracker.max))
        end
    end

    self.tempLabel:SetText(("Temp HP %s%d|r"):format(UI.ACCENT, state.tempHP))
    self.inspirationLabel:SetText(("Inspiration %s%s|r"):format(UI.ACCENT, state.inspiration and "yes" or "no"))
    if self.deathLabel then
        local status = "click to roll"
        if state.deathFail >= 3 then
            status = "dead"
        elseif state.deathPass >= 3 then
            status = "stable at 0 HP"
        end
        self.deathLabel:SetText(("%sDeath saves: %d passed, %d failed - %s|r"):format(
            "|cffff5555", state.deathPass, state.deathFail, status))
    end
end
