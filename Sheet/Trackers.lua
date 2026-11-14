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
    if pool.stat then
        return math.max(pool.min or 0, (pool.flat or 0) + self:Mod(pool.stat))
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
    local state, sheet, class = self:State(), self:Sheet(), self:ClassData()
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
    add("hitdice", "Hit Dice", self:Level(), self:Level(), state, "hitDice")
    -- Class resources, then any the subclass brings (Superiority Dice and the like).
    -- A World of Warcraft class can drop some of its base class's resources and add its own.
    local override = R.CLASS_OVERRIDES[sheet.class] or {}
    local dropped = {}
    for _, name in ipairs(override.removePools or {}) do dropped[name] = true end
    local sources = {
        class and class.pools or {}, override.pools or {}, R.SUBCLASS_POOLS[sheet.subclass] or {},
        ns.FeaturePools(sheet), -- features with uses of their own, such as Divine Intervention
        ns.LineagePools(sheet), -- a lineage's once-per-rest spells
    }
    for _, pools in ipairs(sources) do
        for _, pool in ipairs(pools) do
            if not dropped[pool.name] then
                local max = PoolMax(self, pool, self:Level())
                add("pool", pool.name, max, max, state.pool, pool.name, pool.short)
            end
        end
    end
    for _, resource in ipairs(sheet.resources) do
        local max = self:Amount(resource.flat, resource.stat, resource.times)
        add("resource", resource.name, max, resource.startEmpty and 0 or max, state.res, resource.name,
            resource.shortRest and "ALL" or nil)
    end
    local slots = self:SpellSlots()
    local pact = class and class.caster == "PACT"
    for spellLevel = 1, 9 do
        if slots[spellLevel] then
            add("slot", R.ORDINALS[spellLevel] .. "-level slot", slots[spellLevel], slots[spellLevel], state.slots, spellLevel,
                pact and "ALL" or nil) -- pact magic slots come back on a short rest
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
end
