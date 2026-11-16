-- Every tooltip of the sheet window, the spellbook and the list of spells to prepare,
-- as text. A row's tooltip is put together when the mouse comes over it and not when
-- the window is built (UI/Rows.lua), so this hovers every row of every tab and of the
-- two spell windows for a spread of characters, without clicking, and checks that
-- each tooltip builds, reads the same when hovered again, and reads the same after the
-- sheet was rebuilt. Given a file name it also writes them all there, so that two
-- versions of the addon can be compared with a diff.
-- usage: run.sh t-test-windows-tooltips.lua [file to write the tooltips to]
dofile(ARG3 .. "/t-test-windows-base.lua")
Start()

local OUT = rawget(_G, "ARG4")
local TABS = { "Actions", "Checks", "Skills", "Traits", "Items", "Trade" }
local saved = RPSheet.db.char
local all, characters, twice = {}, 0, 0

-- The open tooltip of a row as one text, or nil when it shows none.
local function TipText(where, part)
    if not (part.events and part.events.OnEnter) then return end
    if not Try(where .. " OnEnter", F.Enter, part.frame) then return end
    local lines, texts = F.TooltipLines(), {}
    for _, line in ipairs(lines or {}) do
        CheckText(where .. " tooltip", line.text)
        texts[#texts + 1] = tostring(line.text)
    end
    Try(where .. " OnLeave", F.Leave, part.frame)
    return lines and table.concat(texts, "\n")
end

-- The tooltips of the rows of one window, added to `list` with where each was.
local function Rows(list, label, place, rows)
    for index, part in ipairs(rows) do
        local where = ("%s | %s | row %d: %s"):format(label, place, index, F.Plain(PartText(part)):gsub("\n", " "):sub(1, 50))
        local text = TipText(where, part)
        if text then
            list[#list + 1] = where .. "\n" .. text
            if TipText(where, part) ~= text then Problem(where .. ": the tooltip reads differently when hovered again") end
            twice = twice + 1
        end
    end
end

-- The spellbook or the list of spells to prepare, opened if the character has one.
local function Window(list, label, place, has, key, toggle, body)
    if not has then return end
    Try(label .. " " .. place, function()
        if not (RPSheet[key] and RPSheet[key].frame:IsShown()) then RPSheet[toggle](RPSheet) end
        F.Settle()
        Rows(list, label, place, RPSheet[body].children)
        RPSheet[key]:Hide()
        F.Settle()
    end)
end

-- Every tooltip of every tab and of the two spell windows, as a list of texts that
-- each start with where it was.
local function Capture(label)
    local list, sheet = {}, RPSheet:Sheet()
    for _, tab in ipairs(TABS) do
        saved.sheetTab = tab
        Try(label .. " tab " .. tab, function() RPSheet:Populate(); F.Settle() end)
        Rows(list, label, tab, RPSheet.body.children)
    end
    Window(list, label, "spellbook", ns.HasSpellbook(sheet), "bookWindow", "ToggleSpellbook", "bookBody")
    Window(list, label, "prepared spells", ns.ChangesPreparedAtRest(sheet), "preparedWindow", "TogglePreparedWindow", "preparedBody")
    return list
end

-- Things for the tooltips to talk about: gear worn and attuned, coins, mounts, a
-- companion creature, tools, renown, conditions and exhaustion.
local function Furnish(n)
    local sheet = RPSheet:Sheet()
    for _, name in ipairs({ "Longsword", "Longbow", "Dagger", "Shield", "Chain Mail", "Rope", "Potion of Healing" }) do
        local item = RPSheet:AddItem(name, 1)
        if item then RPSheet:SetEquipped(item, true) end
    end
    -- magic items: three that ask for attunement (worn and attuned) and three that don't
    local names, attuned, plain = {}, 0, 0
    for name in pairs(R.ITEMS) do names[#names + 1] = name end
    table.sort(names)
    for index = n, #names, 7 do
        local data = R.ITEMS[names[index]]
        if data.rarity and ((data.attune and attuned < 3) or (not data.attune and plain < 3)) then
            local item = RPSheet:AddItem(names[index], 1)
            if item.attune then
                attuned, item.attuned, item.equipped = attuned + 1, true, attuned < 2
            else
                plain = plain + 1
            end
        end
    end
    RPSheet:AddCoins(12345)
    for _, name in ipairs({ "Riding Horse", "Cart", "Beast companion" }) do Try("mount " .. name, RPSheet.AddMount, RPSheet, name) end
    if n % 2 == 0 and sheet.mounts[1] then Try("ride", RPSheet.ToggleRiding, RPSheet, sheet.mounts[1]) end
    for index = 1, #R.TOOL_ORDER, 5 do sheet.tools[R.TOOL_ORDER[index]] = true end
    for index = n % 3 + 1, #R.ALL_FACTIONS, 4 do sheet.renown[R.ALL_FACTIONS[index]] = 3 + (index * 7) % 50 end
    local state = RPSheet:State()
    if n % 3 == 0 then
        state.conditions[R.CONDITIONS[n % #R.CONDITIONS + 1].name] = true
        state.exhaustion = 2
    end
    -- a druid in a beast form
    for _, ability in ipairs(sheet.abilities) do
        if n % 2 == 1 and ability.name:find("^Wild Shape: ") then
            Try("wild shape", RPSheet.UseAbility, RPSheet, ability)
            break
        end
    end
    RPSheet:SheetChanged()
    F.Settle(true)
    RPSheet.busy = false
end

local function Record(label, n)
    Try(label .. " furnish", Furnish, n)
    local first = Capture(label)
    local second = Capture(label)
    if #first ~= #second then Problem(("%s: %d tooltips, and %d after a rebuild"):format(label, #first, #second)) end
    for index, text in ipairs(first) do
        if second[index] and second[index] ~= text then
            Problem(("%s: reads differently after the sheet was rebuilt: %s"):format(label, text:match("^[^\n]*")))
        end
        all[#all + 1] = text
    end
    characters = characters + 1
end

local n = 0
for _, key in ipairs(R.CLASS_ORDER) do
    local class = R.CLASSES[key]
    for _, level in ipairs({ 3, 20 }) do
        n = n + 1
        local subclass = class.subclasses[n % #class.subclasses + 1]
        local label = ("%s/%s L%d"):format(key, subclass, level)
        local sheet = Try(label .. " build", NewCharacter, key, subclass, nil, level, n)
        if sheet then
            Try(label .. " use", Use, sheet)
            Record(label, n)
        end
    end
end

-- A Moon druid, a Beast Master with its companion, and characters of several classes.
local EXTRA = {
    { "DRUID", "Circle of the Moon", 12, {} }, { "HUNTER", "Beast Master", 11, {} },
    { "WARRIOR", nil, 5, { MAGE = 3 } }, { "PALADIN", nil, 6, { WARLOCK = 2, ROGUE = 2 } }, { "ROGUE", nil, 11, { MAGE = 9 } },
}
for index, entry in ipairs(EXTRA) do
    local key, subclass, own, others = entry[1], entry[2], entry[3], entry[4]
    local found = false
    for _, name in ipairs(R.CLASSES[key] and R.CLASSES[key].subclasses or {}) do found = found or name == subclass end
    if R.CLASSES[key] and (found or not subclass) then
        local sheet = Try("extra build", NewCharacter, key, subclass, nil, own, index)
        local total, names = own, { key .. own }
        for other, level in pairs(others) do
            local class = R.CLASSES[other]
            if class then
                sheet.classes[other] = { level = level, subclass = (level >= 3 or class.hero) and class.subclasses[1] or "", spec = class.specs[1],
                    skill = "", fightingStyle = "", fightingStyle2 = "" }
                total = total + level
                names[#names + 1] = other .. level
            end
        end
        table.sort(names)
        sheet.level = total
        local label = "extra " .. table.concat(names, "+") .. (subclass and (" " .. subclass) or "")
        Try(label .. " use", Use, sheet)
        Record(label, index + 1)
    end
end

-- A sum over every tooltip: the same number means the same texts. The order of the rows
-- doesn't count (some follow the order a table is walked in, which differs between runs).
local sum = 0
for _, text in ipairs(all) do
    local one = 0
    text = text:gsub("| row %d+: ", "| ", 1)
    for index = 1, #text do one = (one * 31 + text:byte(index)) % 2147483647 end
    sum = (sum + one) % 2147483647
end
if OUT then
    local file = assert(io.open(OUT, "w"))
    file:write(table.concat(all, "\n\n"), "\n")
    file:close()
end

Finish("tooltips", ("%d characters, %d tooltips read twice and again after a rebuild, checksum %d"):format(characters, twice, sum))
