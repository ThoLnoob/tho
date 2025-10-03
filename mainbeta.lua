-- ThoUltimateHub_Full.lua
-- LocalScript: dán vào StarterGui (hoặc executor). ResetOnSpawn = false cho ScreenGui nếu cần.
-- Features:
-- Floating button (draggable), animated menu, Hop Low Server, FPS Boost,
-- WalkSpeed + Bypass, JumpPower + Bypass, ESP (Name+Box+Distance), Fly mode (max 50),
-- preserves default movement/jump UI (no modal blocking), orientation alignment to camera to reduce skill inversion.

-- === Services & locals ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local placeId = game.PlaceId

-- safety http helper
local function safeHttpGet(url)
	local ok, res = pcall(function() return HttpService:GetAsync(url) end)
	if ok then return res end
	ok, res = pcall(function() return game:HttpGet(url) end)
	if ok then return res end
	return nil
end

-- === Setup GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ThoUltimateHubGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Floating button
local floatBtn = Instance.new("ImageButton")
floatBtn.Name = "FloatBtn"
floatBtn.Parent = screenGui
floatBtn.AnchorPoint = Vector2.new(0,0)
floatBtn.Size = UDim2.new(0,60,0,60)
floatBtn.Position = UDim2.new(0.03,0,0.5,-30)
floatBtn.Image = "rbxassetid://89300403770535"
floatBtn.BackgroundTransparency = 1
floatBtn.ZIndex = 5
local floatCorner = Instance.new("UICorner", floatBtn); floatCorner.CornerRadius = UDim.new(1,0)

-- Menu Frame
local menuFrame = Instance.new("Frame", screenGui)
menuFrame.Name = "MainMenu"
menuFrame.Size = UDim2.new(0,440,0,320)
menuFrame.Position = UDim2.new(0.5,-220,0.45,-160)
menuFrame.Visible = false
menuFrame.BackgroundColor3 = Color3.fromRGB(28,28,28)
menuFrame.BorderSizePixel = 0
menuFrame.ZIndex = 4
local menuCorner = Instance.new("UICorner", menuFrame); menuCorner.CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel", menuFrame)
title.Size = UDim2.new(1,0,0,46)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundColor3 = Color3.fromRGB(40,40,40)
title.BorderSizePixel = 0
title.Text = "Tho Ultimate Hub - Main"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.ZIndex = 6
local titleCorner = Instance.new("UICorner", title); titleCorner.CornerRadius = UDim.new(0,10)

local container = Instance.new("Frame", menuFrame)
container.Size = UDim2.new(1,-20,1,-70)
container.Position = UDim2.new(0,10,0,60)
container.BackgroundTransparency = 1
container.ClipsDescendants = true

-- helpers to create controls
local function createToggle(labelText, xPos, yPos, width)
	width = width or 0.42
	local btn = Instance.new("TextButton", container)
	btn.Size = UDim2.new(width,0,0,36)
	btn.Position = UDim2.new(xPos,0,0,yPos)
	btn.Text = labelText.." (OFF)"
	btn.TextScaled = true
	btn.BackgroundColor3 = Color3.fromRGB(70,130,180)
	btn.TextColor3 = Color3.new(1,1,1)
	local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0,8)
	return btn
end

local function createSlider(labelText, xPos, yPos, default, minv, maxv)
	local lbl = Instance.new("TextLabel", container)
	lbl.Size = UDim2.new(0.42,0,0,20)
	lbl.Position = UDim2.new(xPos,0,0,yPos)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText..": "..tostring(default)
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.TextScaled = true

	local bar = Instance.new("Frame", container)
	bar.Size = UDim2.new(0.42,0,0,12)
	bar.Position = UDim2.new(xPos,0,0,yPos+24)
	bar.BackgroundColor3 = Color3.fromRGB(90,90,90)
	local barCorner = Instance.new("UICorner", bar); barCorner.CornerRadius = UDim.new(0,6)

	local fill = Instance.new("Frame", bar)
	fill.Size = UDim2.new((default-minv)/(maxv-minv),0,1,0)
	fill.BackgroundColor3 = Color3.fromRGB(70,130,180)
	local fillCorner = Instance.new("UICorner", fill); fillCorner.CornerRadius = UDim.new(0,6)

	local dragging = false
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	local callback = nil
	RunService.RenderStepped:Connect(function()
		if dragging then
			local mx = UserInputService:GetMouseLocation().X
			local posX = bar.AbsolutePosition.X
			local sizeX = bar.AbsoluteSize.X
			local rel = math.clamp((mx - posX) / sizeX, 0, 1)
			fill.Size = UDim2.new(rel,0,1,0)
			local value = math.floor(minv + (maxv-minv) * rel)
			lbl.Text = labelText..": "..tostring(value)
			if callback then pcall(callback, value) end
		end
	end)

	return {bar = bar, setCallback = function(fn) callback = fn end, label = lbl}
end

-- Layout positions
local currentY = 0
local function nextY(h) local y = currentY; currentY = currentY + (h or 46); return y end

-- Controls
local hopBtn = createToggle("Hop Low Server", 0, nextY(46), 0.96)
hopBtn.Size = UDim2.new(0.96,0,0,40)
hopBtn.Position = UDim2.new(0,0,0,0) -- top wide
local fpsBtn = createToggle("FPS Boost", 0, nextY(46))
local espBtn = createToggle("ESP Player", 0.5, currentY-46)
currentY = currentY + 46
local speedBypassBtn = createToggle("Speed Bypass", 0, nextY(46))
local jumpBypassBtn = createToggle("Jump Bypass", 0.5, currentY-46)
currentY = currentY + 46

local speedSlider = createSlider("WalkSpeed", 0, nextY(22)+10, 16, 16, 200)
local jumpSlider  = createSlider("JumpPower", 0.5, currentY-12, 50, 50, 200)

-- Fly toggle + label and speed slider for fly (max 50)
local flyBtn = createToggle("Fly (OFF)", 0, nextY(46))
local flySpeedSlider = createSlider("Fly Speed", 0.5, currentY-12, 30, 1, 50)

-- Render order done

-- Internal state
local state = {
	fps = false,
	esp = false,
	speedBypass = false,
	jumpBypass = false,
	walkspeed = 16,
	jumppower = 50,
	fly = false,
	flySpeed = 30, -- default
}

-- tween helper
local function tweenGui(obj, props, t)
	local ti = TweenInfo.new(t or 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, ti, props); tw:Play(); return tw
end

-- open/close animations (scale from small)
local function openMenu()
	menuFrame.Visible = true
	menuFrame.Size = UDim2.new(0,1,0,1)
	tweenGui(menuFrame, {Size = UDim2.new(0,440,0,320)}, 0.22)
end
local function closeMenu()
	tweenGui(menuFrame, {Size = UDim2.new(0,1,0,1)}, 0.18)
	delay(0.18, function()
		if menuFrame then menuFrame.Visible = false; menuFrame.Size = UDim2.new(0,440,0,320) end
	end)
end

-- floating button draggable (move to desired spot; clamp to viewport)
do
	local dragging = false
	local dragStartPos, startBtnPos
	floatBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStartPos = input.Position
			startBtnPos = floatBtn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStartPos
			local newX = startBtnPos.X.Offset + delta.X
			local newY = startBtnPos.Y.Offset + delta.Y
			local camSize = workspace.CurrentCamera.ViewportSize
			newX = math.clamp(newX, 0, camSize.X - floatBtn.AbsoluteSize.X)
			newY = math.clamp(newY, 0, camSize.Y - floatBtn.AbsoluteSize.Y)
			floatBtn.Position = UDim2.new(0, newX, 0, newY)
		end
	end)
end

-- toggle menu on floatBtn click (single click)
floatBtn.MouseButton1Click:Connect(function()
	if menuFrame.Visible then closeMenu() else openMenu() end
end)

-- === Hop Low Server ===
local function hopLowServer()
	local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
	local raw = safeHttpGet(url)
	if not raw then
		warn("Hop: Không thể lấy server list (Http bị chặn).")
		return
	end
	local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok or not data or not data.data then warn("Hop: JSON lỗi") return end
	for _, s in ipairs(data.data) do
		if type(s.playing) == "number" and s.playing < (s.maxPlayers or 999) and tostring(s.id) ~= tostring(game.JobId) then
			local suc, err = pcall(function() TeleportService:TeleportToPlaceInstance(placeId, s.id, localPlayer) end)
			if not suc then warn("Teleport failed:", err) end
			return
		end
	end
	warn("Hop: Không tìm thấy server trống/ít người.")
end

hopBtn.MouseButton1Click:Connect(function()
	hopBtn.Text = "Hop Low Server (Đang...)"
	spawn(function()
		hopLowServer()
		wait(1)
		hopBtn.Text = "Hop Low Server"
	end)
end)

-- === FPS Boost ===
local function applyFPSBoost(on)
	if on then
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				pcall(function() v.Material = Enum.Material.SmoothPlastic end)
			elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
				pcall(function() v.Enabled = false end)
			end
		end
	else
		warn("FPS Boost OFF. Reload map để restore toàn bộ.")
	end
end
fpsBtn.MouseButton1Click:Connect(function()
	state.fps = not state.fps
	fpsBtn.Text = "FPS Boost ("..(state.fps and "ON" or "OFF")..")"
	applyFPSBoost(state.fps)
end)

-- === ESP (Highlight + BillboardGui: name + distance) ===
local espCache = {}
local function createESPFor(p)
	if not p.Character or p == localPlayer then return end
	if espCache[p] then return end
	local char = p.Character
	local hl = Instance.new("Highlight")
	hl.Name = "ThoHighlight"
	hl.Parent = char
	hl.FillTransparency = 1
	hl.OutlineColor = Color3.fromRGB(255,60,60)
	hl.OutlineTransparency = 0
	local head = char:FindFirstChild("Head")
	if head then
		local bill = Instance.new("BillboardGui")
		bill.Name = "ThoNameBill"
		bill.Parent = head
		bill.Adornee = head
		bill.ExtentsOffset = Vector3.new(0,1.2,0)
		bill.Size = UDim2.new(0,140,0,40)
		bill.AlwaysOnTop = true
		local txt = Instance.new("TextLabel", bill)
		txt.Size = UDim2.new(1,0,1,0)
		txt.BackgroundTransparency = 1
		txt.TextScaled = true
		txt.TextColor3 = Color3.new(1,1,1)
		txt.TextStrokeTransparency = 0.6
		espCache[p] = {hl = hl, bill = bill, txt = txt}
	end
end
local function removeESPFor(p)
	local e = espCache[p]
	if not e then return end
	pcall(function() if e.hl and e.hl.Parent then e.hl:Destroy() end end)
	pcall(function() if e.bill and e.bill.Parent then e.bill:Destroy() end end)
	espCache[p] = nil
end

espBtn.MouseButton1Click:Connect(function()
	state.esp = not state.esp
	espBtn.Text = "ESP Player ("..(state.esp and "ON" or "OFF")..")"
	if state.esp then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= localPlayer then createESPFor(p) end
		end
		Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() if state.esp then createESPFor(p) end end) end)
		spawn(function()
			while state.esp do
				for p, data in pairs(espCache) do
					if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
						local dist = (p.Character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
						if data.txt then data.txt.Text = p.Name.." | "..tostring(math.floor(dist)).."m" end
					end
				end
				wait(0.18)
			end
		end)
	else
		for p,_ in pairs(espCache) do removeESPFor(p) end
	end
end)
Players.PlayerRemoving:Connect(function(p) removeESPFor(p) end)

-- === WalkSpeed / JumpPower sliders & bypass toggles ===
local humanoid, rootPart
local function refreshChar()
	if localPlayer.Character then
		humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		rootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart") or localPlayer.Character:FindFirstChild("RootPart")
	end
end
refreshChar()
localPlayer.CharacterAdded:Connect(function() wait(0.3) refreshChar() end)

-- slider callbacks
speedSlider.setCallback(function(v)
	state.walkspeed = v
	if humanoid and not state.speedBypass then pcall(function() humanoid.WalkSpeed = v end) end
end)
jumpSlider.setCallback(function(v)
	state.jumppower = v
	if humanoid and not state.jumpBypass then pcall(function() humanoid.JumpPower = v end) end
end)
flySpeedSlider.setCallback(function(v)
	state.flySpeed = math.clamp(v,1,50)
end)

-- toggle bypass btns
speedBypassBtn.MouseButton1Click:Connect(function()
	state.speedBypass = not state.speedBypass
	speedBypassBtn.Text = "Speed Bypass ("..(state.speedBypass and "ON" or "OFF")..")"
end)
jumpBypassBtn.MouseButton1Click:Connect(function()
	state.jumpBypass = not state.jumpBypass
	jumpBypassBtn.Text = "Jump Bypass ("..(state.jumpBypass and "ON" or "OFF")..")"
end)

-- initial apply
spawn(function()
	wait(0.5)
	refreshChar()
	if humanoid then
		pcall(function() humanoid.WalkSpeed = state.walkspeed; humanoid.JumpPower = state.jumppower end)
	end
end)

-- === Fly implementation ===
-- Approach: do NOT set Humanoid.PlatformStand or change CFrame directly.
-- Use BodyGyro (for yaw alignment to camera) + AssemblyLinearVelocity or VectorForce
-- Use RenderStepped to read inputs and apply velocity relative to camera.
local flyBodyGyro
local flyEnabled = false

local function enableFly(on)
	state.fly = on
	flyBtn.Text = "Fly ("..(state.fly and "ON" or "OFF")..")"
	if on then
		refreshChar()
		if not rootPart then return end
		-- create BodyGyro to keep orientation aligned to camera yaw (small effect)
		if not flyBodyGyro then
			flyBodyGyro = Instance.new("BodyGyro")
			flyBodyGyro.Name = "ThoFlyGyro"
			flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
			flyBodyGyro.P = 10000
			flyBodyGyro.Parent = rootPart
		else
			flyBodyGyro.Parent = rootPart
		end
	else
		if flyBodyGyro and flyBodyGyro.Parent then flyBodyGyro:Destroy(); flyBodyGyro = nil end
		-- On disable: small dampening to avoid sudden velocity
		if rootPart then
			pcall(function() rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z) end)
		end
	end
end

flyBtn.MouseButton1Click:Connect(function() enableFly(not state.fly) end)

-- inputs for flight: use key states
local keyState = {}
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		keyState[input.KeyCode] = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		keyState[input.KeyCode] = false
	end
end)

-- continuous enforcement + movement logic (RunService.RenderStepped for smooth)
RunService.RenderStepped:Connect(function(dt)
	-- refresh refs if needed
	refreshChar()
	-- enforce humanoid speeds if not using bypass
	if humanoid and not state.speedBypass then
		if humanoid.WalkSpeed ~= state.walkspeed then
			pcall(function() humanoid.WalkSpeed = state.walkspeed end)
		end
	end
	if humanoid and not state.jumpBypass then
		if humanoid.JumpPower ~= state.jumppower then
			pcall(function() humanoid.JumpPower = state.jumppower end)
		end
	end

	-- Speed bypass logic (apply velocity in move direction relative to camera)
	if rootPart and state.speedBypass and not state.fly then
		local cam = workspace.CurrentCamera
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		-- get intended move dir by checking keyState (WASD or arrow)
		local mv = Vector3.new(0,0,0)
		if keyState[Enum.KeyCode.W] or keyState[Enum.KeyCode.Up] then mv = mv + Vector3.new(0,0,-1) end
		if keyState[Enum.KeyCode.S] or keyState[Enum.KeyCode.Down] then mv = mv + Vector3.new(0,0,1) end
		if keyState[Enum.KeyCode.A] or keyState[Enum.KeyCode.Left] then mv = mv + Vector3.new(-1,0,0) end
		if keyState[Enum.KeyCode.D] or keyState[Enum.KeyCode.Right] then mv = mv + Vector3.new(1,0,0) end

		if mv.Magnitude > 0 then
			mv = mv.Unit
			-- convert local mv to world using camera basis
			local worldDir = (right * mv.X + look * mv.Z)
			local desired = worldDir.Unit * math.clamp(state.walkspeed + 20, 0, 220)
			local currentVel = rootPart.AssemblyLinearVelocity
			-- preserve Y velocity
			local newVel = Vector3.new(desired.X, currentVel.Y, desired.Z)
			pcall(function() rootPart.AssemblyLinearVelocity = newVel end)
		end
	end

	-- Fly movement handling
	if rootPart and state.fly then
		local cam = workspace.CurrentCamera
		-- Align yaw to camera yaw using BodyGyro (so forward matches camera direction)
		if flyBodyGyro then
			local camY = cam.CFrame - cam.CFrame.p
			local yRot = CFrame.new(Vector3.new(), camY.LookVector)
			-- Keep only yaw: extract lookVector yaw by creating CFrame looking same direction but zero pitch
			local lookVec = cam.CFrame.LookVector
			local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z)
			if flatLook.Magnitude > 0.001 then
				local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + flatLook)
				flyBodyGyro.CFrame = targetCFrame
			end
		end

		-- compute movement vector relative to camera
		local cam = workspace.CurrentCamera
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		local moveVec = Vector3.new(0,0,0)
		if keyState[Enum.KeyCode.W] then moveVec = moveVec + Vector3.new(0,0,-1) end
		if keyState[Enum.KeyCode.S] then moveVec = moveVec + Vector3.new(0,0,1) end
		if keyState[Enum.KeyCode.A] then moveVec = moveVec + Vector3.new(-1,0,0) end
		if keyState[Enum.KeyCode.D] then moveVec = moveVec + Vector3.new(1,0,0) end
		local vertical = 0
		if keyState[Enum.KeyCode.Space] then vertical = vertical + 1 end
		if keyState[Enum.KeyCode.LeftControl] or keyState[Enum.KeyCode.LeftShift] then vertical = vertical - 1 end

		local desiredVel = Vector3.new(0,0,0)
		if moveVec.Magnitude > 0 then
			local worldDir = (right * moveVec.X + look * moveVec.Z)
			desiredVel = worldDir.Unit * state.flySpeed
		end
		desiredVel = Vector3.new(desiredVel.X, vertical * state.flySpeed, desiredVel.Z)
		-- Mix with existing Y to avoid sudden stop when vertical=0 (keep subtle)
		local curr = rootPart.AssemblyLinearVelocity
		local finalVel = Vector3.new(desiredVel.X, desiredVel.Y, desiredVel.Z)
		pcall(function() rootPart.AssemblyLinearVelocity = finalVel end)
	end
end)

-- Jump bypass: apply quick upward velocity on space press (when jumpBypass ON and not flying)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.Space and state.jumpBypass and not state.fly and rootPart then
			local up = math.clamp(state.jumppower / 1.3, 50, 400)
			pcall(function() rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, up, rootPart.AssemblyLinearVelocity.Z) end)
		end
	end
end)

-- Fly speed slider initial apply
flySpeedSlider.setCallback(function(v) state.flySpeed = math.clamp(v,1,50) end)

-- Final: toggles initial wiring
fpsBtn.MouseButton1Click:Connect(function()
	state.fps = not state.fps
	fpsBtn.Text = "FPS Boost ("..(state.fps and "ON" or "OFF")..")"
	applyFPSBoost(state.fps)
end)

-- Ensure menu toggles do not capture input modalities or hide default mobile buttons:
-- We DO NOT set CoreGui or ModalEnabled; GUI is ScreenGui parented to PlayerGui so it won't hide the default movement UI.
-- (Important: some executors / environments may still interfere; this script avoids doing that.)

-- End of script
