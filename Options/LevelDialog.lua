-- The level dialog: shows what a level gives and asks for the choices it comes with
-- (an Ability Score Improvement or a feat, an Epic Boon, a subclass).
-- It is used to take the next level, and to make or change the choice of a level
-- the character already has. This file registers and opens it; its parts are the
-- Options/LevelDialog*.lua files above it in the load list (state in LevelDialogState.lua).
local ADDON, ns = ...
local R = ns.Rules
local Levels = ns.Levels
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = ns.LevelDialog
local args = L.args
local DIALOG = L.DIALOG

ns.SnapSliders({ args = args })

LibStub("AceConfig-3.0"):RegisterOptionsTable(DIALOG, {
    type = "group",
    name = "RP Sheet - Level",
    args = args,
})
AceConfigDialog:SetDefaultSize(DIALOG, 620, 560)

-- Opens the dialog for `level`: a level the character has (its number, see
-- Sheet/ClassSlots.lua) to make or change its choice, or nothing to take the next
-- level. `reopen` brings the settings back afterwards. `classKey` is the class the
-- next level is taken in: the first class when left out, another of the character's
-- classes, or a class it doesn't have yet.
function ns.OpenLevelDialog(level, reopen, classKey)
    local sheet = L.Sheet()
    local taking = not (level and ns.HasSlot(sheet, level))
    local own, classLevel
    if taking then
        if sheet.level >= R.MAX_LEVEL then return end
        own = R.CLASSES[classKey] and classKey or sheet.class
        classLevel = ns.ClassLevel(sheet, own) + 1
        level = ns.LevelSlot(sheet, own, classLevel)
    else
        own, classLevel = ns.SlotClass(sheet, level)
    end
    if reopen == nil then reopen = AceConfigDialog.OpenFrames[ADDON] ~= nil end
    local kind = Levels.Kind(sheet, level)
    local record = Levels.Record(sheet, level)
    local newClass = taking and ns.ClassLevel(sheet, own) == 0
    L.draft = {
        level = level, class = own, classLevel = classLevel, newClass = newClass, skill = "",
        taking = taking, kind = kind, subclass = "", style = "", reopen = reopen,
        maneuvers = CopyTable(sheet.maneuvers), featureSkills = CopyTable(sheet.featureSkills),
        options = CopyTable(sheet.featureOptions), picks = CopyTable(sheet.picks), expertise = CopyTable(sheet.expertise), featSkills = CopyTable(sheet.featSkills),
        featTools = CopyTable(sheet.featTools or {}), before = {}, fixed = {},
        featChoices = CopyTable(sheet.featChoices or {}),
        record = record and CopyTable(record) or Levels.NewRecord(kind),
    }
    for _, key in ipairs(R.PICK_LIST_ORDER) do L.draft.picks[key] = L.draft.picks[key] or {} end
    L.DropUnfollowed() -- a pick that stopped being valid is asked for again
    L.DropUnmet()      -- and so is an option whose own requirement isn't met
    L.RememberPicks(sheet) -- the picks that may not all be exchanged here (LevelDialogSwaps.lua)
    L.RememberManeuvers(sheet) -- and the maneuvers (LevelDialogManeuvers.lua)
    if kind == "BOON" then L.draft.record.choice = "FEAT" end
    -- A hero class taken as a new class comes with its subclass.
    if newClass and R.CLASSES[own].hero then L.draft.subclass = R.CLASSES[own].subclasses[1] or "" end
    -- The specialization's suggestions are pre-selected; the player can pick otherwise.
    local guide = R.SpecGuide(own, ns.ClassSpec(sheet, own))
    if guide then
        if guide.subclass and L.AsksSubclass() then L.draft.subclass = guide.subclass end
        local slot = L.StyleSlot()
        if guide.style and slot then
            for _, name in ipairs(ns.StyleChoices(ns.ClassView(sheet, own), slot)) do
                if name == guide.style then L.draft.style = name end
            end
        end
    end
    -- One window at a time: the settings window would sit underneath and show through.
    -- A moment later, for the reason given at L.Finish (LevelDialogApply.lua).
    C_Timer.After(0, function()
        if not L.draft then return end
        AceConfigDialog:Close(ADDON)
        AceConfigDialog:Open(DIALOG)
    end)
end
