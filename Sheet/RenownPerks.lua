-- Puts a faction's own renown perks on the sheet (data in Data/FactionPerks.lua) while
-- the renown score is high enough, and takes them off when it drops. A perk's passive
-- or ability is marked auto = "renown:<faction>:<tier>"; deleting one in the editor
-- keeps it away, like a class feature. What a trainer taught is in Sheet/RenownTraining.lua.
local _, ns = ...
local R = ns.Rules

local PREFIX = "renown:"

-- Calls visit(key, faction, tier, grant, perk) for every perk the character has reached
-- that the sheet can apply, lowest tier first.
local function EachGrant(sheet, visit)
    for _, faction in ipairs(R.ALL_FACTIONS) do
        local score, perks = ns.RenownScore(sheet, faction), R.FACTION_PERKS[faction]
        for index = #R.RENOWN_TIERS, 1, -1 do
            local need, tier = R.RENOWN_TIERS[index][1], R.RENOWN_TIERS[index][2]
            local perk = perks and perks[tier]
            local key = PREFIX .. faction .. ":" .. tier
            if perk and perk.grant and score >= need and not sheet.dismissed[key] then
                visit(key, faction, tier, perk.grant, perk)
            end
        end
    end
end

local FindAuto = ns.Util.FindAuto

-- Bars for the perks with uses, in the same form as class `pools`.
function ns.RenownPools(sheet)
    local pools = {}
    if type(sheet.renown) ~= "table" then return pools end
    EachGrant(sheet, function(_, _, _, grant)
        if grant.uses then pools[#pools + 1] = { name = grant.name, from = 1, steps = { { 1, grant.uses } } } end
    end)
    return pools
end

local function Apply(sheet, key, faction, tier, grant, perk)
    local isAbility = grant.kind == "ability"
    local list = isAbility and sheet.abilities or sheet.passives
    local entry = FindAuto(list, key)
    if not entry then
        entry = { auto = key }
        if not isAbility then entry.enabled = not grant.startsOff end
        list[#list + 1] = entry
    end
    entry.name = grant.name
    entry.desc = ("%s with %s. %s"):format(tier, faction, grant.desc or perk.text)
    if isAbility then
        entry.actions = grant.uses and { ns.FeatureKit.Spend(grant.name) } or {}
    else
        entry.effects = CopyTable(grant.effects or {})
        entry.advantage = grant.advantage and CopyTable(grant.advantage) or nil
        -- Damage types and conditions a blessing protects from (Sheet/Defenses.lua reads them).
        for _, field in ipairs({ "resist", "immune", "conditionImmune" }) do
            entry[field] = grant[field] and CopyTable(grant[field]) or nil
        end
    end
    -- A blessing raises a score only as far as its own ceiling.
    for stat, points in pairs(grant.scores or {}) do
        local own = (sheet.base[stat] or 10) + (sheet.bonus[stat] or 0) + (sheet.asi[stat] or 0)
        local gain = math.max(0, math.min(points, (grant.scoreMax or 25) - own))
        if gain > 0 then sheet.featureScores[stat] = (sheet.featureScores[stat] or 0) + gain end
    end
end

-- Sheet upkeep, called at the end of ns.ApplyClassFeatures (Sheet/ClassFeatures.lua)
-- and nowhere else: that has just worked out sheet.featureScores afresh, so the points
-- added here are never counted twice.
function ns.ApplyRenownPerks(sheet)
    for _, key in ipairs({ "renown", "dismissed", "featureScores" }) do
        if type(sheet[key]) ~= "table" then sheet[key] = {} end
    end
    ns.NoteRenownReached(sheet) -- before the scores are read: one faction's tier can raise another's score
    local current = {}
    EachGrant(sheet, function(key) current[key] = true end)

    -- Perks of a tier the character no longer has are taken off the sheet.
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for index = #list, 1, -1 do
            local auto = list[index].auto or ""
            if auto:find("^" .. PREFIX) and not current[auto] then table.remove(list, index) end
        end
    end
    EachGrant(sheet, function(key, faction, tier, grant, perk) Apply(sheet, key, faction, tier, grant, perk) end)
    ns.ApplyRenownTraining(sheet)
end
