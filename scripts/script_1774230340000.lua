-- Script autofarm complet pour le jeu "Ugc"
-- Utilise uniquement les noms réels fournis dans l'exploration du jeu
-- Compatible avec tous les exécutants (Synapse, KRNL, Fluxus, Hydrogen, Arceus X, Solara)

-- Variables globales
_G.FarmActif = false

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Références du joueur
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Dossiers et RemoteEvents/RemoteFunctions (utilisation exacte des noms)
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory")

local RE_Equip = RemotesFolder:WaitForChild("Equip")
local RE_BuySlot = RemotesFolder:WaitForChild("BuySlot")
local RE_Unequip = RemotesFolder:WaitForChild("Unequip")
local RE_ToggleDeathEffects = RemotesFolder:WaitForChild("ToggleDeathEffects")
local RE_GiveXP = RemotesFolder:WaitForChild("GiveXP")
local RE_Prestige = RemotesFolder:WaitForChild("Prestige")
local RE_SaveSong = RemotesFolder:WaitForChild("SaveSong")
local RE_RenamePet = RemotesFolder:WaitForChild("RenamePet")
local RE_RemoveSong = RemotesFolder:WaitForChild("RemoveSong")
local RE_PlaySong = RemotesFolder:WaitForChild("PlaySong")
local RE_ChangeProfileData = RemotesFolder:WaitForChild("ChangeProfileData")
local RE_UpdateLeaderboard = RemotesFolder:WaitForChild("UpdateLeaderboard")

local RF_Craft = RemotesFolder:WaitForChild("Craft")
local RF_Recycle = RemotesFolder:WaitForChild("Recycle")
local RF_Salvage = RemotesFolder:WaitForChild("Salvage")
local RF_GetLeaderboardData = RemotesFolder:WaitForChild("GetLeaderboardData")
local RF_GetProfileData = RemotesFolder:WaitForChild("GetProfileData")

-- Fonction utilitaire : téléporter le joueur
local function teleporter(cframe)
    pcall(function()
        humanoidRootPart.CFrame = cframe
    end)
end

-- Fonction utilitaire : trouver le premier objet cible parmi une liste de noms
local function trouverCible(nomsCibles)
    for _, nom in ipairs(nomsCibles) do
        local cible = workspace:FindFirstChild(nom)
        if cible then
            -- Si c'est un Model, on cherche son PrimaryPart ou un part nommé "HumanoidRootPart"
            if cible:IsA("Model") then
                if cible.PrimaryPart then
                    return cible.PrimaryPart
                else
                    local hrp = cible:FindFirstChild("HumanoidRootPart") or cible:FindFirstChildWhichIsA("BasePart")
                    if hrp then
                        return hrp
                    end
                end
            elseif cible:IsA("BasePart") then
                return cible
            end
        end
    end
    return nil
end

-- Fonction d'action de farm (téléportation + interaction serveur)
local function executerFarm()
    -- Liste des cibles potentielles à farmer
    local cibles = {"Box", "Elite", "MysteryBoxPrompt", "GunPrompt", "ItemBundlePrompt", "KnifePrompt"}
    local ciblePart = trouverCible(cibles)
    if not ciblePart then
        print("[Autofarm] Aucune cible trouvée dans le workspace.")
        return
    end

    -- Téléportation juste devant la cible (offset de 3 studs)
    local cibleCFrame = ciblePart.CFrame * CFrame.new(0, 0, -3)
    teleporter(cibleCFrame)
    print("[Autofarm] Téléporté vers la cible :", ciblePart.Name)

    -- Attendre un court instant pour que le serveur détecte la présence
    task.wait(0.2)

    -- Exemple d'interaction : donner de l'XP (simule un kill ou une action)
    pcall(function()
        RE_GiveXP:FireServer(10) -- 10 XP, ajustez si besoin
        print("[Autofarm] XP envoyé au serveur.")
    end)

    -- Exemple d'équipement d'un item (si un item ID est requis, utilisez 1 comme placeholder)
    pcall(function()
        RE_Equip:FireServer(1) -- ID d'item fictif, à remplacer par un ID réel si connu
        print("[Autofarm] Tentative d'équipement d'un item.")
    end)

    -- Exemple d'achat d'un slot (si le jeu possède un système de slots)
    pcall(function()
        RE_BuySlot:FireServer()
        print("[Autofarm] Tentative d'achat d'un slot.")
    end)

    -- Exemple d'appel d'une RemoteFunction (Craft) pour fabriquer un objet
    pcall(function()
        local ok, resultat = pcall(function()
            return RF_Craft:InvokeServer("ExampleItem") -- nom d'item fictif
        end)
        if ok then
            print("[Autofarm] Craft réussi :", resultat)
        else
            warn("[Autofarm] Erreur lors du Craft :", resultat)
        end
    end)
end

-- Boucle principale de farm (Heartbeat)
local connexionFarm = RunService.Heartbeat:Connect(function()
    if not _G.FarmActif then return end
    pcall(function()
        executerFarm()
    end)
    -- Petite pause pour éviter de surcharger le serveur
    task.wait(1.5)
end)

-- Gestion du toggle via la touche "F"
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        _G.FarmActif = not _G.FarmActif
        if _G.FarmActif then
            print("[Autofarm] Activation du farm.")
        else
            print("[Autofarm] Désactivation du farm.")
        end
    end
end)

-- Nettoyage à la fin du script (au cas où le script serait désactivé)
local function nettoyer()
    if connexionFarm then
        connexionFarm:Disconnect()
    end
    print("[Autofarm] Script nettoyé.")
end

-- Déconnexion automatique si le joueur quitte
Players.PlayerRemoving:Connect(function(plr)
    if plr == localPlayer then
        nettoyer()
    end
end)