local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LP = game:GetService("Players").LocalPlayer
local Camera = Workspace.CurrentCamera

local idled = LP.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
	task.wait()
	VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
end)



local defaults = {
    Macro = {
        Enabled = false,
        WhatToMacro = {}
    },
    ESP = {
        Enabled = false,
        WhatToESP = {}
    },
    WebHook = {
        URL = "",
        Notify = {},
        Enabled = false,
        SpecialEggsSpawnNotify = false,
    }
}

local Eggs = {
    PointEggs = {
        "point_egg_1",
        "point_egg_2",
        "point_egg_3",
        "point_egg_4",
        "point_egg_5",
        "point_egg_6",
    },
    RandomPotionEggs = {
        "random_potion_egg_1",
        "random_potion_egg_2",
    },
    AuraEggs = {
        "andromeda_egg",
        "angelic_egg",
        "blooming_egg",
        "dreamer_egg",
        "egg_v2",
        "forest_egg",
        "hatch_egg",
        "royal_egg",
        "the_egg_of_the_sky"
    }
}

local SomethingSomething = table.clone(defaults)

local MacroQueue = {}
local MacroRunning = false

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Path = loadstring(game:HttpGet("https://raw.githubusercontent.com/grayzcale/simplepath/refs/heads/main/src/SimplePath.lua"))()

local EggsFrame

do
    local targetPos = UDim2.new(0, 10, 0.894999981, -10)
    for _, v in ipairs(LP.PlayerGui:WaitForChild("MainInterface"):GetChildren()) do
        if v.Position == targetPos then
            EggsFrame = v
            break
        end
    end
end

local function SendWebhook(data)
    local url = SomethingSomething.WebHook.URL
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

local e = Path.new(LP.Character, {
    AgentHeight     = 6,
    AgentRadius     = 3,
    AgentCanJump    = true,
    AgentJumpHeight = 25,
    WaypointSpacing = 1,
})

local WaterBlocks = Workspace:WaitForChild("Map"):WaitForChild("Miscs"):WaitForChild("WaterBlocks")

local WaterAuras = {
    "Sailor",
    "Sailor_Admiral",
    "Sailor_Flying Dutchman"
}

local function UpdateWaterCollision()
    local hasAura = table.find(WaterAuras, LP:GetAttribute("AuraName"))
    for _, v in ipairs(WaterBlocks:GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide = hasAura ~= nil
            v.CanQuery   = hasAura ~= nil
        end
    end
end

UpdateWaterCollision()
LP:GetAttributeChangedSignal("AuraName"):Connect(UpdateWaterCollision)

local function esp(i)
    local folder = Instance.new("Folder")
    folder.Parent = i
    folder.Name = "esp"

    local highlight = Instance.new("Highlight")
    highlight.Parent = folder
    highlight.FillTransparency = 0.7
    highlight.Adornee = i
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.OutlineTransparency = 0.3
    highlight.Enabled = true

    local bg = Instance.new("BillboardGui")
    bg.Parent = folder
    bg.Size = UDim2.fromOffset(100, 100)
    bg.Brightness = 1
    bg.AlwaysOnTop = true
    bg.MaxDistance = 1000
    bg.Adornee = i

    local txt = Instance.new("TextLabel")
    txt.Parent = bg
    txt.Text = i.Name
    txt.Name = "TextLabel"
    txt.BackgroundTransparency = 1
    txt.Size = UDim2.fromScale(1, 0.3)
    txt.AnchorPoint = Vector2.new(0.5, 0.5)
    txt.Position = UDim2.fromScale(0.5, 0.7)
    txt.Font = Enum.Font.RobotoCondensed
    txt.TextScaled = true

    local stroke = Instance.new("UIStroke", txt)
    stroke.Thickness = 2.6
end

local function dumesp(a0)
    if a0:IsA("MeshPart") and table.find(Eggs.PointEggs, a0.Name) then
        esp(a0)
    elseif a0:IsA("Model") and (table.find(Eggs.RandomPotionEggs, a0.Name) or table.find(Eggs.AuraEggs, a0.Name)) then
        esp(a0)
    end
end

Workspace.DescendantAdded:Connect(dumesp)
task.spawn(function()
    for _, v in Workspace:GetDescendants() do
        dumesp(v)
    end
end)

local function IsNotified(EggType)
    local n = SomethingSomething.WebHook.Notify
    if type(n) == "table" then
        if n[EggType] then return true end
        for _, v in ipairs(n) do
            if v == EggType then return true end
        end
    end
    return false
end

local function GetRootPart(egg)
    if egg:IsA("MeshPart") then return egg end
    if egg:IsA("Model") then return egg:FindFirstChildWhichIsA("BasePart") end
end

local function GetDistance(egg)
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local part = GetRootPart(egg)
    if not root or not part then return math.huge end
    return (root.Position - part.Position).Magnitude
end

local function SortQueue()
    table.sort(MacroQueue, function(a, b)
        return GetDistance(a) < GetDistance(b)
    end)
end

local function GetEggType(egg)
    if egg:IsA("MeshPart") then
        return "Point Egg"
    elseif table.find(Eggs.RandomPotionEggs, egg.Name) then
        return "Random Potion Egg"
    else
        return "Aura Egg"
    end
end

local function SendEggCollectedWebhook(egg, EggType)
    if not SomethingSomething.WebHook.Enabled then return end
    if not IsNotified(EggType) then return end

    if EggType == "Aura Egg" then
        SendWebhook({
            content = "@everyone",
            embeds = {{
                title       = "⚠️ Aura Egg Collected!",
                description = "An **aura egg** has been collected!",
                color       = 65280,
                footer      = { text = "Egg: " .. egg.Name .. " | Check your inventory!" },
            }},
        })
    elseif EggType == "Random Potion Egg" then
        SendWebhook({
            content = "",
            embeds = {{
                title       = "Random Potion Egg Collected!",
                description = "A **random potion egg** has been collected!",
                color       = 65280,
                footer      = { text = "A random potion egg has been collected! Check your inventory!" },
            }},
        })
    elseif EggType == "Point Egg" then
        SendWebhook({
            content = "",
            embeds = {{
                title       = "Point Egg Collected!",
                description = "A **point egg** has been collected!",
                color       = 65280,
                footer      = { text = "A point egg has been collected! You now have " .. (EggsFrame and EggsFrame.TextLabel and EggsFrame.TextLabel.Text or "?") .. " egg points!" },
            }},
        })
    end
end

local ScanAndQueueExistingEggs

local function ProcessQueue()
    if MacroRunning then return end
    MacroRunning = true
    task.spawn(function()
        while #MacroQueue > 0 and SomethingSomething.Macro.Enabled do
            LP.DevComputerMovementMode = Enum.DevComputerMovementMode.Scriptable
            local egg = table.remove(MacroQueue, 1)
            if egg and egg.Parent then
                local done = false

                local reachedConn = e.Reached:Connect(function()
                    done = true
                end)

                local runto = nil
                local ok, err = pcall(function()
                    if egg:IsA("MeshPart") then
                        runto = egg
                        e:Run(egg)
                    elseif egg:IsA("Model") then
                        local part = egg:FindFirstChildWhichIsA("BasePart")
                        if part then runto = part; e:Run(part) end
                    end
                end)

                if not ok then
                    warn("[Shrimp] Path start error: " .. tostring(err))
                    reachedConn:Disconnect()
                    continue
                end

                local elapsed = 0
                while not done and elapsed < 60 do
                    task.wait(0.5)
                    elapsed += 0.5
                end

                reachedConn:Disconnect()

                if not done then
                    warn("[Shrimp] Timeout on egg: " .. tostring(egg.Name) .. " — resetting character")
                    pcall(e.Stop, e)
                    return
                end

                local ok2, err2 = pcall(function()
                    for _, v in egg:GetDescendants() do
                        if v:IsA("ProximityPrompt") then
                            for i = 1, 10 do
                                fireproximityprompt(v)
                            end
                        end
                    end
                end)
                if not ok2 then warn("[Shrimp] Collect error: " .. tostring(err2)) end

                local EggType = GetEggType(egg)
                task.delay(0.5, function()
                    SendEggCollectedWebhook(egg, EggType)
                end)
            end
        end
        LP.DevComputerMovementMode = Enum.DevComputerMovementMode.UserChoice
        MacroRunning = false
    end)
end

ScanAndQueueExistingEggs = function()
    MacroQueue = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("MeshPart") and table.find(Eggs.PointEggs, v.Name) and SomethingSomething.Macro.WhatToMacro["Point Eggs"] then
            table.insert(MacroQueue, v)
        elseif v:IsA("Model") then
            if table.find(Eggs.RandomPotionEggs, v.Name) and SomethingSomething.Macro.WhatToMacro["Random Potion Eggs"] then
                table.insert(MacroQueue, v)
            elseif table.find(Eggs.AuraEggs, v.Name) and SomethingSomething.Macro.WhatToMacro["Aura Eggs"] then
                table.insert(MacroQueue, v)
            end
        end
    end
    SortQueue()
    ProcessQueue()
end

Workspace.ChildAdded:Connect(function(v)
    if not SomethingSomething.Macro.Enabled then return end

    local shouldQueue = false

    if table.find(Eggs.PointEggs, v.Name) and SomethingSomething.Macro.WhatToMacro["Point Eggs"] then
        shouldQueue = true
    elseif table.find(Eggs.RandomPotionEggs, v.Name) and SomethingSomething.Macro.WhatToMacro["Random Potion Eggs"] then
        shouldQueue = true
    elseif table.find(Eggs.AuraEggs, v.Name) and SomethingSomething.Macro.WhatToMacro["Aura Eggs"] then
        if SomethingSomething.WebHook.Enabled and SomethingSomething.WebHook.SpecialEggsSpawnNotify then
            SendWebhook({
                content = "@everyone",
                embeds = {{
                    title       = "⚠️ Aura Egg Found!",
                    description = "An **aura egg** has spawned!",
                    color       = 16711680,
                    footer      = { text = "Egg: " .. v.Name .. " | Attempting to collect!" },
                }},
            })
        end
        shouldQueue = true
    end

    if shouldQueue then
        e:Stop()
        MacroRunning = false
        table.insert(MacroQueue, v)
        SortQueue()
        ProcessQueue()
    end
end)

local Window = Library:CreateWindow({
    Title = "Shrimp's Stuff",
    Footer = "sol's rng - femboys - v2.1.0 - " .. LP.Name,
    Icon = 6171138225,
    NotifySide = "Left",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "user"),
    Webhook = Window:AddTab("Webhook", "user"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local Macro = Tabs.Main:AddLeftGroupbox("Macro", "boxes")

Macro:AddToggle("EnableMacro", {
    Text = "Enable Macro",
    Default = false,
    Callback = function(Value)
        SomethingSomething.Macro.Enabled = Value
        if Value then
            MacroQueue = {}
            MacroRunning = false
            ScanAndQueueExistingEggs()
        else
            MacroQueue = {}
            e:Stop()
            LP.DevComputerMovementMode = Enum.DevComputerMovementMode.UserChoice
        end
    end,
})

Macro:AddDropdown("WhatToMacro", {
    Text = "What to macro",
    Multi = true,
    Values = {"Point Eggs", "Random Potion Eggs", "Aura Eggs"},
    Default = nil,
    Callback = function(Value)
        SomethingSomething.Macro.WhatToMacro = Value
    end,
})

local ESP = Tabs.Main:AddRightGroupbox("ESP", "boxes")

ESP:AddToggle("EnableESP", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(Value)
        SomethingSomething.ESP.Enabled = Value
    end,
})

ESP:AddDropdown("WhatToESP", {
    Text = "What to ESP",
    Multi = true,
    Values = {"Point Eggs", "Random Potion Eggs", "Aura Eggs"},
    Default = nil,
    Callback = function(Value)
        SomethingSomething.ESP.WhatToESP = Value
    end,
})

local WebhookTab = Tabs.Webhook:AddLeftGroupbox("Discord (no way bro)", "boxes")

WebhookTab:AddInput("WebhookURL", {
    Default = "",
    ClearTextOnFocus = true,
    Text = "Webhook URL",
    Tooltip = "The URL of your discord webhook",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(Value)
        SomethingSomething.WebHook.URL = Value
    end,
})

WebhookTab:AddDropdown("NotifiersDropdown", {
    Values = {"Point Egg", "Random Potion Egg", "Aura Egg"},
    Default = nil,
    Multi = true,
    Text = "Notify",
    Tooltip = "What do you want the webhook to notify you about?",
    Callback = function(Value)
        SomethingSomething.WebHook.Notify = Value
    end,
})

WebhookTab:AddToggle("Enable", {
    Text = "Enable Notifications",
    Tooltip = "Self explanatory bro",
    Default = false,
    Callback = function(Value)
        SomethingSomething.WebHook.Enabled = Value
    end,
})

WebhookTab:AddToggle("AuraEggNotify", {
    Text = "Notify when an Aura Egg spawns",
    Tooltip = "Self explanatory bro",
    Default = false,
    Callback = function(Value)
        SomethingSomething.WebHook.SpecialEggsSpawnNotify = Value
    end,
})

Library:OnUnload(function()
    e:Stop()
    idled:Disconnect()
    for _,v in Workspace:GetDescendants() do
        if v.Name == "esp" then v:Destroy() end
    end
end)

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
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("Shrimp's Stuff")
SaveManager:SetFolder("Shrimp's Stuff/Sol's RNG")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
