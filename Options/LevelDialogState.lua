-- The level dialog's shared state (ns.LevelDialog): the level being decided and the
-- character as the dialog would leave it. The dialog's other parts are the
-- Options/LevelDialog*.lua files; Options/LevelDialog.lua opens it.
local ADDON, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- args: the dialog's options, filled in by the files that follow.
local L = { args = {}, DIALOG = ADDON .. "Level" }
ns.LevelDialog = L

-- L.draft is the level being decided, while the dialog is open:
--   level (the number of the level its choice is kept under, Sheet/ClassSlots.lua),
--   class (the class the level belongs to), classLevel (its level in that class),
--   taking (true when it is a new level), newClass (the first level in that class),
--   kind ("ASI", "BOON" or nil), record (the choice so far), subclass and skill
--   (picked here), reopen (settings were open)

function L.Sheet() return RPSheet:Sheet() end

function L.DraftClass()
    return L.draft and R.CLASSES[L.draft.class]
end

function L.AsksSubclass()
    local class = L.DraftClass()
    return L.draft.classLevel >= R.SUBCLASS_LEVEL and ns.ClassSubclass(L.Sheet(), L.draft.class) == "" and class and #class.subclasses > 0
end

-- The subclass the dialog's class will have once this dialog is confirmed.
function L.SubclassAfter()
    local current = ns.ClassSubclass(L.Sheet(), L.draft.class)
    return current ~= "" and current or L.draft.subclass
end

-- The Fighting Style slot (1 or 2) this level opens, or nil.
function L.StyleSlot()
    if not L.draft or not L.draft.taking then return end
    for _, feature in ipairs(ns.FeaturesGainedAt(L.draft.class, L.SubclassAfter(), L.draft.classLevel)) do
        for slot, name in ipairs(ns.STYLE_FEATURES) do
            if feature.name == name then return slot end
        end
    end
end

-- The whole character as this dialog would leave it: the level being taken counted
-- in, in its class, and the subclass picked here. When an earlier level's choice is
-- looked at again it is the character as it is. The classes' own choices are asked for
-- this character, each class by its own level (Sheet/ClassViews.lua).
function L.Like()
    local subclass = L.SubclassAfter()
    if not L.draft.like or L.draft.likeSubclass ~= subclass then
        local sheet = L.Sheet()
        local level = L.draft.taking and L.draft.classLevel or ns.ClassLevel(sheet, L.draft.class)
        L.draft.like, L.draft.likeSubclass = ns.SheetWith(sheet, L.draft.class, level, subclass), subclass
    end
    return L.draft.like
end

-- Skills the first level of a class taken after the first lets the character pick from.
function L.NewClassSkills()
    if not L.draft or not L.draft.newClass then return {} end
    return ns.MulticlassSkills(L.Sheet(), L.draft.class, L.draft.skill)
end

-- The character as this dialog would leave it, for a list whose options depend on
-- other picks made here (spells that have to be in the spellbook).
function L.Picking()
    return setmetatable({ picks = L.draft.picks }, { __index = L.Like() })
end
