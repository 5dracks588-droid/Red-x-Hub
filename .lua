local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

--// Window
local Window = WindUI:CreateWindow({
Title = "Murder Mystery 2",
Icon = "zap",
Author = "ʀᴇᴅ",
Folder = "MM2WindUI",
Size = UDim2.fromOffset(580,430),
Transparent = true,
Theme = "Red",
SideBarWidth = 200,
MinimizeKey = Enum.KeyCode.RightControl
})

-- Chamando a função direto da sua Window criada
Window:EditOpenButton({
Title = "Open Menu",
Icon = "zap",
CornerRadius = UDim.new(0.5, 0),
StrokeThickness = 2,
Color = ColorSequence.new(
Color3.fromHex("FF0000"),
Color3.fromHex("FF0000")
),
        
OnlyMobile = false,
Enabled = true,
Draggable = true,
})

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variáveis
local AimbotEnabled = false
local FovVisible = false
local FovSize = 100
local AutoCoinEnabled = false
local AutoCoinSpeed = 25
local StopDuration = 0.25 -- Fixado em 0.25 segundos conforme solicitado
local SelectedTheme = "Red"
local AutoSafeEnabled = false
local safeTpCount = 0
local KnifeAuraEnabled = false
local KnifeAuraDistance = 3
local SavedPositions = {}
local AutoCoinHideEnabled = false

local EspEnabled = false
local GunEspEnabled = false
local AntiFlingEnabled = false
local LowGraphicsEnabled = false

local Speed = 16
local Jump = 50

local InfiniteJump = false
local NoclipEnabled = false

local FlyEnabled = false
local FlySpeed = 30 -- Ajustado padrão para 30 conforme solicitado

local bodyVelocity
local bodyGyro
local flyConnection
local moveVector = Vector3.zero

local SelectedPlayerToTp = ""
local CurrentTarget = nil

-- VARIÁVEIS DO SISTEMA DE FLING (Mecanismo Kilasik)
local SelectedPlayerToFling = ""
local FlingActive = false
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255,0,0)
FOVCircle.Thickness = 2
FOVCircle.Transparency = 1
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Tabela para ignorar moedas coletadas
local Coletadas = {}

LocalPlayer.CharacterAdded:Connect(function()
    Coletadas = {}
end)

WindUI:SetTheme("Red")

-- STATS
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

-- LABELS
local InfoTab = Window:Tab({Title = "Info", Icon = "house"})
local CombatTab = Window:Tab({Title = "Combate", Icon = "sword"})
local FlingTab = Window:Tab({Title = "Fling", Icon = "wind"})
local EspTab = Window:Tab({Title = "ESP", Icon = "eye"})
local TeleportTab = Window:Tab({Title = "Teleportes", Icon = "map-pinned"})
local FarmTab = Window:Tab({Title = "Farm", Icon = "coins"})
local PlayerTab = Window:Tab({Title = "Player", Icon = "user"})
local PerformanceTab = Window:Tab({Title = "Desempenho", Icon = "cpu"})

local PingParagraph = InfoTab:Paragraph({Title = "Ping", Desc = "0 ms"})
local FPSParagraph = InfoTab:Paragraph({Title = "FPS", Desc = "0 FPS"})
local ServerParagraph = InfoTab:Paragraph({Title = "Servidor", Desc = "0/0"})

-- FPS Loop
local FPS = 0
local Last = tick()

RunService.RenderStepped:Connect(function()
    FPS += 1
    if tick() - Last >= 1 then
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        PingParagraph:SetDesc(ping .. " ms")
        FPSParagraph:SetDesc(FPS .. " FPS")
        ServerParagraph:SetDesc(#Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        FPS = 0
        Last = tick()
    end
end)

-- ROLE DETECTOR
local function GetPlayerRole(player)
    if not player then return "Innocent" end

    -- 1. Verificação por dados do jogo (se disponíveis)
    local playerData = player:FindFirstChild("PlayerData")
    if playerData and playerData:FindFirstChild("Role") then
        return playerData.Role.Value
    end

    -- 2. Busca pelas ferramentas na Mochila (não equipado) e no Personagem (equipado)
    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character

    local hasKnife = (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife"))
    local hasGun = (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun"))

    if hasKnife then
        return "Murderer"
    elseif hasGun then
        return "Sheriff"
    end

    return "Innocent"
end

local function TeleportToCFrame(targetCFrame)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetCFrame.Position)
    end
end

local function GetPlayerNamesList()
    local list = {}
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

-- SAFE AREA
local SafePart = Instance.new("Part")
SafePart.Name = "SafeArea"
SafePart.Size = Vector3.new(20,1,20)
SafePart.Position = Vector3.new(10000,500,10000)
SafePart.Anchored = true
SafePart.CanCollide = true
SafePart.Color = Color3.fromRGB(0,255,0)
SafePart.Material = Enum.Material.Neon
SafePart.Transparency = 0
SafePart.Parent = workspace

local function TeleportToSafeArea()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = SafePart.CFrame + Vector3.new(0,3,0)
    end
end

-- FIND GUN
local function FindDroppedGun()
    local gun = workspace:FindFirstChild("GunDrop")
    if gun then return gun end
    for _,obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "GunDrop" or (obj:IsA("Model") and obj:FindFirstChild("GunDrop")) then
            return obj:FindFirstChild("GunDrop") or obj
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- [SISTEMA DE AUTO FARM COIN INTEGRADO (VELOCITY)]
---------------------------------------------------------------------------
local function GetClosestCoin()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local menorDistancia = math.huge
    local moedaAlvo = nil

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent and not Coletadas[obj] and obj.Transparency < 1 and obj.CanCollide == false then
            local nome = string.lower(obj.Name)
            if nome:find("coin") or nome:find("gold") or nome:find("token") then
                if obj.Size.X <= 6 and obj.Size.Y <= 6 and obj.Size.Z <= 6 then
                    local model = obj:FindFirstAncestorOfClass("Model")
                    if model and not model:FindFirstChild("Lobby") then
                        local dist = (hrp.Position - obj.Position).Magnitude
                        if dist < menorDistancia then
                            menorDistancia = dist
                            moedaAlvo = obj
                        end
                    end
                end
            end
        end
    end
    return moedaAlvo
end

-- Loop de Movimentação do Auto Coin Novo
task.spawn(function()
    while true do
        task.wait(0.1)
        while AutoCoinEnabled do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local alvo = GetClosestCoin()
                
                if alvo and alvo.Parent then
                    -- Noclip temporário de movimentação
                    local noclipConnection
                    noclipConnection = RunService.Stepped:Connect(function()
                        if char then
                            for _, part in ipairs(char:GetChildren()) do
                                if part:IsA("BasePart") then part.CanCollide = false end
                            end
                        end
                    end)
                    
                    local attachment = Instance.new("Attachment")
                    attachment.Parent = hrp
                    
                    local lv = Instance.new("LinearVelocity")
                    lv.MaxForce = 1e6
                    lv.VectorVelocity = Vector3.new(0, 0, 0)
                    lv.Attachment0 = attachment
                    lv.RelativeTo = Enum.ActuatorRelativeTo.World
                    lv.Parent = hrp

                    local bg = Instance.new("BodyGyro")
                    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
                    bg.D = 100; bg.P = 10000; bg.Parent = hrp

                    local spawnDestino = alvo.Position
                    if alvo.Parent:IsA("Model") and alvo.Parent.PrimaryPart then
                        spawnDestino = alvo.Parent.PrimaryPart.Position
                    elseif alvo.Name == "Coin_Sub" and alvo.Parent:FindFirstChild("Coin") then
                        spawnDestino = alvo.Parent.Coin.Position
                    end
                    
                    local destinoFinal = Vector3.new(spawnDestino.X, spawnDestino.Y + 1.2, spawnDestino.Z)

                    while AutoCoinEnabled and alvo and alvo.Parent do
                        local atualPos = hrp.Position
                        local distancia = (atualPos - destinoFinal).Magnitude
                        bg.CFrame = CFrame.new(atualPos, atualPos + Vector3.new(0, 0, -1))
                        if distancia <= 0.8 then break end
                        
                        local direcao = (destinoFinal - atualPos).Unit
                        lv.VectorVelocity = direcao * AutoCoinSpeed
                        task.wait()
                    end

                    lv.VectorVelocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                    if noclipConnection then noclipConnection:Disconnect() end
                    lv:Destroy()
                    attachment:Destroy()
                    bg:Destroy()

                    if not AutoCoinEnabled then break end
                    Coletadas[alvo] = true
                    task.wait(StopDuration) -- Espera exatamente o tempo fixado (0.5s)
                else
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        end
    end
end)

-- NOCLIP GERAL DA TAB
RunService.Stepped:Connect(function()
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- AIMBOT TARGETS (Procura apenas o assassino se você for xerife/inocente, ou todos se você for o assassino)
local function GetClosestPlayerToCenter()
    local closestPlayer = nil
    local shortestDistance = FovSize
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myRole = GetPlayerRole(LocalPlayer)

    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local role = GetPlayerRole(p)
            local canTarget = false

            if myRole == "Murderer" then
                canTarget = true
            else
                if role == "Murderer" then
                    canTarget = true
                end
            end

            if canTarget then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = p.Character.Head
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- ESP SYSTEM
local function UpdateESP()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character

            if EspEnabled and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local role = GetPlayerRole(p)
                local color = Color3.fromRGB(0,255,0)

                if role == "Murderer" then
                    color = Color3.fromRGB(255,0,0)
                elseif role == "Sheriff" then
                    color = Color3.fromRGB(0,0,255)
                end

                if char:FindFirstChild("ESPGui") then char.ESPGui:Destroy() end

                local highlight = char:FindFirstChild("ESPHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ESPHighlight"
                    highlight.Parent = char
                end
                highlight.FillColor = color
                highlight.OutlineColor = color
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
            else
                if char:FindFirstChild("ESPHighlight") then char.ESPHighlight:Destroy() end
                if char:FindFirstChild("ESPGui") then char.ESPGui:Destroy() end
            end
        end
    end
end

-- FPS BOOSTER
local function CleanObject(obj)
    if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
    elseif obj:IsA("Texture") or obj:IsA("Decal") then
        obj:Destroy()
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
        obj.Enabled = false
    elseif obj:IsA("Atmosphere") or obj:IsA("Sky") then
        obj:Destroy()
    end
end

local function OptimizeTextures()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    for _,obj in ipairs(workspace:GetDescendants()) do
        CleanObject(obj)
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if LowGraphicsEnabled then
        task.wait(0.1)
        if descendant and descendant.Parent then
            CleanObject(descendant)
        end
    end
end)

-- FLY SYSTEM
local bodyVelocity
local bodyGyro
local flyConnection

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local function SetupCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(SetupCharacter)

local function StartFly()
    if FlyEnabled then return end
    FlyEnabled = true

    Humanoid.PlatformStand = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = HumanoidRootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 100000
    bodyGyro.CFrame = Camera.CFrame
    bodyGyro.Parent = HumanoidRootPart

    flyConnection = RunService.RenderStepped:Connect(function()
        local camCF = Camera.CFrame
        local forward = camCF.LookVector
        local right = camCF.RightVector
        local direction = Vector3.zero

        direction += forward * moveVector.Z
        direction += right * (moveVector.X * 0.45)

        if direction.Magnitude > 0 then
            bodyVelocity.Velocity = direction.Unit * FlySpeed
        else
            bodyVelocity.Velocity = Vector3.zero
        end

        bodyGyro.CFrame = CFrame.new(
            HumanoidRootPart.Position,
            HumanoidRootPart.Position + Camera.CFrame.LookVector
        )
    end)
end

local function StopFly()
    FlyEnabled = false
    Humanoid.PlatformStand = false
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
end

-- CONTROLES DO FLY
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

RunService.RenderStepped:Connect(function()
    if not Character or not Humanoid then return end
    local moveDir = Humanoid.MoveDirection
    if moveDir.Magnitude > 0 then
        local relative = Camera.CFrame:VectorToObjectSpace(moveDir)
        moveVector = Vector3.new(relative.X, 0, -relative.Z)
    else
        moveVector = Vector3.zero
    end
end)

UserInputService.JumpRequest:Connect(function()
    if InfiniteJump then
        local hum = Character and Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- FLING MECANISMO
local function ExecutarMecanismoFling(TargetPlayer)
    if not TargetPlayer then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    
    local tChar = TargetPlayer.Character
    if not tChar then return end
    
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    local tRoot = tHum and tHum.RootPart
    local tHead = tChar:FindFirstChild("Head")
    local acc = tChar:FindFirstChildOfClass("Accessory")
    local handle = acc and acc:FindFirstChild("Handle")
    
    if char and hum and root then
        if root.Velocity.Magnitude < 50 then
            getgenv().OldPos = root.CFrame
        end
        
        if tHum and tHum.Sit then return end
        
        if tHead then
            workspace.CurrentCamera.CameraSubject = tHead
        elseif handle then
            workspace.CurrentCamera.CameraSubject = handle
        elseif tHum and tRoot then
            workspace.CurrentCamera.CameraSubject = tHum
        end
        
        if not tChar:FindFirstChildWhichIsA("BasePart") then return end
        
        local animScript = char:FindFirstChild("Animate")
        if animScript then animScript.Disabled = true end
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop() end
        end
        
        local FPos = function(BasePart, Pos, Ang)
            root.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            char:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            root.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 5
            local Time = tick()
            local Angle = 0
            
            repeat
                if root and tHum and tRoot then
                    if tRoot.AssemblyLinearVelocity.Magnitude > 150 then
                        break
                    end
                    
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = (Angle + 35) % 360
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + tHum.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + tHum.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        Angle = (Angle + 35) % 360
                        FPos(BasePart, CFrame.new(0, 1.5, tHum.WalkSpeed), CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -tHum.WalkSpeed), CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until Time + TimeToWait < tick() or not FlingActive
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Parent = root
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if tRoot then
            SFBasePart(tRoot)
        elseif tHead then
            SFBasePart(tHead)
        elseif handle then
            SFBasePart(handle)
        end
        
        BV:Destroy()
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = hum
        
        if animScript then animScript.Disabled = false end
        
        if getgenv().OldPos then
            local t = 0
            repeat
                root.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                char:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                hum:ChangeState("GettingUp")
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Velocity, part.RotVelocity = Vector3.zero, Vector3.zero
                    end
                end
                task.wait()
                t = t + 1
            until (root.Position - getgenv().OldPos.p).Magnitude < 25 or t > 10
            workspace.FallenPartsDestroyHeight = getgenv().FPDH
        end
    end
end

-- LOOP PRINCIPAL DO JOGO (RENDERSTEPPED)
RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = screenCenter
    FOVCircle.Radius = FovSize
    FOVCircle.Visible = FovVisible

    -- AIM LOCK INSTANTÂNEO (Trava a CFrame da câmera no oponente)
    if AimbotEnabled then
        local target = GetClosestPlayerToCenter()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end

    if AntiFlingEnabled and LocalPlayer.Character then
        for _,p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _,part in pairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Speed
        LocalPlayer.Character.Humanoid.JumpPower = Jump
    end

    UpdateESP()

    -- ESP GUN LIMPO (SEM TEXTO E SEM DISTÂNCIA)
    local gun = FindDroppedGun()
    if gun and GunEspEnabled then
        local part = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
        if part then
            local highlight = gun:FindFirstChild("GunHighlight")
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "GunHighlight"
                highlight.Parent = gun
            end
            highlight.FillColor = Color3.fromRGB(255, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 1


            -- Destrói qualquer BillboardGui de texto antigo para não mostrar nada na tela
            if gun:FindFirstChild("GunGui") then 
                gun.GunGui:Destroy() 
            end
        end
    else
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "GunDrop" or (obj:IsA("Model") and obj.Name == "GunDrop") then
                if obj:FindFirstChild("GunHighlight") then obj.GunHighlight:Destroy() end
                if obj:FindFirstChild("GunGui") then obj.GunGui:Destroy() end
            end
        end
    end

    -- KNIFE AURA
    if KnifeAuraEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHRP = LocalPlayer.Character.HumanoidRootPart

        for _,plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                local role = GetPlayerRole(plr)
                if role == "Murderer" or role == "Sheriff" or role == "Innocent" then
                    local targetHRP = plr.Character.HumanoidRootPart
                    local distanceFromSafe = (targetHRP.Position - SafePart.Position).Magnitude

                    if distanceFromSafe > 50 then
                        if not SavedPositions[plr] then
                            SavedPositions[plr] = targetHRP.CFrame
                        end

                        local frontPos = myHRP.Position + (myHRP.CFrame.LookVector * KnifeAuraDistance)
                        targetHRP.CFrame = CFrame.new(frontPos)
                        targetHRP.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        targetHRP.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    end
                end
            end
        end
    else
        for plr, savedCFrame in pairs(SavedPositions) do
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.CFrame = savedCFrame
                plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                plr.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
            end
        end
        SavedPositions = {}
    end
end)

-- AUTO COLLECT GUN DROP
local AutoCollectGunEnabled = false
task.spawn(function()
    while true do
        task.wait(0)
        if AutoCollectGunEnabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local currentHRP = char and char:FindFirstChild("HumanoidRootPart")
            
            if currentHRP and hum and hum.Health > 0 then
                local minhaRole = GetPlayerRole(LocalPlayer)
                if minhaRole == "Innocent" then
                    local gun = FindDroppedGun()
                    if gun then
                        local part = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local originalCFrame = currentHRP.CFrame
                            currentHRP.CFrame = part.CFrame
                            task.wait(0) 
                            currentHRP.CFrame = originalCFrame
                            task.wait(50)
                        end
                    end
                end
            end
        end
    end
end)

-- COMBATE ELEMENTOS
CombatTab:Toggle({Title = "Aimbot", Default = false, Callback = function(v) AimbotEnabled = v end})
CombatTab:Toggle({Title = "Mostrar FOV", Default = false, Callback = function(v) FovVisible = v end})
CombatTab:Slider({Title = "FOV", Step = 1, Value = { Min = 50, Max = 500, Default = 100 }, Callback = function(v) FovSize = v end})
CombatTab:Toggle({Title = "Anti Fling", Default = false, Callback = function(v) AntiFlingEnabled = v end})
CombatTab:Toggle({Title = "Knife Aura", Default = false, Callback = function(v) KnifeAuraEnabled = v end})
CombatTab:Slider({Title = "Distância Aura", Step = 1, Value = {Min = 0, Max = 10, Default = 3}, Callback = function(v) KnifeAuraDistance = v end})

-- FLING ELEMENTOS
FlingTab:Button({
    Title = "Fling murderer",
    Callback = function()
        if FlingActive then return end
        local target = GetPlayerByRole("Murderer")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            FlingActive = true
            task.spawn(function()
                ExecutarMecanismoFling(target)
                FlingActive = false
            end)
        end
    end
})

FlingTab:Button({
    Title = "Fling sherife",
    Callback = function()
        if FlingActive then return end
        local target = GetPlayerByRole("Sheriff")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            FlingActive = true
            task.spawn(function()
                ExecutarMecanismoFling(target)
                FlingActive = false
            end)
        end
    end
})

local FlingDropdown = FlingTab:Dropdown({
    Title = "Lista de Jogadores",
    Values = GetPlayerNamesList(),
    Value = "",
    Callback = function(v) SelectedPlayerToFling = v end
})

FlingTab:Button({
    Title = "Fling player",
    Callback = function()
        if FlingActive then return end
        if SelectedPlayerToFling ~= "" then
            local target = Players:FindFirstChild(SelectedPlayerToFling)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                FlingActive = true
                task.spawn(function()
                    ExecutarMecanismoFling(target)
                    FlingActive = false
                end)
            end
        end
    end
})

local function AtualizarTodasAsListas()
    local novaLista = GetPlayerNamesList()
    FlingDropdown:Refresh(novaLista)
    if PlayerDropdown then
        PlayerDropdown:Refresh(novaLista)
    end
end

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    AtualizarTodasAsListas()
end)

Players.PlayerRemoving:Connect(function(p)
    if SelectedPlayerToFling == p.Name then SelectedPlayerToFling = "" end
    if SelectedPlayerToTp == p.Name then SelectedPlayerToTp = "" end
    task.wait(0.1)
    AtualizarTodasAsListas()
end)

-- ESP ELEMENTOS
EspTab:Toggle({Title = "ESP Jogadores", Default = false, Callback = function(v) EspEnabled = v end})
EspTab:Toggle({Title = "ESP Arma", Default = false, Callback = function(v) GunEspEnabled = v end})

-- TELEPORTES ELEMENTOS
TeleportTab:Button({
    Title = "TP Murderer",
    Callback = function()
        local target = GetPlayerByRole("Murderer")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0))
        end
    end
})

TeleportTab:Button({
    Title = "TP Sheriff",
    Callback = function()
        local target = GetPlayerByRole("Sheriff")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0))
        end
    end
})

PlayerDropdown = TeleportTab:Dropdown({
    Title = "Escolher Jogador",
    Values = GetPlayerNamesList(),
    Value = "",
    Callback = function(v) SelectedPlayerToTp = v end
})

TeleportTab:Button({
    Title = "TP Jogador",
    Callback = function()
        if SelectedPlayerToTp ~= "" then
            local target = Players:FindFirstChild(SelectedPlayerToTp)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0))
            end
        end
    end
})

TeleportTab:Button({Title = "Atualizar Lista", Callback = function() AtualizarTodasAsListas() end})
TeleportTab:Button({Title = "TP Área Segura", Callback = function() TeleportToSafeArea() end})

TeleportTab:Button({
    Title = "TP Lobby",
    Callback = function()
        local lobby = workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("LobbyWorkspace")
        if lobby then
            local spawnLocation = lobby:FindFirstChildWhichIsA("SpawnLocation", true)
            if spawnLocation then
                TeleportToCFrame(spawnLocation.CFrame * CFrame.new(0, 5, 0))
                return
            end
        end
        local globalSpawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
        if globalSpawn then
            TeleportToCFrame(globalSpawn.CFrame * CFrame.new(0, 5, 0))
            return
        end
        TeleportToCFrame(CFrame.new(-108, 145, 12))
    end
})

TeleportTab:Button({
    Title = "TP Arena de Jogo",
    Callback = function()
        local activeMapFolder = workspace:FindFirstChild("NormalMaps") or workspace:FindFirstChild("Map")
        if activeMapFolder then
            for _, mapModel in ipairs(activeMapFolder:GetChildren()) do
                if mapModel.Name ~= "Lobby" and mapModel.Name ~= "LobbyWorkspace" then
                    local spawns = mapModel:FindFirstChild("Spawns") or mapModel:FindFirstChild("PlayerSpawns") or mapModel:FindFirstChild("SpawnPoints")
                    if spawns and #spawns:GetChildren() > 0 then
                        local spawnPointsList = spawns:GetChildren()
                        local randomSpawn = spawnPointsList[math.random(1, #spawnPointsList)]
                        if randomSpawn:IsA("BasePart") then
                            TeleportToCFrame(CFrame.new(randomSpawn.Position + Vector3.new(0, 3, 0)))
                            return
                        end
                    end
                    local floor = mapModel:FindFirstChild("Floor") or mapModel:FindFirstChild("Geometry") or mapModel:FindFirstChildWhichIsA("BasePart", true)
                    if floor then
                        TeleportToCFrame(CFrame.new(floor.Position + Vector3.new(0, 6, 0)))
                        return
                    end
                end
            end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj.Name ~= "Lobby" and obj.Name ~= "LobbyWorkspace" then
                if obj:FindFirstChild("CoinContainer") then
                    local spawns = obj:FindFirstChild("Spawns") or obj:FindFirstChild("PlayerSpawns")
                    if spawns and #spawns:GetChildren() > 0 then
                        local randomSpawn = spawns:GetChildren()[math.random(1, #spawns:GetChildren())]
                        if randomSpawn:IsA("BasePart") then
                            TeleportToCFrame(CFrame.new(randomSpawn.Position + Vector3.new(0, 3, 0)))
                            return
                        end
                    end
                end
            end
        end
    end
})

TeleportTab:Button({
    Title = "TP Arma Dropada",
    Callback = function()
        local gun = FindDroppedGun()
        if gun then
            local part = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
            if part then
                TeleportToCFrame(part.CFrame)
            end
        end
    end
})

-- ====================================================================
-- COIN FARM ELEMENTOS (COOLDOWN REMOVIDO / CONFIGS SIMPLIFICADAS)
-- ====================================================================
FarmTab:Toggle({
    Title = "Auto collect Coin",
    Default = false,
    Callback = function(v)
        AutoCoinEnabled = v
        if not v then Coletadas = {} end
    end
})

FarmTab:Toggle({
    Title = "Auto TP Área Segura",
    Default = false,
    Callback = function(v)
        AutoSafeEnabled = v
        if v then
            task.spawn(function()
                while AutoSafeEnabled do
                    task.wait(0)
                    local char = LocalPlayer.Character
                    if char and GetPlayerRole(LocalPlayer) == "Innocent" then
                        TeleportToSafeArea()
                    end
                end
            end)
        end
    end
})

FarmTab:Toggle({Title = "Auto Collect Gun", Default = false, Callback = function(v) AutoCollectGunEnabled = v end})

-- PLAYER CONFIGS
PlayerTab:Input({
    Title = "Velocidade",
    Placeholder = "16",
    Callback = function(text)
        local num = tonumber(text)
        if num then Speed = num end  
    end
})

PlayerTab:Input({
    Title = "Pulo",
    Placeholder = "50",
    Callback = function(text)
        local num = tonumber(text)
        if num then Jump = num end  
    end
})

PlayerTab:Toggle({Title = "Pulo Infinito", Default = false, Callback = function(v) InfiniteJump = v end})
PlayerTab:Toggle({Title = "NoClip", Default = false, Callback = function(v) NoclipEnabled = v end})
PlayerTab:Toggle({Title = "Fly", Default = false, Callback = function(v) if v then StartFly() else StopFly() end end})
PlayerTab:Slider({Title = "Fly Speed", Step = 5, Value = {Min = 10, Max = 200, Default = 30}, Callback = function(v) FlySpeed = v end}) -- Padrão modificado para 30

-- DESEMPENHO CONFIGS
PerformanceTab:Toggle({
    Title = "Modo Leve",
    Default = false,
    Callback = function(v)
        LowGraphicsEnabled = v
        if v then OptimizeTextures() end
    end
})
