-- Swimming, climbing and flying speeds as numbers of their own (words and the list of
-- what grants one: Data/MoveSpeeds.lua). A character has such a speed from a beast
-- form, a feat or feature, a loyal companion, an effect of an item or passive that
-- sets it, or the mount it rides; with none of those the sheet shows nothing.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

local NONE = {}

-- What makes this speed equal to the walking speed right now: its name, or nil.
local function WalkSource(self, kind)
    local from = self:EffectSource(R.MOVE_TARGET[kind], "WALK")
    if from then return from end
    for _, passive in ipairs(self:Sheet().passives or NONE) do
        local grant = passive.enabled and R.MOVE_GRANTS[passive.name]
        if grant and grant[kind] then return passive.name end
    end
    local gift, companion = self:CompanionGift()
    if gift and gift.moves and gift.moves[kind] then return companion.name end
end

-- The character's own speed of that kind before anything is added: the highest of
-- what a form has, what an effect sets, and the walking speed where something ties it
-- to that. Returns feet, what gives it, and true when it follows the walking speed;
-- nothing when the character has no such speed.
local function Own(self, kind)
    local best, from, walks
    local function Take(feet, name, walking)
        if not best or feet > best then best, from, walks = feet, name, walking end
    end
    local form = self:Form()
    if form and (form[kind] or 0) > 0 then Take(form[kind], form.beast and (form.name .. " form") or form.name) end
    local floor, setBy = self:EffectFloor(R.MOVE_TARGET[kind])
    if floor and floor > 0 then Take(floor, setBy) end
    local walker = WalkSource(self, kind)
    if walker then Take(self:Speed(true), walker, true) end
    return best, from, walks
end

-- Feet of swimming, climbing or flying speed (`kind`: "swim", "climb" or "fly"), or
-- nil when the character has none. In the saddle the mount's speeds count in place of
-- your own, as with RPSheet:Speed; the one it is ridden at is the Speed row already.
function RPSheet:MoveSpeed(kind)
    local mount = self:RiddenMount()
    if mount then
        local _, pace = ns.MountPace(mount)
        local feet = mount[kind] or 0
        if feet <= 0 or pace == kind then return nil end
        return self:Immobile() and 0 or feet
    end
    local best = Own(self, kind)
    if not best then return nil end
    if self:Immobile() then return 0 end
    return math.max(0, best + self:Bonus(R.MOVE_TARGET[kind]))
end

-- Explanations are printed for the player, or collected when another player asked
-- (as in Sheet/Explain.lua).
local function Out(self, text)
    if self.explainCapture then
        self.explainCapture[#self.explainCapture + 1] = text
    else
        self:Print(text)
    end
end

function RPSheet:ExplainMoveSpeed(kind)
    local label, noun = R.MOVE_LABELS[kind], R.MOVE_NOUNS[kind]
    local feet = self:MoveSpeed(kind)
    if not feet then
        Out(self, ("You have no %s speed."):format(noun))
        return
    end
    local head = ("%s speed |cffffd100%d ft|r: "):format(label, feet)
    local stuck = self:Immobile()
    if stuck then
        Out(self, head .. ("you are %s."):format(stuck))
        return
    end
    local mount = self:RiddenMount()
    if mount then
        Out(self, head .. ("you are riding %s, and its speeds count in place of your own (%s)."):format(mount.name, ns.MountSpeeds(mount)))
        return
    end
    local best, from, walks = Own(self, kind)
    local text = walks and ("%s makes it equal to your walking speed, %d ft"):format(from, best)
        or ("%s gives %d ft"):format(from, best)
    local added = self:Bonus(R.MOVE_TARGET[kind])
    if added ~= 0 then text = ("%s, and effects on your %s speed add %s"):format(text, noun, ns.Util.Signed(added)) end
    Out(self, head .. text .. ". Your armor and your load don't change a speed that is a number of its own; one that follows your walking speed changes with it.")
end
