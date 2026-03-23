local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

_G.FarmActif = false

-- ─── RemoteEvents ──────────────────────────────────────
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory")
local RE_Equip      = RemotesFolder:WaitForChild("Equip")
local RE_GiveXP     = RemotesFolder:WaitForChild("GiveXP")

-- ─── Chercher les cibles DYNAMIQUEMENT ─────────────────
-- On ne fait plus WaitForChild sur le Workspace (ça bloque)
-- On scanne le Workspace à chaque cycle de farm
local NOMS_CIBLES = {
    "MysteryBoxPrompt",
    "GunPrompt",
    "ItemBundlePrompt",
    "KnifePrompt",
}

local function trouverCibles()
    local cibles = {}
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            for _, nom in ipairs(NOMS_CIBLES) do
                if obj.Name == nom and obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Part") then
                    table.insert(cibles, obj)
                    break
                end
            end
        end
    end)
    return cibles
end

-- ─── Téléportation sécurisée ───────────────────────────
local function teleporter(part)
    pcall(function()
        local character = player.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = part.CFrame + Vector3.new(0, 4, 0)
    end)
end

-- ─── Boucle farm ───────────────────────────────────────
local compteur = 0
RunService.Heartbeat:Connect(function()
    if not _G.FarmActif then return end
    pcall(function()
        local cibles = trouverCibles()
        if #cibles == 0 then
            print("[AutoFarm] Aucune cible trouvée dans le Workspace")
            return
        end
        for _, cible in ipairs(cibles) do
            teleporter(cible)
            task.wait(0.3)
            pcall(function() RE_Equip:FireServer(cible.Name) end)
            pcall(function() RE_GiveXP:FireServer(10) end)
            compteur = compteur + 1
            if compteur % 5 == 0 then
                print("[AutoFarm] Interactions : " .. compteur)
            end
            task.wait(0.5)
        end
    end)
    task.wait(1)
end)

-- ─── GUI Mobile ────────────────────────────────────────
local function creerGUI()
    -- Supprimer l'ancienne GUI si elle existe
    pcall(function()
        local old = CoreGui:FindFirstChild("MobileHub")
        if old then old:Destroy() end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name           = "MobileHub"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok then sg.Parent = playerGui end

    -- Fenêtre principale
    local frame = Instance.new("Frame", sg)
    frame.Size             = UDim2.new(0, 170, 0, 110)
    frame.Position         = UDim2.new(0, 10, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BorderSizePixel  = 0
    frame.Active           = true
    frame.Draggable        = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    -- Titre
    local titre = Instance.new("TextLabel", frame)
    titre.Size                  = UDim2.new(1, 0, 0, 28)
    titre.BackgroundColor3      = Color3.fromRGB(30, 30, 50)
    titre.Text                  = "⚡ Auto Hub"
    titre.TextColor3            = Color3.new(1, 1, 1)
    titre.Font                  = Enum.Font.GothamBold
    titre.TextScaled            = true
    titre.BorderSizePixel       = 0
    Instance.new("UICorner", titre).CornerRadius = UDim.new(0, 10)

    -- Bouton FARM
    local btnFarm = Instance.new("TextButton", frame)
    btnFarm.Size             = UDim2.new(1, -16, 0, 34)
    btnFarm.Position         = UDim2.new(0, 8, 0, 36)
    btnFarm.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    btnFarm.Text             = "🌾 FARM : OFF"
    btnFarm.TextColor3       = Color3.new(1, 1, 1)
    btnFarm.Font             = Enum.Font.GothamBold
    btnFarm.TextScaled       = true
    btnFarm.BorderSizePixel  = 0
    Instance.new("UICorner", btnFarm).CornerRadius = UDim.new(0, 8)

    btnFarm.MouseButton1Click:Connect(function()
        _G.FarmActif = not _G.FarmActif
        if _G.FarmActif then
            btnFarm.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
            btnFarm.Text = "🌾 FARM : ON"
        else
            btnFarm.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            btnFarm.Text = "🌾 FARM : OFF"
        end
    end)

    -- Compteur
    local compteurLabel = Instance.new("TextLabel", frame)
    compteurLabel.Size            = UDim2.new(1, -16, 0, 20)
    compteurLabel.Position        = UDim2.new(0, 8, 0, 78)
    compteurLabel.BackgroundTransparency = 1
    compteurLabel.Text            = "Interactions : 0"
    compteurLabel.TextColor3      = Color3.fromRGB(180, 180, 180)
    compteurLabel.Font            = Enum.Font.Gotham
    compteurLabel.TextScaled      = true

    -- Mettre à jour le compteur toutes les secondes
    RunService.Heartbeat:Connect(function()
        pcall(function()
            compteurLabel.Text = "Interactions : " .. compteur
        end)
    end)
end

creerGUI()
print("[AutoHub] ✅ GUI chargée ! Appuie sur le bouton pour activer le farm.")
