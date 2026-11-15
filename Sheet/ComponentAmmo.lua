-- Spell components that are pieces of ammunition (Cordon of Arrows; data in
-- Data/SpellComponentKinds.lua): how many the character carries and taking them.
-- Ammunition is carried in bundles, "Arrows (20)", so a bundle counts as the number of
-- pieces in its name. Taking pieces uses up loose ones first; then a bundle is opened,
-- and what is left of it becomes loose pieces ("Arrow") in the inventory.
local _, ns = ...
local RPSheet = ns.addon

-- Pieces in one of an item: 20 for "Arrows (20)", 1 for a loose "Arrow".
local function Pieces(name)
    return tonumber(name:match("%((%d+)%)$")) or 1
end

-- The carried, nonmagical entry of that name that still has some, or nil.
local function Carried(self, name)
    for _, item in ipairs(self:Sheet().items or {}) do
        if item.name == name and not item.magic and (item.qty or 0) > 0 then return item end
    end
end

-- How many pieces of the part's ammunition the character carries.
function RPSheet:AmmoCount(part)
    local count = 0
    for _, kind in ipairs(part.kinds) do
        for _, name in ipairs({ kind.single, kind.bundle }) do
            for _, item in ipairs(self:Sheet().items or {}) do
                if item.name == name and not item.magic and (item.qty or 0) > 0 then count = count + item.qty * Pieces(name) end
            end
        end
    end
    return count
end

-- Takes `need` pieces out of the inventory. Returns how many were taken.
function RPSheet:TakeAmmo(part, need)
    local left = need
    for _, kind in ipairs(part.kinds) do -- loose pieces first
        local item = Carried(self, kind.single)
        while item and left > 0 do
            self:DropItem(item)
            left = left - 1
            item = Carried(self, kind.single)
        end
    end
    for _, kind in ipairs(part.kinds) do -- then a bundle is opened
        local bundle = Carried(self, kind.bundle)
        while bundle and left > 0 do
            local size = Pieces(kind.bundle)
            local used = math.min(left, size)
            self:DropItem(bundle)
            if size > used then self:AddItem(kind.single, size - used) end
            left = left - used
            bundle = Carried(self, kind.bundle)
        end
    end
    return need - left
end
