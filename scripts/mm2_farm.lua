-- ╔══════════════════════════════════════════════════════╗
-- ║         MM2 COIN FARM - Murder Mystery 2             ║
-- ║         GUI Mobile + Farm Pièces                     ║
-- ╚══════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Toggles ───────────────────────────────────────────
_G.FarmActif = false

-- ─── RemoteEvents MM2 (vrais noms du scan) ─────────────
local Gameplay      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay")
local RE_GetCoin    = Gameplay:WaitForChild("GetCoin")
local RE_CoinCollected = Gameplay:WaitForChild("CoinCollected")

-- ─── Trouver les pièces dans le Workspace ──────────────
local function trouverPieces()
    local pieces = {}
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (
                obj.Name == "Coin"       or
                obj.Name == "coin"       or
                obj.Name == "GoldCoin"   or
                obj.Name == "Collectible"
            ) then
                table.insert(pieces, obj)
            end
        end
    end)
    return pieces
end

-- ─── Téléportation vers une pièce ──────────────────────
local function teleporter(part)
    pcall(function()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
    end)
end

-- ─── Boucle farm principale ────────────────────────────
local compteur  = 0
local enCours   = false -- empêche les appels simultanés

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

            -- Téléporter vers la pièce
            teleporter(piece)
            task.wait(0.15)

            -- Déclencher la collecte avec les vrais RemoteEvents MM2
            pcall(function() RE_GetCoin:FireServer(piece) end)
            pcall(function() RE_CoinCollected:FireServer(piece) end)

            compteur = compteur + 1
            task.wait(0.1)
        end
    end)

    task.wait(0.5)
    enCours = false
end)

-- ─── Re-appliquer après respawn ────────────────────────
player.CharacterAdded:Connect(function()
    task.wait(1)
    print("[MM2 Farm] Personnage respawn, farm continue...")
end)

-- ─── GUI Mobile ────────────────────────────────────────
local function creerGUI()
    pcall(function()
        local old = CoreGui:FindFirstChild("MM2Hub")
        if old then old:Destroy() end
    end)
    pcall(function()
        local old = playerGui:FindFirstChild("MM2Hub")
        if old then old:Destroy() end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name           = "MM2Hub"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok then sg.Parent = playerGui end

    -- Frame principale
    local frame = Instance.new("Frame", sg)
    frame.Size             = UDim2.new(0, 175, 0, 120)
    frame.Position         = UDim2.new(0, 10, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BorderSizePixel  = 0
    frame.Active           = true
    frame.Draggable        = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    -- Barre de titre
    local titre = Instance.new("TextLabel", frame)
    titre.Size                       = UDim2.new(1, 0, 0, 30)
    titre.BackgroundColor3           = Color3.fromRGB(25, 25, 45)
    titre.Text                       = "🔪 MM2 Farm Hub"
    titre.TextColor3                 = Color3.fromRGB(255, 200, 50)
    titre.Font                       = Enum.Font.GothamBold
    titre.TextScaled                 = true
    titre.BorderSizePixel            = 0
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
        if _G.FarmActif then
            btnFarm.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
            btnFarm.Text = "🪙 COINS : ON"
        else
            btnFarm.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            btnFarm.Text = "🪙 COINS : OFF"
            enCours = false
        end
    end)

    -- Compteur de pièces
    local lblCompteur = Instance.new("TextLabel", frame)
    lblCompteur.Size                       = UDim2.new(1, -16, 0, 22)
    lblCompteur.Position                   = UDim2.new(0, 8, 0, 84)
    lblCompteur.BackgroundTransparency     = 1
    lblCompteur.Text                       = "Pièces collectées : 0"
    lblCompteur.TextColor3                 = Color3.fromRGB(180, 180, 180)
    lblCompteur.Font                       = Enum.Font.Gotham
    lblCompteur.TextScaled                 = true

    -- Mise à jour du compteur
    RunService.Heartbeat:Connect(function()
        pcall(function()
            lblCompteur.Text = "Pièces collectées : " .. compteur
        end)
    end)
end

creerGUI()
print("[MM2 Farm] ✅ Chargé ! Appuie sur le bouton pour farmer les pièces.")
