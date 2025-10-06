--// Menu đầu tiên của tho
-- Galaxy UI Hub - Full improved (LocalScript)
-- Theme: Galaxy (purple / cyan neon)
-- Features: draggable menu, left tabs, right function pane (all visible), toggle switches, +/- controls, ESP full, fly/walk/jump controls, hop server, rejoin, reset, teleport spawn
-- NOTE: Place in StarterPlayerScripts for testing in your own place.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- helpers
local function new(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            if k ~= "Parent" then obj[k] = v end
        end
        if props.Parent then obj.Parent = props.Parent end
    end
    return obj
end

-- Root GUI (use PlayerGui for safety)
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = new("ScreenGui",{Parent = playerGui, Name = "GalaxyHubUI", ResetOnSpawn = false})

-- Styles
local BG1 = Color3.fromRGB(18,10,30)     -- deep purple
local BG2 = Color3.fromRGB(28,12,55)     -- darker
local ACCENT = Color3.fromRGB(125, 50, 255) -- purple neon
local ACCENT2 = Color3.fromRGB(40,200,255)  -- cyan neon
local TEXT = Color3.fromRGB(235,235,240)

-- Floating circular toggle button (draggable)
local ToggleButton = new("ImageButton", {
    Parent = ScreenGui,
    Name = "GalaxyToggle",
    Size = UDim2.new(0,64,0,64),
    Position = UDim2.new(0, 40, 0.5, -32),
    BackgroundTransparency = 1,
    Image = "rbxassetid://89300403770535", -- use a neutral asset or your own
    AutoButtonColor = false,
    ZIndex = 5
})
-- small glow
local glow = new("UICorner",{Parent = ToggleButton, CornerRadius = UDim.new(0,32)})
-- Drag behavior for ToggleButton
do
    local dragging, dragInput, dragStart, startPos
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = ToggleButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    ToggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Main frame (centered by default)
local MainFrame = new("Frame", {
    Parent = ScreenGui,
    Name = "MainFrame",
    Size = UDim2.new(0,520,0,360),
    Position = UDim2.new(0.5,-260,0.5,-180),
    BackgroundColor3 = BG1,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 4
})
new("UICorner",{Parent = MainFrame, CornerRadius = UDim.new(0,14)})
-- outer glow
local outer = new("Frame",{Parent = MainFrame, Size = UDim2.new(1,8,1,8), Position = UDim2.new(0,-4,0,-4), BackgroundTransparency = 1})
new("UICorner",{Parent = outer, CornerRadius = UDim.new(0,16)})

-- Top bar with title and window controls
local TopBar = new("Frame",{Parent = MainFrame, Size = UDim2.new(1,0,0,44), BackgroundColor3 = BG2, BorderSizePixel = 0})
new("UICorner",{Parent = TopBar, CornerRadius = UDim.new(0,12)})
local Title = new("TextLabel",{Parent = TopBar, Size = UDim2.new(0.6,0,1,0), Position = UDim2.new(0,14,0,0), BackgroundTransparency = 1, Text = "Galaxy Hub • Tho Edition", TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left})
-- window controls: minimize, maximize (square), close
local controls = new("Frame",{Parent = TopBar, Size = UDim2.new(0,120,1,0), Position = UDim2.new(1,-130,0,0), BackgroundTransparency = 1})
local btnMin = new("TextButton",{Parent = controls, Size = UDim2.new(0,34,0,28), Position = UDim2.new(0,0,0,8), Text = "—", BackgroundColor3 = BG1, TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 18, BorderSizePixel = 0})
local btnMax = new("TextButton",{Parent = controls, Size = UDim2.new(0,34,0,28), Position = UDim2.new(0,40,0,8), Text = "▢", BackgroundColor3 = BG1, TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0})
local btnClose = new("TextButton",{Parent = controls, Size = UDim2.new(0,34,0,28), Position = UDim2.new(0,80,0,8), Text = "✕", BackgroundColor3 = Color3.fromRGB(200,50,70), TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0})
for _,b in pairs({btnMin, btnMax, btnClose}) do
    new("UICorner",{Parent = b, CornerRadius = UDim.new(0,6)})
    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.1 end)
    b.MouseLeave:Connect(function() b.BackgroundTransparency = 0 end)
end
-- minimize / maximize / close behavior
local minimized = false
btnMin.MouseButton1Click:Connect(function()
    if minimized then
        MainFrame.Size = UDim2.new(0,520,0,360)
        MainFrame.Position = UDim2.new(0.5,-260,0.5,-180)
        minimized = false
    else
        MainFrame.Size = UDim2.new(0,280,0,60)
        MainFrame.Position = UDim2.new(0.02,0,0.02,0)
        minimized = true
    end
end)
btnMax.MouseButton1Click:Connect(function()
    MainFrame.Size = UDim2.new(0,math.clamp(workspace.CurrentCamera.ViewportSize.X-40,300,1200),0,math.clamp(workspace.CurrentCamera.ViewportSize.Y-80,120,800))
    MainFrame.Position = UDim2.new(0.5, -(MainFrame.Size.X.Offset/2), 0.5, -(MainFrame.Size.Y.Offset/2))
end)
btnClose.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Make main frame draggable from TopBar
do
    local dragging, dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Main body
local Body = new("Frame",{Parent = MainFrame, Size = UDim2.new(1,0,1,-44), Position = UDim2.new(0,0,0,44), BackgroundColor3 = BG2})
new("UICorner",{Parent = Body, CornerRadius = UDim.new(0,12)})

-- Left tab list
local LeftPane = new("Frame",{Parent = Body, Size = UDim2.new(0,160,1,0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = Color3.fromRGB(14,8,24)})
new("UICorner",{Parent = LeftPane, CornerRadius = UDim.new(0,10)})
local tabs = {"Main","Player","Teleport","Visual"}
local tabButtons = {}
local tabList = new("UIListLayout",{Parent = LeftPane})
tabList.Padding = UDim.new(0,8)
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabList.VerticalAlignment = Enum.VerticalAlignment.Top
tabList.SortOrder = Enum.SortOrder.LayoutOrder

local contentPane = new("Frame",{Parent = Body, Size = UDim2.new(1,-160,1,0), Position = UDim2.new(0,160,0,0), BackgroundTransparency = 1})
-- right content uses UIListLayout (vertical list of functions)
local contentLayout = new("UIListLayout",{Parent = contentPane})
contentLayout.Padding = UDim.new(0,8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- utility to create function rows
local function createFunctionRow(title, desc)
    local row = new("Frame",{Parent = contentPane, Size = UDim2.new(1,-20,0,48), BackgroundColor3 = Color3.fromRGB(18,12,32)})
    new("UICorner",{Parent = row, CornerRadius = UDim.new(0,8)})
    local left = new("Frame",{Parent = row, Size = UDim2.new(0.7, -10,1,0), Position = UDim2.new(0,10,0,0), BackgroundTransparency = 1})
    local label = new("TextLabel",{Parent = left, Size = UDim2.new(1,0,0.5,0), BackgroundTransparency = 1, Text = title, TextColor3 = TEXT, Font = Enum.Font.GothamSemibold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
    local sub = new("TextLabel",{Parent = left, Size = UDim2.new(1,0,0.5,0), Position = UDim2.new(0,0,0.5,0), BackgroundTransparency = 1, Text = desc or "", TextColor3 = Color3.fromRGB(170,170,185), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
    local right = new("Frame",{Parent = row, Size = UDim2.new(0.3, -20,1,0), Position = UDim2.new(0.7,10,0,0), BackgroundTransparency = 1})
    return row, left, right, label, sub
end

-- small toggle switch creation
local function createToggle(parent, initial)
    local sw = new("TextButton",{Parent = parent, Size = UDim2.new(0,64,0,28), BackgroundColor3 = Color3.fromRGB(40,40,55), Text = "", AutoButtonColor = false})
    new("UICorner",{Parent = sw, CornerRadius = UDim.new(0,14)})
    local knob = new("Frame",{Parent = sw, Size = UDim2.new(0.48,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = Color3.fromRGB(200,200,200)})
    new("UICorner",{Parent = knob, CornerRadius = UDim.new(0,14)})
    local state = initial or false
    local function updateVisual()
        if state then
            knob.Position = UDim2.new(0.52,0,0,0)
            knob.BackgroundColor3 = ACCENT2
            sw.BackgroundColor3 = Color3.fromRGB(30,30,60)
        else
            knob.Position = UDim2.new(0,0,0,0)
            knob.BackgroundColor3 = Color3.fromRGB(200,200,200)
            sw.BackgroundColor3 = Color3.fromRGB(40,40,55)
        end
    end
    sw.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
    end)
    updateVisual()
    return {
        Button = sw,
        Get = function() return state end,
        Set = function(v) state = v; updateVisual() end,
        OnChanged = function(fn) sw.MouseButton1Click:Connect(function() fn(state) end) end
    }
end

-- plus/minus control creation
local function createPlusMinus(parent, default, minV, maxV)
    local frame = new("Frame",{Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
    local minus = new("TextButton",{Parent = frame, Size = UDim2.new(0,36,0,28), Position = UDim2.new(0,0,0,10), Text = "-", BackgroundColor3 = Color3.fromRGB(40,40,55), TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 18, BorderSizePixel = 0})
    local plus = new("TextButton",{Parent = frame, Size = UDim2.new(0,36,0,28), Position = UDim2.new(1,-36,0,10), Text = "+", BackgroundColor3 = Color3.fromRGB(40,40,55), TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 18, BorderSizePixel = 0})
    local label = new("TextLabel",{Parent = frame, Size = UDim2.new(1,-76,0,28), Position = UDim2.new(0,40,0,10), BackgroundTransparency = 1, Text = tostring(default), TextColor3 = ACCENT2, Font = Enum.Font.GothamBold, TextSize = 16})
    new("UICorner",{Parent = minus, CornerRadius = UDim.new(0,6)})
    new("UICorner",{Parent = plus, CornerRadius = UDim.new(0,6)})
    local val = default or 16
    minV = minV or -10000; maxV = maxV or 10000
    minus.MouseButton1Click:Connect(function()
        val = math.max(minV, val - 1)
        label.Text = tostring(val)
    end)
    plus.MouseButton1Click:Connect(function()
        val = math.min(maxV, val + 1)
        label.Text = tostring(val)
    end)
    return {
        Frame = frame,
        Get = function() return val end,
        Set = function(v) val = math.clamp(v,minV,maxV); label.Text = tostring(val) end,
        Label = label,
        Plus = plus,
        Minus = minus
    }
end

-- build left tab buttons
local function selectTab(name)
    -- highlight selected button and update visible content (we will not hide rows, but reposition by tag)
    for k,btn in pairs(tabButtons) do
        if k == name then
            btn.BackgroundColor3 = ACCENT; btn.TextColor3 = Color3.new(0,0,0)
        else
            btn.BackgroundColor3 = Color3.fromRGB(18,10,30); btn.TextColor3 = TEXT
        end
    end
    -- show corresponding rows (we mark rows with attribute Tag)
    for _,child in pairs(contentPane:GetChildren()) do
        if child:IsA("Frame") and child:GetAttribute("Tag") then
            child.Visible = (child:GetAttribute("Tag") == name)
        end
    end
end

for i,name in ipairs(tabs) do
    local b = new("TextButton",{Parent = LeftPane, Size = UDim2.new(1,-16,0,46), Position = UDim2.new(0,8,0,10 + (i-1)*54), Text = name, BackgroundColor3 = Color3.fromRGB(18,10,30), TextColor3 = TEXT, Font = Enum.Font.GothamSemibold, TextSize = 16, BorderSizePixel = 0})
    new("UICorner",{Parent = b, CornerRadius = UDim.new(0,8)})
    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.05 end)
    b.MouseLeave:Connect(function() b.BackgroundTransparency = 0 end)
    tabButtons[name] = b
    b.MouseButton1Click:Connect(function() selectTab(name) end)
end

-- ========== FUNCTIONS ROWS ==========

-- MAIN TAB rows
-- WalkSpeed control
local rowWS,_,rightWS,labelWS,subWS = createFunctionRow("WalkSpeed","Set your walking speed")
rowWS:SetAttribute("Tag","Main")
local pmWS = createPlusMinus(rightWS,16,16,300)
pmWS.Label.TextColor3 = ACCENT2
pmWS.Label.Text = "16"
pmWS.Plus.MouseButton1Click:Connect(function() 
    local v = pmWS.Get()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v
    end
end)
pmWS.Minus.MouseButton1Click:Connect(function() 
    local v = pmWS.Get()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v
    end
end)
-- apply on change continuously (watch label)
pmWS.Plus.MouseButton1Click:Connect(function() end) -- already handled
pmWS.Minus.MouseButton1Click:Connect(function() end)

-- JumpPower control
local rowJP,_,rightJP,labelJP,subJP = createFunctionRow("JumpPower","Set your jump power")
rowJP:SetAttribute("Tag","Main")
local pmJP = createPlusMinus(rightJP,50,30,300)
pmJP.Label.TextColor3 = ACCENT2
pmJP.Label.Text = "50"
pmJP.Plus.MouseButton1Click:Connect(function()
    local v = pmJP.Get()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = v
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").UseJumpPower = true
    end
end)
pmJP.Minus.MouseButton1Click:Connect(function()
    local v = pmJP.Get()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = v
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").UseJumpPower = true
    end
end)

-- Fly Speed and toggle
local rowFly,_,rightFly,labelFly,subFly = createFunctionRow("Fly Speed","Speed while flying")
rowFly:SetAttribute("Tag","Main")
local pmFly = createPlusMinus(rightFly,50,10,200)
pmFly.Label.TextColor3 = ACCENT2
pmFly.Label.Text = "50"
local flyToggle = createToggle(rightFly,false)
flyToggle.Button.Position = UDim2.new(0,0,0,10)
flyToggle.OnChanged(function(state)
    -- handled below
end)

-- Fly logic
local flying = false
local flyBody = nil
local function startFly()
    if flying then return end
    flying = true
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    flyBody = Instance.new("BodyVelocity")
    flyBody.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBody.Velocity = Vector3.new(0,0,0)
    flyBody.P = 3000
    flyBody.Parent = hrp
    spawn(function()
        while flying and hrp and flyBody and task.wait() do
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not humanoid then break end
            local dir = humanoid.MoveDirection
            local spd = pmFly.Get()
            flyBody.Velocity = Vector3.new(dir.X * spd, 0, dir.Z * spd)
            -- hold space to go up
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
                flyBody.Velocity = flyBody.Velocity + Vector3.new(0, spd * 0.6, 0)
            end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) then
                flyBody.Velocity = flyBody.Velocity + Vector3.new(0, -spd * 0.6, 0)
            end
        end
    end)
end
local function stopFly()
    flying = false
    if flyBody then
        flyBody:Destroy()
        flyBody = nil
    end
end
-- toggle hook
flyToggle.OnChanged(function(state)
    if state then startFly() else stopFly() end
end)

-- Hop server (low hop)
local rowHop,_,rightHop,labelHop,subHop = createFunctionRow("Hop Low Server","Teleport to another low-pop server")
rowHop:SetAttribute("Tag","Main")
local hopButton = new("TextButton",{Parent = rightHop, Size = UDim2.new(1,0,0,28), Position = UDim2.new(0,0,10,0), Text = "Hop Low", BackgroundColor3 = ACCENT, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 14})
new("UICorner",{Parent = hopButton, CornerRadius = UDim.new(0,6)})
hopButton.MouseButton1Click:Connect(function()
    -- basic fetch servers (may error due to rate limits)
    local success, res = pcall(function()
        local req = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
        return HttpService:JSONDecode(req)
    end)
    if success and res and res.data then
        for _,v in pairs(res.data) do
            if v.playing < v.maxPlayers then
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer) end)
                break
            end
        end
    else
        -- fallback: teleport to same place
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end
end)

-- ESP (Visual tab)
local rowESP,_,rightESP,labelESP,subESP = createFunctionRow("ESP Players","Show name, health and box for all players")
rowESP:SetAttribute("Tag","Visual")
local espToggle = createToggle(rightESP,false)
local espEnabled = false
local createdESP = {} -- map player -> {billboardGui, box}

local function createForCharacter(player)
    if not player or player == LocalPlayer then return end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    -- name + hp billboard
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    -- BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GHub_ESP_Billboard"
    billboard.Adornee = hrp
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0,180,0,60)
    billboard.StudsOffset = Vector3.new(0,2.5,0)
    billboard.Parent = hrp

    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1,0,0.5,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = ACCENT2
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14

    local hpLabel = Instance.new("TextLabel", billboard)
    hpLabel.Size = UDim2.new(1,0,0.5,0)
    hpLabel.Position = UDim2.new(0,0,0.5,0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text = "HP: ?"
    hpLabel.TextColor3 = Color3.fromRGB(255,255,255)
    hpLabel.Font = Enum.Font.Gotham
    hpLabel.TextSize = 12

    -- Box (BoxHandleAdornment attached to hrp)
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "GHub_ESP_Box"
    box.Adornee = hrp
    box.Size = Vector3.new(4,7,2)
    box.Color3 = Color3.fromRGB(255,255,255)
    box.Transparency = 0.2
    box.AlwaysOnTop = true
    box.Parent = hrp

    -- update loop
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not player.Parent or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            if conn then conn:Disconnect(); conn = nil end
            if billboard then billboard:Destroy() end
            if box then box:Destroy() end
            createdESP[player] = nil
            return
        end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hpLabel.Text = "HP: "..tostring(math.floor(hum.Health))
        end
    end)

    createdESP[player] = {Billboard = billboard, Box = box, Conn = conn}
end

local function removeAllESP()
    for p,data in pairs(createdESP) do
        if data.Billboard then pcall(function() data.Billboard:Destroy() end) end
        if data.Box then pcall(function() data.Box:Destroy() end) end
        if data.Conn then pcall(function() data.Conn:Disconnect() end) end
    end
    createdESP = {}
end

espToggle.OnChanged(function(state)
    espEnabled = state
    if espEnabled then
        -- create for all players
        for _,p in pairs(Players:GetPlayers()) do
            if p.Character then createForCharacter(p) end
        end
        -- connect characteradded for future players
        Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function() if espEnabled then createForCharacter(p) end end)
        end)
        -- handle existing players respawns
        for _,p in pairs(Players:GetPlayers()) do
            p.CharacterAdded:Connect(function() if espEnabled then createForCharacter(p) end end)
        end
    else
        removeAllESP()
    end
end)

-- PLAYER TAB rows
local rowRejoin,_,rightRejoin,labelRejoin,subRejoin = createFunctionRow("Rejoin","Teleport to same place")
rowRejoin:SetAttribute("Tag","Player")
local rejoinBtn = new("TextButton",{Parent = rightRejoin, Size = UDim2.new(1,0,0,28), Position = UDim2.new(0,0,10,0), Text = "Rejoin", BackgroundColor3 = ACCENT2, TextColor3 = Color3.new(0,0,0), Font = Enum.Font.GothamBold})
new("UICorner",{Parent = rejoinBtn, CornerRadius = UDim.new(0,6)})
rejoinBtn.MouseButton1Click:Connect(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

local rowReset,_,rightReset,labelReset,subReset = createFunctionRow("Reset Character","Break joints")
rowReset:SetAttribute("Tag","Player")
local resetBtn = new("TextButton",{Parent = rightReset, Size = UDim2.new(1,0,0,28), Position = UDim2.new(0,0,10,0), Text = "Reset", BackgroundColor3 = ACCENT2, TextColor3 = Color3.new(0,0,0), Font = Enum.Font.GothamBold})
new("UICorner",{Parent = resetBtn, CornerRadius = UDim.new(0,6)})
resetBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end
end)

-- TELEPORT TAB rows
local rowTP,_,rightTP,labelTP,subTP = createFunctionRow("Teleport Spawn","Move to SpawnLocation if present")
rowTP:SetAttribute("Tag","Teleport")
local tpBtn = new("TextButton",{Parent = rightTP, Size = UDim2.new(1,0,0,28), Position = UDim2.new(0,0,10,0), Text = "Teleport Spawn", BackgroundColor3 = ACCENT2, TextColor3 = Color3.new(0,0,0), Font = Enum.Font.GothamBold})
new("UICorner",{Parent = tpBtn, CornerRadius = UDim.new(0,6)})
tpBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and workspace:FindFirstChild("SpawnLocation") then
        LocalPlayer.Character:MoveTo(workspace.SpawnLocation.Position)
    end
end)

-- Initialize: set default tab
selectTab("Main")

-- Toggle mainframe visibility via floating button
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- keep UI responsive to character changes (update walk/jump values from defaults)
LocalPlayer.CharacterAdded:Connect(function(char)
    wait(0.5)
    if pmWS and pmWS.Set then
        -- set values to current humanoid if present
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pmWS.Set(hum.WalkSpeed)
            pmJP.Set(hum.JumpPower)
        end
    end
end)

-- Ensure plus/minus changes apply immediately
-- (we already attached on button clicks to set values)

-- Clean up on script disable/unload
ScreenGui.ChildRemoved:Connect(function(child)
    -- placeholder if you want cleanup
end)

-- Final cosmetic: animate opening when shown
MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    if MainFrame.Visible then
        MainFrame.Position = UDim2.new(0.5,-260,0.2,-180)
        TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0.5,-260,0.5,-180)}):Play()
    end
end)
