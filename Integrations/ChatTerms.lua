-- What a rule term in chat means: the title and lines of the tooltip a marked term
-- shows when it is hovered (Integrations/ChatLinks.lua), from the rules data everyone
-- with the addon has.
local _, ns = ...
local R = ns.Rules

local function WeaponInfo(term, weapon)
    local lines = { ("%s weapon, %s."):format(weapon.category == "SIMPLE" and "Simple" or "Martial", R.WeaponSummary(term)) }
    for _, prop in ipairs(R.WEAPON_PROPERTY_ORDER) do
        if weapon.props[prop] then
            lines[#lines + 1] = ("%s: %s"):format(R.WEAPON_PROPERTIES[prop].name, R.WEAPON_PROPERTIES[prop].desc)
        end
    end
    lines[#lines + 1] = ("Mastery, %s: %s"):format(weapon.mastery, R.MASTERIES[weapon.mastery].desc)
    return term, lines
end

-- A tool, kit, instrument or gaming set (a check with it is announced by its name).
local function ToolInfo(term, tool)
    local item = R.ITEMS[term]
    local lines = { ("%s."):format(R.TOOL_KINDS[tool.kind] or "Tool") }
    if item and (item.desc or "") ~= "" then
        lines[#lines + 1] = item.desc
    elseif R.STAT_NAMES[tool.stat] then
        lines[#lines + 1] = ("Checks with it use %s."):format(R.STAT_NAMES[tool.stat])
    end
    return term, lines
end

-- An item of the catalogue: what kind it is, what it costs and weighs, what it does.
local function ItemInfo(term, item)
    local head
    if item.rarity and item.rarity ~= "" then
        head = ("Magic item, %s%s"):format(item.rarity:lower(), item.attune and ", needs attunement" or "")
    else
        head = item.kind or "Item"
    end
    local summary = R.ItemSummary(item.cost, item.weight)
    local lines = { head .. (summary ~= "" and (", " .. summary) or "") .. "." }
    if (item.desc or "") ~= "" then lines[#lines + 1] = item.desc end
    return term, lines
end

-- Returns a title and a list of lines, or nil for a term the rules data doesn't know
-- (a player's own ability, for instance).
function ns.TermInfo(term)
    if R.MASTERIES[term] then return term, { "Weapon mastery.", R.MASTERIES[term].desc } end
    for _, condition in ipairs(R.CONDITIONS) do
        if condition.name == term then return term, { "Condition.", condition.desc } end
    end
    if R.WEAPONS[term] then return WeaponInfo(term, R.WEAPONS[term]) end
    local spell = R.SPELLS[term]
    if spell then return term, { R.SPELL_LEVELS[spell.level] .. (spell.concentration and ", concentration." or "."), spell.desc } end
    if R.FEATS[term] then return term, { "Feat.", R.FEATS[term].desc } end
    if R.FIGHTING_STYLES[term] then return term, { "Fighting Style.", R.FIGHTING_STYLES[term].desc } end
    if R.TRAITS[term] and R.TRAITS[term].desc then return term, { R.TRAITS[term].desc } end
    -- "STR check" and "STR save" read as the ability; so does a companion's own roll.
    local stat, kind = (term:gsub("^companion ", "")):match("^(%u%u%u) (%l+)$")
    if stat and R.STAT_NAMES[stat] then
        local lines = { ns.Glossary[stat] }
        if kind == "save" then lines[#lines + 1] = ns.Glossary["Saving throw"] end
        return ("%s %s"):format(R.STAT_NAMES[stat], kind == "save" and "saving throw" or "check"), lines
    end
    if ns.Glossary[term] then return term, { ns.Glossary[term] } end
    -- Rolls named in lower case on the sheet ("initiative", "spell attack").
    local capital = term:gsub("^%l", string.upper)
    if ns.Glossary[capital] then return capital, { ns.Glossary[capital] } end
    if R.TOOLS[term] then return ToolInfo(term, R.TOOLS[term]) end
    if R.ITEMS[term] then return ItemInfo(term, R.ITEMS[term]) end
end
