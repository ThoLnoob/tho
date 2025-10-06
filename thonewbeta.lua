--// Banana Galaxy Hub (Fixed Fly + ESP + Galaxy UI)
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "BananaGalaxyUI"

-- Nút tròn mở menu
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0, 100, 0, 200)
ToggleButton.BackgroundTransparency = 1
ToggleButton.Image = "rbxassetid://89300403770535" -- hình bạn gửi
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui

-- Khung menu chính
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 330)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -165)
MainFrame.Visible = false
MainFrame.Draggable = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

-- Hiệu ứng galaxy
local UIGradient = Instance.new("UIGradient", MainFrame)
UIGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 0, 100)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
}
UIGradient.Rotation = 45
task.spawn(function()
    while task.wait(0.05) do
        UIGradient.Rotation += 1
    end
end)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Tab bar
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 12)

local function createTab(name, posX)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 120, 1, 0)
    btn.Position = UDim2.new(0, posX, 0, 0)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundTransparency = 1
    return btn
end

local MainTab = createTab("Main", 0)
local PlayerTab = createTab("Player", 120)
local TeleportTab = createTab("Teleport", 240)

-- Trang
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
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.4,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(255,255,255)

    local slider = Instance.new("TextBox", frame)
    slider.Size = UDim2.new(0.6,0,1,0)
    slider.Position = UDim2.new(0.4,0,0,0)
    slider.Text = tostring(default)
    slider.ClearTextOnFocus = false
    slider.TextColor3 = Color3.fromRGB(0,255,255)

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
createSlider(Pages.Main,"WalkSpeed",16,200,16,function(val)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end)

createSlider(Pages.Main,"JumpPower",50,200,50,function(val)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
    end
end)

local flySpeed = 50
local flying = false
createSlider(Pages.Main,"Fly Speed",10,100,50,function(val)
    flySpeed = val
end)

-- FLY (đã fix - bay thật sự)
local UIS = game:GetService("UserInputService")
local flyBtn = Instance.new("TextButton", Pages.Main)
flyBtn.Size = UDim2.new(1,-20,0,40)
flyBtn.Position = UDim2.new(0,10,0,140)
flyBtn.Text = "Toggle Fly"
flyBtn.TextColor3 = Color3.fromRGB(255,255,255)
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(40,40,80)

flyBtn.MouseButton1Click:Connect(function()
    flying = not flying
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and root) then return end

    if flying then
        local bg = Instance.new("BodyGyro", root)
        local bv = Instance.new("BodyVelocity", root)
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero

        task.spawn(function()
            while flying and task.wait() do
                bg.CFrame = workspace.CurrentCamera.CFrame
                local moveDir = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + workspace.CurrentCamera.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - workspace.CurrentCamera.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - workspace.CurrentCamera.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + workspace.CurrentCamera.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0,1,0)
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveDir = moveDir - Vector3.new(0,1,0)
                end
                bv.Velocity = moveDir * flySpeed
            end
            bg:Destroy()
            bv:Destroy()
        end)
    end
end)

-- ESP
local espEnabled = false
local espBtn = Instance.new("TextButton", Pages.Main)
espBtn.Size = UDim2.new(1,-20,0,40)
espBtn.Position = UDim2.new(0,10,0,190)
espBtn.Text = "Toggle ESP Players"
espBtn.Font = Enum.Font.GothamBold
espBtn.TextColor3 = Color3.fromRGB(255,255,255)
espBtn.BackgroundColor3 = Color3.fromRGB(50,20,80)

local function createESP(player)
    if player == LocalPlayer then return end
    task.spawn(function()
        repeat task.wait(1) until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if player.Character:FindFirstChild("ESP_Box") then return end
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "ESP_Box"
        box.Adornee = player.Character
        box.Size = Vector3.new(4,6,2)
        box.Color3 = Color3.fromRGB(255,255,255)
        box.AlwaysOnTop = true
        box.Transparency = 0.3
        box.ZIndex = 10
        box.Parent = player.Character

        local billboard = Instance.new("BillboardGui", player.Character)
        billboard.Name = "ESP_Name"
        billboard.Adornee = player.Character:WaitForChild("Head")
        billboard.Size = UDim2.new(0,100,0,20)
        billboard.AlwaysOnTop = true

        local name = Instance.new("TextLabel", billboard)
        name.Size = UDim2.new(1,0,1,0)
        name.BackgroundTransparency = 1
        name.Text = player.Name
        name.TextColor3 = Color3.fromRGB(255,255,255)
        name.Font = Enum.Font.GothamBold
        name.TextScaled = true
    end)
end

local function removeESP()
    for _,p in pairs(Players:GetPlayers()) do
        if p.Character then
            for _,v in pairs(p.Character:GetChildren()) do
                if v.Name == "ESP_Box" or v.Name == "ESP_Name" then v:Destroy() end
            end
        end
    end
end

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        for _,p in pairs(Players:GetPlayers()) do createESP(p) end
        Players.PlayerAdded:Connect(function(p) createESP(p) end)
    else
        removeESP()
    end
end)

-- PLAYER TAB
local function createButton(parent,text,callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1,-20,0,40)
    btn.Position = UDim2.new(0,10,0,#parent:GetChildren()*45)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(30,30,60)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

createButton(Pages.Player,"Rejoin",function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

createButton(Pages.Player,"Reset Character",function()
    LocalPlayer.Character:BreakJoints()
end)

createButton(Pages.Player,"Hop Low Server",function()
    local req = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    local data = HttpService:JSONDecode(req)
    for _,v in pairs(data.data) do
        if v.playing < v.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer)
            break
        end
    end
end)

-- TELEPORT TAB
createButton(Pages.Teleport,"Teleport to Spawn",function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and workspace:FindFirstChild("SpawnLocation") then
        LocalPlayer.Character:MoveTo(workspace.SpawnLocation.Position)
    end
end)
