local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Initialisation du toggle global
_G.FarmActif = false

-- Récupération des RemoteEvents/RemoteFunctions (utiliser exactement les noms fournis)
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory")
local RE_Equip = RemotesFolder:WaitForChild("Equip")
local RE_BuySlot = RemotesFolder:WaitForChild("BuySlot")
local RE_GiveXP = RemotesFolder:WaitForChild("GiveXP")
local RE_ToggleDeathEffects = RemotesFolder:WaitForChild("ToggleDeathEffects")
local RE_PlaySong = RemotesFolder:WaitForChild("PlaySong")
local RE_SaveSong = RemotesFolder:WaitForChild("SaveSong")
local RE_RenamePet = RemotesFolder:WaitForChild("RenamePet")
local RE_RemoveSong = RemotesFolder:WaitForChild("RemoveSong")
local RE_PlaySong = RemotesFolder:WaitForChild("PlaySong")
local RE_ChangeProfileData = RemotesFolder:WaitForChild("ChangeProfileData")

-- Tableau des cibles à farmer (objets dans Workspace)
local Cibles = {
    workspace:WaitForChild("MysteryBoxPrompt"),
    workspace:WaitForChild("GunPrompt"),
    workspace:WaitForChild("ItemBundlePrompt"),
    workspace:WaitForChild("KnifePrompt")
}

-- Fonction de téléportation sécurisée
local function teleporter(part)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        -- On se place légèrement au-dessus du prompt pour éviter le clipping
        hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
    end)
end

-- Fonction d'interaction avec un prompt (exemple générique)
local function interagirAvecPrompt(part)
    -- Selon le type de prompt, on peut appeler différents RemoteEvents.
    -- Ici on utilise les RemoteEvents les plus génériques disponibles.
    pcall(function()
        RE_Equip:FireServer(part.Name) -- Exemple : on envoie le nom du prompt
    end)
    pcall(function()
        RE_BuySlot:FireServer(part.Name, 1) -- Exemple : acheter le slot 1 du prompt
    end)
    pcall(function()
        RE_GiveXP:FireServer(10) -- Exemple : donner 10 XP (si applicable)
    end)
end

-- Boucle principale de l'autofarm
local connexion = RunService.Heartbeat:Connect(function()
    if not _G.FarmActif then return end
    for _, cible in ipairs(Cibles) do
        if not cible or not cible:IsDescendantOf(workspace) then continue end
        teleporter(cible)
        task.wait(0.3) -- petite pause pour laisser le serveur mettre à jour la position
        interagirAvecPrompt(cible)
        print("[AutoFarm] Interaction avec :", cible.Name)
        task.wait(0.7) -- pause entre chaque cible
    end
end)

-- GUI mobile obligatoire
local function creerGUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "MobileHub"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = playerGui end

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 160, 0, 50)
    frame.Position = UDim2.new(0, 10, 0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -10, 1, -10)
    btn.Position = UDim2.new(0, 5, 0, 5)
    btn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    btn.Text = "FARM : OFF"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        _G.FarmActif = not _G.FarmActif
        btn.BackgroundColor3 = _G.FarmActif and Color3.fromRGB(50,200,50) or Color3.fromRGB(220,50,50)
        btn.Text = _G.FarmActif and "FARM : ON" or "FARM : OFF"
        print("[AutoFarm] Statut :", _G.FarmActif and "Activé" or "Désactivé")
    end)
end

creerGUI()