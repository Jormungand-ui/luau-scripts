-- ╔══════════════════════════════════════════════════════╗
-- ║       MM2 FARM HUB - Murder Mystery 2                ║
-- ║  Coins par proximité + Slider vitesse + ESP          ║
-- ╚══════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

_G.FarmActif  = false
_G.ESPActif   = false
_G.TweenSpeed = 16

local Remotes          = ReplicatedStorage:WaitForChild("Remotes")
local Gameplay         = Remotes:WaitForChild("Gameplay")
local RE_GetCoin       = Gameplay:WaitForChild("GetCoin")
local RE_CoinCollected = Gameplay:WaitForChild("CoinCollected")

-- ─── Système de Rôle ──────────────────────────────────
local RE_RoleSelect = Gameplay:WaitForChild("RoleSelect")
local RE_ShowRole   = Gameplay:WaitForChild("ShowRoleSelect")
_G.RoleActif        = false
local ROLES         = {"Murderer", "Sheriff"}
local roleIndex     = 1

-- Écouter le début de la sélection de rôle et forcer le rôle voulu
RE_ShowRole.OnClientEvent:Connect(function()
    if not _G.RoleActif then return end
    task.wait(0.1) -- petit délai pour être sûr que le serveur est prêt
    local role = ROLES[roleIndex]
    roleIndex = roleIndex % #ROLES + 1 -- alterner entre les rôles
    pcall(function()
        RE_RoleSelect:FireServer(role)
        print("[MM2] Rôle demandé : " .. role)
    end)
end)

-- ─── Trouver la pièce la plus proche EN TEMPS RÉEL ─────
-- Appelé à chaque itération pour toujours cibler la plus proche
local function getPiecesPlusProche()
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local meilleurepiece = nil
    local meilleuredist  = math.huge

    pcall(function()
        for _, mapObj in ipairs(workspace:GetChildren()) do
            local coinContainer = mapObj:FindFirstChild("CoinContainer", true)
            if not coinContainer then continue end
            for _, obj in ipairs(coinContainer:GetDescendants()) do
                if obj.Name == "Coin_Server" and obj:IsA("BasePart") and obj.Parent then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if dist < meilleuredist then
                        meilleuredist  = dist
                        meilleurepiece = obj
                    end
                end
            end
        end
    end)

    return meilleurepiece, meilleuredist
end

-- ─── Déplacement Tween vitesse réglable ────────────────
local tweenActif = nil

local function deplacerVersPiece(part)
    pcall(function()
        local char = player.Character
        if not char then return end
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if tweenActif then pcall(function() tweenActif:Cancel() end) end

        local distance = (hrp.Position - part.Position).Magnitude
        local vitesse  = math.max(_G.TweenSpeed, 1)
        local duree    = distance / vitesse

        tweenActif = TweenService:Create(hrp, TweenInfo.new(duree, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
        })
        tweenActif:Play()
        tweenActif.Completed:Wait()
        tweenActif = nil
    end)
end

-- ─── Boucle Farm ───────────────────────────────────────
local compteur      = 0
local pieceEnCours  = nil -- pièce actuellement ciblée

task.spawn(function()
    while true do
        if not _G.FarmActif then
            task.wait(0.3)
            continue
        end

        pcall(function()
            -- Toujours récupérer la pièce la plus proche à cet instant
            local piece, dist = getPiecesPlusProche()

            if not piece then
                task.wait(2)
                return
            end

            -- Si on a changé de pièce cible, annuler le tween en cours
            if pieceEnCours ~= piece then
                pieceEnCours = piece
                if tweenActif then
                    pcall(function() tweenActif:Cancel() end)
                    tweenActif = nil
                end
            end

            -- Se déplacer vers la pièce la plus proche
            deplacerVersPiece(piece)

            -- Vérifier que la pièce existe encore après le tween
            if not piece or not piece.Parent then return end
            if not _G.FarmActif then return end

            -- Collecter
            pcall(function() RE_GetCoin:FireServer(piece) end)
            task.wait(0.15)
            pcall(function() RE_CoinCollected:FireServer(piece) end)
            compteur    = compteur + 1
            pieceEnCours = nil
        end)

    end
end)

-- ─── ESP ───────────────────────────────────────────────
local function getRoleEtCouleur(p)
    local role = "Innocent"
    local col  = Color3.fromRGB(255,255,255)
    pcall(function()
        for _, src in ipairs({p.Character, p:FindFirstChild("Backpack")}) do
            if src then
                if src:FindFirstChild("Knife") then
                    role = "⚔️ Meurtrier"
                    col  = Color3.fromRGB(255,60,60)
                    return
                elseif src:FindFirstChild("Gun") then
                    role = "🔫 Shérif"
                    col  = Color3.fromRGB(60,150,255)
                    return
                end
            end
        end
    end)
    return role, col
end

RunService.RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        pcall(function()
            if not p.Character then return end
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local old = hrp:FindFirstChild("MM2_ESP")
            if old then old:Destroy() end
            if not _G.ESPActif then return end

            local hum   = p.Character:FindFirstChild("Humanoid")
            local hp    = hum and math.floor(hum.Health) or 0
            local maxHp = hum and math.floor(hum.MaxHealth) or 100
            local role, col = getRoleEtCouleur(p)
            local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local dist  = myHrp and math.floor((hrp.Position - myHrp.Position).Magnitude) or 0

            local bb = Instance.new("BillboardGui")
            bb.Name = "MM2_ESP"
            bb.Size = UDim2.new(0,130,0,52)
            bb.StudsOffset = Vector3.new(0,4,0)
            bb.AlwaysOnTop = true
            bb.Parent = hrp

            local function makeLabel(parent, size, pos, text, color, bold)
                local l = Instance.new("TextLabel", parent)
                l.Size = size l.Position = pos
                l.BackgroundTransparency = 1
                l.Text = text l.TextColor3 = color
                l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
                l.TextScaled = true l.TextStrokeTransparency = 0
            end

            makeLabel(bb, UDim2.new(1,0,0.4,0), UDim2.new(0,0,0,0),     p.Name,                           col,                           true)
            makeLabel(bb, UDim2.new(1,0,0.35,0),UDim2.new(0,0,0.4,0),   role.." ❤️"..hp.."/"..maxHp,      Color3.fromRGB(220,220,220),   false)
            makeLabel(bb, UDim2.new(1,0,0.25,0),UDim2.new(0,0,0.75,0),  dist.." studs",                   Color3.fromRGB(150,150,150),   false)
        end)
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    pieceEnCours = nil
end)

-- ─── GUI avec slider tactile ───────────────────────────
local function creerGUI()
    pcall(function()
        for _, g in ipairs({CoreGui, playerGui}) do
            local old = g:FindFirstChild("MM2Hub")
            if old then old:Destroy() end
        end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "MM2Hub" sg.ResetOnSpawn = false sg.IgnoreGuiInset = true
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok then sg.Parent = playerGui end

    local frame = Instance.new("Frame", sg)
    frame.Size             = UDim2.new(0, 210, 0, 305)
    frame.Position         = UDim2.new(0, 10, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15,15,25)
    frame.BorderSizePixel  = 0
    frame.Active           = true
    frame.Draggable        = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

    -- Titre
    local titre = Instance.new("TextLabel", frame)
    titre.Size = UDim2.new(1,0,0,30) titre.BackgroundColor3 = Color3.fromRGB(25,25,50)
    titre.Text = "🔪 MM2 Hub" titre.TextColor3 = Color3.fromRGB(255,200,50)
    titre.Font = Enum.Font.GothamBold titre.TextScaled = true titre.BorderSizePixel = 0
    Instance.new("UICorner", titre).CornerRadius = UDim.new(0,10)

    -- Helper bouton
    local function makeBtn(parent, pos, text)
        local b = Instance.new("TextButton", parent)
        b.Size = UDim2.new(1,-16,0,36) b.Position = pos
        b.BackgroundColor3 = Color3.fromRGB(200,40,40)
        b.Text = text b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.GothamBold b.TextScaled = true b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        return b
    end

    local btnFarm = makeBtn(frame, UDim2.new(0,8,0,38), "🪙 COINS : OFF")
    local btnESP  = makeBtn(frame, UDim2.new(0,8,0,82), "👁️ ESP : OFF")

    btnFarm.MouseButton1Click:Connect(function()
        _G.FarmActif = not _G.FarmActif
        btnFarm.BackgroundColor3 = _G.FarmActif and Color3.fromRGB(40,180,40) or Color3.fromRGB(200,40,40)
        btnFarm.Text = _G.FarmActif and "🪙 COINS : ON" or "🪙 COINS : OFF"
        if not _G.FarmActif and tweenActif then
            pcall(function() tweenActif:Cancel() end)
            tweenActif = nil pieceEnCours = nil
        end
    end)

    btnESP.MouseButton1Click:Connect(function()
        _G.ESPActif = not _G.ESPActif
        btnESP.BackgroundColor3 = _G.ESPActif and Color3.fromRGB(40,180,40) or Color3.fromRGB(200,40,40)
        btnESP.Text = _G.ESPActif and "👁️ ESP : ON" or "👁️ ESP : OFF"
    end)

    -- Bouton ROLE
    local btnRole = Instance.new("TextButton", frame)
    btnRole.Size             = UDim2.new(1,-16,0,36)
    btnRole.Position         = UDim2.new(0,8,0,126)
    btnRole.BackgroundColor3 = Color3.fromRGB(200,40,40)
    btnRole.Text             = "🎭 RÔLE AUTO : OFF"
    btnRole.TextColor3       = Color3.new(1,1,1)
    btnRole.Font             = Enum.Font.GothamBold
    btnRole.TextScaled       = true
    btnRole.BorderSizePixel  = 0
    Instance.new("UICorner", btnRole).CornerRadius = UDim.new(0,8)

    -- Labels rôle actuel
    local lblRole = Instance.new("TextLabel", frame)
    lblRole.Size                   = UDim2.new(1,-16,0,18)
    lblRole.Position               = UDim2.new(0,8,0,166)
    lblRole.BackgroundTransparency = 1
    lblRole.Text                   = "Prochain : ⚔️ Meurtrier"
    lblRole.TextColor3             = Color3.fromRGB(255,100,100)
    lblRole.Font                   = Enum.Font.Gotham
    lblRole.TextScaled             = true

    btnRole.MouseButton1Click:Connect(function()
        _G.RoleActif = not _G.RoleActif
        btnRole.BackgroundColor3 = _G.RoleActif and Color3.fromRGB(40,180,40) or Color3.fromRGB(200,40,40)
        btnRole.Text = _G.RoleActif and "🎭 RÔLE AUTO : ON" or "🎭 RÔLE AUTO : OFF"
    end)

    -- Mettre à jour le label du prochain rôle
    RunService.Heartbeat:Connect(function()
        pcall(function()
            if _G.RoleActif then
                local prochainRole = ROLES[roleIndex]
                if prochainRole == "Murderer" then
                    lblRole.Text      = "Prochain : ⚔️ Meurtrier"
                    lblRole.TextColor3 = Color3.fromRGB(255,100,100)
                else
                    lblRole.Text      = "Prochain : 🔫 Shérif"
                    lblRole.TextColor3 = Color3.fromRGB(100,150,255)
                end
            else
                lblRole.Text       = "Rôle auto désactivé"
                lblRole.TextColor3 = Color3.fromRGB(140,140,140)
            end
        end)
    end)

    -- Label vitesse
    local lblVitesse = Instance.new("TextLabel", frame)
    lblVitesse.Size = UDim2.new(1,-16,0,18) lblVitesse.Position = UDim2.new(0,8,0,192)
    lblVitesse.BackgroundTransparency = 1
    lblVitesse.Text = "⚡ Vitesse : 16 studs/s"
    lblVitesse.TextColor3 = Color3.fromRGB(200,200,200)
    lblVitesse.Font = Enum.Font.Gotham lblVitesse.TextScaled = true

    -- Piste slider
    local piste = Instance.new("Frame", frame)
    piste.Size = UDim2.new(1,-24,0,20) piste.Position = UDim2.new(0,12,0,216)
    piste.BackgroundColor3 = Color3.fromRGB(40,40,60) piste.BorderSizePixel = 0
    piste.Active = true
    Instance.new("UICorner", piste).CornerRadius = UDim.new(0,10)

    -- Remplissage
    local fill = Instance.new("Frame", piste)
    fill.Size = UDim2.new(0.22,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(80,130,255) fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,10)

    -- Poignée
    local handle = Instance.new("Frame", piste)
    handle.Size = UDim2.new(0,22,0,22) handle.Position = UDim2.new(0.22,-11,0.5,-11)
    handle.BackgroundColor3 = Color3.fromRGB(200,220,255) handle.BorderSizePixel = 0
    handle.Active = true
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1,0)

    local VMIN, VMAX = 5, 80

    local function appliquerSlider(ratio)
        ratio = math.clamp(ratio, 0, 1)
        fill.Size           = UDim2.new(ratio, 0, 1, 0)
        handle.Position     = UDim2.new(ratio, -11, 0.5, -11)
        local v = math.floor(VMIN + ratio * (VMAX - VMIN))
        _G.TweenSpeed       = v
        lblVitesse.Text     = "⚡ Vitesse : "..v.." studs/s"
    end

    -- Initialiser à 16 studs/s
    appliquerSlider((16 - VMIN) / (VMAX - VMIN))

    -- Gestion tactile et souris sur la piste
    local sliding = false

    local function getratio(inputX)
        local abs = piste.AbsolutePosition.X
        local siz = piste.AbsoluteSize.X
        return (inputX - abs) / siz
    end

    -- Clic direct sur la piste
    piste.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            appliquerSlider(getratio(input.Position.X))
        end
    end)

    -- Drag sur la poignée
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
        end
    end)

    -- Mouvement
    UserInputService.InputChanged:Connect(function(input)
        if not sliding then return end
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then
            appliquerSlider(getratio(input.Position.X))
        end
    end)

    -- Relâcher
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    -- Compteur + infos
    local lblCompteur = Instance.new("TextLabel", frame)
    lblCompteur.Size = UDim2.new(1,-16,0,20) lblCompteur.Position = UDim2.new(0,8,0,248)
    lblCompteur.BackgroundTransparency = 1
    lblCompteur.Text = "🪙 Pièces : 0"
    lblCompteur.TextColor3 = Color3.fromRGB(180,180,180)
    lblCompteur.Font = Enum.Font.Gotham lblCompteur.TextScaled = true

    local lblProche = Instance.new("TextLabel", frame)
    lblProche.Size = UDim2.new(1,-16,0,18) lblProche.Position = UDim2.new(0,8,0,274)
    lblProche.BackgroundTransparency = 1
    lblProche.Text = "📍 --"
    lblProche.TextColor3 = Color3.fromRGB(140,140,140)
    lblProche.Font = Enum.Font.Gotham lblProche.TextScaled = true

    RunService.Heartbeat:Connect(function()
        pcall(function()
            lblCompteur.Text = "🪙 Pièces : "..compteur
            if _G.FarmActif then
                local piece, dist = getPiecesPlusProche()
                if piece then
                    lblProche.Text = "📍 Prochaine : "..math.floor(dist).." studs"
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
print("[MM2 Hub] ✅ Prêt ! Slider tactile + pièce la plus proche en temps réel.")
