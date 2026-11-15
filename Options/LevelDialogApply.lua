-- The level dialog: the buttons at the bottom. Confirming writes the draft to the
-- sheet and takes the level.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local Levels = ns.Levels
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = ns.LevelDialog
local args = L.args
local DIALOG = L.DIALOG

-- Closes the dialog, then opens the dialog for `nextLevel` or goes back to the settings.
-- The window is closed a moment later: the options library redraws a window right
-- after one of its buttons was pressed, which would bring a closed one straight back.
function L.Finish(nextLevel)
    local reopen = L.draft and L.draft.reopen
    L.draft = nil
    C_Timer.After(0, function()
        AceConfigDialog:Close(DIALOG)
        if nextLevel then
            ns.OpenLevelDialog(nextLevel, reopen)
        elseif reopen then
            AceConfigDialog:Open(ADDON)
        end
    end)
end

args.problem = {
    type = "description", order = 90, fontSize = "medium",
    name = function()
        local problem = L.draft and L.Problem()
        return problem and (Opt.RED .. problem .. "|r\n") or "\n"
    end,
}
args.confirm = {
    type = "execute", order = 91,
    name = function() return L.draft and L.draft.taking and ("Take level " .. L.Like().level) or "Save choice" end,
    disabled = function() return not L.draft or L.Problem() ~= nil end,
    func = function()
        local sheet, level, taking = L.Sheet(), L.draft.level, L.draft.taking
        -- For a class that is only added by taking the level, RPSheet:SetLevel below
        -- writes the subclass and the skill.
        local subclass = L.AsksSubclass() and L.draft.subclass ~= "" and L.draft.subclass or nil
        if subclass then ns.SetSubclass(sheet, L.draft.class, subclass) end
        local slot = L.StyleSlot()
        if slot and L.draft.style ~= "" then sheet[ns.STYLE_FIELDS[slot]] = L.draft.style end
        if L.draft.kind then Levels.Set(sheet, level, L.draft.record) end
        for _, feature in ipairs(L.OptionFeatures()) do sheet.featureOptions[feature.name] = L.draft.options[feature.name] end
        for _, key in ipairs(R.PICK_LIST_ORDER) do
            if L.PickLimit(key) > 0 then sheet.picks[key] = CopyTable(L.draft.picks[key]) end
        end
        if L.ManeuverLimit() > 0 then sheet.maneuvers = CopyTable(L.draft.maneuvers) end
        if L.ExpertiseLimit() > 0 then sheet.expertise = CopyTable(L.draft.expertise) end
        if L.FeatSkillLimit() > 0 then
            sheet.featSkills, sheet.featTools = CopyTable(L.draft.featSkills), CopyTable(L.draft.featTools)
        end
        sheet.featChoices = CopyTable(L.draft.featChoices) -- kept per feat; the upkeep drops what no feat asks for
        for _, feature in ipairs(L.SkillFeatures()) do sheet.featureSkills[feature] = L.draft.featureSkills[feature] end
        if taking then
            RPSheet:SetLevel(sheet.level + 1, L.draft.class, { subclass = subclass, skill = L.draft.skill })
        else
            ns.ApplyGrants(sheet)
            ns.NormalizeState(RPSheet:State())
        end
        ns.RebuildOptions()
        Opt.Changed()
        -- Earlier levels with an open choice are asked for next.
        L.Finish(not taking and Levels.Pending(sheet)[1] or nil)
    end,
}
args.cancel = {
    type = "execute", order = 92, name = "Cancel",
    func = function() L.Finish() end,
}
