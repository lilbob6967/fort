-- Obsidian (mspaint) UI — CLIENT / LOCAL (v.122 - TOTAL RESTORATION)
-- Obsidian (mspaint) UI — CLIENT / LOCAL (v.122 - TOTAL RESTORATION)
-- AUTHOR: King's Architect
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- // SERVICES //
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

-- // LOCALS //
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

----------------------------------------------------------------
-- SPEED BYPASS (METATABLE HOOK)
----------------------------------------------------------------
local function EnableSpeedBypass()
    if not getrawmetatable then return end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldindex = mt.__index
    
    mt.__index = newcclosure(function(self, k)
        if k == "WalkSpeed" and not checkcaller() then
            return 16 -- Reports normal speed to server checks
        end
        return oldindex(self, k)
    end)
    
    setreadonly(mt, true)
end
pcall(EnableSpeedBypass)

----------------------------------------------------------------
-- UI WINDOW SETUP
----------------------------------------------------------------
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "mspaint",
    Footer = "fortnite fentsite script v.122 (King Edition)",
    Icon = 95816097006870,
    NotifySide = "Right",
    Center = true,
    AutoShow = true,
    EnableSidebarResize = true, 
})

local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Self = Window:AddTab("Self", "user"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Exploits = Window:AddTab("Exploits", "zap"),
    Fun = Window:AddTab("Fun", "smile"),
    Zeta = Window:AddTab("Zeta", "star"),
    ESP = Window:AddTab("ESP", "eye"),
    UI = Window:AddTab("UI Settings", "settings"),
}

----------------------------------------------------------------
-- GLOBALS & CONTAINERS
----------------------------------------------------------------
local VisualFolder = workspace:FindFirstChild("EliteVisuals") or Instance.new("Folder", workspace)
VisualFolder.Name = "EliteVisuals"
local TempFolder = workspace:FindFirstChild("EliteTempVisuals") or Instance.new("Folder", workspace)
TempFolder.Name = "EliteTempVisuals"

local SixEyesCC = Instance.new("ColorCorrectionEffect", Lighting)
SixEyesCC.Name = "SixEyesTint"
SixEyesCC.Enabled = false

local EliteTimers = { Rally = 0, Adrenaline = 0 }
local BioHUD = Library:AddDraggableLabel("Bio-HUD")
BioHUD:SetVisible(false) 

local SlideTrack = nil
local ChatConnections = {}
local CachedDoors = {}
local CachedGlass = {}
local CachedItems = {}
local ItemESPObjects = {}
local KnownSpawns = setmetatable({}, {__mode = "k"})
local ItemESPFilter = nil
local ItemNotifyFilter = nil
local ItemTeleportDropdown = nil

local CachedWeapons = {}
local KnownWeaponSpawns = setmetatable({}, {__mode = "k"})
local WeaponESPFilter = nil
local WeaponNotifyFilter = nil
local WeaponTeleportDropdown = nil
local ViewerDropdown = nil -- Forward declaration for Visuals/Spectate
local ZetaDropdown = nil
local HealTargetDrop = nil
local CreateItemESP -- Forward declaration

-- // COMBAT GLOBALS //
local CombatStorage = {}
local LawCombatants = {
    ["Specialized Response Squad"] = true, ["Facility Security"] = true,
    ["Facility Intelligence"] = true, ["Facility Administration"] = true,
    ["Facility Director"] = true
}
local HardHostileTeams = { ["Hostile Forces"] = true }
local NeutralStaffTeams = {
    ["Medical Staff"] = true, ["Technical Staff"] = true, ["Zeta Labs"] = true, 
    ["ZMTech"] = true
}
local PerkNames = {"Frost", "Tactician", "Brute", "Rogue", "Ghost", "Desperado"}

local Remotes = {
    Heal = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:WaitForChild("Events", 5) and ReplicatedStorage.Remotes.Events:FindFirstChild("UseTool"),
    BruteBreak = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:WaitForChild("Events", 5) and ReplicatedStorage.Remotes.Events:FindFirstChild("BruteBreak"),
    Door = ReplicatedStorage:WaitForChild("DynamicRemotes", 5) and ReplicatedStorage.DynamicRemotes:WaitForChild("Interaction_Remotes", 5) and ReplicatedStorage.DynamicRemotes.Interaction_Remotes:FindFirstChild("Interaction_RF")
}


----------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------
local function getAnyAttr(plr, attr)
    if not plr then return nil end
    local char = plr.Character
    if char and char:GetAttribute(attr) ~= nil then return char:GetAttribute(attr) end
    if plr:GetAttribute(attr) ~= nil then return plr:GetAttribute(attr) end
    local data = plr:FindFirstChild("Data")
    local val = data and data:FindFirstChild(attr)
    return val and val.Value or nil
end

local LastTargetHL = nil
local function UpdateHighlight(targetModel, color, name)
    if not targetModel or not targetModel:IsA("Model") then return end
    local hl = targetModel:FindFirstChild(name)
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = name
        hl.Parent = targetModel
    end
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = true
    return hl
end

local function ClearHighlightsWithName(name)
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        local hl = char and char:FindFirstChild(name)
        if hl then hl:Destroy() end
    end
end

local function formatInt(n)
    return tostring(math.floor(tonumber(n) or 0)):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local function GetClosestPlayerToMouse()
    local target = nil
    local minDist = 300
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos, vis = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if vis then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < minDist then
                    minDist = dist
                    target = p
                end
            end
        end
    end
    return target
end

local function GetNearestPlayer()
    local closest, minDist = nil, math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
                if dist < minDist then minDist = dist closest = p end
            end
        end
    end
    return closest
end

local function GetNearestCachedItem(itemName)
    local closest, minDist = nil, math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, itemData in ipairs(CachedItems) do
        if itemData.Name == itemName then
            local dist = (itemData.Position - myRoot.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = itemData
            end
        end
    end
    return closest
end

local function GetNearestCachedWeapon(weaponName)
    local closest, minDist = nil, math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, weaponData in ipairs(CachedWeapons) do
        if weaponData.Name == weaponName then
            local dist = (weaponData.Position - myRoot.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = weaponData
            end
        end
    end
    return closest
end

local function DrawTracer(fromPos, toPos, color)
    local attachment0 = Instance.new("Attachment", TempFolder)
    attachment0.WorldPosition = fromPos
    
    local attachment1 = Instance.new("Attachment", TempFolder)
    attachment1.WorldPosition = toPos
    
    local beam = Instance.new("Beam", TempFolder)
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Color = ColorSequence.new(color)
    beam.Width0 = 0.1
    beam.Width1 = 0.1
    beam.FaceCamera = true
end

-- // COMBAT HELPERS //
local function IsVisible(targetPart)
    local character = LocalPlayer.Character
    if not character then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), rayParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetPlayerPerk(player)
    local data = player:FindFirstChild("Data")
    if data then
        for _, perkName in pairs(PerkNames) do
            local perk = data:FindFirstChild(perkName)
            if perk and perk:IsA("BoolValue") and perk.Value == true then
                return perkName
            end
        end
    end
    return "None"
end

local function GetEvolution(player)
    local char = player.Character
    local data = player:FindFirstChild("Data")
    local evoFolder = data and data:FindFirstChild("Evolution")
    local evoType = (char and char:GetAttribute("EvolutionType")) or (evoFolder and evoFolder:GetAttribute("EvolutionType"))
    if evoType and evoType ~= "" and evoType ~= "None" then return tostring(evoType) end
    local potential = (char and char:GetAttribute("PotentialEvolution")) or (evoFolder and evoFolder:FindFirstChild("PotentialEvolution"))
    if potential then
        local pVal = (typeof(potential) == "Instance") and potential.Value or potential
        if pVal and pVal ~= "" and pVal ~= "None" then return tostring(pVal) end
    end
    local advanced = (char and char:GetAttribute("HasReachedAdvancedMutation")) or (evoFolder and evoFolder:FindFirstChild("HasReachedAdvancedMutation"))
    if advanced and (advanced == true or (typeof(advanced) == "Instance" and advanced.Value == true)) then return "Advanced" end
    return "N/A"
end

local function GetZetaIcons(player)
    local char = player.Character
    if not char then return false, false, false end
    local head = char:FindFirstChild("Head")
    if head then
        local tag = head:FindFirstChild(player.Name)
        if tag and tag:IsA("BillboardGui") then
            local frame = tag:FindFirstChild("Frame")
            local icons = frame and frame:FindFirstChild("Icons")
            if icons then
                local traitor = icons:FindFirstChild("Traitor")
                local terminate = icons:FindFirstChild("Terminate")
                local isT = traitor and traitor.Visible
                local isTerm = terminate and terminate.Visible
                local isGT = false
                if isT and traitor.ImageColor3 == Color3.fromRGB(205, 84, 75) then
                    isGT = true
                    isT = false
                end
                return isT, isTerm, isGT
            end
        end
    end
    return false, false, false
end

local function UpdatePlayerStatus(player)
    local char = player.Character
    if not char then return end
    local isTraitor, isTerminate, isGT = GetZetaIcons(player)
    local hasPRM = char:FindFirstChild("PRM-MK1R") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("PRM-MK1R"))
    local activePerk = GetPlayerPerk(player)
    local activeEvo = GetEvolution(player)
    
    if not CombatStorage[player] then CombatStorage[player] = {} end
    CombatStorage[player].IsTraitor = isTraitor
    CombatStorage[player].IsTerminate = isTerminate
    CombatStorage[player].IsGT = isGT
    CombatStorage[player].HasPRM = hasPRM
    CombatStorage[player].Perk = activePerk
    CombatStorage[player].Evo = activeEvo
    CombatStorage[player].Armor = char:GetAttribute("Armor") or 0
    CombatStorage[player].IsProtected = char:FindFirstChildOfClass("ForceField") ~= nil
end

local function GetHostilityState(player)
    if not CombatStorage[player] or not player.Team then return "Neutral" end
    local s = CombatStorage[player]
    if s.IsProtected then return "Neutral" end
    if s.IsGT or player.Team.Name == "Mutant" or (s.Evo and s.Evo ~= "N/A") then return "GT" end
    local team = player.Team.Name
    if team == "Patient" then return s.IsTerminate and "HostilePatient" or "Neutral"
    elseif NeutralStaffTeams[team] then return s.IsTraitor and "TraitorStaff" or "Neutral"
    elseif HardHostileTeams[team] then return "HostileForce"
    elseif LawCombatants[team] then return "Law" end
    return "Neutral"
end

local function IsTargetHostile(otherPlayer)
    local me, them = GetHostilityState(LocalPlayer), GetHostilityState(otherPlayer)
    local hum = otherPlayer.Character and otherPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if me == "Neutral" then return false end
    if me == "GT" or them == "GT" then return true end
    if me == "Law" then return (them == "HostilePatient" or them == "TraitorStaff" or them == "HostileForce") end
    if (me == "HostilePatient" or me == "TraitorStaff") and them == "Law" then return true end
    if me == "HostileForce" and them == "Law" then return true end
    return false
end

local function RemoveESP(player)
    if CombatStorage[player] and CombatStorage[player].Drawings then
        for _, obj in pairs(CombatStorage[player].Drawings) do obj.Visible = false; obj:Remove() end
        CombatStorage[player].ESPConnection:Disconnect()
        CombatStorage[player].Drawings = nil
        CombatStorage[player].ESPConnection = nil
    end
end

local function CreatePlayerESP(player)
    RemoveESP(player)
    if not CombatStorage[player] then CombatStorage[player] = {} end
    
    local drawings = {
        BarOutline = Drawing.new("Square"),
        Bar = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Status = Drawing.new("Text"),
        EvoTag = Drawing.new("Text"),
        PerkTag = Drawing.new("Text"),
        PRMTag = Drawing.new("Text"),
        ArmorTag = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    for _, tag in pairs({drawings.Name, drawings.EvoTag, drawings.PerkTag, drawings.Status, drawings.PRMTag, drawings.ArmorTag, drawings.Distance}) do
        tag.Center = true; tag.Outline = true
    end
    
    drawings.Status.Color = Color3.fromRGB(255, 0, 0)
    drawings.EvoTag.Color = Color3.new(1, 1, 1)
    drawings.PerkTag.Color = Color3.new(1, 1, 1)
    drawings.PRMTag.Color = Color3.fromRGB(160, 160, 160)
    drawings.ArmorTag.Color = Color3.fromRGB(0, 255, 255)
    drawings.BarOutline.Color = Color3.new(0,0,0)
    drawings.Bar.Filled = true; drawings.Bar.Color = Color3.new(0, 1, 0)

    local connection
    connection = RunService.RenderStepped:Connect(function()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if Library.Toggles.CombatESP.Value and hrp and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                local s = CombatStorage[player]
                local teamColor = player.TeamColor.Color
                local scale = math.clamp(1 - (dist / 400), 0.7, 1) 
                local fontSize = 15 * scale
                local barWidth = 65 * scale 
                local currentY = pos.Y - 35
                local isMutant = s.IsGT or (player.Team and player.Team.Name == "Mutant") or (s.Evo and s.Evo ~= "N/A")

                if Library.Toggles.ESPServerStatus.Value then
                    if isMutant then
                        drawings.Status.Visible = true; drawings.Status.Size = fontSize
                        drawings.Status.Text = "MUTANT"
                        drawings.Status.Position = Vector2.new(pos.X, currentY); currentY = currentY + fontSize
                    elseif s.IsTraitor or s.IsTerminate then
                        drawings.Status.Visible = true; drawings.Status.Size = fontSize
                        drawings.Status.Text = s.IsTraitor and "TRAITOR" or "HOSTILE"
                        drawings.Status.Position = Vector2.new(pos.X, currentY); currentY = currentY + fontSize
                    else drawings.Status.Visible = false end
                else drawings.Status.Visible = false end

                drawings.Name.Visible = true; drawings.Name.Text = player.Name; drawings.Name.Size = fontSize; drawings.Name.Color = teamColor; drawings.Name.Position = Vector2.new(pos.X, currentY)
                currentY = currentY + fontSize + 2

                local healthPerc = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                drawings.BarOutline.Visible = true; drawings.BarOutline.Size = Vector2.new(barWidth, 5); drawings.BarOutline.Position = Vector2.new(pos.X - barWidth/2, currentY)
                drawings.Bar.Visible = true; drawings.Bar.Size = Vector2.new((barWidth-2) * healthPerc, 3); drawings.Bar.Position = Vector2.new(pos.X - barWidth/2 + 1, currentY + 1)
                currentY = currentY + 10

                if Library.Toggles.ESPEvolution.Value and s.Evo and s.Evo ~= "N/A" then
                    drawings.EvoTag.Visible = true; drawings.EvoTag.Text = "Evo: " .. s.Evo
                    drawings.EvoTag.Size = fontSize; drawings.EvoTag.Position = Vector2.new(pos.X, currentY); currentY = currentY + fontSize
                else drawings.EvoTag.Visible = false end

                if Library.Toggles.ESPPerks.Value and not isMutant then
                    drawings.PerkTag.Visible = true; drawings.PerkTag.Text = "Perks: " .. (s.Perk or "None")
                    drawings.PerkTag.Size = fontSize; drawings.PerkTag.Position = Vector2.new(pos.X, currentY); currentY = currentY + fontSize
                else drawings.PerkTag.Visible = false end

                if Library.Toggles.ESPPRM.Value and s.HasPRM then
                    drawings.PRMTag.Visible = true; drawings.PRMTag.Text = "PRM"; drawings.PRMTag.Size = fontSize; drawings.PRMTag.Position = Vector2.new(pos.X, currentY); currentY = currentY + fontSize
                else drawings.PRMTag.Visible = false end

                if Library.Toggles.ESPArmor.Value and s.Armor and s.Armor > 0 then
                    drawings.ArmorTag.Visible = true; drawings.ArmorTag.Text = "Armor: " .. math.floor(s.Armor)
                    drawings.ArmorTag.Size = fontSize; drawings.ArmorTag.Position = Vector2.new(pos.X, currentY); currentY = currentY + fontSize
                else drawings.ArmorTag.Visible = false end

                if Library.Toggles.ESPDistance.Value then
                    drawings.Distance.Visible = true; drawings.Distance.Text = math.floor(dist) .. "m"; drawings.Distance.Size = fontSize + 2; drawings.Distance.Color = teamColor; drawings.Distance.Position = Vector2.new(pos.X, currentY + 2)
                else drawings.Distance.Visible = false end
                return
            end
        end
        for _, obj in pairs(drawings) do obj.Visible = false end
    end)
    CombatStorage[player].Drawings = drawings
    CombatStorage[player].ESPConnection = connection
end
-- Shared ESP Creation (Robust)
local function CreateESPLabel(target, name, color)
    if not target then return end
    
    local adornee = target:IsA("BasePart") and target 
        or target:IsA("Model") and (target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart"))
        or target:FindFirstAncestorWhichIsA("BasePart")
        or (target:IsA("Attachment") and target.Parent:IsA("BasePart") and target.Parent)
        
    if not adornee then return end
    
    -- Use a dedicated folder in workspace to avoid camera sync issues
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EliteItemESP"
    billboard.Parent = VisualFolder
    billboard.Adornee = adornee
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 150, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Enabled = true
    
    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = color or Color3.new(1, 1, 0)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    
    return billboard
end

local function ScanFacility(mode) -- mode: 1 = Items, 2 = Weapons
    local cache = mode == 1 and CachedItems or CachedWeapons
    local known = mode == 1 and KnownSpawns or KnownWeaponSpawns
    local filterValue = Library.Options[mode == 1 and "ItemNotifyFilter" or "WeaponNotifyFilter"].Value
    local dropdowns = {
        esp = mode == 1 and ItemESPFilter or WeaponESPFilter,
        notify = mode == 1 and ItemNotifyFilter or WeaponNotifyFilter,
        tp = mode == 1 and ItemTeleportDropdown or WeaponTeleportDropdown
    }

    -- Cleanup old billboards
    for _, v in ipairs(cache) do if v.Billboard then v.Billboard:Destroy() end end
    table.clear(cache)

    local foundNames = {}
    local counts = {}
    local notifyBaseNames = {}

    if filterValue then
        for selection, _ in pairs(filterValue) do
            local baseName = selection:match("(.+) %- X%d+") or selection
            notifyBaseNames[baseName] = true
        end
    end

    local facility = workspace:FindFirstChild("Facility")
    if not facility then 
        return Library:Notify("Facility folder not found in Workspace! Map might be different.", 3) 
    end

    -- Use GetDescendants for robustness (folders might be nested differently)
    for _, spawn in ipairs(facility:GetDescendants()) do
        local itemName = spawn:GetAttribute("Item")
        -- Valid spawns must have an Item attribute OR be specifically named ItemSpawn
        if itemName or spawn.Name == "ItemSpawn" then
            itemName = itemName or "Unknown Item"
            local isWeapon = spawn:FindFirstAncestor("WeaponLocker") ~= nil
            
            if (mode == 1 and not isWeapon) or (mode == 2 and isWeapon) then
                foundNames[itemName] = true
                counts[itemName] = (counts[itemName] or 0) + 1

                if notifyBaseNames[itemName] and not known[spawn] then
                    Library:Notify("Spawned: " .. itemName, 5)
                    known[spawn] = true
                end

                local pos = spawn:IsA("BasePart") and spawn.Position or spawn:GetPivot().Position
                local billboard = CreateESPLabel(spawn, itemName, mode == 1 and Color3.new(1, 1, 0) or Color3.new(0, 1, 1))
                
                if billboard then
                    billboard.Enabled = Library.Toggles[mode == 1 and "ShowItemESP" or "ShowWeaponESP"].Value
                    table.insert(cache, {
                        Name = itemName,
                        Spawn = spawn,
                        Position = pos,
                        Billboard = billboard
                    })
                end
            end
        end
    end

    -- Update UI
    if dropdowns.esp then
        local list = {}
        for name in pairs(foundNames) do table.insert(list, string.format("%s - X%d", name, counts[name])) end
        table.sort(list)
        dropdowns.esp:SetValues(list)
        dropdowns.notify:SetValues(list)
        dropdowns.tp:SetValues(list)
    end
end

local function ScanForItems() ScanFacility(1) end
local function ScanForWeapons() ScanFacility(2) end

----------------------------------------------------------------
-- LOGIC: MOVEMENT & COMBAT
----------------------------------------------------------------
local function CreateGhost(targetCFrame)
    local char = LocalPlayer.Character
    if not char then return end
    local ghostModel = Instance.new("Model", workspace)
    ghostModel.Name = "VFX_Trail"
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 and part.Name ~= "HumanoidRootPart" then
            local clone = part:Clone()
            clone:ClearAllChildren()
            clone.Parent = ghostModel
            clone.Anchored = true
            clone.CanCollide = false
            clone.Material = Enum.Material.Neon
            clone.Color = Color3.fromRGB(200, 200, 200)
            clone.Transparency = 0.6
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                clone.CFrame = targetCFrame * root.CFrame:ToObjectSpace(part.CFrame)
            end
        end
    end
    
    task.spawn(function()
        for i = 0.6, 1, 0.1 do
            task.wait(0.05)
            for _, p in ipairs(ghostModel:GetChildren()) do p.Transparency = i end
        end
        ghostModel:Destroy()
    end)
end

local function DoFlashstep(mode)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    local targetCF, startCF = nil, root.CFrame
    
    if mode == 1 then
        local distance = Library.Options.FlashDistance.Value
        local direction = root.CFrame.LookVector * Vector3.new(1, 0, 1).Unit
        targetCF = CFrame.new(root.Position + (direction * distance), root.Position + (direction * distance) + direction)
    else
        local targetPlayer = GetClosestPlayerToMouse()
        if not targetPlayer or not targetPlayer.Character then return Library:Notify("No target found!", 1) end
        local tRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not tRoot then return end
        
        -- Optimized Behind Position: Use target's LookVector to find absolute back
        local backOffset = (tRoot.CFrame.LookVector * -4)
        local targetPos = tRoot.Position + backOffset
        
        -- Raycast from target center to back position to avoid teleporting into walls behind target
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {targetPlayer.Character, char, VisualFolder, TempFolder}
        rp.FilterType = Enum.RaycastFilterType.Exclude
        
        local backRay = workspace:Raycast(tRoot.Position, backOffset, rp)
        if backRay then
            targetPos = backRay.Position + (backRay.Normal * 1.5)
        end
        
        -- Point at target
        targetCF = CFrame.new(targetPos, tRoot.Position)
    end

    if Library.Toggles.FS_Wallcheck.Value and mode == 1 then -- Wallcheck only for normal dash
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local dir = targetCF.Position - root.Position
        local ray = workspace:Raycast(root.Position, dir, params)
        if ray then targetCF = CFrame.new(ray.Position - (dir.Unit * 2), targetCF.Position + targetCF.LookVector) end
    end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    local downRay = workspace:Raycast(targetCF.Position + Vector3.new(0, 5, 0), Vector3.new(0, -20, 0), params)
    local finalY = downRay and (downRay.Position.Y + hum.HipHeight + 0.5) or (targetCF.Position.Y - hum.HipHeight)
    
    -- Construct final CFrame: Position with correct Y, and Rotation from targetCF
    local finalCF = CFrame.new(targetCF.X, finalY, targetCF.Z) * targetCF.Rotation

    root.CFrame = finalCF
    root.AssemblyLinearVelocity = Vector3.zero

    if mode == 1 then 
        task.spawn(function()
            local steps = 6
            for i = 1, steps do
                local lerpCF = startCF:Lerp(finalCF, i/steps)
                CreateGhost(lerpCF)
                task.wait(0.02)
            end
        end)
    end
end

local function ManageSlideAnimation(state)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    local animator = hum and hum:FindFirstChild("Animator")
    if not animator then return end

    if state then
        if not SlideTrack then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://98871697427845"
            SlideTrack = animator:LoadAnimation(anim)
            SlideTrack.Priority = Enum.AnimationPriority.Action4
            SlideTrack.Looped = true 
        end
        if not SlideTrack.IsPlaying then 
            SlideTrack:Play(0.1, 1, 1.2) 
        end
    else
        if SlideTrack then 
            SlideTrack:Stop()
            SlideTrack:Destroy()
            SlideTrack = nil 
        end
    end
end

local function UseItemSpoof(targetPlayer)
    local char = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    local toolName = Library.Options.HealTool.Value
    local tool = char:FindFirstChild(toolName) or backpack:FindFirstChild(toolName) or backpack:FindFirstChildOfClass("Tool")
    
    if not tool then return end
    local equipped = char:FindFirstChildOfClass("Tool")
    
    -- Invisible Spoof Logic
    local visuals = {}
    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") then
            visuals[v] = v.Transparency
            v.Transparency = 1
        end
    end

    -- Suppress arm animation by parenting manually or destroying the grip weld immediately
    local oldParent = tool.Parent
    tool.Parent = char
    
    task.spawn(function()
        local grip = char:FindFirstChild("RightGrip", true)
        if grip then grip:Destroy() end
    end)

    task.wait(0.05)
    if Remotes.Heal then 
        Remotes.Heal:FireServer(targetPlayer) 
    end
    task.wait(0.05)
    
    -- Cleanup
    tool.Parent = backpack
    for v, trans in pairs(visuals) do
        if v and v.Parent then v.Transparency = trans end
    end
    
    if equipped and equipped.Parent == backpack then
        char.Humanoid:EquipTool(equipped)
    end
end

----------------------------------------------------------------
-- TAB 1: MAIN
----------------------------------------------------------------
local MainGroup = Tabs.Main:AddLeftGroupbox("Dashboard")
MainGroup:AddLabel("Status: Active")
MainGroup:AddButton({
    Text = "Refresh Map Cache",
    Func = function()
        table.clear(CachedDoors)
        table.clear(CachedGlass)
        
        if workspace:FindFirstChild("Facility") then
            for _, v in ipairs(workspace.Facility:GetDescendants()) do
                if v.Name == "Doors" then 
                    for _, d in ipairs(v:GetChildren()) do 
                        table.insert(CachedDoors, d) 
                    end 
                elseif v.Name == "Glass" or v.Name == "Window" then
                    table.insert(CachedGlass, v)
                end
            end
        end
        
        Library:Notify(string.format("Refreshed. Found %d Doors, %d Glass.", #CachedDoors, #CachedGlass), 2)
    end,
    Tooltip = "Scans workspace for interactive doors and glass objects for exploits"
})

local ItemScanGroup = Tabs.ESP:AddLeftGroupbox("Item Scanner")
ItemScanGroup:AddButton({
    Text = "Scan for Items",
    Func = function()
        ScanForItems()
        Library:Notify(string.format("Item Scanner: Found %d items in Facility", #CachedItems), 2)
    end,
    Tooltip = "Scans all ItemRacks in Facility Sectors 1-3 for spawnable items"
})

ItemScanGroup:AddToggle("AutoRefreshItems", {
    Text = "Auto-Refresh Items",
    Default = false,
    Tooltip = "Automatically rescans for items every 5 seconds"
})

ItemScanGroup:AddToggle("ShowItemESP", {
    Text = "Show Item ESP",
    Default = false,
    Tooltip = "Displays ESP overlays with item names above each item spawn location"
})

ItemESPFilter = ItemScanGroup:AddDropdown("ItemESPFilter", {
    Text = "ESP Filter",
    Values = {},
    Multi = true,
    Tooltip = "Select specific items to show ESP for (Empty = All)"
})

ItemNotifyFilter = ItemScanGroup:AddDropdown("ItemNotifyFilter", {
    Text = "Notification Filter",
    Values = {},
    Multi = true,
    Tooltip = "Select items to get a notification when they spawn"
})

ItemTeleportDropdown = ItemScanGroup:AddDropdown("ItemTeleportDropdown", {
    Text = "Teleport Target",
    Values = {},
    Tooltip = "Select an item to teleport to the nearest instance of"
})

ItemScanGroup:AddButton({
    Text = "Teleport to Nearest Item",
    Func = function()
        local selectedItem = Library.Options.ItemTeleportDropdown.Value
        if not selectedItem then return Library:Notify("No item selected!", 2) end
        
        local itemName = selectedItem:match("(.+) %- X%d+") or selectedItem

        local nearestItem = GetNearestCachedItem(itemName)
        if nearestItem and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(nearestItem.Position + Vector3.new(0, 3, 0))
            Library:Notify("Teleported to " .. itemName, 2)
        else
            Library:Notify("Could not find " .. itemName .. " or character is missing.", 2)
        end
    end,
    Tooltip = "Teleports you to the nearest instance of the selected item."
})

local WeaponScanGroup = Tabs.ESP:AddRightGroupbox("Weapon Scanner")
WeaponScanGroup:AddButton({
    Text = "Scan for Weapons",
    Func = function()
        ScanForWeapons()
        Library:Notify(string.format("Weapon Scanner: Found %d weapons in Facility", #CachedWeapons), 2)
    end,
    Tooltip = "Scans all WeaponLockers in Facility Sectors for spawnable weapons"
})

WeaponScanGroup:AddToggle("AutoRefreshWeapons", {
    Text = "Auto-Refresh Weapons",
    Default = false,
    Tooltip = "Automatically rescans for weapons every 5 seconds"
})

WeaponScanGroup:AddToggle("ShowWeaponESP", {
    Text = "Show Weapon ESP",
    Default = false,
    Tooltip = "Displays ESP overlays with weapon names above each weapon spawn location"
})

WeaponESPFilter = WeaponScanGroup:AddDropdown("WeaponESPFilter", {
    Text = "ESP Filter",
    Values = {},
    Multi = true,
    Tooltip = "Select specific weapons to show ESP for (Empty = All)"
})

WeaponNotifyFilter = WeaponScanGroup:AddDropdown("WeaponNotifyFilter", {
    Text = "Notification Filter",
    Values = {},
    Multi = true,
    Tooltip = "Select weapons to get a notification when they spawn"
})

WeaponTeleportDropdown = WeaponScanGroup:AddDropdown("WeaponTeleportDropdown", {
    Text = "Teleport Target",
    Values = {},
    Tooltip = "Select a weapon to teleport to the nearest instance of"
})

WeaponScanGroup:AddButton({
    Text = "Teleport to Nearest Weapon",
    Func = function()
        local selectedWeapon = Library.Options.WeaponTeleportDropdown.Value
        if not selectedWeapon then return Library:Notify("No weapon selected!", 2) end
        
        local weaponName = selectedWeapon:match("(.+) %- X%d+") or selectedWeapon

        local nearestWeapon = GetNearestCachedWeapon(weaponName)
        if nearestWeapon and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(nearestWeapon.Position + Vector3.new(0, 3, 0))
            Library:Notify("Teleported to " .. weaponName, 2)
        else
            Library:Notify("Could not find " .. weaponName .. " or character is missing.", 2)
        end
    end,
    Tooltip = "Teleports you to the nearest instance of the selected weapon."
})

----------------------------------------------------------------
-- TAB 2: SELF
----------------------------------------------------------------
local SelfLeft = Tabs.Self:AddLeftGroupbox("Perk Management")
for _, perk in ipairs({"Brute", "Ghost", "Rogue", "Tactician", "Desperado"}) do
    SelfLeft:AddToggle(perk .. "_Toggle", { 
        Text = "Force " .. perk, 
        Default = false, 
        Callback = function(state) 
            local data = LocalPlayer:FindFirstChild("Data") 
            local value = data and data:FindFirstChild(perk) 
            if value then value.Value = state end 
        end, 
        Tooltip = "Forces " .. perk .. " perk state locally in your Data folder"
    })
end

local MoveGroup = Tabs.Self:AddLeftGroupbox("Movement")
MoveGroup:AddToggle("EnableSpeed", { 
    Text = "Enable Speed Changer", 
    Default = false, 
    Tooltip = "Overrides WalkSpeed using a metatable bypass that spoofs the value to the server" 
})
MoveGroup:AddSlider("SpeedValue", { 
    Text = "WalkSpeed", 
    Default = 24, 
    Min = 16, 
    Max = 100, 
    Rounding = 0,
    Tooltip = "Sets your actual walk speed while the bypass reports 16 to the server"
})

local EliteRight = Tabs.Self:AddRightGroupbox("Elite Abilities")

EliteRight:AddToggle("Elite_Rally", { 
    Text = "Rally", 
    Default = false, 
    Tooltip = "Grants 33% CFrame speed boost and fires heal remote every 0.5s" 
}):AddKeyPicker("KR", { 
    Default = "None", 
    SyncToggleState = true,
    Mode = "Toggle", 
    Tooltip = "Keybind for Rally ability"
})

EliteRight:AddToggle("Elite_Slide", { 
    Text = "Combat Slide", 
    Default = false, 
    Tooltip = "Continuous CFrame slide with looping animation (rbxassetid://98871697427845) at Action4 priority" 
}):AddKeyPicker("KS", { 
    Default = "Z", 
    Mode = "Toggle", 
    Callback = function(value) 
        Library.Toggles.Elite_Slide:SetValue(value) 
    end 
})

EliteRight:AddToggle("Elite_Adrenaline", { 
    Text = "Adrenaline", 
    Default = false, 
    Tooltip = "40% CFrame speed boost + ESP highlights when crouching (Ctrl/C)" 
}):AddKeyPicker("KA", { 
    Default = "None", 
    SyncToggleState = true,
    Mode = "Toggle", 
    Tooltip = "Keybind for Adrenaline ability"
})

EliteRight:AddToggle("Elite_SixEyes", { 
    Text = "Six Eyes", 
    Default = false, 
    Tooltip = "Yellow ESP on all players + Green screen tint (ColorCorrection effect) with infinite range" 
}):AddKeyPicker("K6", { 
    Default = "None", 
    SyncToggleState = true,
    Mode = "Toggle", 
    Tooltip = "Keybind for Six Eyes ability"
})

EliteRight:AddSlider("SixEyesRange", { 
    Text = "Scan Range", 
    Default = 100, 
    Min = 50, 
    Max = 1000, 
    Suffix = " studs",
    Tooltip = "Range for Six Eyes detection (currently infinite regardless of this value)"
})

EliteRight:AddToggle("Elite_Void", { 
    Text = "Infinite Void", 
    Default = false, 
    Tooltip = "Health-based gradient ESP (Green=High HP → Red=Low HP) with infinite range" 
}):AddKeyPicker("KV", { 
    Default = "None", 
    SyncToggleState = true,
    Mode = "Toggle", 
    Tooltip = "Keybind for Infinite Void ability"
})

EliteRight:AddSlider("VoidRange", { 
    Text = "Scan Range", 
    Default = 100, 
    Min = 50, 
    Max = 1000, 
    Suffix = " studs",
    Tooltip = "Range for Infinite Void detection (currently infinite regardless of this value)"
})

----------------------------------------------------------------
-- TAB 3: VISUALS
----------------------------------------------------------------
local VisualLeft = Tabs.ESP:AddLeftGroupbox("Player ESP")
VisualLeft:AddToggle("ShowHUD", { 
    Text = "Enable Bio-HUD", 
    Default = false, 
    Callback = function(state) 
        BioHUD:SetVisible(state)
        if not state then BioHUD:SetText("") end
    end, 
    Tooltip = "Shows a draggable label displaying target's HP and Credits in real-time" 
})

VisualLeft:AddToggle("CombatESP", { 
    Text = "Advanced Player ESP", 
    Default = false, 
    Tooltip = "High-performance Drawing-based ESP showing Health, Team, Status, Perks, and Evolution" 
}):AddKeyPicker("KESP", { 
    Default = "P", 
    SyncToggleState = true,
    Mode = "Toggle", 
    Tooltip = "Keybind for Advanced Player ESP"
})

local ESPOpt = Tabs.ESP:AddRightGroupbox("ESP Customization")
ESPOpt:AddToggle("ESPServerStatus", { Text = "Show Status (Traitor/Mutant)", Default = true })
ESPOpt:AddToggle("ESPEvolution", { Text = "Show Evolution Stages", Default = true })
ESPOpt:AddToggle("ESPPerks", { Text = "Show Player Perks", Default = true })
ESPOpt:AddToggle("ESPPRM", { Text = "Show PRM Status", Default = true })
ESPOpt:AddToggle("ESPDistance", { Text = "Show Distance", Default = true })
ESPOpt:AddToggle("ESPArmor", { Text = "Show Armor Status", Default = true })


local InspectRight = Tabs.Visuals:AddRightGroupbox("Target Inspector")
ViewerDropdown = InspectRight:AddDropdown("PlayerSelect", { 
    Text = "Select Target", 
    Values = {}, 
    Searchable = true, 
    Tooltip = "Choose a specific player for targeting, teleporting, spectating, and highlighting" 
})

InspectRight:AddButton({ 
    Text = "Teleport to Target", 
    Func = function() 
        local target = Players:FindFirstChild(ViewerDropdown.Value) 
        if target and target.Character and LocalPlayer.Character then 
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3) 
        end 
    end, 
    Tooltip = "Teleports you 3 studs behind the selected target's position" 
})

InspectRight:AddToggle("HighlightTarget", { 
    Text = "Highlight Selected", 
    Default = false, 
    Tooltip = "Applies a purple ESP outline to the selected target's character" 
})

local ShowcaseGroup = Tabs.Visuals:AddRightGroupbox("ESP Showcase")
local ShowcaseFrame = ShowcaseGroup:AddLabel("Preview Layout")

-- Showcase dynamic update logic
local ShowcaseLabels = {
    Status = ShowcaseGroup:AddLabel("TRAITOR"),
    Name = ShowcaseGroup:AddLabel("PlayerName"),
    Health = ShowcaseGroup:AddLabel("[ |||||||||| ]"),
    Evo = ShowcaseGroup:AddLabel("Evo: Advanced"),
    Perk = ShowcaseGroup:AddLabel("Perks: Brute"),
    Armor = ShowcaseGroup:AddLabel("Armor: 50"),
    PRM = ShowcaseGroup:AddLabel("PRM"),
    Distance = ShowcaseGroup:AddLabel("150m")
}

local function UpdateShowcase()
    ShowcaseLabels.Status.Visible = Library.Toggles.ESPServerStatus.Value
    ShowcaseLabels.Name.Visible = true
    ShowcaseLabels.Health.Visible = true
    ShowcaseLabels.Evo.Visible = Library.Toggles.ESPEvolution.Value
    ShowcaseLabels.Perk.Visible = Library.Toggles.ESPPerks.Value
    ShowcaseLabels.Armor.Visible = Library.Toggles.ESPArmor.Value
    ShowcaseLabels.PRM.Visible = Library.Toggles.ESPPRM.Value
    ShowcaseLabels.Distance.Visible = Library.Toggles.ESPDistance.Value
end

-- Connect showcase updates
for _, toggle in pairs({"ESPServerStatus", "ESPEvolution", "ESPPerks", "ESPArmor", "ESPPRM", "ESPDistance"}) do
    Library.Toggles[toggle]:OnChanged(UpdateShowcase)
end

UpdateShowcase()

InspectRight:AddToggle("SpectateTarget", { 
    Text = "Spectate Subject", 
    Default = false, 
    Tooltip = "Locks the camera to follow the selected target's character" 
})

InspectRight:AddToggle("AimViewer", { 
    Text = "Aim Viewer (Tracers)", 
    Default = false, 
    Tooltip = "Draws tracer lines from players' heads showing where they are looking/aiming" 
})

----------------------------------------------------------------
-- TAB 4: EXPLOITS
----------------------------------------------------------------
local HealerLeft = Tabs.Exploits:AddLeftGroupbox("Auto Healer")

HealerLeft:AddDropdown("HealMode", { 
    Text = "Heal Priority", 
    Values = {"Nearest", "Target"}, 
    Default = 1, 
    Tooltip = "Choose whether to heal the nearest player or a specific selected target" 
})

HealTargetDrop = HealerLeft:AddDropdown("HealTarget", { 
    Text = "Patient", 
    Values = {}, 
    Searchable = true,
    Tooltip = "Select the specific player to heal when in Target mode"
})

local HealToolDrop = HealerLeft:AddDropdown("HealTool", { 
    Text = "Heal Item", 
    Values = {}, 
    Searchable = true,
    Tooltip = "Select which tool/item from your backpack to use for healing"
})

HealerLeft:AddButton({
    Text = "Refresh Tools",
    Func = function() 
        local toolList = {} 
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do 
            if tool:IsA("Tool") then 
                table.insert(toolList, tool.Name) 
            end 
        end 
        HealToolDrop:SetValues(toolList) 
    end,
    Tooltip = "Refreshes the tool list to show current items in your backpack"
})

HealerLeft:AddToggle("SpoofItem", { 
    Text = "Spoof Item", 
    Default = false, 
    Tooltip = "Rapidly equips tool → waits 0.15s → fires remote → unequips to hide the healing action" 
})

HealerLeft:AddToggle("AutoHeal", { 
    Text = "Auto-Heal Others", 
    Default = false,
    Tooltip = "Automatically heals other players based on your selected mode (Nearest/Target)"
})

HealerLeft:AddToggle("SelfHeal", { 
    Text = "Auto-Heal Self", 
    Default = false,
    Tooltip = "Automatically heals yourself when your health drops below the threshold percentage"
})

HealerLeft:AddSlider("SelfHealPct", { 
    Text = "Self Heal %", 
    Default = 30, 
    Min = 1, 
    Max = 99,
    Tooltip = "Health percentage threshold to trigger self-healing (e.g., 30 = heal when below 30% HP)"
})

HealerLeft:AddToggle("TweenToPatient", { 
    Text = "Tween Below Patient", 
    Default = false, 
    Tooltip = "Phases your character slightly under the target to heal through floors/walls" 
})

HealerLeft:AddSlider("TweenDist", { 
    Text = "Tween Depth", 
    Default = 10, 
    Min = 5, 
    Max = 50,
    Tooltip = "How far below the patient to teleport (in studs) for through-wall healing"
})

local PhysicsRight = Tabs.Exploits:AddRightGroupbox("Physics & Interaction")

PhysicsRight:AddToggle("TouchFling", { 
    Text = "Touch Fling", 
    Default = false, 
    Tooltip = "Uses a RunService loop to spam velocity logic (Velocity * 10000) to fling players on contact" 
})

PhysicsRight:AddToggle("InstaDoors", { 
    Text = "Insta-Doors", 
    Default = false, 
    Tooltip = "Automatically opens doors within 15 studs by firing Interaction_RF with specific arguments" 
})

PhysicsRight:AddToggle("BreakGlass", { 
    Text = "Brute Break", 
    Default = false, 
    Tooltip = "Automatically fires BruteBreak remote on nearby Glass/Window objects to shatter them" 
})

local AimbotGroup = Tabs.Exploits:AddRightGroupbox("Smart Aimbot")
AimbotGroup:AddToggle("EnableAimbot", { 
    Text = "Adaptive Aimbot", 
    Default = false, 
    Tooltip = "Locks onto hostile targets with prediction. Recognizes Traitors, Mutants, and Enemies based on your current team." 
})
AimbotGroup:AddToggle("AimbotPrediction", { 
    Text = "Enable Prediction", 
    Default = true, 
    Tooltip = "Accounts for target velocity when aiming" 
})
AimbotGroup:AddSlider("AimbotDist", { 
    Text = "Max Distance", 
    Default = 50, 
    Min = 10, 
    Max = 300,
    Tooltip = "Maximum distance in studs to lock onto a target"
})
AimbotGroup:AddSlider("AimbotSpeed", { 
    Text = "Lock Smoothness", 
    Default = 5, 
    Min = 1, 
    Max = 20,
    Tooltip = "Lower is smoother, higher is more snappy/instant"
})
AimbotGroup:AddLabel("Aimbot uses Secondary Mouse (M2) to activate.")

----------------------------------------------------------------
-- TAB 5: FUN
----------------------------------------------------------------
local FunLeft = Tabs.Fun:AddLeftGroupbox("Movement Hacks")

FunLeft:AddToggle("FS_Wallcheck", { 
    Text = "Flashstep Wallcheck", 
    Default = true, 
    Tooltip = "Prevents Flashsteps from teleporting through walls by raycasting" 
})

FunLeft:AddToggle("EnableFlashstep", { 
    Text = "Enable Flashstep (Dash)", 
    Default = false, 
    Tooltip = "When enabled, press the keybind (default Q) to dash forward"
}):AddKeyPicker("KD", { 
    Default = "Q", 
    SyncToggleState = false, 
    Mode = "Toggle",
    Tooltip = "Keybind for Flashstep (Dash)"
})

FunLeft:AddSlider("FlashDistance", { 
    Text = "Dash Distance", 
    Default = 40, 
    Min = 10, 
    Max = 100,
    Tooltip = "How far forward the Flashstep (Dash) will teleport you in studs"
})

FunLeft:AddToggle("EnableBehindStep", { 
    Text = "Enable Flashstep (Behind)", 
    Default = false, 
    Tooltip = "When enabled, press the keybind (default E) to dash behind enemies"
}):AddKeyPicker("KB", { 
    Default = "E", 
    SyncToggleState = false, 
    Mode = "Toggle",
    Tooltip = "Keybind for Flashstep (Behind)"
})

FunLeft:AddToggle("Speedblitz", { 
    Text = "Speedblitz (CFrame)", 
    Default = false, 
    Tooltip = "Constant CFrame teleport (1.8 studs) in movement direction with Ghost VFX trails" 
})

----------------------------------------------------------------
-- TAB 6: ZETA
----------------------------------------------------------------
local ScannerLeft = Tabs.Zeta:AddLeftGroupbox("Biological Deep-Scan")
local PhysicalRight = Tabs.Zeta:AddRightGroupbox("Attribute Analysis")

ZetaDropdown = ScannerLeft:AddDropdown("ZetaSelect", { 
    Text = "Select Subject", 
    Values = {}, 
    Searchable = true,
    Tooltip = "Choose a player to perform deep biological scanning and attribute analysis"
})

ScannerLeft:AddDivider()

local ZetaLabels = { 
    Mut = ScannerLeft:AddLabel("Mutation: N/A"), 
    Evo = ScannerLeft:AddLabel("Evolution: N/A"), 
    Exp = ScannerLeft:AddLabel("Exposure: N/A"),
    Adv = ScannerLeft:AddLabel("Advanced: N/A"),
    Weight = ScannerLeft:AddLabel("Weight: N/A"),
    Str = PhysicalRight:AddLabel("Strength: N/A"),
    Agi = PhysicalRight:AddLabel("Agility: N/A"),
    Int = PhysicalRight:AddLabel("Intelligence: N/A"),
    Res = PhysicalRight:AddLabel("Resilience: N/A")
}

----------------------------------------------------------------
-- TAB 7: UI SETTINGS
----------------------------------------------------------------
local UIL = Tabs.UI:AddLeftGroupbox("Configuration")

UIL:AddLabel("Menu Keybind"):AddKeyPicker("MenuKey", { 
    Default = "RightShift", 
    NoUI = true, 
    Callback = function() 
        Library:Toggle() 
    end,
    Tooltip = "Keybind to toggle the entire UI window on/off"
})

UIL:AddButton({
    Text = "Unload Script",
    Func = function() 
        ManageSlideAnimation(false)
        for _, p in ipairs(Players:GetPlayers()) do RemoveESP(p) end
        VisualFolder:ClearAllChildren()
        VisualFolder:Destroy()
        TempFolder:Destroy()
        SixEyesCC:Destroy()
        Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        Library:Unload() 
    end,
    Tooltip = "Completely removes the script, cleans up all visuals, resets camera, and unloads the UI"
})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI)

----------------------------------------------------------------
-- RUNTIME LOOPS
----------------------------------------------------------------
local lastItemScanTime = 0
local lastWeaponScanTime = 0

RunService.RenderStepped:Connect(function(deltaTime)
    Camera = workspace.CurrentCamera -- Always update to active camera
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    TempFolder:ClearAllChildren()
    -- Only disable Highlights that are meant to be updated every frame (SixEyes, Adrenaline, etc)
    for _, v in ipairs(VisualFolder:GetChildren()) do 
        if v:IsA("Highlight") and (v.Name:find("S$") or v.Name:find("V$") or v.Name:find("_Adr$")) then 
            v.Enabled = false 
        end 
    end
    SixEyesCC.Enabled = false
    
    if Library.Toggles.EnableSpeed.Value and hum then 
        hum.WalkSpeed = Library.Options.SpeedValue.Value 
    end

    -- Elite: Rally
    if Library.Toggles.Elite_Rally.Value and hum and root then
        if hum.MoveDirection.Magnitude > 0 then 
            root.CFrame = root.CFrame + (hum.MoveDirection * (0.35 * (60 * deltaTime))) 
        end
        if tick() % 0.5 < 0.1 and Remotes.Heal then 
            Remotes.Heal:FireServer(LocalPlayer) 
        end
    end
    
    -- Elite: Combat Slide
    if Library.Toggles.Elite_Slide.Value and hum and root then
        ManageSlideAnimation(true)
        root.CFrame = root.CFrame + ((hum.MoveDirection.Magnitude > 0 and hum.MoveDirection or root.CFrame.LookVector) * (0.65 * (60 * deltaTime)))
    else
        ManageSlideAnimation(false)
    end

    -- Speedblitz
    if Library.Toggles.Speedblitz.Value and hum and root and hum.MoveDirection.Magnitude > 0 then
        root.CFrame = root.CFrame + (hum.MoveDirection * 1.8)
        if tick() % 0.1 < 0.05 then 
            CreateGhost(root.CFrame) 
        end 
    end

    -- Elite: Adrenaline
    if Library.Toggles.Elite_Adrenaline.Value then
        if hum and root and hum.MoveDirection.Magnitude > 0 then 
            root.CFrame = root.CFrame + (hum.MoveDirection * (0.4 * (60 * deltaTime))) 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
            for _, player in ipairs(Players:GetPlayers()) do 
                if player ~= LocalPlayer and player.Character then 
                    UpdateHighlight(player.Character, Color3.fromRGB(255, 255, 0), player.Name .. "_Adr") 
                end 
            end
        else
            ClearHighlightsWithName(LocalPlayer.Name .. "_Adr") -- Generic cleanup for ADR
            for _, p in ipairs(Players:GetPlayers()) do
                local hl = p.Character and p.Character:FindFirstChild(p.Name .. "_Adr")
                if hl then hl:Destroy() end
            end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            local hl = p.Character and p.Character:FindFirstChild(p.Name .. "_Adr")
            if hl then hl:Destroy() end
        end
    end

    -- Elite: Six Eyes
    if Library.Toggles.Elite_SixEyes.Value and root then
        SixEyesCC.Enabled = true
        SixEyesCC.TintColor = Color3.fromRGB(180, 255, 180)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then 
                UpdateHighlight(player.Character, Color3.new(1, 1, 0), player.Name .. "S") 
            end
        end
    else
        if SixEyesCC.Enabled then
            SixEyesCC.Enabled = false
            for _, p in ipairs(Players:GetPlayers()) do
                local hl = p.Character and p.Character:FindFirstChild(p.Name .. "S")
                if hl then hl:Destroy() end
            end
        end
    end
    
    -- Elite: Infinite Void
    if Library.Toggles.Elite_Void.Value and root then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                local healthPercent = player.Character.Humanoid.Health / player.Character.Humanoid.MaxHealth
                UpdateHighlight(player.Character, Color3.fromHSV(math.clamp(healthPercent, 0, 1) * 0.33, 1, 1), player.Name .. "V")
            end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            local hl = p.Character and p.Character:FindFirstChild(p.Name .. "V")
            if hl then hl:Destroy() end
        end
    end

    -- Spectate Target (Optimized for Third Person)
    if Library.Toggles.SpectateTarget.Value and ViewerDropdown and ViewerDropdown.Value then
        local target = Players:FindFirstChild(ViewerDropdown.Value)
        if target and target.Character and target.Character:FindFirstChild("Humanoid") then
            if Camera.CameraSubject ~= target.Character.Humanoid then
                Camera.CameraSubject = target.Character.Humanoid
            end
            -- Force Camera to follow in third person if game script tries to take it back
            Camera.CameraType = Enum.CameraType.Custom
        elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            if Camera.CameraSubject ~= LocalPlayer.Character.Humanoid then
                Camera.CameraSubject = LocalPlayer.Character.Humanoid
                Camera.CameraType = Enum.CameraType.Custom
            end
        end
    end

    -- Aim Viewer (Fixed - Draws tracers from player heads)
    if Library.Toggles.AimViewer.Value then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local lookVector = head.CFrame.LookVector
                    local startPos = head.Position
                    local endPos = startPos + (lookVector * 50)
                    
                    DrawTracer(startPos, endPos, Color3.fromRGB(255, 0, 0))
                end
            end
        end
    end

    -- Item Scanner Auto-Refresh
    if Library.Toggles.AutoRefreshItems.Value then
        if tick() - lastItemScanTime > 5 then
            ScanForItems()
            lastItemScanTime = tick()
        end
    end

    -- Weapon Scanner Auto-Refresh
    if Library.Toggles.AutoRefreshWeapons.Value then
        if tick() - lastWeaponScanTime > 5 then
            ScanForWeapons()
            lastWeaponScanTime = tick()
        end
    end

    -- Item ESP Display
    if Library.Toggles.ShowItemESP.Value then
        local selection = Library.Options.ItemESPFilter and Library.Options.ItemESPFilter.Value or {}
        local hasSelection = next(selection) ~= nil
        
        local filter = {}
        if hasSelection then
            for k, v in pairs(selection) do
                local name = (type(k) == "string" and k) or (type(v) == "string" and v)
                if name then
                    local baseName = name:match("(.+) %- X%d+") or name
                    filter[baseName] = true
                end
            end
        end

        for _, itemData in ipairs(CachedItems) do
            if itemData.Billboard then
                local visible = true
                if hasSelection and not filter[itemData.Name] then visible = false end
                itemData.Billboard.Enabled = visible
            end
        end
    else
        for _, itemData in ipairs(CachedItems) do if itemData.Billboard then itemData.Billboard.Enabled = false end end
    end

    -- Weapon ESP Display
    if Library.Toggles.ShowWeaponESP.Value then
        local selection = Library.Options.WeaponESPFilter and Library.Options.WeaponESPFilter.Value or {}
        local hasSelection = next(selection) ~= nil
        
        local filter = {}
        if hasSelection then
            for k, v in pairs(selection) do
                local name = (type(k) == "string" and k) or (type(v) == "string" and v)
                if name then
                    local baseName = name:match("(.+) %- X%d+") or name
                    filter[baseName] = true
                end
            end
        end

        for _, weaponData in ipairs(CachedWeapons) do
            if weaponData.Billboard then
                local visible = true
                if hasSelection and not filter[weaponData.Name] then visible = false end
                weaponData.Billboard.Enabled = visible
            end
        end
    else
        for _, weaponData in ipairs(CachedWeapons) do if weaponData.Billboard then weaponData.Billboard.Enabled = false end end
    end

    -- (Interaction logic moved to optimized thread)
    
    -- Scanner Updates (Zeta Tab)

    -- Scanner Updates (Zeta Tab)
    local zetaTarget = Players:FindFirstChild(ZetaDropdown.Value)
    if zetaTarget then
        ZetaLabels.Mut:SetText("Mutation: " .. tostring(getAnyAttr(zetaTarget, "MutationType") or "None"))
        ZetaLabels.Evo:SetText("Evolution: " .. tostring(getAnyAttr(zetaTarget, "EvolutionStage") or "0"))
        ZetaLabels.Exp:SetText("Exposure: " .. string.format("%.1f%%", tonumber(getAnyAttr(zetaTarget, "Exposure")) or 0))
        ZetaLabels.Adv:SetText("Advanced: " .. tostring(getAnyAttr(zetaTarget, "HasReachedAdvancedMutation") or "No"))
        ZetaLabels.Weight:SetText("Weight: " .. tostring(getAnyAttr(zetaTarget, "Weight") or "N/A"))
        ZetaLabels.Str:SetText("Strength: " .. tostring(getAnyAttr(zetaTarget, "Strength") or "0"))
        ZetaLabels.Agi:SetText("Agility: " .. tostring(getAnyAttr(zetaTarget, "Agility") or "0"))
        ZetaLabels.Int:SetText("Intelligence: " .. tostring(getAnyAttr(zetaTarget, "Intelligence") or "0"))
        ZetaLabels.Res:SetText("Resilience: " .. tostring(getAnyAttr(zetaTarget, "Resilience") or "0"))
    end

    -- HUD & Target Highlights (Visuals Tab)
    if Library.Toggles.ShowHUD.Value then
        local hudTgt = ViewerDropdown and ViewerDropdown.Value and Players:FindFirstChild(ViewerDropdown.Value) or LocalPlayer
        if hudTgt and hudTgt.Character and hudTgt.Character:FindFirstChild("Humanoid") then
            BioHUD:SetText(string.format("BIO: %s | HP: %s | Credits: %s", 
                hudTgt.Name == LocalPlayer.Name and "Self" or hudTgt.Name,
                tostring(math.floor(hudTgt.Character.Humanoid.Health) or 0), 
                tostring(getAnyAttr(hudTgt, "Credits") or 0)
            ))
        end
    end

    local targetName = ViewerDropdown and ViewerDropdown.Value
    local targetObj = targetName and Players:FindFirstChild(targetName)
    local targetChar = targetObj and targetObj.Character
    
    if Library.Toggles.HighlightTarget.Value and targetChar then
        -- Refresh other highlights if needed (logic already handles existence)
        UpdateHighlight(targetChar, Color3.fromRGB(255, 0, 255), "TargetHL")
    end

    -- Cleanup logic: If toggle is off OR target changed, remove highlight from anyone who has it
    if not Library.Toggles.HighlightTarget.Value or not targetChar then
        for _, p in ipairs(Players:GetPlayers()) do
            local char = p.Character
            local hl = char and char:FindFirstChild("TargetHL")
            if hl then hl:Destroy() end
        end
    else
        -- Remove highlight from players who are NOT the current target
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name ~= targetName then
                local char = p.Character
                local hl = char and char:FindFirstChild("TargetHL")
                if hl then hl:Destroy() end
            end
        end
    end
    -- Smart Aimbot (Hostility Aware)
    if Library.Toggles.EnableAimbot.Value and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target, minMag = nil, math.huge
        local mousePos = UserInputService:GetMouseLocation()
        local maxDist = Library.Options.AimbotDist.Value
        local lockSpeed = 1 / math.max(1, Library.Options.AimbotSpeed.Value)

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsTargetHostile(p) then
                local head = p.Character and p.Character:FindFirstChild("Head")
                if head and (Camera.CFrame.Position - head.Position).Magnitude <= maxDist and IsVisible(head) then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local mag = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        if mag < minMag then minMag = mag; target = head end
                    end
                end
            end
        end
        
        if target then 
            local predictedPos = target.Position
            if Library.Toggles.AimbotPrediction.Value then
                local velocity = target.AssemblyLinearVelocity
                local distance = (Camera.CFrame.Position - target.Position).Magnitude
                predictedPos = target.Position + (velocity * (distance / 1000))
            end
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPos), lockSpeed) 
        end
    end
end)

-- Background Status Refresh Thread
task.spawn(function()
    while true do
        UpdatePlayerStatus(LocalPlayer)
        for _, p in ipairs(Players:GetPlayers()) do 
            if p ~= LocalPlayer then UpdatePlayerStatus(p) end 
        end
        task.wait(0.5)
    end
end)

----------------------------------------------------------------
-- HEALER THREAD (Separate from RenderStepped)
----------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.25)
        if not LocalPlayer.Character then continue end
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        
        if Library.Toggles.SelfHeal.Value and hum and hum.Health < (hum.MaxHealth * (Library.Options.SelfHealPct.Value / 100)) then
            UseItemSpoof(LocalPlayer)
        else
            if Library.Toggles.AutoHeal.Value then
                local target = (Library.Options.HealMode.Value == "Nearest") and GetNearestPlayer() or Players:FindFirstChild(HealTargetDrop.Value)
                if target then 
                    UseItemSpoof(target)
                    if Library.Toggles.TweenToPatient.Value and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, -Library.Options.TweenDist.Value, 0)
                        LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                    end
                end
            end
        end
    end
end)

----------------------------------------------------------------
-- TOUCH FLING THREAD
----------------------------------------------------------------
Library.Toggles.TouchFling:OnChanged(function()
    if Library.Toggles.TouchFling.Value then
        task.spawn(function()
            local moveLoop = 0.1
            while Library.Toggles.TouchFling.Value do
                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    RunService.Heartbeat:Wait()
                    local originalVelocity = rootPart.Velocity
                    rootPart.Velocity = originalVelocity * 10000 + Vector3.new(0, 10000, 0)
                    RunService.RenderStepped:Wait()
                    rootPart.Velocity = originalVelocity
                    RunService.Stepped:Wait()
                    rootPart.Velocity = originalVelocity + Vector3.new(0, moveLoop, 0)
                    moveLoop = -moveLoop
                else 
                    RunService.Heartbeat:Wait() 
                end
            end
        end)
    end
end)

----------------------------------------------------------------
-- INTERACTION THREAD (Optimized to reduce lag)
----------------------------------------------------------------
task.spawn(function()
    local doorDebounce = {}
    local glassDebounce = {}
    
    while true do
        task.wait(0.2)
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        -- Insta-Doors
        if Library.Toggles.InstaDoors.Value and Remotes.Door then
            if #CachedDoors == 0 and workspace:FindFirstChild("Facility") then
                for _, object in ipairs(workspace.Facility:GetDescendants()) do
                    if object.Name == "Doors" then 
                        for _, door in ipairs(object:GetChildren()) do table.insert(CachedDoors, door) end 
                    end
                end
            end
            
            for _, door in ipairs(CachedDoors) do
                if door and door.PrimaryPart then
                    local dist = (door.PrimaryPart.Position - root.Position).Magnitude
                    if dist < 15 and not doorDebounce[door] then
                        doorDebounce[door] = true
                        task.spawn(function()
                            pcall(function() Remotes.Door:InvokeServer("ServerInteraction", door, Enum.NormalId.Front, nil, "GenericInteraction") end)
                            task.wait(2) -- Don't spam same door
                            doorDebounce[door] = nil
                        end)
                    end
                end
            end
        end

        -- Brute Break
        if Library.Toggles.BreakGlass.Value and Remotes.BruteBreak then
            if #CachedGlass == 0 and workspace:FindFirstChild("Facility") then
                for _, object in ipairs(workspace.Facility:GetDescendants()) do
                    if object.Name == "Glass" or object.Name == "Window" then table.insert(CachedGlass, object) end
                end
            end
            
            for _, glass in ipairs(CachedGlass) do
                if glass and (glass.Position - root.Position).Magnitude < 15 and not glassDebounce[glass] then
                    glassDebounce[glass] = true
                    task.spawn(function()
                        pcall(function() Remotes.BruteBreak:FireServer(glass, glass.Position, Vector3.new(0, 1, 0)) end)
                        task.wait(1)
                        glassDebounce[glass] = nil
                    end)
                end
            end
        end
    end
end)

----------------------------------------------------------------
-- PLAYER DROPDOWN UPDATES
----------------------------------------------------------------
local function UpdatePlayerDropdowns()
    local playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do 
        table.insert(playerNames, player.Name) 
    end
    if ViewerDropdown then ViewerDropdown:SetValues(playerNames) end
    ZetaDropdown:SetValues(playerNames)
    HealTargetDrop:SetValues(playerNames)
end

local function SetupCombatESP(p)
    if p == LocalPlayer then return end
    p.CharacterAdded:Connect(function() 
        task.wait(0.5) 
        CreatePlayerESP(p) 
    end)
    if p.Character then CreatePlayerESP(p) end
end

Players.PlayerAdded:Connect(function(p)
    UpdatePlayerDropdowns()
    SetupCombatESP(p)
end)

Players.PlayerRemoving:Connect(function(p)
    UpdatePlayerDropdowns()
    RemoveESP(p)
end)

for _, p in ipairs(Players:GetPlayers()) do 
    SetupCombatESP(p) 
end

UpdatePlayerDropdowns()

-- Global Keybind Handler for Flashsteps
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    -- Dash Trigger
    if input.KeyCode == Library.Options.KD.Value and Library.Toggles.EnableFlashstep.Value then
        DoFlashstep(1)
    end
    
    -- Behind Step Trigger
    if input.KeyCode == Library.Options.KB.Value and Library.Toggles.EnableBehindStep.Value then
        DoFlashstep(2)
    end
end)

----------------------------------------------------------------
-- INITIALIZATION COMPLETE
----------------------------------------------------------------
Library:Notify("Fortnite Fentsite v.122 Loaded Successfully", 3)
