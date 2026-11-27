-- Small things around the settings: a saved announce channel that is none of ours, the
-- saved sizes of the windows, and what the wizard offers to carry over.
SYNC_SCRIPT = true
dofile(ARG3 .. "/t-sync-clients.lua")

local world = NewWorld()
local anna = world:AddClient({ name = "Anna" }):Login()
world:Advance(5)
anna.opened, anna.ns.Wizard.draft = {}, nil
local addon, ns = anna.addon, anna.ns

Section("a saved channel that is none of ours", function()
    anna:Build("WARRIOR", "", 5)
    for _, channel in ipairs(ns.CHANNELS) do Eq(ns.ChannelLabel(channel), ns.CHANNEL_LABEL[channel], "the label of " .. channel) end
    for _, odd in ipairs({ "SAY", "", "emote", 5, true, {} }) do Eq(ns.ChannelLabel(odd), "Self only", "the label of a saved " .. tostring(odd)) end
    Eq(ns.ChannelLabel(nil), "Self only", "and of none at all")
    -- the row on the sheet, as Refresh writes it
    local shown
    addon.channelLabel = { SetText = function(_, text) shown = text end }
    addon.populateSkipped, addon.trackerRows = false, {}
    addon.tempLabel, addon.inspirationLabel = { SetText = function() end }, { SetText = function() end }
    for _, odd in ipairs({ "SAY", 5, false }) do
        shown = nil
        addon.db.profile.channel = odd
        anna:Do(addon.Refresh, addon)
        Check(type(shown) == "string" and shown:find("Announce to  ", 1, true) and shown:find("Self only", 1, true), ("the row with a saved %s: %s"):format(tostring(odd), tostring(shown)))
        local printed = #anna.printed
        anna:Do(addon.Announce, addon, "waves.")
        Eq(#anna.said, 0, "nothing is sent anywhere")
        Check((anna.printed[printed + 1] or ""):find("Anna waves.", 1, true), "the line is shown to the player")
    end
    addon:CycleChannel()
    Eq(addon.db.profile.channel, "EMOTE", "a click on the row gets out of it")
    Check(shown and shown:find("Emote", 1, true), "and the row says so: " .. tostring(shown))
    world:CheckClean("channel")
end)

Section("window sizes", function()
    local source = io.open(ARG1 .. "/UI/Window.lua", "rb"):read("*a")
    local width, height = source:match("local MIN_WIDTH, MIN_HEIGHT = (%d+), (%d+)")
    width, height = tonumber(width), tonumber(height)
    Check(width and height, "the smallest size of a window was found in UI/Window.lua")
    local defaults = ns.defaults.profile
    for _, key in ipairs({ "window", "itemWindow", "spellbookWindow", "preparedWindow" }) do
        local size = defaults[key]
        if Check(type(size) == "table", key .. " has a default") then
            Check(size.width >= width and size.height >= height, ("%s starts at %dx%d, not below the smallest size %dx%d"):format(key, size.width, size.height, width, height))
            local saved = addon.db.profile[key]
            Check(type(saved) == "table" and saved.width == size.width and saved.height == size.height, key .. " is there on a fresh install")
        end
    end
    -- a size the player set is kept over a reload, a default one is not written out
    addon.db.profile.itemWindow.width = 700
    anna:Reload()
    addon, ns = anna.addon, anna.ns
    Eq(addon.db.profile.itemWindow.width, 700, "a size the player set survives a reload")
    Eq(addon.db.profile.itemWindow.height, ns.defaults.profile.itemWindow.height, "with the default beside it")
    Eq(addon.db.profile.window.width, ns.defaults.profile.window.width, "the sheet's default width")
    -- the cog's tooltip no longer describes the editor of old
    Check(not source:find("Stats, armor, weapons, abilities, passives and appearance", 1, true), "the cog's tooltip was rewritten")
    world:CheckClean("sizes")
end)

Section("the wizard's carry-over tick box", function()
    local W = ns.Wizard
    local function Offered(label, setup, want)
        anna:Build("WARRIOR", "", 3)
        local sheet = addon:Sheet()
        for index = #sheet.weapons, 1, -1 do table.remove(sheet.weapons, index) end
        sheet.items, sheet.mounts = {}, {}
        -- (species traits and the origin feat are passives without a mark of where they
        -- came from, so they count as the player's own: taken off here)
        for index = #sheet.passives, 1, -1 do
            if (sheet.passives[index].auto or "") == "" then table.remove(sheet.passives, index) end
        end
        for coin in pairs(sheet.coins) do sheet.coins[coin] = 0 end
        setup(sheet)
        Eq(W.NewDraft().hasContent, want, "carry over is offered for a character with " .. label)
    end
    Offered("nothing of its own", function() end, false)
    Offered("only an item", function(sheet) sheet.items[1] = { name = "Rope", count = 1 } end, true)
    Offered("only coins", function(sheet) sheet.coins.sp = 4 end, true)
    Offered("only a mount", function(sheet) sheet.mounts[1] = { name = "Riding Horse" } end, true)
    Offered("only a weapon", function(sheet) sheet.weapons[1] = { name = "Stick", dice = 1, sides = 4 } end, true)
    Offered("only an ability of its own", function(sheet) sheet.abilities[#sheet.abilities + 1] = { name = "Trick", auto = "", actions = {} } end, true)
    -- and what it offers is what is carried over
    anna:Build("WARRIOR", "", 3)
    local sheet = addon:Sheet()
    sheet.items, sheet.mounts = { { name = "Rope", count = 2 } }, {}
    for coin in pairs(sheet.coins) do sheet.coins[coin] = 0 end
    sheet.coins.gp = 9
    ns.NormalizeState(addon:State())
    W.draft = W.NewDraft()
    local draft = W.draft
    Eq(draft.hasContent, true, "a character with a rope and nine gold")
    draft.class, draft.level = "ROGUE", 1
    local class = ns.Rules.CLASSES.ROGUE
    for index = 1, class.skillCount do draft.classSkills[class.skills[index]] = true end
    draft.species, draft.background, draft.allegiance = "HUMAN", ns.Rules.BACKGROUND_ORDER[1], ns.Rules.ALLEGIANCE_ORDER[1]
    draft.keepLists = true
    anna:Do(W.Finish)
    W.draft = nil
    sheet = addon:Sheet()
    Eq(sheet.class, "ROGUE", "the new character")
    local rope = false
    for _, item in ipairs(sheet.items) do rope = rope or item.name == "Rope" end
    Check(rope and sheet.coins.gp >= 9, "has the rope and the gold")
    world:CheckClean("carry over")
end)

Summary("t-sync-small")
