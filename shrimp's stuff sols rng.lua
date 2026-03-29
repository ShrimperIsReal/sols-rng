local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Camera = workspace.CurrentCamera

local webhook = {
	Enabled = true,
	Settings = {
		NormalEggs = false,
		ImportantEggs = true,
		Webhook = ""
	}
}

local EggsThingFrame

for _,v in pairs(game.Players.LocalPlayer.PlayerGui:WaitForChild("MainInterface"):GetChildren()) do
	if v.Position == UDim2.new(0, 10, 0.894999981, -10) then
		EggsThingFrame = v
	end
end

local function sendWebhook(data)
	local HttpService = game:GetService("HttpService")
	local webhookUrl = webhook.Settings.Webhook

	local response = request({
		Url = webhookUrl,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode(data)
	})

	if response.StatusCode == 204 or response.StatusCode == 200 then
		print("Webhook sent successfully!")
	else
		print("Failed to send. Status code: " .. tostring(response.StatusCode))
	end
	
end


local idled = game.Players.LocalPlayer.Idled:Connect(function()
	local virtusr = game:GetService("VirtualUser")
	virtusr:Button2Down(Vector2.new(0, 0), Camera.CFrame)
	task.wait()
	virtusr:Button2Up(Vector2.new(0, 0), Camera.CFrame)
end)

local Window = Library:CreateWindow({
	Title = "Shrimp's Stuff",
	Footer = "sol's rng - version: 2.0.0 - "..game.GameId.." - User: "..game.Players.LocalPlayer.Name,
	Icon = 6171138225,
	NotifySide = "Left",
	ShowCustomCursor = true,
})

if workspace:FindFirstChild("SlopeSoNoStuckyPoo") then
	task.spawn(function()
		workspace:FindFirstChild("SlopeSoNoStuckyPoo"):Destroy()
		workspace:FindFirstChild("SlopeSoNoStuckyPoo2"):Destroy()
		workspace:FindFirstChild("SlopeSoNoStuckyPoo3"):Destroy()
		workspace:FindFirstChild("Anti-Stuck1"):Destroy()
		workspace:FindFirstChild("Anti-Stuck2"):Destroy()
		workspace:FindFirstChild("Anti-Stuck3"):Destroy()
		workspace:FindFirstChild("Anti-Stuck4"):Destroy()
		workspace:FindFirstChild("Anti-Stuck5"):Destroy()
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

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function farmEnabled() return Toggles.Macro and Toggles.Macro.Value end
local function getSpacing() return Options.SpacingSlider and Options.SpacingSlider.Value or 2 end
local function isDevMode() return Toggles.DeveloperMode and Toggles.DeveloperMode.Value end
local function espEnabled() return Toggles.ESP and Toggles.ESP.Value end

local REACH_DIST = 4.5
local WAYPOINT_TIMEOUT = 2.5
local STUCK_VEL_THRESHOLD = 1.5
local STUCK_CHECK_AFTER = 0.8
local MAX_PATH_ATTEMPTS = 5
local WALK_HARD_TIMEOUT = 90
local GLOBAL_STUCK_TIMEOUT = 90
local QUEUE_COOLDOWN = 0.2

local GAP_DEPTH_THRESHOLD = 5
local MAX_JUMPABLE_GAP = 4
local PARKOUR_JUMP_BOOST = true

local STUCK_RESET_THRESHOLD = 4
local stuckCheckCount = 0

local EGG_COLORS = {
	[1] = Color3.fromRGB(255, 255, 255),
	[2] = Color3.fromRGB(0, 255, 0),
	[3] = Color3.fromRGB(0, 170, 255),
	[4] = Color3.fromRGB(170, 0, 255),
	[5] = Color3.fromRGB(255, 170, 0),
	[6] = Color3.fromRGB(255, 0, 0),
}
local JUMP_COLOR = Color3.fromRGB(255, 100, 0)
local PRIORITY_COLOR = Color3.fromRGB(255, 0, 0)
local POTION_COLOR = Color3.fromRGB(170, 0, 255)
local DEFAULT_COLOR = Color3.new(1, 1, 1)
local GAP_COLOR = Color3.fromRGB(255, 50, 50)

local PRIORITY_SET = {
	andromeda_egg = true, angelic_egg = true, blooming_egg = true,
	dreamer_egg = true, egg_v2 = true, forest_egg = true,
	hatch_egg = true, royal_egg = true, the_egg_of_the_sky = true,
}

local NormalEggs = {
	point_egg_ = { min = 1, max = 6 },
	random_potion_egg_ = { min = 1, max = 2 },
}

local SpecialEggs = {
	"andromeda_egg", "angelic_egg", "dreamer_egg",
	"hatch_egg", "egg_v2", "royal_egg",
	"blooming_egg", "forest_egg", "the_egg_of_the_sky"
}

local isWalking = false
local eggQueue = {}
local queuedIds = {}
local lastMoveTick = tick()

local function isAlive(inst)
	return inst ~= nil and inst.Parent ~= nil
end

local function safeGet(fn)
	local ok, val = pcall(fn)
	return ok and val or nil
end

local function getChar() return player.Character end
local function getHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
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

	local toHasGap = isGapBelow(toPos)
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
	folder.Name = "ActivePath"

	pcall(function()
		for i, wp in ipairs(waypoints) do
			local p = Instance.new("Part")
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.new(0.6, 0.6, 0.6)
			p.Position = wp.Position
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
			p.Transparency = isDevMode() and 0 or 1
			p.Material = Enum.Material.Neon
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
	local t0 = tick()
	while tick() - t0 < timeout do
		local c = getChar()
		local hum = getHum(c)
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
			return true
		end

		hum:MoveTo(topPos)

		if root.Position.Y > lastY + 0.1 then
			lastY = root.Position.Y
			stuckT = tick()
		elseif tick() - stuckT > 2 then
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

	local result = nil
	local startT = tick()
	local lastPos = root.Position
	local lastPosTime = tick()
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

				if stuckCheckCount >= STUCK_RESET_THRESHOLD then
					stuckCheckCount = 0
					moveConn:Disconnect()
					respawnAndWait()
					return "stuck_reset"
				end

				local lookAheadPos = root.Position + (wp.Position - root.Position).Unit * 3
				local surpriseGap = getGapInfo(root.Position, lookAheadPos)

				local ladder = findLadderNear(root)
				if ladder then
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
				end
			else
				stuckCheckCount = 0
			end

			lastPos = root.Position
			lastPosTime = now
		end
	end

	moveConn:Disconnect()
	return result
end

local checkEgg

local function rescanWorkspace()
	for _, v in ipairs(workspace:GetChildren()) do
		checkEgg(v)
	end
end

local function pathHasGap(waypoints)
	for i = 2, #waypoints do
		local prevPos = waypoints[i-1].Position
		local curPos = waypoints[i].Position
		if getGapInfo(prevPos, curPos) ~= nil then
			return true
		end
	end
	return false
end

local function computeSafePath(fromPos, toPos, extraRadius)
	local params = {
		AgentHeight = 1.5,
		AgentRadius = 2 + (extraRadius or 0),
		AgentCanJump = true,
		AgentJumpHeight = 25,
		WaypointSpacing = getSpacing(),
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
					break
				end
			end
		end

		if not waypoints then
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
				pathBroken = true
				break
			elseif stepResult == "gaptoowide" or stepResult == "gapfail" then
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
					
					local data
					
					if table.find(SpecialEggs, targetInstance.Name) then
						data = {
							["content"] = nil,
							["embeds"] = {
								{
									["title"] = "Aura Egg Collected!",
									["description"] = "You've collected an AURA egg!",
									["color"] = 5814783,
									["footer"] = {
										"You now have "..targetInstance.Name.. " in your inventory!"
									}
								}
							}
						}
					else
						data = {
							["content"] = nil,
							["embeds"] = {
								{
									["title"] = "Egg Collected!",
									["description"] = "You've collected an egg!",
									["color"] = 5814783,
									["footer"] = {
										["text"] = "You now have " .. EggsThingFrame.TextLabel.Text .. " egg points in your stats."
									}
								}
							}
						}
					end
					
					if webhook.Settings.NormalEggs or webhook.Settings.SpecialEggs then
						sendWebhook(data)
					end
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
				respawnAndWait()
				walkToEgg(data.target, data.color)
			end
		end
		task.cancel(hardTimer)
		releaseWalking()
		if farmEnabled() then task.wait(QUEUE_COOLDOWN) processQueue() end
	end)
end

checkEgg = function(v)
	task.spawn(function()
		if not v or not (v:IsA("Model") or v:IsA("BasePart")) then return end
		task.wait(0.1)
		if not isAlive(v) then return end
		if table.find(SpecialEggs, v.Name) then
			local data = {
				["content"] = "@everyone",
				["embeds"] = {
					["title"] = "⚠️ Aura Egg Found!",
					["description"] = "An **aura egg** has spawned!",
					["color"] = 16711680,
					["footer"] = {
						"Egg: ".. v.Name .. " | We will attempt to collect it for you!"
					}
				}
			}
			sendWebhook()
		end
		local name = v.Name
		local uid = name .. tostring(v)
		if queuedIds[uid] then return end

		local eggNum = tonumber(string.match(name, "egg_(%d+)$"))
		local isPriority = PRIORITY_SET[name] == true
		local isPotion = string.find(name, "potion", 1, true) ~= nil
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
		if not hasPrompt then return end

		queuedIds[uid] = true
		table.insert(eggQueue, isPriority and 1 or #eggQueue + 1, { target = v, color = eggColor, id = uid })
		if farmEnabled() then processQueue() end
	end)
end

local function Board(v)
	if v:FindFirstChild("_BillboardGui") then return end
	local Converted = {
		["_BillboardGui"] = Instance.new("BillboardGui");
		["_TextLabel"] = Instance.new("TextLabel");
		["_UIStroke"] = Instance.new("UIStroke");
	}

	Converted["_BillboardGui"].Active = true
	Converted["_BillboardGui"].AlwaysOnTop = true
	Converted["_BillboardGui"].ClipsDescendants = true
	Converted["_BillboardGui"].LightInfluence = 1
	Converted["_BillboardGui"].Size = UDim2.new(0, 200, 0, 50)
	Converted["_BillboardGui"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Converted["_BillboardGui"].Name = "_BillboardGui"
	Converted["_BillboardGui"].Parent = v

	Converted["_TextLabel"].Font = Enum.Font.Unknown
	Converted["_TextLabel"].Text = v.Name
	Converted["_TextLabel"].TextColor3 = Color3.fromRGB(255, 255, 255)
	Converted["_TextLabel"].TextScaled = true
	Converted["_TextLabel"].TextSize = 14
	Converted["_TextLabel"].TextWrapped = true
	Converted["_TextLabel"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Converted["_TextLabel"].BackgroundTransparency = 1
	Converted["_TextLabel"].BorderColor3 = Color3.fromRGB(0, 0, 0)
	Converted["_TextLabel"].BorderSizePixel = 0
	Converted["_TextLabel"].Size = UDim2.new(1, 0, 1, 0)
	Converted["_TextLabel"].Parent = Converted["_BillboardGui"]

	Converted["_UIStroke"].Thickness = 2
	Converted["_UIStroke"].Parent = Converted["_TextLabel"]
end

local function highlightEgg(target)
	if target:FindFirstChild("Highlight") then target.Highlight:Destroy() end
	local highlight = Instance.new("Highlight", target)
	highlight.FillColor = table.find(SpecialEggs, target.Name)
		and Color3.fromRGB(255, 0, 255)
		or Color3.fromRGB(0, 255, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	Board(target)
	if target:IsA("MeshPart") then
		target.Size = Vector3.new(15, 15, 15)
	elseif target:IsA("Model") then
		local part = target:FindFirstChildWhichIsA("BasePart") or target:FindFirstChildWhichIsA("MeshPart")
		if part then
			part.Size = Vector3.new(15, 15, 15)
		end
	end
end

local function Highlight(v)
	if not espEnabled() then return end
	if table.find(SpecialEggs, v.Name) then
		highlightEgg(v)
		return
	end

	for prefix, range in pairs(NormalEggs) do
		local num = tonumber(string.match(v.Name, "^" .. prefix .. "(%d+)$"))
		if num and num >= range.min and num <= range.max then
			highlightEgg(v)
			return
		end
	end
end

local Tabs = {
	Main = Window:AddTab("Main", "user"),
	Webhook = Window:AddTab("Webhook", "user"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Main", "boxes")

LeftGroupBox:AddToggle("Macro", {
	Text = "Egg Macro",
	Default = false,
	Callback = function(Value)
		if Value then
			lastMoveTick = tick()
			for _, v in ipairs(workspace:GetChildren()) do checkEgg(v) end
			processQueue()
		else
			isWalking = false
		end
	end,
})

LeftGroupBox:AddSlider("SpacingSlider", {
	Text = "Spacing between waypoints",
	Default = 2, Min = 1, Max = 5, Rounding = 0.5,
})

LeftGroupBox:AddToggle("DeveloperMode", {
	Text = "Developer Mode",
	Default = false,
})

LeftGroupBox:AddToggle("ESP", {
	Text = "Egg ESP",
	Default = false,
	Callback = function(Value)
		if Value then
			for _, v in pairs(workspace:GetChildren()) do
				Highlight(v)
			end
		else
			for _, v in pairs(workspace:GetDescendants()) do
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
		for _, v in pairs(workspace:GetDescendants()) do
			if v.Name == "Highlight" or v.Name == "_BillboardGui" then
				v:Destroy()
			end
		end
	end,
})

local Hello = Tabs.Webhook:AddLeftGroupbox("Webhook", "boxes")

Hello:AddInput("WebhookURL", {
	Default = "Webhook URL",
	Numeric = false,
	Finished = false,
	ClearTextOnFocus = false,

	Text = "Webhook URL",

	Placeholder = "Webhook URL",

	Callback = function(Value)
		webhook[webhook] = Value
	end,
})

Hello:AddButton({
	Text = "Test",
	Func = function()
		local webhookUrl = webhook[webhook]

		local response = request({
			Url = webhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = game:GetService("HttpService"):JSONEncode({
				["content"] = "This is a test."
			})
		})

		if response.StatusCode == 204 or response.StatusCode == 200 then
			print("Webhook sent successfully!")
		else
			print("Failed to send. Status code: " .. tostring(response.StatusCode))
		end
	end,
})

Hello:AddToggle("Normal Eggs", {
	Text = "Notify Normal Eggs",
	Default = false,
	Callback = function(Value)
		webhook.Settings.NormalEggs = Value
	end,
})

Hello:AddToggle("Aura Eggs", {
	Text = "Notify Aura Eggs",
	Default = false,
	Callback = function(Value)
		webhook.Settings.ImportantEggs = Value
	end,
})



local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)
		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload",
	function()
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

workspace.ChildAdded:Connect(function(v)
	Highlight(v)
	checkEgg(v)
end)

print("SHRIMP'S STUFF LOADED!")
