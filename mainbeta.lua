--[[ 
Tho Lnoob Hub - VIP Menu
Tính năng: Hop Low Server, FPS Boost, Speed, Jump, Fly, ESP
UI: Nút tròn di động -> mở/tắt menu
]]

--// UI Library
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- Nút tròn mở menu
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0, 100, 0, 200)
ToggleButton.Image = "rbxassetid://89300403770535"
ToggleButton.BackgroundTransparency = 1
ToggleButton.Draggable = true

-- Khung Menu
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BorderSizePixel = 0

-- Tiêu đề
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Tho Lnoob Hub - Main"
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.TextScaled = true

-- Nút Toggle Menu
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Hàm tạo nút trong menu
local function CreateButton(text, posY, callback)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Hop Low Server
CreateButton("Hop Low Server", 50, function()
    local servers = {}
    local req = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    local data = HttpService:JSONDecode(req)
    for _,v in pairs(data.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer)
            break
        end
    end
end)

-- FPS Boost
CreateButton("FPS Boost", 95, function()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") or v:IsA("Union") or v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end
    print("FPS Boost ON")
end)

-- Speed
local SpeedOn = false
CreateButton("Toggle Speed", 140, function()
    SpeedOn = not SpeedOn
end)
local speedValue = 50 -- chỉnh max speed
game:GetService("RunService").Heartbeat:Connect(function()
    if SpeedOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = speedValue
    end
end)

-- Jump
local JumpOn = false
CreateButton("Toggle Jump", 185, function()
    JumpOn = not JumpOn
end)
local jumpValue = 100
game:GetService("RunService").Heartbeat:Connect(function()
    if JumpOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = jumpValue
    end
end)

-- Fly
local FlyOn = false
local flySpeed = 50
CreateButton("Toggle Fly", 230, function()
    FlyOn = not FlyOn
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if FlyOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local move = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + (workspace.CurrentCamera.CFrame.LookVector) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - (workspace.CurrentCamera.CFrame.LookVector) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - (workspace.CurrentCamera.CFrame.RightVector) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + (workspace.CurrentCamera.CFrame.RightVector) end
        hrp.Velocity = move * flySpeed
    end
end)

-- ESP
local ESPOn = false
CreateButton("Toggle ESP", 275, function()
    ESPOn = not ESPOn
    if ESPOn then
        for _,plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                local Billboard = Instance.new("BillboardGui", plr.Character.Head)
                Billboard.Name = "ESP"
                Billboard.Size = UDim2.new(0,200,0,50)
                Billboard.AlwaysOnTop = true
                local NameTag = Instance.new("TextLabel", Billboard)
                NameTag.Size = UDim2.new(1,0,1,0)
                NameTag.Text = plr.Name
                NameTag.BackgroundTransparency = 1
                NameTag.TextColor3 = Color3.fromRGB(255,0,0)
                NameTag.TextScaled = true
            end
        end
    else
        for _,plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("Head") and plr.Character.Head:FindFirstChild("ESP") then
                plr.Character.Head.ESP:Destroy()
            end
        end
    end
end)
