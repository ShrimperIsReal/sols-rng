-- MADE BY SHRIMPER :D
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

-- Edit these settings if you want to.
local REACH_DIST           = 4.5
local WAYPOINT_TIMEOUT     = 2.5
local STUCK_VEL_THRESHOLD  = 1.5
local STUCK_CHECK_AFTER    = 0.8
local JUMP_COOLDOWN        = 0.2
local MAX_PATH_ATTEMPTS    = 3
local WALK_HARD_TIMEOUT    = 90
local GLOBAL_STUCK_TIMEOUT = 90
local RESPAWN_TIMEOUT      = 8
local QUEUE_COOLDOWN       = 0.2

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

local PRIORITY_SET = {
    andromeda_egg      = true, angelic_egg  = true, blooming_egg = true,
    dreamer_egg        = true, egg_v2       = true, forest_egg   = true,
    hatch_egg          = true, royal_egg    = true, the_egg_of_the_sky = true,
}

local farmEnabled  = shared.toggled or false
local isWalking    = false
local eggQueue     = {}
local queuedIds    = {}
local lastMoveTick = tick()
local lastPos      = Vector3.zero

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

local function killChar()
    pcall(function()
        local h = getHum(getChar())
        if h then h.Health = 0 end
    end)
end

local function awaitFreshChar(timeout)
    timeout = timeout or RESPAWN_TIMEOUT
    local c = getChar()
    if c then
        local h = getHum(c)
        local r = getRoot(c)
        if h and h.Health > 0 and r then return c, h, r end
    end

    local newChar
    local conn = player.CharacterAdded:Connect(function(ch) newChar = ch end)
    local deadline = tick() + timeout
    while not newChar and tick() < deadline do task.wait(0.05) end
    conn:Disconnect()

    c = newChar or getChar()
    if not c then return nil, nil, nil end
    local h = c:WaitForChild("Humanoid",          RESPAWN_TIMEOUT)
    local r = c:WaitForChild("HumanoidRootPart",  RESPAWN_TIMEOUT)
    if not h or not r then return nil, nil, nil end
    return c, h, r
end

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
            p.Color      = (wp.Action == Enum.PathWaypointAction.Jump)
                           and JUMP_COLOR or eggColor
            p.Parent     = folder
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

local function stepToWaypoint(hum, root, wp, pathFolder)
    if not hum or not root or hum.Health <= 0 then return "dead" end

    hum:MoveTo(wp.Position)

    local result   = nil
    local startT   = tick()
    local lastJumpTime = 0

    local moveConn = hum.MoveToFinished:Connect(function(reached)
        if result == nil then result = reached and "reached" or "timeout" end
    end)

    while result == nil do
        task.wait()

        if not farmEnabled then result = "stopped" break end
        if hum.Health <= 0 then result = "dead" break end
        if tick() - startT > WAYPOINT_TIMEOUT then result = "timeout" break end

        local dist = (root.Position - wp.Position).Magnitude
        if dist < REACH_DIST then
            result = "reached"
            lastMoveTick = tick()
            break
        end

        if (tick() - startT) > STUCK_CHECK_AFTER and (tick() - lastJumpTime) > JUMP_COOLDOWN then
            if root.AssemblyLinearVelocity.Magnitude < STUCK_VEL_THRESHOLD then
                lastJumpTime = tick()
                doJump(hum)
                hum:MoveTo(wp.Position)
            end
        end
    end

    moveConn:Disconnect()
    return result
end

local function walkToEgg(targetInstance, eggColor)
    local _, hum, root = awaitFreshChar()
    if not hum or not root then return "fail" end

    for attempt = 1, MAX_PATH_ATTEMPTS do
        if not farmEnabled then return "stopped" end

        local targetPos = resolvePos(targetInstance)
        if not targetPos then return "done" end

        local path = PathfindingService:CreatePath(PATH_PARAMS)
        local ok = pcall(function() path:ComputeAsync(root.Position, targetPos) end)
        
        if not ok or path.Status ~= Enum.PathStatus.Success then
            task.wait(0.2)
            continue
        end

        local waypoints = path:GetWaypoints()
        local pathFolder, cleanup = makePathFolder(waypoints, eggColor)
        local pathBroken = false

        for i, wp in ipairs(waypoints) do
            if not farmEnabled or not isAlive(targetInstance) or hum.Health <= 0 then
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

            local stepResult = stepToWaypoint(hum, root, wp, pathFolder)

            if stepResult ~= "reached" then
                pathBroken = true
                if stepResult == "timeout" or stepResult == "dead" then killChar() end
                break
            end
        end

        cleanup()
        if not farmEnabled then return "stopped" end
        if pathBroken then task.wait(0.1) continue end

        if isAlive(targetInstance) then
            for _, v in ipairs(targetInstance:GetDescendants()) do
                if v:IsA("ProximityPrompt") then fireproximityprompt(v) end
            end
        end

        task.wait(0.1)
        killChar()
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
    if not farmEnabled or isWalking or #eggQueue == 0 then return end
    isWalking = true

    task.spawn(function()
        local hardTimer = task.delay(WALK_HARD_TIMEOUT, function() releaseWalking() end)
        pruneQueue()
        local data = table.remove(eggQueue, 1)
        if data and queuedIds[data.id] then
            queuedIds[data.id] = nil
            if isAlive(data.target) and farmEnabled then
                walkToEgg(data.target, data.color)
            end
        end
        task.cancel(hardTimer)
        releaseWalking()
        if farmEnabled then task.wait(QUEUE_COOLDOWN) processQueue() end
    end)
end

local function checkEgg(v)
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
        if farmEnabled then processQueue() end
    end)
end

player.Chatted:Connect(function(msg)
    local cmd = msg:lower():match("^/e%s+farm%s+(%a+)$")
    if cmd == "on" then
        farmEnabled = true
        lastMoveTick = tick()
        for _, v in ipairs(workspace:GetChildren()) do checkEgg(v) end
        processQueue()
    elseif cmd == "off" then
        farmEnabled = false
        isWalking = false
    end
end)

workspace.ChildAdded:Connect(checkEgg)
print("[EggBot] Bot Loaded!")
