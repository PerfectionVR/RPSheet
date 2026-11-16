-- The random-play tester's invariants: what must be true of the character after
-- every action, whatever the actions were. Each returns a text when it is not.
-- (Lua errors, also those swallowed by pcall, and chat lines the game would refuse
-- are reported where they happen: t-fuzz-lib.lua, t-fuzz-game-lib.lua.)
local Z = FUZZ
local Invariant = Z.Invariant

local function State() return RPSheet:State() end
local function Whole(value) return type(value) == "number" and value == math.floor(value) and value == value end
local function Count(set) local n = 0 for _ in pairs(set or {}) do n = n + 1 end return n end

---------------------------------------------------------------------------
-- Numbers that have a floor and a ceiling
---------------------------------------------------------------------------
Invariant("hit points", function()
    local state = State()
    local max = RPSheet:MaxHP()
    if not Whole(max) or max < 1 then return "the hit point maximum is " .. tostring(max) end
    if state.hp ~= nil and (not Whole(state.hp) or state.hp < 0 or state.hp > max) then return ("%s hit points of %d"):format(tostring(state.hp), max) end
    if not Whole(state.tempHP) or state.tempHP < 0 then return "temporary hit points are " .. tostring(state.tempHP) end
    if not Whole(state.deathPass) or state.deathPass < 0 or state.deathPass > 3 then return "death save successes are " .. tostring(state.deathPass) end
    if not Whole(state.deathFail) or state.deathFail < 0 or state.deathFail > 3 then return "death save failures are " .. tostring(state.deathFail) end
    if not Whole(state.exhaustion) or state.exhaustion < 0 or state.exhaustion > R.MAX_EXHAUSTION then return "exhaustion is " .. tostring(state.exhaustion) end
end)

Invariant("pools", function()
    for _, tracker in ipairs(RPSheet:GetTrackers()) do
        local value, max = tracker.get(), tracker.max
        if not Whole(max) or max < 0 then return ("'%s' has a maximum of %s"):format(tostring(tracker.label), tostring(max)) end
        if value ~= nil and (not Whole(value) or value < 0 or value > max) then
            return ("'%s' holds %s of %d"):format(tostring(tracker.label), tostring(value), max)
        end
    end
end)

Invariant("coins", function()
    local sheet = RPSheet:Sheet()
    for coin, amount in pairs(sheet.coins) do
        if not Whole(amount) or amount < 0 then return ("%s coins: %s"):format(tostring(coin), tostring(amount)) end
    end
    for kind, worth in pairs(sheet.materials or {}) do
        if not Whole(worth) or worth < 0 then return ("%s materials: %s"):format(tostring(kind), tostring(worth)) end
    end
end)

Invariant("items", function()
    local sheet = RPSheet:Sheet()
    local suits, shields = 0, 0
    for _, item in ipairs(sheet.items) do
        if not Whole(item.qty) or item.qty < 1 then return ("'%s' is in the inventory %s times"):format(tostring(item.name), tostring(item.qty)) end
        local slot = ns.ItemSlot(item)
        if item.equipped and slot == "armor" then
            suits = suits + 1
            local key = R.ARMOR_ITEMS[ns.ItemBase(item)]
            if sheet.armor ~= key then return ("'%s' is equipped but the sheet's armor is %s"):format(item.name, tostring(sheet.armor)) end
        elseif item.equipped and slot == "shield" then
            shields = shields + 1
            if not sheet.shield then return "'" .. item.name .. "' is equipped but the sheet has no shield up" end
        end
    end
    if suits > 1 then return suits .. " suits of armor are equipped" end
    if shields > 1 then return shields .. " shields are equipped" end
    if not Z.IsFree() and #RPSheet:AttunedItems() > R.ATTUNE_LIMIT then return #RPSheet:AttunedItems() .. " items are attuned" end
end)

---------------------------------------------------------------------------
-- The character as a whole
---------------------------------------------------------------------------
Invariant("levels", function()
    local sheet = RPSheet:Sheet()
    if not R.CLASSES[sheet.class] then return end
    if not Whole(sheet.level) or sheet.level < 1 or sheet.level > R.MAX_LEVEL then return "the level is " .. tostring(sheet.level) end
    local total = 0
    for _, key in ipairs(ns.ClassKeys(sheet)) do
        local level = ns.ClassLevel(sheet, key)
        if not Whole(level) or level < 1 then return ("%s has %s levels"):format(key, tostring(level)) end
        total = total + level
    end
    if total ~= sheet.level then return ("the class levels add up to %d, the level is %d"):format(total, sheet.level) end
end)

Invariant("twice", function()
    local sheet = RPSheet:Sheet()
    for _, field in ipairs({ "weapons", "abilities", "passives", "spells", "resources" }) do
        local seen = {}
        for _, entry in ipairs(sheet[field]) do
            if type(entry.auto) == "string" and entry.auto ~= "" then
                -- Two classes may each pick the same spell: one entry each, with the
                -- same mark and its own class (Sheet/SpellPicks.lua, PreparedPicks.lua).
                local id = field == "spells" and (entry.auto .. "/" .. tostring(entry.class or "")) or entry.auto
                if seen[id] then return ("two %s marked '%s' (%s)"):format(field, id, tostring(entry.name)) end
                seen[id] = true
            end
        end
    end
    if Z.IsFree() then return end -- the Spells page adds what it is told to
    local seen = {}
    for _, spell in ipairs(sheet.spells) do
        -- two classes may each prepare the same spell: the entries name their class
        local id = tostring(spell.name) .. "/" .. tostring(spell.class or "")
        if seen[id] and spell.name ~= "" then return ("the spell '%s' is on the sheet twice"):format(id) end
        seen[id] = true
    end
end)

-- Strict until a free edit: nothing above its limit.
Invariant("limits", function()
    local sheet = RPSheet:Sheet()
    if Z.IsFree() or not R.CLASSES[sheet.class] then return end
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        local limit, known = ns.SheetPickLimit(sheet, key), ns.PicksKnown(sheet, key)
        if known > limit then return ("'%s': %d picked, the limit is %d"):format(key, known, limit) end
    end
    if ns.ManeuversKnown(sheet) > ns.SheetManeuverLimit(sheet) then return ("%d maneuvers, the limit is %d"):format(ns.ManeuversKnown(sheet), ns.SheetManeuverLimit(sheet)) end
    if ns.ExpertiseKnown(sheet) > ns.ExpertiseLimit(sheet) then return ("expertise in %d skills, the limit is %d"):format(ns.ExpertiseKnown(sheet), ns.ExpertiseLimit(sheet)) end
    if ns.FeatSkillsKnown(sheet) > ns.FeatSkillLimit(sheet) then return ("%d feat skills, the limit is %d"):format(ns.FeatSkillsKnown(sheet), ns.FeatSkillLimit(sheet)) end
    for _, stat in ipairs(R.STATS) do
        local score = RPSheet:NaturalScore(stat, true)
        if score > R.BOON_MAX_SCORE then return ("%s is %d"):format(stat, score) end
    end
end)

-- The Character tab's red lines: only after a free edit. A choice left open (a level
-- dialog closed unfinished) says so in red, and that is all it may say.
Invariant("red lines", function()
    local sheet = RPSheet:Sheet()
    if Z.IsFree() or not R.CLASSES[sheet.class] then return end
    local text = Z.Options("RPSheet").args.character.args.summary.name()
    for line in text:gmatch("[^\n]+") do
        if line:find(Opt.RED, 1, true) and not line:find("Hero classes normally start", 1, true) then
            local open = line:find("choices to make", 1, true) or line:find("A choice is waiting", 1, true)
                or line:find("Fighting Style to choose", 1, true)
            if not (open and State().fuzzOpen) then return "red on the Character tab without a free edit: " .. F.Plain(line) end
        end
    end
end)

---------------------------------------------------------------------------
-- Nothing stuck, nothing stale
---------------------------------------------------------------------------
Invariant("busy", function()
    if Z.waiting then return end -- a roll is on its way
    if RPSheet:IsRolling() then return "the sheet waits for a roll that nobody is making" end
    if RPSheet.busy then return "the sheet is busy with nothing going on" end
end)

local function WindowTexts()
    local texts = {}
    for _, entry in ipairs(Z.Windows()) do
        for _, part in ipairs(Parts(entry.window)) do
            if part ~= entry.window then texts[#texts + 1] = entry.key .. ": " .. F.Plain(PartText(part)) end
        end
    end
    return texts
end
-- What the open windows show is what a rebuild of them shows: no number was left
-- as it was before the action.
Invariant("stale", function()
    local before = WindowTexts()
    RPSheet:Populate()
    local after = WindowTexts()
    for index = 1, math.max(#before, #after) do
        if before[index] ~= after[index] then
            return ("a window was not brought up to date: it showed '%s' where a rebuild shows '%s'"):format(
                tostring(before[index]):sub(1, 90), tostring(after[index]):sub(1, 90))
        end
    end
end, 2)

Invariant("text", function()
    for _, line in ipairs(Z.NewPrints()) do
        if Z.OddText(line) then return "printed: " .. Z.OddText(line) end
    end
    for _, text in ipairs(WindowTexts()) do
        if Z.OddText(text) then return "shown: " .. Z.OddText(text) end
    end
end)

-- The numbers work out, their explanations too, and what other players are sent.
Invariant("numbers", function()
    local sheet = RPSheet:Sheet()
    local data = RPSheet:GetStatData()
    for _, line in ipairs(RPSheet:GetStatLines(data) or {}) do
        if Z.OddText(line) then return "stats for other players: " .. Z.OddText(line) end
    end
    if not R.CLASSES[sheet.class] then return end
    for _, value in ipairs({ RPSheet:AC(), RPSheet:Speed(), RPSheet:Initiative(), RPSheet:PassivePerception(), RPSheet:ProficiencyBonus() }) do
        if not Whole(value) then return "a number of the sheet is " .. tostring(value) end
    end
    RPSheet:ExplainAC(); RPSheet:ExplainInitiative(); RPSheet:ExplainSpeed(); RPSheet:Languages(); RPSheet:Summary()
    for _, stat in ipairs(R.STATS) do
        if not Whole(RPSheet:SaveMod(stat)) or not Whole(RPSheet:CheckMod(stat)) then return stat .. " save or check is not a whole number" end
        RPSheet:ExplainCheck(stat); RPSheet:ExplainSave(stat)
    end
    for _, skill in ipairs(R.SKILLS) do
        if not Whole(RPSheet:SkillMod(skill)) then return skill.name .. " is " .. tostring(RPSheet:SkillMod(skill)) end
        RPSheet:ExplainSkill(skill)
    end
    for _, passive in ipairs(sheet.passives) do
        for _, effect in ipairs(passive.effects or {}) do RPSheet:EffectText(effect) end
    end
    for _, ability in ipairs(sheet.abilities) do
        for _, action in ipairs(ability.actions or {}) do RPSheet:ActionText(action) end
    end
    for _, spell in ipairs(sheet.spells) do RPSheet:SpellText(spell); RPSheet:ExplainSpell(spell) end
    for _, weapon in ipairs(ns.ReadyWeapons(sheet)) do RPSheet:WeaponText(weapon); RPSheet:ExplainWeapon(weapon) end
end, 3)

-- Every row of every open window can be hovered: its tooltip builds and closes.
Invariant("hover", function()
    for _, entry in ipairs(Z.Windows()) do
        for _, part in ipairs(Parts(entry.window)) do
            if part ~= entry.window and part.frame:IsVisible() and part.events and part.events.OnEnter then
                F.Enter(part.frame)
                for _, line in ipairs(F.TooltipLines() or {}) do
                    if Z.OddText(line.text) then return ("tooltip of '%s': %s"):format(F.Plain(PartText(part)):sub(1, 40), Z.OddText(line.text)) end
                end
                F.Leave(part.frame)
                if GameTooltip:IsShown() then
                    GameTooltip:Hide()
                    return ("the tooltip of '%s' stays open"):format(F.Plain(PartText(part)):sub(1, 40))
                end
            end
        end
    end
end, 7)

-- The settings can be read: every option's name, values and current value.
Invariant("settings", function()
    ns.RebuildOptions()
    Z.Rows(Z.Options("RPSheet"))
    if W.draft then Z.Rows(Z.Options("RPSheetWizard"), "wizard") end
    if ns.LevelDialog.draft then Z.Rows(Z.Options(ns.LevelDialog.DIALOG), "level") end
end, 9)

Invariant("saved", function()
    local _, problem = Z.Serialize(RPSheetDB)
    if problem then return "the saved variables hold " .. problem end
end, 5)

---------------------------------------------------------------------------
-- Before and after: a reload, an export and import
---------------------------------------------------------------------------
-- The character and the numbers worked out from it, for comparing.
function Z.Dump()
    local sheet = RPSheet:Sheet()
    local numbers = { ac = RPSheet:AC(), maxHP = RPSheet:MaxHP(), speed = RPSheet:Speed(), initiative = RPSheet:Initiative(),
        perception = RPSheet:PassivePerception(), proficiency = RPSheet:ProficiencyBonus(), summary = RPSheet:Summary() }
    for _, stat in ipairs(R.STATS) do numbers["save " .. stat], numbers["check " .. stat] = RPSheet:SaveMod(stat), RPSheet:CheckMod(stat) end
    for _, skill in ipairs(R.SKILLS) do numbers[skill.name] = RPSheet:SkillMod(skill) end
    for _, tracker in ipairs(RPSheet:GetTrackers()) do
        numbers["tracker " .. tostring(tracker.label)] = tostring(tracker.get()) .. "/" .. tostring(tracker.max)
    end
    return { state = CopyTable(State()), numbers = numbers, sheet = sheet ~= nil }
end
-- The first difference between two dumps, or nil.
function Z.Compare(a, b, path)
    path = path or ""
    -- An empty table and nothing are the same to the saved data (a table made on
    -- first use, such as state.scrollSpells, isn't there again until it is used).
    local function Empty(value) return value == nil or (type(value) == "table" and next(value) == nil) end
    if Empty(a) and Empty(b) then return end
    if type(a) ~= type(b) then return ("%s was %s and is %s"):format(path, tostring(a), tostring(b)) end
    if type(a) ~= "table" then
        if a ~= b then return ("%s was %s and is %s"):format(path, tostring(a), tostring(b)) end
        return
    end
    local keys = {}
    for key in pairs(a) do keys[#keys + 1] = key end
    for key in pairs(b) do if a[key] == nil then keys[#keys + 1] = key end end
    table.sort(keys, function(x, y) return tostring(x) < tostring(y) end)
    for _, key in ipairs(keys) do
        local difference = Z.Compare(a[key], b[key], path .. "." .. tostring(key))
        if difference then return difference end
    end
end

-- Asked once at the end of a character's run: a reload leaves it as it was, and its
-- export imports to the same export.
function Z.Final()
    if not Z.HasCharacter() then return end
    Z.ReloadSame()
    local first = RPSheet:ExportSheet()
    local decoded, why = RPSheet:DecodeSheet(first)
    if not decoded then Z.Report("transfer", "the character's own export can't be imported: " .. tostring(why)) return end
    RPSheet:ReplaceSheet(decoded)
    F.Settle()
    Z.ExportSame(first)
    Z.CollectErrors("final")
end
