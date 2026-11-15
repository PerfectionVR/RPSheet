-- Getting and losing mounts, vehicles and companion creatures: a new entry from the
-- catalogue (Data/Mounts.lua), adding one for nothing, buying one from the character's
-- coins, and taking one off the list.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- A sheet entry for `name`: filled in from the catalogue when it is listed there,
-- otherwise an empty mount of that name.
function ns.NewMount(name)
    local entry = CopyTable(R.TEMPLATES.mount)
    entry.name = name
    local known = R.MOUNTS[name]
    for key, default in pairs(R.TEMPLATES.mount) do
        if known and known[key] ~= nil and type(known[key]) == type(default) then entry[key] = known[key] end
    end
    return entry
end

-- Adds one without paying: a gift, a reward, something the DM handed out. A companion
-- creature starts with the loyalty its new owner's Charisma gives it.
function RPSheet:AddMount(name)
    local entry = ns.NewMount(name)
    if entry.kind == "COMPANION" then entry.loyalty = self:StartingLoyalty() end
    local mounts = self:Mounts()
    mounts[#mounts + 1] = entry
    return entry
end

-- Why the listed `name` can't be bought, in a few words; nil when it can. Money is not
-- looked at here: RPSheet:CanAfford answers that.
function RPSheet:MountNotSold(name)
    local known = R.MOUNTS[name]
    if not known then return "it is not listed" end
    if known.unsold then return "it can't be bought" end
    if (known.cost or 0) <= 0 then return "it has no listed price" end
    local met, need = ns.MountRenown(self:Sheet(), name)
    if not met then return ("it is only sold to those with %s"):format(need) end
end

-- Pays for a listed mount or vehicle and adds it. False when it isn't sold to this
-- character or the character can't afford it.
function RPSheet:BuyMount(name)
    local why = self:MountNotSold(name)
    if why then
        self:Print(("You can't buy %s: %s."):format(name, why))
        return false
    end
    -- The price is the one for whoever the character is buying from (Sheet/Shop.lua).
    local price, percent, faction = self:MountBuyPrice(name)
    local label = percent and ("%s, %d%% off with %s"):format(name, percent, faction) or name
    if not self:SpendCoins(price, label) then return false end
    self:AddMount(name)
    return true
end

-- The first owned entry of that name, if there is one.
function RPSheet:OwnedMount(name)
    for _, entry in ipairs(self:Sheet().mounts or {}) do
        if entry.name == name then return entry end
    end
end

-- Takes an entry off the list.
function RPSheet:RemoveMount(entry)
    local mounts = self:Mounts()
    for index, other in ipairs(mounts) do
        if other == entry then
            table.remove(mounts, index)
            return
        end
    end
end
