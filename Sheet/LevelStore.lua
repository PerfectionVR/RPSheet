-- Level choices: storing one (its feat goes on the sheet as a passive) and forgetting
-- those of levels the character no longer has.
local _, ns = ...
local R = ns.Rules
local Levels = ns.Levels

local function FeatPassive(sheet, level)
    local key = "level:" .. level
    for index, passive in ipairs(sheet.passives) do
        if passive.auto == key then return passive, index end
    end
end

-- Stores the choice for a level and puts its feat, if any, on the sheet.
-- A saving throw proficiency a level's feat granted is given up with that feat.
local function TakeBackSave(sheet, level)
    local old = sheet.levels[level]
    if old and old.gaveSave then sheet.saves[old.gaveSave] = nil end
end

function Levels.Set(sheet, level, record)
    TakeBackSave(sheet, level)
    local stored = CopyTable(record)
    stored.gaveSave = nil
    sheet.levels[level] = stored

    local passive, index = FeatPassive(sheet, level)
    if record.choice == "FEAT" and record.feat ~= "" then
        local known = R.FEATS[record.feat] -- a listed feat brings its own effects
        local changed = not passive or passive.name ~= record.feat
        if not passive then
            passive = { auto = "level:" .. level, enabled = true, effects = {} }
            sheet.passives[#sheet.passives + 1] = passive
        end
        passive.name = record.feat
        passive.desc = record.featDesc ~= "" and record.featDesc or ("Feat taken at %s."):format(ns.SlotLabel(sheet, level))
        -- Effects are set when the feat is picked; after that they are the player's to edit.
        if changed then passive.effects = CopyTable(known and known.effects or {}) end
        if known and known.save then
            for _, stat in ipairs(R.STATS) do
                if (record.asi[stat] or 0) > 0 and not sheet.saves[stat] then
                    sheet.saves[stat], stored.gaveSave = true, stat
                end
            end
        end
    elseif passive then
        table.remove(sheet.passives, index)
    end
    Levels.Recompute(sheet)
end

-- Forgets the choices of levels the character no longer has, and their feats.
function Levels.Trim(sheet)
    for level in pairs(sheet.levels) do
        if not ns.HasSlot(sheet, level) then
            local _, index = FeatPassive(sheet, level)
            if index then table.remove(sheet.passives, index) end
            TakeBackSave(sheet, level)
            sheet.levels[level] = nil
        end
    end
    Levels.Recompute(sheet)
end
