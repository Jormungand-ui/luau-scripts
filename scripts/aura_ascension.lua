-- ╔══════════════════════════════════════════════════════╗
-- ║        AURA ASCENSION HUB - Auto Farm                ║
-- ║  Auto-Zone + Auto-Rebirth + Chest + Anti-AFK + GUI   ║
-- ╚══════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Toggles ───────────────────────────────────────────
_G.FarmActif    = false
_G.RebirthActif = false
_G.AntiAFK      = true
_G.TweenSpeed   = 24 -- studs/sec

-- ─── RemoteEvents ──────────────────────────────────────
local Communication       = ReplicatedStorage:WaitForChild("Communication")
local RF_Rebirth          = Communication:WaitForChild("RequestRebirth")
local RE_AntiAFK          = Communication:WaitForChild("RequestAFKReturnTeleport")
local RE_Chest            = Communication:WaitForChild("ChestCommunication")
local RE_Ping             = Communication:WaitForChild("ActivePing")

-- ─── Zones d'entraînement (ordre croissant de puissance)
local ZONES = {
    "Fire Bath",
    "Dark Lava",
    "Frost Heaven",
    "Electra Field",
    "Divine Realm",
    "Ancient Ruins",
    "Fallen Star", -- meilleure zone
}

-- Zone cible (modifiable via GUI)
local zoneChoisie = "Fire Bath"

-- ─── Trouver le centre d'une zone ──────────────────────
local function trouverZone(nomZone)
    local trainingAreas = workspace:FindFirstChild("Training Areas")
    if not trainingAreas then return nil end
    local zone = trainingAreas:FindFirstChild(nomZone)
    if not zone then return nil end
    -- Trouver la partie principale (première BasePart)
    for _, obj in ipairs(zone:GetDescendants()) do
        if obj:IsA("BasePart") then
            return obj
        end
    end
    return nil
end

-- ─── Déplacement Tween ─────────────────────────────────
local tweenActif = nil

local function allerVers(cframe)
    pcall(function()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if tweenActif then pcall(function() tweenActif:Cancel() end) end
        local dist  = (hrp.Position - cframe.Position).Magnitude
        local duree = math.clamp(dist / math.max(_G.TweenSpeed, 1), 0.1, 5)
        tweenActif  = TweenService:Create(hrp, TweenInfo.new(duree, Enum.EasingStyle.Linear), {CFrame = cframe})
        tweenActif:Play()
        tweenActif.Completed:Wait()
        tweenActif = nil
    end)
end

-- ─── Auto-Farm Zone ────────────────────────────────────
task.spawn(function()
    while true do
        if not _G.FarmActif then task.wait(0.5) continue end
        pcall(function()
            local zone = trouverZone(zoneChoisie)
            if not zone then
                print("[AuraHub] Zone introuvable : " .. zoneChoisie)
                task.wait(3)
                return
            end
            -- Se déplacer vers la zone
            allerVers(zone.CFrame + Vector3.new(0, 3, 0))
            -- Rester dans la zone quelques secondes pour farm l'aura
            task.wait(3)
        end)
    end
end)

-- ─── Auto-Rebirth ──────────────────────────────────────
local rebirthCount = 0

task.spawn(function()
    while true do
        task.wait(2)
        if not _G.RebirthActif then continue end
        pcall(function()
            local ok, result = pcall(function()
                return RF_Rebirth:InvokeServer()
            end)
            if ok and result then
                rebirthCount = rebirthCount + 1
                print("[AuraHub] ✅ Rebirth #" .. rebirthCount .. " effectué !")
            end
        end)
    end
end)

-- ─── Anti-AFK ──────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(60) -- toutes les 60 secondes
        if not _G.AntiAFK then continue end
        pcall(function()
            RE_AntiAFK:FireServer()
            RE_Ping:FireServer()
            print("[AuraHub] Anti-AFK ping envoyé")
        end)
    end
end)

-- ─── Coffre automatique ────────────────────────────────
task.spawn(function()
    while true do
        task.wait(5)
        if not _G.FarmActif then continue end
        pcall(function()
            local chest = workspace:FindFirstChild("Map") and
                          workspace.Map:FindFirstChild("Chest")
            if chest then
                local part = chest:FindFirstChildWhichIsA("BasePart")
                if part then
                    allerVers(part.CFrame + Vector3.new(0, 3, 0))
                    pcall(function() RE_Chest:FireServer(chest) end)
                    print("[AuraHub] Coffre ouvert !")
                end
            end
        end)
    end
end)

-- ─── GUI ───────────────────────────────────────────────
local function creerGUI()
    pcall(function()
        for _, g in ipairs({CoreGui, playerGui}) do
            local old = g:FindFirstChild("AuraHub")
            if old then old:Destroy() end
        end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "AuraHub" sg.ResetOnSpawn = false sg.IgnoreGuiInset = true
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok then sg.Parent = playerGui end

    -- Frame
    local frame = Instance.new("Frame", sg)
    frame.Size             = UDim2.new(0, 220, 0, 370)
    frame.Position         = UDim2.new(0, 10, 0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
    frame.BorderSizePixel  = 0
    frame.Active           = true
    frame.Draggable        = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    -- Titre
    local titre = Instance.new("TextLabel", frame)
    titre.Size = UDim2.new(1,0,0,32) titre.BackgroundColor3 = Color3.fromRGB(20,20,45)
    titre.Text = "✨ Aura Ascension Hub" titre.TextColor3 = Color3.fromRGB(150,100,255)
    titre.Font = Enum.Font.GothamBold titre.TextScaled = true titre.BorderSizePixel = 0
    Instance.new("UICorner", titre).CornerRadius = UDim.new(0,12)

    -- Helper bouton
    local yOffset = 40
    local function makeBtn(text, color)
        local b = Instance.new("TextButton", frame)
        b.Size = UDim2.new(1,-16,0,34) b.Position = UDim2.new(0,8,0,yOffset)
        b.BackgroundColor3 = Color3.fromRGB(180,40,40)
        b.Text = text b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.GothamBold b.TextScaled = true b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        yOffset = yOffset + 42
        return b
    end

    local btnFarm    = makeBtn("⚡ AUTO-FARM : OFF")
    local btnRebirth = makeBtn("🔄 AUTO-REBIRTH : OFF")
    local btnAFK     = makeBtn("🛡️ ANTI-AFK : ON")
    btnAFK.BackgroundColor3 = Color3.fromRGB(40,180,40)

    btnFarm.MouseButton1Click:Connect(function()
        _G.FarmActif = not _G.FarmActif
        btnFarm.BackgroundColor3 = _G.FarmActif and Color3.fromRGB(40,180,40) or Color3.fromRGB(180,40,40)
        btnFarm.Text = _G.FarmActif and "⚡ AUTO-FARM : ON" or "⚡ AUTO-FARM : OFF"
        if not _G.FarmActif and tweenActif then pcall(function() tweenActif:Cancel() end) tweenActif = nil end
    end)

    btnRebirth.MouseButton1Click:Connect(function()
        _G.RebirthActif = not _G.RebirthActif
        btnRebirth.BackgroundColor3 = _G.RebirthActif and Color3.fromRGB(40,180,40) or Color3.fromRGB(180,40,40)
        btnRebirth.Text = _G.RebirthActif and "🔄 AUTO-REBIRTH : ON" or "🔄 AUTO-REBIRTH : OFF"
    end)

    btnAFK.MouseButton1Click:Connect(function()
        _G.AntiAFK = not _G.AntiAFK
        btnAFK.BackgroundColor3 = _G.AntiAFK and Color3.fromRGB(40,180,40) or Color3.fromRGB(180,40,40)
        btnAFK.Text = _G.AntiAFK and "🛡️ ANTI-AFK : ON" or "🛡️ ANTI-AFK : OFF"
    end)

    -- Sélecteur de zone
    local lblZone = Instance.new("TextLabel", frame)
    lblZone.Size = UDim2.new(1,-16,0,18) lblZone.Position = UDim2.new(0,8,0,yOffset)
    lblZone.BackgroundTransparency = 1
    lblZone.Text = "🎯 Zone : " .. zoneChoisie
    lblZone.TextColor3 = Color3.fromRGB(200,200,200)
    lblZone.Font = Enum.Font.GothamBold lblZone.TextScaled = true
    yOffset = yOffset + 22

    -- Boutons zones
    local zoneIndex = 1
    local function makeZoneBtn(nomZone)
        local b = Instance.new("TextButton", frame)
        b.Size = UDim2.new(0.47,0,0,26)
        b.Position = UDim2.new(zoneIndex % 2 == 1 and 0 or 0.5, 8, 0, yOffset)
        b.BackgroundColor3 = Color3.fromRGB(30,30,55)
        b.Text = nomZone b.TextColor3 = Color3.fromRGB(180,180,255)
        b.Font = Enum.Font.Gotham b.TextScaled = true b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        if zoneIndex % 2 == 0 then yOffset = yOffset + 30 end
        zoneIndex = zoneIndex + 1
        b.MouseButton1Click:Connect(function()
            zoneChoisie = nomZone
            lblZone.Text = "🎯 Zone : " .. nomZone
            -- Réinitialiser la couleur de tous les boutons
            b.BackgroundColor3 = Color3.fromRGB(80,60,180)
        end)
        return b
    end

    for _, zone in ipairs(ZONES) do makeZoneBtn(zone) end
    yOffset = yOffset + 34

    -- Slider vitesse
    local lblVitesse = Instance.new("TextLabel", frame)
    lblVitesse.Size = UDim2.new(1,-16,0,18) lblVitesse.Position = UDim2.new(0,8,0,yOffset)
    lblVitesse.BackgroundTransparency = 1
    lblVitesse.Text = "⚡ Vitesse : 24 studs/s"
    lblVitesse.TextColor3 = Color3.fromRGB(200,200,200)
    lblVitesse.Font = Enum.Font.Gotham lblVitesse.TextScaled = true
    yOffset = yOffset + 22

    local piste = Instance.new("Frame", frame)
    piste.Size = UDim2.new(1,-24,0,18) piste.Position = UDim2.new(0,12,0,yOffset)
    piste.BackgroundColor3 = Color3.fromRGB(35,35,55) piste.BorderSizePixel = 0 piste.Active = true
    Instance.new("UICorner", piste).CornerRadius = UDim.new(0,9)
    yOffset = yOffset + 26

    local fill = Instance.new("Frame", piste)
    fill.Size = UDim2.new(0.3,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(100,60,220) fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,9)

    local handle = Instance.new("Frame", piste)
    handle.Size = UDim2.new(0,20,0,20) handle.Position = UDim2.new(0.3,-10,0.5,-10)
    handle.BackgroundColor3 = Color3.fromRGB(180,150,255) handle.BorderSizePixel = 0 handle.Active = true
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1,0)

    local VMIN, VMAX = 8, 80
    local sliding = false

    local function appliquerSlider(ratio)
        ratio = math.clamp(ratio, 0, 1)
        fill.Size = UDim2.new(ratio,0,1,0)
        handle.Position = UDim2.new(ratio,-10,0.5,-10)
        local v = math.floor(VMIN + ratio*(VMAX-VMIN))
        _G.TweenSpeed = v
        lblVitesse.Text = "⚡ Vitesse : "..v.." studs/s"
    end

    local function getRatio(x)
        return (x - piste.AbsolutePosition.X) / piste.AbsoluteSize.X
    end

    piste.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true appliquerSlider(getRatio(i.Position.X))
        end
    end)
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            appliquerSlider(getRatio(i.Position.X))
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    appliquerSlider((24-VMIN)/(VMAX-VMIN))

    -- Compteur rebirths
    local lblRebirth = Instance.new("TextLabel", frame)
    lblRebirth.Size = UDim2.new(1,-16,0,20) lblRebirth.Position = UDim2.new(0,8,0,yOffset)
    lblRebirth.BackgroundTransparency = 1
    lblRebirth.Text = "🔄 Rebirths : 0"
    lblRebirth.TextColor3 = Color3.fromRGB(180,180,180)
    lblRebirth.Font = Enum.Font.Gotham lblRebirth.TextScaled = true

    RunService.Heartbeat:Connect(function()
        pcall(function()
            lblRebirth.Text = "🔄 Rebirths : "..rebirthCount
        end)
    end)
end

creerGUI()
print("[Aura Hub] ✅ Chargé ! Active le farm et choisis ta zone.")
