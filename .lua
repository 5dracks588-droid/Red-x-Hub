local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = '<font color="rgb(200, 0, 0)">Muscle Legends | Red x Hub</font>',
    Icon = "crown",
    Author = '<font color="rgb(200, 0, 0)">RED</font>',
    Folder = "MuscleLegendsConfig",
    Size = UDim2.fromOffset(580,430),
    Transparent = false,
    Theme = "Crimson",
})

-- APLICAÇÃO DO WALLPAPER DENTRO DO MENU
pcall(function()
    local mainFrame = Window.UIElements and Window.UIElements.Main or Window.Frame or Window.Container
    
    if not mainFrame and Window.Root then
        mainFrame = Window.Root:FindFirstChildOfClass("Frame")
    end
    
    if mainFrame then
        mainFrame.BackgroundTransparency = 0.4
        
        local bgImage = Instance.new("ImageLabel")
        bgImage.Name = "MenuWallpaper"
        bgImage.Size = UDim2.fromScale(1, 1)
        bgImage.Position = UDim2.fromScale(0, 0)
        bgImage.Image = "rbxassetid://71388509379511" 
        bgImage.BackgroundTransparency = 1
        bgImage.ImageTransparency = 0
        bgImage.ScaleType = Enum.ScaleType.Crop
        bgImage.ZIndex = 1
        bgImage.Parent = mainFrame
    end
end)

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "rbxassetid://105346483918041",
    CornerRadius = UDim.new(0.5, 0),
    StrokeThickness = 2,
    Enabled = true,
    Draggable = true,
    OnlyMobile = false, 
    Color = ColorSequence.new(
        Color3.fromRGB(255, 0, 0), 
        Color3.fromRGB(200, 0, 0)
    ),
})

-- ──────────────────────────────────────────────────────────────────
-- 1. FUNÇÃO AUXILIAR DE FORMATAÇÃO DE NÚMEROS
-- ──────────────────────────────────────────────────────────────────
local function formatNumber(val)
    if not val then return "0" end
    
    local str = tostring(val):gsub(",", ".")
    local num = tonumber(str)
    if not num then return tostring(val) end

    local formattedInt = tostring(math.floor(math.abs(num)))
    local decimalPart = str:match("%.(%d+)")

    local k
    while true do
        formattedInt, k = string.gsub(formattedInt, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end

    if num < 0 then
        formattedInt = "-" .. formattedInt
    end

    if decimalPart then
        return formattedInt .. "." .. decimalPart
    else
        return formattedInt
    end
end

-- ──────────────────────────────────────────────────────────────────
-- 2. SERVIÇOS, VARIÁVEIS E CONSTANTES
-- ──────────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variáveis do Personagem
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

-- Configurações Gerais
local PARKED_POS = Vector3.new(10000, 1000, 10000)
local Flags = { AutoPunch = false }
local farmConfig = { autoWeight = false, autoSitups = false, autoPushups = false, autoHandstands = false }

-- Variáveis de Rebirth e TP Muscle King
local targetRebirths = 0
local autoRebirthTarget = false
local autoRebirthInfinite = false
local autoTpMuscleKing = false

-- Controles Internos
local activeRockLabel = nil
local lockConnection = nil
local punchContactOffset = 0
local rockData = {}
local rockToggles = {}
local isDead = false

-- Variáveis do Jogador
local Speed = 250
local Jump = 50
local InfiniteJump = false
local NoclipEnabled = false

-- Variáveis de Fly
local FlyEnabled = false
local FlySpeed = 150
local bodyVelocity, bodyGyro, flyConnection
local moveVector = Vector3.zero

-- Listas de Rebirth
local LISTA_1M = {
    "480 RB – 5 em 5", "1.480 RB – 10 em 10", "2.980 RB – 15 em 15", "4.980 RB – 20 em 20",
    "7.480 RB – 25 em 25", "10.480 RB – 30 em 30", "13.980 RB – 35 em 35", "17.980 RB – 40 em 40",
    "22.480 RB – 45 em 45", "27.480 RB – 50 em 50", "32.980 RB – 55 em 55", "38.980 RB – 60 em 60",
    "45.480 RB – 65 em 65", "52.480 RB – 70 em 70", "59.980 RB – 75 em 75", "67.980 RB – 80 em 80",
    "76.480 RB – 85 em 85", "85.480 RB – 90 em 90", "94.980 RB – 95 em 95",
}

local LISTA_5M = {
    "80 RB – 5 em 5", "220 RB – 8 em 8", "280 RB – 10 em 10", "580 RB – 15 em 15",
    "980 RB – 20 em 20", "1.480 RB – 25 em 25", "2.080 RB – 30 em 30", "2.780 RB – 35 em 35",
    "3.580 RB – 40 em 40", "4.480 RB – 45 em 45", "5.480 RB – 50 em 50", "6.580 RB – 55 em 55",
    "7.780 RB – 60 em 60", "9.080 RB – 65 em 65", "10.480 RB – 70 em 70", "11.980 RB – 75 em 75",
    "13.580 RB – 80 em 80", "15.280 RB – 85 em 85", "17.080 RB – 90 em 90", "18.980 RB – 95 em 95",
}

local LISTA_10M = {
    "52 RB – 5 em 5 (Pet 80 XP)", "208 RB – 10 em 10 (Pet 45 XP)", "440 RB – 15 em 15 (Pet 5 XP)",
    "748 RB – 20 em 20 (Pet 20 XP)", "1.132 RB – 25 em 25 (Pet 30 XP)", "1.592 RB – 30 em 30 (Pet 55 XP)",
    "2.132 RB – 35 em 35 (Pet 30 XP)", "2.748 RB – 40 em 40 (Pet 20 XP)", "3.440 RB – 45 em 45 (Pet 25 XP)",
    "4.208 RB – 50 em 50 (Pet 45 XP)", "5.056 RB – 55 em 55 (Pet 15 XP)", "5.980 RB – 60 em 60 (Pet 0 XP)",
    "6.980 RB – 65 em 65 (Pet 0 XP)", "8.056 RB – 70 em 70 (Pet 15 XP)", "9.208 RB – 75 em 75 (Pet 45 XP)",
    "10.440 RB – 80 em 80 (Pet 25 XP)", "11.748 RB – 85 em 85 (Pet 25 XP)", "13.132 RB – 90 em 90 (Pet 30 XP)",
    "14.592 RB – 95 em 95 (Pet 55 XP)",
}

local ROCKS = {
    { label = "Ancient Jungle Rock 10M", useCoord = false, names = {"Ancient Jungle Rock","AncientJungleRock","Jungle Rock","JungleRock","Rocha da Selva Antiga","Ancient Rock"}, durability = "10M", minSize = 6 },
    { label = "Muscle King Mountain 5M", useCoord = false, names = {"Muscle King Mountain","MuscleKingMountain","Muscle King Rock","MuscleKingRock","King Mountain"}, durability = "5M", minSize = 6 },
    { label = "Stone of Legends 1M", useCoord = true, targetPos = Vector3.new(4147.9, 1006.4, -4106.0), names = {"Stone of Legends","StoneOfLegends","Stone Of Legends","Rock","Stone","Boulder"}, durability = "1M", minSize = 1 },
    { label = "Inferno Rock 750K", useCoord = true, targetPos = Vector3.new(-7256, 18, -1261), names = {"Inferno Rock","InfernoRock","Inferno","FireRock","Fire Rock"}, durability = "750K", minSize = 3 },
    { label = "Mystic Rock 400K", useCoord = true, targetPos = Vector3.new(2190, 15, 1251), names = {"Mystic Rock","MysticRock","Mystic","Magic Rock","MagicRock"}, durability = "400K", minSize = 3 },
    { label = "Frozen Rock 150K", useCoord = true, targetPos = Vector3.new(-2559, 13, -253), names = {"Frozen Rock","FrozenRock","Frozen","Ice Rock","IceRock","Frost Rock"}, durability = "150K", minSize = 3 },
    { label = "Golden Rock 5K", useCoord = true, targetPos = Vector3.new(307, 15, -582), names = {"Golden Rock","GoldenRock","Gold Rock","GoldRock","Golden"}, durability = "5K", minSize = 2 },
    { label = "Large Rock 100", useCoord = true, targetPos = Vector3.new(168, 3, -147), names = {"Large Rock","LargeRock","Large","Big Rock","BigRock"}, durability = "100", minSize = 2 },
    { label = "Punching Rock 10", useCoord = true, targetPos = Vector3.new(-153, 6, 418), names = {"Punching Rock","PunchingRock","Punching","Punch Rock"}, durability = "10", minSize = 1 },
    { label = "Tyni Rock 0", useCoord = true, targetPos = Vector3.new(16, 5, 2105), names = {"Tyni Rock","TyniRock","Tyni","Tinha Rock","TinhaRock","Tiny Rock","TinyRock"}, durability = "0", minSize = 1 },
}

local BLACKLIST = {
    "crystal","crystals","egg","eggs","pet","pets","aura","spin","wheel","portal","teleport","npc",
    "zone","pad","button","gui","billboard","sign","coin","gem","diamond","orb","ring","vip","donate",
    "shop","store","character","humanoidrootpart","head","torso","baseplate","terrain","camera","anoleg_rock_clone",
}

-- ──────────────────────────────────────────────────────────────────
-- 3. FUNÇÕES BASE E LÓGICA DO JOGO
-- ──────────────────────────────────────────────────────────────────

local function isBlacklisted(name)
    local low = name:lower()
    for _, w in ipairs(BLACKLIST) do if low == w or low:find(w, 1, true) then return true end end
    return false
end

local function getObjPos(obj)
    local p = nil
    pcall(function()
        if obj:IsA("BasePart") then p = obj.Position
        elseif obj:IsA("Model") then p = obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetBoundingBox().Position end
    end)
    return p
end

local function getObjSize(obj)
    local s = Vector3.new(8,8,8)
    pcall(function()
        if obj:IsA("BasePart") then s = obj.Size
        elseif obj:IsA("Model") then local _, b = obj:GetBoundingBox(); s = b end
    end)
    return s.Magnitude > 0 and s or Vector3.new(8,8,8)
end

local function getAllParts(obj)
    local parts = {}
    if obj:IsA("BasePart") then table.insert(parts, obj)
    elseif obj:IsA("Model") then
        for _, v in ipairs(obj:GetDescendants()) do if v:IsA("BasePart") then table.insert(parts, v) end end
    end
    return parts
end

local function isValidObj(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    if isBlacklisted(obj.Name) or obj.Name == "ANOLEG_ROCK_CLONE" then return false end
    for _, p in ipairs(Players:GetPlayers()) do if p.Character and obj:IsDescendantOf(p.Character) then return false end end
    return true
end

local function getPunchTool()
    for _, name in ipairs({"Punch","PunchTool","Fist","Glove","Boxing Gloves","Punching Gloves"}) do
        local t = LP.Backpack:FindFirstChild(name) or (Character and Character:FindFirstChild(name))
        if t then return t end
    end
    for _, v in ipairs(LP.Backpack:GetChildren()) do if v:IsA("Tool") then return v end end
    return nil
end

local function isPunchTool(tool)
    if not tool then return false end
    local low = tool.Name:lower()
    for _, n in ipairs({"punch","punchtool","fist","glove","boxing"}) do if low:find(n, 1, true) then return true end end
    return false
end

local function unequipTool(toolName)
    local char = LP.Character
    if char then
        local tool = char:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then tool.Parent = LP.Backpack end
    end
end

local function doRebirth()
    pcall(function()
        ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
    end)
end

local function StopFly()
    FlyEnabled = false
    if Humanoid then Humanoid.PlatformStand = false end
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if bodyVelocity then bodyVelocity:Destroy(); bodyGyro = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
end

local function StartFly()
    if FlyEnabled then return end
    FlyEnabled = true
    if Humanoid then Humanoid.PlatformStand = true end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = HRP

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 100000
    bodyGyro.CFrame = Camera.CFrame
    bodyGyro.Parent = HRP

    flyConnection = RunService.RenderStepped:Connect(function()
        local camCF = Camera.CFrame
        local forward = camCF.LookVector
        local right = camCF.RightVector

        local direction = Vector3.zero
        direction += forward * moveVector.Z
        direction += right * (moveVector.X * 0.45)

        if direction.Magnitude > 0 then bodyVelocity.Velocity = direction.Unit * FlySpeed else bodyVelocity.Velocity = Vector3.zero end
        bodyGyro.CFrame = CFrame.new(HRP.Position, HRP.Position + Camera.CFrame.LookVector)
    end)
end

-- ──────────────────────────────────────────────────────────────────
-- SETUP DE CHARACTER
-- ──────────────────────────────────────────────────────────────────
local function SetupCharacter(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid", 10)
    HRP = newChar:WaitForChild("HumanoidRootPart", 10)
    isDead = false
    
    if Humanoid then
        Humanoid.Died:Connect(function()
            isDead = true
            StopFly()
            HRP = nil
            pcall(function()
                local tool = Character:FindFirstChildWhichIsA("Tool")
                if tool then tool.Parent = LP.Backpack end
            end)
        end)
    end
    
    if Flags.AutoPunch then
        task.wait(0.05)
        local tool = getPunchTool()
        if tool and tool.Parent == LP.Backpack then tool.Parent = Character end
    end
end

LP.CharacterAdded:Connect(SetupCharacter)
if LP.Character then task.spawn(SetupCharacter, LP.Character) end

local function findRealRock(entry)
    local best, bestDist, bestScore = nil, math.huge, -1
    for _, obj in ipairs(workspace:GetDescendants()) do
        if not isValidObj(obj) then continue end
        
        if entry.useCoord then
            local pos = getObjPos(obj)
            if pos then
                local dist = (pos - entry.targetPos).Magnitude
                if dist < bestDist then bestDist = dist; best = obj end
            end
        else
            local size = getObjSize(obj)
            if math.min(size.X, size.Y, size.Z) < (entry.minSize or 5) then continue end
            local objLow, matchScore = obj.Name:lower(), 0
            for _, name in ipairs(entry.names) do
                local nameLow = name:lower()
                if objLow == nameLow then return obj end
                if objLow:find(nameLow, 1, true) and #nameLow > matchScore then matchScore = #nameLow end
            end
            if matchScore > bestScore then bestScore = matchScore; best = obj end
        end
    end
    if entry.useCoord then return (bestDist < 100) and best or nil else return best end
end

local function pivotCloneTo(data, pos)
    local clone = data.cloneObj
    if not clone or not clone.Parent then return end
    local cf = CFrame.new(pos)
    if clone:IsA("Model") and clone.PrimaryPart then pcall(function() clone:PivotTo(cf) end)
    elseif clone:IsA("BasePart") then pcall(function() clone.CFrame = cf end)
    else for _, part in ipairs(data.cloneParts) do pcall(function() part.CFrame = cf end) end end
end

local function createCloneForEntry(entry)
    local real = findRealRock(entry)
    if not real then return nil end
    for _, p in ipairs(getAllParts(real)) do pcall(function() sethiddenproperty(p, "Locked", false) end) end
    local clone = nil
    pcall(function() clone = real:Clone() end)
    if not clone then
        clone = Instance.new("Part")
        clone.Size = getObjSize(real)
        clone.CFrame = CFrame.new(PARKED_POS)
    end
    clone.Name, clone.Parent = "ANOLEG_ROCK_CLONE", workspace
    local parts = getAllParts(clone)
    
    for _, part in ipairs(parts) do
        pcall(function()
            part.CanCollide, part.CanTouch, part.CanQuery, part.Anchored = false, false, false, true
            part.CastShadow, part.Transparency = false, 1
            part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
        end)
    end
    for _, child in ipairs(clone:GetDescendants()) do
        if child:IsA("Decal") or child:IsA("Texture") or child:IsA("ParticleEmitter") or child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
            pcall(function() child:Destroy() end)
        end
    end
    
    if clone:IsA("Model") and not clone.PrimaryPart then clone.PrimaryPart = parts[1] end
    local data = { cloneObj = clone, cloneParts = parts, realRock = real, label = entry.label }
    pivotCloneTo(data, PARKED_POS)
    return data
end

local function calcFrontPos(data)
    if not HRP then return PARKED_POS end
    local rockSize = getObjSize(data.realRock)
    local halfDepth = math.clamp(math.min(rockSize.X, rockSize.Z) / 2, 0, 15)
    local flatLook = Vector3.new(HRP.CFrame.LookVector.X, 0, HRP.CFrame.LookVector.Z)
    flatLook = flatLook.Magnitude < 0.001 and Vector3.new(0,0,-1) or flatLook.Unit
    local dist = halfDepth + punchContactOffset
    return Vector3.new(HRP.Position.X + flatLook.X * dist, HRP.Position.Y, HRP.Position.Z + flatLook.Z * dist)
end

local function touchRealRock(data)
    if not data or not data.realRock or not HRP then return end
    for _, part in ipairs(getAllParts(data.realRock)) do
        pcall(function() firetouchinterest(HRP, part, 0); firetouchinterest(HRP, part, 1) end)
        pcall(function()
            local arm = Character:FindFirstChild("Right Arm") or Character:FindFirstChild("RightHand") or Character:FindFirstChild("RightLowerArm")
            if arm then firetouchinterest(arm, part, 0); firetouchinterest(arm, part, 1) end
        end)
    end
end

local function stopActiveRock()
    if lockConnection then lockConnection:Disconnect(); lockConnection = nil end
    if activeRockLabel and rockData[activeRockLabel] then pivotCloneTo(rockData[activeRockLabel], PARKED_POS) end
    activeRockLabel = nil
end

local function activateRock(label)
    stopActiveRock()
    local data = rockData[label]
    if not data then return end
    activeRockLabel = label
    pivotCloneTo(data, calcFrontPos(data))
    lockConnection = RunService.RenderStepped:Connect(function()
        if activeRockLabel ~= label or isDead or not HRP then lockConnection:Disconnect(); return end
        pivotCloneTo(data, calcFrontPos(data))
    end)
    task.spawn(function() while activeRockLabel == label do task.wait(0.02); if not isDead then touchRealRock(data) end end end)
end

local function deactivateRock(label)
    if activeRockLabel == label then stopActiveRock() end
end

local function findValueDeep(parent, name)
    if parent:IsA("Player") then
        local leaderstats = parent:FindFirstChild("leaderstats")
        if leaderstats then
            local stat = leaderstats:FindFirstChild(name) or leaderstats:FindFirstChild(name:lower()) or leaderstats:FindFirstChild(name:sub(1,1):upper() .. name:sub(2):lower())
            if stat and stat:IsA("ValueBase") then return stat.Value end
        end
    end
    local found = parent:FindFirstChild(name, true)
    if found and found:IsA("ValueBase") then return found.Value end
    for _, child in ipairs(parent:GetDescendants()) do
        if child.Name:lower() == name:lower() and child:IsA("ValueBase") then return child.Value end
    end
    return nil
end

-- ──────────────────────────────────────────────────────────────────
-- 4. CONSTRUÇÃO DAS ABAS (TABS DA INTERFACE)
-- ──────────────────────────────────────────────────────────────────

-- ABA: INFO
local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })
InfoTab:Dropdown({ Title = "Lista de Rebirth 10M", Values = LISTA_10M, Value = LISTA_10M[1], Callback = function(v) end })
InfoTab:Dropdown({ Title = "Lista de Rebirth 5M", Values = LISTA_5M, Value = LISTA_5M[1], Callback = function(v) end })
InfoTab:Dropdown({ Title = "Lista de Rebirth 1M", Values = LISTA_1M, Value = LISTA_1M[1], Callback = function(v) end })

local pingBtn = InfoTab:Button({ Title = "Ping: 0 ms" })
local fpsBtn = InfoTab:Button({ Title = "FPS: 0" })
local serverBtn = InfoTab:Button({ Title = "Server: 0s" })

task.spawn(function()
    local Stats = game:GetService("Stats")
    local frameCount = 0
    local lastTime = tick()
    local currentFps = 60

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 1 then
            currentFps = frameCount
            frameCount = 0
            lastTime = now
        end
    end)

    while task.wait(1) do
        pcall(function()
            local pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            pingBtn:SetTitle("Ping: " .. pingVal .. " ms")
            fpsBtn:SetTitle("FPS: " .. currentFps)

            local uptime = math.floor(workspace.DistributedGameTime)
            local hours = math.floor(uptime / 3600)
            local mins = math.floor((uptime % 3600) / 60)
            local secs = uptime % 60
            serverBtn:SetTitle(string.format("Time: %02dh %02dm %02ds", hours, mins, secs))
        end)
    end
end)

-- ABA: STATS
local StatsTab = Window:Tab({ Title = "Stats", Icon = "activity"})
local myStr = StatsTab:Button({Title = "Força: 0"})
local myDur = StatsTab:Button({Title = "Durabilidade: 0"})
local myAgi = StatsTab:Button({Title = "Agilidade: 0"})
local myKil = StatsTab:Button({Title = "Kills: 0"})
local myReb = StatsTab:Button({Title = "Rebirths: 0"})

task.spawn(function()
    while task.wait(0.05) do
        if LP then
            pcall(function()
                myStr:SetTitle("Força: " .. formatNumber(findValueDeep(LP, "Strength") or 0))
                myDur:SetTitle("Durabilidade: " .. formatNumber(findValueDeep(LP, "Durability") or 0))
                myAgi:SetTitle("Agilidade: " .. formatNumber(findValueDeep(LP, "Agility") or 0))
                myKil:SetTitle("Kills: " .. formatNumber(findValueDeep(LP, "Kills") or 0))
                myReb:SetTitle("Rebirths: " .. formatNumber(findValueDeep(LP, "Rebirths") or 0))
            end)
        end
    end
end)

-- CONTROLADORES DE SINCRONIZAÇÃO
local ToggleW, ToggleW_Rebirth, ToggleS, ToggleP, ToggleH
local isUpdatingWeight = false

local function updateWeightState(Value)
    if isUpdatingWeight then return end
    isUpdatingWeight = true
    
    farmConfig.autoWeight = Value
    if ToggleW then pcall(function() ToggleW:Set(Value) end) end
    if ToggleW_Rebirth then pcall(function() ToggleW_Rebirth:Set(Value) end) end
    
    if Value then
        farmConfig.autoSitups = false; if ToggleS then pcall(function() ToggleS:Set(false) end) end
        farmConfig.autoPushups = false; if ToggleP then pcall(function() ToggleP:Set(false) end) end
        farmConfig.autoHandstands = false; if ToggleH then pcall(function() ToggleH:Set(false) end) end
    else
        unequipTool("Weight")
    end
    
    isUpdatingWeight = false
end

-- ABA: AUTO FARM
local FarmTab = Window:Tab({ Title = "Auto Farm", Icon = "dumbbell" })
local lockPos

ToggleW = FarmTab:Toggle({ Title = "Auto Weight", Value = false, Callback = function(Value)
    updateWeightState(Value)
end})

ToggleS = FarmTab:Toggle({ Title = "Auto Situps", Value = false, Callback = function(Value)
    farmConfig.autoSitups = Value
    if Value then farmConfig.autoWeight = false; if ToggleW then ToggleW:Set(false) end; if ToggleW_Rebirth then ToggleW_Rebirth:Set(false) end; farmConfig.autoPushups = false; if ToggleP then ToggleP:Set(false) end; farmConfig.autoHandstands = false; if ToggleH then ToggleH:Set(false) end else unequipTool("Situps") end
end})

ToggleP = FarmTab:Toggle({ Title = "Auto Pushups", Value = false, Callback = function(Value)
    farmConfig.autoPushups = Value
    if Value then farmConfig.autoWeight = false; if ToggleW then ToggleW:Set(false) end; if ToggleW_Rebirth then ToggleW_Rebirth:Set(false) end; farmConfig.autoSitups = false; if ToggleS then ToggleS:Set(false) end; farmConfig.autoHandstands = false; if ToggleH then ToggleH:Set(false) end else unequipTool("Pushups") end
end})

ToggleH = FarmTab:Toggle({ Title = "Auto Handstands", Value = false, Callback = function(Value)
    farmConfig.autoHandstands = Value
    if Value then farmConfig.autoWeight = false; if ToggleW then ToggleW:Set(false) end; if ToggleW_Rebirth then ToggleW_Rebirth:Set(false) end; farmConfig.autoSitups = false; if ToggleS then ToggleS:Set(false) end; farmConfig.autoPushups = false; if ToggleP then ToggleP:Set(false) end else unequipTool("Handstands") end
end})

FarmTab:Toggle({ Title = "Lock Position", Value = false, Callback = function(Value)
    if Value then
        if HRP then lockPos = HRP.CFrame end
        task.spawn(function()
            while lockPos do
                task.wait(0.1)
                pcall(function() if Character and HRP then HRP.CFrame = lockPos end end)
            end
        end)
    else lockPos = nil end
end})

-- ABA: REBIRTH
local RebirthTab = Window:Tab({ Title = "Rebirth", Icon = "repeat" })

RebirthTab:Input({
    Title = "Rebirth Target",
    Placeholder = "",
    Callback = function(text)
        local num = tonumber(text)
        if num then targetRebirths = num end
    end
})

RebirthTab:Toggle({
    Title = "Auto rebirth target",
    Value = false,
    Callback = function(v) autoRebirthTarget = v end
})

RebirthTab:Toggle({
    Title = "Auto Rebirth Infinite",
    Value = false,
    Callback = function(v) autoRebirthInfinite = v end
})

ToggleW_Rebirth = RebirthTab:Toggle({
    Title = "Auto Weight",
    Value = false,
    Callback = function(Value) updateWeightState(Value) end
})

RebirthTab:Toggle({
    Title = "Auto TP Muscle King",
    Value = false,
    Callback = function(v) autoTpMuscleKing = v end
})

local KillerTab = Window:Tab({ Title = "Killer", Icon = "skull" })

KillerTab:Toggle({ Title = "Kill Aura", Value = false, Callback = function(v)
    AutoKillEveryone = v
    Flags.AutoPunch = v
    
    if v then
        local tool = getPunchTool()
        if tool and tool.Parent == LP.Backpack then tool.Parent = Character end
    else
        pcall(function()
            local equipped = Character:FindFirstChildWhichIsA("Tool")
            if equipped and isPunchTool(equipped) then equipped.Parent = LP.Backpack end
        end)
    end
end})

-- ABA: JOGADOR
local PlayerTab = Window:Tab({ Title = "Jogador", Icon = "user" })
PlayerTab:Input({ Title = "Velocidade", Placeholder = "250", Callback = function(text) local num = tonumber(text); if num then Speed = num end end })
PlayerTab:Input({ Title = "Pulo", Placeholder = "50", Callback = function(text) local num = tonumber(text); if num then Jump = num end end })
PlayerTab:Toggle({ Title = "Pulo Infinito", Value = false, Callback = function(v) InfiniteJump = v end })
PlayerTab:Toggle({ Title = "NoClip", Value = false, Callback = function(v) NoclipEnabled = v end })
PlayerTab:Toggle({ Title = "Fly", Value = false, Callback = function(v) if v then StartFly() else StopFly() end end })
PlayerTab:Slider({ Title = "Fly Speed", Step = 5, Value = { Min = 10, Max = 500, Default = 150 }, Callback = function(v) FlySpeed = v end })

-- ABA: TELEPORTS
local TeleportTab = Window:Tab({ Title = "Teleports", Icon = "map-pin" })
local function teleportTo(pos) pcall(function() if Character and HRP then HRP.CFrame = CFrame.new(pos) end end) end
TeleportTab:Button({Title = "Starting Island", Callback = function() teleportTo(Vector3.new(151, 50, 294)) end})
TeleportTab:Button({Title = "Jungle Island", Callback = function() teleportTo(Vector3.new(-8686, 153, 2392)) end})
TeleportTab:Button({Title = "Muscle King Island", Callback = function() teleportTo(Vector3.new(-8626, 115, -5731)) end})
TeleportTab:Button({Title = "Legends Island", Callback = function() teleportTo(Vector3.new(4602, 1009, -3898)) end})
TeleportTab:Button({Title = "Flaming Island", Callback = function() teleportTo(Vector3.new(-6760, 28, -1285)) end})
TeleportTab:Button({Title = "Mystic Island", Callback = function() teleportTo(Vector3.new(2250, 28, 1073)) end})
TeleportTab:Button({Title = "Frozen Island", Callback = function() teleportTo(Vector3.new(-2624, 28, -410)) end})
TeleportTab:Button({Title = "Tiny Island", Callback = function() teleportTo(Vector3.new(-36, 15, 1889)) end})
TeleportTab:Button({Title = "Secret Island", Callback = function() teleportTo(Vector3.new(1951, 21, 6185)) end})

-- ABA: MISC
local MiscTab = Window:Tab({ Title = "Misc", Icon = "users" })
local selectedPlayerObj = nil
local function GetPlayerNames() local names = {"None"}; for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(names, p.Name) end end; return names end

local btnStrength = MiscTab:Button({Title = "Força: -"})
local btnDurability = MiscTab:Button({Title = "Durabilidade: -"})
local btnRebirths = MiscTab:Button({Title = "Rebirths: -"})
local btnAgility = MiscTab:Button({Title = "Agilidade: -"})
local btnKills = MiscTab:Button({Title = "Kills: -"})

local function updatePlayerStatsDisplay()
    if not selectedPlayerObj or selectedPlayerObj == "None" then
        btnStrength:SetTitle("Força: -"); btnDurability:SetTitle("Durabilidade: -"); btnRebirths:SetTitle("Rebirths: -"); btnAgility:SetTitle("Agilidade: -"); btnKills:SetTitle("Kills: -"); return
    end
    local p = Players:FindFirstChild(selectedPlayerObj)
    if p then
        pcall(function()
            btnStrength:SetTitle("Força: " .. formatNumber(findValueDeep(p, "Strength") or 0))
            btnDurability:SetTitle("Durabilidade: " .. formatNumber(findValueDeep(p, "Durability") or 0))
            btnRebirths:SetTitle("Rebirths: " .. formatNumber(findValueDeep(p, "Rebirths") or 0))
            btnAgility:SetTitle("Agilidade: " .. formatNumber(findValueDeep(p, "Agility") or 0))
            btnKills:SetTitle("Kills: " .. formatNumber(findValueDeep(p, "Kills") or 0))
        end)
    else selectedPlayerObj = "None" end
end

local PlayerDropdown = MiscTab:Dropdown({ Title = "Selecionar Jogador", Values = GetPlayerNames(), Value = "None", Callback = function(v) selectedPlayerObj = v; updatePlayerStatsDisplay() end })
MiscTab:Button({ Title = "Atualizar Lista", Callback = function()
    PlayerDropdown:Refresh(GetPlayerNames())
    PlayerDropdown:Set("None")
    selectedPlayerObj = "None"
    updatePlayerStatsDisplay()
end})

-- ESPECTAR JOGADOR
local isSpectating = false

MiscTab:Toggle({ 
    Title = "Espectar Jogador", 
    Value = false, 
    Callback = function(Value)
        isSpectating = Value
        
        if not Value then
            if LP.Character and LP.Character:FindFirstChild("Humanoid") then
                workspace.CurrentCamera.CameraSubject = LP.Character.Humanoid
            end
        else
            task.spawn(function()
                while isSpectating do
                    task.wait(0.1)
                    
                    if selectedPlayerObj and selectedPlayerObj ~= "None" then
                        local alvo = Players:FindFirstChild(selectedPlayerObj)
                        if alvo and alvo.Character then
                            local alvoHum = alvo.Character:FindFirstChild("Humanoid")
                            if alvoHum then
                                workspace.CurrentCamera.CameraSubject = alvoHum
                            end
                        end
                    else
                        if LP.Character and LP.Character:FindFirstChild("Humanoid") then
                            workspace.CurrentCamera.CameraSubject = LP.Character.Humanoid
                        end
                    end
                end
                
                if LP.Character and LP.Character:FindFirstChild("Humanoid") then
                    workspace.CurrentCamera.CameraSubject = LP.Character.Humanoid
                end
            end)
        end
    end 
})

-- MODO LEVE / FPS BOOST
local modoLeveAtivo = false
local conexaoEfeitos = nil

MiscTab:Toggle({
    Title = "Modo Leve",
    Value = false,
    Callback = function(Value)
        modoLeveAtivo = Value
        local Lighting = game:GetService("Lighting")
        
        if Value then
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") then
                        effect.Enabled = false
                    end
                end
            end)

            local function otimizarObjeto(obj)
                if obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") or obj:IsA("Smoke") or obj:IsA("Fire") then
                    obj.Enabled = false
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 1
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    if obj.Material == Enum.Material.Neon then
                        obj.Material = Enum.Material.SmoothPlastic
                    end
                end
            end

            for _, obj in ipairs(workspace:GetDescendants()) do
                pcall(otimizarObjeto, obj)
            end

            conexaoEfeitos = workspace.DescendantAdded:Connect(function(obj)
                if modoLeveAtivo then
                    pcall(otimizarObjeto, obj)
                end
            end)
        else
            if conexaoEfeitos then
                conexaoEfeitos:Disconnect()
                conexaoEfeitos = nil
            end
            
            pcall(function()
                Lighting.GlobalShadows = true
            end)
        end
    end
})

-- ABA: AUTO ROCKS
local CombateTab = Window:Tab({ Title = "Auto Rocks", Icon = "mountain" })
CombateTab:Toggle({ Title = "Auto Soco", Value = false, Callback = function(v)
    Flags.AutoPunch = v
    if v then
        local tool = getPunchTool()
        if tool and tool.Parent == LP.Backpack then tool.Parent = Character end
    else
        pcall(function()
            local equipped = Character:FindFirstChildWhichIsA("Tool")
            if equipped and isPunchTool(equipped) then equipped.Parent = LP.Backpack end
        end)
    end
end})

for _, entry in ipairs(ROCKS) do
    local lbl = entry.label
    rockToggles[lbl] = CombateTab:Toggle({
        Title = lbl, Value = false, Callback = function(v)
            if v then
                if activeRockLabel and activeRockLabel ~= lbl then
                    local prevToggle = rockToggles[activeRockLabel]
                    if prevToggle then pcall(function() prevToggle:Set(false) end) end
                end
                activateRock(lbl)
            else deactivateRock(lbl) end
        end,
    })
end

-- ──────────────────────────────────────────────────────────────────
-- 5. LOOPS E CONEXÕES DE EVENTOS
-- ──────────────────────────────────────────────────────────────────

-- LOOP DO AUTO REBIRTH
task.spawn(function()
    while task.wait(0.1) do
        if autoRebirthInfinite then
            doRebirth()
        elseif autoRebirthTarget then
            local currentRebirths = tonumber(findValueDeep(LP, "Rebirths")) or 0
            if currentRebirths < targetRebirths then
                doRebirth()
            end
        end
    end
end)

-- LOOP DO AUTO TP MUSCLE KING
task.spawn(function()
    while task.wait(0.25) do
        if autoTpMuscleKing then
            pcall(function()
                if Character and HRP and Humanoid and Humanoid.Health > 0 then
                    HRP.CFrame = CFrame.new(-8626, 17, -5731)
                end
            end)
        end
    end
end)

-- LOOP DO KILL EVERYONE
task.spawn(function()
    local targetIndex = 1
    
    while task.wait(0.05) do
        if AutoKillEveryone and Character and Humanoid and Humanoid.Health > 0 then
            local arm = Character:FindFirstChild("Right Arm") or Character:FindFirstChild("RightHand") or Character:FindFirstChild("RightLowerArm")
            
            if arm then
                local validTargets = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP then
                        local pChar = p.Character
                        if pChar and pChar:FindFirstChild("HumanoidRootPart") and pChar:FindFirstChild("Humanoid") and pChar.Humanoid.Health > 0 then
                            if not pChar:FindFirstChildOfClass("ForceField") then
                                table.insert(validTargets, p)
                            end
                        end
                    end
                end

                if #validTargets > 0 then
                    if targetIndex > #validTargets then 
                        targetIndex = 1 
                    end
                    
                    local currentTarget = validTargets[targetIndex]
                    if currentTarget and currentTarget.Character then
                        local targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
                        local targetHum = currentTarget.Character:FindFirstChild("Humanoid")
                        
                        if targetRoot and targetHum and targetHum.Health > 0 then
                            local startTime = tick()
                            while (tick() - startTime) < 0.2 and AutoKillEveryone and Character and Humanoid and Humanoid.Health > 0 and targetHum.Health > 0 do
                                pcall(function()
                                    firetouchinterest(arm, targetRoot, 0)
                                    firetouchinterest(arm, targetRoot, 1)
                                end)
                                task.wait(0.02)
                            end
                        end
                    end
                    
                    targetIndex = targetIndex + 1
                end
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then moveVector = Vector3.new(moveVector.X, 0, -1)
    elseif input.KeyCode == Enum.KeyCode.S then moveVector = Vector3.new(moveVector.X, 0, 1)
    elseif input.KeyCode == Enum.KeyCode.A then moveVector = Vector3.new(-1, 0, moveVector.Z)
    elseif input.KeyCode == Enum.KeyCode.D then moveVector = Vector3.new(1, 0, moveVector.Z) end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then moveVector = Vector3.new(moveVector.X, 0, 0)
    elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then moveVector = Vector3.new(0, 0, moveVector.Z) end
end)

UserInputService.JumpRequest:Connect(function()
    if InfiniteJump and Character and Humanoid and Humanoid.Health > 0 then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

RunService.RenderStepped:Connect(function()
    if Character and Humanoid and HRP and Humanoid.Health > 0 then
        if NoclipEnabled then for _, part in pairs(Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
        if Speed ~= 16 then Humanoid.WalkSpeed = Speed end
        if Jump ~= 50 then Humanoid.JumpPower = Jump end
        
        local moveDir = Humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local relative = Camera.CFrame:VectorToObjectSpace(moveDir)
            moveVector = Vector3.new(relative.X, 0, -relative.Z)
        else
            if not (UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D)) then moveVector = Vector3.zero end
        end
    end
end)

-- LOOP DE FARM (PESTOS / EXERCÍCIOS)
task.spawn(function()
    while task.wait(0.1) do
        if Character and Character:FindFirstChild("HumanoidRootPart") and Humanoid and Humanoid.Health > 0 then
            if farmConfig.autoWeight then local t = LP.Backpack:FindFirstChild("Weight") or Character:FindFirstChild("Weight"); if t then if t.Parent ~= Character then t.Parent = Character end; pcall(function() LP.muscleEvent:FireServer("rep") end) end end
            if farmConfig.autoSitups then local t = LP.Backpack:FindFirstChild("Situps") or Character:FindFirstChild("Situps"); if t then if t.Parent ~= Character then t.Parent = Character end; pcall(function() LP.muscleEvent:FireServer("rep") end) end end
            if farmConfig.autoPushups then local t = LP.Backpack:FindFirstChild("Pushups") or Character:FindFirstChild("Pushups"); if t then if t.Parent ~= Character then t.Parent = Character end; pcall(function() LP.muscleEvent:FireServer("rep") end) end end
            if farmConfig.autoHandstands then local t = LP.Backpack:FindFirstChild("Handstands") or Character:FindFirstChild("Handstands"); if t then if t.Parent ~= Character then t.Parent = Character end; pcall(function() LP.muscleEvent:FireServer("rep") end) end end
        end
    end
end)

-- LOOP DE AUTO SOCO
task.spawn(function()
    while task.wait(0.1) do
        if Flags.AutoPunch and not isDead and Character and Humanoid and Humanoid.Health > 0 then
            pcall(function()
                LP.muscleEvent:FireServer("punch", "RightHand")
                LP.muscleEvent:FireServer("punch", "LeftHand")
            end)
        end
    end
end)

task.spawn(function() while task.wait(1) do updatePlayerStatsDisplay() end end)

task.spawn(function()
    for _, entry in ipairs(ROCKS) do
        local data = createCloneForEntry(entry)
        if data then rockData[entry.label] = data end
        task.wait()
    end
end)

