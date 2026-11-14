-- What the choices made for feats (Sheet/FeatChoices.lua) do to the sheet: skills
-- become proficient or expert, tools proficient, and the feat's text says what was
-- picked (a resistance picked there is read from that text, see Sheet/Senses.lua).
-- Its spells are in Sheet/FeatSpells.lua.
--   sheet.featGranted[<skill>] = ranks (1 or 2) these choices added to the skill
local _, ns = ...
local R = ns.Rules

local MARK = "Your choices: "

-- A picked skill goes up one rank (proficiency, or expertise on top of proficiency
-- from elsewhere); a feat that trains every skill makes each at least proficient.
-- What an earlier pick added is taken back first.
local function ApplySkills(sheet, instances)
    local want, all = {}, false
    for _, instance in ipairs(instances) do
        all = all or instance.feat.allSkills == true
        ns.EachFeatPick(sheet.featChoices, instance, "skill", function(value) want[value] = (want[value] or 0) + 1 end)
    end
    for _, skill in ipairs(R.SKILLS) do
        local name = skill.name
        local rank, mine = sheet.skills[name] or 0, sheet.featGranted[name] or 0
        if mine > 0 or want[name] or all then
            local other = math.max(0, rank - mine)
            local target = math.min(2, math.max(other, all and 1 or 0) + (want[name] or 0))
            sheet.skills[name] = target > 0 and target or nil
            sheet.featGranted[name] = target > other and (target - other) or nil
        end
    end
end

-- A picked tool stands in for a tick made by hand.
local function ApplyTools(sheet, instances)
    for _, instance in ipairs(instances) do
        ns.EachFeatPick(sheet.featChoices, instance, "tool", function(value) sheet.tools[value] = nil end)
    end
end

-- "Cold and Fire", "Acid, Cold and Fire"
local function Listed(values)
    if #values < 2 then return values[1] or "" end
    return table.concat(values, ", ", 1, #values - 1) .. " and " .. values[#values]
end

-- The feat's passive says what was picked and what is still open. The line is put
-- behind the feat's own text and replaced each time.
local function Describe(sheet, instances)
    for _, instance in ipairs(instances) do
        local passive = instance.passive
        if passive and instance.feat.choices then
            local picks = sheet.featChoices[instance.id].picks
            local made, open = {}, {}
            for _, choice in ipairs(instance.feat.choices) do
                local count, values = ns.FeatChoiceCount(choice, sheet.level), {}
                for index = 1, count do
                    if picks[choice.key][index] then values[#values + 1] = picks[choice.key][index] end
                end
                if #values > 0 then
                    made[#made + 1] = choice.text and choice.text:format(Listed(values))
                        or ("%s: %s"):format(choice.title, table.concat(values, ", "))
                end
                if #values < count then open[#open + 1] = choice.title:lower() end
            end
            local text = MARK .. (#made > 0 and table.concat(made, "; ") or "none yet") .. "."
            if #open > 0 then
                text = ("%s Still to choose: %s. Use \"Class and feat choices\" on the Character tab."):format(text, table.concat(open, ", "))
            end
            local own = (passive.desc or ""):gsub("%s*" .. MARK .. ".*$", "")
            passive.desc = own ~= "" and (own .. " " .. text) or text
        end
    end
end

-- Sheet upkeep (see Sheet/ClassFeatures.lua and Wizard/Grants.lua).
function ns.ApplyFeatChoices(sheet)
    if type(sheet.featChoices) ~= "table" then sheet.featChoices = {} end
    if type(sheet.featGranted) ~= "table" then sheet.featGranted = {} end
    if type(sheet.tools) ~= "table" then sheet.tools = {} end
    local instances = ns.FeatInstances(sheet)
    ns.NormalizeFeatChoices(sheet.featChoices, instances, sheet.level)
    ApplySkills(sheet, instances)
    ApplyTools(sheet, instances)
    Describe(sheet, instances)
end

-- True if a tool is one picked for a feat the character has.
function ns.FeatTool(sheet, name)
    local found = false
    for _, instance in ipairs(ns.FeatInstances(sheet)) do
        ns.EachFeatPick(sheet.featChoices, instance, "tool", function(value) found = found or value == name end)
    end
    return found
end
