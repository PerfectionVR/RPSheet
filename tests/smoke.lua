-- Every class, subclass and specialization at a spread of levels: put on a sheet, then
-- everything on it is read, clicked and cast once.
NUM_CHAT_WINDOWS = 10
RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"
SENT = {}
C_ChatInfo = { SendChatMessage = function(msg, channel)
    SENT[#SENT + 1] = msg
    if type(msg) ~= "string" then Problem("chat message is " .. type(msg))
    elseif #msg > 255 then Problem("chat message over 255: " .. msg:sub(1, 80))
    elseif msg:find("|") or msg:find("\n") then Problem("chat message with a pipe or line break: " .. msg:sub(1, 200)) end
end }
dofile(ARG3 .. "/sim.lua")
ROLLDEPTH = 0
function RandomRoll(low, high)
    local ok, err = pcall(function()
        RPSheet:CHAT_MSG_SYSTEM(nil, ("Tester rolls %d (%d-%d)"):format(math.random(low, high), low, high))
    end)
    if not ok then print("ROLL CALLBACK ERROR (" .. tostring(CONTEXT) .. "): " .. tostring(err):gsub("%S*wt%-hunt%-wizard%-data/", "")) end
    if low ~= 1 or high ~= math.floor(high) or high < 1 then print("ODD ROLL (" .. tostring(CONTEXT) .. "): " .. tostring(low) .. "-" .. tostring(high)) end
end
Start()
dofile(ARG3 .. "/snap.lua")
local SNAP = Snapshot(R)
local Kit = ns.FeatureKit
local LEVELS = { 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 13, 14, 15, 17, 18, 20 }
if ARG4 == "quick" then LEVELS = { 1, 3, 5, 11, 20 } end
local count = 0
local function Top(err) return tostring(err) end
local seenProblems = {}
local function Do(label, fn, ...)
    CONTEXT = label
    local res = { xpcall(fn, function(m) return debug.traceback(m, 2) end, ...) }
    if not res[1] then
        local first = tostring(res[2]):match("^[^\n]*") or ""
        local key = first:gsub("^.*wt%-hunt%-wizard%-data/", "")
        if not seenProblems[key] then
            seenProblems[key] = true
            print("PROBLEM [" .. label .. "]: " .. tostring(res[2]):gsub("%S*wt%-hunt%-wizard%-data/", ""):sub(1, 1100))
        end
        return nil
    end
    return unpack(res, 2)
end
local mainOptions = REGISTRY:GetOptionsTable("RPSheet")("dialog", "AceConfigDialog-3.0")

local function Exercise(label)
    local sheet = RPSheet:Sheet()
    Do(label .. " trackers", function() RPSheet:GetTrackers() end)
    Do(label .. " stats", function()
        local data = RPSheet:GetStatData(); RPSheet:GetStatLines(data); RPSheet:Summary()
        RPSheet:AC(); RPSheet:MaxHP(); RPSheet:Speed(); RPSheet:Initiative(); RPSheet:PassivePerception(); RPSheet:Darkvision(); RPSheet:Languages()
        RPSheet:ExplainAC(); RPSheet:ExplainInitiative(); RPSheet:ExplainSpeed(); RPSheet:ExplainPassivePerception(); RPSheet:ExplainSpellDC(); RPSheet:ExplainSpellAttack()
        for _, stat in ipairs(R.STATS) do RPSheet:SaveMod(stat); RPSheet:CheckMod(stat); RPSheet:ExplainCheck(stat); RPSheet:ExplainSave(stat) end
        for _, skill in ipairs(R.SKILLS) do RPSheet:SkillMod(skill); RPSheet:ExplainSkill(skill) end
    end)
    for _, passive in ipairs(sheet.passives) do
        Do(label .. " passive " .. tostring(passive.name), function()
            if type(passive.name) ~= "string" or type(passive.desc) ~= "string" then error("passive name/desc is " .. type(passive.name) .. "/" .. type(passive.desc)) end
            for _, effect in ipairs(passive.effects or {}) do
                local text = RPSheet:EffectText(effect)
                if type(text) ~= "string" then error("EffectText gives " .. type(text)) end
            end
        end)
    end
    -- everything switched on, then the numbers again
    Do(label .. " all on", function()
        local was = {}
        for index, passive in ipairs(sheet.passives) do was[index] = passive.enabled; passive.enabled = true end
        RPSheet:SheetChanged()
        RPSheet:GetStatData(); RPSheet:AC(); RPSheet:MaxHP(); RPSheet:Speed(); RPSheet:ExplainAC(); RPSheet:ExplainSpeed()
        for _, stat in ipairs(R.STATS) do RPSheet:SaveMod(stat); RPSheet:ExplainSave(stat) end
        for index, passive in ipairs(sheet.passives) do passive.enabled = was[index] end
        RPSheet:SheetChanged()
    end)
    for _, ability in ipairs(sheet.abilities) do
        Do(label .. " ability " .. tostring(ability.name), function()
            if type(ability.name) ~= "string" or type(ability.desc) ~= "string" then error("ability name/desc is " .. type(ability.name) .. "/" .. type(ability.desc)) end
            for _, action in ipairs(ability.actions or {}) do
                local text = RPSheet:ActionText(action)
                if type(text) ~= "string" then error("ActionText gives " .. type(text)) end
            end
            RPSheet:UseAbility(ability); FlushTimers()
            RPSheet.busy = false
            RPSheet:UseAbility(ability, "ADV"); FlushTimers()
            RPSheet.busy = false
        end)
    end
    for _, spell in ipairs(sheet.spells) do
        Do(label .. " spell " .. tostring(spell.name), function()
            RPSheet:SpellText(spell); RPSheet:ExplainSpell(spell)
            RPSheet:CastSpell(spell); FlushTimers()
            RPSheet.busy = false
        end)
    end
    Do(label .. " weapons", function()
        for _, name in ipairs({ "Longsword", "Longbow", "Dagger", "Quarterstaff", "Shield", "Chain Mail", "Leather Armor" }) do
            local item = RPSheet:AddItem(name, 1)
            RPSheet:SetEquipped(item, true)
        end
        RPSheet:SheetChanged()
        for index, weapon in ipairs(ns.ReadyWeapons(sheet)) do
            RPSheet:State().weapon = index
            RPSheet:WeaponText(weapon); RPSheet:ExplainWeapon(weapon)
            RPSheet:Attack(); FlushTimers(); RPSheet.busy = false
            RPSheet:Attack("DIS"); FlushTimers(); RPSheet.busy = false
        end
        RPSheet:AC(); RPSheet:ExplainAC(); RPSheet:Speed()
    end)
    Do(label .. " rest", function() RPSheet:ShortRest(); FlushTimers(); RPSheet:LongRest(); FlushTimers() end)
    Do(label .. " options", function()
        ns.RebuildOptions()
        local saved = PROBLEMS
        Feed(mainOptions, "options")
    end)
    RPSheet.busy = false
end

local function Build(key, subclass, spec, level, n)
    local sheet = ns.NewSheet()
    for _, list in ipairs(R.PICK_LIST_ORDER) do sheet.picks[list] = {} end
    sheet.class, sheet.subclass, sheet.spec, sheet.level = key, subclass, spec, level
    sheet.species = R.SPECIES_ORDER[n % #R.SPECIES_ORDER + 1]
    sheet.background = R.BACKGROUND_ORDER[n % #R.BACKGROUND_ORDER + 1]
    sheet.allegiance = R.ALLEGIANCE_ORDER[n % #R.ALLEGIANCE_ORDER + 1]
    local lineages = R.LINEAGES[sheet.species]
    if lineages then sheet.lineage = lineages.options[n % #lineages.options + 1].name end
    sheet.base = { STR = 15, DEX = 14, CON = 13, INT = 12, WIS = 10, CHA = 8 }
    local class = R.CLASSES[key]
    for index = 1, class.skillCount do sheet.skills[class.skills[index]] = 1 end
    return sheet
end

local n = 0
for _, key in ipairs(R.CLASS_ORDER) do
    local class = R.CLASSES[key]
    for subIndex, subclass in ipairs(class.subclasses) do
        for _, level in ipairs(LEVELS) do
            n = n + 1
            local spec = class.specs[n % #class.specs + 1]
            local sub = (level >= 3 or class.hero) and subclass or ""
            local label = ("%s/%s/%s L%d"):format(key, sub, spec, level)
            local sheet = Do(label .. " build", Build, key, sub, spec, level, n)
            if sheet then
                Do(label .. " grants", ns.ApplyGrants, sheet)
                Do(label .. " replace", function() RPSheet:ReplaceSheet(sheet) end)
                Exercise(label)
                -- every choice a feature offers, taken in turn
                Do(label .. " options of features", function()
                    for _, feature in ipairs(ns.OptionFeatures(sheet)) do
                        for _, option in ipairs(feature.options) do
                            sheet.featureOptions[feature.name] = option.name
                            Opt.Regrant()
                        end
                    end
                end)
                Exercise(label .. " +options")
                count = count + 1
            end
        end
    end
end
print("characters", count, "chat lines", #SENT, "printed", #PRINTED)
io.stdout:flush()
for i = 1, #SENT, 601 do print("SENT " .. SENT[i]) end
for i = 1, #PRINTED, 4801 do print("PRINT " .. PRINTED[i]:sub(1, 300)) end
local longest = ""
for _, line in ipairs(SENT) do if #line > #longest then longest = line end end
print(#longest, longest)
io.stdout:flush()
local shown = 0
for i, line in ipairs(PRINTED) do
    if line:find("Couldn't read the roll") and shown < 6 then
        shown = shown + 1
        print("---- at " .. i)
        for j = math.max(1, i - 4), i do print("   " .. PRINTED[j]:sub(1, 260)) end
    end
end
local total = 0
for i, line in ipairs(PRINTED) do if line:find("Couldn't read the roll") then total = total + 1 end end
print("unread rolls", total)
io.stdout:flush()
local same, all = 0, 0
for _, line in ipairs(SENT) do
    for a, b in line:gmatch("advantage: (%d+), (%d+)%]") do
        all = all + 1
        if a == b then same = same + 1 end
    end
end
print("advantage pairs", all, "equal", same)
io.stdout:flush()
SnapDiff(SNAP, Snapshot(R))
io.stdout:flush()
