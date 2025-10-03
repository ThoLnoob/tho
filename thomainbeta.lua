--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// UI Library đơn giản kiểu giống Banana Hub
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThoHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Size = UDim2.new(0, 550, 0, 300)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -150)
MainFrame.Visible = true

Instance.new("UICorner", MainFrame)

-- Tabs Panel
local TabFrame = Instance.new("Frame", MainFrame)
TabFrame.Size = UDim2.new(0, 150, 1, 0)
TabFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", TabFrame)

-- Content Panel
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Position = UDim2.new(0, 160, 0, 0)
ContentFrame.Size = UDim2.new(1, -160, 1, 0)
ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", ContentFrame)

-- Helper create tab button
local function CreateTab(name)
    local Btn = Instance.new("TextButton", TabFrame)
    Btn.Text = name
    Btn.Size = UDim2.new(1, -10, 0, 40)
    Btn.Position = UDim2.new(0, 5, 0, (#TabFrame:GetChildren()-1)*45)
    Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Btn.TextColor3 = Color3.fromRGB(255,255,255)
    Btn.Font = Enum.Font.SourceSansBold
    Btn.TextSize = 18
    Instance.new("UICorner", Btn)
    return Btn
end

-- Content Pages
local Pages = {}

local function CreatePage(name)
    local Page = Instance.new("Frame", ContentFrame)
    Page.Size = UDim2.new(1,0,1,0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Pages[name] = Page
    return Page
end

local function ShowPage(name)
    for _,p in pairs(Pages) do p.Visible = false end
    if Pages[name] then Pages[name].Visible = true end
end

--// Tabs
local mainBtn = CreateTab("Main")
local playerBtn = CreateTab("Player")
local espBtn = CreateTab("ESP")
local otherBtn = CreateTab("Other")

-- Pages
local mainPage = CreatePage("Main")
local playerPage = CreatePage("Player")
local espPage = CreatePage("ESP")
local otherPage = CreatePage("Other")

-- Show default
ShowPage("Main")

mainBtn.MouseButton1Click:Connect(function() ShowPage("Main") end)
playerBtn.MouseButton1Click:Connect(function() ShowPage("Player") end)
espBtn.MouseButton1Click:Connect(function() ShowPage("ESP") end)
otherBtn.MouseButton1Click:Connect(function() ShowPage("Other") end)

--// Variables
local WalkSpeedValue, JumpPowerValue, FlySpeedValue = 16, 50, 50
local flying = false
local espEnabled = false
local espConnections = {}

--// Helper Slider
local function CreateSlider(parent, text, min, max, default, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1,-20,0,60)
    Frame.Position = UDim2.new(0,10,0,#parent:GetChildren()*65)
    Frame.BackgroundTransparency = 1

    local Label = Instance.new("TextLabel", Frame)
    Label.Text = text .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(255,255,255)
    Label.Font = Enum.Font.SourceSansBold
    Label.Size = UDim2.new(1,0,0,20)
    Label.BackgroundTransparency = 1

    local Slider = Instance.new("TextButton", Frame)
    Slider.Size = UDim2.new(1,0,0,20)
    Slider.Position = UDim2.new(0,0,0,30)
    Slider.BackgroundColor3 = Color3.fromRGB(80,80,80)
    Slider.Text = ""
    Instance.new("UICorner", Slider)

    local Fill = Instance.new("Frame", Slider)
    Fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    Fill.BackgroundColor3 = Color3.fromRGB(0,170,255)
    Fill.BorderSizePixel = 0

    local dragging = false
    Slider.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mouseX = UserInputService:GetMouseLocation().X
            local percent = math.clamp((mouseX-Slider.AbsolutePosition.X)/Slider.AbsoluteSize.X,0,1)
            Fill.Size = UDim2.new(percent,0,1,0)
            local val = math.floor(min + (max-min)*percent)
            Label.Text = text .. ": " .. val
            callback(val)
        end
    end)
end

--// Sliders in Player Page
CreateSlider(playerPage,"WalkSpeed",16,200,16,function(val)
    WalkSpeedValue = val
    LocalPlayer.Character.Humanoid.WalkSpeed = WalkSpeedValue
end)

CreateSlider(playerPage,"JumpPower",50,200,50,function(val)
    JumpPowerValue = val
    LocalPlayer.Character.Humanoid.JumpPower = JumpPowerValue
end)

CreateSlider(playerPage,"FlySpeed",10,50,25,function(val)
    FlySpeedValue = val
end)

-- Fly Toggle
local FlyBtn = Instance.new("TextButton", playerPage)
FlyBtn.Text = "Toggle Fly (OFF)"
FlyBtn.Size = UDim2.new(0,200,0,40)
FlyBtn.Position = UDim2.new(0,10,0,220)
FlyBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
FlyBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", FlyBtn)

FlyBtn.MouseButton1Click:Connect(function()
    flying = not flying
    FlyBtn.Text = "Toggle Fly ("..(flying and "ON" or "OFF")..")"
end)

-- Fly logic
RunService.RenderStepped:Connect(function()
    if flying and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
        hrp.Velocity = moveDir.Unit * FlySpeedValue
    end
end)

--// ESP
local function AddESP(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Color = Color3.new(1,1,1)
    box.Thickness = 2
    box.Filled = false

    local name = Drawing.new("Text")
    name.Color = Color3.new(1,1,1)
    name.Size = 15
    name.Center = true

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if espEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos, vis = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if vis then
                local size = 50
                box.Size = Vector2.new(size, size*2)
                box.Position = Vector2.new(pos.X-size/2, pos.Y-size)
                box.Visible = true
                name.Position = Vector2.new(pos.X,pos.Y-size/2)
                name.Text = player.Name
                name.Visible = true
            else
                box.Visible = false
                name.Visible = false
            end
        else
            box.Visible = false
            name.Visible = false
        end
    end)

    espConnections[player] = {conn,box,name}
end

local function RemoveESP(player)
    if espConnections[player] then
        for _,v in pairs(espConnections[player]) do
            if typeof(v)=="RBXScriptConnection" then v:Disconnect() else v:Remove() end
        end
        espConnections[player] = nil
    end
end

Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveESP)

for _,plr in pairs(Players:GetPlayers()) do
    AddESP(plr)
end

local ESPBtn = Instance.new("TextButton", espPage)
ESPBtn.Text = "ESP Player: OFF"
ESPBtn.Size = UDim2.new(0,200,0,40)
ESPBtn.Position = UDim2.new(0,10,0,20)
ESPBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
ESPBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", ESPBtn)

ESPBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPBtn.Text = "ESP Player: " .. (espEnabled and "ON" or "OFF")
end)
