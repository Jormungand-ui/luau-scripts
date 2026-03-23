-- ╔══════════════════════════════════════════════════════╗
-- ║       MM2 FARM HUB - Murder Mystery 2                ║
-- ║       Coins + ESP + GUI Mobile                       ║
-- ╚══════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Toggles ───────────────────────────────────────────
_G.FarmActif = false
_G.ESPActif  = false

-- ─── RemoteEvents MM2 (vrais chemins du scan) ──────────
local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local Gameplay     = Remotes:WaitForChild("Gameplay")
local RE_GetCoin   = Gameplay:WaitForChild("GetCoin")
local RE_CoinCollected = Gameplay:WaitForChild("CoinCollected")

-- ─── Chercher les pièces dans Workspace ────────────────
local function trouverPieces()
    local pieces = {}
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (
                obj.Name == "Coin"     or
                obj.Name == "GoldCoin" or
                obj.Name == "coin"
            ) then
                -- Vérifier que la pièce n'est pas trop loin (anti-cheat)
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        table.insert(pieces, obj)
                    end
                end
            end
        end
    end)
    return pieces
end

-- ─── Téléportation sécurisée ───────────────────────────
local function teleporter(part)
    pcall(function()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
    end)
end

-- ─── Boucle farm ───────────────────────────────────────
local compteur = 0
local enCours  = false

RunService.Heartbeat:Connect(function()
    if not _G.FarmActif then return end
    if enCours then return end
    enCours = true

    pcall(function()
        local pieces = trouverPieces()

        if #pieces == 0 then
            task.wait(1)
            enCours = false
            return
        end

        for _, piece in ipairs(pieces) do
            if not _G.FarmActif then break end
            if not piece or not piece.Parent then continue end

            teleporter(piece)
            task.wait(0.3) -- anti-cheat : attendre avant de fire

            pcall(function() RE_GetCoin:FireServer(piece) end)
            task.wait(0.1)
            pcall(function() RE_CoinCollected:FireServer(piece) end)

            compteur = compteur + 1
            task.wait(0.2)
        end
    end)

    task.wait(0.5)
    enCours = false
end)

-- ─── ESP Joueurs ───────────────────────────────────────
local function nettoyerESP()
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bb = hrp:FindFirstChild("MM2_ESP")
                    if bb then bb:Destroy() end
                end
            end
        end
    end)
end

local function creerESP(p)
    pcall(function()
        if not p.Character then return end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or hrp:FindFirstChild("MM2_ESP") then return end

        -- Détecter le rôle (Meurtrier = Knife, Shérif = Gun)
        local couleur = Color3.fromRGB(255, 255, 255)
        local role    = "Innocent"
        local bp = p:FindFirstChild("Backpack") or p.Character
        if bp then
            if bp:FindFirstChild("Knife") or (p.Character and p.Character:FindFirstChild("Knife")) then
                couleur = Color3.fromRGB(255, 50, 50)
                role    = "⚔️ Meurtrier"
            elseif bp:FindFirstChild("Gun") or (p.Character and p.Character:FindFirstChild("Gun")) then
                couleur = Color3.fromRGB(50, 150, 255)
                role    = "🔫 Shérif"
            end
        end

        local humanoid = p.Character:FindFirstChild("Humanoid")
        local hp = humanoid and math.floor(humanoid.Health) or "?"

        local bb = Instance.new("BillboardGui")
        bb.Name          = "MM2_ESP"
        bb.Size          = UDim2.new(0, 120, 0, 45)
        bb.StudsOffset   = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop   = true
        bb.Parent        = hrp

        local nom = Instance.new("TextLabel", bb)
        nom.Size                  = UDim2.new(1, 0, 0.55, 0)
        nom.BackgroundTransparency = 1
        nom.Text                  = p.Name
        nom.TextColor3            = couleur
        nom.Font                  = Enum.Font.GothamBold
        nom.TextScaled            = true
        nom.TextStrokeTransparency = 0

        local roleLabel = Instance.new("TextLabel", bb)
        roleLabel.Size                   = UDim2.new(1, 0, 0.45, 0)
        roleLabel.Position               = UDim2.new(0, 0, 0.55, 0)
        roleLabel.BackgroundTransparency = 1
        roleLabel.Text                   = role .. " | ❤️" .. hp
        roleLabel.TextColor3             = Color3.fromRGB(220, 220, 220)
        roleLabel.Font                   = Enum.Font.Gotham
        roleLabel.TextScaled             = true
        roleLabel.TextStrokeTransparency = 0
    end)
end

RunService.RenderStepped:Connect(function()
    if not _G.ESPActif then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            creerESP(p)
        end
    end
end)

-- ─── Re-appliquer après respawn ────────────────────────
player.CharacterAdded:Connect(function()
    task.wait(1)
    enCours = false
end)

-- ─── GUI Mobile ────────────────────────────────────────
local function creerGUI()
    pcall(function()
        for _, g in ipairs({CoreGui, playerGui}) do
            local old = g:FindFirstChild("MM2Hub")
            if old then old:Destroy() end
        end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name           = "MM2Hub"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok then sg.Parent = playerGui end

    -- Frame principale
    local frame = Instance.new("Frame", sg)
    frame.Size             = UDim2.new(0, 180, 0, 155)
    frame.Position         = UDim2.new(0, 10, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BorderSizePixel  = 0
    frame.Active           = true
    frame.Draggable        = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    -- Titre
    local titre = Instance.new("TextLabel", frame)
    titre.Size             = UDim2.new(1, 0, 0, 30)
    titre.BackgroundColor3 = Color3.fromRGB(25, 25, 50)
    titre.Text             = "🔪 MM2 Hub"
    titre.TextColor3       = Color3.fromRGB(255, 200, 50)
    titre.Font             = Enum.Font.GothamBold
    titre.TextScaled       = true
    titre.BorderSizePixel  = 0
    Instance.new("UICorner", titre).CornerRadius = UDim.new(0, 10)

    -- Bouton FARM
    local btnFarm = Instance.new("TextButton", frame)
    btnFarm.Size             = UDim2.new(1, -16, 0, 36)
    btnFarm.Position         = UDim2.new(0, 8, 0, 38)
    btnFarm.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    btnFarm.Text             = "🪙 COINS : OFF"
    btnFarm.TextColor3       = Color3.new(1, 1, 1)
    btnFarm.Font             = Enum.Font.GothamBold
    btnFarm.TextScaled       = true
    btnFarm.BorderSizePixel  = 0
    Instance.new("UICorner", btnFarm).CornerRadius = UDim.new(0, 8)

    btnFarm.MouseButton1Click:Connect(function()
        _G.FarmActif = not _G.FarmActif
        enCours = false
        btnFarm.BackgroundColor3 = _G.FarmActif and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(200, 40, 40)
        btnFarm.Text = _G.FarmActif and "🪙 COINS : ON" or "🪙 COINS : OFF"
    end)

    -- Bouton ESP
    local btnESP = Instance.new("TextButton", frame)
    btnESP.Size             = UDim2.new(1, -16, 0, 36)
    btnESP.Position         = UDim2.new(0, 8, 0, 82)
    btnESP.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    btnESP.Text             = "👁️ ESP : OFF"
    btnESP.TextColor3       = Color3.new(1, 1, 1)
    btnESP.Font             = Enum.Font.GothamBold
    btnESP.TextScaled       = true
    btnESP.BorderSizePixel  = 0
    Instance.new("UICorner", btnESP).CornerRadius = UDim.new(0, 8)

    btnESP.MouseButton1Click:Connect(function()
        _G.ESPActif = not _G.ESPActif
        btnESP.BackgroundColor3 = _G.ESPActif and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(200, 40, 40)
        btnESP.Text = _G.ESPActif and "👁️ ESP : ON" or "👁️ ESP : OFF"
        if not _G.ESPActif then nettoyerESP() end
    end)

    -- Compteur
    local lblCompteur = Instance.new("TextLabel", frame)
    lblCompteur.Size                   = UDim2.new(1, -16, 0, 20)
    lblCompteur.Position               = UDim2.new(0, 8, 0, 128)
    lblCompteur.BackgroundTransparency = 1
    lblCompteur.Text                   = "Pièces : 0"
    lblCompteur.TextColor3             = Color3.fromRGB(180, 180, 180)
    lblCompteur.Font                   = Enum.Font.Gotham
    lblCompteur.TextScaled             = true

    RunService.Heartbeat:Connect(function()
        pcall(function() lblCompteur.Text = "Pièces collectées : " .. compteur end)
    end)
end

creerGUI()
print("[MM2 Hub] ✅ Chargé ! Boutons : Coins Farm + ESP Joueurs")
