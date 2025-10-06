--// Banana Style Hub (Tho Edition Full)
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)

-- Nút tròn mở/đóng menu
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0, 100, 0, 200)
ToggleButton.BackgroundTransparency = 1
ToggleButton.Image = "rbxassetid://89300403770535" -- hình bạn đưa
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui

-- Khung menu chính
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 320)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Tab bar
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local function createTab(name, posX)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.Position = UDim2.new(0, posX, 0, 0)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundTransparency = 1
    return btn
end

local MainTab = createTab("Main", 0)
local PlayerTab = createTab("Player", 100)
local TeleportTab = createTab("Teleport", 200)

-- Các trang
local Pages = {}
local function createPage()
    local frame = Instance.new("Frame", MainFrame)
    frame.Size = UDim2.new(1, 0, 1, -40)
    frame.Position = UDim2.new(0,0,0,40)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    return frame
end

Pages.Main = createPage()
Pages.Player = createPage()
Pages.Teleport = createPage()

-- Switch tab
local function showPage(tab)
    for _,p in pairs(Pages) do p.Visible = false end
    Pages[tab].Visible = true
end
MainTab.MouseButton1Click:Connect(function() showPage("Main") end)
PlayerTab.MouseButton1Click:Connect(function() showPage("Player") end)
TeleportTab.MouseButton1Click:Connect(function() showPage("Teleport") end)
showPage("Main")

-- Toggle menu
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ========== SLIDER FUNCTION ==========
local function createSlider(parent, title, min, max, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, #parent:GetChildren()*45)
    frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.4,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(255,255,255)

    local slider = Instance.new("TextBox", frame)
    slider.Size = UDim2.new(0.6,0,1,0)
    slider.Position = UDim2.new(0.4,0,0,0)
    slider.Text = tostring(default)
    slider.ClearTextOnFocus = false
    slider.TextColor3 = Color3.fromRGB(0,255,0)

    slider.FocusLost:Connect(function()
        local val = tonumber(slider.Text)
        if val then
            if val < min then val = min end
            if val > max then val = max end
            slider.Text = tostring(val)
            callback(val)
        end
    end)
end

-- ========== MAIN TAB ==========
-- WalkSpeed
createSlider(Pages.Main,"WalkSpeed",16,200,16,function(val)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end)

-- JumpPower
createSlider(Pages.Main,"JumpPower",50,200,50,function(val)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
    end
end)

-- Fly Speed
local flying = false
local flySpeed = 50
createSlider(Pages.Main,"Fly Speed",10,50,50,function(val)
    flySpeed = val
end)

-- Fly Button
local flyBtn = Instance.new("TextButton", Pages.Main)
flyBtn.Size = UDim2.new(1,-20,0,40)
flyBtn.Position = UDim2.new(0,10,0,140)
flyBtn.Text = "Toggle Fly"
flyBtn.TextColor3 = Color3.fromRGB(255,255,255)
flyBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
flyBtn.MouseButton1Click:Connect(function()
    flying = not flying
    if flying then
        local char = LocalPlayer.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        spawn(function()
            while flying and task.wait() do
                if hum and root then
                    root.Velocity = hum.MoveDirection * flySpeed
                end
            end
        end)
    end
end)

-- Hop server
local hopBtn = Instance.new("TextButton", Pages.Main)
hopBtn.Size = UDim2.new(1,-20,0,40)
hopBtn.Position = UDim2.new(0,10,0,190)
hopBtn.Text = "Hop Low Server"
hopBtn.TextColor3 = Color3.fromRGB(255,255,255)
hopBtn.BackgroundColor3 = Color3.fromRGB(80,30,30)
hopBtn.MouseButton1Click:Connect(function()
    local req = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    local data = HttpService:JSONDecode(req)
    for _,v in pairs(data.data) do
        if v.playing < v.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer)
            break
        end
    end
end)

-- ESP Toggle
local espEnabled = false
local espBtn = Instance.new("TextButton", Pages.Main)
espBtn.Size = UDim2.new(1,-20,0,40)
espBtn.Position = UDim2.new(0,10,0,240)
espBtn.Text = "Toggle ESP Players"
espBtn.TextColor3 = Color3.fromRGB(255,255,255)
espBtn.BackgroundColor3 = Color3.fromRGB(40,40,80)

local function createESP(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        if not espEnabled then return end
        if not char:FindFirstChild("HumanoidRootPart") then return end

        -- Tên
        local billboard = Instance.new("BillboardGui", char.HumanoidRootPart)
        billboard.Size = UDim2.new(0,200,0,50)
        billboard.AlwaysOnTop = true
        local nameLabel = Instance.new("TextLabel", billboard)
        nameLabel.Size = UDim2.new(1,0,1,0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255,255,255)

        -- Ô vuông
        local box = Instance.new("BoxHandleAdornment", char.HumanoidRootPart)
        box.Size = Vector3.new(4,7,2)
        box.Color3 = Color3.fromRGB(255,255,255)
        box.Transparency = 0.5
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Adornee = char
    end)
end

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        for _,p in pairs(Players:GetPlayers()) do
            createESP(p)
        end
        Players.PlayerAdded:Connect(createESP)
    else
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("BillboardGui") or v:IsA("BoxHandleAdornment") then
                v:Destroy()
            end
        end
    end
end)

-- ========== PLAYER TAB ==========
local reBtn = Instance.new("TextButton", Pages.Player)
reBtn.Size = UDim2.new(1,-20,0,40)
reBtn.Position = UDim2.new(0,10,0,10)
reBtn.Text = "Rejoin"
reBtn.TextColor3 = Color3.fromRGB(255,255,255)
reBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
reBtn.MouseButton1Click:Connect(function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

local resetBtn = Instance.new("TextButton", Pages.Player)
resetBtn.Size = UDim2.new(1,-20,0,40)
resetBtn.Position = UDim2.new(0,10,0,60)
resetBtn.Text = "Reset Character"
resetBtn.TextColor3 = Color3.fromRGB(255,255,255)
resetBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
resetBtn.MouseButton1Click:Connect(function()
    LocalPlayer.Character:BreakJoints()
end)

-- ========== TELEPORT TAB ==========
local tpBtn = Instance.new("TextButton", Pages.Teleport)
tpBtn.Size = UDim2.new(1,-20,0,40)
tpBtn.Position = UDim2.new(0,10,0,10)
tpBtn.Text = "Teleport Spawn"
tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
tpBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
tpBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and workspace:FindFirstChild("SpawnLocation") then
        LocalPlayer.Character:MoveTo(workspace.SpawnLocation.Position)
    end
end)
