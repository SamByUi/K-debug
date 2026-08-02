-- ==========================================
-- K-Panel Mobile v2.0 (重构版)
-- 特性：丝滑动画、悬浮球、输入框、防误触
-- ==========================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- 等待角色加载
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
end)

-- ==========================================
-- 1. UI 构建系统
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "K_Panel_Mobile"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = player.PlayerGui

-- 主容器 (用于动画)
local MainContainer = Instance.new("Frame")
MainContainer.Name = "MainContainer"
MainContainer.Size = UDim2.new(0, 300, 0, 420)
MainContainer.Position = UDim2.new(0.5, -150, 0.5, -210)
MainContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainContainer.BackgroundTransparency = 0.05
MainContainer.BorderSizePixel = 0
MainContainer.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = MainContainer

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 80)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainContainer

-- 标题栏 (拖拽区域)
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Header.BorderSizePixel = 0
Header.Parent = MainContainer

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 16)
HeaderCorner.Parent = Header

-- 修复底部圆角
local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 16)
HeaderFix.Position = UDim2.new(0, 0, 1, -16)
HeaderFix.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚙️ K-Debug Panel"
Title.TextColor3 = Color3.fromRGB(220, 220, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- 最小化按钮 (-)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -40, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
MinBtn.TextSize = 22
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0)

-- 滚动区域
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -55)
Scroll.Position = UDim2.new(0, 5, 0, 50)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = MainContainer

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 6)
ListLayout.Parent = Scroll

Scroll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Scroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end)

-- ==========================================
-- 2. 悬浮球系统
-- ==========================================
local Orb = Instance.new("TextButton")
Orb.Name = "K_Orb"
Orb.Size = UDim2.new(0, 50, 0, 50)
Orb.Position = UDim2.new(0, 20, 0.5, -25)
Orb.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Orb.Text = "K"
Orb.TextColor3 = Color3.fromRGB(100, 200, 255)
Orb.TextSize = 24
Orb.Font = Enum.Font.GothamBold
Orb.Visible = false
Orb.Parent = ScreenGui
Instance.new("UICorner", Orb).CornerRadius = UDim.new(1, 0)

local OrbStroke = Instance.new("UIStroke")
OrbStroke.Color = Color3.fromRGB(100, 200, 255)
OrbStroke.Thickness = 2
OrbStroke.Parent = Orb

-- ==========================================
-- 3. 核心逻辑：动画与防误触
-- ==========================================
local isOpen = true
local isDragging = false
local dragInput, dragStart, startPos

-- 丝滑开关动画
local function TogglePanel(state)
	isOpen = state
	local info = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	if state then
		MainContainer.Visible = true
		Orb.Visible = false
		TweenService:Create(MainContainer, info, {
			Size = UDim2.new(0, 300, 0, 420),
			BackgroundTransparency = 0.05,
			Position = UDim2.new(0.5, -150, 0.5, -210) -- 恢复原位或记录的位置
		}):Play()
	else
		TweenService:Create(MainContainer, info, {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1
		}):Play()
		task.wait(0.3)
		MainContainer.Visible = false
		Orb.Visible = true
	end
end

MinBtn.MouseButton1Click:Connect(function()
	TogglePanel(false)
end)

Orb.MouseButton1Click:Connect(function()
	TogglePanel(true)
end)

-- 移动端拖拽逻辑 (仅标题栏响应)
Header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- 防误触：如果点击的是按钮，不启动拖拽
		if input.Target and (input.Target:IsA("TextButton") or input.Target:IsA("TextBox")) then return end
		
		isDragging = true
		dragStart = input.Position
		startPos = MainContainer.Position
	end
end)

Header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and isDragging then
		local delta = input.Position - dragStart
		MainContainer.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = false
	end
end)

-- ==========================================
-- 4. 组件工厂
-- ==========================================

-- 创建按钮
local function CreateButton(text, order, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	btn.TextColor3 = Color3.fromRGB(230, 230, 240)
	btn.Text = text
	btn.TextSize = 15
	btn.Font = Enum.Font.GothamMedium
	btn.LayoutOrder = order
	btn.Parent = Scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	-- 点击反馈
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 50, 65)}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
	end)
	
	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- 创建输入框行
local function CreateInputRow(label, defaultVal, order, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 38)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.LayoutOrder = order
	frame.Parent = Scroll
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.4, 0, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(180, 180, 200)
	lbl.TextSize = 14
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frame
	
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0.5, -10, 0, 26)
	box.Position = UDim2.new(0.45, 0, 0.5, -13)
	box.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	box.TextColor3 = Color3.fromRGB(100, 220, 255)
	box.Text = tostring(defaultVal)
	box.TextSize = 14
	box.Font = Enum.Font.GothamBold
	box.ClearTextOnFocus = false
	box.Parent = frame
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
	
	-- 回车确认
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local num = tonumber(box.Text)
			if num then callback(num) end
		end
	end)
	
	return box
end

-- ==========================================
-- 5. 功能实现 (10+ 功能)
-- ==========================================

-- 1. 速度输入
CreateInputRow("⚡ 速度", 16, 1, function(val)
	humanoid.WalkSpeed = val
end)

-- 2. 跳跃输入
CreateInputRow("🦘 跳跃力", 50, 2, function(val)
	humanoid.JumpPower = val
end)

-- 3. 飞行
local flyConn
CreateButton("🕊️ 切换飞行模式", 3, function()
	if flyConn then 
		flyConn:Disconnect() 
		flyConn = nil 
		rootPart.Velocity = Vector3.new(0,0,0)
		return 
	end
	
	flyConn = RunService.RenderStepped:Connect(function()
		if character and rootPart then
			local cam = workspace.CurrentCamera
			local dir = Vector3.new(0,0,0)
			
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
			
			rootPart.Velocity = dir.Magnitude > 0 and dir.Unit * 80 or Vector3.new(0,0,0)
		end
	end)
end)

-- 4. 无碰撞
CreateButton("👻 切换无碰撞", 4, function()
	for _, v in pairs(character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = not v.CanCollide
		end
	end
end)

-- 5. 传送到准星
CreateButton("📍 传送到准星位置", 5, function()
	if mouse.Hit then
		rootPart.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
	end
end)

-- 6. 夜视/光照
local lightOn = false
CreateButton("🔦 切换夜视仪", 6, function()
	lightOn = not lightOn
	local existing = character:FindFirstChild("K_NightVision")
	if lightOn then
		local light = Instance.new("PointLight")
		light.Name = "K_NightVision"
		light.Brightness = 3
		light.Range = 30
		light.Color = Color3.fromRGB(200, 255, 200)
		light.Parent = rootPart
	else
		if existing then existing:Destroy() end
	end
end)

-- 7. 原地旋转
local spinConn
CreateButton("🔄 切换原地旋转", 7, function()
	if spinConn then spinConn:Disconnect(); spinConn = nil; return end
	spinConn = RunService.RenderStepped:Connect(function(dt)
		if rootPart then
			rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(360 * dt), 0)
		end
	end)
end)

-- 8. 传送到原点
CreateButton("🏠 传送到原点 (0,0,0)", 8, function()
	rootPart.CFrame = CFrame.new(0, 10, 0)
end)

-- 9. 移除背包
CreateButton("🎒 清空背包", 9, function()
	for _, v in pairs(player.Backpack:GetChildren()) do
		v:Destroy()
	end
end)

-- 10. 强制重生
CreateButton("💀 强制重生", 10, function()
	humanoid.Health = 0
end)

-- 11. 重置所有状态
CreateButton("♻️ 重置所有调试状态", 11, function()
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	if spinConn then spinConn:Disconnect(); spinConn = nil end
	
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	rootPart.Velocity = Vector3.new(0,0,0)
	
	for _, v in pairs(character:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.CanCollide = true
		end
	end
	
	local nv = character:FindFirstChild("K_NightVision")
	if nv then nv:Destroy() end
	
	-- 更新输入框显示
	Scroll:FindFirstChildWhichIsA("Frame", true) -- 简单刷新，实际需引用
end)

-- 初始动画
MainContainer.Size = UDim2.new(0, 0, 0, 0)
MainContainer.BackgroundTransparency = 1
task.wait(0.1)
TogglePanel(true)