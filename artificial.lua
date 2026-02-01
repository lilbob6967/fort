-- // SERVICES //
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- // UI SETUP //
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Blatant Suite",
    Footer = "Instant Navigation & Automation",
    Icon = 10002823616,
    NotifySide = "Right",
    Center = true,
    AutoShow = true,
})

local NavTab = Window:AddTab("Navigation", "map")
local NavGroup = NavTab:AddLeftGroupbox("Teleport Controls")
local ConsoleGroup = NavTab:AddRightGroupbox("Console Log")

local SettingsTab = Window:AddTab("UI Settings", "settings")
local SettingGroup = SettingsTab:AddLeftGroupbox("Menu Settings")

-- // HUD OVERLAY SETUP //
local HUDGui = Instance.new("ScreenGui")
HUDGui.Name = "BlatantHUD"
HUDGui.ResetOnSpawn = false
pcall(function() HUDGui.Parent = game:GetService("CoreGui") end)

local Player = Players.LocalPlayer
if not HUDGui.Parent then HUDGui.Parent = Player:WaitForChild("PlayerGui") end

local HUDFrame = Instance.new("Frame")
HUDFrame.Name = "MainFrame"
HUDFrame.Size = UDim2.new(0, 200, 0, 60)
HUDFrame.Position = UDim2.new(0.02, 0, 0.15, 0)
HUDFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
HUDFrame.BorderSizePixel = 0
HUDFrame.Parent = HUDGui

local HUDCorner = Instance.new("UICorner")
HUDCorner.CornerRadius = UDim.new(0, 8)
HUDCorner.Parent = HUDFrame

local HUDStroke = Instance.new("UIStroke")
HUDStroke.Color = Color3.fromRGB(0, 255, 100)
HUDStroke.Thickness = 2
HUDStroke.Parent = HUDFrame

local HUDTitle = Instance.new("TextLabel")
HUDTitle.Text = " BLATANT STATUS"
HUDTitle.Size = UDim2.new(1, 0, 0, 25)
HUDTitle.BackgroundTransparency = 1
HUDTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HUDTitle.TextXAlignment = Enum.TextXAlignment.Left
HUDTitle.Font = Enum.Font.GothamBold
HUDTitle.TextSize = 12
HUDTitle.Parent = HUDFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Text = "State: Ready"
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.Parent = HUDFrame

local function UpdateHUD(state)
    StatusLabel.Text = "State: " .. (state or "Ready")
    if state == "Ready" then HUDStroke.Color = Color3.fromRGB(0, 255, 100)
    else HUDStroke.Color = Color3.fromRGB(60, 60, 60) end
end

-- Dragging logic for HUD
local dragging, dragInput, dragStart, startPos
HUDFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = HUDFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
HUDFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        HUDFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- // LOGGING SYSTEM //
local LogLabels = {}
local function Log(text)
    print("[Blatant]: " .. text)
    local lbl = ConsoleGroup:AddLabel(text)
    table.insert(LogLabels, lbl)
    
    UpdateHUD("Action Executed")
    task.delay(1.5, function() UpdateHUD("Ready") end)

    if #LogLabels > 15 then
        table.remove(LogLabels, 1)
    end
end

-- // POI DATA TABLES //
local TARGET_CFRAME = CFrame.new(659.66217, -63.0000153, -252.58049, -0.999743223, -1.91775218e-09, 0.02265957, -3.87522325e-09, 1, -8.63421548e-08, -0.02265957, -8.64077947e-08, -0.999743223)

local COFFEE_PATHS = {
    {"Facility", "Sectors", "Sector 1", "Interactions", "Power", "Dispensers", 3},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Power", "Dispensers", "Coffee Machine"},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Power", "Dispensers", 2},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Power", "Dispensers", "Coffee Machine"},
    {"Facility", "Sectors", "Research&Management", "Interactions", "Power", "Dispensers", "Coffee Machine"},
    {"Facility", "Sectors", "Sector 2", "Interactions", "Power", "Dispensers", 3},
    {"Facility", "Sectors", "Sector 2", "Interactions", "Power", "Dispensers", "Coffee Machine"},
    {"Facility", "Sectors", "Sector 2", "Interactions", "Power", "Dispensers", 2},
    {"Facility", "Sectors", "Zeta Labs", "Interactions", "Dispensers", 2},
    {"Facility", "Sectors", "Zeta Labs", "Interactions", "Dispensers", "Coffee Machine"}
}

local ARMOR_PATHS = {
    {"Facility", "Sectors", "MaintenanceAndService", "Interactions", "Miscellaneous", 2},
    {"Facility", "Sectors", "Zeta Labs", "Interactions", "Miscellaneous", "ArmorStation"},
    {"Facility", "Sectors", "Sector 2", "Interactions", "Miscellaneous", 3},
    {"Facility", "Sectors", "Sector 2", "Interactions", "Miscellaneous", "ArmorStation"},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Miscelleaneous", 3},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Miscelleaneous", "ArmorStation"},
    {"Facility", "Sectors", "Research&Management", "Interactions", "Miscellaneous", "ArmorStation"},
    {"Facility", "Sectors", "MaintenanceAndService", "Interactions", "Miscellaneous", "ArmorStation"},
    {"Facility", "Sectors", "Armory", "Interactions", "Miscellaneous", 3},
    {"Facility", "Sectors", "Armory", "Interactions", "Miscellaneous", "ArmorStation"}
}

local VENDING_PATHS = {
    {"Facility", "Sectors", "Sector 2", "Interactions", "Power", "Dispensers", 7},
    {"Facility", "Sectors", "Sector 2", "Interactions", "Power", "Dispensers", 8},
    {"Facility", "Sectors", "Sector 2", "Interactions", "Power", "Dispensers", "Vending Machine"},
    {"Facility", "Sectors", "Sector 2", "Interactions", "Power", "Dispensers", 6},
    {"Facility", "Sectors", "Sector 2", "Interactions", "Power", "Dispensers", 5},
    {"Facility", "Sectors", "Sector 3", "Interactions", "Power", "Dispensers", "Vending Machine"},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Power", "Dispensers", 5},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Power", "Dispensers", 6},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Power", "Dispensers", "Vending Machine"},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Power", "Dispensers", 7},
    {"Facility", "Sectors", "Research&Management", "Interactions", "Power", "Dispensers", "Vending Machine"},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Power", "Dispensers", 4},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Power", "Dispensers", "Vending Machine"},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Power", "Dispensers", 5},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Power", "Dispensers", 3},
    {"Facility", "Sectors", "MedicalFaculty", "Interactions", "Power", "Dispensers", "Vending Machine"}
}

local FOOD_PATHS = {
    {"Facility", "Sectors", "Sector 1", "Interactions", "Food", "Food Tray", "TouchPart"},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Food", 2},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Food", "Food Tray"},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Food", 3},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Food", 4},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Food", 5},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Food", 6},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Food", 2},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Food", "Food Tray"},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Food", 3}
}

local VENDOR_PATHS = {
    {"Facility", "Sectors", "Armory", "Interactions", "NPCs", "Vendor"},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "NPCs", "Vendors", "Vendor"},
    {"Facility", "Sectors", "Research&Management", "Interactions", "NPCs", "Vendor"}
}

local GAS_PIPE_PATHS = {
    {"Facility", "Sectors", "Sector 2", "Interactions", "GasPipes", 4},
    {"Facility", "Sectors", "Checkpoint", "Interactions", "Pipes", "GasPipe"},
    {"Facility", "Sectors", "MaintenanceAndService", "Interactions", "Power", "LowerFloor", "Pipes", 3},
    {"Facility", "Sectors", "MaintenanceAndService", "Interactions", "Power", "LowerFloor", "Pipes", "GasPipe"},
    {"Facility", "Sectors", "MaintenanceAndService", "Interactions", "Power", "LowerFloor", "Pipes", 2},
    {"Facility", "Sectors", "MaintenanceAndService", "Interactions", "Power", "UpperFloor", "Pipes", 2},
    {"Facility", "Sectors", "MaintenanceAndService", "Interactions", "Power", "UpperFloor", "Pipes", "GasPipe"},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Pipes", 2},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Pipes", "GasPipe"},
    {"Facility", "Sectors", "Research&Management", "Interactions", "Pipes", "GasPipe"},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Pipes", 4},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Pipes", "GasPipe"},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Pipes", 2},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Pipes", 3},
    {"Facility", "Sectors", "Sector 2", "Interactions", "GasPipes", 6},
    {"Facility", "Sectors", "Sector 2", "Interactions", "GasPipes", "GasPipe"},
    {"Facility", "Sectors", "Sector 2", "Interactions", "GasPipes", 3},
    {"Facility", "Sectors", "Sector 2", "Interactions", "GasPipes", 2},
    {"Facility", "Sectors", "Sector 2", "Interactions", "GasPipes", 4},
    {"Facility", "Sectors", "Sector 2", "Interactions", "GasPipes", 5},
    {"Facility", "Sectors", "Zeta Labs", "Interactions", "GasPipes", 2},
    {"Facility", "Sectors", "Zeta Labs", "Interactions", "GasPipes", "GasPipe"},
    {"Facility", "Sectors", "Zeta Labs", "Interactions", "GasPipes", 3}
}

local TURRET_BOX_PATHS = {
    {"Facility", "Sectors", "LogisticsZone", "Interactions", "Power", "PowerBoxes", 2},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Power", "PowerBoxes", 3},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Power", "PowerBoxes", 2},
}

local GATE_BOX_PATHS = {
    {"Facility", "Sectors", "LogisticsZone", "Interactions", "Power", "PowerBoxes", "PowerBoxGate"},
    {"Facility", "Sectors", "PatientHousing", "Interactions", "Power", "PowerBoxes", "PowerBoxGate"},
    {"Facility", "Sectors", "Sector 1", "Interactions", "Power", "PowerBoxes", "PowerBoxGate"},
}

local ELECTRICAL_PANEL_PATHS = {
    {"Facility", "Sectors", "MaintenanceAndService", "Interactions", "Power", "UpperFloor", "ControlPanels", "ElectricalPanel"},
    {"Facility", "Sectors", "MaintenanceAndService", "Interactions", "Power", "LowerFloor", "ControlPanels", "ElectricalPanel"},
}

local LOCKDOWN_GATE_PATHS = {
    {"Facility", "Sectors", "Zeta Labs", "Interactions", "Doors", "LockdownGates", 4, "LockdownGate"},
    {"Facility", "Sectors", "Zeta Labs", "Interactions", "Doors", "LockdownGates", "LockdownGate", "LockdownGate"},
    {"Facility", "Sectors", "Zeta Labs", "Interactions", "Doors", "LockdownGates", 2, "LockdownGate"},
    {"Facility", "Sectors", "Zeta Labs", "Interactions", "Doors", "LockdownGates", 3, "LockdownGate"},
}

local ELEVATOR_PATHS = {
    {Path = {"Facility", "Sectors", "Sector 2", "Parts", 140}},
    {Path = {"Facility", "Sectors", "Sector 2", "Parts", "Elevator"}},
    {Path = {"Facility", "Sectors", "PatientHousing", "Interactions", "Power", "Elevators", "Elevator"}},
    -- Zeta Labs Overrides
    {
        Path = {"Facility", "Sectors", "Zeta Labs", "Power", "Elevators", "Elevator"}, 
        Override = CFrame.new(421.109955, -150.454636, 97.4042206, -0.969440877, 4.28244196e-09, 0.245325029, 1.88210389e-08, 1, 5.6918136e-08, -0.245325029, 5.97960366e-08, -0.969440877)
    },
    {
        Path = {"Facility", "Sectors", "Zeta Labs", "Power", "Elevators", 2}, 
        Override = CFrame.new(439.443634, -150.454636, 94.6029282, -0.999943852, 1.52679747e-09, 0.0105965044, 1.48949619e-09, 1, -3.52803897e-09, -0.0105965044, -3.51205753e-09, -0.999943852),
        BoundryIndex = 6 -- Specific remote argument from user
    },
}

local SWITCHGEAR_PATHS = {
    {"ServerFarms", "S1_Mainframe", "SwitchGear"},
    {"ServerFarms", "S2_Mainframe", "SwitchGear"},
}

local C4_WALL_PATHS = {
    {
        Path = {"Facility", "Sectors", "Sector 1", "Interactions", "C4Walls", "AuxArmory"},
        SubPath = {"Scripted", "Wall", "Wall"},
        Override = CFrame.new(365.108643, -25.3501015, -167.908615, -0.414108306, -2.57193395e-08, 0.910227597, -5.24889963e-08, 1, 4.3760604e-09, -0.910227597, -4.59647715e-08, -0.414108306)
    },
    {
        Path = {"Facility", "Sectors", "PatientHousing", "Interactions", "C4Walls", "CourtyardWall"},
        SubPath = {"Scripted", "Wall", "Wall"},
        Override = CFrame.new(257.155762, -3, 154.406677, -0.22129631, 3.09140873e-08, -0.975206614, -7.56754162e-08, 1, 4.88724936e-08, 0.975206614, 8.4614463e-08, -0.22129631)
    },
}

-- // CORE LOGIC //
local RepairRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RepairableObjects"):WaitForChild("RepairObject")

local function ResolvePath(pathTable)
    local obj = workspace
    for _, step in ipairs(pathTable) do
        if type(step) == "string" then
            obj = obj:FindFirstChild(step)
        elseif type(step) == "number" then
            local children = obj:GetChildren()
            obj = children[step]
        end
        if not obj then break end
    end
    return obj
end

local function GetCFrame(obj)
    if not obj then return nil end
    if typeof(obj) == "CFrame" then return obj end -- Support raw CFrame
    if obj:IsA("Model") then return obj:GetPivot()
    elseif obj:IsA("BasePart") then return obj.CFrame
    end
    return nil
end

local function TeleportTo(cf)
    if not cf then return end
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = cf
    end
end

local function SmartTeleport(pathList)
    Log("Searching for valid supply target...")
    for _, path in ipairs(pathList) do
        local obj = ResolvePath(path)
        local cf = GetCFrame(obj)
        if cf then
            TeleportTo(cf)
            Log("Teleported to valid station.")
            Library:Notify("Arrival Successful", 2)
            
            -- AUTO RETURN OPTIONAL (Might want to wait for user to use machine)
            if Library.Toggles.AutoReturnGoal and Library.Toggles.AutoReturnGoal.Value then
                task.delay(3, function() -- Give 3 seconds to use machine
                    TeleportTo(TARGET_CFRAME)
                    Log("Automated return to goal.")
                end)
            end
            return
        end
    end
    Log("Error: No valid targets found in proximity.")
    Library:Notify("No stations found!", 3)
end

-- // AUTO-REPAIR LOOP //
local ScriptRunning = true -- Control flag

task.spawn(function()
    while ScriptRunning and task.wait(1.5) do
        local success, err = pcall(function()
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local facility = workspace:FindFirstChild("Facility")
            local sectors = facility and facility:FindFirstChild("Sectors")
            if not facility or not sectors then return end
            
            local runtime = workspace:FindFirstChild("RuntimeObjects")
            
            local function YieldingRepair(obj, boundry, checkFunc, offsetDist, posObj)
                Log("Starting Repair on: " .. tostring(obj))
                local startTick = tick()
                
                local dist = offsetDist or 5 -- Default 5 studs
                local target = posObj or obj
                local baseCF = GetCFrame(target)
                
                if baseCF then
                    local safeCF = baseCF * CFrame.new(0, 0, dist)
                    TeleportTo(safeCF)
                    task.wait(0.1)
                else
                    warn("[Artificial] Could not get CFrame for object: " .. tostring(obj))
                    return
                end
                
                while tick() - startTick < 10 do
                    if not ScriptRunning then break end -- Stop if script unloaded
                    if not checkFunc() then 
                        Log("Repair Complete.")
                        break 
                    end
                    for i = 1, 5 do RepairRemote:FireServer(obj, boundry) end
                    task.wait()
                end

                if Library.Toggles.AutoReturnGoal and Library.Toggles.AutoReturnGoal.Value then
                    TeleportTo(TARGET_CFRAME)
                end
            end

            local RepairAll = Library.Toggles.RepairAll and Library.Toggles.RepairAll.Value

            -- 1. Scan Power Boxes (Turrets)
            if RepairAll or (Library.Toggles.RepairTurrets and Library.Toggles.RepairTurrets.Value) then
                for _, path in ipairs(TURRET_BOX_PATHS) do
                    local box = ResolvePath(path)
                    if box then
                        local isBroken = box:GetAttribute("Broken")
                        if isBroken then
                            local boundry = box:FindFirstChild("Boundry")
                            Log("Repairing Turret Box (Attribute Detection)...")
                            YieldingRepair(box, boundry, function()
                                return box:GetAttribute("Broken") == true
                            end)
                        end
                    end
                end
            end

            -- 2. Scan Gate Boxes
            if RepairAll or (Library.Toggles.RepairGates and Library.Toggles.RepairGates.Value) then
                for _, path in ipairs(GATE_BOX_PATHS) do
                    local box = ResolvePath(path)
                    if box then
                        local isBroken = box:GetAttribute("Broken")
                        if isBroken then
                            local boundry = box:FindFirstChild("Boundry")
                            Log("Repairing Gate Box (Attribute Detection)...")
                            YieldingRepair(box, boundry, function()
                                return box:GetAttribute("Broken") == true
                            end)
                        end
                    end
                end
            end

            -- 3. Scan Lockdown Gates (Zeta Labs)
            if RepairAll or (Library.Toggles.RepairLockdowns and Library.Toggles.RepairLockdowns.Value) then
                for _, path in ipairs(LOCKDOWN_GATE_PATHS) do
                    local gate = ResolvePath(path)
                    if gate then
                        local hp = gate:GetAttribute("Health")
                        if hp and hp <= 0 then
                            local boundry = gate:FindFirstChild("Boundry")
                            Log("Repairing Lockdown Gate (Health: " .. tostring(hp) .. ")...")
                            YieldingRepair(gate, boundry, function()
                                -- Wait until Health > 0
                                local curr = gate:GetAttribute("Health")
                                return curr and curr <= 0
                            end)
                        end
                    end
                end
            end

            -- 5. Scan SwitchGears (Broken Attribute)
            if RepairAll or (Library.Toggles.RepairSwitchGears and Library.Toggles.RepairSwitchGears.Value) then
                for _, path in ipairs(SWITCHGEAR_PATHS) do
                    local gear = ResolvePath(path)
                    if gear then
                        local isBroken = gear:GetAttribute("Broken")
                        if isBroken then
                            local boundry = gear:FindFirstChild("Boundry")
                            Log("Repairing SwitchGear (Attribute)...")
                            YieldingRepair(gear, boundry, function()
                                return gear:GetAttribute("Broken") == true
                            end)
                        end
                    end
                end
            end

            -- 6. Scan Barricades
            if RepairAll or (Library.Toggles.RepairBarricades and Library.Toggles.RepairBarricades.Value) then
                if runtime then
                    local destroyed = runtime:FindFirstChild("DestroyedBarricades")
                    if destroyed then
                        for _, barricade in ipairs(destroyed:GetChildren()) do
                            local boundry = barricade:FindFirstChild("Boundry")
                            if boundry then
                                Log("Repairing Barricade.")
                                YieldingRepair(barricade, boundry, function()
                                    return barricade:IsDescendantOf(destroyed)
                                end)
                            end
                        end
                    end
                end
            end

            -- 7. Scan Gas Pipes
            if RepairAll or (Library.Toggles.RepairGasPipes and Library.Toggles.RepairGasPipes.Value) then
                for _, path in ipairs(GAS_PIPE_PATHS) do
                    local pipe = ResolvePath(path)
                    if pipe then
                        local isBroken = pipe:GetAttribute("Broken")
                        if isBroken then
                            local boundry = pipe:FindFirstChild("Boundry") or pipe.Parent:FindFirstChild("Boundry")
                            Log("Repairing Gas Pipe (Attribute Detection)...")
                            YieldingRepair(pipe, boundry, function()
                                return pipe:GetAttribute("Broken") == true
                            end)
                        end
                    end
                end
            end

            -- 8. Scan Electrical Panels
            if RepairAll or (Library.Toggles.RepairPanels and Library.Toggles.RepairPanels.Value) then
                for _, path in ipairs(ELECTRICAL_PANEL_PATHS) do
                    local panel = ResolvePath(path)
                    if panel then
                        local isBroken = panel:GetAttribute("Broken")
                        if isBroken then
                            local boundry = panel:FindFirstChild("Boundry")
                            Log("Repairing Electrical Panel...")
                            YieldingRepair(panel, boundry, function()
                                return panel:GetAttribute("Broken") == true
                            end)
                        end
                    end
                end
            end

            -- 9. Scan Walls (Specific & Generic)
            if RepairAll or (Library.Toggles.RepairWalls and Library.Toggles.RepairWalls.Value) then
                -- Specific Attribute-based Walls
                for _, def in ipairs(C4_WALL_PATHS) do
                    local root = ResolvePath(def.Path)
                    if root then
                        local isDestroyed = root:GetAttribute("Destroyed")
                        if isDestroyed then
                            -- Resolve absolute repair target (Nested or Root)
                            local target = root
                            if def.SubPath then
                                for _, k in ipairs(def.SubPath) do
                                    target = target and target:FindFirstChild(k)
                                end
                            end

                            if target then
                                local boundry = target:FindFirstChild("Boundry")
                                Log("Repairing C4 Wall (Refined Target)...")
                                
                                -- Use override if available, 0 offset
                                local targetPos = def.Override
                                local useDist = targetPos and 0 or 5
                                
                                YieldingRepair(target, boundry, function()
                                    return root:GetAttribute("Destroyed") == true
                                end, useDist, targetPos)
                            else
                                warn("Could not resolve SubPath for C4 Wall: " .. root.Name)
                            end
                        end
                    end
                end

                -- Previous Generic Logic (PatientHousing)
                if sectors then
                    local housing = sectors:FindFirstChild("PatientHousing")
                    local walls = housing and housing.Interactions:FindFirstChild("C4Walls")
                    if walls then
                        for _, wall in ipairs(walls:GetChildren()) do
                            local exploded = wall:FindFirstChild("ExplodedState")
                            if exploded and exploded:FindFirstChild("Debris") then
                                local boundry = wall:FindFirstChild("Boundry")
                                Log("Repairing Wall (Generic)...")
                                YieldingRepair(wall, boundry, function()
                                    local exp = wall:FindFirstChild("ExplodedState")
                                    return exp and exp:FindFirstChild("Debris") ~= nil
                                end)
                            end
                        end
                    end
                end
            end

            -- 10. Scan Elevators (Health) - MOVED TO LAST
            if RepairAll or (Library.Toggles.RepairElevators and Library.Toggles.RepairElevators.Value) then
                for i, def in ipairs(ELEVATOR_PATHS) do
                    local elevator = ResolvePath(def.Path)
                    if elevator then
                        local hp = elevator:GetAttribute("Health")
                        -- Log("Checking Elevator " .. i .. ": " .. tostring(elevator) .. " | HP: " .. tostring(hp)) -- Spammy but useful if desperate
                        if hp and hp <= 0 then
                            -- Determine boundry (Standard or Indexed override)
                            local boundry 
                            if def.BoundryIndex then
                                local children = elevator:GetChildren()
                                boundry = children[def.BoundryIndex]
                                Log("Using Boundry Override Index " .. def.BoundryIndex .. " for " .. elevator.Name)
                            else
                                boundry = elevator:FindFirstChild("Boundry")
                            end

                            -- Determine target position: Override -> Car1Point -> Object (0 offset)
                            local targetPos = def.Override
                            if targetPos then
                                Log("Using HARDCODED Override for " .. elevator.Name)
                            else
                                local carPoint = elevator:FindFirstChild("Car1Point")
                                if carPoint then
                                    Log("Found Car1Point for " .. elevator.Name)
                                    targetPos = carPoint 
                                end
                            end
                            
                            Log("Repairing Elevator (Health: " .. tostring(hp) .. ")...")
                            YieldingRepair(elevator, boundry, function()
                                local curr = elevator:GetAttribute("Health")
                                return curr and curr <= 0
                            end, 0, targetPos)
                        end
                    else
                        warn("Failed to resolve elevator path index: " .. i)
                    end
                end
            end
        end)
        if not success then
            warn("[Artificial] Repair Loop Error: " .. tostring(err))
        end
    end
end)

-- // QUEST ANALYSIS //
local function AnalyzeQuests()
    Log("Analyzing quests...")
    local pg = Player:FindFirstChild("PlayerGui")
    local sidebar = pg and pg:FindFirstChild("Sidebar")
    local list = sidebar and sidebar:FindFirstChild("Quests") and sidebar.Quests:FindFirstChild("List")
    
    if not list then return Log("Error: Quest UI not found.") end

    local bestQuestUI = nil
    local maxCredits = -1
    local bestQuestName = "Unknown"

    local function getStrippedText(obj)
        if not obj then return nil end
        return obj:GetAttribute("Text") or (obj:IsA("TextLabel") and obj.Text) or nil
    end

    for _, uiQuest in ipairs(list:GetChildren()) do
        if uiQuest:IsA("Frame") or uiQuest:IsA("GuiObject") then
            local rewardFolder = uiQuest:FindFirstChild("Reward")
            if rewardFolder then
                for _, child in ipairs(rewardFolder:GetChildren()) do
                    local text = getStrippedText(child) or (child:FindFirstChildOfClass("TextLabel") and getStrippedText(child:FindFirstChildOfClass("TextLabel")))
                    if text then
                        local num = tonumber(text:match("%d+"))
                        if num and (text:lower():find("credit") or text:lower():find("cr")) then
                            if num > maxCredits then
                                maxCredits = num
                                bestQuestUI = uiQuest
                                bestQuestName = uiQuest.Name
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    if bestQuestUI then
        Log("Best Quest: " .. bestQuestName .. " (" .. maxCredits .. " Credits)")
        Library:Notify("Best Quest: " .. bestQuestName, 4)
    else
        Log("No profitable quests found.")
    end
end

-- // UI ELEMENTS //
NavGroup:AddButton({
    Text = "Teleport to Goal",
    Func = function() TeleportTo(TARGET_CFRAME) end
})

NavGroup:AddButton({
    Text = "Analyze Quests",
    Func = AnalyzeQuests
})
NavGroup:AddToggle("AutoReturnGoal", { Text = "Auto-Return to Goal", Default = false })

local AutoGroup = NavTab:AddLeftGroupbox("Automation")
AutoGroup:AddToggle("RepairAll", { Text = "Repair All (Sequential)", Default = false })
AutoGroup:AddDivider()
AutoGroup:AddToggle("RepairTurrets", { Text = "Repair Turret Boxes", Default = false })
AutoGroup:AddToggle("RepairGates", { Text = "Repair Gate Boxes", Default = false })
AutoGroup:AddToggle("RepairLockdowns", { Text = "Repair Lockdown Gates", Default = false })
AutoGroup:AddToggle("RepairElevators", { Text = "Repair Elevators", Default = false })
AutoGroup:AddToggle("RepairSwitchGears", { Text = "Repair SwitchGears", Default = false })
AutoGroup:AddToggle("RepairBarricades", { Text = "Repair Barricades", Default = false })
AutoGroup:AddToggle("RepairGasPipes", { Text = "Repair Gas Pipes (Safe TP)", Default = false })
AutoGroup:AddToggle("RepairPanels", { Text = "Repair Electrical Panels", Default = false })
AutoGroup:AddToggle("RepairWalls", { Text = "Repair C4 Walls", Default = false })

local SupplyGroup = NavTab:AddLeftGroupbox("Smart Supplies")
SupplyGroup:AddButton({ Text = "Find Coffee Machine", Func = function() SmartTeleport(COFFEE_PATHS) end })
SupplyGroup:AddButton({ Text = "Find Armor Station", Func = function() SmartTeleport(ARMOR_PATHS) end })
SupplyGroup:AddButton({ Text = "Find Vending Machine", Func = function() SmartTeleport(VENDING_PATHS) end })
SupplyGroup:AddButton({ Text = "Find Food Tray", Func = function() SmartTeleport(FOOD_PATHS) end })
SupplyGroup:AddButton({ Text = "Find Vendor NPC", Func = function() SmartTeleport(VENDOR_PATHS) end })

-- // UI SETTINGS //
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder("BlatantSuite")
SaveManager:SetFolder("BlatantSuite/nav")
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)

SettingGroup:AddButton("Uninject", function() 
    ScriptRunning = false -- Stop all loops
    HUDGui:Destroy()
    Library:Unload() 
end)
SettingGroup:AddLabel("Menu bind"):AddKeybind("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu bind" })

Log("Blatant Suite Loaded.")
Library:Notify("Blatant Navigation Active", 2)
