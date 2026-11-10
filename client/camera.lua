Camera = {}

local FOV = 40.0
local FRAMES = {
    face = { dist = 0.75, high = 0.62 },
    chest = { dist = 1.35, high = 0.28 },
    body = { dist = 2.4, high = -0.05 },
}
local DIST_MIN, DIST_MAX = 0.5, 2.8
local HIGH_MIN, HIGH_MAX = -0.85, 0.75
local SMOOTH = 0.18

local active, cam = false, nil
local base, anchorZ
local target, current = {}, {}

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

local function forward(heading)
    local h = math.rad(heading)
    return vector3(-math.sin(h), math.cos(h), 0.0)
end

local function place(v, ped)
    local point = vector3(base.x, base.y, anchorZ + v.high)
    local dir = forward(v.heading)
    local dist = v.dist
    local ray = StartExpensiveSynchronousShapeTestLosProbe(point.x, point.y, point.z,
        point.x + dir.x * dist, point.y + dir.y * dist, point.z, 1 + 16, ped, 4)
    local _, hit, stop = GetShapeTestResult(ray)
    if hit == 1 or hit == true then dist = math.max(0.3, #(vector3(stop.x, stop.y, stop.z) - point) - 0.15) end
    local pos = point + dir * dist
    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, point.x, point.y, point.z)
end

function Camera.start(frame)
    local ped = PlayerPedId()
    base = GetEntityCoords(ped)
    anchorZ = base.z
    local f = FRAMES[frame] or FRAMES.face
    local heading = GetEntityHeading(ped)
    target = { dist = f.dist, high = f.high, heading = heading }
    current = { dist = f.dist, high = f.high, heading = heading }
    cam = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, FOV, false, 0)
    place(current, ped)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
    active = true
    CreateThread(function()
        while active and cam do
            local p = PlayerPedId()
            anchorZ = anchorZ + (GetEntityCoords(p).z - anchorZ) * SMOOTH
            for k, val in pairs(target) do current[k] = current[k] + (val - current[k]) * SMOOTH end
            place(current, p)
            Wait(0)
        end
    end)
end

function Camera.stop()
    if not active then return end
    active = false
    RenderScriptCams(false, true, 500, true, true)
    if cam then DestroyCam(cam, false) end
    cam = nil
end

function Camera.frame(name)
    local f = FRAMES[name]
    if not active or not f then return end
    target.dist, target.high = f.dist, f.high
end

function Camera.rotate(dx)
    dx = tonumber(dx)
    if not active or not dx then return end
    local ped = PlayerPedId()
    SetEntityHeading(ped, GetEntityHeading(ped) + clamp(dx, -1.0, 1.0) * 360.0)
end

function Camera.zoom(dir)
    if not active then return end
    target.dist = clamp(target.dist * ((tonumber(dir) or 0) > 0 and 0.85 or 1 / 0.85), DIST_MIN, DIST_MAX)
    target.high = clamp(target.high, HIGH_MIN, HIGH_MAX)
end
