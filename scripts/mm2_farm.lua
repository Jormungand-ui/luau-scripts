-- ╔══════════════════════════════════════════════════════╗
-- ║         MM2 HUB - Murder Mystery 2                   ║
-- ║     Coins Tween + ESP Rôles + Slider Vitesse         ║
-- ╚══════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Config ────────────────────────────────────────────
_G.FarmActif  = false
_G.ESPActif   = false
_G.TweenSpeed = 16 -- studs/sec

-- ─── RemoteEvents MM2 ──────────────────────────────────
local Remotes          = ReplicatedStorage:WaitForChild("Remotes")
local Gameplay         = Remotes:WaitForChild("Gameplay")
local RE_GetCoin       = Gameplay:WaitForChild("GetCoin")
local RE_CoinCollected = Gameplay:WaitForChild("CoinCollected")

-- ─── Trouver la pièce la plus proche ───────────────────
local function getPieceProche()
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, 0 end

    local meilleures = nil
    local meilleuredist = math.huge

    pcall(function()
        for _, mapObj in ipairs(workspace:GetChildren()) do
            local cc = mapObj:FindFirstChild("CoinContainer", true)
            if not cc then continue end
            for _, obj in ipairs(cc:GetDescendants()) do
                if obj.Name == "Coin_Server" and obj:IsA("BasePart") and obj.Parent then
                    local d = (obj.Position - hrp.Position).Magnitude
                    if d < meilleuredist then
                        meilleuredist = d
                        meilleures    = obj
                    end
                end
            end
        end
    end)

    return meilleures, meilleuredist
end

-- ─── Tween vers une position ───────────────────────────
local tweenActif = nil

local function allerVers(piece)
    pcall(function()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if tweenActif then
            pcall(function() tweenActif:Cancel() end)
            tweenActif = nil
        end

        local dist  = (hrp.Position - piece.Position).Magnitude
        local duree = dist / math.max(_G.TweenSpeed, 1)

        tweenActif = TweenService:Create(
            hrp,
            TweenInfo.new(duree, Enum.EasingStyle.Linear),
            { CFrame = CFrame.new(piece.Position + Vector3.new(0, 3, 0)) }
        )
        tweenActif:Play()
        tweenActif.Completed:Wait()
        tweenActif = nil
    end)
end

-- ─── Boucle Farm ───────────────────────────────────────
local compteur = 0

task.spawn(function()
    while true do
        if not _G.FarmActif then
            task.wait(0.3)
            continue
        end

        pcall(function()
            local piece, dist = getPieceProche()

            if not piece then
                task.wait(2)
                return
            end

            -- Aller vers la pièce la plus proche
            allerVers(piece)

            -- Vérifier qu'elle existe encore
            if not piece or not piece.Parent then return end
            if not _G.FarmActif then return end

            -- Collecter
            pcall(function() RE_GetCoin:FireServer(piece) end)
            task.wait(0.2)
            pcall(function() RE_CoinCollected:FireServer(piece) end)
            compteur = compteur + 1
        end)
    end
end)

-- ─── ESP Joueurs ───────────────────────────────────────
-- Détecte le rôle même avant le début de la partie
local function getRoleInfo(p)
    local role    = "👤 " .. p.Name
    local couleur = Color3.fromRGB(255, 255, 255)

    pcall(function()
        -- Chercher dans le character ET le backpack
        for _, src in ipairs({ p.Character, p:FindFirstChild("Backpack") }) do
            if not src then continue end
            if src:FindFirstChild("Knife") then
                role    = "⚔️ " .. p.Name
                couleur = Color3.fromRGB(255, 60, 60)
                return
            elseif src:FindFirstChild("Gun") then
                role    = "🔫 " .. p.Name
                couleur = Color3.fromRGB(60, 150, 255)
                return
            end
        end
    end)

    return role, couleur
end

RunService.RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        pcall(function()
            if not p.Character then return end
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- Toujours détruire l'ancien pour mise à jour temps réel
            local old = hrp:FindFirstChild("MM2_ESP")
            if old then old:Destroy() end
            if not _G.ESPActif then return end

            local hum   = p.Character:FindFirstChild("Humanoid")
            local hp    = hum and math.floor(hum.Health) or 0
            local maxHp = hum and math.floor(hum.MaxHealth) or 100
            local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local dist  = myHrp and math.floor((hrp.Position - myHrp.Position).Magnitude) or 0
            local role, couleur = getRoleInfo(p)

            local bb = Instance.new("BillboardGui")
            bb.Name        = "MM2_ESP"
            bb.Size        = UDim2.new(0, 140, 0, 55)
            bb.StudsOffset = Vector3.new(0, 4, 0)
            bb.AlwaysOnTop = true
            bb.Parent      = hrp

            local function label(txt, col, yPos, bold)
                local l = Instance.new("TextLabel", bb)
                l.Size                   = UDim2.new(1, 0, 0.33, 0)
                l.Position               = UDim2.new(0, 0, yPos, 0)
                l.BackgroundTransparency = 1
                l.Text                   = txt
                l.TextColor3             = col
                l.Font                   = bold and Enum.Font.GothamBold or Enum.Font.Gotham
                l.TextScaled             = true
                l.TextStrokeTransparency = 0
            end

            label(role,                         couleur,                       0,    true)
            label("❤️ " .. hp .. "/" .. maxHp,  Color3.fromRGB(220, 220, 220), 0.33, false)
            label(dist .. " studs",             Color3.fromRGB(150, 150, 150), 0.66, false)
        end)
    end
end)

-- ─── Respawn ───────────────────────────────────────────
player.CharacterAdded:Connect(function()
    task.wait(1)
    if tweenActif then
        pcall(function() tweenActif:Cancel() end)
        tweenActif = nil
    end
end)

-- ─── GUI ───────────────────────────────────────────────
local function creerGUI()
    pcall(function()
        for _, g in ipairs({ CoreGui, playerGui }) do
            local old = g:FindFirstChild("MM2Hub")
            if old then old:Destroy() end
        end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "MM2Hub" sg.ResetOnSpawn = false sg.IgnoreGuiInset = true
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok then sg.Parent = playerGui end

    -- Frame
    local frame = Instance.new("Frame", sg)
    frame.Size             = UDim2.new(0, 200, 0, 245)
    frame.Position         = UDim2.new(0, 10, 0.35, 0)
    frame.BackgroundColor3 = Color3.fromRGB(13, 13, 23)
    frame.BorderSizePixel  = 0
    frame.Active           = true
    frame.Draggable        = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    -- Titre
    local titre = Instance.new("TextLabel", frame)
    titre.Size             = UDim2.new(1, 0, 0, 30)
    titre.BackgroundColor3 = Color3.fromRGB(22, 22, 44)
    titre.Text             = "🔪 MM2 Hub"
    titre.TextColor3       = Color3.fromRGB(255, 200, 50)
    titre.Font             = Enum.Font.GothamBold
    titre.TextScaled       = true
    titre.BorderSizePixel  = 0
    Instance.new("UICorner", titre).CornerRadius = UDim.new(0, 10)

    -- Helper bouton toggle
    local function makeToggle(text, yPos)
        local b = Instance.new("TextButton", frame)
        b.Size             = UDim2.new(1, -16, 0, 36)
        b.Position         = UDim2.new(0, 8, 0, yPos)
        b.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        b.Text             = text .. " : OFF"
        b.TextColor3       = Color3.new(1, 1, 1)
        b.Font             = Enum.Font.GothamBold
        b.TextScaled       = true
        b.BorderSizePixel  = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end

    local btnFarm = makeToggle("🪙 COINS", 38)
    local btnESP  = makeToggle("👁️ ESP",   82)

    btnFarm.MouseButton1Click:Connect(function()
        _G.FarmActif = not _G.FarmActif
        btnFarm.BackgroundColor3 = _G.FarmActif and Color3.fromRGB(40,180,40) or Color3.fromRGB(200,40,40)
        btnFarm.Text = "🪙 COINS : " .. (_G.FarmActif and "ON" or "OFF")
        if not _G.FarmActif and tweenActif then
            pcall(function() tweenActif:Cancel() end)
            tweenActif = nil
        end
    end)

    btnESP.MouseButton1Click:Connect(function()
        _G.ESPActif = not _G.ESPActif
        btnESP.BackgroundColor3 = _G.ESPActif and Color3.fromRGB(40,180,40) or Color3.fromRGB(200,40,40)
        btnESP.Text = "👁️ ESP : " .. (_G.ESPActif and "ON" or "OFF")
    end)

    -- Label vitesse
    local lblVitesse = Instance.new("TextLabel", frame)
    lblVitesse.Size                = UDim2.new(1, -16, 0, 18)
    lblVitesse.Position            = UDim2.new(0, 8, 0, 128)
    lblVitesse.BackgroundTransparency = 1
    lblVitesse.Text                = "⚡ Vitesse : 16 studs/s"
    lblVitesse.TextColor3          = Color3.fromRGB(200, 200, 200)
    lblVitesse.Font                = Enum.Font.Gotham
    lblVitesse.TextScaled          = true

    -- Piste slider
    local piste = Instance.new("Frame", frame)
    piste.Size             = UDim2.new(1, -24, 0, 18)
    piste.Position         = UDim2.new(0, 12, 0, 150)
    piste.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    piste.BorderSizePixel  = 0
    piste.Active           = true
    Instance.new("UICorner", piste).CornerRadius = UDim.new(0, 9)

    local fill = Instance.new("Frame", piste)
    fill.Size             = UDim2.new(0.2, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 9)

    local handle = Instance.new("Frame", piste)
    handle.Size             = UDim2.new(0, 22, 0, 22)
    handle.Position         = UDim2.new(0.2, -11, 0.5, -11)
    handle.BackgroundColor3 = Color3.fromRGB(180, 210, 255)
    handle.BorderSizePixel  = 0
    handle.Active           = true
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

    local VMIN, VMAX = 5, 80
    local sliding = false

    local function appliquer(ratio)
        ratio = math.clamp(ratio, 0, 1)
        fill.Size       = UDim2.new(ratio, 0, 1, 0)
        handle.Position = UDim2.new(ratio, -11, 0.5, -11)
        local v = math.floor(VMIN + ratio * (VMAX - VMIN))
        _G.TweenSpeed   = v
        lblVitesse.Text = "⚡ Vitesse : " .. v .. " studs/s"
    end

    local function ratio(x)
        return (x - piste.AbsolutePosition.X) / piste.AbsoluteSize.X
    end

    piste.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            appliquer(ratio(i.Position.X))
        end
    end)
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not sliding then return end
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseMovement then
            appliquer(ratio(i.Position.X))
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    -- Init slider à 16 studs/s
    appliquer((16 - VMIN) / (VMAX - VMIN))

    -- Compteur + prochaine pièce
    local lblCompteur = Instance.new("TextLabel", frame)
    lblCompteur.Size                   = UDim2.new(1, -16, 0, 20)
    lblCompteur.Position               = UDim2.new(0, 8, 0, 182)
    lblCompteur.BackgroundTransparency = 1
    lblCompteur.Text                   = "🪙 Pièces : 0"
    lblCompteur.TextColor3             = Color3.fromRGB(180, 180, 180)
    lblCompteur.Font                   = Enum.Font.Gotham
    lblCompteur.TextScaled             = true

    local lblProche = Instance.new("TextLabel", frame)
    lblProche.Size                   = UDim2.new(1, -16, 0, 18)
    lblProche.Position               = UDim2.new(0, 8, 0, 205)
    lblProche.BackgroundTransparency = 1
    lblProche.Text                   = "📍 --"
    lblProche.TextColor3             = Color3.fromRGB(140, 140, 140)
    lblProche.Font                   = Enum.Font.Gotham
    lblProche.TextScaled             = true

    RunService.Heartbeat:Connect(function()
        pcall(function()
            lblCompteur.Text = "🪙 Pièces : " .. compteur
            if _G.FarmActif then
                local _, dist = getPieceProche()
                if dist < math.huge then
                    lblProche.Text = "📍 " .. math.floor(dist) .. " studs"
                else
                    lblProche.Text = "📍 En attente..."
                end
            else
                lblProche.Text = "📍 Farm inactif"
            end
        end)
    end)
end

creerGUI()
print("[MM2 Hub] ✅ Prêt !")
