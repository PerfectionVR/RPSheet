-- The creation wizard and the level dialog, really built by the options library and
-- worked by clicking: the wizard is opened as /sheet new does, every step filled in
-- through its dropdowns, tick boxes and sliders, Back and Next pressed, the closet
-- opened from its button, and the character created. Then the level dialog is opened
-- for every level the new character has and for the next one: everything it shows is
-- looked over and worked, its choices are made and it is confirmed.
-- usage: run.sh t-test-windows-wizard.lua [quick]
dofile(ARG3 .. "/t-test-windows-base.lua")
dofile(ARG3 .. "/t-test-windows-dialog.lua")
Start()

local WIZARD, LEVEL, MAIN = "RPSheetWizard", "RPSheetLevel", "RPSheet"
local D = Dialog
local L = ns.LevelDialog
local QUICK = ARG4 == "quick"
local stats = { made = 0, steps = 0, levelDialogs = 0, confirmed = 0, unfinished = 0, worked = 0 }
local function Check(what, ok) if not ok then Problem(what) end end

-- The values a dropdown offers, sorted, without the empty one.
local function Choices(app, key, avoid)
    local option = D.Find(app, key)
    local control = option and D.Control(app, option)
    local names = {}
    for value in pairs(control and control.list or {}) do
        if value ~= "" and not (avoid and avoid[value]) then names[#names + 1] = value end
    end
    table.sort(names, function(a, b) return tostring(a) < tostring(b) end)
    return names
end
local function Empty(app, key)
    local value = D.Value(app, key)
    return value == nil or value == ""
end

local function Next(label)
    local step = W.draft.step
    local problem = W.StepProblem()
    local button = D.Control(WIZARD, D.Find(WIZARD, "next"))
    if problem then
        Check(label .. ": Next can be pressed although: " .. problem, button and button.disabled)
        Problem(("%s: step %d is stuck: %s"):format(label, step, problem))
        return false
    end
    Check(label .. ": Next is greyed out at step " .. step .. " with nothing missing", button and not button.disabled)
    D.Press(WIZARD, "next", label .. " Next")
    stats.steps = stats.steps + 1
    return true
end

-- Makes a character through the wizard's window.
local function Make(spec)
    local label = spec.label
    Try(label .. " open", function() RPSheet:SlashCommand("new") end)
    F.Settle()
    if not D.Shown(WIZARD) or not W.draft then Problem(label .. ": /sheet new doesn't open the wizard") return end
    Check(label .. ": the settings window stays open under the wizard", not D.Shown(MAIN))
    local root = D.Root(WIZARD)
    Check(label .. ": the wizard's title is " .. tostring(root.titletext:GetText()), root.titletext:GetText() == "RP Sheet - Create your character")
    local draft = W.draft
    local class = R.CLASSES[spec.class]

    -- Step 1: class
    local shown = D.Look(WIZARD, label .. " step 1 empty")
    local back = D.Control(WIZARD, D.Find(WIZARD, "back"))
    Check(label .. ": Back can be pressed on the first step", back and back.disabled)
    local nextButton = D.Control(WIZARD, D.Find(WIZARD, "next"))
    Check(label .. ": Next can be pressed before a class is chosen", nextButton and nextButton.disabled)
    D.Set(WIZARD, "class", spec.class, label .. " class")
    Check(label .. ": the class isn't taken", draft.class == spec.class)
    D.Set(WIZARD, "level", spec.level, label .. " level")
    Check(label .. ": the level is " .. tostring(draft.level), draft.level == spec.level)
    if class.specs and class.specs[1] then D.Set(WIZARD, "spec", class.specs[(spec.n - 1) % #class.specs + 1], label .. " spec") end
    for index, extra in ipairs(spec.extras or {}) do
        D.Set(WIZARD, "moreClass" .. index, extra.class, label .. " more class")
        D.Set(WIZARD, "moreLevel" .. index, extra.level, label .. " more level")
        shown = D.Look(WIZARD, label .. " extra " .. index)
        if shown["moreSpec" .. index] then
            local names = Choices(WIZARD, "moreSpec" .. index)
            if names[1] then D.Set(WIZARD, "moreSpec" .. index, names[1], label .. " more spec") end
        end
        shown = D.Look(WIZARD, label .. " extra spec " .. index)
        if shown["moreSubclass" .. index] and Empty(WIZARD, "moreSubclass" .. index) then
            local names = Choices(WIZARD, "moreSubclass" .. index)
            if names[1] then D.Set(WIZARD, "moreSubclass" .. index, names[1], label .. " more subclass") end
        end
    end
    shown = D.Look(WIZARD, label .. " step 1 class")
    if shown.subclass and Empty(WIZARD, "subclass") then
        local names = Choices(WIZARD, "subclass")
        if names[1] then D.Set(WIZARD, "subclass", names[(spec.n - 1) % #names + 1], label .. " subclass") end
    end
    -- class skills, keeping off the ones the background gives
    local background = R.BACKGROUNDS[spec.background]
    local avoid = {}
    for _, skill in ipairs(background.skills) do avoid[skill] = true end
    local picked = 0
    for index, skill in ipairs(R.SKILLS) do
        if shown["skill" .. index] and not avoid[skill.name] and picked < class.skillCount then
            if D.Set(WIZARD, "skill" .. index, true, label .. " skill " .. skill.name) then picked = picked + 1 end
        end
    end
    -- fighting styles and the other classes' skills: the first choice offered
    for _ = 1, 6 do
        shown = D.Look(WIZARD, label .. " step 1 styles")
        for key, entry in pairs(shown) do
            if entry.option.type == "select" and (key:find("[sS]tyle") or key:find("^moreSkill")) and Empty(WIZARD, key) then
                local names = Choices(WIZARD, key, avoid)
                if names[1] then D.Set(WIZARD, key, names[1], label .. " " .. key) end
            end
        end
    end
    D.Look(WIZARD, label .. " step 1 done")
    if not Next(label) then return end
    Check(label .. ": Next didn't lead to step 2", draft.step == 2)

    -- Step 2: origin; and Back and Next again keep what was chosen
    D.Look(WIZARD, label .. " step 2 empty")
    D.Press(WIZARD, "back", label .. " Back")
    Check(label .. ": Back didn't lead to step 1", draft.step == 1)
    Check(label .. ": going back lost the class", draft.class == spec.class and D.Value(WIZARD, "class") == spec.class)
    if not Next(label) then return end
    D.Set(WIZARD, "species", spec.species, label .. " species")
    D.Set(WIZARD, "background", spec.background, label .. " background")
    for _ = 1, 4 do
        shown = D.Look(WIZARD, label .. " step 2")
        for key, entry in pairs(shown) do
            if entry.option.type == "select" and Empty(WIZARD, key) then
                local names = Choices(WIZARD, key)
                if names[1] then D.Set(WIZARD, key, names[spec.n % #names + 1], label .. " " .. key) end
            end
        end
    end
    D.Look(WIZARD, label .. " step 2 done")
    if not Next(label) then return end

    -- Step 3: ability scores; what the classes need gets the high ones
    local need, order = {}, {}
    local function Needs(key)
        local rule = R.MULTICLASS[R.CLASSES[key].base]
        for _, stat in ipairs(rule and rule.primary or {}) do
            if not need[stat] then need[stat] = true; order[#order + 1] = stat end
        end
    end
    Needs(spec.class)
    for _, extra in ipairs(spec.extras or {}) do Needs(extra.class) end
    for _, stat in ipairs(R.STATS) do if not need[stat] then order[#order + 1] = stat end end
    D.Look(WIZARD, label .. " step 3 empty")
    local buy = { 14, 14, 13, 13, 8, 8 } -- 24 of the 27 points
    for index, stat in ipairs(order) do
        D.Set(WIZARD, "score" .. stat, buy[index], label .. " score " .. stat)
        Check(("%s: the %s slider gave %s, not %d"):format(label, stat, tostring(draft.base[stat]), buy[index]), draft.base[stat] == buy[index])
    end
    local left = { 2, 1 }
    for _, stat in ipairs(R.STATS) do
        if Opt.BackgroundAllows(spec.background, stat) and left[1] then D.Set(WIZARD, "bonus" .. stat, table.remove(left, 1), label .. " bonus " .. stat) end
    end
    D.Look(WIZARD, label .. " step 3 done")
    if not Next(label) then return end

    -- Step 4: alignment and allegiance
    D.Look(WIZARD, label .. " step 4 empty")
    D.Set(WIZARD, "alignment", R.ALIGNMENTS[1], label .. " alignment")
    D.Set(WIZARD, "allegiance", R.ALLEGIANCE_ORDER[spec.n % #R.ALLEGIANCE_ORDER + 1], label .. " allegiance")
    D.Look(WIZARD, label .. " step 4 done")
    if not Next(label) then return end

    -- Step 5: starting gear, with the closet
    shown = D.Look(WIZARD, label .. " step 5 empty")
    if shown.gearSet then
        local sets = Choices(WIZARD, "gearSet")
        if sets[1] then D.Set(WIZARD, "gearSet", sets[spec.n % #sets + 1], label .. " gear set") end
    end
    D.Press(WIZARD, "takeClassGear", label .. " class gear")
    D.Press(WIZARD, "takeBackgroundGear", label .. " background gear")
    for _ = 1, 2 do
        shown = D.Look(WIZARD, label .. " step 5 gear")
        for key in pairs(shown) do
            if key:find("^gearChoice") and Empty(WIZARD, key) then
                local names = Choices(WIZARD, key)
                if names[1] then D.Set(WIZARD, key, names[1], label .. " " .. key) end
            end
        end
    end
    Check(label .. ": taking the starting gear put nothing in the closet", next(draft.closet) ~= nil)
    D.Press(WIZARD, "openCloset", label .. " open the closet")
    local closet = RPSheet.itemWindow
    Check(label .. ": the Open the closet button opens nothing", closet and closet.frame:IsShown() and closet.titleText:GetText() == "Starting gear")
    -- a block's button in the closet shows in the wizard's own summary
    if closet and closet.frame:IsShown() then
        local taken
        for _, part in ipairs(RPSheet.itemBody.children) do
            if part.type == "InlineGroup" and not taken then
                for _, button in ipairs(part.children) do
                    if button.type == "Button" and button.text:GetText() == "Take another" then
                        local name = F.Plain(part.titletext:GetText()):gsub("  %(.*%)$", "")
                        local had = draft.closet[name] or 0
                        ClickPart(label .. " closet Take another", button, "LeftButton")
                        Check(label .. ": Take another in the closet took nothing", (draft.closet[name] or 0) == had + 1)
                        taken = name
                        break
                    end
                end
            end
        end
        local summary = D.Control(WIZARD, D.Find(WIZARD, "taken"))
        if taken and summary then
            Check(label .. ": the wizard's list of what was taken doesn't show " .. taken .. " x2",
                F.Plain(PartText(summary)):find(taken .. " x", 1, true) ~= nil)
        end
    end
    D.Look(WIZARD, label .. " step 5 done")
    Check(label .. ": the last step's button reads " .. tostring(D.Control(WIZARD, D.Find(WIZARD, "next")).text:GetText()),
        D.Control(WIZARD, D.Find(WIZARD, "next")).text:GetText() == "Create character")
    local closetWas = CopyTable(draft.closet)
    if not Next(label) then return end
    F.Settle()
    Check(label .. ": the wizard stays open after Create", not D.Shown(WIZARD) and W.draft == nil)
    Check(label .. ": the closet stays open after Create", not (closet and closet.frame:IsShown()))
    local sheet = RPSheet:Sheet()
    Check(("%s: the sheet has %s %s, not %s %d"):format(label, tostring(sheet.class), tostring(sheet.level), spec.class, spec.total or spec.level),
        sheet.class == spec.class and sheet.level == (spec.total or spec.level))
    for name, count in pairs(closetWas) do
        local item = RPSheet:CarriedItem(name)
        if not item or item.qty < count then Problem(("%s: %d %s were taken from the closet, the sheet carries %s"):format(label, count, name, tostring(item and item.qty))) end
    end
    stats.made = stats.made + 1
    return sheet
end

---------------------------------------------------------------------------
-- The level dialog
---------------------------------------------------------------------------
-- Makes the choices the dialog still asks for, a click at a time, until it has no
-- complaint or nothing helps any more: an empty dropdown gets its first value, then
-- tick boxes are ticked (the ones under a heading the complaint names first) and kept
-- when the complaint changes, then sliders are moved up.
local deadEnds = {}
local function Solve(label)
    local function Words(text)
        local set = {}
        for word in F.Plain(tostring(text or "")):gmatch("%a%a%a%a+") do set[word:lower()] = true end
        return set
    end
    local tried = {}
    for _ = 1, 120 do
        local problem = L.draft and L.Problem()
        if not problem then return true end
        local wanted = Words(problem)
        local entries = {}
        for _, entry in ipairs(D.PageOptions(LEVEL, D.Options(LEVEL), {})) do
            if not entry.hidden then
                local score = 0
                for word in pairs(Words((entry.box or "") .. " " .. tostring(D.Member(entry.option, "name", D.Info(LEVEL, entry.option, entry.path)) or ""))) do
                    if wanted[word] then score = score + 1 end
                end
                entry.score = score
                entries[#entries + 1] = entry
            end
        end
        table.sort(entries, function(a, b)
            if a.score ~= b.score then return a.score > b.score end
            return table.concat(a.path, "/") < table.concat(b.path, "/")
        end)
        local helped = false
        for _, entry in ipairs(entries) do
            if helped then break end
            local option = entry.option
            if option.type == "select" then
                local control = D.Control(LEVEL, option)
                if control and control.type == "Dropdown" and not control.disabled and (control:GetValue() == nil or control:GetValue() == "") then
                    local names = {}
                    for value in pairs(control.list or {}) do
                        if value ~= "" then names[#names + 1] = value end
                    end
                    table.sort(names, function(a, b) return tostring(a) < tostring(b) end)
                    for _, value in ipairs(names) do
                        if not helped and not tried[tostring(option) .. tostring(value)] then
                            tried[tostring(option) .. tostring(value)] = true
                            if D.Set(LEVEL, option, value, label .. " " .. entry.key) then helped = true end
                        end
                    end
                end
            end
        end
        local attempts = 0
        for _, entry in ipairs(entries) do
            if helped or attempts >= 12 then break end
            local option = entry.option
            if option.type == "toggle" or option.type == "multiselect" then
                -- one tick box, or one per value
                local boxes = {}
                for _, part in ipairs(D.Controls(LEVEL)) do
                    if part:GetUserData("option") == option and part.type == "CheckBox" then boxes[#boxes + 1] = part:GetUserData("value") or false end
                end
                for _, value in ipairs(boxes) do
                    local id = tostring(option) .. tostring(value)
                    local box = D.Control(LEVEL, option, value or nil)
                    if not helped and not tried[id] and box and not box.disabled and not box:GetValue() then
                        tried[id] = true
                        attempts = attempts + 1
                        Try(label .. " tick " .. entry.key, F.Click, box.frame)
                        D.After(label .. " tick " .. entry.key)
                        if not L.draft then return false, "the dialog closed" end
                        if L.Problem() ~= problem then
                            helped = true
                        else
                            local again = D.Control(LEVEL, option, value or nil)
                            if again and again:GetValue() then
                                Try(label .. " untick " .. entry.key, F.Click, again.frame)
                                D.After(label .. " untick " .. entry.key)
                            end
                        end
                    end
                end
            end
        end
        for _, entry in ipairs(entries) do
            if helped then break end
            local option = entry.option
            if option.type == "range" then
                local control = D.Control(LEVEL, option)
                if control and control.slider and not control.disabled and control:GetValue() < control.max and not tried[tostring(option)] then
                    tried[tostring(option)] = true
                    local was = control:GetValue()
                    -- all the way up first (two points on one ability), then a step
                    for _, value in ipairs({ control.max, was + 1 }) do
                        if not helped and L.draft and D.Set(LEVEL, option, value, label .. " " .. entry.key) and L.draft then
                            if L.Problem() ~= problem then helped = true else D.Set(LEVEL, option, was, label .. " " .. entry.key .. " back") end
                        end
                    end
                end
            end
        end
        if not helped then
            -- Nothing among the likely controls helped. Before calling it a dead end,
            -- every other tick box is tried too, once per character and complaint.
            local who = label:gsub(" level %d+$", ""):gsub(" next level$", "")
            if deadEnds[who .. problem] == nil then
                local found = false
                for _, entry in ipairs(entries) do
                    local option = entry.option
                    if not found and (option.type == "toggle" or option.type == "multiselect") then
                        local boxes = {}
                        for _, part in ipairs(D.Controls(LEVEL)) do
                            if part:GetUserData("option") == option and part.type == "CheckBox" then boxes[#boxes + 1] = part:GetUserData("value") or false end
                        end
                        for _, value in ipairs(boxes) do
                            local id = tostring(option) .. tostring(value)
                            local box = D.Control(LEVEL, option, value or nil)
                            if not found and not tried[id] and box and not box.disabled and not box:GetValue() then
                                tried[id] = true
                                Try(label .. " tick " .. entry.key, F.Click, box.frame)
                                D.After(label .. " tick " .. entry.key)
                                if not L.draft then return false, "the dialog closed" end
                                if L.Problem() ~= problem then
                                    found = true
                                else
                                    local again = D.Control(LEVEL, option, value or nil)
                                    if again and again:GetValue() then
                                        Try(label .. " untick " .. entry.key, F.Click, again.frame)
                                        D.After(label .. " untick " .. entry.key)
                                    end
                                end
                            end
                        end
                    end
                end
                deadEnds[who .. problem] = not found
                if found then
                    helped = true
                else
                    Problem(("%s: the level dialog can't be confirmed (\"%s\"): nothing it shows changes that"):format(who, problem))
                end
            end
            if not helped then return false, problem end
        end
    end
    return false, L.draft and L.Problem()
end

local function LevelDialog(label, slot, work)
    Try(label .. " open", ns.OpenLevelDialog, slot)
    F.Settle()
    if not L.draft then return end -- nothing to ask at this level
    stats.levelDialogs = stats.levelDialogs + 1
    if not D.Shown(LEVEL) then Problem(label .. ": the level dialog doesn't open") L.draft = nil return end
    Check(label .. ": the settings stay open under the level dialog", not D.Shown(MAIN))
    Check(label .. ": title " .. tostring(D.Root(LEVEL).titletext:GetText()), D.Root(LEVEL).titletext:GetText() == "RP Sheet - Level")
    local shown = D.Look(LEVEL, label)
    -- the confirm button is greyed exactly while something is missing
    local confirm = D.Control(LEVEL, L.args.confirm)
    local problem = L.Problem()
    Check(label .. ": no confirm button", confirm ~= nil)
    if confirm then
        Check(("%s: the confirm button is %s while the dialog says: %s"):format(label, confirm.disabled and "greyed" or "live", tostring(problem)),
            (confirm.disabled and true or false) == (problem ~= nil))
    end
    -- every control worked once (values are put back), except the buttons that close it
    if work then
        local keys = {}
        for key in pairs(shown) do keys[#keys + 1] = key end
        table.sort(keys)
        for _, key in ipairs(keys) do
            local option = shown[key].option
            if option.type ~= "execute" and L.draft and D.Control(LEVEL, option) then
                D.Work(LEVEL, option, label .. " " .. key, 8)
                stats.worked = stats.worked + 1
            end
        end
    end
    if not L.draft or not D.Shown(LEVEL) then Problem(label .. ": working the controls closed the dialog") L.draft = nil return end
    local solved, why = Solve(label)
    if not solved then
        stats.unfinished = stats.unfinished + 1
        if rawget(_G, "ARG5") == "why" then print(("NOTE: %s left open: %s"):format(label, tostring(why))) end
        -- closed with its Cancel button
        local cancel = D.Find(LEVEL, "cancel")
        if cancel and D.Control(LEVEL, cancel) then
            D.Press(LEVEL, cancel, label .. " cancel")
        else
            L.draft = nil
            AceConfigDialog:Close(LEVEL)
        end
        F.Settle()
        L.draft = nil
        if D.Shown(LEVEL) then AceConfigDialog:Close(LEVEL) F.Settle() end
        return
    end
    D.Look(LEVEL, label .. " chosen")
    local levelBefore = RPSheet:Sheet().level
    local taking = L.draft.taking
    Check(label .. ": the confirm button can't be pressed with every choice made", D.Press(LEVEL, L.args.confirm, label .. " confirm"))
    F.Settle()
    stats.confirmed = stats.confirmed + 1
    if taking then
        Check(("%s: taking the level left the character at level %d"):format(label, RPSheet:Sheet().level), RPSheet:Sheet().level == levelBefore + 1)
    else
        Check(label .. ": saving a choice changed the level", RPSheet:Sheet().level == levelBefore)
    end
    -- a dialog for a later level may have opened by itself: closed here, opened below
    if L.draft or D.Shown(LEVEL) then
        L.draft = nil
        AceConfigDialog:Close(LEVEL)
        F.Settle()
    end
    if D.Shown(MAIN) then AceConfigDialog:Close(MAIN) F.Settle() end
    CheckHidden(label)
end

local function AfterMake(label, work)
    -- the wizard may have opened the level dialog for earlier choices: looked at, closed
    if D.Shown(LEVEL) then
        D.Look(LEVEL, label .. " first pending level")
        L.draft = nil
        AceConfigDialog:Close(LEVEL)
        F.Settle()
    end
    local sheet = RPSheet:Sheet()
    SmokeChecks(label .. " made")
    -- every level's dialog is opened, looked over, its choices made and confirmed; the
    -- controls of the first and the last are also worked one by one
    local slots = ns.LevelSlots(sheet)
    for index, slot in ipairs(slots) do
        Try(label .. " level " .. slot, LevelDialog, label .. " level " .. slot, slot, work and (index == 1 or index == #slots))
    end
    if RPSheet:Sheet().level < R.MAX_LEVEL then
        Try(label .. " next level", LevelDialog, label .. " next level", nil, false)
    end
    SmokeChecks(label .. " levelled")
    -- the sheet window shows the new character
    RPSheet.db.char.sheetTab = "Actions"
    RPSheet:Populate()
    F.Settle()
    CheckOverlap(RPSheet.body, label .. " sheet")
end

---------------------------------------------------------------------------
-- The characters
---------------------------------------------------------------------------
local SPECS = {
    { class = "WARRIOR", level = 1 }, { class = "MAGE", level = 3 }, { class = "PALADIN", level = 5 }, { class = "DRUID", level = 8 },
    { class = "ROGUE", level = 4 }, { class = "PRIEST", level = 12 }, { class = "HUNTER", level = 19 }, { class = "WARLOCK", level = 20 },
    { class = "WARRIOR", level = 6, extras = { { class = "MAGE", level = 3 } } },
    { class = "PALADIN", level = 5, extras = { { class = "WARLOCK", level = 4 } } },
}
if QUICK then SPECS = { SPECS[2], SPECS[4], SPECS[9] } end
for n, spec in ipairs(SPECS) do
    if R.CLASSES[spec.class] then
        spec.n = n
        spec.species = R.SPECIES_ORDER[(n * 7) % #R.SPECIES_ORDER + 1]
        spec.background = R.BACKGROUND_ORDER[(n * 5) % #R.BACKGROUND_ORDER + 1]
        spec.total = spec.level
        local names = { spec.class .. spec.level }
        for _, extra in ipairs(spec.extras or {}) do
            spec.total = spec.total + extra.level
            names[#names + 1] = extra.class .. extra.level
        end
        if spec.extras then spec.level = spec.total end
        spec.label = "wizard " .. table.concat(names, "+")
        local sheet = Try(spec.label, Make, spec)
        W.draft = nil
        if D.Shown(WIZARD) then AceConfigDialog:Close(WIZARD) F.Settle() end
        if sheet then Try(spec.label .. " levels", AfterMake, spec.label, n <= 4 or QUICK) end
        Dismiss()
    end
end

-- A character whose class gives expertise in one of a few skills (a Mage's Scholar)
-- and who is proficient in none of them: the level dialog must not ask for a choice
-- it shows no tick box for, or no level of that character can be taken or changed.
Try("expertise with no skill to choose", function()
    local sheet = NewCharacter("WARRIOR", nil, nil, 5, 3)
    sheet.skills = { Athletics = 1, Intimidation = 1 }
    sheet.classes = { MAGE = { level = 2, subclass = "", spec = R.CLASSES.MAGE.specs[1], skill = "", fightingStyle = "", fightingStyle2 = "" } }
    sheet.level = 7
    Use(sheet)
    sheet = RPSheet:Sheet()
    local limit, allowed = ns.ExpertiseLimit(sheet)
    local open = 0
    for skill in pairs(allowed or {}) do
        if (sheet.skills[skill] or 0) >= 1 then open = open + 1 end
    end
    ns.OpenLevelDialog()
    F.Settle()
    if not D.Shown(LEVEL) then Problem("the level dialog doesn't open for a warrior with mage levels") return end
    local boxes = 0
    for _, entry in ipairs(D.PageOptions(LEVEL, D.Options(LEVEL), {})) do
        if not entry.hidden and entry.path[1] == "expertise" and D.Control(LEVEL, entry.option) then boxes = boxes + 1 end
    end
    local problem = L.Problem() or ""
    if problem:find("expertise", 1, true) and boxes == 0 then
        Problem(("a character with %d of the skills its class gives expertise in is asked \"%s\" and shown %d tick boxes: no level can be taken or changed"):format(open, problem, boxes))
    end
    L.draft = nil
    AceConfigDialog:Close(LEVEL)
    F.Settle()
end)

-- "Not now" closes the wizard without a character, and it isn't offered again.
Try("not now", function()
    RPSheet:ReplaceSheet(ns.NewSheet())
    RPSheet:State().created = nil
    RPSheet:SlashCommand("new")
    F.Settle()
    Check("the wizard doesn't open for an empty sheet", D.Shown(WIZARD))
    D.Look(WIZARD, "not now")
    D.Press(WIZARD, "skip", "Not now")
    F.Settle()
    Check("Not now leaves the wizard open", not D.Shown(WIZARD) and W.draft == nil)
    Check("Not now isn't remembered", RPSheet:State().created == true)
    ns.OfferWizard()
    F.Settle()
    Check("the wizard is offered again after Not now", not D.Shown(WIZARD))
    -- the sheet of a character without a class offers the wizard: clicked
    RPSheet:Populate()
    F.Settle()
    for _, part in ipairs(RPSheet.body.children) do
        if F.Plain(PartText(part)):find("^Create your character") then
            ClickPart("the sheet's 'create your character' row", part, "LeftButton")
        end
    end
    Check("the sheet's 'create your character' row doesn't open the wizard", D.Shown(WIZARD))
    -- closed by the window's own close button: the draft is dropped
    local root = D.Root(WIZARD)
    for _, child in ipairs({ root.frame:GetChildren() }) do
        if child:IsObjectType("Button") and child:GetText() == "Close" then F.Click(child) end
    end
    F.Settle()
    Check("the wizard's Close button leaves it open", not D.Shown(WIZARD))
    W.draft = nil
end)

local c = D.count
Finish("wizard", ("%d characters made by clicking through %d steps; %d level dialogs opened, %d confirmed, %d left open by the test's simple chooser, %d of their controls worked; %d dropdown choices, %d ticks, %d slider moves, %d buttons"):format(
    stats.made, stats.steps, stats.levelDialogs, stats.confirmed, stats.unfinished, stats.worked, c.selects, c.toggles, c.ranges, c.executes))
