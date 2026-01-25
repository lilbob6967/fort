-- Obsidian (mspaint) UI — CLIENT / LOCAL (Final Fixes)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 1. Load Library
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- 2. Create Window
local Window = Library:CreateWindow({
    Title = "mspaint",
    Footer = "fortnite fentsite script v.67",
    Icon = 95816097006870,
    NotifySide = "Right",
    Center = true,
    AutoShow = true,
    EnableSidebarResize = true, 
})

local Tabs = {
    Main = Window:AddTab("Main", "house", "Dashboard"),
    Self = Window:AddTab("Self", "user", "Character & Perks"),
    Visuals = Window:AddTab("Visuals", "eye", "ESP & HUD Overlay"),
    Exploits = Window:AddTab("Exploits", "zap", "Combat & Heals"),
    Zeta = Window:AddTab("Zeta", "star", "Bio-Data Analysis"),
    UI = Window:AddTab("UI Settings", "settings", "Themes & Configs"),
}

----------------------------------------------------------------
-- Global Variables & Caches
----------------------------------------------------------------
local CachedDoors = {}
local CachedGlass = {}
local CombatAnimTrack = nil 

-- Define Remotes safely
local Remotes = {
    Heal = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:WaitForChild("Events", 5) and ReplicatedStorage.Remotes.Events:FindFirstChild("UseTool"),
    Door = ReplicatedStorage:WaitForChild("DynamicRemotes", 5) and ReplicatedStorage.DynamicRemotes:WaitForChild("Interaction_Remotes", 5) and ReplicatedStorage.DynamicRemotes.Interaction_Remotes:FindFirstChild("Interaction_RF"),
    Glass = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:WaitForChild("Events", 5) and ReplicatedStorage.Remotes.Events:FindFirstChild("DestroyGlass"),
    Ability = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:WaitForChild("Events", 5) and ReplicatedStorage.Remotes.Events:FindFirstChild("UseEliteAbility")
}

----------------------------------------------------------------
-- Map Caching Logic (Improved)
----------------------------------------------------------------
local function CacheMap()
    table.clear(CachedDoors)
    table.clear(CachedGlass)
    
    local Facility = workspace:FindFirstChild("Facility")
    if not Facility then 
        Library:Notify("Facility folder not found!", 3)
        return 
    end

    -- Deep scan the entire facility for glass and doors
    for _, obj in ipairs(Facility:GetDescendants()) do
        -- Cache Doors
        if obj.Name == "Doors" and obj:IsA("Folder") then
            for _, door in ipairs(obj:GetChildren()) do
                table.insert(CachedDoors, door)
            end
        end
        
        -- Cache Glass (Strict check for parts named "Glass")
        if obj.Name == "Glass" and obj:IsA("BasePart") then
            table.insert(CachedGlass, obj)
        end
    end
    
    Library:Notify(string.format("Cached: %d Doors, %d Glass Panes", #CachedDoors, #CachedGlass), 3)
end

----------------------------------------------------------------
-- Helper Functions
----------------------------------------------------------------
local function getData(plr) return plr and plr:FindFirstChild("Data") end

local function readDataValue(plr, key)
    local data = getData(plr)
    if not data then return nil end
    local obj = data:FindFirstChild(key)
    if obj then return obj.Value end
    return nil
end

local function setPerk(perk, state)
    local data = getData(LocalPlayer)
    if data then
        local val = data:FindFirstChild(perk)
        if val then pcall(function() val.Value = state end) end
    end
end

local function getAnyAttr(plr, attr)
    if not plr then return nil end
    local char = plr.Character
    if char and char:GetAttribute(attr) ~= nil then return char:GetAttribute(attr) end
    if plr:GetAttribute(attr) ~= nil then return plr:GetAttribute(attr) end
    return readDataValue(plr, attr)
end

local function formatInt(n)
    return tostring(math.floor(tonumber(n) or 0)):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

----------------------------------------------------------------
-- FEATURE: Draggable HUD
----------------------------------------------------------------
local BioHUD = Library:AddDraggableLabel("Bio-HUD")
BioHUD:SetVisible(false) 

----------------------------------------------------------------
-- Shared Dropdown Logic
----------------------------------------------------------------
local AllDropdowns = {}

local function UpdatePlayerLists()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(names, p.Name) 
    end
    table.sort(names)
    for _, dropdown in ipairs(AllDropdowns) do
        pcall(function() dropdown:SetValues(names) end)
    end
end
Players.PlayerAdded:Connect(UpdatePlayerLists)
Players.PlayerRemoving:Connect(UpdatePlayerLists)

----------------------------------------------------------------
-- TABS SETUP
----------------------------------------------------------------

-- [[ MAIN TAB ]]
local MainGroup = Tabs.Main:AddLeftGroupbox("Welcome", "info")
MainGroup:AddLabel("Fortnite Fentsite Loaded.")
MainGroup:AddButton("Refresh Map Cache", CacheMap)

-- [[ SELF TAB ]]
pcall(function()
    local Left = Tabs.Self:AddLeftGroupbox("Perk Management", "user")
    local Perks = { "Brute", "Ghost", "Rogue", "Tactician", "Desperado" }
    for _, perk in ipairs(Perks) do
        local isEnabled = readDataValue(LocalPlayer, perk) == true
        Left:AddToggle(perk .. "_Toggle", {
            Text = "Active: " .. perk,
            Default = isEnabled,
            Callback = function(state) setPerk(perk, state) end
        })
        pcall(function()
            local DepBox = Left:AddDependencyBox()
            local toggleRef = Library.Toggles[perk .. "_Toggle"]
            if toggleRef then
                DepBox:SetupDependencies({ { toggleRef, true } })
                DepBox:AddLabel({ Text = perk .. " module active.", Size = 14, DoesWrap = true })
            end
        end)
    end
end)

-- [[ VISUALS TAB ]]
local ViewerDropdown, SpectateToggle, ViewerLabels
pcall(function()
    local Left = Tabs.Visuals:AddLeftGroupbox("Overlay Settings", "monitor")
    Left:AddToggle("ShowHUD", {
        Text = "Enable Bio-Data HUD",
        Default = false,
        Callback = function(state) BioHUD:SetVisible(state) end
    })

    local Right = Tabs.Visuals:AddRightGroupbox("Target Inspector", "users")
    ViewerDropdown = Right:AddDropdown("PlayerSelect", { Text = "Select Target", Values = {}, Default = 1, Multi = false, Searchable = true })
    table.insert(AllDropdowns, ViewerDropdown)
    SpectateToggle = Right:AddToggle("SpectateTarget", { Text = "Spectate Subject", Default = false })
    
    SpectateToggle:OnChanged(function()
        if not SpectateToggle.Value and LocalPlayer.Character then
            Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
            Camera.CameraType = Enum.CameraType.Custom
        end
    end)
    
    Right:AddDivider()
    ViewerLabels = {
        Name = Right:AddLabel("Name: N/A"),
        Region = Right:AddLabel("Region: N/A"),
        Credits = Right:AddLabel("Credits: N/A"),
    }
end)

-- [[ EXPLOITS TAB ]]
local AbilityGroup = Tabs.Exploits:AddLeftGroupbox("Abilities", "zap")
local HealerGroup = Tabs.Exploits:AddLeftGroupbox("Auto Healer", "heart")
local InteractGroup = Tabs.Exploits:AddRightGroupbox("Interaction", "hand")

-- 1. Abilities
pcall(function()
    local function PerformCombatSlide()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        
        if hum then
            local animator = hum:FindFirstChild("Animator") or hum:WaitForChild("Animator", 1)
            if animator then
                if not CombatAnimTrack then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://98871697427845" 
                    CombatAnimTrack = animator:LoadAnimation(anim)
                    CombatAnimTrack.Priority = Enum.AnimationPriority.Action
                    CombatAnimTrack.Looped = false
                end
                CombatAnimTrack:Play()
            end
        end

        if Remotes.Ability then
            if (getgenv and getgenv().firesignal) or firesignal then
                local fire = (getgenv and getgenv().firesignal) or firesignal
                fire(Remotes.Ability.OnClientEvent, "LocalEffect", "Combat Slide", char)
            end
        end
    end

    local SlideBtn = AbilityGroup:AddButton("Combat Slide", PerformCombatSlide)
    SlideBtn:AddKeyPicker("SlideKey", { Default = "Z", Text = "Slide Key", Mode = "Hold", Callback = function(v) if v then PerformCombatSlide() end end })
end)

-- 2. Healer
local HealTargetDropdown
pcall(function()
    HealerGroup:AddDropdown("HealMode", { Text = "Healing Mode", Values = { "Nearest", "Target" }, Default = 1 })
    HealTargetDropdown = HealerGroup:AddDropdown("HealTarget", { Text = "Select Patient", Values = {}, Default = 1, Searchable = true })
    table.insert(AllDropdowns, HealTargetDropdown)
    
    pcall(function()
        local DepBox = HealerGroup:AddDependencyBox()
        DepBox:SetupDependencies({ { Library.Options.HealMode, "Target" } })
    end)

    HealerGroup:AddToggle("AutoHeal", { Text = "Enable Auto-Heal", Default = false })
    HealerGroup:AddDivider()
    HealerGroup:AddToggle("TweenToPatient", { Text = "Tween Below Patient", Default = false })
    HealerGroup:AddSlider("TweenDistance", { Text = "Distance Below", Default = 10, Min = 5, Max = 50 })
end)

-- 3. Interactions
pcall(function()
    InteractGroup:AddLabel("Range: 30 Studs")
    InteractGroup:AddToggle("InstaDoors", { Text = "Insta-Doors", Default = false })
    InteractGroup:AddToggle("BreakGlass", { Text = "Break Nearby Glass", Default = false })
    
    InteractGroup:AddButton("Force Break All Cached", function()
        if not Remotes.Glass then return Library:Notify("Glass Remote not found", 3) end
        for _, glass in ipairs(CachedGlass) do
            if glass and glass.Parent and glass.Transparency < 0.9 then
                local force = (glass.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * 120
                Remotes.Glass:FireServer(glass, glass.Position, force, 120, true)
            end
        end
        Library:Notify("Fired break event on all cached glass", 2)
    end)
    
    InteractGroup:AddButton("Refresh Map Cache", CacheMap)
end)

-- [[ ZETA TAB ]]
local ZetaDropdown, ZetaLabels
pcall(function()
    local Bio = Tabs.Zeta:AddLeftGroupbox("Mutation Analysis", "dna")
    local Stats = Tabs.Zeta:AddRightGroupbox("Core Attributes", "bar-chart-3")
    ZetaDropdown = Bio:AddDropdown("ZetaSelect", { Text = "Select Subject", Values = {}, Default = 1, Searchable = true })
    table.insert(AllDropdowns, ZetaDropdown)
    Bio:AddDivider()
    ZetaLabels = {
        Subject = Bio:AddLabel("Subject: N/A"), Exposure = Bio:AddLabel("Exposure: N/A"),
        Mut = Bio:AddLabel("Mutation: N/A"), Evo = Bio:AddLabel("Evolution: N/A"),
        Adv = Bio:AddLabel("Advanced: N/A"), Weight = Bio:AddLabel("Weight: N/A"),
        Str = Stats:AddLabel("Strength: N/A"), Agi = Stats:AddLabel("Agility: N/A"),
        Int = Stats:AddLabel("Intelligence: N/A"), Res = Stats:AddLabel("Resilience: N/A"),
        MaxRes = Stats:AddLabel("Max Res: N/A"),
    }
end)

-- [[ SETTINGS TAB ]]
pcall(function()
    local S = Tabs.UI:AddLeftGroupbox("Configuration", "settings")
    S:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Toggle Menu" })
    Library.ToggleKeybind = Library.Options.MenuKeybind
    S:AddButton("Unload Script", function() Library:Unload() end)
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    ThemeManager:SetFolder("fentsite")
    SaveManager:SetFolder("fentsite/configs")
    ThemeManager:ApplyToTab(Tabs.UI)
    SaveManager:BuildConfigSection(Tabs.UI)
end)

UpdatePlayerLists()
CacheMap() 
ThemeManager:LoadDefault()
SaveManager:LoadAutoloadConfig()

----------------------------------------------------------------
-- GAME LOGIC LOOPS
----------------------------------------------------------------

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

-- RENDER STEPPED (For Camera Spectating)
RunService.RenderStepped:Connect(function()
    if SpectateToggle and SpectateToggle.Value then
        local targetName = ViewerDropdown.Value
        local target = (type(targetName) == "string") and Players:FindFirstChild(targetName)
        
        if target and target.Character then
            local hum = target.Character:FindFirstChild("Humanoid")
            if hum then
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = hum
            end
        else
            -- Fallback if target lost
            if LocalPlayer.Character then
                Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
            end
        end
    end
end)

-- HEARTBEAT (UI Updates)
local lastUiUpdate = 0
RunService.Heartbeat:Connect(function(dt)
    pcall(function()
        lastUiUpdate = lastUiUpdate + dt
        if lastUiUpdate >= 0.2 then
            if ViewerDropdown then
                local target = Players:FindFirstChild(ViewerDropdown.Value) or LocalPlayer
                ViewerLabels.Name:SetText("Name: " .. target.Name)
                ViewerLabels.Region:SetText("Region: " .. tostring(getAnyAttr(target, "RegionCode") or "N/A"))
                ViewerLabels.Credits:SetText("Credits: " .. formatInt(getAnyAttr(target, "Credits")))
                
                if Library.Toggles.ShowHUD.Value then
                    local hp = target.Character and target.Character:FindFirstChild("Humanoid") and math.floor(target.Character.Humanoid.Health) or "N/A"
                    local exp = getAnyAttr(target, "Exposure") or 0
                    BioHUD:SetText(string.format("Fentsite V.67 | HP: %s | EXP: %.1f%% | $: %s", tostring(hp), tonumber(exp) or 0, formatInt(getAnyAttr(target, "Credits"))))
                end
            end
            if ZetaDropdown then
                local zPlr = Players:FindFirstChild(ZetaDropdown.Value) or LocalPlayer
                ZetaLabels.Subject:SetText("Subject: " .. zPlr.Name)
                ZetaLabels.Exposure:SetText("Exposure: " .. string.format("%.2f", tonumber(getAnyAttr(zPlr, "Exposure")) or 0))
                ZetaLabels.Mut:SetText("Mutation: " .. tostring(getAnyAttr(zPlr, "MutationType") or "N/A"))
                ZetaLabels.Adv:SetText("Adv: " .. tostring(getAnyAttr(zPlr, "HasReachedAdvancedMutation") or "N/A"))
                local s = tonumber(getAnyAttr(zPlr, "Strength") or getAnyAttr(zPlr, "StrengthAttribute"))
                if s then ZetaLabels.Str:SetText(string.format("Strength: %.2f", s)) end
            end
            lastUiUpdate = 0
        end
    end)
end)

-- HEARTBEAT (Exploits)
local lastAction = 0
RunService.Heartbeat:Connect(function(dt)
    pcall(function()
        if not Library.Toggles.AutoHeal then return end
        
        -- HEALER
        if Library.Toggles.AutoHeal.Value then
            lastAction = lastAction + dt
            if lastAction >= 0.1 then
                lastAction = 0
                local patient
                if Library.Options.HealMode.Value == "Nearest" then patient = GetNearestPlayer()
                else patient = Players:FindFirstChild(Library.Options.HealTarget.Value) end
                
                if patient and Remotes.Heal then
                    Remotes.Heal:FireServer(patient)
                end
            end
        end

        -- INTERACTION
        if Library.Toggles.InstaDoors.Value or Library.Toggles.BreakGlass.Value then
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local myPos = myRoot.Position
                
                -- Doors
                if Library.Toggles.InstaDoors.Value and Remotes.Door then
                    for _, door in ipairs(CachedDoors) do
                        if door and door.Parent then
                            local part = door:IsA("Model") and door.PrimaryPart or door:FindFirstChild("Door") or door
                            if part and part:IsA("BasePart") and (part.Position - myPos).Magnitude < 30 then
                                Remotes.Door:InvokeServer("ServerInteraction", door, Enum.NormalId.Front, nil, "GenericInteraction")
                            end
                        end
                    end
                end

                -- Glass
                if Library.Toggles.BreakGlass.Value and Remotes.Glass then
                    for _, glass in ipairs(CachedGlass) do
                        if glass and glass.Parent and glass.Transparency < 0.9 and (glass.Position - myPos).Magnitude < 30 then
                             local force = (glass.Position - myPos).Unit * 120 -- Increased force
                             Remotes.Glass:FireServer(glass, glass.Position, force, 120, true)
                        end
                    end
                end
            end
        end

        -- TWEEN
        if Library.Toggles.AutoHeal.Value and Library.Toggles.TweenToPatient.Value then
             local patient
            if Library.Options.HealMode.Value == "Nearest" then patient = GetNearestPlayer()
            else patient = Players:FindFirstChild(Library.Options.HealTarget.Value) end
            
            if patient and patient.Character and patient.Character:FindFirstChild("HumanoidRootPart") then
                 local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                 if myRoot then
                     local cf = patient.Character.HumanoidRootPart.CFrame * CFrame.new(0, -Library.Options.TweenDistance.Value, 0)
                     local tw = TweenService:Create(myRoot, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {CFrame = cf})
                     tw:Play()
                     myRoot.AssemblyLinearVelocity = Vector3.zero
                 end
            end
        end
    end)
end)
