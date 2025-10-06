-- Tho Lnoob Galaxy Hub - Full Fixed (LocalScript)
-- Paste into StarterPlayerScripts (for testing in your own place)
-- Features:
--  • Galaxy theme, draggable floating toggle button
--  • Draggable main window, title "Tho Lnoob"
--  • Left tabs (Main / Player / Teleport / Visual)
--  • Right pane shows ALL functions for selected tab
--  • Toggle switches (gạt style) with clear visual state
--  • + / - controls for WalkSpeed, JumpPower, Fly Speed (apply immediately)
--  • Fly (hold Space to go up, Ctrl to go down)
--  • ESP: name + HP + white box for all players (toggleable)
--  • Hop low server (requests public server list, pcall guarded)
--  • Rejoin, Reset, Teleport to Spawn
--  • Toggle menu via floating button or key M
--  • Clean cleanup and robust checks

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- small helper constructor
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

-- Colors / theme
local BG1 = Color3.fromRGB(18,10,30)
local BG2 = Color3.fromRGB(28,12,55)
local ACCENT = Color3.fromRGB(125,50,255)
local ACCENT2 = Color3.fromRGB(40,200,255)
local TEXT = Color3.fromRGB(235,235,240)
local OFF_BG = Color3.fromRGB(45,45,55)
local ON_BG = Color3.fromRGB(30,40,70)

-- Root GUI
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = new("ScreenGui", {Parent = playerGui, Name = "ThoLnoobGalaxyHub", ResetOnSpawn = false})

-- Floating circular toggle button (draggable + click)
local ToggleButton = new("ImageButton", {
    Parent = ScreenGui,
    Name = "GalaxyToggle",
    Size = UDim2.new(0,64,0,64),
    Position = UDim2.new(0, 40, 0.5, -32),
    BackgroundTransparency = 0,
    BackgroundColor3 = BG2,
    Image = "rbxassetid://89300403770535", -- replace if you want
    AutoButtonColor = false,
    ZIndex = 5
})
new("UICorner", {Parent = ToggleButton, CornerRadius = UDim.new(0,32)})
ToggleButton.ImageTransparency = 0.0

-- make toggle button draggable
do
    local dragging = false
    local dragStart, startPos, dragInput

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

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Main window
local MainFrame = new("Frame", {
    Parent = ScreenGui,
    Name = "MainFrame",
    Size = UDim2.new(0,580,0,420),
    Position = UDim2.new(0.5, -290, 0.5, -210),
    BackgroundColor3 = BG1,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 4
})
new("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0,14)})
-- top glow frame (subtle)
local GlowTop = new("Frame", {Parent = MainFrame, Size = UDim2.new(1,0,0,6), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1})
-- Top bar
local TopBar = new("Frame", {Parent = MainFrame, Size = UDim2.new(1,0,0,58), BackgroundColor3 = BG2})
new("UICorner", {Parent = TopBar, CornerRadius = UDim.new(0,12)})

-- Title (Tho Lnoob)
local TitleLabel = new("TextLabel", {
    Parent = TopBar,
    Text = "Tho Lnoob",
    TextColor3 = TEXT,
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    Position = UDim2.new(0.02, 0, 0, 0),
    Size = UDim2.new(0.5,0,1,0),
    TextXAlignment = Enum.TextXAlignment.Left
})
-- small subtitle
local Subtitle = new("TextLabel", {
    Parent = TopBar,
    Text = "Galaxy Hub",
    TextColor3 = ACCENT2,
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    Position = UDim2.new(0.02, 0, 0.58, 0),
    Size = UDim2.new(0.5,0,0.42,0),
    TextXAlignment = Enum.TextXAlignment.Left
})

-- window controls (minimize, maximize, close)
local Controls = new("Frame", {Parent = TopBar, Size = UDim2.new(0,120,1,0), Position = UDim2.new(1,-140,0,0), BackgroundTransparency = 1})
local btnMin, btnMax, btnClose
btnMin = new("TextButton", {Parent = Controls, Size = UDim2.new(0,36,0,30), Position = UDim2.new(0,0,0.1,0), Text = "—", BackgroundColor3 = BG1, TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 18, BorderSizePixel = 0})
btnMax = new("TextButton", {Parent = Controls, Size = UDim2.new(0,36,0,30), Position = UDim2.new(0,44,0.1,0), Text = "▢", BackgroundColor3 = BG1, TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0})
btnClose = new("TextButton", {Parent = Controls, Size = UDim2.new(0,36,0,30), Position = UDim2.new(0,88,0.1,0), Text = "✕", BackgroundColor3 = Color3.fromRGB(200,50,70), TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0})
for _,b in pairs({btnMin, btnMax, btnClose}) do new("UICorner",{Parent = b, CornerRadius = UDim.new(0,6)}) end
btnClose.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
btnMin.MouseButton1Click:Connect(function()
    if MainFrame.Size.X.Offset > 100 then
        MainFrame.Size = UDim2.new(0,280,0,64)
        MainFrame.Position = UDim2.new(0.02,0,0.02,0)
    else
        MainFrame.Size = UDim2.new(0,580,0,420)
        MainFrame.Position = UDim2.new(0.5,-290,0.5,-210)
    end
end)
btnMax.MouseButton1Click:Connect(function()
    MainFrame.Size = UDim2.new(0, math.clamp(workspace.CurrentCamera.ViewportSize.X - 40, 300, 1400), 0, math.clamp(workspace.CurrentCamera.ViewportSize.Y - 80, 120, 900))
    MainFrame.Position = UDim2.new(0.5, -(MainFrame.Size.X.Offset/2), 0.5, -(MainFrame.Size.Y.Offset/2))
end)

-- make MainFrame draggable from TopBar
do
    local dragging, dragStart, startPos, dragInput
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Body: Left tabs + Right content
local Body = new("Frame", {Parent = MainFrame, Size = UDim2.new(1,0,1,-58), Position = UDim2.new(0,0,0,58), BackgroundTransparency = 1})
-- left pane
local LeftPane = new("Frame", {Parent = Body, Size = UDim2.new(0,180,1,0), BackgroundColor3 = Color3.fromRGB(14,8,24)})
new("UICorner", {Parent = LeftPane, CornerRadius = UDim.new(0,10)})
local LeftList = new("UIListLayout", {Parent = LeftPane})
LeftList.Padding = UDim.new(0,8)
LeftList.SortOrder = Enum.SortOrder.LayoutOrder
-- content pane
local ContentPane = new("Frame", {Parent = Body, Size = UDim2.new(1,-180,1,0), Position = UDim2.new(0,180,0,0), BackgroundTransparency = 1})
local ContentLayout = new("UIListLayout", {Parent = ContentPane}); ContentLayout.Padding = UDim.new(0,8); ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- tabs
local tabs = {"Main","Player","Teleport","Visual"}
local tabButtons = {}
local function selectTab(name)
    for k,btn in pairs(tabButtons) do
        if k == name then
            btn.BackgroundColor3 = ACCENT; btn.TextColor3 = Color3.fromRGB(0,0,0)
        else
            btn.BackgroundColor3 = Color3.fromRGB(18,10,30); btn.TextColor3 = TEXT
        end
    end
    for _,child in pairs(ContentPane:GetChildren()) do
        if child:IsA("Frame") and child:GetAttribute("Tag") then
            child.Visible = (child:GetAttribute("Tag") == name)
        end
    end
end

for i,name in ipairs(tabs) do
    local b = new("TextButton", {Parent = LeftPane, Size = UDim2.new(1,-20,0,50), Position = UDim2.new(0,10,0,10 + (i-1)*60), Text = name, BackgroundColor3 = Color3.fromRGB(18,10,30), TextColor3 = TEXT, Font = Enum.Font.GothamSemibold, TextSize = 16, BorderSizePixel = 0})
    new("UICorner",{Parent = b, CornerRadius = UDim.new(0,8)})
    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.05 end)
    b.MouseLeave:Connect(function() b.BackgroundTransparency = 0 end)
    tabButtons[name] = b
    b.MouseButton1Click:Connect(function() selectTab(name) end)
end
selectTab("Main")

-- helper to make rows in content
local function createFunctionRow(tag, title, subtitle)
    local row = new("Frame", {Parent = ContentPane, Size = UDim2.new(1,-20,0,52), BackgroundColor3 = Color3.fromRGB(18,12,32)})
    new("UICorner", {Parent = row, CornerRadius = UDim.new(0,8)})
    row:SetAttribute("Tag", tag)
    local left = new("Frame", {Parent = row, Size = UDim2.new(0.68,0,1,0), BackgroundTransparency = 1})
    local titleLbl = new("TextLabel", {Parent = left, Text = title, BackgroundTransparency = 1, TextColor3 = TEXT, Font = Enum.Font.GothamSemibold, TextSize = 14, Size = UDim2.new(1,0,0.6,0), TextXAlignment = Enum.TextXAlignment.Left})
    local subLbl = new("TextLabel", {Parent = left, Text = subtitle or "", BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(170,170,185), Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(1,0,0.4,0), Position = UDim2.new(0,0,0.6,0), TextXAlignment = Enum.TextXAlignment.Left})
    local right = new("Frame", {Parent = row, Size = UDim2.new(0.32,0,1,0), BackgroundTransparency = 1})
    return row, left, right, titleLbl, subLbl
end

-- toggle switch builder (gạt style)
local function createSwitch(parent, initial)
    local sw = new("TextButton", {Parent = parent, Size = UDim2.new(0,68,0,30), BackgroundColor3 = OFF_BG, AutoButtonColor = false, Text = ""})
    new("UICorner", {Parent = sw, CornerRadius = UDim.new(0,16)})
    local knob = new("Frame", {Parent = sw, Size = UDim2.new(0.48,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = Color3.fromRGB(220,220,220)})
    new("UICorner", {Parent = knob, CornerRadius = UDim.new(0,14)})
    local state = initial or false
    local function refresh()
        if state then
            sw.BackgroundColor3 = ON_BG
            knob:TweenPosition(UDim2.new(0.52,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.12, true)
            knob.BackgroundColor3 = ACCENT2
        else
            sw.BackgroundColor3 = OFF_BG
            knob:TweenPosition(UDim2.new(0,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.12, true)
            knob.BackgroundColor3 = Color3.fromRGB(220,220,220)
        end
    end
    sw.MouseButton1Click:Connect(function()
        state = not state
        refresh()
    end)
    refresh()
    return {
        Button = sw,
        Set = function(v) state = v; refresh() end,
        Get = function() return state end,
        OnChanged = function(fn) sw.MouseButton1Click:Connect(function() fn(state) end) end
    }
end

-- plus/minus control builder
local function createPlusMinus(parent, default, minV, maxV)
    local cont = new("Frame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
    local minus = new("TextButton", {Parent = cont, Text = "-", Size = UDim2.new(0,36,0,30), Position = UDim2.new(0,6,0,11), BackgroundColor3 = Color3.fromRGB(40,40,55), TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 20, BorderSizePixel = 0})
    new("UICorner", {Parent = minus, CornerRadius = UDim.new(0,8)})
    local plus = new("TextButton", {Parent = cont, Text = "+", Size = UDim2.new(0,36,0,30), Position = UDim2.new(1,-42,0,11), BackgroundColor3 = Color3.fromRGB(40,40,55), TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 20, BorderSizePixel = 0})
    new("UICorner", {Parent = plus, CornerRadius = UDim.new(0,8)})
    local label = new("TextLabel", {Parent = cont, Text = tostring(default), Size = UDim2.new(1,-92,0,30), Position = UDim2.new(0,50,0,11), BackgroundTransparency = 1, TextColor3 = ACCENT2, Font = Enum.Font.GothamBold, TextSize = 16})
    local val = default or 0
    minV = minV or -math.huge; maxV = maxV or math.huge
    local function set(v)
        val = math.clamp(math.floor(v), minV, maxV)
        label.Text = tostring(val)
    end
    minus.MouseButton1Click:Connect(function()
        set(val - 1)
    end)
    plus.MouseButton1Click:Connect(function()
        set(val + 1)
    end)
    set(default)
    return {
        Frame = cont,
        Get = function() return val end,
        Set = function(v) set(v) end,
        Label = label,
        Plus = plus,
        Minus = minus
    }
end

-- --------------- Implementation of functions ----------------
-- Track UI elements we need to manipulate
local pmWalk, pmJump, pmFly, flySwitch
local espSwitch

-- MAIN tab rows
local rowWalk, _, rightWalk = createFunctionRow("Main", "WalkSpeed", "Adjust walking speed")
pmWalk = createPlusMinus(rightWalk, 16, 16, 300)
pmWalk.Label.TextColor3 = ACCENT2
pmWalk.Set(16)
-- apply when changed: we hook plus/minus buttons to set WalkSpeed
pmWalk.Plus.MouseButton1Click:Connect(function() 
    local v = pmWalk.Get()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v
    end
end)
pmWalk.Minus.MouseButton1Click:Connect(function()
    local v = pmWalk.Get()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v
    end
end)

local rowJump, _, rightJump = createFunctionRow("Main", "JumpPower", "Adjust jump power")
pmJump = createPlusMinus(rightJump, 50, 30, 400)
pmJump.Label.TextColor3 = ACCENT2
pmJump.Set(50)
pmJump.Plus.MouseButton1Click:Connect(function()
    local v = pmJump.Get()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local H = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        H.JumpPower = v
        H.UseJumpPower = true
    end
end)
pmJump.Minus.MouseButton1Click:Connect(function()
    local v = pmJump.Get()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local H = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        H.JumpPower = v
        H.UseJumpPower = true
    end
end)

local rowFly, _, rightFly = createFunctionRow("Main", "Fly", "Toggle flight and adjust speed")
pmFly = createPlusMinus(rightFly, 50, 10, 300)
pmFly.Label.TextColor3 = ACCENT2
pmFly.Set(50)
flySwitch = createSwitch(rightFly, false)
local flying = false
local flyBody = nil

local function startFly()
    if flying then return end
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    flying = true
    flyBody = Instance.new("BodyVelocity")
    flyBody.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBody.Velocity = Vector3.new(0,0,0)
    flyBody.P = 3000
    flyBody.Parent = hrp
    spawn(function()
        while flying and flyBody and hrp and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") do
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local dir = hum.MoveDirection
            local spd = pmFly.Get()
            local vy = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vy = spd * 0.6 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then vy = -spd * 0.6 end
            flyBody.Velocity = Vector3.new(dir.X * spd, vy, dir.Z * spd)
            task.wait()
        end
    end)
end

local function stopFly()
    flying = false
    if flyBody then
        pcall(function() flyBody:Destroy() end)
        flyBody = nil
    end
end

flySwitch.OnChanged(function(state)
    if state then startFly() else stopFly() end
end)

-- Hop Low Server row
local rowHop, _, rightHop = createFunctionRow("Main", "Hop Low Server", "Teleport to a lower-pop server")
local hopBtn = new("TextButton", {Parent = rightHop, Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,0,10), Text = "Hop Low", BackgroundColor3 = ACCENT, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1,1,1)})
new("UICorner", {Parent = hopBtn, CornerRadius = UDim.new(0,6)})
hopBtn.MouseButton1Click:Connect(function()
    local success, res = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        local raw = game:HttpGet(url)
        return HttpService:JSONDecode(raw)
    end)
    if success and res and res.data then
        for _,v in pairs(res.data) do
            if v.playing < v.maxPlayers then
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer) end)
                return
            end
        end
    else
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end
end)

-- VISUAL tab (ESP)
local rowESP, _, rightESP = createFunctionRow("Visual", "ESP Players", "Show name, HP and white box for all players")
espSwitch = createSwitch(rightESP, false)
local espEnabled = false
local espData = {} -- player -> {Billboard, Box, Conn}

local function createESPForPlayer(p)
    if not p or p == LocalPlayer then return end
    local char = p.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Billboard
    local bb = Instance.new("BillboardGui")
    bb.Name = "ThoLnoob_ESP"
    bb.Adornee = hrp
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,180,0,60)
    bb.StudsOffset = Vector3.new(0,2.6,0)
    bb.Parent = hrp

    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.Size = UDim2.new(1,0,0.5,0)
    nameLbl.Position = UDim2.new(0,0,0,0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = p.Name
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 14
    nameLbl.TextColor3 = ACCENT2

    local hpLbl = Instance.new("TextLabel", bb)
    hpLbl.Size = UDim2.new(1,0,0.5,0)
    hpLbl.Position = UDim2.new(0,0,0.5,0)
    hpLbl.BackgroundTransparency = 1
    hpLbl.Text = "HP: ?"
    hpLbl.Font = Enum.Font.Gotham
    hpLbl.TextSize = 12
    hpLbl.TextColor3 = Color3.new(1,1,1)

    -- White box
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ThoLnoob_Box"
    box.Adornee = hrp
    box.Size = Vector3.new(4,7,2)
    box.Color3 = Color3.new(1,1,1)
    box.Transparency = 0.25
    box.AlwaysOnTop = true
    box.Parent = hrp

    -- update connection
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not p.Parent or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
            if conn then conn:Disconnect(); conn = nil end
            if bb and bb.Parent then pcall(function() bb:Destroy() end) end
            if box and box.Parent then pcall(function() box:Destroy() end) end
            espData[p] = nil
            return
        end
        local h = p.Character:FindFirstChildOfClass("Humanoid")
        if h then
            hpLbl.Text = "HP: "..tostring(math.floor(h.Health))
        end
    end)

    espData[p] = {Billboard = bb, Box = box, Conn = conn}
end

local function removeAllESP()
    for p,data in pairs(espData) do
        if data.Conn then pcall(function() data.Conn:Disconnect() end) end
        if data.Billboard and data.Billboard.Parent then pcall(function() data.Billboard:Destroy() end) end
        if data.Box and data.Box.Parent then pcall(function() data.Box:Destroy() end) end
    end
    espData = {}
end

espSwitch.OnChanged(function(state)
    espEnabled = state
    if espEnabled then
        for _,p in pairs(Players:GetPlayers()) do
            if p.Character then createESPForPlayer(p) end
        end
        -- handle future players and respawns
        Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function() if espEnabled then createESPForPlayer(p) end end)
        end)
        for _,p in pairs(Players:GetPlayers()) do
            p.CharacterAdded:Connect(function() if espEnabled then createESPForPlayer(p) end end)
        end
    else
        removeAllESP()
    end
end)

-- PLAYER tab rows: Rejoin & Reset
local rowRejoin, _, rightRejoin = createFunctionRow("Player", "Rejoin", "Teleport to same place")
local rejoinBtn = new("TextButton", {Parent = rightRejoin, Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,0,10), Text = "Rejoin", BackgroundColor3 = ACCENT2, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(0,0,0)})
new("UICorner", {Parent = rejoinBtn, CornerRadius = UDim.new(0,6)})
rejoinBtn.MouseButton1Click:Connect(function()
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end)

local rowReset, _, rightReset = createFunctionRow("Player", "Reset Character", "Break joints (reset)")
local resetBtn = new("TextButton", {Parent = rightReset, Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,0,10), Text = "Reset", BackgroundColor3 = ACCENT2, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(0,0,0)})
new("UICorner", {Parent = resetBtn, CornerRadius = UDim.new(0,6)})
resetBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character then pcall(function() LocalPlayer.Character:BreakJoints() end) end
end)

-- TELEPORT tab: Teleport spawn
local rowSpawn, _, rightSpawn = createFunctionRow("Teleport", "Teleport Spawn", "Move to SpawnLocation if exists")
local spawnBtn = new("TextButton", {Parent = rightSpawn, Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,0,10), Text = "Teleport to Spawn", BackgroundColor3 = ACCENT2, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(0,0,0)})
new("UICorner", {Parent = spawnBtn, CornerRadius = UDim.new(0,6)})
spawnBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and workspace:FindFirstChild("SpawnLocation") then
        pcall(function() LocalPlayer.Character:MoveTo(workspace.SpawnLocation.Position) end)
    end
end)

-- ensure default visibility of rows per tab
selectTab("Main")

-- Toggle mainframe via toggle button and key M
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        MainFrame.Position = UDim2.new(0.5,-290,0.2,-210)
        TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0.5,-290,0.5,-210)}):Play()
    end
end)
UserInputService.InputBegan:Connect(function(io, processed)
    if processed then return end
    if io.KeyCode == Enum.KeyCode.M then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Keep UI values synced with character if respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        -- Set to current UI values if exist
        if pmWalk and pmWalk.Set then pmWalk.Set(hum.WalkSpeed) end
        if pmJump and pmJump.Set then pmJump.Set(hum.JumpPower) end
        -- apply immediate
        if pmWalk and pmWalk.Get then hum.WalkSpeed = pmWalk.Get() end
        if pmJump and pmJump.Get then hum.JumpPower = pmJump.Get(); hum.UseJumpPower = true end
    end
end)

-- Safety: cleanup on unload
local function cleanup()
    stopFly()
    removeAllESP()
    if ScreenGui and ScreenGui.Parent then pcall(function() ScreenGui:Destroy() end) end
end

-- in case script is disabled/unloaded
if script.Parent == nil then cleanup() end

-- Done
print("[Tho Lnoob Galaxy Hub] Loaded (full fixed).")
