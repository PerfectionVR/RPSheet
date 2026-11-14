-- Reads resistances, immunities and vulnerabilities from the wording of a passive the
-- player wrote: "resistance to fire damage", "immune to poison and cold damage",
-- "vulnerable to all damage except force", "can't be charmed".
-- Rules data never goes through here: its features name their types outright, because
-- wording misleads ("your spells ignore the target's resistance to cold damage").
local _, ns = ...
local R = ns.Rules

local PATTERNS = {
    resist = "resist%a*%s+t?o?%s*([%a%s,]-) damage",
    immune = "immun%a*%s+to%s+([%a%s,]-) damage",
    vulnerable = "vulnerab%a*%s+to%s+([%a%s,]-) damage",
}
-- A sentence with one of these is about someone else's defenses.
local NOT_MINE = { "ignor", "target", "enem", "attacker", "bypass", "overcom" }
local CONDITION_PATTERNS = { "immun%a*%s+to%s+([%a%s,]-) condition", "can't be ([%a%s,]+)", "cannot be ([%a%s,]+)" }

local conditionNames
local function ConditionName(word)
    if not conditionNames then
        conditionNames = {}
        for _, condition in ipairs(R.CONDITIONS) do conditionNames[condition.name:lower()] = condition.name end
        conditionNames.concentrating = nil -- tracked like a condition, but not one
    end
    return conditionNames[word]
end

-- The damage types a phrase names. "all" is every type, less the ones the sentence
-- lists after "except" or "but".
local function Types(phrase, clause)
    local list = {}
    if phrase:find("%f[%a]all%f[%A]") or phrase:find("%f[%a]every%f[%A]") then
        local skip = {}
        local exceptions = clause:match("except(.*)$") or clause:match("%f[%a]but%f[%A](.*)$") or ""
        for word in exceptions:gmatch("%a+") do skip[word] = true end
        for _, name in ipairs(R.DAMAGE_TYPES) do
            if not skip[name] then list[#list + 1] = name end
        end
        return list
    end
    for word in phrase:gmatch("%a+") do
        if R.DAMAGE_TYPE[word] then list[#list + 1] = word end
    end
    return list
end

-- Calls visit(field, name) for everything the text grants: field is "resist",
-- "immune", "vulnerable" or "conditionImmune".
function ns.ReadDefenses(text, visit)
    for clause in text:lower():gmatch("[^%.;:!%?\n]+") do
        local theirs = false
        for _, word in ipairs(NOT_MINE) do
            theirs = theirs or clause:find(word, 1, true) ~= nil
        end
        if not theirs then
            for field, pattern in pairs(PATTERNS) do
                for phrase in clause:gmatch(pattern) do
                    for _, name in ipairs(Types(phrase, clause)) do visit(field, name) end
                end
            end
            for _, pattern in ipairs(CONDITION_PATTERNS) do
                for phrase in clause:gmatch(pattern) do
                    for word in phrase:gmatch("%a+") do
                        if ConditionName(word) then visit("conditionImmune", ConditionName(word)) end
                    end
                end
            end
        end
    end
end
