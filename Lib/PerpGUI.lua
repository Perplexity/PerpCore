-- PerpGUI: GUI for PerpCore configuration
-- Based on mmominion GUI API and MuAiCore patterns

PerpGUI = PerpGUI or {}
PerpGUI.open = false
PerpGUI.visible = true

-- Keybind settings (Ctrl + P by default)
PerpGUI.keyBindFirst = 17  -- Ctrl
PerpGUI.keyBindSecond = 80 -- P

-- Tab system (vertical sidebar like AnyoneCore)
PerpGUI.currentTab = "party" -- party, debug, reactions
PerpGUI.sidebarWidth = 60
PerpGUI.tabs = {
    { id = "party",     label = "Party Roles", icon = "party.png" },
    { id = "reactions", label = "Reactions",   icon = "reactions.png" },
    { id = "debug",     label = "Debug",       icon = "debug.png" },
}
PerpGUI.iconBasePath = nil -- Set in Initialize
PerpGUI.iconSize = 28

-- Role display order for the GUI
PerpGUI.roleOrder = { "MT", "OT", "H1", "H2", "M1", "M2", "R1", "R2" }

-- Role descriptions
PerpGUI.roleDescriptions = {
    MT = "Main Tank",
    OT = "Off Tank",
    H1 = "Healer 1",
    H2 = "Healer 2",
    M1 = "Melee 1",
    M2 = "Melee 2",
    R1 = "Phys Ranged",
    R2 = "Caster",
}

-- Cached party list for assignment
PerpGUI.partyCache = {}
PerpGUI.lastPartyRefresh = 0

-- Default fallback roles (empty - use Auto-Assign to populate with full names)
PerpGUI.defaultRoles = {
    MT = "",
    OT = "",
    H1 = "",
    H2 = "",
    M1 = "",
    M2 = "",
    R1 = "",
    R2 = "",
}

-- Drag state (following MuAiCore pattern)
PerpGUI.mousePosition = nil
PerpGUI.selected = nil

-- Debug tab state (use nil checks to preserve values between reloads)
PerpGUI.npcCache = PerpGUI.npcCache or {}
PerpGUI.lastNPCRefresh = PerpGUI.lastNPCRefresh or 0
PerpGUI.selectedNPCId = PerpGUI.selectedNPCId -- nil is valid
PerpGUI.cardinalArrowLength = PerpGUI.cardinalArrowLength or 5.0
PerpGUI.arrowColor = PerpGUI.arrowColor or 0xFF00FF00
PerpGUI.arrowOutlineColor = PerpGUI.arrowOutlineColor or 0xFF00AA00
PerpGUI.cardinalTextUUIDs = PerpGUI.cardinalTextUUIDs or {}
PerpGUI.lastCardinalTextUpdate = PerpGUI.lastCardinalTextUpdate or 0
PerpGUI.arenaCenter = PerpGUI.arenaCenter or { x = 100, y = 0, z = 100 }
PerpGUI.centerCircleColor = PerpGUI.centerCircleColor or { r = 1.0, g = 0.0, b = 0.0, a = 1.0 } -- Default red
PerpGUI.lastNPCDebugTextUpdate = PerpGUI.lastNPCDebugTextUpdate or 0
PerpGUI.lastPlayerDebugUpdate = PerpGUI.lastPlayerDebugUpdate or 0
PerpGUI.npcFilterString = PerpGUI.npcFilterString or "alive,maxdistance=100"

-- Boolean toggles (default to specific values only if nil)
if PerpGUI.drawArrowToNPC == nil then PerpGUI.drawArrowToNPC = false end
if PerpGUI.drawCardinalArrows == nil then PerpGUI.drawCardinalArrows = false end
if PerpGUI.filterVisibleOnly == nil then PerpGUI.filterVisibleOnly = true end  -- Default ON
if PerpGUI.filterShowUnnamed == nil then PerpGUI.filterShowUnnamed = false end -- Default OFF (show unnamed/event objects)
if PerpGUI.drawArenaCenter == nil then PerpGUI.drawArenaCenter = false end
if PerpGUI.drawNPCDebugText == nil then PerpGUI.drawNPCDebugText = false end
if PerpGUI.drawPlayerDebug == nil then PerpGUI.drawPlayerDebug = false end
if PerpGUI.drawGroundAOEDebug == nil then PerpGUI.drawGroundAOEDebug = false end

-- Misc / Reactions: attack-range ring on current target (hitbox + job-based reach: 3 melee/tank, 25 ranged)
if PerpGUI.drawAttackRangeOnTarget == nil then PerpGUI.drawAttackRangeOnTarget = false end
PerpGUI.attackRangeRingColor = PerpGUI.attackRangeRingColor or { r = 0.2, g = 0.85, b = 0.38, a = 0.78 }
if PerpGUI.attackRangeMeleeYalms == nil then PerpGUI.attackRangeMeleeYalms = 3 end
if PerpGUI.attackRangeRangedYalms == nil then PerpGUI.attackRangeRangedYalms = 25 end

-- Reactions tab: DMU settings (content-specific)
PerpGUI.dmu                      = PerpGUI.dmu or {}
PerpGUI.dmu.p1ArrowsStratOptions = PerpGUI.dmu.p1ArrowsStratOptions or
    { [1] = "Default (2x2)", [2] = "Merry-go Round", [3] = "Freaky" }
PerpGUI.dmu.p1ArrowsStratValues  = PerpGUI.dmu.p1ArrowsStratValues or
    { [1] = "Default", [2] = "MerryGoRound", [3] = "Freaky" }
if PerpGUI.dmu.p1ArrowsStratIndex == nil then
    PerpGUI.dmu.p1ArrowsStratIndex = PerpGUI.dmuP1ArrowsStratIndex or 1
end
PerpGUI.dmu.p3BlackHoleStratOptions = PerpGUI.dmu.p3BlackHoleStratOptions or
    { [1] = "Markers (piR)", [2] = "Kefka Relative (ZsQ)" }
PerpGUI.dmu.p3BlackHoleStratValues  = PerpGUI.dmu.p3BlackHoleStratValues or { [1] = "Markers", [2] = "KefkaRelative" }
if PerpGUI.dmu.p3BlackHoleStratIndex == nil then
    PerpGUI.dmu.p3BlackHoleStratIndex = PerpGUI.dmuP3BlackHoleStratIndex or 1
end
PerpGUI.dmu.optimisation = PerpGUI.dmu.optimisation or {}
PerpGUI.dmu.optimisation.ninja = PerpGUI.dmu.optimisation.ninja or {}
if PerpGUI.dmu.optimisation.ninja.zeroGcdOpener == nil then
    PerpGUI.dmu.optimisation.ninja.zeroGcdOpener = PerpGUI.dmu.optimisation.ninja.ninjaZeroGcdOpener
        or PerpGUI.dmu.optimisation.ninjaZeroGcdOpener
        or PerpGUI.ninjaZeroGcdOpener
        or false
end

-- Samurai job-specific overlay (Misc / Reactions)
PerpGUI.JOB_SAMURAI = PerpGUI.JOB_SAMURAI or 34
if PerpGUI.drawSamuraiMidareRange == nil then PerpGUI.drawSamuraiMidareRange = false end
PerpGUI.midareRangeColor = PerpGUI.midareRangeColor or { r = 0.95, g = 0.25, b = 0.15, a = 0.85 }
if PerpGUI.midareRangeExtraYalms == nil then PerpGUI.midareRangeExtraYalms = 6 end

PerpGUI.JOB_NINJA = PerpGUI.JOB_NINJA or 30

-- Debug arrow from center settings
if PerpGUI.drawDebugArrow == nil then PerpGUI.drawDebugArrow = false end
PerpGUI.debugArrowDegree = PerpGUI.debugArrowDegree or 0
PerpGUI.debugArrowLength = PerpGUI.debugArrowLength or 10
PerpGUI.debugArrowColor = PerpGUI.debugArrowColor or { r = 1.0, g = 0.5, b = 0.0, a = 1.0 } -- Orange default

-- Custom AOE drawings (debug builder): a user-editable list of shapes drawn every frame.
-- Each entry = { shape (1-based), x, y, z, length, width, heading (degrees), color = {r,g,b,a} }.
PerpGUI.customAOEs = PerpGUI.customAOEs or {}
PerpGUI.lastCustomAOEUpdate = PerpGUI.lastCustomAOEUpdate or 0
if PerpGUI.drawCustomAOEs == nil then PerpGUI.drawCustomAOEs = false end
if PerpGUI.customAOEUseOldDraws == nil then PerpGUI.customAOEUseOldDraws = false end
if PerpGUI.customAOEClickPlace == nil then PerpGUI.customAOEClickPlace = false end
PerpGUI.customAOEClickPlaceMode  = PerpGUI.customAOEClickPlaceMode or 1 -- 1=Add, 2=Move selected
PerpGUI.customAOEMoveIndex       = PerpGUI.customAOEMoveIndex or 1
PerpGUI.customAOEClickPlaceModes = { [1] = "Add new", [2] = "Move selected" }
-- Shape dropdown (1-based) -> PerpCore.DrawAOEShape castType (2=circle, 10=donut, 4=rect, 3=cone, 11=cross).
PerpGUI.customAOEShapeOptions    = { [1] = "Circle", [2] = "Donut", [3] = "Rect", [4] = "Cone", [5] = "Cross" }
PerpGUI.customAOEShapeCastTypes  = { [1] = 2, [2] = 10, [3] = 4, [4] = 3, [5] = 11 }

-- Map effects explorer (Argus OnMapEffect dev tool)
PerpGUI.mapEffectsCache          = PerpGUI.mapEffectsCache or {}
PerpGUI.mapEffectSearchFilter    = PerpGUI.mapEffectSearchFilter or ""
PerpGUI.mapEffectSelectedIndex   = PerpGUI.mapEffectSelectedIndex or -1
if PerpGUI.showMapEffectsExplorer == nil then PerpGUI.showMapEffectsExplorer = false end
if PerpGUI.drawMapEffectWorldText == nil then PerpGUI.drawMapEffectWorldText = false end
if PerpGUI.showNPCInspector == nil then PerpGUI.showNPCInspector = true end
PerpGUI.lastInspectorNPCId = PerpGUI.lastInspectorNPCId
PerpGUI.lastMapEffectWorldTextUpdate = PerpGUI.lastMapEffectWorldTextUpdate or 0
PerpGUI.mapEffectTypeNames = { [2] = "Model", [4] = "VFX", [6] = "Script", [7] = "Sound" }

-- Waymark line toggles (default off)
if PerpGUI.drawWaymarkA == nil then PerpGUI.drawWaymarkA = false end
if PerpGUI.drawWaymarkB == nil then PerpGUI.drawWaymarkB = false end
if PerpGUI.drawWaymarkC == nil then PerpGUI.drawWaymarkC = false end
if PerpGUI.drawWaymarkD == nil then PerpGUI.drawWaymarkD = false end
if PerpGUI.drawWaymark1 == nil then PerpGUI.drawWaymark1 = false end
if PerpGUI.drawWaymark2 == nil then PerpGUI.drawWaymark2 = false end
if PerpGUI.drawWaymark3 == nil then PerpGUI.drawWaymark3 = false end
if PerpGUI.drawWaymark4 == nil then PerpGUI.drawWaymark4 = false end
if PerpGUI.drawNPCToNearestWaymark == nil then PerpGUI.drawNPCToNearestWaymark = false end

-- Cardinal direction colors (relative to player-to-NPC direction)
PerpGUI.cardinalColors = {
    N  = 0xFFFF0000, -- Red (toward NPC / away from player)
    NE = 0xFFFF8800, -- Orange
    E  = 0xFFFFFF00, -- Yellow
    SE = 0xFF88FF00, -- Lime
    S  = 0xFF00FF00, -- Green (toward player / away from NPC)
    SW = 0xFF00FFFF, -- Cyan
    W  = 0xFF0088FF, -- Light Blue
    NW = 0xFFFF00FF, -- Magenta
}

-- Waymark colors (ABGR format for Argus)
PerpGUI.waymarkColors = {
    A = 0xFF0000FF,     -- Red
    B = 0xFF00FFFF,     -- Yellow
    C = 0xFFFF0000,     -- Blue
    D = 0xFFFF00FF,     -- Purple
    ["1"] = 0xFF0000FF, -- Red
    ["2"] = 0xFF00FFFF, -- Yellow
    ["3"] = 0xFFFF0000, -- Blue
    ["4"] = 0xFFFF00FF, -- Purple
}

-- Job icon path helper
function PerpGUI.GetJobIconPath(jobId, role)
    local basePath = GetLuaModsPath() .. "\\PerpCore\\Images\\Jobs\\"

    if jobId then
        local iconPath = basePath .. tostring(jobId) .. ".png"
        -- Check if specific job icon exists (we have icons for jobs 19+)
        if jobId >= 19 then
            return iconPath
        end
    end

    -- Fallback to role icons
    if role == "MT" or role == "OT" then
        return basePath .. "TankRole.png"
    elseif role == "H1" or role == "H2" then
        return basePath .. "HealerRole.png"
    else
        return basePath .. "DPSRole.png"
    end
end

-- Toggle the GUI
function PerpGUI.Toggle()
    PerpGUI.open = not PerpGUI.open
end

-- Update function - check for keybind
function PerpGUI.Update(event, ticks)
    if GUI:IsKeyDown(PerpGUI.keyBindFirst) and GUI:IsKeyPressed(PerpGUI.keyBindSecond) then
        PerpGUI.Toggle()
    end
end

-- Get first name from full name
function PerpGUI.GetFirstName(fullName)
    if not fullName then return nil end
    return string.match(fullName, "^(%S+)")
end

-- Check if entity is a valid player
function PerpGUI.IsValidPlayer(entity)
    if not entity then return false end
    if not entity.name or entity.name == "" then return false end
    if entity.type ~= 1 then return false end
    if not entity.job then return false end
    -- Job IDs 1-42 are valid combat/crafting/gathering jobs
    if entity.job < 1 or entity.job > 42 then return false end
    return true
end

-- Refresh party list cache
function PerpGUI.RefreshPartyList()
    PerpGUI.partyCache = {}

    local members = PerpCore.GetPartyEntities()

    -- Process members into cache
    for _, member in ipairs(members) do
        local firstName = PerpGUI.GetFirstName(member.name)
        if firstName then
            table.insert(PerpGUI.partyCache, {
                name = member.name,
                firstName = firstName,
                job = member.job,
                id = member.id,
            })
        end
    end

    PerpGUI.lastPartyRefresh = Now()
    d("[PerpGUI] Party refreshed: " .. tostring(#PerpGUI.partyCache) .. " members found")
end

-- Check if a player is already assigned to any role (by full name)
function PerpGUI.IsPlayerAssigned(fullName)
    for _, role in ipairs(PerpGUI.roleOrder) do
        if PerpCore.Config.PartyRoles[role] == fullName then
            return true, role
        end
    end
    return false, nil
end

-- Determine the ideal role for a job
function PerpGUI.GetIdealRole(jobId)
    if IsTank(jobId) then
        return "tank"
    elseif IsHealer(jobId) then
        return "healer"
    elseif IsMeleeDPS(jobId) then
        return "melee"
    elseif IsPhysicalDPS(jobId) and IsRangedDPS(jobId) then
        return "physranged"
    elseif IsCasterDPS(jobId) then
        return "caster"
    elseif IsRangedDPS(jobId) then
        return "ranged"
    end
    return "dps"
end

-- Auto-assign all party members to roles based on their jobs
function PerpGUI.AutoAssignRoles()
    PerpGUI.RefreshPartyList()

    -- Clear all current assignments
    for _, role in ipairs(PerpGUI.roleOrder) do
        PerpCore.Config.PartyRoles[role] = ""
    end

    -- Categorize players by role type
    local tanks = {}
    local healers = {}
    local melees = {}
    local physRanged = {}
    local casters = {}
    local otherDPS = {}

    for _, member in ipairs(PerpGUI.partyCache) do
        local roleType = PerpGUI.GetIdealRole(member.job)

        if roleType == "tank" then
            table.insert(tanks, member)
        elseif roleType == "healer" then
            table.insert(healers, member)
        elseif roleType == "melee" then
            table.insert(melees, member)
        elseif roleType == "physranged" then
            table.insert(physRanged, member)
        elseif roleType == "caster" then
            table.insert(casters, member)
        else
            table.insert(otherDPS, member)
        end
    end

    -- Assign tanks (use full name for consistency)
    if #tanks >= 1 then PerpCore.Config.PartyRoles.MT = tanks[1].name end
    if #tanks >= 2 then PerpCore.Config.PartyRoles.OT = tanks[2].name end

    -- Assign healers
    if #healers >= 1 then PerpCore.Config.PartyRoles.H1 = healers[1].name end
    if #healers >= 2 then PerpCore.Config.PartyRoles.H2 = healers[2].name end

    -- Assign melees
    if #melees >= 1 then PerpCore.Config.PartyRoles.M1 = melees[1].name end
    if #melees >= 2 then PerpCore.Config.PartyRoles.M2 = melees[2].name end

    -- Assign physical ranged
    if #physRanged >= 1 then PerpCore.Config.PartyRoles.R1 = physRanged[1].name end

    -- Assign caster
    if #casters >= 1 then PerpCore.Config.PartyRoles.R2 = casters[1].name end

    -- Fill remaining slots with leftover DPS
    local remainingDPS = {}
    for i = 3, #melees do table.insert(remainingDPS, melees[i]) end
    for i = 2, #physRanged do table.insert(remainingDPS, physRanged[i]) end
    for i = 2, #casters do table.insert(remainingDPS, casters[i]) end
    for _, member in ipairs(otherDPS) do table.insert(remainingDPS, member) end

    local dpsRoles = { "M1", "M2", "R1", "R2" }
    local remainingIdx = 1
    for _, role in ipairs(dpsRoles) do
        if PerpCore.Config.PartyRoles[role] == "" and remainingIdx <= #remainingDPS then
            PerpCore.Config.PartyRoles[role] = remainingDPS[remainingIdx].name
            remainingIdx = remainingIdx + 1
        end
    end

    d("[PerpGUI] Auto-assignment complete")
end

-- Swap two roles
function PerpGUI.SwapRoles(role1, role2)
    local temp = PerpCore.Config.PartyRoles[role1]
    PerpCore.Config.PartyRoles[role1] = PerpCore.Config.PartyRoles[role2]
    PerpCore.Config.PartyRoles[role2] = temp
    d("[PerpGUI] Swapped: " .. role1 .. " <=> " .. role2)
end

-- Clear all role assignments
function PerpGUI.ResetToDefaults()
    for role, name in pairs(PerpGUI.defaultRoles) do
        PerpCore.Config.PartyRoles[role] = name
    end
    d("[PerpGUI] Cleared all role assignments")
end

-- Get job name for display
function PerpGUI.GetJobName(jobId)
    local jobNames = {
        [0] = "ADV",
        [1] = "GLA",
        [2] = "PGL",
        [3] = "MRD",
        [4] = "LNC",
        [5] = "ARC",
        [6] = "CNJ",
        [7] = "THM",
        [8] = "CRP",
        [9] = "BSM",
        [10] = "ARM",
        [11] = "GSM",
        [12] = "LTW",
        [13] = "WVR",
        [14] = "ALC",
        [15] = "CUL",
        [16] = "MIN",
        [17] = "BTN",
        [18] = "FSH",
        [19] = "PLD",
        [20] = "MNK",
        [21] = "WAR",
        [22] = "DRG",
        [23] = "BRD",
        [24] = "WHM",
        [25] = "BLM",
        [26] = "ACN",
        [27] = "SMN",
        [28] = "SCH",
        [29] = "ROG",
        [30] = "NIN",
        [31] = "MCH",
        [32] = "DRK",
        [33] = "AST",
        [34] = "SAM",
        [35] = "RDM",
        [36] = "BLU",
        [37] = "GNB",
        [38] = "DNC",
        [39] = "RPR",
        [40] = "SGE",
        [41] = "VPR",
        [42] = "PCT",
    }
    return jobNames[jobId] or "???"
end

-- Find party member info by full name
function PerpGUI.FindMemberByName(fullName)
    for _, member in ipairs(PerpGUI.partyCache) do
        if member.name == fullName then
            return member
        end
    end
    return nil
end

-- ============================================
-- DEBUG TAB FUNCTIONS
-- ============================================

-- Check if entity is a valid NPC (not player, not dead object)
function PerpGUI.IsValidNPC(entity)
    return PerpCore.IsValidNPCEntity(entity, PerpGUI.filterShowUnnamed)
end

-- Refresh NPC list cache (silent=true to suppress log output)
function PerpGUI.RefreshNPCList(silent)
    PerpGUI.npcCache = {}
    local seenIds = {}

    -- Helper to add NPC if not already seen
    local function addNPC(ent)
        if PerpGUI.IsValidNPC(ent) and not seenIds[ent.id] then
            if not PerpCore.NpcPassesVisibleRules(ent) then
                return
            end

            seenIds[ent.id] = true
            local distance = 0
            local me = TensorCore and TensorCore.mGetPlayer() or Player
            if me and me.pos and ent.pos then
                local dx = ent.pos.x - me.pos.x
                local dy = ent.pos.y - me.pos.y
                local dz = ent.pos.z - me.pos.z
                distance = math.sqrt(dx * dx + dy * dy + dz * dz)
            end
            table.insert(PerpGUI.npcCache, {
                name = (ent.name ~= nil and ent.name ~= "") and ent.name or "<unnamed>",
                id = ent.id,
                type = ent.type,
                pos = ent.pos,
                distance = distance,
                contentid = ent.contentid,
                targetable = ent.targetable,
                visible = ent.visible,
                -- Additional debug info
                hp = ent.hp,
                alive = ent.alive,
                attackable = ent.attackable,
                radius = ent.radius,
                heading = ent.pos and ent.pos.h,
                level = ent.level,
                castinginfo = ent.castinginfo,
                status = ent.status,
                fateid = ent.fateid,
                bnpcid = ent.bnpcid,
            })
        end
    end

    local filterStr = type(PerpGUI.npcFilterString) == "string" and PerpGUI.npcFilterString or "alive,maxdistance=100"
    local entities = EntityList(filterStr)
    if entities and table.valid(entities) then
        for _, ent in pairs(entities) do
            addNPC(ent)
        end
    end

    -- Sort by distance
    table.sort(PerpGUI.npcCache, function(a, b)
        return a.distance < b.distance
    end)

    PerpGUI.lastNPCRefresh = Now()
    if not silent then
        d("[PerpGUI] NPC list refreshed: " .. tostring(#PerpGUI.npcCache) .. " NPCs found")
    end
end

-- Find NPC by ID from cache
function PerpGUI.FindNPCById(id)
    for _, npc in ipairs(PerpGUI.npcCache) do
        if npc.id == id then
            return npc
        end
    end
    return nil
end

-- Resolve an action ID to its in-game name via ActionList
-- Tries common categories used for monster/player actions; returns nil on failure
function PerpGUI.GetActionName(actionId)
    if not actionId or actionId == 0 then return nil end
    if not ActionList or not ActionList.Get then return nil end

    -- Cache resolved names to avoid repeated lookups every frame
    PerpGUI._actionNameCache = PerpGUI._actionNameCache or {}
    local cached = PerpGUI._actionNameCache[actionId]
    if cached ~= nil then
        if cached == false then return nil end
        return cached
    end

    -- Try categories: 1 = Action (most common), 5 = Companion, 6 = Mount,
    -- 7 = General, 8 = BuddyAction, 9 = MainCommand, 13 = Mount-as-action
    local categories = { 1, 7, 8, 9, 5, 6, 13 }
    for _, cat in ipairs(categories) do
        local ok, action = pcall(ActionList.Get, ActionList, cat, actionId)
        if ok and action and action.name and action.name ~= "" then
            PerpGUI._actionNameCache[actionId] = action.name
            return action.name
        end
    end

    PerpGUI._actionNameCache[actionId] = false
    return nil
end

-- Get entity type name for display
function PerpGUI.GetEntityTypeName(entityType)
    local typeNames = {
        [0] = "Unknown",
        [1] = "Player",
        [2] = "Monster",
        [3] = "NPC",
        [4] = "Treasure",
        [5] = "Aetheryte",
        [6] = "Gathering",
        [7] = "EventNPC",
        [8] = "Mount",
        [9] = "Minion",
        [10] = "Retainer",
        [11] = "Area",
        [12] = "Housing",
        [13] = "Cutscene",
        [14] = "CardStand",
    }
    return typeNames[entityType] or ("Type" .. tostring(entityType))
end

-- Draw debug text on all cached NPCs
function PerpGUI.DrawNPCDebugText()
    if not PerpGUI.drawNPCDebugText then return end
    if not AnyoneCore or not AnyoneCore.addTimedWorldTextOnEnt then return end

    -- Throttle updates to avoid spam
    local now = Now and Now() or 0
    if (now - (PerpGUI.lastNPCDebugTextUpdate or 0)) < 1000 then
        return
    end
    PerpGUI.lastNPCDebugTextUpdate = now

    -- Refresh NPC list each update to catch newly spawned NPCs
    PerpGUI.RefreshNPCList(true) -- silent mode to avoid log spam

    -- Get player for distance calc
    local me = TensorCore and TensorCore.mGetPlayer() or Player

    -- When an NPC is selected, only draw that one (at double scale); otherwise draw all NPCs.
    local selId = PerpGUI.selectedNPCId
    local onlySelected = (selId ~= nil and selId ~= 0)
    local npcScale = onlySelected and 1.4 or 0.7

    -- Draw text on each cached NPC
    for _, npc in ipairs(PerpGUI.npcCache) do
        if (not onlySelected) or npc.id == selId then
            -- Calculate fresh distance
            local dist = 0
            if me and me.pos and npc.pos then
                local dx = npc.pos.x - me.pos.x
                local dz = npc.pos.z - me.pos.z
                dist = math.sqrt(dx * dx + dz * dz)
            end

            -- Get type name
            local typeName = PerpGUI.GetEntityTypeName(npc.type)

            -- Build status flags line with clear symbols
            local aliveStr = npc.alive == true and "[ALIVE]" or (npc.alive == false and "[DEAD]" or "[?]")
            local tgtStr = npc.targetable and "[TGT]" or "[ - ]"
            local atkStr = npc.attackable and "[ATK]" or "[ - ]"
            local visStr = npc.visible and "[VIS]" or "[ - ]"
            local flagsStr = string.format("%s %s %s %s", aliveStr, tgtStr, atkStr, visStr)

            -- Build HP line
            local hpStr = "N/A"
            if npc.hp then
                if npc.hp.percent then
                    hpStr = string.format("%.0f%% (%d/%d)", npc.hp.percent, npc.hp.current or 0, npc.hp.max or 0)
                elseif npc.hp.current and npc.hp.max then
                    local pct = npc.hp.max > 0 and (npc.hp.current / npc.hp.max * 100) or 0
                    hpStr = string.format("%.0f%% (%d/%d)", pct, npc.hp.current, npc.hp.max)
                end
            end

            -- Build casting/channeling block (always shown so empty/zero fields are visible)
            local castStr = ""
            local ci = npc.castinginfo
            if ci then
                local channelingId = tonumber(ci.channelingid) or 0
                local channelTargetId = tonumber(ci.channeltargetid) or 0
                local castingId = tonumber(ci.castingid) or 0
                local castTime = tonumber(ci.casttime) or 0
                local channelTime = tonumber(ci.channeltime) or 0
                local lastCastId = tonumber(ci.lastcastid) or 0
                local timeSinceCast = tonumber(ci.timesincecast) or 0
                local targetCount = ci.castingtargetcount

                local channelingName = PerpGUI.GetActionName(channelingId) or ""
                local castingName = PerpGUI.GetActionName(castingId) or ""
                local lastCastName = PerpGUI.GetActionName(lastCastId) or ""

                -- Cast progress (only meaningful while casting)
                local castProgress = ""
                if castingId > 0 and castTime > 0 then
                    local pct = math.min(100, (channelTime / castTime) * 100)
                    castProgress = string.format("  [%.0f%%]", pct)
                end

                castStr = string.format(
                    "\n-- Cast Info --\n" ..
                    "Channeling: %s [%d]\n" ..
                    "Channel Tgt: %d\n" ..
                    "Cast: %s [%d]%s\n" ..
                    "Cast Time: %.2f\n" ..
                    "Last Cast: %s [%d]\n" ..
                    "Time Since: %d\n" ..
                    "Targets: %s",
                    channelingName ~= "" and channelingName or "-",
                    channelingId,
                    channelTargetId,
                    castingName ~= "" and castingName or "-",
                    castingId,
                    castProgress,
                    castTime,
                    lastCastName ~= "" and lastCastName or "-",
                    lastCastId,
                    timeSinceCast,
                    tostring(targetCount)
                )
            end

            -- Build fancy debug text with decorations
            local debugText = string.format(
                "~~ %s ~~\n" ..
                "ID: %s | CID: %s\n" ..
                "BNPC: %s\n" ..
                "Type: %s [%d]\n" ..
                "HP: %s\n" ..
                "[%s]\n" ..
                "Dist: %.1fy | R: %.1f\n" ..
                "Hdg: %.2f\n" ..
                "Pos: %.1f, %.1f, %.1f%s",
                npc.name or "???",
                tostring(npc.id),
                tostring(npc.contentid or "N/A"),
                tostring(npc.bnpcid or "N/A"),
                typeName,
                npc.type or 0,
                hpStr,
                flagsStr,
                dist,
                npc.radius or 0,
                npc.heading or 0,
                npc.pos and npc.pos.x or 0,
                npc.pos and npc.pos.y or 0,
                npc.pos and npc.pos.z or 0,
                castStr
            )

            -- Sexy colors based on type
            local color = 0xFFE0E0E0 -- Light gray default
            if npc.type == 2 then
                color = 0xFFFF6B6B   -- Coral red for monsters
            elseif npc.type == 3 then
                color = 0xFF6BCB77   -- Mint green for NPCs
            elseif npc.type == 7 then
                color = 0xFF4ECDC4   -- Teal for Event NPCs
            elseif npc.type == 5 then
                color = 0xFF95E1D3   -- Seafoam for Aetherytes
            elseif npc.type == 6 then
                color = 0xFFFFD93D   -- Gold for Gathering nodes
            end

            -- Highlight selected NPC with bright yellow
            if npc.id == PerpGUI.selectedNPCId then
                color = 0xFFFFE66D
            end

            -- Draw text on entity (1000ms duration, with background, +2.5 height).
            -- Scale is doubled (1.4) when a single NPC is selected, otherwise 0.7.
            AnyoneCore.addTimedWorldTextOnEnt(1100, debugText, npc.id, color, true, npcScale, 2.5)
        end
    end
end

-- Draw debug text on all party members (buffs, markers, tethers)
function PerpGUI.DrawPlayerDebug()
    if not PerpGUI.drawPlayerDebug then return end
    if not AnyoneCore or not AnyoneCore.addTimedWorldTextOnEnt then return end

    -- Throttle updates
    local now = Now and Now() or 0
    if (now - (PerpGUI.lastPlayerDebugUpdate or 0)) < 1000 then
        return
    end
    PerpGUI.lastPlayerDebugUpdate = now

    -- Get all player entities (type=1)
    local partyMembers = {}
    local seenIds = {}

    local allEntities = EntityList("type=1,maxdistance=50")
    if allEntities and table.valid(allEntities) then
        for _, ent in pairs(allEntities) do
            if ent and ent.id and ent.type == 1 and not seenIds[ent.id] then
                seenIds[ent.id] = true
                table.insert(partyMembers, ent)
            end
        end
    end

    -- Also include local player if not already added
    local me = TensorCore and TensorCore.mGetPlayer() or Player
    if me and me.id and not seenIds[me.id] then
        table.insert(partyMembers, me)
    end

    -- Draw debug info for each party member
    for _, member in ipairs(partyMembers) do
        PerpGUI.DrawPlayerDebugForMember(member)
    end
end

-- Draw debug text for a single party member
function PerpGUI.DrawPlayerDebugForMember(member)
    if not member then return end

    -- Build buff list
    local buffLines = {}
    if member.buffs then
        for _, buff in pairs(member.buffs) do
            if buff and buff.id and buff.id > 0 then
                local buffName = buff.name or "Unknown"
                local stacks = buff.stacks or 0
                local duration = buff.duration or 0
                local stackStr = stacks > 0 and string.format(" x%d", stacks) or ""
                local durStr = duration > 0 and string.format(" (%.1fs)", duration) or ""
                table.insert(buffLines, string.format("  [%d] %s%s%s", buff.id, buffName, stackStr, durStr))
            end
        end
    end

    -- Get marker info
    local markerLine = "None"
    if member.marker and member.marker > 0 then
        markerLine = string.format("[%d]", member.marker)
    elseif member.headMarker and member.headMarker > 0 then
        markerLine = string.format("[%d]", member.headMarker)
    end

    -- Full label for an entity id: name, entity ID, content ID, plus the things that can tell apart
    -- entities that share a content id -- model (subcontentid) and auras/VFX (e.g. orb colour).
    local function tetherEntLabel(id)
        if not id then return "?" end
        local name, cid = nil, "?"
        local ent
        if TensorCore and TensorCore.mGetEntity then
            ent = TensorCore.mGetEntity(id)
            if ent then
                if ent.name and ent.name ~= "" then
                    name = string.match(ent.name, "^(%S+)") or ent.name
                end
                if ent.contentid then cid = tostring(ent.contentid) end
            end
        end

        local model = "?"
        if Argus and Argus.getEntityModel then
            local ok, m = pcall(Argus.getEntityModel, id)
            if ok and m ~= nil then model = tostring(m) end
        end

        local auraStr = ""
        if Argus and Argus.getEntityAuras then
            local ok, p, a1, a2 = pcall(Argus.getEntityAuras, id)
            if ok then
                auraStr = string.format(", auras %s/%s/%s",
                    tostring(p or 0), tostring(a1 or 0), tostring(a2 or 0))
            end
        end

        local bnpc = (ent and ent.bnpcid) and tostring(ent.bnpcid) or "?"

        return string.format("%s (id %s, cid %s, bnpc %s, model %s%s)",
            name or "?", tostring(id), cid, bnpc, model, auraStr)
    end

    -- Dump every key/value pair on the tether table so we don't miss any field.
    local function tetherFields(tether)
        local parts = {}
        for k, v in pairs(tether) do
            parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
        end
        table.sort(parts)
        return table.concat(parts, " ")
    end

    -- Get tether info using Argus. getCurrentTethers is keyed by the tether SOURCE entity, so we can
    -- render "source -> target" and surface where the tether originated, not just our partner.
    local tetherLines = {}
    if Argus and Argus.getCurrentTethers and member.id then
        local allTethers = Argus.getCurrentTethers()
        if allTethers then
            for sourceId, ts in pairs(allTethers) do
                if ts then
                    for i = 1, #ts do
                        local tether = ts[i]
                        local targetId = tether.targetid
                        if sourceId == member.id or targetId == member.id then
                            table.insert(tetherLines, string.format(
                                "  src %s\n  -> tgt %s\n  {%s}",
                                tetherEntLabel(sourceId),
                                tetherEntLabel(targetId),
                                tetherFields(tether)
                            ))
                        end
                    end
                end
            end
        end
    end
    local tetherLine = #tetherLines > 0 and ("\n" .. table.concat(tetherLines, "\n")) or "None"

    -- Get player name (first name only for cleaner display)
    local displayName = member.name or "Unknown"
    local firstName = string.match(displayName, "^(%S+)") or displayName

    -- Build debug text
    local buffText = #buffLines > 0 and table.concat(buffLines, "\n") or "  None"
    local posX = member.pos and member.pos.x or 0
    local posY = member.pos and member.pos.y or 0
    local posZ = member.pos and member.pos.z or 0
    local debugText = string.format(
        "~~ %s ~~\n" ..
        "Pos: %.1f, %.1f, %.1f\n" ..
        "Marker: %s\n" ..
        "Tether: %s\n" ..
        "Buffs (%d):\n%s",
        firstName,
        posX, posY, posZ,
        markerLine,
        tetherLine,
        #buffLines,
        buffText
    )

    -- Cyan color for player debug
    local color = 0xFF00FFFF

    -- Draw text on member
    AnyoneCore.addTimedWorldTextOnEnt(1100, debugText, member.id, color, true, 0.7, 3.0)
end

-- Draw debug text on all ground AOEs
function PerpGUI.DrawGroundAOEDebug()
    if not PerpGUI.drawGroundAOEDebug then return end
    if not Argus or not Argus.getCurrentGroundAOEs then return end
    if not AnyoneCore or not AnyoneCore.addTimedWorldText then return end

    -- Throttle updates
    local now = Now and Now() or 0
    if (now - (PerpGUI.lastGroundAOEDebugUpdate or 0)) < 500 then
        return
    end
    PerpGUI.lastGroundAOEDebugUpdate = now

    local groundAOEs = Argus.getCurrentGroundAOEs()
    if not groundAOEs then return end

    -- Cast type names for display
    local castTypeNames = {
        [2] = "Circle",
        [3] = "Cone",
        [4] = "Line",
        [5] = "Circle",
        [6] = "Meteor",
        [7] = "Circle",
        [8] = "TargetLine",
        [10] = "Donut",
        [11] = "Cross",
        [12] = "Line",
        [13] = "Cone",
    }

    for _, aoe in pairs(groundAOEs) do
        local castTypeName = castTypeNames[aoe.aoeCastType] or ("Type" .. tostring(aoe.aoeCastType or 0))
        local attachStr = aoe.targetAttach and ("Attach: " .. tostring(aoe.targetAttach)) or "Free"
        local areaTargetStr = aoe.isAreaTarget and "[AREA]" or ""

        local debugText = string.format(
            "~~ %s ~~\n" ..
            "ID: %d | %s\n" ..
            "Shape: %s\n" ..
            "Size: L=%.1f W=%.1f\n" ..
            "%s %s\n" ..
            "Pos: %.1f, %.1f, %.1f",
            aoe.aoeName or "Unknown AOE",
            aoe.aoeID or 0,
            castTypeName,
            castTypeName,
            aoe.aoeLength or 0,
            aoe.aoeWidth or 0,
            attachStr,
            areaTargetStr,
            aoe.x or 0,
            aoe.y or 0,
            aoe.z or 0
        )

        -- Orange/red color for AOE warnings
        local color = 0xFF5588FF -- Orange-red (ABGR)

        -- Draw at AOE position
        local pos = { x = aoe.x or 0, y = aoe.y or 0, z = aoe.z or 0 }
        AnyoneCore.addTimedWorldText(600, debugText, pos, color, true, 1.1)
    end
end

-- Draw arrows from player to enabled waymarks
function PerpGUI.DrawWaymarkLines()
    if not Argus or not Argus.addArrowFilled then return end
    if not TensorCore then return end

    local me = TensorCore.mGetPlayer() or Player
    if not me or not me.pos then return end

    -- Waymark toggle mapping
    local waymarkToggles = {
        { mark = "A", enabled = PerpGUI.drawWaymarkA },
        { mark = "B", enabled = PerpGUI.drawWaymarkB },
        { mark = "C", enabled = PerpGUI.drawWaymarkC },
        { mark = "D", enabled = PerpGUI.drawWaymarkD },
        { mark = "1", enabled = PerpGUI.drawWaymark1 },
        { mark = "2", enabled = PerpGUI.drawWaymark2 },
        { mark = "3", enabled = PerpGUI.drawWaymark3 },
        { mark = "4", enabled = PerpGUI.drawWaymark4 },
    }

    for _, wm in ipairs(waymarkToggles) do
        if wm.enabled then
            local info = PerpCore.GetWaymarkInfo(wm.mark)
            if info and info.isActive then
                local fillColor = PerpGUI.waymarkColors[wm.mark] or 0xFFFFFFFF
                local outlineColor = 0xFF000000 -- Black outline

                -- Calculate distance and heading from player to waymark
                local dx = info.x - me.pos.x
                local dz = info.z - me.pos.z
                local distance = math.sqrt(dx * dx + dz * dz)
                local heading = math.atan2(dx, dz)

                -- Arrow parameters
                local baseWidth = 0.4
                local tipLength = 1.0
                local tipWidth = 0.8

                if distance > 0.5 then
                    Argus.addArrowFilled(
                        me.pos.x, me.pos.y, me.pos.z,
                        distance,
                        baseWidth,
                        tipLength,
                        tipWidth,
                        heading,
                        fillColor,
                        outlineColor
                    )
                end
            end
        end
    end
end

-- Draw circle at arena center
function PerpGUI.DrawArenaCenterCircle()
    if not PerpGUI.drawArenaCenter then return end
    if not Argus or not Argus.addCircleFilled then return end

    local center = PerpGUI.arenaCenter or { x = 100, y = 0, z = 100 }

    -- Use player Y if center Y is 0 (prevents underground drawing)
    local drawY = center.y
    if drawY == 0 then
        local me = TensorCore and TensorCore.mGetPlayer() or Player
        if me and me.pos then
            drawY = me.pos.y
        end
    end

    local radius = 1.5
    local segments = 32 -- Circle smoothness

    -- Convert RGBA floats to U32 color using GUI converter (ABGR format)
    local col = PerpGUI.centerCircleColor or { r = 1.0, g = 0.0, b = 0.0, a = 1.0 }
    local fillColor = GUI:ColorConvertFloat4ToU32(col.r, col.g, col.b, col.a)
    local outlineColor = 0xFF000000 -- Black outline

    -- Argus.addCircleFilled(x, y, z, radius, segments, colorFill[, colorOutline])
    Argus.addCircleFilled(center.x, drawY, center.z, radius, segments, fillColor, outlineColor)
end

-- Yalms past target hitbox for attack-range ring: tanks + melee DPS = 3, all other jobs = 25 (ranged/casters/healers)
function PerpGUI.GetAttackRangeRingYalms(jobId)
    jobId = tonumber(jobId) or 0
    local melee = tonumber(PerpGUI.attackRangeMeleeYalms)
    local ranged = tonumber(PerpGUI.attackRangeRangedYalms)
    if melee == nil then melee = 3 end
    if ranged == nil then ranged = 25 end
    if IsTank(jobId) or IsMeleeDPS(jobId) then
        return math.max(0, melee)
    end
    return math.max(0, ranged)
end

-- Ring on current target at hitbox + job-based reach
function PerpGUI.DrawAttackRangeOnTarget()
    if not PerpGUI.drawAttackRangeOnTarget then return end
    if not Argus or not Argus.addDonutFilled then return end

    local me = TensorCore and TensorCore.mGetPlayer() or Player
    if not me then return end

    local tid = me.targetid
    if not tid or tid == 0 or tid == me.id then return end

    local ent = nil
    if TensorCore and TensorCore.mGetEntity then
        ent = TensorCore.mGetEntity(tid)
    end
    if not ent and EntityList then
        ent = EntityList:Get(tid)
    end
    if not ent or not ent.pos then return end

    local atk = PerpGUI.GetAttackRangeRingYalms(me.job)
    local hitR = tonumber(ent.hitradius) or 0.5
    local ringR = hitR + atk
    local halfThick = 0.06
    local innerR = math.max(0.15, ringR - halfThick)
    local outerR = math.max(innerR + 0.02, ringR + halfThick)

    local col = PerpGUI.attackRangeRingColor or { r = 0.2, g = 0.85, b = 0.38, a = 0.78 }
    local fillColor = GUI:ColorConvertFloat4ToU32(col.r, col.g, col.b, col.a)
    local outlineColor = GUI:ColorConvertFloat4ToU32(col.r * 0.45, col.g * 0.45, col.b * 0.45, math.min(1, col.a + 0.12))

    local segments = 48
    Argus.addDonutFilled(ent.pos.x, ent.pos.y, ent.pos.z, innerR, outerR, segments, fillColor, outlineColor)
end

-- Samurai: ring on current target at configured yalms past hitbox edge (default +6)
function PerpGUI.DrawSamuraiMidareRange()
    if not PerpGUI.drawSamuraiMidareRange then return end
    if not Argus or not Argus.addDonutFilled then return end

    local me = TensorCore and TensorCore.mGetPlayer() or Player
    if not me or me.job ~= PerpGUI.JOB_SAMURAI then return end

    local tid = me.targetid
    if not tid or tid == 0 then return end

    local ent = nil
    if TensorCore and TensorCore.mGetEntity then
        ent = TensorCore.mGetEntity(tid)
    end
    if not ent and EntityList then
        ent = EntityList:Get(tid)
    end
    if not ent or not ent.pos then return end

    local hitR = tonumber(ent.hitradius) or 0.5
    local extra = tonumber(PerpGUI.midareRangeExtraYalms)
    if extra == nil then extra = 6 end
    local midareRadius = hitR + math.max(0, extra)
    -- Thin band so the true edge (hitbox + 6) is obvious; ~0.12 yalm total width
    local halfThick = 0.06
    local innerR = math.max(0.15, midareRadius - halfThick)
    local outerR = math.max(innerR + 0.02, midareRadius + halfThick)

    local col = PerpGUI.midareRangeColor or { r = 0.95, g = 0.25, b = 0.15, a = 0.85 }
    local fillColor = GUI:ColorConvertFloat4ToU32(col.r, col.g, col.b, col.a)
    local outlineColor = GUI:ColorConvertFloat4ToU32(col.r * 0.5, col.g * 0.5, col.b * 0.5, math.min(1, col.a + 0.15))

    local drawY = ent.pos.y
    local segments = 48
    Argus.addDonutFilled(ent.pos.x, drawY, ent.pos.z, innerR, outerR, segments, fillColor, outlineColor)
end

-- Draw debug arrow from arena center at specified degree and length
function PerpGUI.DrawDebugArrowFromCenter()
    if not PerpGUI.drawDebugArrow then return end
    if not Argus or not Argus.addArrowFilled then return end

    local center = PerpGUI.arenaCenter or { x = 100, y = 0, z = 100 }

    -- Use player Y if center Y is 0 (prevents underground drawing)
    local drawY = center.y
    if drawY == 0 then
        local me = TensorCore and TensorCore.mGetPlayer() or Player
        if me and me.pos then
            drawY = me.pos.y
        end
    end

    -- Convert degree to radians
    -- 0 degrees = North (+Z direction in game), clockwise rotation
    local degree = PerpGUI.debugArrowDegree or 0
    local radians = math.rad(degree)
    -- Adjust heading: 0° = North (+Z), 90° = East (+X), 180° = South (-Z), 270° = West (-X)
    local heading = radians

    local arrowLength = PerpGUI.debugArrowLength or 10
    local baseWidth = 1.0
    local tipLength = 2.0
    local tipWidth = 2.5

    -- Convert RGBA floats to U32 color
    local col = PerpGUI.debugArrowColor or { r = 1.0, g = 0.5, b = 0.0, a = 1.0 }
    local fillColor = GUI:ColorConvertFloat4ToU32(col.r, col.g, col.b, col.a)
    local outlineColor = 0xFF000000 -- Black outline

    -- Draw arrow from center
    Argus.addArrowFilled(
        center.x, drawY, center.z,
        arrowLength,
        baseWidth,
        tipLength,
        tipWidth,
        heading,
        fillColor,
        outlineColor
    )
end

-- Append a new custom AOE entry at the given world position (or player / arena center when omitted).
function PerpGUI.AddCustomAOEAt(x, y, z)
    if x == nil or z == nil then
        local center = PerpGUI.arenaCenter or { x = 100, y = 0, z = 100 }
        x, y, z = center.x, center.y, center.z
        local me = TensorCore and TensorCore.mGetPlayer() or Player
        if me and me.pos then
            x, y, z = me.pos.x, me.pos.y, me.pos.z
        end
    end
    PerpGUI.customAOEs[#PerpGUI.customAOEs + 1] = {
        shape   = 1, -- Circle
        x       = x,
        y       = y or 0,
        z       = z,
        length  = 5,
        width   = 2,
        heading = 0,
        color   = { r = 1.0, g = 0.2, b = 0.2, a = 0.4 },
    }
    PerpGUI.lastClickPlacePos = { x = x, y = y or 0, z = z }
end

function PerpGUI.AddCustomAOE()
    PerpGUI.AddCustomAOEAt()
end

-- Resolve cursor position on the 3D game view to instance/world X/Y/Z.
-- GetMouseInWorldPos() returns correct duty-instance coords; GetGameCoordsFromMapPosition is open-world only.
function PerpGUI.GetMouseWorldPos()
    local function refineY(x, y, z)
        if y and y ~= 0 then return y end
        if RayCast then
            local me = TensorCore and TensorCore.mGetPlayer() or Player
            local yRef = (me and me.pos and me.pos.y) or ((PerpGUI.arenaCenter or {}).y or 0)
            local hit, _, hity = RayCast(x, yRef + 50, z, x, yRef - 50, z)
            if hit and hity then return hity end
        end
        local me = TensorCore and TensorCore.mGetPlayer() or Player
        return (me and me.pos and me.pos.y) or ((PerpGUI.arenaCenter or {}).y or 0)
    end

    if GetMouseInWorldPos then
        local wpos = GetMouseInWorldPos()
        local valid = wpos and wpos.x ~= nil and wpos.z ~= nil
        if table and table.valid then
            valid = table.valid(wpos)
        end
        if valid then
            return { x = wpos.x, y = refineY(wpos.x, wpos.y, wpos.z), z = wpos.z }
        end
    end

    -- Fallback (open-world map coords — inaccurate in instances).
    if Hacks and Hacks.GetGameCoordsFromMapPosition and GUI and GUI.GetMousePos then
        local gameCoords = Hacks:GetGameCoordsFromMapPosition(GUI:GetMousePos())
        if gameCoords and gameCoords.x ~= nil and gameCoords.z ~= nil then
            return {
                x = gameCoords.x,
                y = refineY(gameCoords.x, gameCoords.y, gameCoords.z),
                z = gameCoords.z,
            }
        end
    end

    return nil
end

-- Cyan preview ring at cursor world position when click-to-place mode is enabled.
function PerpGUI.DrawCustomAOEPlacementPreview()
    if not PerpGUI.customAOEClickPlace then return end
    local pos = PerpGUI.GetMouseWorldPos()
    if pos and Argus and Argus.addCircleFilled and GUI then
        local previewColor = GUI:ColorConvertFloat4ToU32(0.3, 0.85, 1.0, 0.35)
        Argus.addCircleFilled(pos.x, pos.y, pos.z, 0.6, 24, previewColor, 0xFF66CCFF)
    end
end

-- Right-click on the 3D view to add or move a custom AOE (call after all GUI each frame).
function PerpGUI.HandleCustomAOEClickPlace()
    if not PerpGUI.customAOEClickPlace then return end
    if not (GUI and GUI.IsMouseClicked) then return end

    local pos = PerpGUI.GetMouseWorldPos()
    if not (GUI:IsMouseClicked(1) and pos) then return end

    if PerpGUI.customAOEClickPlaceMode == 2 then
        local idx = math.max(1, math.min(PerpGUI.customAOEMoveIndex or 1, #PerpGUI.customAOEs))
        local aoe = PerpGUI.customAOEs[idx]
        if aoe then
            aoe.x, aoe.y, aoe.z = pos.x, pos.y, pos.z
            PerpGUI.lastClickPlacePos = pos
        end
    else
        PerpGUI.AddCustomAOEAt(pos.x, pos.y, pos.z)
    end
end

-- Draw every custom AOE (called each frame from PerpGUI.Draw). Throttled like the other timed debug
-- overlays: redraw ~once a second with a slightly longer lifetime so shapes persist without stacking.
function PerpGUI.DrawCustomAOEs()
    if not PerpGUI.drawCustomAOEs then return end
    if not (PerpCore and PerpCore.DrawAOEShape and GUI) then return end
    if #PerpGUI.customAOEs == 0 then return end

    local now = Now and Now() or 0
    if (now - (PerpGUI.lastCustomAOEUpdate or 0)) < 900 then return end
    PerpGUI.lastCustomAOEUpdate = now

    local DRAW_MS = 1000
    for _, aoe in ipairs(PerpGUI.customAOEs) do
        local castType = PerpGUI.customAOEShapeCastTypes[aoe.shape or 1] or 2
        local col = aoe.color or { r = 1, g = 0.2, b = 0.2, a = 0.4 }
        local color = GUI:ColorConvertFloat4ToU32(col.r, col.g, col.b, col.a)

        -- Use player Y when y is 0 so shapes don't render underground.
        local drawY = aoe.y or 0
        if drawY == 0 then
            local me = TensorCore and TensorCore.mGetPlayer() or Player
            if me and me.pos then drawY = me.pos.y end
        end

        PerpCore.DrawAOEShape(
            color,
            aoe.x or 0, drawY, aoe.z or 0,
            castType,
            aoe.length or 0,
            aoe.width or 0,
            math.rad(aoe.heading or 0),
            DRAW_MS,
            nil,
            PerpGUI.customAOEUseOldDraws
        )
    end
end

-- Draw arrows for selected NPC (called every frame in Draw)
function PerpGUI.DrawArrowToSelectedNPC()
    -- Need an NPC selected for any drawing
    if not PerpGUI.selectedNPCId then
        return
    end

    -- Need at least one feature enabled
    if not PerpGUI.drawArrowToNPC and not PerpGUI.drawCardinalArrows and not PerpGUI.drawNPCToNearestWaymark then
        return
    end

    local me = TensorCore and TensorCore.mGetPlayer() or Player
    if not me or not me.pos then return end

    -- Get fresh entity position (not from cache, to handle movement)
    local targetEntity = nil
    if TensorCore and TensorCore.mGetEntity then
        targetEntity = TensorCore.mGetEntity(PerpGUI.selectedNPCId)
    end
    if not targetEntity then
        targetEntity = EntityList:Get(PerpGUI.selectedNPCId)
    end

    if not targetEntity or not targetEntity.pos then
        return
    end

    -- Calculate direction from player to NPC
    local dx = targetEntity.pos.x - me.pos.x
    local dz = targetEntity.pos.z - me.pos.z
    local heading = math.atan2(dx, dz)
    local distance = math.sqrt(dx * dx + dz * dz)

    -- Draw arrow from player to NPC if enabled
    if PerpGUI.drawArrowToNPC then
        local fillColor = PerpGUI.arrowColor or 0xFF00FF00
        local outlineColor = PerpGUI.arrowOutlineColor or 0xFF00AA00
        local arrowLength = distance
        local baseWidth = 0.6
        local tipLength = 1.5
        local tipWidth = 1.2

        if Argus and Argus.addArrowFilled and arrowLength > 0.5 then
            Argus.addArrowFilled(
                me.pos.x, me.pos.y, me.pos.z,
                arrowLength,
                baseWidth,
                tipLength,
                tipWidth,
                heading,
                fillColor,
                outlineColor
            )
        end
    end

    -- Draw cardinal/intercardinal arrows from NPC if enabled
    if PerpGUI.drawCardinalArrows then
        PerpGUI.DrawCardinalArrowsFromNPC(targetEntity)
    end

    -- Draw arrow from NPC to nearest waymark if enabled
    if PerpGUI.drawNPCToNearestWaymark then
        local closest = PerpCore.GetWaymarkClosestToEntity(targetEntity)
        if closest then
            local fillColor = PerpGUI.waymarkColors[closest.waymark] or 0xFFFFFFFF
            local outlineColor = 0xFF000000

            -- Calculate heading from NPC to waymark
            local wmDx = closest.x - targetEntity.pos.x
            local wmDz = closest.z - targetEntity.pos.z
            local wmHeading = math.atan2(wmDx, wmDz)

            -- Arrow parameters
            local baseWidth = 0.5
            local tipLength = 1.2
            local tipWidth = 1.0

            if closest.distance > 0.5 then
                Argus.addArrowFilled(
                    targetEntity.pos.x, targetEntity.pos.y, targetEntity.pos.z,
                    closest.distance,
                    baseWidth,
                    tipLength,
                    tipWidth,
                    wmHeading,
                    fillColor,
                    outlineColor
                )
            end
        end
    end
end

-- Draw 8 cardinal/intercardinal arrows from the NPC
-- "North" is defined as the direction FROM the arena center TO the NPC
function PerpGUI.DrawCardinalArrowsFromNPC(npc)
    if not Argus or not Argus.addArrowFilled then return end
    if not npc or not npc.pos then return end
    if not TensorCore then return end

    -- Copy NPC position to avoid any reference issues
    local npcPos = { x = npc.pos.x, y = npc.pos.y, z = npc.pos.z }

    local arrowLength = PerpGUI.cardinalArrowLength or 5.0
    local baseWidth = 0.4
    local tipLength = 1.0
    local tipWidth = 0.8
    local outlineColor = 0xFF000000      -- Black outline
    local textOffset = arrowLength + 1.0 -- Position text slightly past arrow tip

    -- Get heading from arena center to NPC (this is "North" - pointing away from center)
    local center = PerpGUI.arenaCenter or { x = 100, y = 0, z = 100 }
    local centerToNpcHeading = TensorCore.getHeadingToTarget(center, npcPos)

    -- Cardinal directions as offsets from "North" (NPC-to-center direction)
    -- North = 0, East = -π/2 (clockwise), South = π, West = π/2 (counter-clockwise)
    local directions = {
        { name = "N",  offset = 0 },
        { name = "NE", offset = -math.pi / 4 },
        { name = "E",  offset = -math.pi / 2 },
        { name = "SE", offset = -3 * math.pi / 4 },
        { name = "S",  offset = math.pi },
        { name = "SW", offset = 3 * math.pi / 4 },
        { name = "W",  offset = math.pi / 2 },
        { name = "NW", offset = math.pi / 4 },
    }

    -- Pre-calculate all positions first using TensorCore
    local textData = {}
    for _, dir in ipairs(directions) do
        local arrowHeading = centerToNpcHeading + dir.offset
        local color = PerpGUI.cardinalColors[dir.name] or 0xFFFFFFFF

        -- Use TensorCore to get position in direction from NPC
        local textPos = TensorCore.getPosInDirection(npcPos, arrowHeading, textOffset)

        table.insert(textData, {
            name = dir.name,
            heading = arrowHeading,
            color = color,
            posX = textPos.x,
            posY = textPos.y,
            posZ = textPos.z,
        })
    end

    -- Draw all arrows from NPC position
    for _, data in ipairs(textData) do
        Argus.addArrowFilled(
            npcPos.x, npcPos.y, npcPos.z,
            arrowLength,
            baseWidth,
            tipLength,
            tipWidth,
            data.heading,
            data.color,
            outlineColor
        )
    end

    -- Then draw all text labels (throttled)
    local now = Now and Now() or 0
    local shouldUpdateText = (now - (PerpGUI.lastCardinalTextUpdate or 0)) > 1000

    if shouldUpdateText and AnyoneCore and AnyoneCore.addTimedWorldText then
        for _, data in ipairs(textData) do
            local textPos = { x = data.posX, y = data.posY, z = data.posZ }
            AnyoneCore.addTimedWorldText(1100, data.name, textPos, data.color, true, 1.2)
        end
        PerpGUI.lastCardinalTextUpdate = now
    end
end

local function mapEffectShortPath(path)
    if type(path) ~= "string" then return "Unknown" end
    return path:match(".*/(.*)") or path
end

local function mapEffectTypeLabel(rType)
    return PerpGUI.mapEffectTypeNames[tonumber(rType)] or tostring(rType)
end

-- Scan active Argus map effects into PerpGUI.mapEffectsCache for the explorer UI.
function PerpGUI.RefreshMapEffects()
    local cache = {}
    if not (Argus and Argus.getNumCurrentMapEffects and Argus.getMapEffectResource) then
        PerpGUI.mapEffectsCache = cache
        return
    end

    local numEffects = Argus.getNumCurrentMapEffects()
    for i = 0, numEffects - 1 do
        local res = Argus.getMapEffectResource(i)
        if res then
            local resId, resPath, resType, isActive = Argus.getEffectResourceInfo(res)
            local typeStr = mapEffectTypeLabel(resType)

            local validScriptCount = 0
            if tonumber(resType) == 6 and Argus.getNumEffectResourceScripts then
                local rawNum = Argus.getNumEffectResourceScripts(res) or 0
                for si = 0, rawNum - 1 do
                    local sName = Argus.getEffectResourceScriptInfo(res, si)
                    if sName and sName ~= "" then
                        validScriptCount = validScriptCount + 1
                    end
                end
            end

            local fullSearchString = string.format("index=%d id=%d type=%s active=%s scripts=%d path=%s",
                i, resId or 0, typeStr, tostring(isActive), validScriptCount, tostring(resPath))
            local activeTag = isActive and " (ON)" or ""
            local displayLabel = string.format("[%d] %s%s", i, mapEffectShortPath(resPath), activeTag)

            cache[#cache + 1] = {
                index = i,
                label = displayLabel,
                searchString = string.lower(fullSearchString),
                isActive = isActive,
            }
        end
    end
    PerpGUI.mapEffectsCache = cache
end

local function mapEffectRunningScripts(res)
    if not (res and Argus.getNumEffectResourceScripts and Argus.getEffectResourceScriptInfo) then
        return {}
    end
    local lines = {}
    local rawNum = Argus.getNumEffectResourceScripts(res) or 0
    for si = 0, rawNum - 1 do
        local sName, _, _, sRunning = Argus.getEffectResourceScriptInfo(res, si)
        if sName and sName ~= "" then
            local flag = math.floor(2 ^ si)
            local mark = sRunning and "RUN" or "off"
            lines[#lines + 1] = string.format("[%d] flag=%d %s (%s)", si, flag, sName, mark)
        end
    end
    return lines
end

-- Draw world-text labels at each cached map effect's position (throttled).
function PerpGUI.DrawMapEffectsWorldText()
    if not PerpGUI.drawMapEffectWorldText then return end
    if not (Argus and Argus.getNumCurrentMapEffects and Argus.getMapEffectResource and Argus.getEffectResourcePosition) then return end
    if not (AnyoneCore and AnyoneCore.addTimedWorldText) then return end

    local numEffects = Argus.getNumCurrentMapEffects() or 0
    if numEffects == 0 then return end

    local now = Now and Now() or 0
    if (now - (PerpGUI.lastMapEffectWorldTextUpdate or 0)) < 600 then return end
    PerpGUI.lastMapEffectWorldTextUpdate = now

    local TEXT_MS = 700
    local selectedIdx = PerpGUI.mapEffectSelectedIndex

    for i = 0, numEffects - 1 do
        local res = Argus.getMapEffectResource(i)
        if res then
            local x, y, z = Argus.getEffectResourcePosition(res)
            if x and z then
                local id, path, rType, isActive = Argus.getEffectResourceInfo(res)
                local typeStr = mapEffectTypeLabel(rType)
                local isSelected = (i == selectedIdx)
                local statusStr = isActive and "ON" or "OFF"

                local lines = {
                    string.format("[%d] %s  id=%s", i, typeStr, tostring(id or 0)),
                    string.format("%s  %s", mapEffectShortPath(path), statusStr),
                    string.format("%.1f, %.1f, %.1f", x, y or 0, z),
                }

                if isSelected and tonumber(rType) == 6 then
                    for _, sl in ipairs(mapEffectRunningScripts(res)) do
                        lines[#lines + 1] = sl
                    end
                end

                local color
                if isSelected then
                    color = isActive and 0xFF00FFFF or 0xFF8888FF -- cyan / muted cyan
                elseif isActive then
                    color = 0xFF66FFCC                            -- gold (matches OnMapEffect debug)
                else
                    color = 0xFF888888                            -- grey
                end

                local scale = isSelected and 1.15 or 0.85
                AnyoneCore.addTimedWorldText(
                    TEXT_MS,
                    table.concat(lines, "\n"),
                    { x = x, y = (y or 0) + 1.5, z = z },
                    color,
                    true,
                    scale
                )
            end
        end
    end
end

-- Collapsible entry point in the Debug tab.
function PerpGUI.DrawMapEffectsSection()
    if not GUI:TreeNode("Map Effects##mapEffects") then return end

    GUI:Spacing()
    GUI:Dummy(5, 0)
    GUI:SameLine()

    local openLabel = PerpGUI.showMapEffectsExplorer and "Close Explorer" or "Open Explorer"
    if GUI:Button(openLabel .. "##mapFxOpen", 110, 22) then
        PerpGUI.showMapEffectsExplorer = not PerpGUI.showMapEffectsExplorer
        if PerpGUI.showMapEffectsExplorer then
            PerpGUI.RefreshMapEffects()
        end
    end
    if GUI:IsItemHovered() then
        GUI:SetTooltip("Open the Map Effects Explorer window\n(inspect Argus map effects and copy reaction conditions)")
    end

    GUI:SameLine(0, 8)
    if GUI:Button("Refresh##mapFxRefresh", 65, 22) then
        PerpGUI.RefreshMapEffects()
    end
    if GUI:IsItemHovered() then GUI:SetTooltip("Rescan current map effects") end

    GUI:SameLine(0, 12)
    GUI:TextColored(0.6, 0.6, 0.6, 1, "Cached: " .. tostring(#PerpGUI.mapEffectsCache))

    GUI:Dummy(5, 0)
    GUI:SameLine()
    PerpGUI.drawMapEffectWorldText = GUI:Checkbox("World Text##mapFxWorldText", PerpGUI.drawMapEffectWorldText)
    if GUI:IsItemHovered() then
        GUI:SetTooltip("Draw labels in-world at each map effect position\n(selected effect shows script flags)")
    end

    GUI:Spacing()
    GUI:TreePop()
end

-- Dual-pane Map Effects Explorer (separate window; stays open independently of PerpCore window).
function PerpGUI.DrawMapEffectsExplorerWindow()
    if not PerpGUI.showMapEffectsExplorer then return end

    GUI:SetNextWindowSize(900, 520, GUI.SetCond_FirstUseEver)
    local visible, open = GUI:Begin("Map Effects Explorer###PerpMapEffects", PerpGUI.showMapEffectsExplorer)
    if not open then
        PerpGUI.showMapEffectsExplorer = false
    end

    if visible then
        if GUI:Button("Refresh List##mapFxListRefresh", 100, 24) then
            PerpGUI.RefreshMapEffects()
        end
        GUI:SameLine()
        GUI:TextColored(0.6, 0.6, 0.6, 1, "Filter:")
        GUI:SameLine()
        GUI:PushItemWidth(220)
        local newFilter = GUI:InputText("##mapFxFilter", PerpGUI.mapEffectSearchFilter)
        if newFilter ~= nil then
            PerpGUI.mapEffectSearchFilter = newFilter
        end
        GUI:PopItemWidth()
        GUI:Spacing()

        local filterLower = string.lower(PerpGUI.mapEffectSearchFilter or "")
        local filteredItems = {}
        for _, item in ipairs(PerpGUI.mapEffectsCache) do
            if filterLower == "" or string.find(item.searchString, filterLower, 1, true) then
                filteredItems[#filteredItems + 1] = item
            end
        end

        GUI:Columns(2, "PerpMapEffectsColumns", true)
        GUI:SetColumnWidth(0, 280)

        GUI:BeginChild("PerpMapFxLeft", 0, 0, true)
        for _, item in ipairs(filteredItems) do
            local isSelected = (PerpGUI.mapEffectSelectedIndex == item.index)
            if isSelected then
                GUI:PushStyleColor(GUI.Col_Text, 1.0, 0.85, 0.3, 1.0)
            elseif item.isActive then
                GUI:PushStyleColor(GUI.Col_Text, 0.9, 0.9, 0.9, 1.0)
            else
                GUI:PushStyleColor(GUI.Col_Text, 0.5, 0.5, 0.5, 1.0)
            end
            if GUI:Selectable(item.label, isSelected) then
                PerpGUI.mapEffectSelectedIndex = item.index
            end
            GUI:PopStyleColor()
        end
        GUI:EndChild()

        GUI:NextColumn()

        GUI:BeginChild("PerpMapFxRight", 0, 0, true)
        if PerpGUI.mapEffectSelectedIndex ~= -1 and Argus and Argus.getMapEffectResource then
            local targetRes = Argus.getMapEffectResource(PerpGUI.mapEffectSelectedIndex)
            if targetRes then
                local id, path, rType, isActive = Argus.getEffectResourceInfo(targetRes)
                local rTypeStr = mapEffectTypeLabel(rType)
                local selIdx = PerpGUI.mapEffectSelectedIndex

                GUI:TextColored(0.95, 0.75, 0.20, 1.0, string.format("Index: %d", selIdx))
                GUI:SameLine(90)
                GUI:TextColored(0.40, 0.75, 1.00, 1.0, string.format("ID: %d", id or 0))
                GUI:SameLine(180)
                GUI:TextColored(0.95, 0.75, 0.20, 1.0, string.format("Type: %s (%d)", rTypeStr, rType or 0))
                GUI:SameLine(320)
                if isActive then
                    GUI:TextColored(0.30, 0.90, 0.40, 1.0, "ACTIVE")
                else
                    GUI:TextColored(0.60, 0.60, 0.60, 1.0, "INACTIVE")
                end

                GUI:Spacing()
                GUI:TextColored(0.7, 0.7, 0.7, 1.0, "Path:")
                GUI:SameLine()
                GUI:TextColored(1, 1, 1, 1, tostring(path))
                GUI:SameLine()
                if GUI:Button("Copy##mapFxPath", 45, 18) and GUI.SetClipboardText then
                    GUI:SetClipboardText(tostring(path))
                end

                GUI:Separator()
                GUI:Spacing()
                GUI:Text("Actions:")
                GUI:SameLine()
                if GUI:Button("Teleport to Me##mapFxTp", 110, 20) then
                    local p = TensorCore and TensorCore.mGetPlayer and TensorCore.mGetPlayer()
                    if p and p.pos and Argus.setEffectResourcePosition then
                        Argus.setEffectResourcePosition(targetRes, p.pos.x, p.pos.y, p.pos.z)
                    end
                end
                GUI:SameLine()
                if GUI:Button("Turn Off (4)##mapFxOff", 100, 20) and Argus.runMapEffect then
                    Argus.runMapEffect(selIdx, 0, 4)
                end

                GUI:Spacing()
                local px, py, pz = Argus.getEffectResourcePosition(targetRes)
                if px then
                    GUI:TextColored(0.4, 0.8, 1.0, 1.0,
                        string.format("Position: X: %.3f  Y: %.3f  Z: %.3f", px, py, pz))
                end
                local sx, sy, sz = Argus.getEffectResourceScale(targetRes)
                if sx then
                    GUI:TextColored(0.4, 1.0, 0.4, 1.0,
                        string.format("Scale: X: %.3f  Y: %.3f  Z: %.3f", sx, sy, sz))
                end
                local dx, dy, dz, ux, uy, uz = Argus.getEffectResourceOrientation(targetRes)
                if dx then
                    GUI:TextColored(1.0, 0.6, 0.6, 1.0, string.format(
                        "Dir: %.3f, %.3f, %.3f  |  Up: %.3f, %.3f, %.3f", dx, dy, dz, ux, uy, uz))
                end
                local rt, rs = Argus.getEffectResourceRenderInfo(targetRes)
                if rt then
                    GUI:TextColored(0.8, 0.8, 0.8, 1.0, string.format(
                        "Render: %s  |  State: %s", mapEffectTypeLabel(rt), tostring(rs)))
                end

                if tonumber(rType) == 6 and Argus.getNumEffectResourceScripts then
                    GUI:Spacing()
                    GUI:Separator()
                    GUI:Spacing()

                    local rawNumScripts = Argus.getNumEffectResourceScripts(targetRes) or 0
                    local validScripts = {}
                    for si = 0, rawNumScripts - 1 do
                        local sName, numSub, sRes, sRunning = Argus.getEffectResourceScriptInfo(targetRes, si)
                        if sName and sName ~= "" then
                            validScripts[#validScripts + 1] = {
                                index = si, name = sName, numSub = numSub, res = sRes, running = sRunning,
                            }
                        end
                    end

                    if #validScripts > 0 then
                        GUI:TextColored(0.95, 0.75, 0.20, 1.0,
                            "Scripts (" .. tostring(#validScripts) .. ")")
                        GUI:Spacing()

                        for _, sInfo in ipairs(validScripts) do
                            local scriptFlag = math.floor(2 ^ sInfo.index)
                            local sfx = "_mfx_" .. selIdx .. "_" .. sInfo.index
                            if sInfo.running then
                                GUI:TextColored(0.3, 0.9, 0.4, 1.0, string.format("[%d] %s  flag=%d",
                                    sInfo.index, tostring(sInfo.name), scriptFlag))
                            else
                                GUI:TextColored(0.9, 0.3, 0.3, 1.0, string.format("[%d] %s  flag=%d",
                                    sInfo.index, tostring(sInfo.name), scriptFlag))
                            end

                            GUI:SameLine(340)
                            if GUI:Button("Run##" .. sfx, 40, 18) and Argus.startEffectResourceScript then
                                Argus.startEffectResourceScript(targetRes, sInfo.index, 0)
                            end
                            GUI:SameLine()
                            if GUI:Button("Stop##" .. sfx, 40, 18) and Argus.runMapEffect then
                                Argus.runMapEffect(selIdx, 0, 4)
                            end
                            GUI:SameLine()
                            if GUI:Button("Copy Cond##" .. sfx, 75, 18) and GUI.SetClipboardText then
                                local cond = string.format(
                                    "return eventArgs.a1 == %d and eventArgs.a2 == 0 and eventArgs.a3 == %d",
                                    selIdx, scriptFlag)
                                GUI:SetClipboardText(cond)
                            end
                            if GUI:IsItemHovered() then
                                GUI:SetTooltip("Copy OnMapEffect condition to clipboard")
                            end

                            if sInfo.res and sInfo.numSub and sInfo.numSub > 0
                                and Argus.getEffectResourceScriptSubresource then
                                for subI = 0, sInfo.numSub - 1 do
                                    local ssRes = Argus.getEffectResourceScriptSubresource(sInfo.res, subI)
                                    if ssRes then
                                        local ssId, ssPath, ssType = Argus.getEffectResourceInfo(ssRes)
                                        GUI:TextColored(0.5, 0.5, 0.5, 1.0, "    ↳ ")
                                        GUI:SameLine()
                                        GUI:TextColored(0.7, 0.7, 0.7, 1.0, string.format("[%s] ID:%d %s",
                                            mapEffectTypeLabel(ssType), ssId or 0, mapEffectShortPath(ssPath)))
                                        if GUI:IsItemHovered() then GUI:SetTooltip(tostring(ssPath)) end
                                    end
                                end
                            end
                            GUI:Spacing()
                        end
                    end

                    if Argus.getNumEffectSubresources then
                        local numFullSub = Argus.getNumEffectSubresources(targetRes) or 0
                        if numFullSub > 0 then
                            GUI:Spacing()
                            GUI:TextColored(0.40, 0.75, 1.00, 1.0,
                                "Resource Pool (" .. tostring(numFullSub) .. ")")
                            GUI:Spacing()
                            for fi = 0, numFullSub - 1 do
                                local fRes = Argus.getEffectSubresource(targetRes, fi)
                                if fRes then
                                    local fId, fPath, fType, fActive = Argus.getEffectResourceInfo(fRes)
                                    local aColor = fActive and { 0.9, 0.9, 0.9 } or { 0.5, 0.5, 0.5 }
                                    GUI:TextColored(aColor[1], aColor[2], aColor[3], 1.0, string.format(
                                        "[%d] %s | ID:%d", fi, mapEffectTypeLabel(fType), fId or 0))
                                    GUI:SameLine(160)
                                    GUI:TextColored(0.6, 0.6, 0.6, 1.0, tostring(fPath))
                                end
                            end
                        end
                    end
                end
            else
                GUI:TextColored(1.0, 0.4, 0.4, 1.0, "Resource is nil or despawned.")
            end
        else
            GUI:TextColored(0.5, 0.5, 0.5, 1.0, "Select a map effect from the list.")
        end
        GUI:EndChild()

        GUI:Columns(1)
    end

    GUI:End()
end

-- Custom AOE builder UI (collapsible). Lets you add/edit/remove a list of debug shapes with
-- per-entry shape, position, size, heading and colour. Drawn each frame by PerpGUI.DrawCustomAOEs.
function PerpGUI.DrawCustomAOESection()
    if not GUI:TreeNode("Custom AOEs##customAOE") then return end

    local SLIDER_W = 140

    local function sliderFloat(label, id, val, vmin, vmax)
        GUI:Dummy(5, 0)
        GUI:SameLine()
        GUI:Text(label)
        GUI:SameLine()
        GUI:PushItemWidth(SLIDER_W)
        local nv = GUI:SliderFloat(id, val or 0, vmin, vmax)
        GUI:PopItemWidth()
        return nv
    end

    GUI:Spacing()
    GUI:Dummy(5, 0)
    GUI:SameLine()
    PerpGUI.drawCustomAOEs = GUI:Checkbox("Enable##customAOEEnable", PerpGUI.drawCustomAOEs)
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw all custom AOE shapes below") end

    GUI:SameLine(0, 12)
    PerpGUI.customAOEUseOldDraws = GUI:Checkbox("Old draws##customAOEOldDraws", PerpGUI.customAOEUseOldDraws)
    if GUI:IsItemHovered() then
        GUI:SetTooltip("Use Argus old draw mode (overlays on top of terrain/models)")
    end

    GUI:SameLine(0, 15)
    GUI:Button("Add##customAOEAdd", 55, 22)
    if GUI:IsItemClicked(0) then PerpGUI.AddCustomAOE() end
    if GUI:IsItemHovered() then GUI:SetTooltip("Add a new AOE at your current position") end

    GUI:SameLine(0, 8)
    GUI:Button("Clear All##customAOEClear", 75, 22)
    if GUI:IsItemClicked(0) then PerpGUI.customAOEs = {} end

    GUI:SameLine(0, 12)
    GUI:TextColored(0.6, 0.6, 0.6, 1, "Count: " .. tostring(#PerpGUI.customAOEs))

    GUI:Dummy(5, 0)
    GUI:SameLine()
    PerpGUI.customAOEClickPlace = GUI:Checkbox("Click to place##customAOEClick", PerpGUI.customAOEClickPlace)
    if GUI:IsItemHovered() then
        GUI:SetTooltip(
            "Right-click the 3D game view to place AOEs on the arena floor.\n" ..
            "Uses GetMouseInWorldPos (instance-correct).\n" ..
            "A cyan preview ring follows your cursor over the arena."
        )
    end

    if PerpGUI.customAOEClickPlace then
        local hoverPos = PerpGUI.GetMouseWorldPos()
        if hoverPos then
            GUI:SameLine(0, 8)
            GUI:TextColored(0.5, 0.75, 0.95, 1, string.format(
                "Hover: %.1f, %.1f, %.1f", hoverPos.x, hoverPos.y, hoverPos.z
            ))
        end
    end

    if PerpGUI.customAOEClickPlace then
        GUI:Dummy(5, 0)
        GUI:SameLine()
        GUI:Text("Mode")
        GUI:SameLine()
        GUI:PushItemWidth(110)
        local newMode, modeChanged = GUI:Combo("##customAOEClickMode", PerpGUI.customAOEClickPlaceMode or 1,
            PerpGUI.customAOEClickPlaceModes)
        GUI:PopItemWidth()
        if modeChanged and newMode then PerpGUI.customAOEClickPlaceMode = newMode end

        if PerpGUI.customAOEClickPlaceMode == 2 then
            GUI:SameLine(0, 8)
            GUI:Text("#")
            GUI:SameLine()
            GUI:PushItemWidth(50)
            local newIdx = GUI:SliderInt("##customAOEMoveIdx", PerpGUI.customAOEMoveIndex or 1, 1,
                math.max(1, #PerpGUI.customAOEs))
            GUI:PopItemWidth()
            if newIdx then PerpGUI.customAOEMoveIndex = newIdx end
        end

        if PerpGUI.lastClickPlacePos then
            GUI:Dummy(5, 0)
            GUI:SameLine()
            GUI:TextColored(0.5, 0.85, 0.5, 1, string.format(
                "Last: %.1f, %.1f, %.1f",
                PerpGUI.lastClickPlacePos.x, PerpGUI.lastClickPlacePos.y, PerpGUI.lastClickPlacePos.z
            ))
        end
    end

    GUI:Spacing()

    local me = TensorCore and TensorCore.mGetPlayer() or Player
    local ref = (me and me.pos) or PerpGUI.arenaCenter or { x = 100, y = 0, z = 100 }
    local xMin, xMax = ref.x - 80, ref.x + 80
    local yMin, yMax = ref.y - 15, ref.y + 15
    local zMin, zMax = ref.z - 80, ref.z + 80

    local removeIdx = nil
    for i, aoe in ipairs(PerpGUI.customAOEs) do
        local sfx = "_caoe_" .. i
        GUI:Separator()

        -- Shape selector + delete button.
        GUI:Dummy(5, 0)
        GUI:SameLine()
        GUI:TextColored(0.7, 0.85, 1.0, 1, "#" .. i)
        GUI:SameLine(0, 8)
        GUI:Text("Shape")
        GUI:SameLine(0, 6)
        GUI:PushItemWidth(90)
        local newShape, shapeChanged = GUI:Combo("##shape" .. sfx, aoe.shape or 1, PerpGUI.customAOEShapeOptions)
        GUI:PopItemWidth()
        if shapeChanged and newShape then aoe.shape = newShape end

        GUI:SameLine(0, 10)
        GUI:PushStyleColor(GUI.Col_Text, 1, 0.5, 0.5, 1)
        GUI:Button("X##del" .. sfx, 22, 20)
        GUI:PopStyleColor()
        if GUI:IsItemClicked(0) then removeIdx = i end
        if GUI:IsItemHovered() then GUI:SetTooltip("Remove this AOE") end

        -- Position X / Y / Z + a "Me" button to snap to the player.
        local nx = sliderFloat("X", "##x" .. sfx, aoe.x, xMin, xMax)
        if nx then aoe.x = nx end

        local ny = sliderFloat("Y", "##y" .. sfx, aoe.y, yMin, yMax)
        if ny then aoe.y = ny end

        GUI:Dummy(5, 0)
        GUI:SameLine()
        GUI:Text("Z")
        GUI:SameLine()
        GUI:PushItemWidth(SLIDER_W)
        local nz = GUI:SliderFloat("##z" .. sfx, aoe.z or 0, zMin, zMax)
        GUI:PopItemWidth()
        if nz then aoe.z = nz end

        GUI:SameLine(0, 8)
        GUI:Button("Me##pos" .. sfx, 30, 20)
        if GUI:IsItemClicked(0) then
            local me = TensorCore and TensorCore.mGetPlayer() or Player
            if me and me.pos then
                aoe.x, aoe.y, aoe.z = me.pos.x, me.pos.y, me.pos.z
            end
        end
        if GUI:IsItemHovered() then GUI:SetTooltip("Snap position to your current location") end

        -- Size row: length/radius, optional width/inner, optional heading -- shown per shape.
        local shape = aoe.shape or 1
        local lenLabel = (shape == 1 or shape == 4) and "Radius" or "Length"
        local nl = sliderFloat(lenLabel, "##len" .. sfx, aoe.length, 0, 80)
        if nl then aoe.length = math.max(0, nl) end

        -- Width is the inner radius for donuts, the cross/rect width otherwise.
        if shape == 2 or shape == 3 or shape == 5 then
            local wLabel = (shape == 2) and "Inner" or "Width"
            local nw = sliderFloat(wLabel, "##wid" .. sfx, aoe.width, 0, 80)
            if nw then aoe.width = math.max(0, nw) end
        end

        -- Heading only matters for directional shapes (rect, cone, cross).
        if shape == 3 or shape == 4 or shape == 5 then
            GUI:Dummy(5, 0)
            GUI:SameLine()
            GUI:Text("Deg")
            GUI:SameLine()
            GUI:PushItemWidth(SLIDER_W)
            local nh = GUI:SliderInt("##hd" .. sfx, aoe.heading or 0, 0, 360)
            GUI:PopItemWidth()
            if nh then aoe.heading = nh end
        end

        -- Colour picker.
        GUI:Dummy(5, 0)
        GUI:SameLine()
        GUI:Text("Color")
        GUI:SameLine()
        GUI:ColorEditMode(GUI.ColorEditMode_NoInputs + GUI.ColorEditMode_AlphaBar)
        local c = aoe.color or { r = 1, g = 0.2, b = 0.2, a = 0.4 }
        local cr, cg, cb, ca, cchanged = GUI:ColorEdit4("##col" .. sfx, c.r, c.g, c.b, c.a)
        if cchanged then aoe.color = { r = cr, g = cg, b = cb, a = ca } end
    end

    if removeIdx then table.remove(PerpGUI.customAOEs, removeIdx) end

    GUI:Spacing()
    GUI:TreePop()
end

-- ============================================
-- NPC Inspector (live entity dump when an NPC is selected)
-- ============================================

function PerpGUI.GetFreshNPCEntity(id)
    if not id then return nil end
    local ent
    if TensorCore and TensorCore.mGetEntity then
        ent = TensorCore.mGetEntity(id)
    end
    if not ent and EntityList and EntityList.Get then
        ent = EntityList:Get(id)
    end
    return ent
end

function PerpGUI.FormatInspectorValue(value)
    if value == nil then return "nil" end
    local t = type(value)
    if t == "boolean" then return value and "true" or "false" end
    if t == "number" then
        if value ~= value then return "nan" end
        if math.abs(value) >= 1000000 or (value ~= 0 and math.abs(value) < 0.0001) then
            return string.format("%.6g", value)
        end
        return tostring(value)
    end
    if t == "string" then return value ~= "" and value or '""' end
    if t == "table" then
        if value.x ~= nil and value.z ~= nil then
            local y = value.y or 0
            local h = value.h
            if h ~= nil then
                return string.format("(%.3f, %.3f, %.3f, h=%.3f)", value.x, y, value.z, h)
            end
            return string.format("(%.3f, %.3f, %.3f)", value.x, y, value.z)
        end
        local n = table.size and table.size(value) or #value
        return string.format("<table, %d entries>", n)
    end
    return tostring(value)
end

function PerpGUI.DrawInspectorField(label, value, indent)
    indent = indent or 0
    GUI:Dummy(indent, 0)
    GUI:SameLine()
    GUI:TextColored(0.65, 0.65, 0.65, 1, label .. ":")
    GUI:SameLine(160 + indent)
    GUI:TextWrapped(PerpGUI.FormatInspectorValue(value))
end

function PerpGUI.DrawInspectorBar(label, bar)
    if not bar then
        PerpGUI.DrawInspectorField(label, nil)
        return
    end
    local cur   = tonumber(bar.current) or 0
    local max   = tonumber(bar.max) or 0
    local pct   = tonumber(bar.percent)
    local extra = bar.extra
    local text  = string.format("%s / %s", PerpGUI.FormatInspectorValue(cur), PerpGUI.FormatInspectorValue(max))
    if pct ~= nil then
        text = text .. string.format(" (%.1f%%)", pct)
    end
    if extra ~= nil then
        text = text .. " extra=" .. PerpGUI.FormatInspectorValue(extra)
    end
    PerpGUI.DrawInspectorField(label, text)
end

function PerpGUI.DrawInspectorSection(title, drawFn)
    if GUI:TreeNode(title) then
        drawFn()
        GUI:TreePop()
    end
end

function PerpGUI.DrawInspectorCastingInfo(cinfo)
    if not cinfo or (table.size and table.size(cinfo) == 0) then
        GUI:TextColored(0.5, 0.5, 0.5, 1, "  (none)")
        return
    end

    local fields = {
        { "ptr",                  cinfo.ptr and string.format("%X", cinfo.ptr) or cinfo.ptr },
        { "castingid",            cinfo.castingid },
        { "castingid (name)",     PerpGUI.GetActionName(cinfo.castingid) },
        { "casttime",             cinfo.casttime },
        { "castingtargetcount",   cinfo.castingtargetcount },
        { "castinginterruptible", cinfo.castinginterruptible },
        { "lastcastid",           cinfo.lastcastid },
        { "lastcastid (name)",    PerpGUI.GetActionName(cinfo.lastcastid) },
        { "timesincecast",        cinfo.timesincecast },
        { "channelingid",         cinfo.channelingid },
        { "channelingid (name)",  PerpGUI.GetActionName(cinfo.channelingid) },
        { "channeltargetid",      cinfo.channeltargetid },
        { "channeltime",          cinfo.channeltime },
    }
    for _, row in ipairs(fields) do
        PerpGUI.DrawInspectorField(row[1], row[2], 8)
    end

    local ct = cinfo.castingtargets
    if ct and table.size and table.size(ct) > 0 then
        if GUI:TreeNode("castingtargets##npcCastTargets") then
            for tid, target in pairs(ct) do
                PerpGUI.DrawInspectorField("target " .. tostring(tid), target, 8)
            end
            GUI:TreePop()
        end
    end
end

function PerpGUI.DrawInspectorBuffs(buffs)
    if not buffs or (table.size and table.size(buffs) == 0) then
        GUI:TextColored(0.5, 0.5, 0.5, 1, "  (none)")
        return
    end

    local list = {}
    for _, b in pairs(buffs) do
        if b then list[#list + 1] = b end
    end
    table.sort(list, function(a, b)
        return (tonumber(a.slot) or 0) < (tonumber(b.slot) or 0)
    end)

    for i, b in ipairs(list) do
        local title = string.format("[%s] %s (id %s)##npcBuff%d",
            tostring(b.slot or "?"), tostring(b.name or "?"), tostring(b.id or "?"), i)
        if GUI:TreeNode(title) then
            PerpGUI.DrawInspectorField("id", b.id, 8)
            PerpGUI.DrawInspectorField("name", b.name, 8)
            PerpGUI.DrawInspectorField("duration", b.duration, 8)
            PerpGUI.DrawInspectorField("stacks", b.stacks, 8)
            PerpGUI.DrawInspectorField("slot", b.slot, 8)
            PerpGUI.DrawInspectorField("ownerid", b.ownerid, 8)
            PerpGUI.DrawInspectorField("isbuff", b.isbuff, 8)
            PerpGUI.DrawInspectorField("isdebuff", b.isdebuff, 8)
            PerpGUI.DrawInspectorField("dispellable", b.dispellable, 8)
            if b.ptr then
                PerpGUI.DrawInspectorField("ptr", string.format("%X", b.ptr), 8)
            end
            if b.ptr2 then
                PerpGUI.DrawInspectorField("ptr2", string.format("%X", b.ptr2), 8)
            end
            GUI:TreePop()
        end
    end
end

function PerpGUI.DrawInspectorTethers(entId)
    local lines = {}
    if Argus and Argus.getTethersOnEnt then
        local tethers = Argus.getTethersOnEnt(entId)
        if tethers then
            for i = 1, #tethers do
                local t = tethers[i]
                lines[#lines + 1] = string.format("out #%d: type=%s partner=%s {%s}",
                    i, tostring(t.type), tostring(t.partnerid), PerpGUI.FormatInspectorValue(t))
            end
        end
    end
    if Argus and Argus.getCurrentTethers then
        local all = Argus.getCurrentTethers()
        if all then
            for sourceId, ts in pairs(all) do
                if ts then
                    for i = 1, #ts do
                        local t = ts[i]
                        if t and (sourceId == entId or t.targetid == entId or t.partnerid == entId) then
                            lines[#lines + 1] = string.format("global src=%s tgt=%s type=%s {%s}",
                                tostring(sourceId), tostring(t.targetid or t.partnerid),
                                tostring(t.type), PerpGUI.FormatInspectorValue(t))
                        end
                    end
                end
            end
        end
    end
    if #lines == 0 then
        GUI:TextColored(0.5, 0.5, 0.5, 1, "  (none)")
        return
    end
    for _, line in ipairs(lines) do
        GUI:TextWrapped("  " .. line)
    end
end

function PerpGUI.DrawInspectorExternal(ent)
    if Argus and Argus.getEntityModel then
        local ok, model = pcall(Argus.getEntityModel, ent.id)
        PerpGUI.DrawInspectorField("Argus model id", ok and model or "error")
    end
    if Argus and Argus.getEntityAuras then
        local ok, p, a1, a2 = pcall(Argus.getEntityAuras, ent.id)
        if ok then
            PerpGUI.DrawInspectorField("Argus aura primary", p)
            PerpGUI.DrawInspectorField("Argus aura 1", a1)
            PerpGUI.DrawInspectorField("Argus aura 2", a2)
        else
            PerpGUI.DrawInspectorField("Argus auras", "error")
        end
    end
    if TensorCore and TensorCore.getEntitySpeed then
        local ok, speed = pcall(TensorCore.getEntitySpeed, ent.id)
        PerpGUI.DrawInspectorField("TensorCore speed", ok and speed or "error")
    end
end

function PerpGUI.DrawInspectorKnownFields(ent)
    local fields = {
        "ptr", "id", "name", "contentid", "type", "chartype", "status", "level", "job",
        "bnpcid", "subcontentid", "modelid", "iconid", "fateid", "targetid", "ownerid",
        "claimedbyid", "radius", "hitradius", "distance", "distance2d", "pathdistance",
        "aggro", "aggropercentage", "attackable", "aggressive", "friendly", "incombat",
        "interactable", "targetable", "alive", "visible", "cangather", "onmesh", "los", "los2",
        "isreachable", "ismounted", "action", "lastaction", "marker", "headMarker", "tp",
        "pettype", "chocobostate", "spearfishstate", "gatherattempts", "gatherattemptsmax",
        "grandcompany", "grandcompanyrank", "onlinestatus", "currentworld", "homeworld",
        "pvpteam", "role", "hasaggro", "revivestate", "combotimeremain", "lastcomboid",
    }
    for _, key in ipairs(fields) do
        local ok, value = pcall(function() return ent[key] end)
        if ok and value ~= nil then
            PerpGUI.DrawInspectorField(key, value, 8)
        end
    end
end

function PerpGUI.DrawInspectorRawPairs(ent)
    local ok, _ = pcall(function()
        for k, v in pairs(ent) do
            PerpGUI.DrawInspectorField(tostring(k), v, 8)
        end
    end)
    if not ok then
        GUI:TextColored(0.5, 0.5, 0.5, 1, "  Entity does not support pairs() — see Known Fields above.")
    end
end

function PerpGUI.DrawNPCInspectorContent(ent)
    PerpGUI.DrawInspectorSection("Identity##npcInsIdentity", function()
        PerpGUI.DrawInspectorField("name", ent.name)
        PerpGUI.DrawInspectorField("id", ent.id)
        PerpGUI.DrawInspectorField("contentid", ent.contentid)
        PerpGUI.DrawInspectorField("bnpcid", ent.bnpcid)
        PerpGUI.DrawInspectorField("type", ent.type)
        PerpGUI.DrawInspectorField("type (label)", PerpGUI.GetEntityTypeName(ent.type))
        PerpGUI.DrawInspectorField("chartype", ent.chartype)
        PerpGUI.DrawInspectorField("status", ent.status)
        PerpGUI.DrawInspectorField("level", ent.level)
        PerpGUI.DrawInspectorField("iconid", ent.iconid)
        PerpGUI.DrawInspectorField("fateid", ent.fateid)
        if ent.ptr then
            PerpGUI.DrawInspectorField("ptr", string.format("%X", ent.ptr))
        end
    end)

    PerpGUI.DrawInspectorSection("Position & Size##npcInsPos", function()
        PerpGUI.DrawInspectorField("pos", ent.pos)
        if ent.meshpos then
            PerpGUI.DrawInspectorField("meshpos", ent.meshpos)
            PerpGUI.DrawInspectorField("meshpos.distance", ent.meshpos.distance)
            PerpGUI.DrawInspectorField("meshpos.meshdistance", ent.meshpos.meshdistance)
        end
        if ent.cubepos and table.valid and table.valid(ent.cubepos) then
            PerpGUI.DrawInspectorField("cubepos", ent.cubepos)
        end
        PerpGUI.DrawInspectorField("hitradius", ent.hitradius)
        PerpGUI.DrawInspectorField("radius", ent.radius)
        PerpGUI.DrawInspectorField("distance", ent.distance)
        PerpGUI.DrawInspectorField("distance2d", ent.distance2d)
        PerpGUI.DrawInspectorField("pathdistance", ent.pathdistance)
        PerpGUI.DrawInspectorField("onmesh", ent.onmesh)
        PerpGUI.DrawInspectorField("isreachable", ent.isreachable)
        PerpGUI.DrawInspectorField("los", ent.los)
        PerpGUI.DrawInspectorField("los2", ent.los2)
    end)

    PerpGUI.DrawInspectorSection("Combat & Flags##npcInsCombat", function()
        PerpGUI.DrawInspectorField("hp", ent.hp and string.format("%s / %s (%.1f%%)",
            tostring(ent.hp.current), tostring(ent.hp.max), tonumber(ent.hp.percent) or 0) or nil)
        PerpGUI.DrawInspectorField("alive", ent.alive)
        PerpGUI.DrawInspectorField("attackable", ent.attackable)
        PerpGUI.DrawInspectorField("aggressive", ent.aggressive)
        PerpGUI.DrawInspectorField("friendly", ent.friendly)
        PerpGUI.DrawInspectorField("incombat", ent.incombat)
        PerpGUI.DrawInspectorField("aggro", ent.aggro)
        PerpGUI.DrawInspectorField("aggropercentage", ent.aggropercentage)
        PerpGUI.DrawInspectorField("targetable", ent.targetable)
        PerpGUI.DrawInspectorField("visible", ent.visible)
        PerpGUI.DrawInspectorField("interactable", ent.interactable)
        PerpGUI.DrawInspectorField("targetid", ent.targetid)
        PerpGUI.DrawInspectorField("ownerid", ent.ownerid)
        PerpGUI.DrawInspectorField("claimedbyid", ent.claimedbyid)
        PerpGUI.DrawInspectorField("marker", ent.marker)
        PerpGUI.DrawInspectorField("headMarker", ent.headMarker)
    end)

    PerpGUI.DrawInspectorSection("Resources##npcInsBars", function()
        PerpGUI.DrawInspectorBar("hp", ent.hp)
        PerpGUI.DrawInspectorBar("mp", ent.mp)
        PerpGUI.DrawInspectorBar("cp", ent.cp)
        PerpGUI.DrawInspectorBar("gp", ent.gp)
        PerpGUI.DrawInspectorField("tp", ent.tp)
    end)

    PerpGUI.DrawInspectorSection("Casting & Actions##npcInsCast", function()
        PerpGUI.DrawInspectorField("action", ent.action)
        PerpGUI.DrawInspectorField("lastaction", ent.lastaction)
        PerpGUI.DrawInspectorCastingInfo(ent.castinginfo)
    end)

    PerpGUI.DrawInspectorSection("Buffs & Debuffs##npcInsBuffs", function()
        PerpGUI.DrawInspectorBuffs(ent.buffs)
    end)

    PerpGUI.DrawInspectorSection("Tethers##npcInsTethers", function()
        PerpGUI.DrawInspectorTethers(ent.id)
    end)

    PerpGUI.DrawInspectorSection("Argus / TensorCore##npcInsExternal", function()
        PerpGUI.DrawInspectorExternal(ent)
    end)

    if ent.eurekainfo and table.size and table.size(ent.eurekainfo) > 0 then
        PerpGUI.DrawInspectorSection("Eureka Info##npcInsEureka", function()
            PerpGUI.DrawInspectorField("level", ent.eurekainfo.level, 8)
            PerpGUI.DrawInspectorField("element", ent.eurekainfo.element, 8)
        end)
    end

    PerpGUI.DrawInspectorSection("All Known Fields##npcInsKnown", function()
        PerpGUI.DrawInspectorKnownFields(ent)
    end)

    PerpGUI.DrawInspectorSection("Raw Entity Dump##npcInsRaw", function()
        PerpGUI.DrawInspectorRawPairs(ent)
    end)
end

-- Floating inspector window; opens automatically when an NPC is selected.
function PerpGUI.DrawSelectedNPCInspectorWindow()
    local selId = PerpGUI.selectedNPCId
    if not selId then
        PerpGUI.lastInspectorNPCId = nil
        return
    end

    if selId ~= PerpGUI.lastInspectorNPCId then
        PerpGUI.showNPCInspector = true
        PerpGUI.lastInspectorNPCId = selId
    end
    if not PerpGUI.showNPCInspector then return end

    local ent = PerpGUI.GetFreshNPCEntity(selId)
    local title = ent and ent.name and ent.name ~= "" and ent.name or ("Entity " .. tostring(selId))

    GUI:SetNextWindowSize(520, 640, GUI.SetCond_FirstUseEver)
    local visible, open = GUI:Begin("NPC Inspector — " .. title .. "###PerpNPCInspector", PerpGUI.showNPCInspector)
    PerpGUI.showNPCInspector = open

    if visible then
        GUI:TextColored(0.6, 0.8, 1, 1, "Live entity data (refreshes every frame)")
        GUI:SameLine()
        if GUI:SmallButton("Refresh List##npcInsRefresh") then
            PerpGUI.RefreshNPCList(true)
        end
        GUI:SameLine()
        if GUI:SmallButton("Copy ID##npcInsCopyId") then
            if GUI.SetClipboardText then
                GUI:SetClipboardText(tostring(selId))
            end
        end

        if not ent then
            GUI:Spacing()
            GUI:TextColored(1, 0.4, 0.4, 1, "Entity not found (despawned or out of range).")
            GUI:Text("ID: " .. tostring(selId))
        else
            GUI:Separator()
            GUI:BeginChild("##npcInspectorScroll", 0, 0, true)
            PerpGUI.DrawNPCInspectorContent(ent)
            GUI:EndChild()
        end
    end

    GUI:End()
end

-- Draw the Debug tab content
function PerpGUI.DrawDebugTab()
    GUI:Spacing()
    GUI:Dummy(5, 0)
    GUI:SameLine()

    -- Row 1: Buttons
    GUI:Button("Refresh", 70, 25)
    if GUI:IsItemClicked(0) then
        PerpGUI.RefreshNPCList()
    end
    if GUI:IsItemHovered() then
        GUI:SetTooltip("Reload NPC list from game world")
    end

    GUI:SameLine()
    GUI:Button("Clear", 50, 25)
    if GUI:IsItemClicked(0) then
        PerpGUI.selectedNPCId = nil
        PerpGUI.showNPCInspector = false
        PerpGUI.lastInspectorNPCId = nil
        PerpGUI.drawArrowToNPC = false
        PerpGUI.drawCardinalArrows = false
    end

    -- Row 2: Drawing checkboxes
    GUI:Dummy(5, 0)
    GUI:SameLine()
    PerpGUI.drawArrowToNPC = GUI:Checkbox("Arrow", PerpGUI.drawArrowToNPC)
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw arrow to selected NPC") end

    GUI:SameLine(0, 15)
    local oldDirs = PerpGUI.drawCardinalArrows
    PerpGUI.drawCardinalArrows = GUI:Checkbox("Dirs", PerpGUI.drawCardinalArrows)
    if PerpGUI.drawCardinalArrows and not oldDirs then
        PerpGUI.lastCardinalTextUpdate = 0
    end
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw 8 directional arrows from NPC") end

    GUI:SameLine(0, 15)
    PerpGUI.drawNPCToNearestWaymark = GUI:Checkbox("NearWM", PerpGUI.drawNPCToNearestWaymark)
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw arrow from NPC to nearest waymark\n(Uses waymark color)") end

    GUI:SameLine(0, 15)
    PerpGUI.drawArenaCenter = GUI:Checkbox("Center", PerpGUI.drawArenaCenter)
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw circle at arena center") end

    GUI:SameLine(0, 15)
    local oldVis = PerpGUI.filterVisibleOnly
    PerpGUI.filterVisibleOnly = GUI:Checkbox("Visible", PerpGUI.filterVisibleOnly)
    if PerpGUI.filterVisibleOnly ~= oldVis then
        PerpGUI.RefreshNPCList()
    end
    if GUI:IsItemHovered() then GUI:SetTooltip("Filter to only show visible NPCs") end

    GUI:SameLine(0, 15)
    local oldUnnamed = PerpGUI.filterShowUnnamed
    PerpGUI.filterShowUnnamed = GUI:Checkbox("Unnamed", PerpGUI.filterShowUnnamed)
    if PerpGUI.filterShowUnnamed ~= oldUnnamed then
        PerpGUI.RefreshNPCList()
    end
    if GUI:IsItemHovered() then GUI:SetTooltip("Also show entities with no name\n(event objects, boss parts, etc.)") end

    -- Row 3: Debug text checkboxes
    GUI:Dummy(5, 0)
    GUI:SameLine()
    PerpGUI.drawNPCDebugText = GUI:Checkbox("NPC Text", PerpGUI.drawNPCDebugText)
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw debug info on all cached NPCs") end

    GUI:SameLine(0, 15)
    PerpGUI.drawPlayerDebug = GUI:Checkbox("Party Text", PerpGUI.drawPlayerDebug)
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw debug info on ALL party members\n(Buffs, Markers, Tethers)") end

    GUI:SameLine(0, 15)
    PerpGUI.drawGroundAOEDebug = GUI:Checkbox("AOE Text", PerpGUI.drawGroundAOEDebug)
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw debug info on all ground AOEs\n(Name, ID, Shape, Size, Position)") end

    -- Row 4: Waymark lines (A-D)
    GUI:Dummy(5, 0)
    GUI:SameLine()
    GUI:TextColored(0.6, 0.6, 0.6, 1, "Waymarks:")
    GUI:SameLine()
    GUI:PushStyleColor(GUI.Col_Text, 1, 0.3, 0.3, 1) -- Red
    PerpGUI.drawWaymarkA = GUI:Checkbox("A", PerpGUI.drawWaymarkA)
    GUI:PopStyleColor()
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw line to waymark A (Red)") end

    GUI:SameLine(0, 8)
    GUI:PushStyleColor(GUI.Col_Text, 1, 1, 0.3, 1) -- Yellow
    PerpGUI.drawWaymarkB = GUI:Checkbox("B", PerpGUI.drawWaymarkB)
    GUI:PopStyleColor()
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw line to waymark B (Yellow)") end

    GUI:SameLine(0, 8)
    GUI:PushStyleColor(GUI.Col_Text, 0.3, 0.5, 1, 1) -- Blue
    PerpGUI.drawWaymarkC = GUI:Checkbox("C", PerpGUI.drawWaymarkC)
    GUI:PopStyleColor()
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw line to waymark C (Blue)") end

    GUI:SameLine(0, 8)
    GUI:PushStyleColor(GUI.Col_Text, 0.8, 0.3, 1, 1) -- Purple
    PerpGUI.drawWaymarkD = GUI:Checkbox("D", PerpGUI.drawWaymarkD)
    GUI:PopStyleColor()
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw line to waymark D (Purple)") end

    -- Row 5: Waymark lines (1-4)
    GUI:Dummy(5, 0)
    GUI:SameLine()
    GUI:Dummy(65, 0)                                 -- Align with above
    GUI:SameLine()
    GUI:PushStyleColor(GUI.Col_Text, 1, 0.3, 0.3, 1) -- Red
    PerpGUI.drawWaymark1 = GUI:Checkbox("1", PerpGUI.drawWaymark1)
    GUI:PopStyleColor()
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw line to waymark 1 (Red)") end

    GUI:SameLine(0, 8)
    GUI:PushStyleColor(GUI.Col_Text, 1, 1, 0.3, 1) -- Yellow
    PerpGUI.drawWaymark2 = GUI:Checkbox("2", PerpGUI.drawWaymark2)
    GUI:PopStyleColor()
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw line to waymark 2 (Yellow)") end

    GUI:SameLine(0, 8)
    GUI:PushStyleColor(GUI.Col_Text, 0.3, 0.5, 1, 1) -- Blue
    PerpGUI.drawWaymark3 = GUI:Checkbox("3", PerpGUI.drawWaymark3)
    GUI:PopStyleColor()
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw line to waymark 3 (Blue)") end

    GUI:SameLine(0, 8)
    GUI:PushStyleColor(GUI.Col_Text, 0.8, 0.3, 1, 1) -- Purple
    PerpGUI.drawWaymark4 = GUI:Checkbox("4", PerpGUI.drawWaymark4)
    GUI:PopStyleColor()
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw line to waymark 4 (Purple)") end

    -- Row 6: Arena center position
    GUI:Dummy(5, 0)
    GUI:SameLine()
    GUI:TextColored(0.6, 0.6, 0.6, 1, "Center:")
    GUI:SameLine()
    GUI:Text("X")
    GUI:SameLine()
    GUI:PushItemWidth(50)
    local newX = GUI:InputInt("##CX", PerpGUI.arenaCenter.x or 100, 0, 0)
    if newX then PerpGUI.arenaCenter.x = newX end
    GUI:PopItemWidth()

    GUI:SameLine(0, 8)
    GUI:Text("Y")
    GUI:SameLine()
    GUI:PushItemWidth(50)
    local newY = GUI:InputInt("##CY", PerpGUI.arenaCenter.y or 0, 0, 0)
    if newY then PerpGUI.arenaCenter.y = newY end
    GUI:PopItemWidth()

    GUI:SameLine(0, 8)
    GUI:Text("Z")
    GUI:SameLine()
    GUI:PushItemWidth(50)
    local newZ = GUI:InputInt("##CZ", PerpGUI.arenaCenter.z or 100, 0, 0)
    if newZ then PerpGUI.arenaCenter.z = newZ end
    GUI:PopItemWidth()

    -- Color picker for center circle
    GUI:SameLine(0, 15)
    GUI:ColorEditMode(GUI.ColorEditMode_NoInputs + GUI.ColorEditMode_AlphaBar)
    local col = PerpGUI.centerCircleColor or { r = 1.0, g = 0.0, b = 0.0, a = 1.0 }
    local r, g, b, a, changed = GUI:ColorEdit4("##CenterColor", col.r, col.g, col.b, col.a)
    if changed then
        PerpGUI.centerCircleColor = { r = r, g = g, b = b, a = a }
        PerpGUI._colorDebugPrinted = nil -- Reset debug print
    end
    if GUI:IsItemHovered() then GUI:SetTooltip("Center circle color") end

    -- Row 7: Debug arrow from center
    GUI:Dummy(5, 0)
    GUI:SameLine()
    PerpGUI.drawDebugArrow = GUI:Checkbox("Arrow##DebugArrow", PerpGUI.drawDebugArrow)
    if GUI:IsItemHovered() then GUI:SetTooltip("Draw debug arrow from arena center") end

    GUI:SameLine(0, 10)
    GUI:Text("Deg:")
    GUI:SameLine()
    GUI:PushItemWidth(120)
    local newDegree = GUI:SliderInt("##ArrowDegree", PerpGUI.debugArrowDegree or 0, 0, 360)
    if newDegree then PerpGUI.debugArrowDegree = newDegree end
    GUI:PopItemWidth()
    if GUI:IsItemHovered() then
        GUI:SetTooltip(
            "Arrow direction in degrees\n0° = North, 90° = East, 180° = South, 270° = West")
    end

    GUI:SameLine(0, 10)
    GUI:Text("Len:")
    GUI:SameLine()
    GUI:PushItemWidth(50)
    local newLength = GUI:InputFloat("##ArrowLength", PerpGUI.debugArrowLength or 10, 0, 0, 1)
    if newLength then PerpGUI.debugArrowLength = math.max(0.5, newLength) end
    GUI:PopItemWidth()
    if GUI:IsItemHovered() then GUI:SetTooltip("Arrow length in yalms") end

    -- Color picker for debug arrow
    GUI:SameLine(0, 10)
    GUI:ColorEditMode(GUI.ColorEditMode_NoInputs + GUI.ColorEditMode_AlphaBar)
    local arrowCol = PerpGUI.debugArrowColor or { r = 1.0, g = 0.5, b = 0.0, a = 1.0 }
    local ar, ag, ab, aa, arrowChanged = GUI:ColorEdit4("##ArrowColor", arrowCol.r, arrowCol.g, arrowCol.b, arrowCol.a)
    if arrowChanged then
        PerpGUI.debugArrowColor = { r = ar, g = ag, b = ab, a = aa }
    end
    if GUI:IsItemHovered() then GUI:SetTooltip("Debug arrow color") end

    -- Row 8: Custom AOE drawings builder
    GUI:Spacing()
    GUI:Dummy(5, 0)
    GUI:SameLine()
    PerpGUI.DrawCustomAOESection()

    GUI:Spacing()
    GUI:Dummy(5, 0)
    GUI:SameLine()
    PerpGUI.DrawMapEffectsSection()

    GUI:Spacing()
    GUI:Separator()

    -- Info display
    GUI:Dummy(5, 0)
    GUI:SameLine()
    local filterText = PerpGUI.filterVisibleOnly and " (visible)" or ""
    GUI:Text("NPCs: " .. tostring(#PerpGUI.npcCache) .. filterText)

    GUI:SameLine(180)
    if PerpGUI.selectedNPCId then
        local selectedNPC = PerpGUI.FindNPCById(PerpGUI.selectedNPCId)
        if selectedNPC then
            GUI:TextColored(0.4, 1, 0.6, 1, "Selected: " .. selectedNPC.name)
        else
            GUI:TextColored(1, 0.5, 0.5, 1, "Selected NPC not found")
        end
    else
        GUI:TextColored(0.5, 0.5, 0.5, 1, "No NPC selected")
    end

    GUI:Spacing()

    -- NPC filter input
    GUI:Dummy(5, 0)
    GUI:SameLine()
    GUI:TextColored(0.7, 0.7, 0.7, 1, "Filter:")
    GUI:SameLine()
    GUI:PushItemWidth(280)
    local newFilter, changed = GUI:InputText("##NPCFilter", PerpGUI.npcFilterString or "alive,maxdistance=100",
        GUI.InputTextFlags_EnterReturnsTrue)
    GUI:PopItemWidth()
    if changed and newFilter ~= nil then
        PerpGUI.npcFilterString = newFilter
        PerpGUI.RefreshNPCList()
        d("[PerpGUI] Filter updated: " .. newFilter)
    end
    if GUI:IsItemHovered() then
        GUI:SetTooltip(
            "Entity filter string (press Enter to apply)\nExamples:\n  alive,maxdistance=100\n  chartype=4\n  contentid=1234")
    end

    GUI:Spacing()

    -- NPC list header
    GUI:Dummy(5, 0)
    GUI:SameLine()
    GUI:TextColored(0.7, 0.7, 0.7, 1, " Dist   Type        Name                    ID")

    -- NPC list
    GUI:Dummy(5, 0)
    GUI:SameLine()
    GUI:ListBoxHeader("##NPCList", 380, 260)

    for i, npc in ipairs(PerpGUI.npcCache) do
        local isSelected = (npc.id == PerpGUI.selectedNPCId)

        -- Selectable row (Minion returns true every frame while selected, not just on click)
        if GUI:Selectable("##npc_" .. tostring(npc.id), isSelected, 0, 340, 0) then
            if PerpGUI.selectedNPCId ~= npc.id then
                PerpGUI.selectedNPCId = npc.id
            end
        end

        -- Draw content on top
        GUI:SameLine(8)

        -- Distance
        local distStr = string.format("%.1f", npc.distance)
        GUI:TextColored(0.6, 0.8, 1, 1, distStr)

        -- Entity type
        GUI:SameLine(55)
        local typeName = PerpGUI.GetEntityTypeName(npc.type)
        if npc.type == 2 then
            GUI:TextColored(1, 0.5, 0.5, 1, typeName)
        elseif npc.type == 7 or npc.type == 3 then
            GUI:TextColored(0.5, 1, 0.5, 1, typeName)
        else
            GUI:TextColored(0.7, 0.7, 0.7, 1, typeName)
        end

        -- Name (truncate if too long)
        GUI:SameLine(120)
        local displayName = npc.name
        if #displayName > 18 then
            displayName = string.sub(displayName, 1, 16) .. ".."
        end
        if isSelected then
            GUI:TextColored(1, 1, 0.4, 1, displayName)
        else
            GUI:TextColored(1, 1, 1, 1, displayName)
        end

        -- ID
        GUI:SameLine(270)
        GUI:TextColored(0.5, 0.5, 0.5, 1, tostring(npc.id))

        if i < #PerpGUI.npcCache and i < 50 then
            GUI:Separator()
        end

        -- Limit display to 50 NPCs for performance
        if i >= 50 then
            GUI:TextColored(0.5, 0.5, 0.5, 1, "... and " .. tostring(#PerpGUI.npcCache - 50) .. " more")
            break
        end
    end

    GUI:ListBoxFooter()

    if PerpGUI.selectedNPCId then
        GUI:Spacing()
        GUI:TextColored(0.5, 0.85, 0.55, 1, "NPC Inspector window is open for the selected entity.")
    end
end

-- Draw the Party Roles tab content
function PerpGUI.DrawPartyRolesTab()
    -- Action buttons with nice styling
    GUI:Spacing()
    GUI:Dummy(5, 0)
    GUI:SameLine()

    GUI:Button("Refresh Party", 95, 28)
    if GUI:IsItemClicked(0) then
        PerpGUI.RefreshPartyList()
    end
    if GUI:IsItemHovered() then
        GUI:SetTooltip("Reload party member list from game")
    end

    GUI:SameLine()
    GUI:Button("Auto-Assign", 95, 28)
    if GUI:IsItemClicked(0) then
        PerpGUI.AutoAssignRoles()
    end
    if GUI:IsItemHovered() then
        GUI:SetTooltip("Automatically assign roles based on job")
    end

    GUI:SameLine()
    GUI:Button("Clear All", 75, 28)
    if GUI:IsItemClicked(0) then
        PerpGUI.ResetToDefaults()
    end
    if GUI:IsItemHovered() then
        GUI:SetTooltip("Clear all role assignments\n(Use Auto-Assign to repopulate)")
    end

    GUI:Spacing()
    GUI:Separator()
    GUI:Spacing()

    -- Party info
    GUI:Dummy(5, 0)
    GUI:SameLine()
    GUI:Text("Party: " .. tostring(#PerpGUI.partyCache) .. " members")
    GUI:SameLine(200)
    GUI:TextColored(0.6, 0.8, 0.6, 1, "Drag rows to swap")

    GUI:Spacing()

    -- Role list header
    GUI:Dummy(5, 0)
    GUI:SameLine()
    GUI:TextColored(0.7, 0.7, 0.7, 1, " Role         Job          Player Name")

    -- Role list with drag support
    GUI:Dummy(5, 0)
    GUI:SameLine()
    GUI:ListBoxHeader("##Roles", 360, 295)

    local roleMembers = {}
    for i, role in ipairs(PerpGUI.roleOrder) do
        local name = PerpCore.Config.PartyRoles[role] or ""
        local member = PerpGUI.FindMemberByName(name)
        table.insert(roleMembers, {
            role = role,
            name = name,
            member = member,
            index = i,
        })
    end

    for i, entry in ipairs(roleMembers) do
        local role = entry.role
        local name = entry.name
        local member = entry.member
        local isSelected = (role == PerpGUI.selected)

        -- Invisible full-width selectable for drag handling
        GUI:Selectable("                                                    ##row_" .. role, isSelected,
            GUI.SelectableFlags_SpanAllColumns, 340, 0)

        -- Drag handling (MuAiCore pattern)
        local hoverFlags = GUI.HoveredFlags_AllowWhenBlockedByPopup + GUI.HoveredFlags_AllowWhenBlockedByActiveItem +
            GUI.HoveredFlags_AllowWhenOverlapped
        if GUI:IsItemHovered(hoverFlags) then
            if GUI:IsMouseDown(0) then
                if PerpGUI.mousePosition == nil then
                    PerpGUI.mousePosition = role
                    PerpGUI.selected = role
                elseif PerpGUI.mousePosition ~= role then
                    PerpGUI.SwapRoles(PerpGUI.mousePosition, role)
                    PerpGUI.mousePosition = role
                    PerpGUI.selected = role
                end
            end
        end

        -- Reset drag state on mouse release
        if PerpGUI.mousePosition ~= nil and (GUI:IsMouseReleased(0) or not GUI:IsMouseDown(0)) then
            PerpGUI.mousePosition = nil
        end
        if PerpGUI.selected ~= nil and (GUI:IsMouseReleased(0) or not GUI:IsMouseDown(0)) then
            PerpGUI.selected = nil
        end

        -- Draw colored content on top (SameLine goes back to start)
        GUI:SameLine(8)

        -- Role label with color
        if role == "MT" or role == "OT" then
            GUI:TextColored(0.4, 0.7, 1, 1, role)
        elseif role == "H1" or role == "H2" then
            GUI:TextColored(0.4, 1, 0.6, 1, role)
        else
            GUI:TextColored(1, 0.5, 0.5, 1, role)
        end

        -- Job icon
        GUI:SameLine(45)
        local jobId = member and member.job or nil
        local iconPath = PerpGUI.GetJobIconPath(jobId, role)
        GUI:Image(iconPath, 20, 20)

        -- Job abbreviation (smaller, after icon)
        GUI:SameLine(0, 5)
        local jobStr = member and PerpGUI.GetJobName(member.job) or "---"
        if member then
            local roleType = PerpGUI.GetIdealRole(member.job)
            if roleType == "tank" then
                GUI:TextColored(0.5, 0.7, 1, 1, jobStr)
            elseif roleType == "healer" then
                GUI:TextColored(0.5, 1, 0.7, 1, jobStr)
            else
                GUI:TextColored(1, 0.6, 0.6, 1, jobStr)
            end
        else
            GUI:TextColored(0.5, 0.5, 0.5, 1, "---")
        end

        -- Player name
        GUI:SameLine(130)
        local displayName = name ~= "" and name or "(empty)"
        if name ~= "" then
            GUI:TextColored(1, 1, 1, 1, displayName)
        else
            GUI:TextColored(0.4, 0.4, 0.4, 1, displayName)
        end

        if i < 8 then
            GUI:Separator()
        end
    end

    GUI:ListBoxFooter()

    -- Reset drag if mouse leaves the list
    local hoverFlags = GUI.HoveredFlags_AllowWhenBlockedByPopup + GUI.HoveredFlags_AllowWhenBlockedByActiveItem +
        GUI.HoveredFlags_AllowWhenOverlapped
    if PerpGUI.mousePosition ~= nil and not GUI:IsItemHovered(hoverFlags) then
        PerpGUI.mousePosition = nil
    end

    -- Perspective player for reaction testing (e.g. replays where you are logged in as yourself)
    if data then
        GUI:Spacing()
        GUI:Separator()
        GUI:Spacing()
        GUI:Dummy(5, 0)
        GUI:SameLine()
        GUI:TextColored(0.7, 0.7, 0.7, 1, "Perspective player (data.perspective):")
        GUI:Dummy(5, 0)
        GUI:SameLine()
        GUI:PushItemWidth(220)
        data.perspective = data.perspective or ""
        local newPerspective, changed = GUI:InputText("##perspective", data.perspective)
        if newPerspective ~= nil then
            data.perspective = newPerspective
        end
        GUI:PopItemWidth()
        if GUI:IsItemHovered() then
            GUI:SetTooltip(
                "Substring match against player names.\nReactions use this instead of your logged-in character.\nMatch a role name above or type part of a replay player's name.")
        end
    end
end

-- Draw the Reactions tab content
function PerpGUI.DrawReactionsTab()
    GUI:Spacing()

    -- Ultimates
    if GUI:TreeNode("Ultimates##reactions") then
        GUI:Spacing()

        -- DMU
        if GUI:TreeNode("DMU##reactions_dmu") then
            GUI:Spacing()

            -- Phase 1
            if GUI:TreeNode("Phase 1##reactions_dmu_p1") then
                GUI:Spacing()

                GUI:Text("Arrows Strat")
                GUI:SameLine(0, 8)
                GUI:PushItemWidth(180)
                local newIdx, changed = GUI:Combo("##dmuP1ArrowsStrat",
                    PerpGUI.dmu.p1ArrowsStratIndex, PerpGUI.dmu.p1ArrowsStratOptions)
                GUI:PopItemWidth()
                if changed and newIdx then
                    PerpGUI.dmu.p1ArrowsStratIndex = newIdx
                    if PerpCore and PerpCore.SetDMUPhase1ArrowsStrat then
                        PerpCore.SetDMUPhase1ArrowsStrat(PerpGUI.dmu.p1ArrowsStratValues[newIdx] or "Default")
                    end
                end
                if GUI:IsItemHovered() then
                    GUI:SetTooltip(
                        "Teleport arrows resolution strat\nDefault (2x2): 2x2 grid around nearest intercardinal waymark\nMerry-go Round: fixed clockwise square spots per debuff pair\nFreaky: Merry-go Round with cardinal spots offset toward center")
                end

                GUI:Spacing()
                GUI:TreePop()
            end

            -- Phase 3
            if GUI:TreeNode("Phase 3##reactions_dmu_p3") then
                GUI:Spacing()

                GUI:Text("Black Hole Strat")
                GUI:SameLine(0, 8)
                GUI:PushItemWidth(180)
                local newP3Idx, p3Changed = GUI:Combo("##dmuP3BlackHoleStrat",
                    PerpGUI.dmu.p3BlackHoleStratIndex, PerpGUI.dmu.p3BlackHoleStratOptions)
                GUI:PopItemWidth()
                if p3Changed and newP3Idx then
                    PerpGUI.dmu.p3BlackHoleStratIndex = newP3Idx
                    if PerpCore and PerpCore.SetDMUPhase3BlackHoleStrat then
                        PerpCore.SetDMUPhase3BlackHoleStrat(PerpGUI.dmu.p3BlackHoleStratValues[newP3Idx] or "Markers")
                    end
                end
                if GUI:IsItemHovered() then
                    GUI:SetTooltip(
                        "Black Hole tether orb resolution strat\nMarkers (piR): A/B/C/D waymark priority\nKefka Relative (ZsQ): 1st/2nd/3rd orb clockwise from big Kefka facing")
                end

                GUI:Spacing()
                GUI:TreePop()
            end

            -- Optimisation
            if GUI:TreeNode("Optimisation##reactions_dmu_optim") then
                GUI:Spacing()

                local ninjaIcon = PerpGUI.GetJobIconPath(PerpGUI.JOB_NINJA, nil)
                GUI:Image(ninjaIcon, 20, 20)
                GUI:SameLine(0, 6)
                if GUI:TreeNode("Ninja##reactions_dmu_ninja") then
                    GUI:Spacing()
                    local prevZeroGcd = PerpGUI.dmu.optimisation.ninja.zeroGcdOpener
                    PerpGUI.dmu.optimisation.ninja.zeroGcdOpener = GUI:Checkbox(
                        "0gcd Opener##ninjaZeroGcdOpener", PerpGUI.dmu.optimisation.ninja.zeroGcdOpener)
                    if PerpGUI.dmu.optimisation.ninja.zeroGcdOpener ~= prevZeroGcd
                        and PerpSettings and PerpSettings.SaveReactions then
                        PerpSettings.SaveReactions()
                    end
                    GUI:Spacing()
                    GUI:TreePop()
                end

                GUI:Spacing()
                GUI:TreePop()
            end

            GUI:Spacing()
            GUI:TreePop()
        end

        GUI:Spacing()
        GUI:TreePop()
    end
end

-- Draw a sidebar navigation button (icon only with tooltip)
function PerpGUI.DrawSidebarButton(tabId, label, iconFile)
    local isSelected = (PerpGUI.currentTab == tabId)

    -- Style for selected vs unselected
    if isSelected then
        GUI:PushStyleColor(GUI.Col_Button, 0.25, 0.35, 0.45, 1.0)
        GUI:PushStyleColor(GUI.Col_ButtonHovered, 0.30, 0.40, 0.50, 1.0)
        GUI:PushStyleColor(GUI.Col_ButtonActive, 0.35, 0.45, 0.55, 1.0)
    else
        GUI:PushStyleColor(GUI.Col_Button, 0.12, 0.12, 0.14, 1.0)
        GUI:PushStyleColor(GUI.Col_ButtonHovered, 0.18, 0.18, 0.22, 1.0)
        GUI:PushStyleColor(GUI.Col_ButtonActive, 0.15, 0.15, 0.18, 1.0)
    end

    -- Draw image button
    local clicked = false
    if PerpGUI.iconBasePath and iconFile then
        local iconPath = PerpGUI.iconBasePath .. iconFile
        if GUI:ImageButton("##btn_" .. tabId, iconPath, PerpGUI.iconSize, PerpGUI.iconSize) then
            clicked = true
        end
    else
        -- Fallback if no icon
        if GUI:Button(label .. "##sidebar_" .. tabId, PerpGUI.iconSize + 8, PerpGUI.iconSize + 8) then
            clicked = true
        end
    end

    -- Show tooltip with label
    if GUI:IsItemHovered() then
        GUI:SetTooltip(label)
    end

    GUI:PopStyleColor(3)

    -- Handle click
    if clicked then
        PerpGUI.currentTab = tabId
        if tabId == "debug" and #PerpGUI.npcCache == 0 then
            PerpGUI.RefreshNPCList()
        end
    end
end

-- Draw the main window with sidebar layout
function PerpGUI.Draw(event, ticks)
    -- Always draw debug overlays (even when window is closed)
    PerpGUI.DrawArrowToSelectedNPC()
    PerpGUI.DrawArenaCenterCircle()
    PerpGUI.DrawAttackRangeOnTarget()
    PerpGUI.DrawSamuraiMidareRange()
    PerpGUI.DrawDebugArrowFromCenter()
    PerpGUI.DrawNPCDebugText()
    PerpGUI.DrawPlayerDebug()
    PerpGUI.DrawGroundAOEDebug()
    PerpGUI.DrawWaymarkLines()
    PerpGUI.DrawCustomAOEs()
    PerpGUI.DrawCustomAOEPlacementPreview()
    PerpGUI.DrawMapEffectsWorldText()
    PerpGUI.DrawMapEffectsExplorerWindow()
    PerpGUI.DrawSelectedNPCInspectorWindow()

    if not PerpGUI.open then
        PerpGUI.HandleCustomAOEClickPlace()
        return
    end

    -- Larger window to accommodate sidebar + content
    GUI:SetNextWindowSize(580, 520, GUI.SetCond_Appearing)
    PerpGUI.visible, PerpGUI.open = GUI:Begin("PerpCore", PerpGUI.open)

    if PerpGUI.visible then
        -- Use columns for sidebar layout
        GUI:Columns(2, "##PerpCoreLayout", true)
        GUI:SetColumnWidth(0, PerpGUI.sidebarWidth)

        -- ============ LEFT SIDEBAR ============
        GUI:Spacing()

        -- Draw each sidebar button
        for _, tab in ipairs(PerpGUI.tabs) do
            GUI:Dummy(4, 0)
            GUI:SameLine()
            PerpGUI.DrawSidebarButton(tab.id, tab.label, tab.icon)
        end

        -- ============ RIGHT CONTENT AREA ============
        GUI:NextColumn()

        -- Draw active tab content
        if PerpGUI.currentTab == "party" then
            PerpGUI.DrawPartyRolesTab()
        elseif PerpGUI.currentTab == "debug" then
            PerpGUI.DrawDebugTab()
        elseif PerpGUI.currentTab == "reactions" then
            PerpGUI.DrawReactionsTab()
        end

        GUI:Columns(1)
    end

    GUI:End()
    PerpGUI.HandleCustomAOEClickPlace()
end

-- Initialize function
function PerpGUI.Initialize()
    local tooltip = "PerpCore Configuration\nParty Roles | Debug | Reactions"

    -- Set icon base path
    PerpGUI.iconBasePath = GetLuaModsPath() .. "\\PerpCore\\Images\\Icons\\"

    ml_gui.ui_mgr:AddMember({
        id = "PerpCore",
        name = "PerpCore",
        onClick = function()
            PerpGUI.Toggle()
        end,
        tooltip = tooltip,
        texture = PerpGUI.iconBasePath .. "reactions.png",
    }, "FFXIVMINION##MENU_HEADER")

    -- Initial party refresh
    PerpGUI.RefreshPartyList()

    d("[PerpGUI] Initialized. Press Ctrl+P or use Minion menu to open.")
end

-- Register event handlers
RegisterEventHandler("Module.Initalize", PerpGUI.Initialize, "PerpGUI_Initialize")
RegisterEventHandler("Gameloop.Update", PerpGUI.Update, "PerpGUI_Update")
RegisterEventHandler("Gameloop.Draw", PerpGUI.Draw, "PerpGUI_Draw")

d("[PerpGUI] Loaded.")
