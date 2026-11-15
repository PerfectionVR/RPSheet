-- The addon's origin data against the rules site: species and lineages, backgrounds,
-- feats and what they let you choose, starting gear, conditions, renown tiers,
-- factions and languages. The site's facts are in tests/data/ (see t-conform-lib.lua).
dofile(ARG3 .. "/t-conform-lib.lua")

---------------------------------------------------------------------------
-- Deliberate differences, each with its reason
---------------------------------------------------------------------------
Allow("background/Scribe/gear", "the site's structured list drops the counts; its own text says Oil (3 flasks) and Parchment (12 sheets), which is what the addon hands out")
Allow("classgear/Druid/1", "the druidic focus is handed out as a Quarterstaff, which is the wooden-staff focus and a weapon the sheet can ready")
Allow("feat/Ability Score Improvement/missing", "raising scores is the level dialog's own choice, not a feat in the list")
Allow("condition/Exhaustion/missing", "exhaustion is counted in levels of its own (Rules.MAX_EXHAUSTION), not ticked like a condition")
Allow("condition/Concentrating/extra", "the site lists Concentration as a status; the sheet tracks it beside the conditions")
Allow("status/Surprised", "being surprised is the DM's call at the start of a fight; the sheet has nothing to track")

local function Title(text)
    return (text:gsub("(%a)([%w']*)", function(first, rest) return first:upper() .. rest end))
end

---------------------------------------------------------------------------
-- Species and lineages
---------------------------------------------------------------------------
local speciesByName = {}
for key, species in pairs(R.SPECIES) do speciesByName[species.name] = key end
local siteSpecies, siteLineages, counts = {}, {}, { species = 0, lineages = 0 }

for _, row in ipairs(ReadData("species.txt")) do
    local name = row[2]
    if row[1] == "species" then
        siteSpecies[name] = true
        counts.species = counts.species + 1
        local species = R.SPECIES[speciesByName[name] or ""]
        if species then
            local key = "species/" .. name .. "/"
            Same(key .. "size", Sorted(species.sizes), Sorted(row.size))
            Same(key .. "speed", "walk=" .. species.speed, row.speed)
            Same(key .. "darkvision", species.darkvision or 0, row.dv)
            Same(key .. "traits", Sorted(species.traits), Sorted((row.traits:gsub("Darkvision,?", ""))))
            -- What the species resists whatever its lineage: from its traits.
            local resists = {}
            for _, trait in ipairs(species.traits) do
                for _, kind in ipairs(R.TRAITS[trait] and R.TRAITS[trait].resist or {}) do resists[#resists + 1] = kind end
            end
            Same(key .. "resist", Sorted(resists), row.resist:find("choose:") and "" or Sorted(row.resist))
            -- Skills: fixed ones on the species, a choice in a trait.
            local fixed, choice = {}, nil
            for part in row.skills:gmatch("[^,]+") do
                if part:find("^choose:") then choice = Sorted(part:sub(8), "/")
                elseif part:find("^any:") then choice = "any"
                else fixed[#fixed + 1] = part end
            end
            Same(key .. "skills", Sorted(species.skills), Sorted(fixed))
            if choice then
                local found = "none"
                for _, trait in ipairs(species.traits) do
                    local data = R.TRAITS[trait]
                    if data and data.choice == "SKILL" then found = data.options and Sorted(data.options) or "any" end
                end
                Same(key .. "skill choice", found, choice)
            end
            Same(key .. "spells", Sorted(species.spells), Sorted({ row.spell3 ~= "" and row.spell3 or nil, row.spell5 ~= "" and row.spell5 or nil }))
        end
    else
        local speciesName, key = row[2], "lineage/" .. row[2] .. "/" .. row[3] .. "/"
        siteLineages[speciesName .. "/" .. row[3]] = true
        counts.lineages = counts.lineages + 1
        local _, option = R.Lineage(speciesByName[speciesName] or "", row[3])
        if option then
            Same(key .. "darkvision", option.darkvision or "", row.dv)
            Same(key .. "resist", Sorted(option.resist), Sorted(row.resist))
            Same(key .. "skills", Sorted(option.skills), Sorted(row.skills))
            Same(key .. "spells", Sorted(option.spells), Sorted({ row.spell3 ~= "" and row.spell3 or nil, row.spell5 ~= "" and row.spell5 or nil }))
            -- The cantrip is only in the wording: it has to be named there.
            if row.cantrip ~= "" and not row.cantrip:find("^choose") then
                COMPARED = COMPARED + 1
                if not option.desc:lower():find(row.cantrip, 1, true) then Differ(key .. "cantrip", "the description doesn't name " .. row.cantrip) end
            end
        end
    end
end
local addonLineages = {}
for key, lineages in pairs(R.LINEAGES) do
    for _, option in ipairs(lineages.options) do addonLineages[R.SPECIES[key].name .. "/" .. option.name] = true end
end
BothWays("species", siteSpecies, speciesByName)
BothWays("lineage", siteLineages, addonLineages)

---------------------------------------------------------------------------
-- Starting gear, shared by backgrounds and classes
---------------------------------------------------------------------------
local SITE_CHOICE = {
    ["holy symbol"] = "choice:HOLY", ["type:toolArtisan"] = "choice:ARTISAN", ["type:instrumentMusical"] = "choice:INSTRUMENT",
    ["type:setGaming"] = "choice:GAMING", ["type:instrumentMusical/toolArtisan"] = "choice:CRAFT",
}
-- The site's "a;b*2;cp:800" as sorted "a,b*2" and the copper left over.
local function SiteGear(text)
    local parts, copper = {}, 0
    for entry in text:gmatch("[^;]+") do
        if entry:find("^cp:") then copper = tonumber(entry:sub(4))
        else
            local name, count = entry:match("^(.-)%*(%d+)$")
            name = SITE_CHOICE[name or entry] or (name or entry):lower()
            parts[#parts + 1] = name .. ((tonumber(count) or 1) > 1 and ("*" .. count) or "")
        end
    end
    table.sort(parts)
    return table.concat(parts, ","), copper
end
local function AddonGear(set)
    local parts = {}
    for entry in set.items:gmatch("[^;]+") do
        local name, count = entry:match("^(.-)%*(%d+)$")
        name = strtrim(name or entry)
        if not R.ITEMS[name] then Differ("gear item/" .. name, "a starting set names it, the item lists don't have it") end
        parts[#parts + 1] = name:lower() .. (count and ("*" .. count) or "")
    end
    for _, choice in ipairs(set.choices or {}) do parts[#parts + 1] = "choice:" .. choice.kind end
    table.sort(parts)
    return table.concat(parts, ","), set.gold * 100
end
local function SameGear(key, set, siteText)
    local items, copper = AddonGear(set)
    local siteItems, siteCopper = SiteGear(siteText)
    Same(key, items .. " + " .. copper .. " cp", siteItems .. " + " .. siteCopper .. " cp")
end

---------------------------------------------------------------------------
-- Backgrounds
---------------------------------------------------------------------------
local TOOL_CHOICE = { anyArtisansTool = "one kind of artisan's tools", anyMusicalInstrument = "one musical instrument", anyGamingSet = "one gaming set" }
local backgroundByName, siteBackgrounds = {}, {}
for key, background in pairs(R.BACKGROUNDS) do backgroundByName[background.name] = key end
for _, row in ipairs(ReadData("backgrounds.txt")) do
    local name = row[2]
    siteBackgrounds[name] = true
    local id = backgroundByName[name]
    local background = R.BACKGROUNDS[id or ""]
    if background then
        local key = "background/" .. name .. "/"
        Same(key .. "stats", Sorted(background.stats), Sorted(row.stats))
        Same(key .. "skills", Sorted(background.skills), Sorted(row.skills))
        local feat, list = row.feat:match("^(.-); (.+)$")
        Same(key .. "feat", background.feat:lower(), feat and ("%s (%s)"):format(feat, list) or row.feat)
        COMPARED = COMPARED + 1
        if not R.FEATS[(background.feat:gsub(" %(.+%)$", ""))] then Differ(key .. "feat known", background.feat .. " is not in the feat list") end
        if TOOL_CHOICE[row.tool] then
            Same(key .. "tool", R.BACKGROUND_TOOL_CHOICE[id] or (R.BACKGROUND_TOOLS[id] or "none"), TOOL_CHOICE[row.tool])
        else
            Same(key .. "tool", (R.BACKGROUND_TOOLS[id] or R.BACKGROUND_TOOL_CHOICE[id] or "none"):lower(), row.tool)
        end
        if R.BACKGROUND_GEAR[id] then SameGear(key .. "gear", R.BACKGROUND_GEAR[id], row.A)
        else Differ(key .. "gear", "no starting set") end
        Same(key .. "gold instead", R.BACKGROUND_GOLD * 100, row.B:match("^cp:(%d+)$"))
    end
end
BothWays("background", siteBackgrounds, backgroundByName)
for id in pairs(R.BACKGROUND_GEAR) do
    if not R.BACKGROUNDS[id] then Differ("background gear/" .. id, "a starting set for a background that doesn't exist") end
end

---------------------------------------------------------------------------
-- Class gear and the rest of the smaller lists
---------------------------------------------------------------------------
local misc = { condition = {}, status = {}, tier = {}, faction = {}, language = {}, proflevel = {}, classgear = {} }
for _, row in ipairs(ReadData("misc.txt")) do
    if misc[row[1]] then table.insert(misc[row[1]], row) end
end

local siteClasses = {}
for _, row in ipairs(misc.classgear) do
    local class = row[2]
    siteClasses[class] = true
    local sets, options = R.CLASS_GEAR[class] or {}, {}
    for _, letter in ipairs({ "A", "B", "C" }) do if row[letter] then options[#options + 1] = row[letter] end end
    Same("classgear/" .. class .. "/sets", #sets, #options - 1)
    for index = 1, #options - 1 do
        if sets[index] then SameGear(("classgear/%s/%d"):format(class, index), sets[index], options[index]) end
    end
    Same("classgear/" .. class .. "/gold instead", (R.START_GOLD[class] or 0) * 100, options[#options]:match("^cp:(%d+)$"))
end
BothWays("classgear", siteClasses, R.CLASS_GEAR)
BothWays("class gold", siteClasses, R.START_GOLD)

-- Conditions
local siteConditions, addonConditions = {}, {}
for _, row in ipairs(misc.condition) do siteConditions[row[2]] = true end
for _, condition in ipairs(R.CONDITIONS) do addonConditions[condition.name] = true end
COMPARED = COMPARED + #misc.condition
BothWays("condition", siteConditions, addonConditions)
for _, row in ipairs(misc.status) do
    COMPARED = COMPARED + 1
    local known = (row[2] == "Concentration" and addonConditions.Concentrating) or (row[2] == "Bloodied" and R.BLOODIED ~= nil)
        or (ns.Glossary or R.GLOSSARY or {})[row[2]] ~= nil
    if not known then Differ("status/" .. row[2], "the sheet has no word for it") end
end

-- Renown tiers, factions, languages
for _, row in ipairs(misc.tier) do
    local score
    for _, tier in ipairs(R.RENOWN_TIERS) do if tier[2] == row[2] then score = tier[1] end end
    Same("renown tier/" .. row[2], score or "none", row[3])
    COMPARED = COMPARED + 1
    if R.RenownTier(tonumber(row[3])) ~= row[2] or R.RenownTier(tonumber(row[3]) - 1) == row[2] then
        Differ("renown tier/" .. row[2] .. "/reached", "not reached at exactly " .. row[3])
    end
    if not R.RENOWN_PERKS[row[2]] then Differ("renown tier/" .. row[2] .. "/perk", "no general perk") end
end
Same("renown tiers", #R.RENOWN_TIERS, #misc.tier)
local siteFactions, addonFactions = {}, {}
for _, row in ipairs(misc.faction) do
    -- One heading on the site, two rival factions in play.
    for name in row[3]:gmatch("[^/]+") do siteFactions[row[2] .. "/" .. name] = true end
end
for group, list in pairs(R.FACTIONS) do
    for _, name in ipairs(list) do addonFactions[group .. "/" .. name] = true end
end
COMPARED = COMPARED + #misc.faction
BothWays("faction", siteFactions, addonFactions)
local siteLanguages, addonLanguages = {}, {}
for _, row in ipairs(misc.language) do siteLanguages[row[2] .. "/" .. row[3]] = true end
for group, list in pairs(R.LANGUAGES) do
    for _, name in ipairs(list) do addonLanguages[group .. "/" .. name] = true end
end
COMPARED = COMPARED + #misc.language
BothWays("language", siteLanguages, addonLanguages)
for _, row in ipairs(misc.proflevel) do
    local level = R.PROFESSION_LEVELS[tonumber(row[2])] or {}
    Same("profession level/" .. row[2] .. "/name", level.name, row[3])
    Same("profession level/" .. row[2] .. "/rarity", (level.rarity or ""):lower(), row[4]:lower())
end

---------------------------------------------------------------------------
-- Feats
---------------------------------------------------------------------------
local KIND = { O = "ORIGIN", G = "GENERAL", EB = "BOON" }
local function SiteNeed(pre)
    local any, parts = {}, {}
    for option in (pre .. " OR "):gmatch("(.-) OR ") do
        for token in option:gmatch("%S+") do
            local all = token:match("^abil:(.+&.+)$")
            local one = not all and token:match("^abil:(%a+)%d+$")
            if all then parts["all:" .. Sorted((all:gsub("%d+", "")), "&")] = true
            elseif one then any[#any + 1] = one
            elseif not token:find("^L%d+$") then
                parts[token:gsub("^prof:armor:", "armor:"):gsub("^race:", "species:")] = true
            end
        end
    end
    if #any > 0 then parts["any:" .. Sorted(any)] = true end
    return Keys(parts)
end
local function AddonNeed(feat)
    local parts = {}
    if feat.needStats then parts["any:" .. Sorted(feat.needStats)] = true end
    if feat.needAllStats then parts["all:" .. Sorted(feat.needAllStats)] = true end
    if feat.needTraining then parts["armor:" .. feat.needTraining] = true end
    if feat.needCaster then parts["caster"] = true end
    if feat.needSpecies then parts["species:" .. R.SPECIES[feat.needSpecies].name:lower()] = true end
    if feat.needTools then parts["tools"] = true end
    return Keys(parts)
end

local siteFeats, siteStyles, featCount = {}, {}, 0
for _, row in ipairs(ReadData("feats.txt")) do
    local name, key = row[2], "feat/" .. row[2] .. "/"
    featCount = featCount + 1
    if row.cat:find("^FS") then
        siteStyles[name] = true
        local style = R.FIGHTING_STYLES[name]
        if style then
            local owner = row.cat == "FS:P" and "Paladin" or (row.cat == "FS:R" and row[3] == "XPHB" and "Ranger") or nil
            Same("style/" .. name .. "/class", style.base or "", owner or "")
        end
    else
        siteFeats[name] = true
        local feat = R.FEATS[name]
        if feat then
            Same(key .. "kind", feat.kind, KIND[row.cat] or row.cat)
            Same(key .. "raises", Sorted(feat.stats), Sorted(row.abil, "/"))
            Same(key .. "repeatable", feat.repeatable and 1 or 0, row.rep)
            Same(key .. "level", (feat.kind == "GENERAL" and "L4") or (feat.kind == "BOON" and "L19") or "", row.pre:match("L%d+") or "")
            local need = SiteNeed(row.pre)
            -- Proficiency with one of several tools: their names have spaces, so they are
            -- compared apart from the other needs.
            local tools = {}
            for tool in (row.pre:match("prof:(tool:.+)$") or ""):gmatch("tool:([^/]+)") do tools[#tools + 1] = tool:lower() end
            if #tools > 0 then need = "tools" end
            Same(key .. "need", AddonNeed(feat), need)
            local mine = {}
            for _, tool in ipairs(feat.needTools or {}) do mine[#mine + 1] = tool:lower() end
            Same(key .. "tools", Sorted(mine), Sorted(tools))
        end
    end
end
BothWays("feat", siteFeats, R.FEATS)
BothWays("style", siteStyles, R.FIGHTING_STYLES)

-- What a feat lets you choose, and the spells it gives.
local choiceCount = 0
for _, row in ipairs(ReadData("feat-choices.txt")) do
    local feat = R.FEATS[row[2]] or {}
    choiceCount = choiceCount + 1
    if row[1] == "featchoice" then
        -- The first choice whose options are a fixed list of names (not abilities).
        local found = "none"
        for _, choice in ipairs(feat.choices or {}) do
            if type(choice.from) == "table" and choice.key ~= "ability" and found == "none" then found = Sorted(choice.from) end
        end
        Same("feat/" .. row[2] .. "/choices", found, Sorted(row[3], ";"))
    else
        local spells = {}
        for _, spell in ipairs(feat.spells or {}) do
            spells[#spells + 1] = spell.name .. (spell.level and ("@" .. spell.level) or "")
        end
        Same("feat/" .. row[2] .. "/spells", Sorted(spells), Sorted(row[3], ";"))
    end
end

print(("compared: %d species, %d lineages, %d backgrounds, %d class gear sets, %d feats and styles, %d feat choice lists, %d conditions, %d tiers, %d factions, %d languages")
    :format(counts.species, counts.lineages, #R.BACKGROUND_ORDER, #misc.classgear, featCount, choiceCount, #misc.condition, #misc.tier, #misc.faction, #misc.language))
Finish("origin")
