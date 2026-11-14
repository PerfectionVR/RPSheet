-- The creation wizard's window: title, the current page, Back / Next / Not now,
-- and when it opens. Offered automatically when the active profile has no character
-- yet; /sheet new reopens it.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Opt = ns.Opt
local W = ns.Wizard
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local DIALOG = ADDON .. "Wizard"
local offered = {} -- sheet keys the wizard was already offered for this session

-- Closed a moment later: the options library redraws a window right after one of its
-- buttons was pressed, which would bring a closed one straight back.
local function Close()
    W.draft = nil
    C_Timer.After(0, function() AceConfigDialog:Close(DIALOG) end)
end

local args = {
    title = {
        type = "description", order = 1, fontSize = "large",
        name = function()
            if not W.draft then return "" end
            return ("%sStep %d of %d: %s|r\n"):format(Opt.GOLD, W.draft.step, #W.STEPS, W.STEPS[W.draft.step])
        end,
    },
    problem = {
        type = "description", order = 90, fontSize = "medium",
        name = function()
            local problem = W.draft and W.StepProblem()
            return problem and (Opt.RED .. problem .. "|r\n") or "\n"
        end,
    },
    back = {
        type = "execute", order = 91, name = "Back",
        disabled = function() return not W.draft or W.draft.step == 1 end,
        func = function() W.draft.step = W.draft.step - 1 end,
    },
    next = {
        type = "execute", order = 92,
        name = function() return W.draft and W.draft.step == #W.STEPS and "Create character" or "Next" end,
        disabled = function() return not W.draft or W.StepProblem() ~= nil end,
        func = function()
            if W.draft.step < #W.STEPS then
                W.draft.step = W.draft.step + 1
                return
            end
            W.Finish()
            Close()
            RPSheet:Print(("%s created. Use the gear icon on the sheet to change anything."):format(RPSheet:Summary() or "Character"))
            -- A character made above level 3 has choices the wizard doesn't ask about.
            local pending = ns.Levels.Pending(RPSheet:Sheet())
            -- A subclass's own choices (a Battle Master's maneuvers) are asked for the current level.
            if #pending == 0 and ns.OpenClassChoices(RPSheet:Sheet()) then pending = { RPSheet:Sheet().level } end
            if #pending > 0 then
                RPSheet:Print("At this level you have earlier level-up choices to make. They are asked one by one now, and stay available on the Character tab.")
                ns.OpenLevelDialog(pending[1])
            end
        end,
    },
    skip = {
        type = "execute", order = 93, name = "Not now",
        desc = "Close without creating a character. You can come back with /sheet new.",
        func = function()
            RPSheet:State().created = true
            Close()
        end,
    },
}
for index, page in ipairs(W.pages) do
    args["page" .. index] = page
end

ns.SnapSliders({ args = args })

LibStub("AceConfig-3.0"):RegisterOptionsTable(DIALOG, {
    type = "group",
    name = "RP Sheet - Create your character",
    args = args,
})
AceConfigDialog:SetDefaultSize(DIALOG, 620, 560)

function ns.OpenWizard()
    W.draft = W.NewDraft()
    -- One window at a time: the settings window would sit underneath and show through.
    -- A moment later, for the reason given at Close.
    C_Timer.After(0, function()
        if not W.draft then return end
        AceConfigDialog:Close(ADDON)
        AceConfigDialog:Open(DIALOG)
    end)
end

-- Opens the wizard once per session for a profile that has no character yet.
function ns.OfferWizard()
    local key = RPSheet.sheetKey
    if not key or offered[key] or InCombatLockdown() then return end
    local state = RPSheet:State()
    if state.created or R.CLASSES[state.sheet.class] then return end
    offered[key] = true
    ns.OpenWizard()
end
