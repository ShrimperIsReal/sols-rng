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
 
local Slope2 = Instance.new("Part", game.Workspace)
Slope2.Name = "SlopeSoNoStuckyPoo2"
Slope2.Size = Vector3.new(33, 20, 30)
Slope2.Position = Vector3.new(-63, 85, -182)
Slope2.Rotation = Vector3.new(0,0,0)
Slope2.Shape = Enum.PartType.Wedge
Slope2.Anchored = true
Slope2.Transparency = 0.5
 
local Slope3 = Instance.new("Part", game.Workspace)
Slope3.Name = "SlopeSoNoStuckyPoo3"
Slope3.Size = Vector3.new(20,20,19)
Slope3.Position = Vector3.new(478.5477600097656, 102.00000762939453, -399.6143493652344)
Slope3.Rotation = Vector3.new(0,90,0)
Slope3.Shape = Enum.PartType.Wedge
Slope3.Anchored = true
Slope3.Transparency = 0.5
 
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
 
local AntiSign5 = Instance.new("Part", game.Workspace)
AntiSign5.Name = "Anti-Stuck5"
AntiSign5.Anchored = true
AntiSign5.Size = Vector3.new(80, 2, 8)
AntiSign5.Position = Vector3.new(400, 91, -316.5)
AntiSign5.Rotation = Vector3.new(0, 0, 0)
AntiSign5.Transparency = 0.5
 
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
 
local REACH_DIST           = 4.5
local WAYPOINT_TIMEOUT      = 2.5
local STUCK_VEL_THRESHOLD  = 1.5
local STUCK_CHECK_AFTER    = 0.8
local MAX_PATH_ATTEMPTS    = 5
local WALK_HARD_TIMEOUT    = 90
local GLOBAL_STUCK_TIMEOUT = 90
local QUEUE_COOLDOWN       = 0.2
 
local GAP_DEPTH_THRESHOLD  = 5
local MAX_JUMPABLE_GAP     = 4
local PARKOUR_JUMP_BOOST   = true
 
local STUCK_RESET_THRESHOLD = 4
local stuckCheckCount       = 0
 
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
    local rayDir = Vector3.new(0, -(GAP_DEPTH_THRESHOLD + 0.5), 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local char = getChar()
    if char then params.FilterDescendantsInstances = { char } end

    local offsets = {
        Vector3.new(0, 0.5, 0),
        Vector3.new(0.4, 0.5, 0),
        Vector3.new(-0.4, 0.5, 0),
        Vector3.new(0, 0.5, 0.4),
        Vector3.new(0, 0.5, -0.4),
    }
    for _, offset in ipairs(offsets) do
        local result = workspace:Raycast(position + offset, rayDir, params)
        if result then return false end
    end
    return true
end
 
local function getGapInfo(fromPos, toPos)
    local horizontalDist = Vector3.new(toPos.X - fromPos.X, 0, toPos.Z - fromPos.Z).Magnitude
    local midPos = (fromPos + toPos) / 2
 
    local toHasGap  = isGapBelow(toPos)
    local midHasGap = isGapBelow(midPos)
 
    if not toHasGap and not midHasGap then
        return nil
    end
 
    if horizontalDist <= MAX_JUMPABLE_GAP then
        return horizontalDist
    end
 
    return false
end
 
local function makePathFolder(waypoints, eggColor)
    local folder = Instance.new("Folder")
    folder.Name  = "ActivePath"
 
    pcall(function()
        for i, wp in ipairs(waypoints) do
            local p      = Instance.new("Part")
            p.Shape      = Enum.PartType.Ball
            p.Size       = Vector3.new(0.6, 0.6, 0.6)
            p.Position   = wp.Position
            p.Anchored   = true
            p.CanCollide = false
            p.CastShadow = false
            p.Transparency = shared.dev and 0 or 1
            p.Material   = Enum.Material.Neon
            local prevPos = (i > 1) and waypoints[i-1].Position or wp.Position
            local gapInfo = getGapInfo(prevPos, wp.Position)
            if gapInfo then
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
 
local function doGapJump(hum, root, targetPos)
    if not hum or not root then return false end
 
    local dir = (Vector3.new(targetPos.X, root.Position.Y, targetPos.Z) - root.Position).Unit
 
    if PARKOUR_JUMP_BOOST then
        local edgeApproach = root.Position + dir * 1.5
        hum:MoveTo(edgeApproach)
        task.wait(0.08)
    end
 
    doJump(hum)
    hum:MoveTo(targetPos)
 
    local t0 = tick()
    local landed = false
    while tick() - t0 < 2.5 do
        task.wait()
        local state = hum:GetState()
        if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
            landed = true
            break
        end
        hum:MoveTo(targetPos)
    end
 
    return landed
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
 
local function findLadderNear(root)
    local nearby = workspace:GetPartBoundsInBox(
        CFrame.new(root.Position),
        Vector3.new(4, 6, 4)
    )
    for _, part in ipairs(nearby) do
        if part:IsA("BasePart")
            and not part:IsA("TrussPart")
            and string.find(part.Name:lower(), "ladder")
        then
            return part
        end
    end
    return nil
end

local function climbLadder(hum, root, ladder)
    local topY = ladder.Position.Y + ladder.Size.Y / 2 + 3
    local topPos = Vector3.new(ladder.Position.X, topY, ladder.Position.Z)

    local basePos = Vector3.new(ladder.Position.X, root.Position.Y, ladder.Position.Z)
    hum:MoveTo(basePos)
    task.wait(0.3)

    local t0 = tick()
    local lastY = root.Position.Y
    local stuckT = tick()

    while tick() - t0 < 10 do
        task.wait(0.1)
        local state = hum:GetState()

        if root.Position.Y >= topY - 1.5 then
            warn("[EggBot] Ladder climbed successfully")
            return true
        end

        hum:MoveTo(topPos)

        if root.Position.Y > lastY + 0.1 then
            lastY = root.Position.Y
            stuckT = tick()
        elseif tick() - stuckT > 2 then
            warn("[EggBot] Stuck on ladder – giving up climb")
            return false
        end
    end

    return false
end

local function stepToWaypoint(hum, root, wp, prevPos)
    if not hum or not root then return "fail" end
 
    local fromPos = prevPos or root.Position
    local gapInfo = getGapInfo(fromPos, wp.Position)
 
    if gapInfo == false then
        return "gaptoowide"
    elseif gapInfo then
        local success = doGapJump(hum, root, wp.Position)
        if success then
            lastMoveTick = tick()
            stuckCheckCount = 0
            return "reached"
        else
            return "gapfail"
        end
    end
 
    hum:MoveTo(wp.Position)
 
    local result       = nil
    local startT       = tick()
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
            stuckCheckCount = 0
            break
        end
 
        local now = tick()
 
        if now - lastPosTime > PROGRESS_CHECK_INTERVAL then
            local moved = (root.Position - lastPos).Magnitude
 
            if moved < MIN_PROGRESS then
                stuckCheckCount = stuckCheckCount + 1
                warn("[EggBot] Stuck check " .. stuckCheckCount .. "/" .. STUCK_RESET_THRESHOLD)
 
                if stuckCheckCount >= STUCK_RESET_THRESHOLD then
                    warn("[EggBot] Repeatedly stuck – respawning character!")
                    stuckCheckCount = 0
                    moveConn:Disconnect()
                    respawnAndWait()
                    return "stuck_reset"
                end
 
                local lookAheadPos = root.Position + (wp.Position - root.Position).Unit * 3
                local surpriseGap  = getGapInfo(root.Position, lookAheadPos)
 
                local ladder = findLadderNear(root)
                if ladder then
                    warn("[EggBot] Ladder detected - attempting climb")
                    moveConn:Disconnect()
                    local climbed = climbLadder(hum, root, ladder)
                    if climbed then
                        stuckCheckCount = 0
                        result = "reached"
                    else
                        result = "timeout"
                    end
                    break
                elseif surpriseGap and surpriseGap ~= false then
                    local success = doGapJump(hum, root, wp.Position)
                    if success then
                        stuckCheckCount = 0
                        result = "reached"
                        break
                    end
                else
                    local awayDir = (root.Position - wp.Position).Unit
                    local backTarget = root.Position + Vector3.new(awayDir.X * 3, 0, awayDir.Z * 3)
                    
                    hum:MoveTo(backTarget)
                    task.wait(0.4)
                    
                    doJump(hum)
                    task.wait(0.05)
                    
                    hum:MoveTo(wp.Position)
                    warn("[EggBot] Resuming path with Forced Jump")
                end
            else
                stuckCheckCount = 0
            end
 
            lastPos     = root.Position
            lastPosTime = now
        end
    end
 
    moveConn:Disconnect()
    return result
end
 
local function rescanWorkspace()
    for _, v in ipairs(workspace:GetChildren()) do
        checkEgg(v)
    end
end
 
local function pathHasGap(waypoints)
    for i = 2, #waypoints do
        local prevPos = waypoints[i-1].Position
        local curPos  = waypoints[i].Position
        if getGapInfo(prevPos, curPos) ~= nil then
            return true
        end
    end
    return false
end

local function computeSafePath(fromPos, toPos, extraRadius)
    local params = {
        AgentHeight     = PATH_PARAMS.AgentHeight,
        AgentRadius     = PATH_PARAMS.AgentRadius + (extraRadius or 0),
        AgentCanJump    = PATH_PARAMS.AgentCanJump,
        AgentJumpHeight = PATH_PARAMS.AgentJumpHeight,
        WaypointSpacing = PATH_PARAMS.WaypointSpacing,
    }
    local path = PathfindingService:CreatePath(params)
    local ok = pcall(function() path:ComputeAsync(fromPos, toPos) end)
    if not ok or path.Status ~= Enum.PathStatus.Success then return nil end
    return path
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

        local waypoints = nil
        for _, extraRadius in ipairs({0, 2, 4, 6, 8}) do
            local candidate = computeSafePath(root.Position, targetPos, extraRadius)
            if candidate then
                local wps = candidate:GetWaypoints()
                if not pathHasGap(wps) then
                    waypoints = wps
                    if extraRadius > 0 then
                        warn("[EggBot] Gap-free path found with radius +" .. extraRadius)
                    end
                    break
                end
            end
        end

        if not waypoints then
            warn("[EggBot] No gap-free path found on attempt " .. attempt .. " - retrying")
            task.wait(0.2)
            continue
        end

        local pathFolder, cleanup = makePathFolder(waypoints, eggColor)
        local pathBroken = false

        for i, wp in ipairs(waypoints) do
            if not farmEnabled() or not isAlive(targetInstance) then
                pathBroken = true
                break
            end

            local prevPos = (i > 1) and waypoints[i-1].Position or root.Position

            if wp.Action == Enum.PathWaypointAction.Jump then
                doJump(hum)
            end

            local stepResult = stepToWaypoint(hum, root, wp, prevPos)

            if stepResult == "stuck_reset" then
                warn("[EggBot] Respawned mid-path - re-queuing egg")
                pathBroken = true
                break
            elseif stepResult == "gaptoowide" or stepResult == "gapfail" then
                warn("[EggBot] Unexpected gap mid-walk at waypoint " .. i .. " - recomputing")
                pathBroken = true
                break
            elseif stepResult ~= "reached" then
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
                warn("[EggBot] Resetting before next egg: " .. data.id)
                respawnAndWait()
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

        local hasPrompt = false
        for _, d in ipairs(v:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                hasPrompt = true
                break
            end
        end
        if not hasPrompt then
            warn("[EggBot] Skipping " .. name .. " – no ProximityPrompt found")
            return
        end

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
print("[EggBot] Bot Loaded - v2.0.0")
