ROLLDEPTH = 0
function RandomRoll(low, high)
    local ok, err = pcall(function()
        RPSheet:CHAT_MSG_SYSTEM(nil, ("Tester rolls %d (%d-%d)"):format(math.random(low, high), low, high))
    end)
    if not ok then print("ROLL CALLBACK ERROR (" .. tostring(CONTEXT) .. "): " .. tostring(err):gsub("%S*wt%-hunt%-wizard%-data/", "")) end
    if low ~= 1 or high ~= math.floor(high) or high < 1 then print("ODD ROLL (" .. tostring(CONTEXT) .. "): " .. tostring(low) .. "-" .. tostring(high)) end
end
local Kit = ns.FeatureKit
local LEVELS = { 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 13, 14, 15, 17, 18, 20 }
if ARG4 == "quick" then LEVELS = { 1, 3, 5, 11, 20 } end
local count = 0
local function Top(err) return tostring(err) end
local seenProblems = {}
function Do(label, fn, ...)
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

function Exercise(label)
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

