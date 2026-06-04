PerpCore = PerpCore or {}
local AddonName = "PerpCore"

-- Configuration storage
PerpCore.Config = PerpCore.Config or {}

-- Default party roles (placeholders - use Auto-Assign in GUI to populate with full names)
PerpCore.Config.PartyRoles = PerpCore.Config.PartyRoles or {
    MT = "MT",
    OT = "OT",
    H1 = "H1",
    H2 = "H2",
    M1 = "M1",
    M2 = "M2",
    R1 = "R1",
    R2 = "R2",
}

-- Party groups (which roles are in which group)
PerpCore.Config.PartyGroups = PerpCore.Config.PartyGroups or {
    { "MT", "H1", "M1", "R1" }, -- Group[1]
    { "OT", "H2", "M2", "R2" }, -- Group[2]
}

-- Strat selections (set from the PerpGUI "Reactions" tab). Reactions query these to enable
-- or disable strat-specific behaviour.
PerpCore.Config.Strats = PerpCore.Config.Strats or {
    DMUPhase1Arrows = "Default", -- "Default" or "X13"
}

-- DMU Phase 1 "Arrows Strat" accessor ("Default" or "X13").
function PerpCore.GetDMUPhase1ArrowsStrat()
    return (PerpCore.Config.Strats and PerpCore.Config.Strats.DMUPhase1Arrows) or "Default"
end

function PerpCore.SetDMUPhase1ArrowsStrat(value)
    PerpCore.Config.Strats = PerpCore.Config.Strats or {}
    PerpCore.Config.Strats.DMUPhase1Arrows = value or "Default"
end

-- Arena coordinates for Savage content
PerpCore.Arenas = PerpCore.Arenas or {}

-- M11S Arena
PerpCore.Arenas.M9S = {
    Center = { x = 100, y = 0, z = 100 },
    North = { x = 100, y = 0, z = 82 },
    Northeast = { x = 118, y = 0, z = 82 },
    East = { x = 118, y = 0, z = 100 },
    Southeast = { x = 118, y = 0, z = 118 },
    South = { x = 100, y = 0, z = 118 },
    Southwest = { x = 82, y = 0, z = 118 },
    West = { x = 82, y = 0, z = 100 },
    Northwest = { x = 82, y = 0, z = 82 },
}
-- M11S Arena
PerpCore.Arenas.M11S = {
    Center = { x = 100, y = 0, z = 100 },
    North = { x = 100, y = 0, z = 82 },
    Northeast = { x = 118, y = 0, z = 82 },
    East = { x = 118, y = 0, z = 100 },
    Southeast = { x = 118, y = 0, z = 118 },
    South = { x = 100, y = 0, z = 118 },
    Southwest = { x = 82, y = 0, z = 118 },
    West = { x = 82, y = 0, z = 100 },
    Northwest = { x = 82, y = 0, z = 82 },
}

function PerpCore.Initialize()
    d("[PerpCore] Initializing...")
    -- Job modules are automatically loaded via module.def Files= directive
    d("[PerpCore] Loaded successfully!")
end

function PerpCore.GetPlayerFirstName(playerOrFullName)
    local fullName = nil

    if type(playerOrFullName) == "table" then
        fullName = playerOrFullName.name
    elseif type(playerOrFullName) == "string" then
        fullName = playerOrFullName
    end

    if fullName == nil then
        return nil
    end

    return string.match(fullName, "^(%S+)")
end

-- Get a player's role slot (MT/OT/H1/etc) based on their name
-- Accepts: player object (with .name) OR full name string
function PerpCore.GetPlayerRole(playerOrName)
    local fullName = nil

    if type(playerOrName) == "table" then
        fullName = playerOrName.name
    elseif type(playerOrName) == "string" then
        fullName = playerOrName
    end

    if fullName == nil then
        return nil
    end

    for roleSlot, name in pairs(PerpCore.Config.PartyRoles) do
        if name == fullName then
            return roleSlot
        end
    end
    return nil
end

-- Waymark string to ID mapping
PerpCore.WaymarkIDs = {
    A = 1,
    B = 2,
    C = 3,
    D = 4,
    ["1"] = 5,
    ["2"] = 6,
    ["3"] = 7,
    ["4"] = 8,
}

-- Get waymark info by waymark string (A, B, C, D, 1, 2, 3, 4)
-- Returns: { x = number, y = number, z = number, isActive = bool, timeLastModify = int } or nil if invalid
function PerpCore.GetWaymarkInfo(waymark)
    local markerID = PerpCore.WaymarkIDs[tostring(waymark)]
    if markerID == nil then
        return nil
    end

    local x, y, z, isActive, timeLastModify = Argus.getWaymarkInfo(markerID)
    if x == nil then
        return nil
    end

    return {
        x = x,
        y = y,
        z = z,
        isActive = isActive,
        timeLastModify = timeLastModify,
    }
end

-- Get the closest waymark to an entity
-- Accepts: entity object (with .pos) or position table { x, y, z }
-- Returns: { waymark = string, x = number, y = number, z = number, distance = number } or nil if no active waymarks
function PerpCore.GetWaymarkClosestToEntity(entityOrPos)
    local pos = nil

    -- Handle entity object or position table
    if entityOrPos.pos then
        pos = entityOrPos.pos
    elseif entityOrPos.x and entityOrPos.z then
        pos = entityOrPos
    end

    if pos == nil then
        return nil
    end

    local allWaymarks = { "A", "B", "C", "D", "1", "2", "3", "4" }
    local closest = nil
    local closestDist = math.huge

    for _, mark in ipairs(allWaymarks) do
        local info = PerpCore.GetWaymarkInfo(mark)
        if info and info.isActive then
            local dx = info.x - pos.x
            local dz = info.z - pos.z
            local dist = math.sqrt(dx * dx + dz * dz)

            if dist < closestDist then
                closestDist = dist
                closest = {
                    waymark = mark,
                    x = info.x,
                    y = info.y,
                    z = info.z,
                    distance = dist,
                }
            end
        end
    end

    return closest
end

-- Get a player's group index (1 or 2) based on their name or role
-- Accepts: player object (with .name) OR full name string OR first name string OR role slot string (MT/OT/etc)
function PerpCore.GetPlayerGroup(playerOrNameOrRole)
    local role = playerOrNameOrRole

    -- If it's a player object or name, convert to role first
    if type(playerOrNameOrRole) == "table" or
        (type(playerOrNameOrRole) == "string" and not PerpCore.Config.PartyRoles[playerOrNameOrRole]) then
        role = PerpCore.GetPlayerRole(playerOrNameOrRole)
    end

    if role == nil then
        return nil
    end

    for groupIndex, group in ipairs(PerpCore.Config.PartyGroups) do
        for _, roleSlot in ipairs(group) do
            if roleSlot == role then
                return groupIndex
            end
        end
    end
    return nil
end

function PerpCore.HoldActionUntilPot(actionId, offsetSeconds)
    offsetSeconds = offsetSeconds or 0
    local pot = ActionList:Get(1, 846)
    local holdTime = math.floor((pot.cdmax - pot.cd) * 1000) - (offsetSeconds * 1000)
    if holdTime < 0 then holdTime = 0 end
    TensorCore.API.TensorACR.holdActionUntil(actionId, Now() + holdTime)
    d("[PerpCore] Held action " ..
        actionId .. " until pot is ready in " .. holdTime .. "ms (offset: -" .. offsetSeconds .. "s)")
end

-- Get player entity, optionally by perspective name
-- If perspectiveName is provided, finds a player whose name contains that string
-- Falls back to local player if not found or perspectiveName is nil/empty
-- Returns: player entity
function PerpCore.GetPlayer(perspectiveName)
    local me = TensorCore and TensorCore.mGetPlayer() or Player

    if perspectiveName and perspectiveName ~= "" then
        local allPlayers = EntityList("type=1,maxdistance=50")
        if allPlayers then
            for _, player in pairs(allPlayers) do
                if player.name and string.find(player.name, perspectiveName) then
                    return player
                end
            end
        end
    end

    return me
end

-- True if entity looks like a combat player (for party aggregation)
local function IsPartyMemberEntity(ent)
    if not ent then
        return false
    end
    if not ent.name or ent.name == "" then
        return false
    end
    if not ent.type or ent.type ~= 1 then
        return false
    end
    if not ent.job then
        return false
    end
    if ent.job < 1 or ent.job > 42 then
        return false
    end
    return true
end

-- Full party as player entities. TensorCore.getEntityGroupList("Party") often returns only
-- yourself (#1); when that happens we merge TensorCore.entityList("Party"). Also used by
-- PerpGUI.RefreshPartyList (single implementation for GUI + reactions).
function PerpCore.GetPartyEntities()
    local members = {}
    local seen = {}

    local function entityKey(ent)
        if ent.id and ent.id ~= 0 then
            return "id:" .. tostring(ent.id)
        end
        return "name:" .. tostring(ent.name)
    end

    local function addMember(ent)
        if not IsPartyMemberEntity(ent) then
            return
        end
        local key = entityKey(ent)
        if seen[key] then
            return
        end
        seen[key] = true
        table.insert(members, ent)
    end

    if TensorCore and TensorCore.getEntityGroupList then
        local curPt = TensorCore.getEntityGroupList("Party")
        if curPt then
            if #curPt == 1 then
                addMember(curPt[1])
                if TensorCore.entityList then
                    curPt = TensorCore.entityList("Party")
                end
            end
            if curPt then
                for _, ent in pairs(curPt) do
                    addMember(ent)
                end
            end
        end
    end

    if #members <= 1 and TensorCore and TensorCore.entityList then
        local extra = TensorCore.entityList("Party")
        if extra then
            for _, ent in pairs(extra) do
                addMember(ent)
            end
        end
    end

    if #members == 0 and EntityList then
        local party = EntityList("myparty")
        local valid = party and (not table.valid or table.valid(party))
        if party and valid then
            for _, member in pairs(party) do
                addMember(member)
            end
        end
    end

    if #members == 0 and MEntityList then
        local party = MEntityList("myparty,alive,chartype=4")
        local valid = party and (not table.valid or table.valid(party))
        if party and valid then
            for _, member in pairs(party) do
                addMember(member)
            end
        end
    end

    return members
end

--- Print every party member's buffs (name + id), one line per buff.
--- The console d() does not render embedded newlines, so each line is printed with its own d() call.
--- Console use: d(GetPartyMemberBuffs()) or just GetPartyMemberBuffs()
function PerpCore.GetPartyMemberBuffs()
    local members = PerpCore.GetPartyEntities() or {}

    if #members == 0 then
        d("[PartyBuffs] No party members found")
        return "[PartyBuffs] No party members found"
    end

    for _, member in ipairs(members) do
        local firstName = PerpCore.GetPlayerFirstName(member.name) or tostring(member.name)
        d("[PartyBuffs] " .. firstName .. " (id " .. tostring(member.id) .. "):")

        local any = false
        if member.buffs then
            for _, buff in pairs(member.buffs) do
                if buff and buff.id and buff.id > 0 then
                    any = true
                    d(string.format("[PartyBuffs]    - %s (id %s, dur %s, stacks %s)",
                        tostring(buff.name or "Unknown"),
                        tostring(buff.id),
                        tostring(buff.duration or 0),
                        tostring(buff.stacks or 0)))
                end
            end
        end
        if not any then
            d("[PartyBuffs]    - (no buffs)")
        end
    end

    return "[PartyBuffs] Printed buffs for " .. tostring(#members) .. " party member(s)"
end

-- Global alias so it can be called directly from the in-game console: d(GetPartyMemberBuffs())
GetPartyMemberBuffs = PerpCore.GetPartyMemberBuffs

--- Enemies near a player position: attackable, alive, and passing visibility rules.
-- player: entity (e.g. TensorCore.mGetPlayer()) or nil for local player.
-- radius: max horizontal distance in yalms (from player.pos, XZ only — same as PerpCore.GetDistance).
-- visibleOnlyOverride: nil = use PerpGUI.filterVisibleOnly / Argus.isEntityVisible; false = skip visibility filter; true = force visible-only rules.
-- Returns: array of entity tables (order undefined).
function PerpCore.GetSurroundingEnemiesWithinRadius(player, radius, visibleOnlyOverride)
    radius = tonumber(radius)
    if not radius or radius < 0 then
        return {}
    end

    local me = player
    if type(me) ~= "table" then
        me = TensorCore and TensorCore.mGetPlayer() or Player
    end
    if not me or not me.pos then
        return {}
    end

    if not EntityList then
        return {}
    end

    -- EntityList maxdistance is from the local client; widen if measuring from another entity's position.
    local sep = 0
    if Player and Player.pos and me.pos then
        if not me.id or not Player.id or me.id ~= Player.id then
            sep = PerpCore.GetDistance(Player.pos, me.pos)
        end
    end
    local maxFetch = math.max(1, math.ceil(radius + sep + 1))
    local csv = "alive,attackable,maxdistance=" .. tostring(maxFetch)
    local el = EntityList(csv)
    local out = {}

    local function consider(ent)
        if not ent or not ent.pos then
            return
        end
        if me.id and ent.id and ent.id == me.id then
            return
        end
        if ent.alive == false then
            return
        end
        if PerpCore.GetDistance(me.pos, ent.pos) > radius then
            return
        end
        if not PerpCore.NpcPassesVisibleRules(ent, visibleOnlyOverride) then
            return
        end
        table.insert(out, ent)
    end

    if el then
        if table and table.valid and table.valid(el) then
            for _, ent in pairs(el) do
                consider(ent)
            end
        else
            for _, ent in pairs(el) do
                consider(ent)
            end
        end
    end

    return out
end

-- ============================================================================
-- Angle/Position Utilities
-- ============================================================================

-- Calculate angle from arena center to a position
-- Returns angle in radians where north=0, clockwise positive (0 to 2π)
-- If northToleranceDeg is provided, angles within that many degrees of 360° will be
-- wrapped to negative values so they sort before small positive angles
-- Accepts: pos = { x, z } or { x, y, z }, center = { x, z } or arena table with .Center
function PerpCore.GetAngleFromCenter(pos, centerOrArena, northToleranceDeg)
    local center = centerOrArena
    if centerOrArena.Center then
        center = centerOrArena.Center
    end

    local dx = pos.x - center.x
    local dz = pos.z - center.z
    -- atan2(dx, -dz) gives angle where north=0, clockwise positive
    local angle = math.atan2(dx, -dz)

    -- Normalize to 0 to 2π range
    if angle < 0 then
        angle = angle + 2 * math.pi
    end

    -- Optionally wrap angles close to 360° to negative
    if northToleranceDeg and northToleranceDeg > 0 then
        local northToleranceRad = math.rad(northToleranceDeg)
        if angle > (2 * math.pi - northToleranceRad) then
            angle = angle - 2 * math.pi
        end
    end

    return angle
end

-- Add angles to a list of positions relative to arena center
-- positions: table of { x, z, ... } objects
-- centerOrArena: { x, z } or arena table with .Center
-- northToleranceDeg: optional, degrees within 360° to wrap to negative
-- Returns: table of { item = original position, angle = calculated angle }
function PerpCore.AddAnglesFromCenter(positions, centerOrArena, northToleranceDeg)
    local result = {}
    for i, pos in ipairs(positions) do
        local angle = PerpCore.GetAngleFromCenter(pos, centerOrArena, northToleranceDeg)
        result[i] = { item = pos, angle = angle }
    end
    return result
end

-- Sort positions with angles clockwise from north (ascending angle)
-- positionsWithAngles: table of { item = ..., angle = ... } from AddAnglesFromCenter
-- Returns: sorted table (modifies in place and returns)
function PerpCore.SortClockwiseFromNorth(positionsWithAngles)
    table.sort(positionsWithAngles, function(a, b)
        return a.angle < b.angle
    end)
    return positionsWithAngles
end

-- Sort positions with angles counter-clockwise from north (descending angle)
-- positionsWithAngles: table of { item = ..., angle = ... } from AddAnglesFromCenter
-- Returns: sorted table (modifies in place and returns)
function PerpCore.SortCounterClockwiseFromNorth(positionsWithAngles)
    table.sort(positionsWithAngles, function(a, b)
        return a.angle > b.angle
    end)
    return positionsWithAngles
end

-- Convenience function: Add angles and sort clockwise from north in one call
-- Returns: sorted table of { item = original position, angle = calculated angle }
function PerpCore.SortPositionsClockwise(positions, centerOrArena, northToleranceDeg)
    local withAngles = PerpCore.AddAnglesFromCenter(positions, centerOrArena, northToleranceDeg)
    return PerpCore.SortClockwiseFromNorth(withAngles)
end

-- Convenience function: Add angles and sort counter-clockwise from north in one call
-- Returns: sorted table of { item = original position, angle = calculated angle }
function PerpCore.SortPositionsCounterClockwise(positions, centerOrArena, northToleranceDeg)
    local withAngles = PerpCore.AddAnglesFromCenter(positions, centerOrArena, northToleranceDeg)
    return PerpCore.SortCounterClockwiseFromNorth(withAngles)
end

-- Calculate distance between two positions
-- Accepts: pos1 = { x, z }, pos2 = { x, z }
-- Returns: distance in yalms
function PerpCore.GetDistance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dz = pos2.z - pos1.z
    return math.sqrt(dx * dx + dz * dz)
end

-- Get the center point between two positions
-- Accepts: pos1 = { x, z }, pos2 = { x, z }, optionalY = number
-- Returns: { x, y, z }
function PerpCore.GetCenterPoint(pos1, pos2, optionalY)
    return {
        x = (pos1.x + pos2.x) / 2,
        y = optionalY or pos1.y or pos2.y or 0,
        z = (pos1.z + pos2.z) / 2,
    }
end

-- Find the largest gap between consecutive items in a sorted circular list
-- sortedPositions: table of { item = { x, z, ... }, angle = ... } sorted by angle
-- Returns: { gapIndex = index of first item, distance = gap distance, pos1 = first item, pos2 = second item }
function PerpCore.FindLargestGap(sortedPositions)
    local count = #sortedPositions
    if count < 2 then return nil end

    local largestGap = 0
    local gapIndex = 1

    for i = 1, count do
        local current = sortedPositions[i].item
        local next = sortedPositions[(i % count) + 1].item
        local distance = PerpCore.GetDistance(current, next)

        if distance > largestGap then
            largestGap = distance
            gapIndex = i
        end
    end

    return {
        gapIndex = gapIndex,
        distance = largestGap,
        pos1 = sortedPositions[gapIndex].item,
        pos2 = sortedPositions[(gapIndex % count) + 1].item,
    }
end

-- ============================================================================
-- AOE / Safespot Utilities
-- ============================================================================

-- Flat list of every active ground + directional AOE.
function PerpCore.GetActiveAOEs()
    local out = {}
    if Argus then
        if Argus.getCurrentGroundAOEs then
            for _, a in pairs(Argus.getCurrentGroundAOEs() or {}) do out[#out + 1] = a end
        end
        if Argus.getCurrentDirectionalAOEs then
            for _, a in pairs(Argus.getCurrentDirectionalAOEs(true) or {}) do out[#out + 1] = a end
        end
    end
    return out
end

-- Active AOEs whose aoeID matches the given id.
function PerpCore.GetActiveAOEsById(aoeId)
    aoeId = tonumber(aoeId)
    local out = {}
    for _, a in ipairs(PerpCore.GetActiveAOEs()) do
        if tonumber(a.aoeID) == aoeId then
            out[#out + 1] = a
        end
    end
    return out
end

-- Rotate an AOE 90 degrees clockwise about a centre (position + facing). World axes are +X east,
-- +Z south, so a clockwise rotation maps (dx,dz) -> (-dz, dx). The heading is rotated the same way
-- by reading the forward vector, rotating it, and converting back to a heading. Returns x, z, heading.
function PerpCore.RotateAOEClockwise(x, y, z, heading, center)
    center = center or { x = 100, y = 0, z = 100 }
    local dx, dz = x - center.x, z - center.z
    local rx     = center.x - dz
    local rz     = center.z + dx
    local h      = heading
    if TensorCore and TensorCore.getPosInDirection and TensorCore.getHeadingToTarget then
        local fwd = TensorCore.getPosInDirection({ x = x, y = y, z = z }, heading, 10)
        if fwd then
            local vx, vz   = fwd.x - x, fwd.z - z
            local rvx, rvz = -vz, vx
            h = TensorCore.getHeadingToTarget({ x = rx, y = y, z = rz }, { x = rx + rvx, y = y, z = rz + rvz })
        end
    end
    return rx, rz, h
end

-- Draw a filled Argus2 shape matching an AOE cast type, in a solid colour.
function PerpCore.DrawAOEShape(color, x, y, z, castType, length, width, heading, ms)
    if not Argus2 then return end
    local ct  = tonumber(castType) or 0
    local L   = tonumber(length) or 0
    local W   = tonumber(width) or 0
    local h   = tonumber(heading) or 0
    local SEG = 48
    if ct == 2 or ct == 5 or ct == 7 or ct == 6 then
        Argus2.addTimedCircleFilled(ms, x, y, z, L, SEG, color, color, nil, 0, nil, nil, nil, 3)
    elseif ct == 3 or ct == 13 then
        Argus2.addTimedConeFilled(ms, x, y, z, L, math.rad(90), h, SEG, color, color, nil, 0, nil, nil, nil, nil, 4)
    elseif ct == 4 or ct == 12 or ct == 8 then
        Argus2.addTimedRectFilled(ms, x, y, z, L, W, h, color, color, nil, 0, nil, nil, false, nil, nil, 4)
    elseif ct == 10 then
        local inner = W > 0 and W or (L * 0.4)
        Argus2.addTimedDonutFilled(ms, x, y, z, inner, L, SEG, color, color, nil, 0, nil, nil, nil, 2)
    elseif ct == 11 then
        Argus2.addTimedCrossFilled(ms, x, y, z, L, W, h, color, color, nil, 0, nil, nil, nil, nil, 4)
    else
        Argus2.addTimedCircleFilled(ms, x, y, z, (L > 0 and L or 3), SEG, color, color, nil, 0, nil, nil, nil, 3)
    end
end

-- Highlight AOE-derived safespots. Finds active AOEs with opts.aoeId; if fewer than opts.minCount
-- (default 2) are present yet, returns 0 so the caller can stay armed. Otherwise draws each in
-- opts.color (default solid green). When opts.rotate is true the AOE (position + facing) is first
-- rotated 90 degrees clockwise about opts.center (default arena centre 100,0,100) -- turning a danger
-- zone into its safe spot. Per-AOE duration is used unless opts.drawMs is given. Returns count drawn.
function PerpCore.DrawAOESafespots(opts)
    opts = opts or {}
    if not Argus2 or not GUI then return 0 end

    local center   = opts.center or { x = 100, y = 0, z = 100 }
    local minCount = opts.minCount or 2
    local color    = opts.color or GUI:ColorConvertFloat4ToU32(0, 1, 0, 1)

    local matches = PerpCore.GetActiveAOEsById(opts.aoeId)
    if #matches < minCount then
        return 0
    end

    for _, a in ipairs(matches) do
        local x = tonumber(a.x) or 0
        local y = tonumber(a.y) or 0
        local z = tonumber(a.z) or 0
        local h = tonumber(a.heading) or 0
        local ms = opts.drawMs or ((tonumber(a.duration) or 6) * 1000)
        if opts.rotate then
            x, z, h = PerpCore.RotateAOEClockwise(x, y, z, h, center)
        end
        PerpCore.DrawAOEShape(color, x, y, z, a.aoeCastType, a.aoeLength, a.aoeWidth, h, ms)
    end
    return #matches
end

RegisterEventHandler("Module.Initalize", PerpCore.Initialize, AddonName)
