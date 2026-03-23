-- ╔══════════════════════════════════════════════════════╗
-- ║       MM2 FARM HUB - Murder Mystery 2                ║
-- ║  Coins par proximité + Slider vitesse + ESP          ║
-- ╚══════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Toggles ───────────────────────────────────────────
_G.FarmActif  = false
_G.ESPActif   = false
_G.TweenSpeed = 16 -- studs/sec (vitesse de marche normale = 16)

-- ─── RemoteEvents MM2 ──────────────────────────────────
local Remotes          = ReplicatedStorage:WaitForChild("Remotes")
local Gameplay         = Remotes:WaitForChild("Gameplay")
local RE_GetCoin       = Gameplay:WaitForChild("GetCoin")
local RE_CoinCollected = Gameplay:WaitForChild("CoinCollected")

-- ─── Trouver les pièces triées par proximité ───────────
local function trouverPiecesProches()
    local pieces = {}
    local char   = player.Character
    local hrp    = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return pieces end

    pcall(function()
        for _, mapObj in ipairs(workspace:GetChildren()) do
            local coinContainer = mapObj:FindFirstChild("CoinContainer", true)
            if not coinContainer then continue end
            for _, obj in ipairs(coinContainer:GetDescendants()) do
                if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    table.insert(pieces, { part = obj, dist = dist })
                end
            end
        end
    end)

    -- Trier par distance croissante (pièce la plus proche en premier)
    table.sort(pieces, function(a, b) return a.dist < b.dist end)

    -- Retourner uniquement les parts
    local result = {}
    for _, entry in ipairs(pieces) do
        table.insert(result, entry.part)
    end
    return result
end

-- ─── Déplacement Tween à vitesse réglable ──────────────
local tweenActif = nil

local function deplacerVersPiece(part)
    pcall(function()
        local char = player.Character
        if not char then return end
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Annuler le tween précédent si encore actif
        if tweenActif then
            pcall(function() tweenActif:Cancel() end)
        end

        local distance = (hrp.Position - part.Position).Magnitude
        local vitesse  = math.max(_G.TweenSpeed, 1)
        local duree    = distance / vitesse

        local tweenInfo = TweenInfo.new(
            duree,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out
        )

        tweenActif = TweenService:Create(hrp, tweenInfo, {
            CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
        })
        tweenActif:Play()
        tweenActif.Completed:Wait()
        tweenActif = nil
    end)
end

-- ─── Boucle Farm séquentielle ──────────────────────────
local compteur = 0

task.spawn(function()
    while true do
        if not _G.FarmActif then
            task.wait(0.3)
            continue
        end

        pcall(function()
            local pieces = trouverPiecesProches()

            if #pieces == 0 then
                task.wait(2)
                return
            end

            -- Traiter UNE pièce à la fois, la plus proche d'abord
            for _, piece in ipairs(pieces) do
                if not _G.FarmActif then break end
                if not piece or not piece.Parent then continue end

                -- Se déplacer à vitesse réglée
                deplacerVersPiece(piece)

                if not _G.FarmActif then break end

                -- Collecter
                pcall(function() RE_GetCoin:FireServer(piece) end)
                task.wait(0.2)
                pcall(function() RE_CoinCollected:FireServer(piece) end)
                compteur = compteur + 1
            end
        end)

        task.wait(0.5)
    end
end)

-- ─── ESP Joueurs ───────────────────────────────────────
local function getRoleEtCouleur(p)
    local role    = "Innocent"
    local couleur = Color3.fromRGB(255, 255, 255)
    pcall(function()
        for _, src in ipairs({p.Character, p:FindFirstChild("Backpack")}) do
            if src then
                if src:FindFirstChild("Knife") then
                    role = "⚔️ Meurtrier" couleur = Color3.fromRGB(255, 60, 60) return
                elseif src:FindFirstChild("Gun") then
                    role = "🔫 Shérif" couleur = Color3.fromRGB(60, 150, 255) return
                end
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

            local old = hrp:FindFirstChild("MM2_ESP")
            if old then old:Destroy() end
            if not _G.ESPActif then return end

            local humanoid = p.Character:FindFirstChild("Humanoid")
            local hp       = humanoid and math.floor(humanoid.Health) or 0
            local maxHp    = humanoid and math.floor(humanoid.MaxHealth) or 100
            local role, couleur = getRoleEtCouleur(p)
            local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local dist  = myHrp and math.floor((hrp.Position - myHrp.Position).Magnitude) or 0

            local bb = Instance.new("BillboardGui")
            bb.Name = "MM2_ESP" bb.Size = UDim2.new(0, 130, 0, 52)
            bb.StudsOffset = Vector3.new(0, 4, 0) bb.AlwaysOnTop = true bb.Parent = hrp

            local lblNom = Instance.new("TextLabel", bb)
            lblNom.Size = UDim2.new(1,0,0.4,0) lblNom.BackgroundTransparency = 1
            lblNom.Text = p.Name lblNom.TextColor3 = couleur
            lblNom.Font = Enum.Font.GothamBold lblNom.TextScaled = true lblNom.TextStrokeTransparency = 0

            local lblInfo = Instance.new("TextLabel", bb)
            lblInfo.Size = UDim2.new(1,0,0.35,0) lblInfo.Position = UDim2.new(0,0,0.4,0)
            lblInfo.BackgroundTransparency = 1 lblInfo.Text = role.." | ❤️"..hp.."/"..maxHp
            lblInfo.TextColor3 = Color3.fromRGB(220,220,220) lblInfo.Font = Enum.Font.Gotham
            lblInfo.TextScaled = true lblInfo.TextStrokeTransparency = 0

            local lblDist = Instance.new("TextLabel", bb)
            lblDist.Size = UDim2.new(1,0,0.25,0) lblDist.Position = UDim2.new(0,0,0.75,0)
            lblDist.BackgroundTransparency = 1 lblDist.Text = dist.." studs"
            lblDist.TextColor3 = Color3.fromRGB(150,150,150) lblDist.Font = Enum.Font.Gotham
            lblDist.TextScaled = true lblDist.TextStrokeTransparency = 0
        end)
    end
end)

player.CharacterAdded:Connect(function() task.wait(1) end)

-- ─── GUI Mobile avec Slider ────────────────────────────
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

    -- Frame principale
    local frame = Instance.new("Frame", sg)
    frame.Size             = UDim2.new(0, 200, 0, 230)
    frame.Position         = UDim2.new(0, 10, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BorderSizePixel  = 0
    frame.Active           = true
    frame.Draggable        = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    -- Titre
    local titre = Instance.new("TextLabel", frame)
    titre.Size = UDim2.new(1,0,0,30) titre.BackgroundColor3 = Color3.fromRGB(25,25,50)
    titre.Text = "🔪 MM2 Hub" titre.TextColor3 = Color3.fromRGB(255,200,50)
    titre.Font = Enum.Font.GothamBold titre.TextScaled = true titre.BorderSizePixel = 0
    Instance.new("UICorner", titre).CornerRadius = UDim.new(0, 10)

    -- Bouton FARM
    local btnFarm = Instance.new("TextButton", frame)
    btnFarm.Size = UDim2.new(1,-16,0,36) btnFarm.Position = UDim2.new(0,8,0,38)
    btnFarm.BackgroundColor3 = Color3.fromRGB(200,40,40)
    btnFarm.Text = "🪙 COINS : OFF" btnFarm.TextColor3 = Color3.new(1,1,1)
    btnFarm.Font = Enum.Font.GothamBold btnFarm.TextScaled = true btnFarm.BorderSizePixel = 0
    Instance.new("UICorner", btnFarm).CornerRadius = UDim.new(0, 8)

    btnFarm.MouseButton1Click:Connect(function()
        _G.FarmActif = not _G.FarmActif
        btnFarm.BackgroundColor3 = _G.FarmActif and Color3.fromRGB(40,180,40) or Color3.fromRGB(200,40,40)
        btnFarm.Text = _G.FarmActif and "🪙 COINS : ON" or "🪙 COINS : OFF"
        if not _G.FarmActif and tweenActif then
            pcall(function() tweenActif:Cancel() end)
            tweenActif = nil
        end
    end)

    -- Bouton ESP
    local btnESP = Instance.new("TextButton", frame)
    btnESP.Size = UDim2.new(1,-16,0,36) btnESP.Position = UDim2.new(0,8,0,82)
    btnESP.BackgroundColor3 = Color3.fromRGB(200,40,40)
    btnESP.Text = "👁️ ESP : OFF" btnESP.TextColor3 = Color3.new(1,1,1)
    btnESP.Font = Enum.Font.GothamBold btnESP.TextScaled = true btnESP.BorderSizePixel = 0
    Instance.new("UICorner", btnESP).CornerRadius = UDim.new(0, 8)

    btnESP.MouseButton1Click:Connect(function()
        _G.ESPActif = not _G.ESPActif
        btnESP.BackgroundColor3 = _G.ESPActif and Color3.fromRGB(40,180,40) or Color3.fromRGB(200,40,40)
        btnESP.Text = _G.ESPActif and "👁️ ESP : ON" or "👁️ ESP : OFF"
    end)

    -- Label vitesse
    local lblVitesse = Instance.new("TextLabel", frame)
    lblVitesse.Size = UDim2.new(1,-16,0,18) lblVitesse.Position = UDim2.new(0,8,0,126)
    lblVitesse.BackgroundTransparency = 1
    lblVitesse.Text = "⚡ Vitesse : ".._G.TweenSpeed.." studs/s"
    lblVitesse.TextColor3 = Color3.fromRGB(200,200,200)
    lblVitesse.Font = Enum.Font.Gotham lblVitesse.TextScaled = true

    -- Piste du slider
    local sliderBg = Instance.new("Frame", frame)
    sliderBg.Size = UDim2.new(1,-16,0,14) sliderBg.Position = UDim2.new(0,8,0,150)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40,40,60) sliderBg.BorderSizePixel = 0
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0,7)

    -- Remplissage du slider
    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new(0.25,0,1,0) -- 25% = vitesse 16 par défaut (max 64)
    sliderFill.BackgroundColor3 = Color3.fromRGB(100,150,255) sliderFill.BorderSizePixel = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0,7)

    -- Bouton du slider
    local sliderBtn = Instance.new("TextButton", sliderBg)
    sliderBtn.Size = UDim2.new(0,18,0,18) sliderBtn.Position = UDim2.new(0.25,-9,0.5,-9)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(180,200,255)
    sliderBtn.Text = "" sliderBtn.BorderSizePixel = 0
    Instance.new("UICorner", sliderBtn).CornerRadius = UDim.new(1,0)

    -- Logique du slider (drag tactile)
    local dragging = false
    local VITESSE_MIN = 5   -- studs/sec minimum
    local VITESSE_MAX = 64  -- studs/sec maximum

    local function updateSlider(inputPos)
        local bgPos    = sliderBg.AbsolutePosition.X
        local bgSize   = sliderBg.AbsoluteSize.X
        local relative = math.clamp((inputPos - bgPos) / bgSize, 0, 1)

        -- Mettre à jour visuels
        sliderFill.Size     = UDim2.new(relative, 0, 1, 0)
        sliderBtn.Position  = UDim2.new(relative, -9, 0.5, -9)

        -- Calculer la vitesse
        local vitesse = math.floor(VITESSE_MIN + relative * (VITESSE_MAX - VITESSE_MIN))
        _G.TweenSpeed = vitesse
        lblVitesse.Text = "⚡ Vitesse : "..vitesse.." studs/s"
    end

    sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
    sliderBg.MouseButton1Down:Connect(function(_, x) updateSlider(x) end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)

    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Compteur pièces
    local lblCompteur = Instance.new("TextLabel", frame)
    lblCompteur.Size = UDim2.new(1,-16,0,20) lblCompteur.Position = UDim2.new(0,8,0,175)
    lblCompteur.BackgroundTransparency = 1
    lblCompteur.Text = "Pièces : 0" lblCompteur.TextColor3 = Color3.fromRGB(180,180,180)
    lblCompteur.Font = Enum.Font.Gotham lblCompteur.TextScaled = true

    -- Pièces les plus proches
    local lblProche = Instance.new("TextLabel", frame)
    lblProche.Size = UDim2.new(1,-16,0,18) lblProche.Position = UDim2.new(0,8,0,200)
    lblProche.BackgroundTransparency = 1
    lblProche.Text = "Prochaine : --" lblProche.TextColor3 = Color3.fromRGB(140,140,140)
    lblProche.Font = Enum.Font.Gotham lblProche.TextScaled = true

    -- Mise à jour compteur + distance pièce la plus proche
    RunService.Heartbeat:Connect(function()
        pcall(function()
            lblCompteur.Text = "🪙 Pièces : "..compteur
            if _G.FarmActif then
                local char = player.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pieces = trouverPiecesProches()
                    if #pieces > 0 then
                        local dist = math.floor((pieces[1].Position - hrp.Position).Magnitude)
                        lblProche.Text = "📍 Prochaine : "..dist.." studs"
                    else
                        lblProche.Text = "📍 En attente des pièces..."
                    end
                end
            else
                lblProche.Text = "📍 Farm inactif"
            end
        end)
    end)
end

creerGUI()
print("[MM2 Hub] ✅ Chargé ! Vitesse réglable avec le slider.")
