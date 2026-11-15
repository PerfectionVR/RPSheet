-- A Death Knight and a Demon Hunter have spell lists of their own (Data/SpellLists.lua):
-- the Paladin's and the Ranger's without the spells the setting adds for Paladins and
-- Hunters. Checked here wherever a list is consulted: the level dialog at every level,
-- the Spells page's dropdown, the choices after a long rest. A Paladin and a Hunter
-- are still offered those spells, and a character who already has one keeps it.
-- (Which spells the site puts on each list is tests/t-conform-spells.lua's business.)
dofile(ARG3 .. "/t-test-levelling-lib.lua")
local checks = 0
local function Check(ok, text)
    checks = checks + 1
    if not ok then Problem(text) end
end
local function Plain(text) return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub(" %(.*$", "")) end

-- The spells the dialog shows in its prepared spells group right now.
local function Offered()
    local names = {}
    for _, row in ipairs((T.Rows(levelRoot, T.label))) do
        if row.parent:find("picksprepared") and row.option.type == "toggle" then names[Plain(row.name or "")] = row end
    end
    return names
end
local function Dropdown()
    local args = {}
    Opt.lists.spells.extra(args)
    return args.known.values()
end
local function OnSheet(sheet, name)
    for _, spell in ipairs(sheet.spells) do
        if spell.name == name then return spell end
    end
end

local CASES = {
    { hero = "DEATHKNIGHT", core = "PALADIN", list = "preparedPaladin", out = { "Consecration", "Guided Prayer", "Divine Shield" } },
    { hero = "DEMONHUNTER", core = "HUNTER", list = "preparedRanger", out = { "Freezing Trap", "Serpent Sting", "Explosive Trap" } },
}
for n, case in ipairs(CASES) do
    -- The core class sees them; the hero class never does.
    for _, key in ipairs({ case.core, case.hero }) do
        local hero = key == case.hero
        local name = R.CLASSES[key].name
        local sheet = T.NewCharacter(key, n, true)
        local seen = {}
        local function Look()
            for spell in pairs(Offered()) do seen[spell] = true end
        end
        while sheet and sheet.level < 17 do
            if not T.TakeLevel(nil, { inspect = Look }) then break end
        end
        T.Check(name .. " at 17")
        for _, spell in ipairs(case.out) do
            Check(R.OnClassSpellList(key, spell) == not hero, ("%s: %s is %s its spell list"):format(name, spell, hero and "on" or "not on"))
            if hero then
                Check(not seen[spell], ("%s: the level dialog offers %s"):format(name, spell))
                Check(not OnSheet(sheet, spell), ("%s: %s got onto the sheet"):format(name, spell))
                Check(Dropdown()[spell] == nil, ("%s: the Spells page offers %s"):format(name, spell))
                Check(ns.PickBlocked(case.list, spell, 17, sheet.picks[case.list], sheet.subclass, sheet) ~= nil, ("%s: %s can be prepared"):format(name, spell))
            else
                Check(seen[spell] == true, ("%s: the level dialog never offers %s"):format(name, spell))
                Check(Dropdown()[spell] ~= nil or OnSheet(sheet, spell) ~= nil, ("%s: the Spells page doesn't offer %s"):format(name, spell))
            end
        end
        local choices = ns.PreparedChoices(sheet, ns.PrepareRules(sheet)[1])
        for _, spell in ipairs(case.out) do
            Check(tContains(choices, spell) == not hero, ("%s: after a long rest %s %s be prepared"):format(name, spell, hero and "can" or "can't"))
        end
        -- Everything else on the shared list is open to both.
        local shared = 0
        for _, spell in ipairs(R.ClassSpellList(key)) do
            if R.SPELLS[spell].level > 0 and tContains(choices, spell) then shared = shared + 1 end
        end
        Check(shared > 30, ("%s: only %d spells to prepare from"):format(name, shared))

        if hero then
            -- A character from before the lists were told apart: one of those spells
            -- picked in the place of another.
            local kept, picks = case.out[1], sheet.picks[case.list]
            for spell in pairs(picks) do picks[spell] = nil break end
            picks[kept] = true
            ns.ApplyGrants(sheet); ns.NormalizeState(RPSheet:State()); RPSheet:SheetChanged()
            local spell = OnSheet(sheet, kept)
            Check(picks[kept] == true and spell ~= nil and spell.auto == "spell:" .. kept, ("%s: a %s prepared earlier is taken away"):format(name, kept))
            T.Check(name .. " with " .. kept)
            Check(tContains(ns.PreparedChoices(sheet, ns.PrepareRules(sheet)[1]), kept), ("%s: the %s it has is missing from its prepared choices"):format(name, kept))
            -- The dialog shows it ticked and leaves it be; the others stay hidden.
            T.TakeLevel(nil, { inspect = function()
                local offered = Offered()
                Check(offered[kept] ~= nil and offered[kept].option.get({}) == true, ("%s: the dialog doesn't show the %s it has"):format(name, kept))
                Check(offered[case.out[2]] == nil and offered[case.out[3]] == nil, name .. ": the dialog offers the other spells of the core class")
            end })
            Check(sheet.picks[case.list][kept] == true and OnSheet(sheet, kept) ~= nil, ("%s: %s is lost when a level is taken"):format(name, kept))
            T.Check(name .. " at 18 with " .. kept)
            -- One added by hand under Customize stays the player's own entry.
            local other = CopyTable(R.SPELLS[case.out[2]])
            sheet.spells[#sheet.spells + 1] = other
            ns.ApplyGrants(sheet); ns.NormalizeState(RPSheet:State())
            other = OnSheet(sheet, case.out[2])
            Check(other ~= nil and other.auto == "" and not sheet.picks[case.list][case.out[2]], ("%s: a %s added by hand is taken for a pick of its list"):format(name, case.out[2]))
        end
    end
end

local problems = 0
for _ in pairs(PROBLEMS) do problems = problems + 1 end
print(("hero class spell lists: %d dialogs, %d checks, %d problems"):format(T.dialogs, checks + T.checks, problems))
