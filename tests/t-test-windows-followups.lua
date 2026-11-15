-- Follow-ups from a read-through of the window code, each as a test of its own:
--   1. deleting an equipped item on its Customize page takes the armor off and puts
--      the weapon away
--   2. the renown line of the sheet reads well when a score below Friendly is partly
--      added by rule
--   3. every spell named on a class list is a spell the data knows (Options/Spells.lua
--      looks each one up without checking)
--   4. the settings window is redrawn once a frame however often ns.RebuildOptions is
--      called in it, and a rebuild is cheap
--   5. what one step of a renown slider costs (told, not judged)
dofile(ARG3 .. "/t-test-windows-base.lua")
dofile(ARG3 .. "/t-test-windows-dialog.lua")
Start()

local APP = "RPSheet"
local D = Dialog
local function Check(what, ok) if not ok then Problem(what) end end
local told = {}

---------------------------------------------------------------------------
-- 1. Delete on an equipped item
---------------------------------------------------------------------------
Try("delete an equipped item", function()
    Use(NewCharacter("WARRIOR", nil, nil, 5, 1))
    local sheet = RPSheet:Sheet()
    wipe(sheet.items)
    wipe(sheet.weapons)
    sheet.armor, sheet.shield = "NONE", false
    local wanted = { "Chain Mail", "Shield", "Longsword" }
    for _, name in ipairs(wanted) do
        RPSheet:SetEquipped(RPSheet:AddItem(name, 1), true)
    end
    RPSheet:SheetChanged()
    F.Settle(true)
    local bare = 10 + RPSheet:Mod("DEX")
    Check("the armor and shield aren't on: AC " .. RPSheet:AC(), sheet.armor ~= "NONE" and sheet.shield == true and RPSheet:AC() > bare)
    Check("the longsword isn't readied", #ns.ReadyWeapons(sheet) == 1)

    -- each item's page under Customize, Inventory: its Delete button, answered with yes
    for _, name in ipairs(wanted) do
        local page
        for _, candidate in ipairs(D.Pages(APP, D.Options(APP))) do
            local path = candidate.path
            if path[1] == "customize" and path[2] == "items" and path[3] and D.Member(candidate.group, "name", D.Info(APP, candidate.group, path)) == name then
                page = candidate
            end
        end
        if not page then
            Problem("no page under Customize, Inventory for " .. name)
        else
            D.Open(APP, page.path)
            Check("deleting " .. name .. ": no Delete button", D.Execute(APP, page.group.args.delete, "delete " .. name))
            Check(name .. " is still carried after Delete", RPSheet:CarriedItem(name) == nil)
        end
    end
    F.Settle(true)
    sheet = RPSheet:Sheet()
    Check("the deleted armor is still worn: armor " .. tostring(sheet.armor), sheet.armor == "NONE")
    Check("the deleted shield is still carried on the arm", sheet.shield ~= true)
    Check("AC is " .. RPSheet:AC() .. " with nothing worn, not " .. bare, RPSheet:AC() == bare)
    local ready = {}
    for _, weapon in ipairs(ns.ReadyWeapons(sheet)) do ready[#ready + 1] = weapon.name end
    Check("the deleted weapon is still readied: " .. table.concat(ready, ", "), #ready == 0)
    AceConfigDialog:Close(APP)
    F.Settle()
    SmokeChecks("after deleting equipped items")
end)

---------------------------------------------------------------------------
-- 2. The renown line below Friendly, partly by rule
---------------------------------------------------------------------------
Try("renown line", function()
    local found
    for index = 1, #R.SPECIES_ORDER do
        local sheet = NewCharacter("WARRIOR", nil, nil, 5, index)
        local home, side = ns.RenownHome(sheet)
        if home then
            local other
            for _, faction in ipairs(R.FACTIONS[side]) do
                if faction ~= home then other = other or faction end
            end
            Use(sheet)
            -- after it is in use: a new character is given renown with its home faction
            sheet = RPSheet:Sheet()
            wipe(sheet.renown)
            wipe(sheet.renownReached)
            sheet.renown[home], sheet.renown[other] = 1, 3
            ns.ApplyClassFeatures(sheet)
            RPSheet:SheetChanged()
            local score, added = ns.RenownScore(RPSheet:Sheet(), home)
            if score == 2 and #added > 0 then found = { home = home, other = other } break end
        end
    end
    Check("no species gives a home faction to try this with", found ~= nil)
    if not found then return end
    RPSheet.db.char.sheetTab = "Traits"
    RPSheet:Populate()
    F.Settle()
    local seen = 0
    for _, part in ipairs(RPSheet.body.children) do
        local text = F.Plain(PartText(part))
        if text:find(found.home, 1, true) == 1 or text:find(found.other, 1, true) == 1 then
            seen = seen + 1
            if text:find(" ,", 1, true) or text:find("  ", 1, true) or text:find(" $") then Problem("the renown line reads: '" .. text .. "'") end
            HoverPart("renown line " .. text, part)
            if text:find(found.home, 1, true) == 1 then
                Check("the renown line doesn't say the score is partly by rule: " .. text, text == found.home .. " 2 partly by rule")
            else
                Check("the renown line of the other faction: " .. text, text == found.other .. " 3 Friendly")
            end
        end
    end
    Check("the Traits tab shows " .. seen .. " renown lines, not 2", seen == 2)
    -- with a rival and below Friendly
    for _, pair in ipairs(R.RIVAL_FACTIONS) do
        local sheet = RPSheet:Sheet()
        wipe(sheet.renown)
        sheet.renown[pair[1]], sheet.renown[pair[2]] = 1, 12
        RPSheet:SheetChanged()
        F.Settle()
        for _, part in ipairs(RPSheet.body.children) do
            local text = F.Plain(PartText(part))
            if text:find(pair[1], 1, true) == 1 or text:find(pair[2], 1, true) == 1 then
                if text:find(" ,", 1, true) or text:find("  ", 1, true) or text:find(" $") then Problem("the renown line of a rival reads: '" .. text .. "'") end
                Check("the renown line doesn't name the rivalry: " .. text, text:find("(rival)", 1, true) ~= nil)
            end
        end
        break
    end
end)

---------------------------------------------------------------------------
-- 3. Every listed spell exists
---------------------------------------------------------------------------
Try("spell lists", function()
    local names, missing = 0, {}
    for _, lists in ipairs({ R.SPELL_LISTS, R.CLASS_SPELLS }) do
        for key, list in pairs(lists) do
            for _, name in ipairs(list) do
                names = names + 1
                if not R.SPELLS[name] then missing[#missing + 1] = tostring(key) .. ": " .. tostring(name) end
            end
        end
    end
    told[#told + 1] = ("%d names on class spell lists, %d unknown"):format(names, #missing)
    for index = 1, math.min(10, #missing) do Problem("a class list names a spell the data doesn't have: " .. missing[index]) end
    -- the Spells page with every class, at a level with every slot
    for index, key in ipairs(R.CLASS_ORDER) do
        Use(NewCharacter(key, nil, nil, 17, index))
        local group = D.Options(APP).args.customize.args.spells
        local option = group.args.known
        local info = D.Info(APP, option, { "customize", "spells", "known" })
        Try(key .. " spells for your class", function()
            local values = option.values(info)
            for _, name in ipairs(option.sorting(info)) do
                if values[name] == nil then error("sorting names " .. tostring(name) .. " which values lacks") end
            end
        end)
    end
end)

---------------------------------------------------------------------------
-- 4. Rebuilding the options several times in one frame
---------------------------------------------------------------------------
Try("rebuilds", function()
    Use(NewCharacter("PALADIN", nil, nil, 11, 1))
    AceConfigDialog:Open(APP)
    F.Settle()
    local opens = 0
    local realOpen = AceConfigDialog.Open
    AceConfigDialog.Open = function(...) opens = opens + 1 return realOpen(...) end
    for _ = 1, 5 do ns.RebuildOptions() end
    Check("the window is redrawn inside ns.RebuildOptions", opens == 0)
    F.Settle()
    Check(("five rebuilds in one frame redrew the settings window %d times, not once"):format(opens), opens == 1)
    AceConfigDialog.Open = realOpen
    local began = os.clock()
    for _ = 1, 200 do ns.RebuildOptions() end
    local each = (os.clock() - began) / 200 * 1000
    told[#told + 1] = ("one ns.RebuildOptions takes %.2f ms here"):format(each)
    -- the pages are there the moment it returns: a new entry can be opened at once
    local sheet = RPSheet:Sheet()
    local before = #sheet.abilities
    D.Open(APP, { "customize", "abilities" })
    local group = D.Options(APP).args.customize.args.abilities
    Check("no Add button on the Abilities page", D.Execute(APP, group.args.add, "add ability"))
    Check("Add didn't add an ability", #RPSheet:Sheet().abilities == before + 1)
    Check("the new ability has no page", group.args["item" .. (before + 1)] ~= nil)
    D.Open(APP, { "customize", "abilities", "item" .. (before + 1) })
    local page = group.args["item" .. (before + 1)]
    Check("the new ability's page doesn't open", page and D.Control(APP, page.args.delete) ~= nil)
    if page then
        Check("Delete on the new ability", D.Execute(APP, page.args.delete, "delete ability"))
        Check("Delete left the new ability", #RPSheet:Sheet().abilities == before)
    end
    AceConfigDialog:Close(APP)
    F.Settle()
end)

---------------------------------------------------------------------------
-- 5. One step of a renown slider
---------------------------------------------------------------------------
Try("renown slider", function()
    Use(NewCharacter("PALADIN", nil, nil, 11, 1))
    local faction = R.ALL_FACTIONS[1]
    RPSheet:Sheet().renown[faction] = 0
    ns.RebuildOptions()
    RPSheet:SheetChanged()
    D.Open(APP, { "customize", "origin" })
    local row
    for key, option in pairs(D.Options(APP).args.customize.args.origin.args) do
        if key:find("^renownRow") then row = option end
    end
    Check("no renown row on the Origin page", row ~= nil)
    local control = D.Control(APP, row.args.score)
    Check("no renown slider", control ~= nil and control.slider ~= nil)
    local upkeep, populate, upkeepTime, populateTime = 0, 0, 0, 0
    local realUpkeep, realPopulate = ns.ApplyClassFeatures, RPSheet.Populate
    ns.ApplyClassFeatures = function(...)
        local began = os.clock()
        upkeep = upkeep + 1
        local result = realUpkeep(...)
        upkeepTime = upkeepTime + os.clock() - began
        return result
    end
    RPSheet.Populate = function(...)
        local began = os.clock()
        populate = populate + 1
        realPopulate(...)
        populateTime = populateTime + os.clock() - began
    end
    -- a drag from 0 to 50, a step at a time as the handle moves
    F.Fire(control.slider, "OnMouseDown", "LeftButton")
    for value = 1, 50 do F.SetSliderValue(control.slider, value, true) end
    F.Fire(control.slider, "OnMouseUp", "LeftButton")
    F.Settle()
    ns.ApplyClassFeatures, RPSheet.Populate = realUpkeep, realPopulate
    Check("the drag didn't set the score: " .. tostring(RPSheet:Sheet().renown[faction]), RPSheet:Sheet().renown[faction] == 50)
    told[#told + 1] = ("a renown drag of 50 steps ran the sheet upkeep %d times (%.1f ms each) and rebuilt the sheet's rows %d times (%.1f ms each)"):format(
        upkeep, upkeepTime / math.max(1, upkeep) * 1000, populate, populateTime / math.max(1, populate) * 1000)
    -- the perks followed the score
    local perks = 0
    for _, list in ipairs({ RPSheet:Sheet().abilities, RPSheet:Sheet().passives }) do
        for _, entry in ipairs(list) do
            if (entry.auto or ""):find("^renown:") then perks = perks + 1 end
        end
    end
    local wanted = 0
    for _, tier in ipairs(R.RENOWN_TIERS) do
        local perk = R.FACTION_PERKS[faction] and R.FACTION_PERKS[faction][tier[2]]
        if perk and perk.grant and 50 >= tier[1] then wanted = wanted + 1 end
    end
    Check(("after the drag to 50 the sheet has %d renown perks of %s, not %d"):format(perks, faction, wanted), perks == wanted)
    AceConfigDialog:Close(APP)
    F.Settle()
    SmokeChecks("after the renown drag")
end)

for _, line in ipairs(told) do print("NOTE: " .. line) end
Finish("followups", "deleting equipped items, the renown line, spell lists, rebuilds and the renown slider")
