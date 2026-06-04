-- Shared NPC filtering for PerpGUI debug list and reactions (EntityList + visibility rules).

PerpCore = PerpCore or {}

local function visibleOnlyFromSettings()
    if PerpGUI and PerpGUI.filterVisibleOnly ~= nil then
        return PerpGUI.filterVisibleOnly
    end
    return true
end

--- Not a player / unknown; has name and position (matches former PerpGUI.IsValidNPC).
--- Pass allowUnnamed = true to also keep entities with empty names (event objects, boss parts).
function PerpCore.IsValidNPCEntity(entity, allowUnnamed)
    if not entity then
        return false
    end
    if not allowUnnamed and (not entity.name or entity.name == "") then
        return false
    end
    if entity.type == 1 or entity.type == 0 then
        return false
    end
    if not entity.pos then
        return false
    end
    return true
end

--- When visible-only is on: Argus.isEntityVisible, else ent.visible. Override skips GUI.
function PerpCore.NpcPassesVisibleRules(entity, visibleOnlyOverride)
    if not entity then
        return false
    end
    local filter = visibleOnlyOverride
    if filter == nil then
        filter = visibleOnlyFromSettings()
    end
    if not filter then
        return true
    end
    if Argus and Argus.isEntityVisible then
        return Argus.isEntityVisible(entity)
    end
    if entity.visible ~= nil then
        return entity.visible
    end
    return true
end

function PerpCore.NpcEntityMatchesContentId(entity, wantContentId)
    if not entity then
        return false
    end
    return tonumber(entity.contentid) == tonumber(wantContentId)
end

--- EntityList filter: contentid=… plus GUI npcFilterString, or baseCsv (default alive,maxdistance=100).
--- mergeGuiFilter false forces baseCsv only.
function PerpCore.BuildNpcEntityListFilter(contentId, baseCsv, mergeGuiFilter)
    local id = tonumber(contentId)
    local prefix = "contentid=" .. tostring(id) .. ","
    if mergeGuiFilter ~= false and PerpGUI and PerpGUI.npcFilterString and PerpGUI.npcFilterString ~= "" then
        return prefix .. PerpGUI.npcFilterString
    end
    baseCsv = baseCsv or "alive,maxdistance=100"
    return prefix .. baseCsv
end

local function forEachEntityList(el, fn)
    if not el or not fn then
        return
    end
    if table.valid and table.valid(el) then
        for _, ent in pairs(el) do
            fn(ent)
        end
    else
        for _, ent in pairs(el) do
            fn(ent)
        end
    end
end

--- Among EntityList hits: valid NPC, exact content id, visible rules; nearest to origin on XZ.
function PerpCore.FindNearestNpcByContentId(contentId, origin, baseCsv, mergeGuiFilter)
    origin = origin or (PerpGUI and PerpGUI.arenaCenter) or { x = 100, y = 0, z = 100 }
    local want = tonumber(contentId)
    local filter = PerpCore.BuildNpcEntityListFilter(contentId, baseCsv, mergeGuiFilter)
    local el = EntityList(filter)
    local bestEnt = nil
    local bestDistSq = math.huge
    forEachEntityList(el, function(ent)
        if not ent or not ent.pos then
            return
        end
        if tonumber(ent.contentid) ~= want then
            return
        end
        if not PerpCore.IsValidNPCEntity(ent) then
            return
        end
        if not PerpCore.NpcPassesVisibleRules(ent) then
            return
        end
        local dx = ent.pos.x - origin.x
        local dz = ent.pos.z - origin.z
        local d2 = dx * dx + dz * dz
        if d2 < bestDistSq then
            bestDistSq = d2
            bestEnt = ent
        end
    end)
    return bestEnt
end

--- Nearest entity by content id on XZ: same as manual EntityList("contentid=…"). No PerpGUI filter merge,
--- no non-empty name requirement, no visibility filter (boss parts / eyes often fail IsValidNPCEntity / isEntityVisible).
--- listCsv is appended after contentid= (default wide maxdistance from player).
function PerpCore.FindNearestEntityByContentIdRelaxed(contentId, origin, listCsv)
    origin = origin or (PerpGUI and PerpGUI.arenaCenter) or { x = 100, y = 0, z = 100 }
    local want = tonumber(contentId)
    listCsv = listCsv or "alive,maxdistance=500"
    local filter = "contentid=" .. tostring(want) .. "," .. listCsv
    local el = EntityList(filter)
    local bestEnt = nil
    local bestDistSq = math.huge
    forEachEntityList(el, function(ent)
        if not ent or not ent.pos then
            return
        end
        if tonumber(ent.contentid) ~= want then
            return
        end
        local dx = ent.pos.x - origin.x
        local dz = ent.pos.z - origin.z
        local d2 = dx * dx + dz * dz
        if d2 < bestDistSq then
            bestDistSq = d2
            bestEnt = ent
        end
    end)
    if bestEnt then
        return bestEnt
    end
    el = EntityList("contentid=" .. tostring(want))
    forEachEntityList(el, function(ent)
        if not ent or not ent.pos then
            return
        end
        if tonumber(ent.contentid) ~= want then
            return
        end
        local dx = ent.pos.x - origin.x
        local dz = ent.pos.z - origin.z
        local d2 = dx * dx + dz * dz
        if d2 < bestDistSq then
            bestDistSq = d2
            bestEnt = ent
        end
    end)
    return bestEnt
end
