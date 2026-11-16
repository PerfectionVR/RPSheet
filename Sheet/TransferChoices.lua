-- Importing a character: the choices made on it (picks, feats, expertise, tools, trait
-- and feature choices), each kept only where the rules data knows it.
local _, ns = ...
local R = ns.Rules
local Text = ns.TransferKit.Text

local function CleanChoices(sheet, source)
    sheet.stronghold = R.STRONGHOLD_LANDS[source.stronghold] and source.stronghold or ""
    -- Damage types chosen for a passive's resistance: only the ones its list allows.
    sheet.defensePicks = {}
    for name in pairs(R.DEFENSE_PICKS) do
        local picks = ns.DefensePicks(source, name)
        if #picks > 0 then sheet.defensePicks[name] = picks end
    end
    if not R.ALLEGIANCES[sheet.allegiance] then sheet.allegiance = "" end
    sheet.maneuvers, sheet.featureSkills, sheet.featureSkillGranted = {}, {}, {}
    if type(source.maneuvers) == "table" then
        for name in pairs(R.MANEUVERS) do
            if source.maneuvers[name] == true then sheet.maneuvers[name] = true end
        end
    end
    sheet.expertise, sheet.expertiseGranted, sheet.featSkills, sheet.featSkillGranted = {}, {}, {}, {}
    for _, field in ipairs({ "expertise", "expertiseGranted", "featSkills", "featSkillGranted" }) do
        if type(source[field]) == "table" then
            for _, skill in ipairs(R.SKILLS) do
                if source[field][skill.name] == true then sheet[field][skill.name] = true end
            end
        end
    end
    sheet.featChoices, sheet.featGranted = ns.CleanFeatChoices(source.featChoices), {}
    if type(source.featGranted) == "table" then
        for _, skill in ipairs(R.SKILLS) do
            local ranks = tonumber(source.featGranted[skill.name])
            if ranks == 1 or ranks == 2 then sheet.featGranted[skill.name] = ranks end
        end
    end
    sheet.spellbook = {}
    if type(source.spellbook) == "table" then
        for name in pairs(source.spellbook) do
            if type(name) == "string" and R.SPELLS[name] and source.spellbook[name] == true then sheet.spellbook[name] = true end
        end
    end
    for _, field in ipairs({ "tools", "featTools" }) do
        sheet[field] = {}
        if type(source[field]) == "table" then
            for _, name in ipairs(R.TOOL_ORDER) do
                if source[field][name] == true then sheet[field][name] = true end
            end
        end
    end
    sheet.picks = {}
    for _, key in ipairs(R.PICK_LIST_ORDER) do
        sheet.picks[key] = {}
        local source = type(source.picks) == "table" and source.picks[key]
        if type(source) == "table" then
            for name in pairs(R.PICK_LISTS[key].items) do
                if source[name] == true then sheet.picks[key][name] = true end
            end
        end
    end
    -- Features the player deleted stay deleted: [auto key] = true, such as "class:Rage".
    sheet.dismissed = {}
    if type(source.dismissed) == "table" then
        for key, value in pairs(source.dismissed) do
            if value == true and type(key) == "string" and #key <= 120 and key:find("^%a+:.") and not key:find("[|%c]") then
                sheet.dismissed[key] = true
            end
        end
    end
    sheet.featureOptions = {}
    for _, field in ipairs({ "featureSkills", "featureSkillGranted", "featureOptions" }) do
        if type(source[field]) == "table" then
            for name, skill in pairs(source[field]) do
                if type(name) == "string" and type(skill) == "string" and #name <= 60 then
                    sheet[field][Text(name, 60)] = Text(skill, 60)
                end
            end
        end
    end
    for _, field in ipairs({ "traitChoices", "traitGranted" }) do
        sheet[field] = {}
        if type(source[field]) == "table" then
            for name in pairs(R.TRAITS) do
                if type(source[field][name]) == "string" then sheet[field][name] = Text(source[field][name], 60) end
            end
        end
    end
end

ns.TransferKit.CleanChoices = CleanChoices
