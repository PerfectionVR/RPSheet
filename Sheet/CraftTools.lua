-- Carrying the tool: making something takes the tool in hand, not only knowing how
-- to use it. The character needs one of the profession's tools that it is proficient
-- with among its items (Tools tab of the item browser). A setting under Customize,
-- Professions switches the check off, for a table where the DM rules otherwise.
local _, ns = ...
local RPSheet = ns.addon

-- True while the check is on. A character from before this setting has it on.
function RPSheet:ToolCheckOn()
    return self:Sheet().toolsWaived ~= true
end

-- The tool the character makes things with: the first of the profession's tools it is
-- proficient with and, while the check is on, carries. Nil when there is none; the
-- second value then lists the tools it is proficient with but doesn't carry.
function RPSheet:CraftTool(profession)
    local proficient, check = {}, self:ToolCheckOn()
    for _, name in ipairs(profession.tools or {}) do
        if self:ToolSource(name) then
            local carried = self:CarriedItem(name)
            if not check or (carried and (carried.qty or 0) > 0) then return name end
            proficient[#proficient + 1] = name
        end
    end
    return nil, proficient
end

-- Why the character can't work at a profession for want of its tool, with the two
-- ways out, or nil when it can (or when it isn't proficient, which is another matter).
function RPSheet:MissingTool(profession)
    local tool, proficient = self:CraftTool(profession)
    if tool or #proficient == 0 then return nil end
    return ("you don't carry your %s (add or buy it in the item browser under Tools; a DM's ruling can switch this check off under Customize, Professions)")
        :format(table.concat(proficient, " or "))
end
