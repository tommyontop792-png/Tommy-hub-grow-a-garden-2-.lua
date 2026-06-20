-- Sacred UI V9.2 | Anti Lava + Delete Ghost Ship | Standalone Version

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

-- Verificar si estamos en un entorno de juego
local function IsGameRunning()
    return game:IsLoaded() and player and player.Character
end

-- Esperar a que el juego esté listo
repeat task.wait(0.5) until IsGameRunning()

print("🚀 Iniciando Sacred UI V9.2 Standalone...")

-- ============================================================
-- STATE VARIABLES
-- ============================================================
local SoruInfinitoEnabled = false
local SoruAimbotEnabled = false
local soruMaxDist = 2000
local AimlockPlayerEnabled = false
local AimlockNpcEnabled = false
local SilentAimPlayersEnabled = false
local SilentAimNPCsEnabled = false
local NoCooldownEnabled = false
local PlayerWidgetActive = false
local NpcWidgetActive = false
local SelectedSoruTarget = "Nearest"
local maxRange = 1000
local PlayersPosition = nil
local NPCPosition = nil

-- ============================================================
-- FAST ATTACK
-- ============================================================
local RegisterHit = nil
local RegisterAttack = nil
local FastAttackEnabled = false
local FastAttackRange = 2000
local FastAttackRunning = false

task.spawn(function()
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == "RE/RegisterHit" then RegisterHit = v end
        if v:IsA("RemoteEvent") and v.Name == "RE/RegisterAttack" then RegisterAttack = v end
    end
end)

local function AttackMultipleTargets(targets)
    if not RegisterHit or not RegisterAttack then return end
    pcall(function()
        if not targets or #targets == 0 then return end
        local allTargets = {}
        for _, char in pairs(targets) do
            local head = char:FindFirstChild("Head")
            if head then table.insert(allTargets, {char, head}) end
        end
        if #allTargets == 0 then return end
        RegisterAttack:FireServer(0)
        RegisterHit:FireServer(allTargets[1][2], allTargets)
    end)
end

local function StartFastAttack()
    if FastAttackRunning then return end
    FastAttackRunning = true
    task.spawn(function()
        while FastAttackEnabled do
            RunService.Stepped:Wait()
            local myChar = player.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then continue end
            local targets = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local hum = p.Character:FindFirstChild("Humanoid")
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0
                    and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                        table.insert(targets, p.Character)
                    end
                end
            end
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, npc in pairs(enemies:GetChildren()) do
                    local hum = npc:FindFirstChild("Humanoid")
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0
                    and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                        table.insert(targets, npc)
                    end
                end
            end
            if #targets > 0 then AttackMultipleTargets(targets) end
        end
        FastAttackRunning = false
    end)
end

-- ============================================================
-- ANTI-STUN
-- ============================================================
local AntiStunEnabled = false

local flyingFruits = {
    "Portal", "Rumble", "Light", "Flame", "Ice", "Dough",
    "Buddha", "Magma", "Dragon", "Spider", "Venom", "Shadow"
}

local function isUsingFlyingFruit()
    local char = player.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    for _, f in ipairs(flyingFruits) do
        if tool.Name:find(f) or (tool.ToolTip or ""):find(f) then return true end
    end
    return false
end

local flyingStates = {
    [Enum.HumanoidStateType.Freefall] = true,
    [Enum.HumanoidStateType.Jumping] = true,
    [Enum.HumanoidStateType.Flying] = true,
    [Enum.HumanoidStateType.GettingUp] = true,
}

task.spawn(function()
    while true do
        task.wait(0.05)
        if AntiStunEnabled then
            pcall(function()
                local char = player.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then return end
                if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
                if hum.JumpPower < 50 then hum.JumpPower = 50 end
                local state = hum:GetState()
                local flying = isUsingFlyingFruit()
                if not flyingStates[state] and not flying then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        for _, o in ipairs(root:GetChildren()) do
                            if o:IsA("BodyVelocity") or o:IsA("BodyPosition") or o:IsA("LinearVelocity") then
                                if o:IsA("LinearVelocity") and o.VectorVelocity.Magnitude < 50 then o:Destroy()
                                elseif o:IsA("BodyVelocity") and o.Velocity.Magnitude < 50 then o:Destroy()
                                elseif not o:IsA("LinearVelocity") and not o:IsA("BodyVelocity") then o:Destroy()
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- WALK SPEED
-- ============================================================
local WalkSpeedEnabled = false
local WalkSpeedValue = 16

task.spawn(function()
    while true do
        task.wait(0.05)
        if WalkSpeedEnabled then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= WalkSpeedValue then hum.WalkSpeed = WalkSpeedValue end
        end
    end
end)

-- ============================================================
-- DASH DISTANCE
-- ============================================================
local DashEnabled = false
local DashLengthDist = 1
local DashRunning = false

local function startDashLoop()
    if DashRunning then return end
    DashRunning = true
    task.spawn(function()
        while DashEnabled do
            task.wait(0.1)
            pcall(function()
                local char = player.Character
                if char then
                    if char:GetAttribute("DashLength") ~= DashLengthDist then char:SetAttribute("DashLength", DashLengthDist) end
                    if char:GetAttribute("DashLengthAir") ~= DashLengthDist then char:SetAttribute("DashLengthAir", DashLengthDist) end
                end
            end)
        end
        DashRunning = false
    end)
end

local function stopDashLoop()
    DashEnabled = false
    pcall(function()
        local char = player.Character
        if char then
            char:SetAttribute("DashLength", 1)
            char:SetAttribute("DashLengthAir", 1)
        end
    end)
end

-- ============================================================
-- NOCLIP
-- ============================================================
local NoclipEnabled = false
local NoclipConn = nil

local function SetNoclip(state)
    NoclipEnabled = state
    if state then
        NoclipConn = RunService.Stepped:Connect(function()
            local char = player.Character
            if char and NoclipEnabled then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

player.CharacterAdded:Connect(function()
    if NoclipEnabled then task.wait(0.5); SetNoclip(true) end
end)

-- ============================================================
-- INFINITE JUMP
-- ============================================================
local InfiniteJumpEnabled = false

UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ============================================================
-- WALK ON WATER
-- ============================================================
local WalkOnWaterEnabled = false

task.spawn(function()
    local waterPart = Instance.new("Part")
    waterPart.Size = Vector3.new(200, 1, 200)
    waterPart.Transparency = 1
    waterPart.Anchored = true
    waterPart.CanCollide = false
    waterPart.Name = "SacredWaterPlatform"
    waterPart.Parent = workspace
    while true do
        task.wait(0.05)
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if WalkOnWaterEnabled and hrp then
            if hrp.Position.Y >= 9.5 then
                waterPart.Position = Vector3.new(hrp.Position.X, 9.2, hrp.Position.Z)
                waterPart.CanCollide = true
            else
                waterPart.CanCollide = false
            end
        else
            waterPart.CanCollide = false
        end
    end
end)

-- ============================================================
-- SMART AUTO V4
-- ============================================================
local SmartAutoV4Enabled = false

task.spawn(function()
    while true do
        task.wait(1)
        if SmartAutoV4Enabled then
            pcall(function()
                local char = player.Character
                if char and char:GetAttribute("RaceEnergy") and char:GetAttribute("RaceEnergy") >= 100 then
                    local awakening = player.Backpack:FindFirstChild("Awakening")
                    if awakening and awakening:FindFirstChild("RemoteFunction") then
                        awakening.RemoteFunction:InvokeServer(true)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- ESP
-- ============================================================
local ESPEnabled = false
local ESPObjects = {}

local function CreateESP(target)
    if not target:FindFirstChild("Head") then return end
    local existing = target.Head:FindFirstChild("SacredESP")
    if existing then existing:Destroy() end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SacredESP"
    billboard.Adornee = target.Head
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = target.Head
    local label = Instance.new("TextLabel", billboard)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = target.Name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.new(0, 1, 1)
    label.TextStrokeTransparency = 0
    table.insert(ESPObjects, billboard)
end

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    ESPObjects = {}
end

local function UpdateESP()
    ClearESP()
    if not ESPEnabled then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then CreateESP(p.Character) end
    end
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, npc in pairs(enemies:GetChildren()) do CreateESP(npc) end
    end
end

task.spawn(function()
    while true do
        task.wait(5)
        if ESPEnabled then UpdateESP() end
    end
end)

-- ============================================================
-- SORU INFINITO
-- ============================================================
local function enforceSoru(char)
    if not char then return end
    if SoruInfinitoEnabled then char:SetAttribute("FlashstepCooldown", 1) end
    char.AttributeChanged:Connect(function(attr)
        if attr == "FlashstepCooldown" and SoruInfinitoEnabled
        and char:GetAttribute("FlashstepCooldown") ~= 1 then
            char:SetAttribute("FlashstepCooldown", 1)
        end
    end)
end

player.CharacterAdded:Connect(enforceSoru)
if player.Character then enforceSoru(player.Character) end

task.spawn(function()
    while true do
        task.wait(0.5)
        if SoruInfinitoEnabled and player.Character then
            pcall(function() player.Character:SetAttribute("FlashstepCooldown", 1) end)
        end
    end
end)

-- ============================================================
-- TARGET HELPERS
-- ============================================================
local function getClosestPlayer()
    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local closest, closestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (p.Character.HumanoidRootPart.Position - myHrp.Position).Magnitude
                if dist < closestDist and dist < maxRange then
                    closestDist = dist
                    closest = p.Character
                end
            end
        end
    end
    return closest
end

local function getClosestNPC()
    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local container = workspace:FindFirstChild("Enemies") or workspace
    local closest, closestDist = nil, math.huge
    for _, npc in pairs(container:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart")
        and not Players:GetPlayerFromCharacter(npc) then
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (npc.HumanoidRootPart.Position - myHrp.Position).Magnitude
                if dist < closestDist and dist < maxRange then
                    closestDist = dist
                    closest = npc
                end
            end
        end
    end
    return closest
end

-- ============================================================
-- AIMLOCK + SILENT AIM POSITIONS
-- ============================================================
RunService.RenderStepped:Connect(function()
    PlayersPosition = SilentAimPlayersEnabled and (getClosestPlayer() and getClosestPlayer().HumanoidRootPart.Position) or nil
    NPCPosition = SilentAimNPCsEnabled and (getClosestNPC() and getClosestNPC().HumanoidRootPart.Position) or nil

    if PlayerWidgetActive and AimlockPlayerEnabled then
        local t = getClosestPlayer()
        if t and t:FindFirstChild("HumanoidRootPart") then
            camera.CFrame = CFrame.new(camera.CFrame.Position, t.HumanoidRootPart.Position)
        end
    end
    if NpcWidgetActive and AimlockNpcEnabled then
        local t = getClosestNPC()
        if t and t:FindFirstChild("HumanoidRootPart") then
            camera.CFrame = CFrame.new(camera.CFrame.Position, t.HumanoidRootPart.Position)
        end
    end
end)

-- ============================================================
-- METAMETHODS (Silent Aim + Soru Aimbot + No Cooldown)
-- ============================================================
local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    if not checkcaller() and self == mouse and (key == "Hit" or key == "Target") then
        if SoruAimbotEnabled then
            local targetName = SelectedSoruTarget
            if targetName == "Nearest" then
                local cl = getClosestPlayer()
                local p = cl and Players:GetPlayerFromCharacter(cl)
                targetName = p and p.Name or nil
            end
            if targetName then
                local tObj = Players:FindFirstChild(targetName)
                local eHRP = tObj and tObj.Character and tObj.Character:FindFirstChild("HumanoidRootPart")
                if eHRP then
                    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if myHRP and (myHRP.Position - eHRP.Position).Magnitude <= soruMaxDist then
                        if key == "Hit" then return CFrame.new(eHRP.Position) end
                        if key == "Target" then return eHRP end
                    end
                end
            end
        end
        if SilentAimPlayersEnabled or SilentAimNPCsEnabled then
            local activePos = PlayersPosition or NPCPosition
            if activePos then
                if key == "Hit" then return CFrame.new(activePos) end
                if key == "Target" then return workspace:FindFirstChild("HumanoidRootPart") end
            end
        end
    end
    return oldIndex(self, key)
end)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod():lower()

    if not checkcaller() and (method == "fireserver" or method == "invokeserver") then
        local activePos = PlayersPosition or NPCPosition
        if activePos then
            for i, arg in ipairs(args) do
                if typeof(arg) == "Vector3" then args[i] = activePos
                elseif typeof(arg) == "CFrame" then args[i] = CFrame.new(activePos)
                end
            end
            return oldNamecall(self, unpack(args))
        end
    end

    if not checkcaller() and NoCooldownEnabled and method == "invokeserver"
    and tostring(self) == "" then
        task.spawn(function()
            local function isInCombat()
                local gui = player:FindFirstChild("PlayerGui")
                local main = gui and gui:FindFirstChild("Main")
                local hud = main and main:FindFirstChild("BottomHUDList")
                local combat = hud and hud:FindFirstChild("InCombat")
                return combat and combat.Visible == true
            end
            local permanentFruits = {}
            pcall(function()
                local fruitResult = ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits", false)
                if fruitResult then
                    for _, fruit in pairs(fruitResult) do
                        if fruit.HasPermanent then table.insert(permanentFruits, fruit.Name) end
                    end
                end
            end)
            local char = player.Character
            if not char then return end
            for _, item in char:GetChildren() do
                if item:IsA("Tool") and (item.ToolTip == "Sword" or item.ToolTip == "Gun" or item.ToolTip == "Blox Fruit") then
                    task.wait(0.01)
                    if item.ToolTip == "Blox Fruit" and not table.find(permanentFruits, item.Name) then return end
                    local CommF = ReplicatedStorage.Remotes.CommF_
                    local result
                    repeat
                        task.wait()
                        result = CommF:InvokeServer(item.ToolTip == "Blox Fruit" and "SwitchFruit" or "LoadItem", item.Name)
                    until result == true or isInCombat()
                    if isInCombat() then
                        char:SetAttribute("AllCooldown", 0)
                        repeat task.wait(0.1) until not isInCombat()
                        char:SetAttribute("AllCooldown", 3)
                    end
                    pcall(function()
                        if player.Backpack and player.Backpack:FindFirstChild(item.Name) then
                            player.Backpack[item.Name].Parent = char
                        end
                    end)
                    break
                end
            end
        end)
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- ============================================================
-- INTERFACE GRÁFICA MEJORADA PARA STANDALONE
-- ============================================================
local function CreateStandaloneUI()
    -- Limpiar UIs antiguas
    for _, old in ipairs(playerGui:GetChildren()) do
        if old.Name:match("SacredUI") then old:Destroy() end
    end

    -- Crear ScreenGui
    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "SacredUI_Standalone"
    screenGui.ResetOnSpawn = false

    -- Marco principal
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 380, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local corner = Instance.new("UICorner", mainFrame)
    corner.CornerRadius = UDim.new(0, 12)
    
    -- Efecto de vidrio
    local glass = Instance.new("Frame", mainFrame)
    glass.Size = UDim2.new(1, 0, 1, 0)
    glass.BackgroundTransparency = 0.8
    glass.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glass.BorderSizePixel = 0
    local glassCorner = Instance.new("UICorner", glass)
    glassCorner.CornerRadius = UDim.new(0, 12)

    -- Título
    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ Sacred UI V9.2 ⚡"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(0, 150, 255)
    title.TextScaled = true

    -- Subtítulo
    local subtitle = Instance.new("TextLabel", mainFrame)
    subtitle.Size = UDim2.new(1, 0, 0, 20)
    subtitle.Position = UDim2.new(0, 0, 0, 35)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "by BBG & iSacredRivals"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
    subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)

    -- Scroll frame para opciones
    local scrollFrame = Instance.new("ScrollingFrame", mainFrame)
    scrollFrame.Size = UDim2.new(1, -20, 1, -80)
    scrollFrame.Position = UDim2.new(0, 10, 0, 60)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 3
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local layout = Instance.new("UIListLayout", scrollFrame)
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Categorías
    local categories = {
        {name = "⚔️ Combat", color = Color3.fromRGB(255, 50, 50)},
        {name = "🌀 Glitches", color = Color3.fromRGB(255, 200, 50)},
        {name = "🎯 Aimlock", color = Color3.fromRGB(50, 200, 50)},
        {name = "⚡ Soru Engine", color = Color3.fromRGB(150, 50, 255)},
        {name = "👁️ ESP", color = Color3.fromRGB(50, 150, 255)},
    }

    local function createCategory(name, color)
        -- Crear categoría
        local catFrame = Instance.new("Frame", scrollFrame)
        catFrame.Size = UDim2.new(1, 0, 0, 180)
        catFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        catFrame.BackgroundTransparency = 0.4
        catFrame.BorderSizePixel = 0
        local catCorner = Instance.new("UICorner", catFrame)
        catCorner.CornerRadius = UDim.new(0, 8)
        
        local catTitle = Instance.new("TextLabel", catFrame)
        catTitle.Size = UDim2.new(1, -20, 0, 25)
        catTitle.Position = UDim2.new(0, 10, 0, 5)
        catTitle.BackgroundTransparency = 1
        catTitle.Text = name
        catTitle.Font = Enum.Font.GothamBold
        catTitle.TextSize = 14
        catTitle.TextColor3 = color
        catTitle.TextXAlignment = Enum.TextXAlignment.Left

        return catFrame
    end

    -- Botón toggle estilo moderno
    local function createToggle(parent, label, defaultState, yPos, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, -20, 0, 30)
        frame.Position = UDim2.new(0, 10, 0, yPos)
        frame.BackgroundTransparency = 1

        local labelText = Instance.new("TextLabel", frame)
        labelText.Size = UDim2.new(0.7, 0, 1, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.Font = Enum.Font.Gotham
        labelText.TextSize = 13
        labelText.TextColor3 = Color3.fromRGB(200, 200, 200)
        labelText.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 50, 0, 25)
        btn.Position = UDim2.new(1, -55, 0.5, -12.5)
        btn.BackgroundColor3 = defaultState and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
        btn.Text = defaultState and "ON" or "OFF"
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BorderSizePixel = 0
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 6)

        local state = defaultState
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
            btn.Text = state and "ON" or "OFF"
            callback(state)
        end)
    end

    -- Crear categorías y opciones
    -- Combat
    local combatCat = createCategory("⚔️ Combat Options", Color3.fromRGB(255, 50, 50))
    createToggle(combatCat, "Silent Aim Players", false, 35, function(v) SilentAimPlayersEnabled = v end)
    createToggle(combatCat, "Silent Aim NPCs", false, 70, function(v) SilentAimNPCsEnabled = v end)
    createToggle(combatCat, "Fast Attack", false, 105, function(v) FastAttackEnabled = v; if v then StartFastAttack() end end)
    createToggle(combatCat, "Anti-Stun", false, 140, function(v) AntiStunEnabled = v end)

    -- Movement
    local moveCat = createCategory("🏃 Movement", Color3.fromRGB(255, 200, 50))
    createToggle(moveCat, "Walk Speed", false, 35, function(v) WalkSpeedEnabled = v end)
    createToggle(moveCat, "Dash Distance", false, 70, function(v) DashEnabled = v; if v then startDashLoop() else stopDashLoop() end end)
    createToggle(moveCat, "Noclip", false, 105, function(v) SetNoclip(v) end)
    createToggle(moveCat, "Infinite Jump", false, 140, function(v) InfiniteJumpEnabled = v end)
    createToggle(moveCat, "Walk on Water", false, 175, function(v) WalkOnWaterEnabled = v end)

    -- Glitches
    local glitchCat = createCategory("🌀 Glitches", Color3.fromRGB(255, 200, 50))
    createToggle(glitchCat, "Anti Lava", false, 35, function(v) 
        antiLavaActive = v
        if v then startAntiLava() else stopAntiLava() end
    end)
    createToggle(glitchCat, "Delete Ghost Ship", false, 70, function(v) 
        deleteShipActive = v
        if v then startDeleteShipLoop() end
    end)

    -- Aimlock
    local aimCat = createCategory("🎯 Aimlock", Color3.fromRGB(50, 200, 50))
    createToggle(aimCat, "Lock Players", false, 35, function(v) 
        PlayerWidgetActive = v
        if not v then AimlockPlayerEnabled = false end
    end)
    createToggle(aimCat, "Lock NPCs", false, 70, function(v) 
        NpcWidgetActive = v
        if not v then AimlockNpcEnabled = false end
    end)

    -- Soru
    local soruCat = createCategory("⚡ Soru Engine", Color3.fromRGB(150, 50, 255))
    createToggle(soruCat, "Infinite Soru", false, 35, function(v) 
        SoruInfinitoEnabled = v
        if player.Character then enforceSoru(player.Character) end
    end)
    createToggle(soruCat, "Soru Aimbot (TP)", false, 70, function(v) SoruAimbotEnabled = v end)
    createToggle(soruCat, "No Cooldown", false, 105, function(v) 
        NoCooldownEnabled = v
        if v then
            if player.Character then player.Character:SetAttribute("AllCooldown", 3) end
        else
            if player.Character then player.Character:SetAttribute("AllCooldown", 0) end
        end
    end)

    -- ESP
    local espCat = createCategory("👁️ ESP", Color3.fromRGB(50, 150, 255))
    createToggle(espCat, "ESP Names", false, 35, function(v) 
        ESPEnabled = v
        if v then UpdateESP() else ClearESP() end
    end)
    createToggle(espCat, "Target ESP", false, 70, function(v) 
        targetEspEnabled = v
        if v then
            if not targetEspFrame then createTargetEspFrame() end
            targetEspFrame.Visible = true; updateTargetEsp()
        else
            if targetEspFrame then targetEspFrame.Visible = false end
        end
    end)

    -- Botón para cerrar
    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BorderSizePixel = 0
    local closeCorner = Instance.new("UICorner", closeBtn)
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Botón minimizar
    local minBtn = Instance.new("TextButton", mainFrame)
    minBtn.Size = UDim2.new(0, 30, 0, 30)
    minBtn.Position = UDim2.new(1, -70, 0, 5)
    minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    minBtn.Text = "─"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.BorderSizePixel = 0
    local minCorner = Instance.new("UICorner", minBtn)
    minCorner.CornerRadius = UDim.new(0, 6)
    minBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)

    return screenGuiend

-- ============================================================
-- FUNCIONES FALTANTES PARA GLITCHES
-- ============================================================
-- Anti Lava
local antiLavaActive = false
local antiLavaConnection = nil

local function startAntiLava()
    if antiLavaConnection then antiLavaConnection:Disconnect() end
    antiLavaConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if not (char and antiLavaActive) then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart"
            and part.Name ~= "Torso" and part.Name ~= "UpperTorso"
            and part.Name ~= "LowerTorso" and part.Name ~= "Head" then
                part.CanTouch = false
            end
        end
    end)
end

local function stopAntiLava()
    if antiLavaConnection then antiLavaConnection:Disconnect(); antiLavaConnection = nil end
end

-- Delete Ghost Ship
local deleteShipActive = false
local deleteShipRunning = false

local function deleteShipStructure()
    if not deleteShipActive then return end
    task.spawn(function()
        local shipNames = {"CursedShip","Cursed Ship","Ship"}
        local exteriorNames = {"Wall","Floor","Ceiling","Base","Hull","Window","DoorFrame"}
        for _, obj in pairs(workspace:GetDescendants()) do
            for _, sName in pairs(shipNames) do
                if obj.Name:find(sName) and (obj:IsA("Model") or obj:IsA("Folder")) then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("BasePart") and not child.Parent:FindFirstChild("Humanoid") then
                            local isExterior = false
                            for _, ext in pairs(exteriorNames) do
                                if child.Name:find(ext) then isExterior = true; break end
                            end
                            if not isExterior then child:Destroy() end
                        end
                    end
                end
            end
        end
    end)
end

local function startDeleteShipLoop()
    if deleteShipRunning then return end
    deleteShipRunning = true
    task.spawn(function()
        while deleteShipActive do
            deleteShipStructure()
            task.wait(3)
        end
        deleteShipRunning = false
    end)
end

-- ============================================================
-- TARGET ESP
-- ============================================================
local targetEspEnabled = false
local targetEspFrame, targetEspName, targetEspDist, targetEspHealth

local function createTargetEspFrame()
    if targetEspFrame then targetEspFrame:Destroy() end
    targetEspFrame = Instance.new("Frame", playerGui)
    targetEspFrame.Size = UDim2.new(0, 220, 0, 80)
    targetEspFrame.Position = UDim2.new(1, -230, 0, 10)
    targetEspFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    targetEspFrame.BackgroundTransparency = 0.4
    targetEspFrame.BorderSizePixel = 0
    targetEspFrame.Visible = false
    Instance.new("UICorner", targetEspFrame).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", targetEspFrame)
    stroke.Color = Color3.fromRGB(0, 150, 255)
    stroke.Thickness = 1

    local function mkLabel(text, yPos, size)
        local l = Instance.new("TextLabel", targetEspFrame)
        l.Size = UDim2.new(1, -10, 0, size or 22)
        l.Position = UDim2.new(0, 5, 0, yPos)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.new(1, 1, 1)
        l.Font = Enum.Font.GothamBold
        l.TextSize = size == 22 and 12 or 10
        l.TextXAlignment = Enum.TextXAlignment.Left
        return l
    end
    targetEspName = mkLabel("🎯 Target: None", 5, 22)
    targetEspDist = mkLabel("📏 Distance: --", 30, 18)
    targetEspHealth = mkLabel("❤️ Health: --", 52, 18)
    targetEspDist.TextColor3 = Color3.fromRGB(200, 200, 200)
    targetEspHealth.TextColor3 = Color3.fromRGB(200, 200, 200)
end

local function updateTargetEsp()
    if not targetEspEnabled then
        if targetEspFrame then targetEspFrame.Visible = false end
        return
    end
    if not targetEspFrame then createTargetEspFrame() end
    targetEspFrame.Visible = true
    local targetChar = nil
    if (PlayerWidgetActive and AimlockPlayerEnabled) or SilentAimPlayersEnabled then
        targetChar = getClosestPlayer()
    elseif SoruAimbotEnabled then
        if SelectedSoruTarget == "Nearest" then
            targetChar = getClosestPlayer()
        else
            local tp = Players:FindFirstChild(SelectedSoruTarget)
            if tp then targetChar = tp.Character end
        end
    end
    local targetPlayer = targetChar and Players:GetPlayerFromCharacter(targetChar)
    if targetPlayer and targetChar then
        local hum = targetChar:FindFirstChildOfClass("Humanoid")
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local dist = myHrp and (hrp.Position - myHrp.Position).Magnitude or 0
            targetEspName.Text = "🎯 " .. targetPlayer.Name
            targetEspDist.Text = string.format("📏 Distance: %.1f", dist)
            targetEspHealth.Text = string.format("❤️ Health: %.0f / %.0f", hum.Health, hum.MaxHealth)
            targetEspHealth.TextColor3 = (hum.Health / hum.MaxHealth < 0.3)
                and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
            return
        end
    end
    targetEspName.Text = "🎯 Target: None"
    targetEspDist.Text = "📏 Distance: --"
    targetEspHealth.Text = "❤️ Health: --"
end

task.spawn(function()
    while true do task.wait(0.3); if targetEspEnabled then updateTargetEsp() end end
end)

-- ============================================================
-- F4 TOGGLE MEJORADO
-- ============================================================
local uiScreen = nil

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.F4 then
        if uiScreen then
            uiScreen:Destroy()
            uiScreen = nil
        else
            uiScreen = CreateStandaloneUI()
        end
    end
end)

-- ============================================================
-- INICIALIZACIÓN
-- ============================================================
-- Esperar a que el juego esté completamente cargado
task.wait(2)

-- Crear UI por defecto
uiScreen = CreateStandaloneUI()

print("✅ Sacred UI V9.2 Standalone loaded successfully!")
print("📌 Presiona F4 para mostrar/ocultar la interfaz")
