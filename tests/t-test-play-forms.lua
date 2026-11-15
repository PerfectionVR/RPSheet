-- Wild Shape: taking and leaving forms, what a form changes, every beast's attack
-- rows (riders, charge and follow-up rows, second damage), and casting in a form.
dofile(ARG3 .. "/t-test-play-lib.lua")

local function Dice(from)
    local list = {}
    for i = (from or 0) + 1, #ROLLED do list[#list + 1] = ROLLED[i].sides end
    return table.concat(list, ",")
end
local function Repeat(count, sides, list)
    for _ = 1, count do list[#list + 1] = sides end
end
local function Druid(subclass, level, forms, opts)
    opts = opts or {}
    opts.base = opts.base or { STR = 8, DEX = 12, CON = 14, INT = 10, WIS = 16, CHA = 10 }
    local inner = opts.setup
    opts.setup = function(sheet)
        sheet.picks.forms = {}
        for _, name in ipairs(forms) do sheet.picks.forms[name] = true end
        if inner then inner(sheet) end
    end
    return Build("DRUID", subclass, level, opts)
end

Section("taking and leaving a form", function()
    local sheet = Druid("Circle of the Land", 4, { "Wolf", "Riding Horse" })
    local state = RPSheet:State()
    if not Check(R.BEASTS["Wolf"] and R.BEASTS["Riding Horse"], "the test's beasts are listed") then return end
    local use, wild = Ability("Wild Shape: Wolf"), Tracker("Wild Shape")
    if not Check(use and wild, "a druid who knows the wolf has its Wild Shape ability and uses") then return end
    local wolf = R.BEASTS["Wolf"]
    local max, str, left = RPSheet:MaxHP(), RPSheet:Score("STR"), wild.get()
    local wisSave = RPSheet:SaveMod("WIS")
    RPSheet:UseAbility(use)
    Eq(wild.get(), left - 1, "a use is spent")
    local form = RPSheet:Form()
    Check(form ~= nil and form.beast, "the character is in a beast form")
    Eq(state.tempHP, 4, "temporary hit points equal to the druid level")
    Eq(RPSheet:MaxHP(), max, "hit points are kept")
    Eq(RPSheet:Score("STR"), wolf.str, "Strength is the wolf's")
    Eq(RPSheet:AC(), wolf.ac, "Armor Class is the wolf's")
    Eq(RPSheet:Speed(), wolf.speed, "speed is the wolf's")
    Eq(RPSheet:SaveMod("WIS"), wisSave, "a mental save is your own")
    Said("uses [Wild Shape: Wolf] (1 Wild Shape) - temporary HP 4 (now 4 temporary HP)", "the announcement")
    -- no spells in a form
    local wisp = Learn("Starry Wisp")
    local before, sent = #PRINTED, #SENT
    RPSheet:CastSpell(wisp)
    Eq(#SENT, sent, "no spell in a beast form")
    Check(AnyPrinted("You can't cast spells in a beast form. Leave the form first.", before), "a line says why")
    -- another form replaces this one
    RPSheet:UseAbility(Ability("Wild Shape: Riding Horse"))
    Check(Passive("Riding Horse form").enabled and not Passive("Wolf form").enabled, "a new form ends the old one")
    Eq(wild.get(), left - 2, "and spends another use")
    Eq(state.tempHP, 4, "temporary hit points don't add up")
    -- leaving
    RPSheet:UseAbility(Ability("Leave beast form"))
    Check(not RPSheet:Form(), "Leave beast form ends it")
    Eq(RPSheet:Score("STR"), str, "your own Strength again")
    -- no uses left
    wild.set(0)
    before = #PRINTED
    RPSheet:UseAbility(use)
    Check(not RPSheet:Form(), "no form without a use")
    Check(AnyPrinted("Not enough Wild Shape", before), "a line says so")
    wild.set(1)
    -- 0 hit points ends it
    RPSheet:UseAbility(use)
    state.tempHP = 0
    sent = #SENT
    RPSheet:TakeDamage(max + 1)
    Check(not RPSheet:Form(), "dropping to 0 ends the form")
    Check(AnySaid("returns to their own shape: at 0 hit points.", sent), "and says so")
    RPSheet:Heal(max)
    -- incapacitated ends it
    wild.set(1)
    RPSheet:UseAbility(use)
    RPSheet:ToggleCondition("Stunned")
    Check(not RPSheet:Form(), "being stunned ends the form")
    RPSheet:ToggleCondition("Stunned")
    -- a form lasts half the level in hours: at level 4 a short rest leaves it, a long one ends it
    wild.set(1)
    RPSheet:UseAbility(use)
    RPSheet:ShortRest()
    Check(RPSheet:Form() ~= nil, "a two-hour form outlasts a short rest")
    RPSheet:LongRest()
    Check(not RPSheet:Form(), "and ends during a long rest")
    Eq(state.tempHP, 0, "temporary hit points end with the long rest")

    Druid("Circle of the Land", 2, { "Wolf" })
    RPSheet:UseAbility(Ability("Wild Shape: Wolf"))
    RPSheet:ShortRest()
    Check(not RPSheet:Form(), "at level 2 the form lasts an hour: a short rest ends it")
end)

Section("every beast's rows", function()
    local names = {}
    for name in pairs(R.BEASTS) do names[#names + 1] = name end
    table.sort(names)
    Druid("Circle of the Moon", 20, names)
    local state = RPSheet:State()
    local wild = Tracker("Wild Shape")
    local rows, riders, alts, follows, saves = 0, 0, 0, 0, 0
    for _, name in ipairs(names) do
        local beast = R.BEASTS[name]
        local use = Ability("Wild Shape: " .. name)
        if Check(use ~= nil, "Wild Shape: " .. name .. " is on the sheet") then
            wild.set(wild.max)
            state.tempHP = 0
            RPSheet:UseAbility(use)
            local form = RPSheet:Form()
            Check(form == R.FORMS[R.BeastFormPassive(name)], name .. ": the form is on")
            local swarm = name:find("^Swarm of") ~= nil
            Eq(state.tempHP, swarm and 0 or 60, name .. ": temporary hit points (three times the level; none for a swarm)")
            Eq(RPSheet:AC(), math.max(beast.ac, 13 + RPSheet:Mod("WIS")), name .. ": Armor Class, at least 13 + Wisdom for a Moon druid")
            Eq(RPSheet:Score("DEX"), beast.dex, name .. ": Dexterity")
            for index, attack in ipairs(beast.attacks) do
                local kinds = { { "", attack[1] } }
                if attack.alt then kinds[#kinds + 1] = { ":alt", ("%s (%s)"):format(attack[1], attack.alt[1]) } end
                if attack.follow then kinds[#kinds + 1] = { ":follow", ("%s (%s)"):format(attack[1], attack.follow[1]) } end
                for _, kind in ipairs(kinds) do
                    local label = ("%s: %s"):format(name, kind[2])
                    local ability = Ability(label)
                    if Check(ability ~= nil, "row " .. label) then
                        rows = rows + 1
                        local alt = kind[1] == ":alt" and attack.alt or nil
                        -- the dice this row should roll
                        local want = {}
                        if attack[2] then want[1] = 20 end
                        local count, sides, flat = attack[3], attack[4], attack[5]
                        if alt and not alt.extra then count, sides, flat = alt[2], alt[3], alt[4] end
                        Repeat(count, sides, want)
                        if alt and alt.extra then Repeat(alt[2], alt[3], want) end
                        if attack.plus then Repeat(attack.plus[1], attack.plus[2], want) end
                        local at = #ROLLED
                        Rolls(10)
                        RPSheet:UseAbility(ability)
                        Eq(Dice(at), table.concat(want, ","), label .. ": dice rolled")
                        local line = SENT[#SENT] or ""
                        if attack[2] then
                            Check(line:find(("attack: 10 + %d = %d"):format(attack[2], 10 + attack[2]), 1, true), label .. ": the beast's own attack bonus, in \"" .. line .. "\"")
                        else
                            saves = saves + 1
                            Check(not line:find("attack:"), label .. ": no attack roll")
                        end
                        local rider = (alt and alt.rider) or attack.rider
                        if rider then
                            riders = riders + 1
                            local text = rider:gsub("{(.-)}", "[%1]")
                            if #line < 250 then
                                Check(line:find((attack[2] and "On a hit: " or "") .. text, 1, true), label .. ": the rider is announced, in \"" .. line .. "\"")
                            end
                            Check(not line:find("{"), label .. ": no braces left in the line")
                        end
                        if alt then alts = alts + 1 end
                        if kind[1] == ":follow" then follows = follows + 1 end
                        -- a natural 20 doubles the damage dice
                        if attack[2] and (count > 0 or attack.plus) then
                            local double = { 20 }
                            Repeat(count * 2, sides, double)
                            if alt and alt.extra then Repeat(alt[2] * 2, alt[3], double) end
                            if attack.plus then Repeat(attack.plus[1] * 2, attack.plus[2], double) end
                            at = #ROLLED
                            Rolls(20)
                            RPSheet:UseAbility(ability)
                            Eq(Dice(at), table.concat(double, ","), label .. ": a natural 20 doubles the dice")
                        end
                    end
                end
            end
        end
    end
    Check(rows > 50 and riders > 5 and alts > 3 and follows > 0 and saves > 0,
        ("rows of every kind were tried (%d rows, %d riders, %d situations, %d follow-ups, %d without an attack roll)"):format(rows, riders, alts, follows, saves))
    print(("  beasts %d, rows %d, riders %d, situation rows %d, follow-up rows %d, rows without an attack roll %d"):format(#names, rows, riders, alts, follows, saves))
end)

Section("casting in a form", function()
    -- A Circle of the Moon druid casts its circle spells in a form, and no others.
    Druid("Circle of the Moon", 5, { "Wolf" })
    local cure, wisp = Spell("Cure Wounds"), Learn("Thunderwave")
    if not Check(cure and (cure.auto or ""):find("^prepared:"), "a Moon druid has Cure Wounds prepared by its circle") then return end
    RPSheet:UseAbility(Ability("Wild Shape: Wolf"))
    Eq(RPSheet:State().tempHP, 15, "a Moon druid's form gives three times the level")
    Eq(RPSheet:FormBlocksSpell(cure), nil, "a circle spell can be cast in the form")
    local sent = #SENT
    RPSheet:CastSpell(cure)
    Check(#SENT > sent, "and is")
    Check(RPSheet:FormBlocksSpell(wisp) ~= nil, "any other spell can't")

    -- with another class: that class's always-prepared spells are no circle spells
    Druid("Circle of the Moon", 8, { "Wolf" }, { extras = { { class = "PRIEST", level = 3, subclass = "Life Domain" } } })
    local bless, moonbeam = Spell("Bless"), Spell("Moonbeam")
    if Check(bless and moonbeam, "a Moon druid / Life priest has Bless and Moonbeam prepared") then
        Eq(bless.class, "PRIEST", "Bless belongs to the priest")
        RPSheet:UseAbility(Ability("Wild Shape: Wolf"))
        Check(RPSheet:Form() ~= nil, "in a form")
        Eq(RPSheet:FormBlocksSpell(moonbeam), nil, "the circle's Moonbeam can be cast")
        Check(RPSheet:FormBlocksSpell(bless) ~= nil, "the domain's Bless can't be cast in a form")
        Eq(RPSheet:FormBlocksSpell(Spell("Cure Wounds")), nil, "Cure Wounds, which both keep prepared, can")
    end
    -- a druid of another circle with a Moon-less form: nothing
    Druid("Circle of the Land", 8, { "Wolf" }, { extras = { { class = "PRIEST", level = 3, subclass = "Life Domain" } } })
    RPSheet:UseAbility(Ability("Wild Shape: Wolf"))
    Check(RPSheet:FormBlocksSpell(Spell("Bless")) ~= nil, "without the Moon circle no prepared spell is cast in a form")

    -- Beast Spells at level 18: anything without a priced component
    Druid("Circle of the Land", 18, { "Wolf" })
    RPSheet:UseAbility(Ability("Wild Shape: Wolf"))
    Check(ns.HasFeature(RPSheet:Sheet(), "Beast Spells"), "a level 18 druid has Beast Spells")
    Eq(RPSheet:FormBlocksSpell(Learn("Thunderwave")), nil, "a spell without a priced component can be cast")
    local stone = Learn("Stoneskin")
    Check((RPSheet:FormBlocksSpell(stone) or ""):find("needs a component with a price"), "one with a priced component can't")
    RPSheet:AddItem("Diamond dust (100 gp)", 1)
    Check(RPSheet:FormBlocksSpell(stone) ~= nil, "even when it is carried")
end)

Summary("t-test-play-forms")
