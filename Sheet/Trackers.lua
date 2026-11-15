-- Everything on the sheet that has a current and a maximum value:
-- HP, hit dice, class resources, the player's own resources, and spell slots.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- Maximum of a class resource at a level (see `pools` in Data/Classes.lua).
-- A pool is sized by level steps, per level, or from an ability modifier.
local function PoolMax(self, pool, level)
    if level < (pool.from or 1) then return 0 end
    if pool.perLevel then
        return pool.perLevel * level
    end
    if pool.max then return pool.max end -- worked out where the pool is made
    if pool.prof then return self:ProficiencyBonus() end
    if pool.stat then
        -- An ability modifier, plus half the level for some.
        -- ...or a few more at certain levels (levelBonus).
        local extra = pool.levelBonus and ns.FeatureKit.AtLevel(level, pool.levelBonus) or 0
        return math.max(pool.min or 0, (pool.flat or 0) + self:Mod(pool.stat) + (pool.halfLevel and math.floor(level / 2) or 0)) + extra
    end
    local max = 0
    for _, step in ipairs(pool.steps) do
        if level >= step[1] then max = step[2] end
    end
    return max
end

-- In display order. Each entry has:
--   kind    "hp", "hitdice", "pool", "resource" or "slot"
--   label, max, get(), set(value)
--   reset   value after a long rest
--   short   what a short rest gives back: "ALL", a number of uses, or nil for nothing
function RPSheet:GetTrackers()
    local state, sheet = self:State(), self:Sheet()
    local list = {}
    local function add(kind, label, max, reset, store, key, short)
        if max <= 0 then return end
        list[#list + 1] = {
            kind = kind, label = label, max = max, reset = reset, short = short,
            level = kind == "slot" and key or nil, -- spell level, for spell slots
            get = function() return store[key] end,
            set = function(value) store[key] = math.max(0, math.min(max, value)) end,
        }
    end
    add("hp", "HP", self:MaxHP(), self:MaxHP(), state, "hp")
    -- Hit Dice: one pool, or one per size of die for classes with different dice
    -- (Sheet/ClassHitDice.lua). The first class's pool is kept where it always was.
    for _, dice in ipairs(ns.HitDice(sheet)) do
        if dice.first then
            add("hitdice", dice.label, dice.count, dice.count, state, "hitDice")
        else
            if type(state.hitDiceMore) ~= "table" then state.hitDiceMore = {} end
            add("hitdice", dice.label, dice.count, dice.count, state.hitDiceMore, dice.sides)
        end
        list[#list].sides = dice.sides
    end
    -- Class resources, then any the subclass brings (Superiority Dice and the like).
    -- A World of Warcraft class can drop some of its base class's resources and add its own.
    -- Every class of the character brings its own, sized by its own level. Two classes
    -- with a resource of the same name (Channel Divinity) share one bar: the larger.
    local views = ns.ClassViews(sheet)
    local pools, byName, firstDropped = {}, {}, nil
    local function collect(source, level, dropped)
        for _, pool in ipairs(source) do
            if not dropped[pool.name] then
                local max = PoolMax(self, pool, level)
                local same = #views > 1 and byName[pool.name]
                if same then
                    same.max = math.max(same.max, max)
                else
                    local entry = { name = pool.name, max = max, short = pool.short }
                    pools[#pools + 1], byName[pool.name] = entry, entry
                end
            end
        end
    end
    for _, view in ipairs(views) do
        local viewClass = R.CLASSES[view.class]
        local override = R.CLASS_OVERRIDES[view.class] or {}
        local dropped = {}
        for _, name in ipairs(override.removePools or {}) do dropped[name] = true end
        firstDropped = firstDropped or dropped
        local sources = {
            viewClass and viewClass.pools or {}, override.pools or {}, R.SUBCLASS_POOLS[view.subclass] or {},
            ns.FeaturePools(view), -- features with uses of their own, such as Divine Intervention
        }
        for _, source in ipairs(sources) do collect(source, view.level, dropped) end
    end
    local shared = {
        ns.LineagePools(sheet), -- a lineage's once-per-rest spells
        ns.TraitPools(sheet),   -- species traits with uses
        ns.RenownPools(sheet),  -- a faction's blessings with uses
        ns.PetPools(sheet),     -- a Beast Master's companion
    }
    for _, source in ipairs(shared) do collect(source, self:Level(), firstDropped) end
    for _, pool in ipairs(pools) do
        add("pool", pool.name, pool.max, pool.max, state.pool, pool.name, pool.short)
    end
    for _, resource in ipairs(sheet.resources) do
        local max = self:Amount(resource.flat, resource.stat, resource.times)
        add("resource", resource.name, max, resource.startEmpty and 0 or max, state.res, resource.name,
            resource.shortRest and "ALL" or nil)
    end
    local slots, pactSlots, pact = ns.SheetSlots(sheet)
    for spellLevel = 1, 9 do
        if slots[spellLevel] then
            -- Slots made from Sorcery Points can go above the usual number (see
            -- Actions/SlotActions.lua). The maximum follows them up, and comes back
            -- down as they are spent; a long rest resets to the usual number.
            local usual = slots[spellLevel]
            local have = type(state.slots[spellLevel]) == "number" and state.slots[spellLevel] or 0
            add("slot", R.ORDINALS[spellLevel] .. "-level slot", math.max(usual, have), usual, state.slots, spellLevel,
                pact and "ALL" or nil) -- pact magic slots come back on a short rest
            list[#list].usual = usual
        end
    end
    -- A Warlock with another spellcasting class keeps its Pact Magic slots beside the
    -- shared ones; they come back on a short rest.
    for spellLevel = 1, 9 do
        local count = pactSlots and pactSlots[spellLevel]
        if count and count > 0 then
            if type(state.pactSlots) ~= "table" then state.pactSlots = {} end
            add("slot", ("Pact slot (%s level)"):format(R.ORDINALS[spellLevel]), count, count, state.pactSlots, spellLevel, "ALL")
            list[#list].usual, list[#list].pact = count, true
        end
    end
    return list
end

function RPSheet:FindTracker(label)
    for _, tracker in ipairs(self:GetTrackers()) do
        if tracker.label == label then return tracker end
    end
end

-- Keeps every current value inside its limits. `refill` sets them all to their rested value.
function RPSheet:ClampState(refill)
    for _, tracker in ipairs(self:GetTrackers()) do
        local value = tracker.get()
        if refill or type(value) ~= "number" then value = tracker.reset end
        tracker.set(value)
    end
    if refill then
        -- Rested: first uses are free again, and nothing spent before can be taken back.
        self:State().freeUsed = {}
        self:RestoreChosenCastings() -- spells cast once without a slot
        self:ForgetRefunds()
    end
end
