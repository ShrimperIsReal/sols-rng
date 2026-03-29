-- MADE BY SHRIMPER :D

if workspace:FindFirstChild("Slope1") then
	task.spawn(function()
		workspace:FindFirstChild("Slope1"):Destroy()
		workspace:FindFirstChild("Anti-Stuck1"):Destroy()
		workspace:FindFirstChild("Anti-Stuck2"):Destroy()
		workspace:FindFirstChild("Anti-Stuck3"):Destroy()
		workspace:FindFirstChild("Anti-Stuck4"):Destroy()
	end)
end

local Slope1 = Instance.new("Part", game.Workspace)
Slope1.Name = "SlopeSoNoStuckyPoo"
Slope1.Size = Vector3.new(10,15,15)
Slope1.Position = Vector3.new(448.75, 102.75, -406)
Slope1.Rotation = Vector3.new(0,90,0)
Slope1.Shape = Enum.PartType.Wedge
Slope1.Anchored = true
Slope1.Transparency = 0.5

local AntiSign1 = Instance.new("Part", game.Workspace)
AntiSign1.Name = "Anti-Stuck1"
AntiSign1.Anchored = true
AntiSign1.Size = Vector3.new(2, 34, 21)
AntiSign1.Position = Vector3.new(321, 100, -390)
AntiSign1.Rotation = Vector3.new(-90, 0, 180)
AntiSign1.Transparency = 0.5

local AntiSign2 = Instance.new("Part", game.Workspace)
AntiSign2.Name = "Anti-Stuck2"
AntiSign2.Anchored = true
AntiSign2.Size = Vector3.new(25,40,5)
AntiSign2.Position = Vector3.new(278.137, 106, -433.454)
AntiSign2.Rotation = Vector3.new(0, -69.999, 0)
AntiSign2.Transparency = 0.5

local AntiSign3 = Instance.new("Part", game.Workspace)
AntiSign3.Name = "Anti-Stuck3"
AntiSign3.Anchored = true
AntiSign3.Size = Vector3.new(25,40,5)
AntiSign3.Position = Vector3.new(255.786, 106, -452.495)
AntiSign3.Rotation = Vector3.new(0, -19.999, 0)
AntiSign3.Transparency = 0.5

local AntiSign4 = Instance.new("Part", game.Workspace)
AntiSign4.Name = "Anti-Stuck4"
AntiSign4.Anchored = true
AntiSign4.Size = Vector3.new(40, 50, 8)
AntiSign4.Position = Vector3.new(113.875, 100, -444)
AntiSign4.Rotation = Vector3.new(0, -90, 0)
AntiSign4.Transparency = 0.5

local Players            = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PATH_PARAMS = {
    AgentHeight     = 1.5,
    AgentRadius     = 2,
    AgentCanJump    = true,
    AgentJumpHeight = 25,
    WaypointSpacing = shared.spacing or 2,
}

-- edit whatever yo want bruh
local REACH_DIST           = 4.5
local WAYPOINT_TIMEOUT      = 2.5
local STUCK_VEL_THRESHOLD  = 1.5
local STUCK_CHECK_AFTER    = 0.8
local JUMP_COOLDOWN        = 0.2
local MAX_PATH_ATTEMPTS    = 5
local WALK_HARD_TIMEOUT    = 90
local GLOBAL_STUCK_TIMEOUT = 90
local QUEUE_COOLDOWN       = 0.2
local GAP_DEPTH_THRESHOLD  = 5

local EGG_COLORS = {
    [1] = Color3.fromRGB(255, 255, 255),
    [2] = Color3.fromRGB(0,   255, 0),
    [3] = Color3.fromRGB(0,   170, 255),
    [4] = Color3.fromRGB(170, 0,   255),
    [5] = Color3.fromRGB(255, 170, 0),
    [6] = Color3.fromRGB(255, 0,   0),
}
local JUMP_COLOR     = Color3.fromRGB(255, 100, 0)
local PRIORITY_COLOR = Color3.fromRGB(255, 0,   0)
local POTION_COLOR   = Color3.fromRGB(170, 0,   255)
local DEFAULT_COLOR  = Color3.new(1, 1, 1)
local GAP_COLOR      = Color3.fromRGB(255, 50, 50)

local PRIORITY_SET = {
    andromeda_egg      = true, angelic_egg  = true, blooming_egg = true,
    dreamer_egg        = true, egg_v2       = true, forest_egg   = true,
    hatch_egg          = true, royal_egg    = true, the_egg_of_the_sky = true,
}

local function farmEnabled()  return shared.toggled == true end
local function setFarm(v)     shared.toggled = v end
local isWalking    = false
local eggQueue     = {}
local queuedIds    = {}
local lastMoveTick = tick()

local function isAlive(inst)
    return inst ~= nil and inst.Parent ~= nil
end

local function safeGet(fn)
    local ok, val = pcall(fn)
    return ok and val or nil
end

local function getChar()  return player.Character end
local function getHum(c)  return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(c) return c and c:FindFirstChild("HumanoidRootPart") end

local function resolvePos(inst)
    if not isAlive(inst) then return nil end
    return safeGet(function()
        if inst:IsA("BasePart") then return inst.Position end
        if inst:IsA("Model") then
            if inst.PrimaryPart then return inst.PrimaryPart.Position end
            local bp = inst:FindFirstChildWhichIsA("BasePart", true)
            return bp and bp.Position
        end
    end)
end

local function isGapBelow(position)
    local rayOrigin    = position + Vector3.new(0, 0.5, 0)
    local rayDirection = Vector3.new(0, -(GAP_DEPTH_THRESHOLD + 0.5), 0)
    local params       = RaycastParams.new()
    params.FilterType  = Enum.RaycastFilterType.Exclude
    local char = getChar()
    if char then params.FilterDescendantsInstances = { char } end
    local result = workspace:Raycast(rayOrigin, rayDirection, params)
    return result == nil
end

local function pathSegmentHasGap(fromPos, toPos)
    local mid = (fromPos + toPos) / 2
    return isGapBelow(toPos) or isGapBelow(mid)
end

local function makePathFolder(waypoints, eggColor)
    local folder = Instance.new("Folder")
    folder.Name  = "ActivePath"

    pcall(function()
        for _, wp in ipairs(waypoints) do
            local p      = Instance.new("Part")
            p.Shape      = Enum.PartType.Ball
            p.Size       = Vector3.new(0.6, 0.6, 0.6)
            p.Position   = wp.Position
            p.Anchored   = true
            p.CanCollide = false
            p.CastShadow = false
            p.Material   = Enum.Material.Neon
            if isGapBelow(wp.Position) then
                p.Color = GAP_COLOR
            elseif wp.Action == Enum.PathWaypointAction.Jump then
                p.Color = JUMP_COLOR
            else
                p.Color = eggColor
            end
            p.Parent = folder
        end
    end)

    folder.Parent = workspace

    local function cleanup()
        task.spawn(function()
            pcall(function()
                if folder.Parent then folder:Destroy() end
            end)
        end)
    end

    return folder, cleanup
end

local function doJump(hum)
    if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function stepToWaypoint(hum, root, wp)
    if not hum or not root then return "fail" end

    hum:MoveTo(wp.Position)

    local result       = nil
    local startT       = tick()
    local lastJumpTime = 0
    local lastPos      = root.Position
    local lastPosTime  = tick()
    local PROGRESS_CHECK_INTERVAL = 0.6
    local MIN_PROGRESS = 0.8

    local moveConn = hum.MoveToFinished:Connect(function(reached)
        if result == nil then result = reached and "reached" or "timeout" end
    end)

    while result == nil do
        task.wait()

        if not farmEnabled() then result = "stopped" break end
        if tick() - startT > WAYPOINT_TIMEOUT then result = "timeout" break end

        local dist = (root.Position - wp.Position).Magnitude
        if dist < REACH_DIST then
            result = "reached"
            lastMoveTick = tick()
            break
        end

        local now = tick()

        if now - lastPosTime > PROGRESS_CHECK_INTERVAL then
            local moved = (root.Position - lastPos).Magnitude

            if moved < MIN_PROGRESS then
                local awayDir = (root.Position - wp.Position).Unit
                local ceilingRay = workspace:Raycast(
                    root.Position,
                    Vector3.new(0, 3.5, 0),
                    RaycastParams.new()
                )
                if ceilingRay then
                    local backTarget = root.Position + Vector3.new(awayDir.X * 3, 0, awayDir.Z * 3)
                    hum:MoveTo(backTarget)
                    task.wait(0.4)
                    hum:MoveTo(wp.Position)
                elseif (now - lastJumpTime) > JUMP_COOLDOWN then
                    lastJumpTime = now
                    doJump(hum)
                    hum:MoveTo(wp.Position)
                end
            end

            lastPos     = root.Position
            lastPosTime = now
        end
    end

    moveConn:Disconnect()
    return result
end

local function respawnAndWait()
    local humanoid = getHum(getChar())
    if humanoid then
        humanoid.Health = 0
    end
    task.wait(0.5)
    local timeout = 10
    local t0      = tick()
    while tick() - t0 < timeout do
        local c    = getChar()
        local hum  = getHum(c)
        local root = getRoot(c)
        if c and hum and root and hum.Health > 0 then break end
        task.wait(0.2)
    end
    task.wait(0.3)
end
local function rescanWorkspace()
    for _, v in ipairs(workspace:GetChildren()) do
        checkEgg(v)
    end
end

local function walkToEgg(targetInstance, eggColor)
    local char = getChar()
    local hum = getHum(char)
    local root = getRoot(char)

    if not hum or not root then return "fail" end

    for attempt = 1, MAX_PATH_ATTEMPTS do
        if not farmEnabled() then return "stopped" end

        local targetPos = resolvePos(targetInstance)
        if not targetPos then return "done" end

        local path = PathfindingService:CreatePath(PATH_PARAMS)
        local ok = pcall(function() path:ComputeAsync(root.Position, targetPos) end)

        if not ok or path.Status ~= Enum.PathStatus.Success then
            task.wait(0.2)
            continue
        end

        local waypoints   = path:GetWaypoints()
        local pathFolder, cleanup = makePathFolder(waypoints, eggColor)
        local pathBroken  = false

        for i, wp in ipairs(waypoints) do
            if not farmEnabled() or not isAlive(targetInstance) then
                pathBroken = true
                break
            end
            local prevPos = (i > 1) and waypoints[i-1].Position or root.Position
            if pathSegmentHasGap(prevPos, wp.Position) then
                warn("[EggBot] Gap detected near waypoint " .. i .. " – abandoning path attempt " .. attempt)
                pathBroken = true
                break
            end

            local needsJump = wp.Action == Enum.PathWaypointAction.Jump
            if not needsJump and i < #waypoints then
                if (waypoints[i+1].Position.Y - wp.Position.Y) > 1.2 then
                    needsJump = true
                end
            end

            if needsJump then
                doJump(hum)
            end

            local stepResult = stepToWaypoint(hum, root, wp)

            if stepResult ~= "reached" then
                pathBroken = true
                break
            end
        end

        cleanup()
        if not farmEnabled() then return "stopped" end
        if pathBroken then task.wait(0.1) continue end

        local collected = false
        if isAlive(targetInstance) then
            for _, v in ipairs(targetInstance:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    task.wait(0.5)
                    fireproximityprompt(v)
                    collected = true
                end
            end
        end

        task.wait(0.1)

        if collected then
            respawnAndWait()
            rescanWorkspace()
        end

        return "done"
    end
    return "fail"
end

local function pruneQueue()
    local alive = {}
    for _, e in ipairs(eggQueue) do
        if isAlive(e.target) then table.insert(alive, e) else queuedIds[e.id] = nil end
    end
    eggQueue = alive
end

local function releaseWalking() isWalking = false end

local function processQueue()
    if not farmEnabled() or isWalking or #eggQueue == 0 then return end
    isWalking = true

    task.spawn(function()
        local hardTimer = task.delay(WALK_HARD_TIMEOUT, function() releaseWalking() end)
        pruneQueue()
        local data = table.remove(eggQueue, 1)
        if data and queuedIds[data.id] then
            queuedIds[data.id] = nil
            if isAlive(data.target) and farmEnabled() then
                walkToEgg(data.target, data.color)
            end
        end
        task.cancel(hardTimer)
        releaseWalking()
        if farmEnabled() then task.wait(QUEUE_COOLDOWN) processQueue() end
    end)
end

function checkEgg(v)
    task.spawn(function()
        if not v or not (v:IsA("Model") or v:IsA("BasePart")) then return end
        task.wait(0.1)
        if not isAlive(v) then return end

        local name = v.Name
        local uid  = name .. tostring(v)
        if queuedIds[uid] then return end

        local eggNum     = tonumber(string.match(name, "egg_(%d+)$"))
        local isPriority = PRIORITY_SET[name] == true
        local isPotion   = string.find(name, "potion", 1, true) ~= nil
        local eggColor

        if isPriority then eggColor = PRIORITY_COLOR
        elseif isPotion then eggColor = POTION_COLOR
        elseif eggNum then eggColor = EGG_COLORS[eggNum] or DEFAULT_COLOR
        else return end

        queuedIds[uid] = true
        table.insert(eggQueue, isPriority and 1 or #eggQueue + 1, { target = v, color = eggColor, id = uid })
        if farmEnabled() then processQueue() end
    end)
end

player.Chatted:Connect(function(msg)
    local cmd = msg:lower():match("^/e%s+farm%s+(%a+)$")
    if cmd == "on" then
        setFarm(true)
        lastMoveTick = tick()
        for _, v in ipairs(workspace:GetChildren()) do checkEgg(v) end
        processQueue()
    elseif cmd == "off" then
        setFarm(false)
        isWalking = false
    end
end)

workspace.ChildAdded:Connect(checkEgg)
print("[EggBot] Bot Loaded - V1.6.0!")
