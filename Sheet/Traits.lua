-- Species traits that need more than a passive (data in Data/Traits.lua):
--   * a trait with uses or dice is a clickable ability, marked auto = "trait:<name>",
--     with a bar of the same name when it has uses;
--   * a trait with a choice stores it in sheet.traitChoices[<name>]; a chosen skill is
--     made proficient (remembered in sheet.traitGranted so it can be taken back), a
--     chosen feat is a passive marked auto = "trait:<name>".
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local PREFIX = "trait:"

-- The species' traits that Data/Traits.lua knows, as { name = data }, for a sheet or
-- a wizard draft (anything with a `species` field).
local function Traits(character)
    local species, found = R.SPECIES[character.species], {}
    for _, name in ipairs(species and species.traits or {}) do
        if R.TRAITS[name] then found[name] = R.TRAITS[name] end
    end
    return found
end

-- Names of the traits that ask for a choice, in the species' own order.
function ns.TraitChoices(character)
    local species, names = R.SPECIES[character.species], {}
    for _, name in ipairs(species and species.traits or {}) do
        if R.TRAITS[name] and R.TRAITS[name].choice then names[#names + 1] = name end
    end
    return names
end

-- True if the character has a trait with this field set (e.g. "hitDieMax").
function RPSheet:TraitValue(field)
    local total
    for _, trait in pairs(Traits(self:Sheet())) do
        if trait[field] == true then return true end
        if type(trait[field]) == "number" then total = (total or 0) + trait[field] end
    end
    return total
end

-- Bars for traits with uses, in the same form as class `pools`.
function ns.TraitPools(sheet)
    local pools = {}
    for name, trait in pairs(Traits(sheet)) do
        if trait.uses and sheet.level >= (trait.level or 1) and not sheet.dismissed[PREFIX .. name] then
            local pool = { name = name, from = trait.level or 1, short = trait.short }
            if trait.uses == "PROF" then pool.prof = true else pool.steps = { { pool.from, trait.uses } } end
            pools[#pools + 1] = pool
        end
    end
    table.sort(pools, function(a, b) return a.name < b.name end)
    return pools
end

local function FindAuto(list, key)
    for index, entry in ipairs(list) do
        if entry.auto == key then return entry, index end
    end
end

---------------------------------------------------------------------------
-- Choices
---------------------------------------------------------------------------
-- What can be picked for a trait: skills the character isn't proficient in yet, or
-- origin feats it doesn't have. The current pick is always included.
-- `free` lists everything, for the Customize page.
function ns.TraitOptions(sheet, name, free)
    local trait, current, names = R.TRAITS[name], sheet.traitChoices[name], {}
    if trait.choice == "SKILL" then
        local pool = trait.options
        if not pool then
            pool = {}
            for _, skill in ipairs(R.SKILLS) do pool[#pool + 1] = skill.name end
        end
        for _, skill in ipairs(pool) do
            if free or skill == current or (sheet.skills[skill] or 0) == 0 then names[#names + 1] = skill end
        end
    else
        local key = PREFIX .. name
        for _, feat in ipairs(R.FEAT_NAMES.GENERAL) do
            if R.FEATS[feat].kind == "ORIGIN" then
                local taken = false
                for _, passive in ipairs(sheet.passives) do
                    taken = taken or (passive.name == feat and passive.auto ~= key)
                end
                local allowed = not R.FEATS[feat].needSpecies or R.FEATS[feat].needSpecies == sheet.species
                if free or feat == current or (allowed and (R.FEATS[feat].repeatable or not taken)) then names[#names + 1] = feat end
            end
        end
    end
    return names
end

-- Traits whose choice hasn't been made.
function ns.OpenTraitChoices(sheet)
    local open = {}
    for _, name in ipairs(ns.TraitChoices(sheet)) do
        if (sheet.traitChoices[name] or "") == "" then open[#open + 1] = name end
    end
    return open
end

local function ApplyChoice(sheet, name, trait)
    local choice = sheet.traitChoices[name] or ""
    if trait.choice == "SKILL" then
        local granted = sheet.traitGranted[name]
        if granted and granted ~= choice then
            -- The earlier pick is given up, unless it has since become expertise.
            if sheet.skills[granted] == 1 then sheet.skills[granted] = nil end
            sheet.traitGranted[name] = nil
        end
        if choice ~= "" and (sheet.skills[choice] or 0) == 0 then
            sheet.skills[choice], sheet.traitGranted[name] = 1, choice
        end
    else
        local key = PREFIX .. name
        local passive, index = FindAuto(sheet.passives, key)
        local feat = R.FEATS[choice]
        if feat then
            local changed = not passive or passive.name ~= choice
            if not passive then
                passive = { auto = key, enabled = true }
                sheet.passives[#sheet.passives + 1] = passive
            end
            passive.name = choice
            passive.desc = ("Origin feat from %s. %s"):format(name, feat.desc)
            if changed then passive.effects = CopyTable(feat.effects or {}) end
        elseif passive then
            table.remove(sheet.passives, index)
        end
    end
end

---------------------------------------------------------------------------
-- Putting traits on the sheet
---------------------------------------------------------------------------
-- Called whenever what the species grants is refreshed (see Wizard/Grants.lua).
function ns.ApplyTraits(sheet)
    local traits = Traits(sheet)

    -- Abilities and feats of traits the character no longer has are taken off, and
    -- skills they granted are given back.
    for _, list in ipairs({ sheet.abilities, sheet.passives }) do
        for index = #list, 1, -1 do
            local name = (list[index].auto or ""):match("^" .. PREFIX .. "(.+)$")
            if name and not (traits[name] and sheet.level >= (traits[name].level or 1)) then
                table.remove(list, index)
            end
        end
    end
    for name, skill in pairs(sheet.traitGranted) do
        if not traits[name] then
            if sheet.skills[skill] == 1 then sheet.skills[skill] = nil end
            sheet.traitGranted[name], sheet.traitChoices[name] = nil, nil
        end
    end

    for name, trait in pairs(traits) do
        local key = PREFIX .. name
        if trait.choice then
            ApplyChoice(sheet, name, trait)
            -- The reminder passive says what was picked.
            for _, passive in ipairs(sheet.passives) do
                if passive.name == name and (passive.auto or "") == "" then
                    local choice = sheet.traitChoices[name] or ""
                    passive.desc = choice ~= "" and ("%s Chosen: %s."):format(ns.Glossary[name] or "", choice)
                        or ("%s Not chosen yet: pick it under Customize, Lineage, languages, renown."):format(ns.Glossary[name] or "")
                end
            end
        elseif R.TraitIsAbility(name) and sheet.level >= (trait.level or 1) and not sheet.dismissed[key] then
            local ability = FindAuto(sheet.abilities, key)
            if not ability then
                ability = { name = name, auto = key }
                sheet.abilities[#sheet.abilities + 1] = ability
            end
            local actions = trait.actions
            if type(actions) == "function" then actions = actions(sheet.level) end
            ability.actions = CopyTable(actions or {})
            if trait.uses then table.insert(ability.actions, 1, ns.FeatureKit.Spend(name)) end
            ability.desc = trait.desc or ns.Glossary[name] or ""
            -- A passive that goes with it, such as a form the ability switches on.
            if trait.passive then
                local passive = FindAuto(sheet.passives, key)
                if not passive then
                    passive = { auto = key, enabled = not trait.passive.startsOff }
                    sheet.passives[#sheet.passives + 1] = passive
                end
                passive.name, passive.desc = trait.passive.name, trait.passive.desc
                passive.effects = CopyTable(trait.passive.effects or {})
            end
            -- An earlier version listed it as a plain passive.
            for index = #sheet.passives, 1, -1 do
                local passive = sheet.passives[index]
                if passive.name == name and (passive.auto or "") == "" then table.remove(sheet.passives, index) end
            end
        end
    end
end
