local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local PARKED_POS = Vector3.new(10000, 1000, 10000)
local Flags = { AutoPunch = false }
local activeRockLabel = nil
local lockConnection = nil
local punchContactOffset = 0
local rockData = {}
local rockToggles = {}
local isDead = false

local ROCKS = {
    {
        label = "Ancient Jungle Rock 10M", useCoord = false,
        names = {"Ancient Jungle Rock","AncientJungleRock","Jungle Rock","JungleRock","Rocha da Selva Antiga","Ancient Rock"},
        durability = "10.000.000", minSize = 6,
    },
    {
        label = "Muscle King Mountain 5M", useCoord = false,
        names = {"Muscle King Mountain","MuscleKingMountain","Muscle King Rock","MuscleKingRock","King Mountain"},
        durability = "5.000.000", minSize = 6,
    },
    {
        label = "Stone of Legends 1M", useCoord = true,
        targetPos = Vector3.new(4147.9, 1006.4, -4106.0),
        names = {"Stone of Legends","StoneOfLegends","Stone Of Legends","Rock","Stone","Boulder"},
        durability = "1.000.000", minSize = 1,
    },
    {
        label = "Inferno Rock 750K", useCoord = true,
        targetPos = Vector3.new(-7256, 18, -1261),
        names = {"Inferno Rock","InfernoRock","Inferno","FireRock","Fire Rock"},
        durability = "750.000", minSize = 3,
    },
    {
        label = "Mystic Rock 400K", useCoord = true,
        targetPos = Vector3.new(2190, 15, 1251),
        names = {"Mystic Rock","MysticRock","Mystic","Magic Rock","MagicRock"},
        durability = "400.000", minSize = 3,
    },
    {
        label = "Frozen Rock 150K", useCoord = true,
        targetPos = Vector3.new(-2559, 13, -253),
        names = {"Frozen Rock","FrozenRock","Frozen","Ice Rock","IceRock","Frost Rock"},
        durability = "150.000", minSize = 3,
    },
    {
        label = "Golden Rock 5K", useCoord = true,
        targetPos = Vector3.new(307, 15, -582),
        names = {"Golden Rock","GoldenRock","Gold Rock","GoldRock","Golden"},
        durability = "5.000", minSize = 2,
    },
    {
        label = "Large Rock 100", useCoord = true,
        targetPos = Vector3.new(168, 3, -147),
        names = {"Large Rock","LargeRock","Large","Big Rock","BigRock"},
        durability = "100", minSize = 2,
    },
    {
        label = "Punching Rock 10", useCoord = true,
        targetPos = Vector3.new(-153, 6, 418),
        names = {"Punching Rock","PunchingRock","Punching","Punch Rock"},
        durability = "10", minSize = 1,
    },
    {
        label = "Tyni Rock 0", useCoord = true,
        targetPos = Vector3.new(16, 5, 2105),
        names = {"Tyni Rock","TyniRock","Tyni","Tinha Rock","TinhaRock","Tiny Rock","TinyRock"},
        durability = "0", minSize = 1,
    },
}

local BLACKLIST = {
    "crystal","crystals","egg","eggs","pet","pets","aura","spin","wheel","portal","teleport","npc",
    "zone","pad","button","gui","billboard","sign","coin","gem","diamond","orb","ring","vip","donate",
    "shop","store","character","humanoidrootpart","head","torso","baseplate","terrain","camera","anoleg_rock_clone",
}

local function isBlacklisted(name)
    local low = name:lower()
    for _, w in ipairs(BLACKLIST) do
        if low == w or low:find(w, 1, true) then return true end
    end
    return false
end

local function getObjPos(obj)
    local p = nil
    pcall(function()
        if obj:IsA("BasePart") then p = obj.Position
        elseif obj:IsA("Model") then
            p = obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetBoundingBox().Position
        end
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
        for _, v in ipairs(obj:GetDescendants()) do
            if v:IsA("BasePart") then table.insert(parts, v) end
        end
    end
    return parts
end

local function isValidObj(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    if isBlacklisted(obj.Name) or obj.Name == "ANOLEG_ROCK_CLONE" then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then return false end
    end
    return true
end

function getPunchTool()
    for _, name in ipairs({"Punch","PunchTool","Fist","Glove","Boxing Gloves","Punching Gloves"}) do
        local t = LP.Backpack:FindFirstChild(name) or Character:FindFirstChild(name)
        if t then return t end
    end
    for _, v in ipairs(LP.Backpack:GetChildren()) do if v:IsA("Tool") then return v end end
    return nil
end

local function isPunchTool(tool)
    if not tool then return false end
    local low = tool.Name:lower()
    for _, n in ipairs({"punch","punchtool","fist","glove","boxing"}) do
        if low:find(n, 1, true) then return true end
    end
    return false
end

-- Variable para controlar a velocidade da animação do soco (Ajuste aqui)
local PUNCH_SPEED_MULTIPLIER = 2.5 

-- Função para acelerar as animações de soco ativas
local function speedUpPunchAnimations()
    pcall(function()
        local animator = Humanoid:FindFirstChildWhichIsA("Animator") or Humanoid
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                local animName = track.Animation and track.Animation.Name:lower() or ""
                -- Detecta se a animação é de soco, ataque ou braço
                if animName:find("punch") or animName:find("fist") or animName:find("attack") or animName:find("hit") then
                    track:AdjustSpeed(PUNCH_SPEED_MULTIPLIER)
                else
                    -- Fallback caso o jogo use IDs/Nomes genéricos: acelera se o nome tiver "anim" ou "tool"
                    track:AdjustSpeed(PUNCH_SPEED_MULTIPLIER)
                end
            end
        end
    end)
end

-- Loop do Auto Punch Otimizado e Acelerado
task.spawn(function()
    while true do
        task.wait(0.001) -- Cliques na velocidade máxima permitida pelo motor
        if Flags.AutoPunch and not isDead then
            pcall(function()
                local equipped = Character:FindFirstChildWhichIsA("Tool")
                if equipped and not isPunchTool(equipped) then
                    equipped.Parent = LP.Backpack
                    task.wait(0.01)
                end
                local tool = getPunchTool()
                if tool then
                    if tool.Parent == LP.Backpack then 
                        tool.Parent = Character 
                        task.wait(0.01) 
                    end
                    tool:Activate()
                    speedUpPunchAnimations() -- Força a animação a ir mais rápido após ativar
                end
            end)
        end
    end
end)

Humanoid.Died:Connect(function()
    isDead = true
    pcall(function()
        local tool = Character:FindFirstChildWhichIsA("Tool")
        if tool then tool.Parent = LP.Backpack end
    end)
end)

LP.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
    isDead = false
    Humanoid.Died:Connect(function()
        isDead = true
        pcall(function()
            local tool = Character:FindFirstChildWhichIsA("Tool")
            if tool then tool.Parent = LP.Backpack end
        end)
    end)
    if Flags.AutoPunch then
        task.wait(0.5)
        isDead = false
        local tool = getPunchTool()
        if tool and tool.Parent == LP.Backpack then tool.Parent = Character end
    else
        isDead = false
    end
end)

local function findRockByCoord(entry)
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if not isValidObj(obj) then continue end
        local pos = getObjPos(obj)
        if pos then
            local dist = (pos - entry.targetPos).Magnitude
            if dist < bestDist then bestDist = dist; best = obj end
        end
    end
    return (bestDist < 100) and best or nil
end

local function findRockByName(entry)
    local best, bestScore = nil, -1
    for _, obj in ipairs(workspace:GetDescendants()) do
        if not isValidObj(obj) then continue end
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
    return best
end

local function findRealRock(entry)
    if entry.useCoord then return findRockByCoord(entry) end
    return findRockByName(entry)
end

local function makeInvisible(clone)
    for _, part in ipairs(getAllParts(clone)) do
        pcall(function()
            part.CanCollide, part.CanTouch, part.CanQuery, part.Anchored = false, false, false, true
            part.CastShadow, part.Transparency = false, 1
            part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
        end)
    end
    for _, child in ipairs(clone:GetDescendants()) do
        if child:IsA("Decal") or child:IsA("Texture") or child:IsA("ParticleEmitter")
        or child:IsA("BillboardGui") or child:IsA("SurfaceGui") or child:IsA("Beam")
        or child:IsA("Trail") or child:IsA("PointLight") or child:IsA("SpotLight")
        or child:IsA("SelectionBox") then
            pcall(function() child:Destroy() end)
        end
    end
end

local function pivotCloneTo(data, pos)
    local clone = data.cloneObj
    if not clone or not clone.Parent then return end
    local cf = CFrame.new(pos)
    if clone:IsA("Model") and clone.PrimaryPart then
        pcall(function() clone:PivotTo(cf) end)
    elseif clone:IsA("BasePart") then
        pcall(function() clone.CFrame = cf end)
    else
        for _, part in ipairs(data.cloneParts) do pcall(function() part.CFrame = cf end) end
    end
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
    makeInvisible(clone)
    if clone:IsA("Model") and not clone.PrimaryPart then clone.PrimaryPart = parts[1] end
    local data = { cloneObj = clone, cloneParts = parts, realRock = real, label = entry.label }
    pivotCloneTo(data, PARKED_POS)
    return data
end

local function calcFrontPos(data)
    local rockSize = getObjSize(data.realRock)
    local halfDepth = math.min(rockSize.X, rockSize.Z) / 2
    if halfDepth > 15 then halfDepth = 15 end
    local flatLook = Vector3.new(HRP.CFrame.LookVector.X, 0, HRP.CFrame.LookVector.Z)
    flatLook = flatLook.Magnitude < 0.001 and Vector3.new(0,0,-1) or flatLook.Unit
    local dist = halfDepth + punchContactOffset
    return Vector3.new(
        HRP.Position.X + flatLook.X * dist,
        HRP.Position.Y,
        HRP.Position.Z + flatLook.Z * dist
    )
end

local function touchRealRock(data)
    if not data or not data.realRock then return end
    for _, part in ipairs(getAllParts(data.realRock)) do
        pcall(function() firetouchinterest(HRP, part, 0); firetouchinterest(HRP, part, 1) end)
        pcall(function()
            local arm = Character:FindFirstChild("Right Arm")
                     or Character:FindFirstChild("RightHand")
                     or Character:FindFirstChild("RightLowerArm")
            if arm then firetouchinterest(arm, part, 0); firetouchinterest(arm, part, 1) end
        end)
    end
end

local function stopActiveRock()
    if lockConnection then lockConnection:Disconnect(); lockConnection = nil end
    if activeRockLabel and rockData[activeRockLabel] then
        pivotCloneTo(rockData[activeRockLabel], PARKED_POS)
    end
    activeRockLabel = nil
end

local function activateRock(label)
    stopActiveRock()
    local data = rockData[label]
    if not data then return end
    activeRockLabel = label
    pivotCloneTo(data, calcFrontPos(data))
    lockConnection = RunService.RenderStepped:Connect(function()
        if activeRockLabel ~= label then lockConnection:Disconnect(); return end
        pivotCloneTo(data, calcFrontPos(data))
    end)
    task.spawn(function()
        while activeRockLabel == label do
            task.wait(0.02)
            touchRealRock(data)
        end
    end)
end

local function deactivateRock(label)
    if activeRockLabel ~= label then return end
    stopActiveRock()
end

local function unequipTool(toolName)
    local char = LP.Character
    if char then
        local tool = char:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then
            tool.Parent = LP.Backpack
        end
    end
end

local farmConfig = {
    autoWeight     = false,
    autoSitups     = false,
    autoPushups    = false,
    autoHandstands = false,
}

local Window = WindUI:CreateWindow({
    Title = "Red x Hub",
    Icon = "dumbbell",
    Author = "RED",
    Folder = "MuscleLegendsConfig",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Red",
})

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "dumbbell",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 0, 0)
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house",
})

local LISTA_1M = {
    "480 RB – 5 em 5",
    "1.480 RB – 10 em 10",
    "2.980 RB – 15 em 15",
    "4.980 RB – 20 em 20",
    "7.480 RB – 25 em 25",
    "10.480 RB – 30 em 30",
    "13.980 RB – 35 em 35",
    "17.980 RB – 40 em 40",
    "22.480 RB – 45 em 45",
    "27.480 RB – 50 em 50",
    "32.980 RB – 55 em 55",
    "38.980 RB – 60 em 60",
    "45.480 RB – 65 em 65",
    "52.480 RB – 70 em 70",
    "59.980 RB – 75 em 75",
    "67.980 RB – 80 em 80",
    "76.480 RB – 85 em 85",
    "85.480 RB – 90 em 90",
    "94.980 RB – 95 em 95",
}

local LISTA_5M = {
    "80 RB – 5 em 5",
    "220 RB – 8 em 8",
    "280 RB – 10 em 10",
    "580 RB – 15 em 15",
    "980 RB – 20 em 20",
    "1.480 RB – 25 em 25",
    "2.080 RB – 30 em 30",
    "2.780 RB – 35 em 35",
    "3.580 RB – 40 em 40",
    "4.480 RB – 45 em 45",
    "5.480 RB – 50 em 50",
    "6.580 RB – 55 em 55",
    "7.780 RB – 60 em 60",
    "9.080 RB – 65 em 65",
    "10.480 RB – 70 em 70",
    "11.980 RB – 75 em 75",
    "13.580 RB – 80 em 80",
    "15.280 RB – 85 em 85",
    "17.080 RB – 90 em 90",
    "18.980 RB – 95 em 95",
}

local LISTA_10M = {
    "52 RB – 5 em 5 (Pet 80 XP)",
    "208 RB – 10 em 10 (Pet 45 XP)",
    "440 RB – 15 em 15 (Pet 5 XP)",
    "748 RB – 20 em 20 (Pet 20 XP)",
    "1.132 RB – 25 em 25 (Pet 30 XP)",
    "1.592 RB – 30 em 30 (Pet 55 XP)",
    "2.132 RB – 35 em 35 (Pet 30 XP)",
    "2.748 RB – 40 em 40 (Pet 20 XP)",
    "3.440 RB – 45 em 45 (Pet 25 XP)",
    "4.208 RB – 50 em 50 (Pet 45 XP)",
    "5.056 RB – 55 em 55 (Pet 15 XP)",
    "5.980 RB – 60 em 60 (Pet 0 XP)",
    "6.980 RB – 65 em 65 (Pet 0 XP)",
    "8.056 RB – 70 em 70 (Pet 15 XP)",
    "9.208 RB – 75 em 75 (Pet 45 XP)",
    "10.440 RB – 80 em 80 (Pet 25 XP)",
    "11.748 RB – 85 em 85 (Pet 25 XP)",
    "13.132 RB – 90 em 90 (Pet 30 XP)",
    "14.592 RB – 95 em 95 (Pet 55 XP)",
}

MainTab:Dropdown({
    Title = "Lista de Rebirth 10M",
    Values = LISTA_10M,
    Value = LISTA_10M[1],
    Callback = function(v) end,
})

MainTab:Dropdown({
    Title = "Lista de Rebirth 5M",
    Values = LISTA_5M,
    Value = LISTA_5M[1],
    Callback = function(v) end,
})

MainTab:Dropdown({
    Title = "Lista de Rebirth 1M",
    Values = LISTA_1M,
    Value = LISTA_1M[1],
    Callback = function(v) end,
})

local FarmTab = Window:Tab({
    Title = "Auto Farm",
    Icon = "activity"
})

local ToggleW, ToggleS, ToggleP, ToggleH

ToggleW = FarmTab:Toggle({
    Title = "Auto Weight",
    Value = false,
    Callback = function(Value)
        farmConfig.autoWeight = Value
        if Value then
            farmConfig.autoSitups = false;     ToggleS:Set(false)
            farmConfig.autoPushups = false;    ToggleP:Set(false)
            farmConfig.autoHandstands = false; ToggleH:Set(false)
        else
            unequipTool("Weight")
        end
    end,
})

ToggleS = FarmTab:Toggle({
    Title = "Auto Situps",
    Value = false,
    Callback = function(Value)
        farmConfig.autoSitups = Value
        if Value then
            farmConfig.autoWeight = false;     ToggleW:Set(false)
            farmConfig.autoPushups = false;    ToggleP:Set(false)
            farmConfig.autoHandstands = false; ToggleH:Set(false)
        else
            unequipTool("Situps")
        end
    end,
})

ToggleP = FarmTab:Toggle({
    Title = "Auto Pushups",
    Value = false,
    Callback = function(Value)
        farmConfig.autoPushups = Value
        if Value then
            farmConfig.autoWeight = false;     ToggleW:Set(false)
            farmConfig.autoSitups = false;     ToggleS:Set(false)
            farmConfig.autoHandstands = false; ToggleH:Set(false)
        else
            unequipTool("Pushups")
        end
    end,
})

ToggleH = FarmTab:Toggle({
    Title = "Auto Handstands",
    Value = false,
    Callback = function(Value)
        farmConfig.autoHandstands = Value
        if Value then
            farmConfig.autoWeight = false;  ToggleW:Set(false)
            farmConfig.autoSitups = false;  ToggleS:Set(false)
            farmConfig.autoPushups = false; ToggleP:Set(false)
        else
            unequipTool("Handstands")
        end
    end,
})

local lockPos = nil

FarmTab:Toggle({
    Title = "Lock Position",
    Value = false,
    Callback = function(Value)
        if Value then
            -- ── Salva a posição atual quando ativa ──
            lockPos = HRP.CFrame
            task.spawn(function()
                while Value do
                    task.wait(0.1)
                    pcall(function()
                        local char = LP.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = lockPos
                        end
                    end)
                end
            end)
        else
            lockPos = nil
        end
    end,
})

task.spawn(function()
    while task.wait(0.1) do
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            if farmConfig.autoWeight then
                local tool = LP.Backpack:FindFirstChild("Weight") or char:FindFirstChild("Weight")
                if tool then
                    if tool.Parent ~= char then tool.Parent = char end
                    pcall(function() LP.muscleEvent:FireServer("rep") end)
                end
            end
            if farmConfig.autoSitups then
                local tool = LP.Backpack:FindFirstChild("Situps") or char:FindFirstChild("Situps")
                if tool then
                    if tool.Parent ~= char then tool.Parent = char end
                    pcall(function() LP.muscleEvent:FireServer("rep") end)
                end
            end
            if farmConfig.autoPushups then
                local tool = LP.Backpack:FindFirstChild("Pushups") or char:FindFirstChild("Pushups")
                if tool then
                    if tool.Parent ~= char then tool.Parent = char end
                    pcall(function() LP.muscleEvent:FireServer("rep") end)
                end
            end
            if farmConfig.autoHandstands then
                local tool = LP.Backpack:FindFirstChild("Handstands") or char:FindFirstChild("Handstands")
                if tool then
                    if tool.Parent ~= char then tool.Parent = char end
                    pcall(function() LP.muscleEvent:FireServer("rep") end)
                end
            end
        end
    end
end)

local CombateTab = Window:Tab({
    Title = "Auto Rocks",
    Icon = "mountain"
})

CombateTab:Toggle({
    Title = "Auto Soco",
    Value = false,
    Callback = function(v)
        Flags.AutoPunch = v
        if v then
            pcall(function()
                local equipped = Character:FindFirstChildWhichIsA("Tool")
                if equipped and not isPunchTool(equipped) then equipped.Parent = LP.Backpack end
            end)
            task.wait(0.05)
            local tool = getPunchTool()
            if tool and tool.Parent == LP.Backpack then tool.Parent = Character end
        else
            pcall(function()
                local equipped = Character:FindFirstChildWhichIsA("Tool")
                if equipped and isPunchTool(equipped) then equipped.Parent = LP.Backpack end
            end)
        end
    end,
})

for _, entry in ipairs(ROCKS) do
    local lbl = entry.label
    local toggle = CombateTab:Toggle({
        Title = lbl,
        Value = false,
        Callback = function(v)
            if v then
                if activeRockLabel and activeRockLabel ~= lbl then
                    local prevToggle = rockToggles[activeRockLabel]
                    if prevToggle then pcall(function() prevToggle:Set(false) end) end
                end
                activateRock(lbl)
            else
                deactivateRock(lbl)
            end
        end,
    })
    rockToggles[lbl] = toggle
end

task.spawn(function()
    task.wait(1)
    for _, entry in ipairs(ROCKS) do
        local data = createCloneForEntry(entry)
        if data then rockData[entry.label] = data end
        task.wait(0.2)
    end
end)
