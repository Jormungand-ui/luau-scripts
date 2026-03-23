local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character

-- Initialisation des variables
local _G = _G or {}
_G.FarmActif = false

-- Configuration des objets
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Inventory = Remotes:WaitForChild("Inventory")
local Craft = Inventory:WaitForChild("Craft")
local Equip = Inventory:WaitForChild("Equip")
local Recycle = Inventory:WaitForChild("Recycle")
local BuySlot = Inventory:WaitForChild("BuySlot")
local Unequip = Inventory:WaitForChild("Unequip")
local Salvage = Inventory:WaitForChild("Salvage")
local UpdateLeaderboard = Inventory:WaitForChild("UpdateLeaderboard")
local GetLeaderboardData = Inventory:WaitForChild("GetLeaderboardData")
local GiveXP = Inventory:WaitForChild("GiveXP")

-- Fonction pour téléporter le joueur vers une cible
local function teleportTo(cframe)
    if character then
        pcall(function()
            character.HumanoidRootPart.CFrame = cframe
        end)
    end
end

-- Fonction pour équiper un objet
local function equipItem()
    if character then
        pcall(function()
            Equip:FireServer()
        end)
        print("Objet équipé")
    end
end

-- Fonction pour déséquiper un objet
local function unequipItem()
    if character then
        pcall(function()
            Unequip:FireServer()
        end)
        print("Objet déséquipé")
    end
end

-- Fonction pour récolter des ressources
local function collectResources()
    if character then
        pcall(function()
            Craft:InvokeServer()
        end)
        print("Ressources récoltées")
    end
end

-- Fonction pour donner de l'expérience au joueur
local function giveXPToPlayer()
    if character then
        pcall(function()
            GiveXP:FireServer()
        end)
        print("Expérience donnée")
    end
end

-- Boucle principale
RunService.Heartbeat:Connect(function()
    if _G.FarmActif then
        -- Téléporter vers les cibles
        local Lobby = workspace:WaitForChild("Lobby")
        local Spawns = Lobby:WaitForChild("Spawns")
        local spawns = Spawns:GetChildren()
        if #spawns > 0 then
            local spawn = spawns[math.random(1, #spawns)]
            teleportTo(spawn.CFrame)
        end

        -- Équiper un objet
        equipItem()

        -- Collecter des ressources
        collectResources()

        -- Déséquiper un objet
        unequipItem()

        -- Donner de l'expérience au joueur
        giveXPToPlayer()

        print("Farm actif")
    else
        print("Farm inactif")
    end
end)

-- Activation/désactivation du farm
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F5 then
        _G.FarmActif = not _G.FarmActif
        print("Farm actif : " .. tostring(_G.FarmActif))
    end
end)