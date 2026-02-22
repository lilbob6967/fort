-- neverlose_lib.lua
-- Reusable UI Library for the Neverlose Theme

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Library = {
    Theme = {
        Main = Color3.fromRGB(10, 14, 20),
        Sidebar = Color3.fromRGB(14, 18, 25),
        Accent = Color3.fromRGB(0, 194, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(130, 140, 150),
        Card = Color3.fromRGB(18, 22, 30),
        Outline = Color3.fromRGB(30, 35, 45)
    }
}

local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function MakeDraggable(frame, parent)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = parent.Position
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            parent.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function Library:CreateWindow(options)
    local Window = {}
    options = options or {}
    local TitleText = options.Title or "NEVERLOSE"
    local UserNameText = options.UserName or "User"
    local UserStatusText = options.UserStatus or "Till: Never"
    
    local ScreenGui = Create("ScreenGui", {
        Name = "NeverloseMenu",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Library.Theme.Main,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -350, 0.5, -250),
        Size = UDim2.new(0, 700, 0, 500),
        ClipsDescendants = true
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainFrame })
    MakeDraggable(MainFrame, MainFrame)

    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        Parent = MainFrame,
        BackgroundColor3 = Library.Theme.Sidebar,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 180, 1, 0)
    })

    Create("TextLabel", {
        Name = "Logo",
        Parent = Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 20),
        Size = UDim2.new(0, 140, 0, 30),
        Font = Enum.Font.GothamBold,
        Text = TitleText,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local SidebarScroll = Create("ScrollingFrame", {
        Name = "TabHolder",
        Parent = Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 60),
        Size = UDim2.new(1, 0, 1, -120),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 1.2, 0)
    })
    Create("UIListLayout", { Parent = SidebarScroll, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })

    local ProfileFooter = Create("Frame", {
        Parent = Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -60),
        Size = UDim2.new(1, 0, 0, 60)
    })

    local ProfileAvatar = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 45, 50),
        Position = UDim2.new(0, 15, 0.5, -15),
        Size = UDim2.new(0, 30, 0, 30),
        Parent = ProfileFooter
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ProfileAvatar })

    Create("TextLabel", {
        Parent = ProfileFooter,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 55, 0, 15),
        Size = UDim2.new(0, 100, 0, 15),
        Font = Enum.Font.GothamBold,
        Text = UserNameText,
        TextColor3 = Color3.white,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    Create("TextLabel", {
        Parent = ProfileFooter,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 55, 0, 30),
        Size = UDim2.new(0, 100, 0, 15),
        Font = Enum.Font.Gotham,
        Text = UserStatusText,
        TextColor3 = Library.Theme.TextMuted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local ContentContainer = Create("Frame", {
        Name = "Content",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 180, 0, 0),
        Size = UDim2.new(1, -180, 1, 0)
    })
    
    local ActiveTabLabel = nil
    local ActiveTabFrame = nil

    function Window:AddCategory(name)
        Create("TextLabel", {
            Parent = SidebarScroll,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 25),
            Font = Enum.Font.GothamBold,
            Text = name,
            TextColor3 = Color3.fromRGB(80, 85, 90),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    end

    function Window:AddTab(name)
        local TabBtn = Create("TextButton", {
            Parent = SidebarScroll,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 35),
            Font = Enum.Font.Gotham,
            Text = "   " .. name,
            TextColor3 = Library.Theme.TextMuted,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local Indicator = Create("Frame", {
            Parent = TabBtn,
            BackgroundColor3 = Library.Theme.Accent,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 2, 1, 0),
            BorderSizePixel = 0,
            Visible = false
        })
        
        local TabFrame = Create("Frame", {
            Parent = ContentContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false
        })

        local TabObj = {}
        
        function TabObj:Select()
            if ActiveTabLabel then
                ActiveTabLabel.TextColor3 = Library.Theme.TextMuted
                ActiveTabLabel:FindFirstChildOfClass("Frame").Visible = false
            end
            if ActiveTabFrame then
                ActiveTabFrame.Visible = false
            end
            
            TabBtn.TextColor3 = Color3.white
            Indicator.Visible = true
            TabFrame.Visible = true
            
            ActiveTabLabel = TabBtn
            ActiveTabFrame = TabFrame
        end

        TabBtn.MouseButton1Click:Connect(function()
            TabObj:Select()
        end)
        
        -- Auto select first tab
        if not ActiveTabLabel then
            TabObj:Select()
        end
        
        -- Helper for Friends custom tab content
        function TabObj:SetupFriendsTab()
            local TopBar = Create("Frame", {
                Parent = TabFrame,
                BackgroundColor3 = Color3.fromRGB(2, 4, 6),
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 50)
            })

            local AddFriendBtn = Create("TextButton", {
                Parent = TopBar,
                BackgroundColor3 = Color3.fromRGB(0, 100, 200),
                Position = UDim2.new(0, 230, 0, 10),
                Size = UDim2.new(0, 110, 0, 30),
                Font = Enum.Font.GothamBold,
                Text = "+ Add Friend",
                TextColor3 = Color3.white,
                TextSize = 13
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = AddFriendBtn })

            local RequestsBadge = Create("Frame", {
                Parent = TopBar,
                BackgroundColor3 = Color3.fromRGB(255, 50, 50),
                Position = UDim2.new(0, 485, 0, 5),
                Size = UDim2.new(0, 14, 0, 14),
                ZIndex = 5
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = RequestsBadge })
            Create("TextLabel", { Parent = RequestsBadge, Text = "4", TextSize = 10, Font = Enum.Font.GothamBold, TextColor3 = Color3.white, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) })
            
            local FriendsScroll = Create("ScrollingFrame", {
                Parent = TabFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 20, 0, 60), 
                Size = UDim2.new(1, -40, 1, -150),
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Library.Theme.Accent,
                CanvasSize = UDim2.new(0, 0, 2, 0)
            })
            Create("UIListLayout", { Parent = FriendsScroll, Padding = UDim.new(0, 10) })
            
            local BottomPanel = Create("Frame", {
                Parent = TabFrame,
                BackgroundColor3 = Color3.fromRGB(15, 20, 25),
                Position = UDim2.new(0, 20, 1, -80),
                Size = UDim2.new(1, -40, 0, 60)
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = BottomPanel })

            return {
                AddCard = function(name, status, address)
                    local Card = Create("Frame", {
                        BackgroundColor3 = Library.Theme.Card,
                        Size = UDim2.new(1, 0, 0, 65),
                        BorderSizePixel = 0
                    })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Card })
                    Card.Parent = FriendsScroll

                    local Avatar = Create("Frame", {
                        BackgroundColor3 = Color3.fromRGB(40, 45, 50),
                        Position = UDim2.new(0, 10, 0.5, -20),
                        Size = UDim2.new(0, 40, 0, 40),
                        Parent = Card
                    })
                    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Avatar })

                    Create("TextLabel", {
                        Parent = Card,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 60, 0, 12),
                        Size = UDim2.new(0, 200, 0, 20),
                        Font = Enum.Font.GothamBold,
                        Text = name,
                        TextColor3 = Color3.white,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })

                    Create("TextLabel", {
                        Parent = Card,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 60, 0, 32),
                        Size = UDim2.new(0, 300, 0, 20),
                        Font = Enum.Font.Gotham,
                        Text = "Playing on: " .. (address or status),
                        TextColor3 = Color3.fromRGB(0, 194, 255),
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })

                    local ConnectBtn = Create("TextButton", {
                        Parent = Card,
                        BackgroundColor3 = Color3.fromRGB(0, 100, 200),
                        Position = UDim2.new(1, -110, 0.5, -15),
                        Size = UDim2.new(0, 100, 0, 30),
                        Font = Enum.Font.GothamBold,
                        Text = "▶ Connect",
                        TextColor3 = Color3.white,
                        TextSize = 13
                    })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ConnectBtn })
                end
            }
        end

        return TabObj
    end

    return Window
end

return Library
