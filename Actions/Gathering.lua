-- The checks of the gathering professions: where the character gathers (which sets
-- the DC and what a find is worth), a d20 check against that DC, and what comes of it.
-- How many days a stretch of a journey lasts and what exactly is found is the DM's
-- call, so only skinning, which gives one find per creature, adds it by itself.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local SKILL = {}
for _, skill in ipairs(R.SKILLS) do SKILL[skill.name] = skill end

-- The row of R.REGIONS a character of that level belongs in.
function ns.RegionForLevel(level)
    for _, region in ipairs(R.REGIONS) do
        if level <= region.top then return region end
    end
    return R.REGIONS[#R.REGIONS]
end

-- Where the character gathers now: the region picked on the sheet, or until one is
-- picked the one for its own level. Kept per game character, not on the sheet.
function RPSheet:GatherRegion()
    return R.REGIONS[self.db.char.gatherRegion] or ns.RegionForLevel(self:Level())
end

-- The next region, or with `back` the one before; it wraps around.
function RPSheet:CycleGatherRegion(back)
    local current = self:GatherRegion()
    for index, region in ipairs(R.REGIONS) do
        if region == current then
            self.db.char.gatherRegion = (index - 1 + (back and -1 or 1)) % #R.REGIONS + 1
        end
    end
    self:PopulateSoon()
end

-- A d20 check against a DC. `label` is the skill it goes by, `shown` how it is
-- announced. `done(d20, total, text)` gets the announcement so far and finishes it.
function RPSheet:RollAgainst(label, shown, mod, mode, dc, done)
    local reliable = (self:Sheet().skills[label] or 0) >= 1 and self:FeatureFlag("reliable")
    self:RollD20(mode, function(d20, note)
        if reliable and d20 < 10 then
            note = ("%s [rolled %d, counts as 10]"):format(note, d20)
            d20 = 10
        end
        done(d20, d20 + mod, ("rolls %s against DC %d"):format(ns.RollText.Check(shown, d20, mod, note), dc))
    end)
end

-- The modifier of a profession's gathering check, and whether the character is
-- proficient in Survival. Archaeology goes by its own skill. Skinning is made with
-- the tools, so the proficiency bonus counts even without the skill.
function RPSheet:GatherMod(profession)
    if profession.skill then return self:SkillMod(SKILL[profession.skill]), true end -- archaeology
    local mod = self:SkillMod(SKILL.Survival)
    if profession.key == "skinning" then
        mod = math.max(mod, self:Mod("WIS") + self:ProficiencyBonus() + self:Bonus("CHECKS"))
    end
    return mod, (self:Sheet().skills.Survival or 0) >= 1
end

-- What a successful check brings in, by profession. `rare` is true when the DC was
-- beaten by enough. Returns the words for the announcement.
local FOUND = {}
local function Journey(_, region, rare)
    return ("finds something for each day of this stretch of the journey, worth %s apiece%s"):format(
        ns.CoinText(region.common), rare and (", one of them rare and worth %s"):format(ns.CoinText(region.rare)) or "")
end
FOUND.herbalism, FOUND.mining = Journey, Journey
function FOUND.fishing() return "catches the fish it was after" end
function FOUND.skinning(self, region, rare)
    local worth = rare and region.rare or region.common
    self:AddMaterials("leather", worth)
    return ("takes %s worth %s"):format(rare and "a hide" or "leather", ns.CoinText(worth))
end

-- The gathering check of a profession: Wisdom (Survival) against the region's DC.
function RPSheet:Gather(profession, mode)
    local can, lacks = self:CanPractise(profession)
    if not can then
        self:Print(("%s needs %s."):format(profession.name, lacks))
        return
    end
    -- Herbalism, mining and skinning are done with their tool in hand, like making
    -- things (Sheet/CraftTools.lua). Fishing asks for none.
    local missing = self:MissingTool(profession)
    if missing then
        self:Print(("You can't go %s: %s."):format(profession.name:lower(), missing))
        return
    end
    local region = self:GatherRegion()
    local mod, skilled = self:GatherMod(profession)
    if profession.key == "skinning" and skilled then
        -- Proficient with the tools and in the skill: advantage, which a chosen
        -- disadvantage cancels.
        mode = mode ~= "DIS" and self:ResolveMode("Survival", "ADV") or nil
    else
        mode = self:ResolveMode("Survival", mode)
    end
    self:RollAgainst("Survival", ("%s, %s"):format(profession.name, ns.Mark("Survival")), mod, mode, region.dc, function(d20, total, text)
        if total < region.dc then
            self:Announce(text .. ": nothing found.")
            return
        end
        self:Announce(("%s: %s."):format(text, FOUND[profession.key](self, region, total >= region.dc + R.RARE_FIND_MARGIN)))
        if profession.key == "fishing" and d20 == 20 then
            self:Print(("A natural 20: the DM may let you pull up a crate of other materials worth %s."):format(ns.CoinText(region.rare)))
        elseif profession.key ~= "skinning" then
            self:Print(("Once the DM has said what you found, add it to your %s on the sheet."):format(R.MATERIALS[profession.yields]:lower()))
        end
    end)
end
