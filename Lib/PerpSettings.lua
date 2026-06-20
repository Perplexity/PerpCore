-- PerpSettings: autosave / load for PerpGUI Reactions tab settings only.

PerpSettings = PerpSettings or {}

local VALID_P1_ARROWS = { Default = true, MerryGoRound = true, Freaky = true }
local VALID_P3_BLACK_HOLE = { Markers = true, KefkaRelative = true }

function PerpSettings.GetFilePath()
    if not GetLuaModsPath then
        return nil
    end
    return GetLuaModsPath() .. "\\PerpCore\\settings.lua"
end

local function quoteString(s)
    return string.format("%q", tostring(s))
end

local function isArrayTable(tbl)
    local n = #tbl
    if n == 0 then
        return false
    end
    for k in pairs(tbl) do
        if type(k) ~= "number" or k < 1 or k > n or math.floor(k) ~= k then
            return false
        end
    end
    return true
end

local function serializeValue(value, indent)
    local t = type(value)
    if t == "nil" then
        return "nil"
    end
    if t == "boolean" or t == "number" then
        return tostring(value)
    end
    if t == "string" then
        return quoteString(value)
    end
    if t ~= "table" then
        return "nil"
    end

    local pad = string.rep("    ", indent)
    local inner = string.rep("    ", indent + 1)
    local lines = { "{" }

    if isArrayTable(value) then
        for i = 1, #value do
            lines[#lines + 1] = inner .. serializeValue(value[i], indent + 1) .. ","
        end
    else
        local keys = {}
        for k in pairs(value) do
            keys[#keys + 1] = k
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)
        for _, k in ipairs(keys) do
            local keyStr
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                keyStr = k
            else
                keyStr = "[" .. serializeValue(k, indent + 1) .. "]"
            end
            lines[#lines + 1] = inner .. keyStr .. " = " .. serializeValue(value[k], indent + 1) .. ","
        end
    end

    lines[#lines + 1] = pad .. "}"
    return table.concat(lines, "\n")
end

function PerpSettings.Collect()
    return {
        Strats = {
            DMUPhase1Arrows = PerpCore.GetDMUPhase1ArrowsStrat(),
            DMUPhase3BlackHole = PerpCore.GetDMUPhase3BlackHoleStrat(),
        },
        dmu = {
            p1ArrowsStratIndex = (PerpGUI.dmu and PerpGUI.dmu.p1ArrowsStratIndex) or 1,
            p3BlackHoleStratIndex = (PerpGUI.dmu and PerpGUI.dmu.p3BlackHoleStratIndex) or 1,
            optimisation = {
                ninja = {
                    zeroGcdOpener = PerpGUI.dmu
                        and PerpGUI.dmu.optimisation
                        and PerpGUI.dmu.optimisation.ninja
                        and PerpGUI.dmu.optimisation.ninja.zeroGcdOpener
                        or false,
                },
            },
        },
    }
end

local function indexForValue(values, target)
    if not values then
        return 1
    end
    for i, v in ipairs(values) do
        if v == target then
            return i
        end
    end
    return 1
end

local function normalizeStrat(value, valid, fallback)
    if value and valid[value] then
        return value
    end
    return fallback
end

local function resolveDmuBlock(settings)
    if type(settings.dmu) == "table" then
        return settings.dmu
    end
    -- Legacy saves nested under Reactions.
    if type(settings.Reactions) == "table" and type(settings.Reactions.dmu) == "table" then
        return settings.Reactions.dmu
    end
    return nil
end

function PerpSettings.Apply(settings)
    if type(settings) ~= "table" then
        return false
    end

    local strats = settings.Strats or {}
    local p1 = normalizeStrat(strats.DMUPhase1Arrows, VALID_P1_ARROWS, "Default")
    local p3 = normalizeStrat(strats.DMUPhase3BlackHole, VALID_P3_BLACK_HOLE, "Markers")
    PerpCore.SetDMUPhase1ArrowsStrat(p1)
    PerpCore.SetDMUPhase3BlackHoleStrat(p3)

    PerpGUI.dmu = PerpGUI.dmu or {}
    PerpGUI.dmu.p1ArrowsStratIndex = indexForValue(PerpGUI.dmu.p1ArrowsStratValues, p1)
    PerpGUI.dmu.p3BlackHoleStratIndex = indexForValue(PerpGUI.dmu.p3BlackHoleStratValues, p3)

    local dmu = resolveDmuBlock(settings)
    if type(dmu) == "table" then
        if tonumber(dmu.p1ArrowsStratIndex) then
            local idx = math.floor(dmu.p1ArrowsStratIndex)
            local value = PerpGUI.dmu.p1ArrowsStratValues and PerpGUI.dmu.p1ArrowsStratValues[idx]
            if value and VALID_P1_ARROWS[value] then
                PerpGUI.dmu.p1ArrowsStratIndex = idx
                PerpCore.SetDMUPhase1ArrowsStrat(value)
            end
        end
        if tonumber(dmu.p3BlackHoleStratIndex) then
            local idx = math.floor(dmu.p3BlackHoleStratIndex)
            local value = PerpGUI.dmu.p3BlackHoleStratValues and PerpGUI.dmu.p3BlackHoleStratValues[idx]
            if value and VALID_P3_BLACK_HOLE[value] then
                PerpGUI.dmu.p3BlackHoleStratIndex = idx
                PerpCore.SetDMUPhase3BlackHoleStrat(value)
            end
        end
        local ninja = dmu.optimisation and dmu.optimisation.ninja
        if type(ninja) == "table" and type(ninja.zeroGcdOpener) == "boolean" then
            PerpGUI.dmu.optimisation = PerpGUI.dmu.optimisation or {}
            PerpGUI.dmu.optimisation.ninja = PerpGUI.dmu.optimisation.ninja or {}
            PerpGUI.dmu.optimisation.ninja.zeroGcdOpener = ninja.zeroGcdOpener
        end
    end

    return true
end

function PerpSettings.Load()
    local path = PerpSettings.GetFilePath()
    if not path then
        return false
    end

    local chunk, err = loadfile(path)
    if not chunk then
        return false
    end

    local ok, settings = pcall(chunk)
    if not ok or type(settings) ~= "table" then
        d("[PerpSettings] Failed to load settings: " .. tostring(settings))
        return false
    end

    PerpSettings._loading = true
    local applied = PerpSettings.Apply(settings)
    PerpSettings._loading = false

    if applied then
        d("[PerpSettings] Loaded Reactions settings from " .. path)
    end
    return applied
end

function PerpSettings.Save()
    if PerpSettings._loading or PerpSettings._saving then
        return false
    end
    if not FileWrite then
        return false
    end

    local path = PerpSettings.GetFilePath()
    if not path then
        return false
    end

    PerpSettings._saving = true
    local payload = PerpSettings.Collect()
    local body = "-- PerpCore Reactions tab settings (auto-generated; edits may be overwritten)\nreturn "
        .. serializeValue(payload, 0)
        .. "\n"
    FileWrite(path, body, false)
    PerpSettings._saving = false
    return true
end

function PerpSettings.SaveReactions()
    return PerpSettings.Save()
end
