local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players            = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local HttpService        = game:GetService("HttpService")
local VirtualUser        = game:GetService("VirtualUser")

local Options = Library.Options
local Toggles = Library.Toggles
local Camera  = workspace.CurrentCamera
local player  = Players.LocalPlayer
local WS      = workspace

local webhook = {
	Settings = {
		NormalEggs    = false,
		ImportantEggs = true,
		Webhook       = "",
	}
}

local EggsThingFrame
do
	local targetPos = UDim2.new(0, 10, 0.894999981, -10)
	for _, v in ipairs(player.PlayerGui:WaitForChild("MainInterface"):GetChildren()) do
		if v.Position == targetPos then
			EggsThingFrame = v
			break
		end
	end
end

local REACH_DIST            = 4.5
local WAYPOINT_TIMEOUT      = 2.5
local MAX_PATH_ATTEMPTS     = 5
local WALK_HARD_TIMEOUT     = 90
local QUEUE_COOLDOWN        = 0.2
local EGG_GIVE_UP_TIMEOUT   = 60
local GAP_DEPTH_THRESHOLD   = 5
local MAX_JUMPABLE_GAP      = 4
local PARKOUR_JUMP_BOOST    = true
local STUCK_RESET_THRESHOLD = 4
local PROGRESS_INTERVAL     = 0.6
local MIN_PROGRESS          = 0.8
local RAY_DOWN_DIR          = Vector3.new(0, -(GAP_DEPTH_THRESHOLD + 0.5), 0)

local CLEARANCE_HEIGHT      = 8
local RAY_UP_DIR            = Vector3.new(0, CLEARANCE_HEIGHT, 0)

local CLEARANCE_CHECK_DIST  = 6

local GAP_OFFSETS = {
	Vector3.new(0,    0.5, 0),
	Vector3.new(0.4,  0.5, 0),
	Vector3.new(-0.4, 0.5, 0),
	Vector3.new(0,    0.5,  0.4),
	Vector3.new(0,    0.5, -0.4),
}

local _rayParams = RaycastParams.new()
_rayParams.FilterType = Enum.RaycastFilterType.Exclude

local _activePathFolder = nil

local function refreshRayParams()
	local c = player.Character
	local excludes = c and { c } or {}
	if _activePathFolder and _activePathFolder.Parent then
		excludes[#excludes + 1] = _activePathFolder
	end
	_rayParams.FilterDescendantsInstances = excludes
end

local EGG_COLORS = {
	[1] = Color3.fromRGB(255, 255, 255),
	[2] = Color3.fromRGB(0,   255,   0),
	[3] = Color3.fromRGB(0,   170, 255),
	[4] = Color3.fromRGB(170,   0, 255),
	[5] = Color3.fromRGB(255, 170,   0),
	[6] = Color3.fromRGB(255,   0,   0),
}
local JUMP_COLOR     = Color3.fromRGB(255, 100, 0)
local PRIORITY_COLOR = Color3.fromRGB(255,   0, 0)
local POTION_COLOR   = Color3.fromRGB(170,   0, 255)
local DEFAULT_COLOR  = Color3.new(1, 1, 1)
local GAP_COLOR      = Color3.fromRGB(255,  50, 50)

local PRIORITY_SET = {
	andromeda_egg      = true, angelic_egg = true, blooming_egg       = true,
	dreamer_egg        = true, egg_v2      = true, forest_egg         = true,
	hatch_egg          = true, royal_egg   = true, the_egg_of_the_sky = true,
}

local SpecialEggs = {
	"andromeda_egg", "angelic_egg", "dreamer_egg",
	"hatch_egg", "egg_v2", "royal_egg",
	"blooming_egg", "forest_egg", "the_egg_of_the_sky",
}
local SPECIAL_SET = {}
for _, name in ipairs(SpecialEggs) do SPECIAL_SET[name] = true end

local NormalEggs = {
	point_egg_         = { min = 1, max = 6 },
	random_potion_egg_ = { min = 1, max = 2 },
}

local isWalking     = false
local eggQueue      = {}
local queuedIds     = {}
local lastMoveTick  = tick()
local stuckCheckCount = 0

local function farmEnabled() return Toggles.Macro        and Toggles.Macro.Value end
local function getSpacing()  return (Options.SpacingSlider and Options.SpacingSlider.Value) or 2 end
local function isDevMode()   return Toggles.DeveloperMode and Toggles.DeveloperMode.Value end
local function espEnabled()  return Toggles.ESP           and Toggles.ESP.Value end

local function getChar()  return player.Character end
local function getHum(c)  return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(c) return c and c:FindFirstChild("HumanoidRootPart") end

local function isAlive(inst)
	return inst ~= nil and inst.Parent ~= nil
end

local function resolvePos(inst)
	if not isAlive(inst) then return nil end
	local ok, val = pcall(function()
		if inst:IsA("BasePart") then return inst.Position end
		if inst:IsA("Model") then
			if inst.PrimaryPart then return inst.PrimaryPart.Position end
			local bp = inst:FindFirstChildWhichIsA("BasePart", true)
			return bp and bp.Position
		end
	end)
	return ok and val or nil
end

local function sendWebhook(data)
	local url = webhook.Settings.Webhook
	if not url or url == "" then return end
	task.spawn(function()
		local ok, resp = pcall(request, {
			Url     = url,
			Method  = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body    = HttpService:JSONEncode(data),
		})
		if ok then
			print(resp.StatusCode == 204 or resp.StatusCode == 200
				and "[Shrimp] Webhook OK"
				or  "[Shrimp] Webhook failed: " .. tostring(resp.StatusCode))
		else
			print("[Shrimp] Webhook error: " .. tostring(resp))
		end
	end)
end

local idled = player.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
	task.wait()
	VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
end)

local Window = Library:CreateWindow({
	Title            = "Shrimp's Stuff",
	Footer           = "sol's rng - v2.1.0 - " .. game.GameId .. " - " .. player.Name,
	Icon             = 6171138225,
	NotifySide       = "Left",
	ShowCustomCursor = true,
})

local function isGapBelow(position)
	for i = 1, #GAP_OFFSETS do
		if WS:Raycast(position + GAP_OFFSETS[i], RAY_DOWN_DIR, _rayParams) then
			return false
		end
	end
	return true
end

local function getGapInfo(fromPos, toPos)
	local dx = toPos.X - fromPos.X
	local dz = toPos.Z - fromPos.Z
	local horizontalDist = math.sqrt(dx * dx + dz * dz)
	local midPos = (fromPos + toPos) * 0.5

	if not isGapBelow(toPos) and not isGapBelow(midPos) then return nil end
	if horizontalDist <= MAX_JUMPABLE_GAP then return horizontalDist end
	return false
end

local function hasClearance(pos)
	local origin = Vector3.new(pos.X, pos.Y + 0.2, pos.Z)
	return WS:Raycast(origin, RAY_UP_DIR, _rayParams) == nil
end

local function pathHasOverhang(waypoints)
	for i = 1, #waypoints do
		if not hasClearance(waypoints[i].Position) then
			return true
		end
		if i < #waypoints then
			local mid = (waypoints[i].Position + waypoints[i+1].Position) * 0.5
			if not hasClearance(mid) then
				return true
			end
		end
	end
	return false
end

local function makePathFolder(waypoints, eggColor)
	if _activePathFolder and _activePathFolder.Parent then
		_activePathFolder:Destroy()
		_activePathFolder = nil
	end

	if not isDevMode() then
		refreshRayParams()
		return nil, function() end
	end

	local folder = Instance.new("Folder")
	folder.Name = "ActivePath"

	for i, wp in ipairs(waypoints) do
		local p          = Instance.new("Part")
		p.Shape          = Enum.PartType.Ball
		p.Size           = Vector3.new(0.6, 0.6, 0.6)
		p.Position       = wp.Position
		p.Anchored       = true
		p.CanCollide     = false
		p.CanQuery       = false
		p.CanTouch       = false
		p.CastShadow     = false
		p.Transparency   = 0
		p.Material       = Enum.Material.Neon
		local prevPos    = (i > 1) and waypoints[i-1].Position or wp.Position
		local gapInfo    = getGapInfo(prevPos, wp.Position)
		p.Color = gapInfo and GAP_COLOR
			or (wp.Action == Enum.PathWaypointAction.Jump and JUMP_COLOR or eggColor)
		p.Parent = folder
	end

	folder.Parent = WS
	_activePathFolder = folder
	refreshRayParams()

	return folder, function()
		if folder.Parent then
			folder:Destroy()
		end
		if _activePathFolder == folder then
			_activePathFolder = nil
			refreshRayParams()
		end
	end
end

local function doJump(hum)
	local state = hum:GetState()
	if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

local function doGapJump(hum, root, targetPos)
	if PARKOUR_JUMP_BOOST then
		local rootPos = root.Position
		local dir = (Vector3.new(targetPos.X, rootPos.Y, targetPos.Z) - rootPos).Unit
		hum:MoveTo(rootPos + dir * 1.5)
		task.wait(0.08)
	end
	doJump(hum)
	hum:MoveTo(targetPos)

	local t0 = tick()
	while tick() - t0 < 2.5 do
		task.wait()
		local state = hum:GetState()
		if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
			return true
		end
		hum:MoveTo(targetPos)
	end
	return false
end

local function respawnAndWait()
	local hum = getHum(getChar())
	if hum then hum.Health = 0 end
	task.wait(0.5)
	local t0 = tick()
	while tick() - t0 < 10 do
		local c = getChar()
		local h = getHum(c)
		local r = getRoot(c)
		if c and h and r and h.Health > 0 then break end
		task.wait(0.2)
	end
	refreshRayParams()
	task.wait(0.3)
end

local function findLadderNear(root)
	local nearby = WS:GetPartBoundsInBox(CFrame.new(root.Position), Vector3.new(4, 6, 4))
	for _, part in ipairs(nearby) do
		if part:IsA("BasePart")
			and not part:IsA("TrussPart")
			and string.find(part.Name:lower(), "ladder", 1, true)
		then
			return part
		end
	end
	return nil
end

local function climbLadder(hum, root, ladder)
	local topY   = ladder.Position.Y + ladder.Size.Y * 0.5 + 3
	local topPos = Vector3.new(ladder.Position.X, topY, ladder.Position.Z)
	hum:MoveTo(Vector3.new(ladder.Position.X, root.Position.Y, ladder.Position.Z))
	task.wait(0.3)

	local t0     = tick()
	local lastY  = root.Position.Y
	local stuckT = tick()

	while tick() - t0 < 10 do
		task.wait(0.1)
		local curY = root.Position.Y
		if curY >= topY - 1.5 then return true end
		hum:MoveTo(topPos)
		if curY > lastY + 0.1 then
			lastY  = curY
			stuckT = tick()
		elseif tick() - stuckT > 2 then
			return false
		end
	end
	return false
end

local function stepToWaypoint(hum, root, wp, prevPos, eggStartTime)
	if eggStartTime and tick() - eggStartTime > EGG_GIVE_UP_TIMEOUT then
		return "giveup"
	end

	local gapInfo = getGapInfo(prevPos or root.Position, wp.Position)
	if gapInfo == false then return "gaptoowide" end
	if gapInfo then
		if doGapJump(hum, root, wp.Position) then
			lastMoveTick    = tick()
			stuckCheckCount = 0
			return "reached"
		end
		return "gapfail"
	end

	hum:MoveTo(wp.Position)

	local result      = nil
	local startT      = tick()
	local lastPos     = root.Position
	local lastPosTime = startT
	local wpPos       = wp.Position

	local moveConn = hum.MoveToFinished:Connect(function(reached)
		if result == nil then
			result = reached and "reached" or "timeout"
		end
	end)

	while result == nil do
		task.wait()

		if not farmEnabled()                                              then result = "stopped" break end
		if tick() - startT > WAYPOINT_TIMEOUT                            then result = "timeout"  break end
		if eggStartTime and tick() - eggStartTime > EGG_GIVE_UP_TIMEOUT  then result = "giveup"   break end

		local rootPos = root.Position
		if (rootPos - wpPos).Magnitude < REACH_DIST then
			result          = "reached"
			lastMoveTick    = tick()
			stuckCheckCount = 0
			break
		end

		if (rootPos - wpPos).Magnitude < CLEARANCE_CHECK_DIST and not hasClearance(rootPos) then
			result = "overhang"
			break
		end

		local now = tick()
		if now - lastPosTime >= PROGRESS_INTERVAL then
			local moved = (rootPos - lastPos).Magnitude

			if moved < MIN_PROGRESS then
				stuckCheckCount += 1

				if stuckCheckCount >= STUCK_RESET_THRESHOLD then
					stuckCheckCount = 0
					moveConn:Disconnect()
					respawnAndWait()
					return "stuck_reset"
				end

				local ladder = findLadderNear(root)
				if ladder then
					moveConn:Disconnect()
					local climbed = climbLadder(hum, root, ladder)
					stuckCheckCount = 0
					return climbed and "reached" or "timeout"
				end

				local lookAhead   = rootPos + (wpPos - rootPos).Unit * 3
				local surpriseGap = getGapInfo(rootPos, lookAhead)
				if surpriseGap and surpriseGap ~= false then
					if doGapJump(hum, root, wpPos) then
						stuckCheckCount = 0
						result = "reached"
						break
					end
				else
					local awayDir = (rootPos - wpPos).Unit
					hum:MoveTo(rootPos + Vector3.new(awayDir.X * 3, 0, awayDir.Z * 3))
					task.wait(0.4)
					doJump(hum)
					task.wait(0.05)
					hum:MoveTo(wpPos)
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

local function pathHasGap(waypoints)
	for i = 2, #waypoints do
		if getGapInfo(waypoints[i-1].Position, waypoints[i].Position) ~= nil then
			return true
		end
	end
	return false
end

local function computeSafePath(fromPos, toPos, extraRadius, extraHeight)
	local path = PathfindingService:CreatePath({
		AgentHeight     = 6 + (extraHeight or 0),
		AgentRadius     = 2 + (extraRadius or 0),
		AgentCanJump    = true,
		AgentJumpHeight = 25,
		WaypointSpacing = getSpacing(),
	})
	local ok = pcall(function() path:ComputeAsync(fromPos, toPos) end)
	if not ok or path.Status ~= Enum.PathStatus.Success then return nil end
	return path
end

local _lastRescan = 0
local checkEgg

local function rescanWorkspace()
	local now = tick()
	if now - _lastRescan < 1 then return end
	_lastRescan = now
	for _, v in ipairs(WS:GetChildren()) do
		checkEgg(v)
	end
end

local PATH_ATTEMPTS = {
	{0, 0}, {2, 0}, {4, 0},
	{0, 4}, {2, 4}, {4, 4},
	{0, 8}, {4, 8},
}

local function walkToEgg(targetInstance, eggColor)
	local char = getChar()
	local hum  = getHum(char)
	local root = getRoot(char)
	if not hum or not root then return "fail" end

	local eggStartTime = tick()

	for attempt = 1, MAX_PATH_ATTEMPTS do
		if not farmEnabled() then return "stopped" end
		if tick() - eggStartTime > EGG_GIVE_UP_TIMEOUT then
			print("[Shrimp] 60 s timeout, skipping: " .. targetInstance.Name)
			respawnAndWait()
			return "giveup"
		end

		local targetPos = resolvePos(targetInstance)
		if not targetPos then return "done" end

		char = getChar()
		hum  = getHum(char)
		root = getRoot(char)
		if not hum or not root then return "fail" end

		local waypoints
		for _, attempt in ipairs(PATH_ATTEMPTS) do
			local candidate = computeSafePath(root.Position, targetPos, attempt[1], attempt[2])
			if candidate then
				local wps = candidate:GetWaypoints()
				if not pathHasGap(wps) and not pathHasOverhang(wps) then
					waypoints = wps
					break
				end
			end
		end

		if not waypoints then task.wait(0.2) continue end

		local _, cleanup = makePathFolder(waypoints, eggColor)
		local pathBroken = false
		local givenUp    = false

		for i, wp in ipairs(waypoints) do
			if not farmEnabled() or not isAlive(targetInstance) then
				pathBroken = true break
			end

			local prevPos = (i > 1) and waypoints[i-1].Position or root.Position
			if wp.Action == Enum.PathWaypointAction.Jump then doJump(hum) end

			local stepResult = stepToWaypoint(hum, root, wp, prevPos, eggStartTime)

			if stepResult == "giveup" then
				givenUp = true pathBroken = true break
			elseif stepResult == "overhang" then
				print("[Shrimp] Overhang detected mid-path, retrying safer route")
				pathBroken = true break
			elseif stepResult ~= "reached" then
				pathBroken = true break
			end
		end

		cleanup()

		if givenUp then
			print("[Shrimp] Gave up mid-path: " .. targetInstance.Name)
			respawnAndWait()
			return "giveup"
		end
		if not farmEnabled() then return "stopped" end
		if pathBroken then task.wait(0.1) continue end

		if isAlive(targetInstance) then
			for _, v in ipairs(targetInstance:GetDescendants()) do
				if v:IsA("ProximityPrompt") then
					task.wait(0.5)
					fireproximityprompt(v)

					if webhook.Settings.NormalEggs or webhook.Settings.ImportantEggs then
						local isSpecial = SPECIAL_SET[targetInstance.Name]
						local data
						if isSpecial then
							data = {
								content = nil,
								embeds  = {{
									title       = "Aura Egg Collected!",
									description = "You've collected an AURA egg!",
									color       = 5814783,
									footer      = { text = "Egg: " .. targetInstance.Name },
								}},
							}
						else
							local pts = EggsThingFrame
								and EggsThingFrame.TextLabel
								and EggsThingFrame.TextLabel.Text or "?"
							data = {
								content = nil,
								embeds  = {{
									title       = "Egg Collected!",
									description = "You've collected an egg!",
									color       = 5814783,
									footer      = { text = "You now have " .. pts .. " egg points." },
								}},
							}
						end
						sendWebhook(data)
					end
					break
				end
			end
		end

		task.wait(0.1)
		rescanWorkspace()
		return "done"
	end

	print("[Shrimp] Exhausted attempts, resetting: " .. targetInstance.Name)
	respawnAndWait()
	return "fail"
end

local function pruneQueue()
	local alive = {}
	for _, e in ipairs(eggQueue) do
		if isAlive(e.target) then
			alive[#alive + 1] = e
		else
			queuedIds[e.id] = nil
		end
	end
	eggQueue = alive
end

local function releaseWalking() isWalking = false end

local function processQueue()
	if not farmEnabled() or isWalking or #eggQueue == 0 then return end
	isWalking = true

	task.spawn(function()
		local hardTimer = task.delay(WALK_HARD_TIMEOUT, releaseWalking)
		pruneQueue()
		local data = table.remove(eggQueue, 1)
		if data and queuedIds[data.id] then
			queuedIds[data.id] = nil
			if isAlive(data.target) and farmEnabled() then
				respawnAndWait()
				walkToEgg(data.target, data.color)
			end
		end
		task.cancel(hardTimer)
		releaseWalking()
		if farmEnabled() then
			task.wait(QUEUE_COOLDOWN)
			processQueue()
		end
	end)
end

local _checkInFlight = {}

checkEgg = function(v)
	if not v or _checkInFlight[v] then return end
	if not (v:IsA("Model") or v:IsA("BasePart")) then return end

	_checkInFlight[v] = true
	task.spawn(function()
		task.wait(0.1)
		_checkInFlight[v] = nil

		if not isAlive(v) then return end

		local name = v.Name
		local uid  = name .. tostring(v)
		if queuedIds[uid] then return end

		if SPECIAL_SET[name] then
			sendWebhook({
				content = "@everyone",
				embeds  = {{
					title       = "⚠️ Aura Egg Found!",
					description = "An **aura egg** has spawned!",
					color       = 16711680,
					footer      = { text = "Egg: " .. name .. " | Attempting to collect!" },
				}},
			})
		end

		local eggNum     = tonumber(string.match(name, "egg_(%d+)$"))
		local isPriority = PRIORITY_SET[name] == true
		local isPotion   = string.find(name, "potion", 1, true) ~= nil
		local eggColor

		if isPriority   then eggColor = PRIORITY_COLOR
		elseif isPotion then eggColor = POTION_COLOR
		elseif eggNum   then eggColor = EGG_COLORS[eggNum] or DEFAULT_COLOR
		else return end

		for _, d in ipairs(v:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				queuedIds[uid] = true
				table.insert(eggQueue, isPriority and 1 or (#eggQueue + 1),
					{ target = v, color = eggColor, id = uid })
				if farmEnabled() then processQueue() end
				return
			end
		end
	end)
end

local function Board(v)
	if v:FindFirstChild("_BillboardGui") then return end

	local gui            = Instance.new("BillboardGui")
	gui.Active           = true
	gui.AlwaysOnTop      = true
	gui.ClipsDescendants = true
	gui.LightInfluence   = 1
	gui.Size             = UDim2.new(0, 200, 0, 50)
	gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	gui.Name             = "_BillboardGui"
	gui.Parent           = v

	local lbl                  = Instance.new("TextLabel", gui)
	lbl.Font                   = Enum.Font.Unknown
	lbl.Text                   = v.Name
	lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	lbl.TextScaled             = true
	lbl.TextSize               = 14
	lbl.TextWrapped            = true
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel        = 0
	lbl.Size                   = UDim2.new(1, 0, 1, 0)

	Instance.new("UIStroke", lbl).Thickness = 2
end

local function highlightEgg(target)
	local existing = target:FindFirstChild("Highlight")
	if existing then existing:Destroy() end

	local hl               = Instance.new("Highlight", target)
	hl.FillColor           = SPECIAL_SET[target.Name] and Color3.fromRGB(255, 0, 255) or Color3.fromRGB(0, 255, 255)
	hl.FillTransparency    = 0.5
	hl.OutlineTransparency = 0.5
	hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
	Board(target)

	local part = target:IsA("MeshPart") and target
		or (target:IsA("Model") and (
			target:FindFirstChildWhichIsA("MeshPart") or
			target:FindFirstChildWhichIsA("BasePart")))
	if part then part.Size = Vector3.new(15, 15, 15) end
end

local function Highlight(v)
	if not espEnabled() then return end
	if SPECIAL_SET[v.Name] then highlightEgg(v) return end

	for prefix, range in pairs(NormalEggs) do
		local num = tonumber(string.match(v.Name, "^" .. prefix .. "(%d+)$"))
		if num and num >= range.min and num <= range.max then
			highlightEgg(v) return
		end
	end
end

local Tabs = {
	Main            = Window:AddTab("Main",        "user"),
	Webhook         = Window:AddTab("Webhook",     "user"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Main", "boxes")

LeftGroupBox:AddToggle("Macro", {
	Text     = "Egg Macro",
	Default  = false,
	Callback = function(Value)
		if Value then
			lastMoveTick = tick()
			refreshRayParams()
			for _, v in ipairs(WS:GetChildren()) do checkEgg(v) end
			processQueue()
		else
			isWalking = false
		end
	end,
})

LeftGroupBox:AddSlider("SpacingSlider", {
	Text     = "Spacing between waypoints",
	Default  = 2, Min = 1, Max = 5, Rounding = 0.5,
})

LeftGroupBox:AddToggle("DeveloperMode", {
	Text    = "Developer Mode",
	Default = false,
})

LeftGroupBox:AddToggle("ESP", {
	Text     = "Egg ESP",
	Default  = false,
	Callback = function(Value)
		if Value then
			for _, v in ipairs(WS:GetChildren()) do Highlight(v) end
		else
			for _, v in ipairs(WS:GetDescendants()) do
				if v.Name == "Highlight" or v.Name == "_BillboardGui" then
					v:Destroy()
				end
			end
		end
	end,
})

LeftGroupBox:AddButton({
	Text = "Clear ESP",
	Func = function()
		for _, v in ipairs(WS:GetDescendants()) do
			if v.Name == "Highlight" or v.Name == "_BillboardGui" then
				v:Destroy()
			end
		end
	end,
})

local Hello = Tabs.Webhook:AddLeftGroupbox("Webhook", "boxes")

Hello:AddInput("WebhookURL", {
	Default          = "",
	Numeric          = false,
	Finished         = false,
	ClearTextOnFocus = false,
	Text             = "Webhook URL",
	Placeholder      = "https://discord.com/api/webhooks/...",
	Callback         = function(Value) webhook.Settings.Webhook = Value end,
})

Hello:AddButton({
	Text = "Test Webhook",
	Func = function()
		sendWebhook({ content = "✅ Shrimp's Stuff webhook test!" })
	end,
})

Hello:AddToggle("Normal Eggs", {
	Text     = "Notify Normal Eggs",
	Default  = false,
	Callback = function(Value) webhook.Settings.NormalEggs = Value end,
})

Hello:AddToggle("Aura Eggs", {
	Text     = "Notify Aura Eggs",
	Default  = false,
	Callback = function(Value) webhook.Settings.ImportantEggs = Value end,
})

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default  = Library.KeybindFrame.Visible,
	Text     = "Open Keybind Menu",
	Callback = function(value) Library.KeybindFrame.Visible = value end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text     = "Custom Cursor",
	Default  = true,
	Callback = function(Value) Library.ShowCustomCursor = Value end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values   = { "Left", "Right" },
	Default  = "Right",
	Text     = "Notification Side",
	Callback = function(Value) Library:SetNotifySide(Value) end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values   = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default  = "100%",
	Text     = "DPI Scale",
	Callback = function(Value)
		Library:SetDPIScale(tonumber(Value:gsub("%%", "")))
	end,
})
MenuGroup:AddSlider("UICornerSlider", {
	Text     = "Corner Radius",
	Default  = Library.CornerRadius,
	Min      = 0, Max = 20, Rounding = 0,
	Callback = function(value) Window:SetCornerRadius(value) end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift", NoUI = true, Text = "Menu keybind",
})
MenuGroup:AddButton("Unload", function()
	Library:Unload()
	idled:Disconnect()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Shrimp's Stuff")
SaveManager:SetFolder("Shrimp's Stuff/sol's rng")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

WS.ChildAdded:Connect(function(v)
	Highlight(v)
	checkEgg(v)
end)

refreshRayParams()
player.CharacterAdded:Connect(refreshRayParams)

print("SHRIMP'S STUFF LOADED!")
