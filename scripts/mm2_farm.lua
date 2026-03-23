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

_G.FarmActif = false
_G.ESPActif  = false

-- ─── RemoteEvents MM2 ──────────────────────────────────
local Remotes          = ReplicatedStorage:WaitForChild("Remotes")
local Gameplay         = Remotes:WaitForChild("Gameplay")
local RE_GetCoin       = Gameplay:WaitForChild("GetCoin")
local RE_CoinCollected = Gameplay:WaitForChild("CoinCollected")

-- ─── Chercher les pièces ───────────────────────────────
-- /!\ Si les coins ne se farmant pas, cherche leur vrai nom
-- dans l'Explorer de Codex pendant un round et remplace ici
-- Vrai chemin MM2 : Workspace.Coins.CoinObjects.Coin / CoinOld
local function trouverPieces()
    local pieces = {}
    pcall(function()
        local coinsFolder = workspace:FindFirstChild("Coins")
        if not coinsFolder then
            print("[MM2] Dossier Coins introuvable — round pas encore commencé ?")
            return
        end
        local coinObjects = coinsFolder:FindFirstChild("CoinObjects")
        if not coinObjects then return end
        for _, obj in ipairs(coinObjects:GetChildren()) do
            if obj.Name == "Coin" or obj.Name == "CoinOld" then
                -- Chercher la BasePart principale dans le modèle
                local part = obj:IsA("BasePart") and obj
                    or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    table.insert(pieces, part)
                end
            end
        end
    end)
    return pieces
end

-- ─── Téléportation ─────────────────────────────────────
local function teleporter(part)
    pcall(function()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
    end)
end

-- ─── Boucle Farm ───────────────────────────────────────
local compteur = 0
local enCours  = false

RunService.Heartbeat:Connect(function()
    if not _G.FarmActif then
        enCours = false
        return
    end
    if enCours then return end
    enCours = true

    task.spawn(function()
        pcall(function()
            local pieces = trouverPieces()
            if #pieces == 0 then
                print("[MM2] Aucune pièce trouvée — vérifie le nom dans l'Explorer")
                task.wait(2)
                enCours = false
                return
            end
            for _, piece in ipairs(pieces) do
                if not _G.FarmActif then break end
                if not piece or not piece.Parent then continue end
                teleporter(piece)
                task.wait(0.25)
                pcall(function() RE_GetCoin:FireServer(piece) end)
                task.wait(0.1)
                pcall(function() RE_CoinCollected:FireServer(piece) end)
                compteur = compteur + 1
                task.wait(0.15)
            end
        end)
        task.wait(0.5)
        enCours = false
    end)
end)

-- ─── ESP — recréé à chaque frame ───────────────────────
-- On détruit et recrée le BillboardGui à chaque RenderStepped
-- pour que les infos (HP, rôle) soient toujours à jour

local function getRoleEtCouleur(p)
    local role   = "Innocent"
    local couleur = Color3.fromRGB(255, 255, 255)
    pcall(function()
        local sources = {p.Character, p:FindFirstChild("Backpack")}
        for _, src in ipairs(sources) do
            if src then
                if src:FindFirstChild("Knife") then
                    role    = "⚔️ Meurtrier"
                    couleur = Color3.fromRGB(255, 60, 60)
                    return
                elseif src:FindFirstChild("Gun") then
                    role    = "🔫 Shérif"
                    couleur = Color3.fromRGB(60, 150, 255)
                    return
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

            -- Supprimer l'ancien ESP pour forcer la mise à jour
            local old = hrp:FindFirstChild("MM2_ESP")
            if old then old:Destroy() end

            if not _G.ESPActif then return end

            local humanoid = p.Character:FindFirstChild("Humanoid")
            local hp       = humanoid and math.floor(humanoid.Health) or 0
            local maxHp    = humanoid and math.floor(humanoid.MaxHealth) or 100
            local role, couleur = getRoleEtCouleur(p)

            -- Distance
            local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local dist  = myHrp and math.floor((hrp.Position - myHrp.Position).Magnitude) or 0

            local bb = Instance.new("BillboardGui")
            bb.Name          = "MM2_ESP"
            bb.Size          = UDim2.new(0, 130, 0, 52)
            bb.StudsOffset   = Vector3.new(0, 4, 0)
            bb.AlwaysOnTop   = true
            bb.Parent        = hrp

            -- Nom du joueur
            local lblNom = Instance.new("TextLabel", bb)
            lblNom.Size                   = UDim2.new(1, 0, 0.4, 0)
            lblNom.BackgroundTransparency = 1
            lblNom.Text                   = p.Name
            lblNom.TextColor3             = couleur
            lblNom.Font                   = Enum.Font.GothamBold
            lblNom.TextScaled             = true
            lblNom.TextStrokeTransparency = 0

            -- Rôle + HP + Distance
            local lblInfo = Instance.new("TextLabel", bb)
            lblInfo.Size                   = UDim2.new(1, 0, 0.35, 0)
            lblInfo.Position               = UDim2.new(0, 0, 0.4, 0)
            lblInfo.BackgroundTransparency = 1
            lblInfo.Text                   = role .. " | ❤️" .. hp .. "/" .. maxHp
            lblInfo.TextColor3             = Color3.fromRGB(220, 220, 220)
            lblInfo.Font                   = Enum.Font.Gotham
            lblInfo.TextScaled             = true
            lblInfo.TextStrokeTransparency = 0

            local lblDist = Instance.new("TextLabel", bb)
            lblDist.Size                   = UDim2.new(1, 0, 0.25, 0)
            lblDist.Position               = UDim2.new(0, 0, 0.75, 0)
            lblDist.BackgroundTransparency = 1
            lblDist.Text                   = dist .. " studs"
            lblDist.TextColor3             = Color3.fromRGB(150, 150, 150)
            lblDist.Font                   = Enum.Font.Gotham
            lblDist.TextScaled             = true
            lblDist.TextStrokeTransparency = 0
        end)
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

    local frame = Instance.new("Frame", sg)
    frame.Size             = UDim2.new(0, 180, 0, 160)
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
        btnFarm.BackgroundColor3 = _G.FarmActif
            and Color3.fromRGB(40, 180, 40)
            or  Color3.fromRGB(200, 40, 40)
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
        btnESP.BackgroundColor3 = _G.ESPActif
            and Color3.fromRGB(40, 180, 40)
            or  Color3.fromRGB(200, 40, 40)
        btnESP.Text = _G.ESPActif and "👁️ ESP : ON" or "👁️ ESP : OFF"
    end)

    -- Compteur
    local lblCompteur = Instance.new("TextLabel", frame)
    lblCompteur.Size                   = UDim2.new(1, -16, 0, 22)
    lblCompteur.Position               = UDim2.new(0, 8, 0, 130)
    lblCompteur.BackgroundTransparency = 1
    lblCompteur.Text                   = "Pièces : 0"
    lblCompteur.TextColor3             = Color3.fromRGB(180, 180, 180)
    lblCompteur.Font                   = Enum.Font.Gotham
    lblCompteur.TextScaled             = true

    RunService.Heartbeat:Connect(function()
        pcall(function()
            lblCompteur.Text = "Pièces : " .. compteur
        end)
    end)
end

creerGUI()
print("[MM2 Hub] ✅ Chargé ! ESP mis à jour en temps réel.")
