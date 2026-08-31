local Cache = {}
local Services = getgenv().Services

-- // Samet's cloneref service cacher | https://github.com/sametexe001
if not Services then
	Services = setmetatable({}, {
		__index = function(_, Name)
			if not Cache[Name] then
				Cache[Name] = cloneref(game:GetService(Name))
			end
			return Cache[Name]
		end,
	})
	getgenv().Services = Services
end

local Run = Services.RunService
local Http = Services.HttpService
local CoreGui = Services.CoreGui
local Players = Services.Players
local Workspace = Services.Workspace
local TweenService = Services.TweenService
local Input = Services.UserInputService

local Hui = CoreGui
if gethui then
	local Ok, Result = pcall(gethui)
	if Ok and Result then
		Hui = cloneref(Result)
	end
end

local ESP = {
	Objects = {},
	Conns = {},
	Font = Font.fromEnum(Enum.Font.SpecialElite),
	Size = 12,
	Height = 6,
	Width = 4,

	Flags = {
		['Enabled'] = true,
		['Names'] = true,
		['Name_Type'] = 'Both',
		['Name_Color'] = { Color = Color3.fromRGB(255, 255, 255) },
		['Boxes'] = true,
		['Box_Type'] = '2D',
		['Box_Dynamic'] = false,
		['Box_Color'] = { Color = Color3.fromRGB(255, 255, 255) },
		['Fill'] = true,
		['Fill_Color'] = { Color = Color3.fromRGB(255, 255, 255) },
		['Fill_Type'] = 'Full',
		['Fill_Half'] = 'Top',
		['Fill_Static'] = false,
		['Fill_Rotation'] = nil,
		['Fill_Transparency'] = 0.5,
		['Fill_Spin'] = true,
		['Fill_Spin_Speed'] = 60,
		['Head'] = true,
		['Head_Color'] = { Color = Color3.fromRGB(255, 255, 255) },
		['Head_Fill'] = true,
		['Head_Fill_Color'] = { Color = Color3.fromRGB(255, 0, 75) },
		['Head_Fill_Type'] = 'Full',
		['Head_Fill_Static'] = false,
		['Head_Fill_Transparency'] = 0.5,
		['Head_Spin'] = true,
		['Head_Spin_Speed'] = 60,
		['Healthbar'] = true,
		['Health_Text'] = true,
		['Health_Text_Dynamic'] = true,
		['Health_Text_Color'] = { Color = Color3.fromRGB(0, 255, 80) },
		['Health_High'] = { Color = Color3.fromRGB(0, 255, 80) },
		['Health_Mid'] = { Color = Color3.fromRGB(255, 230, 0) },
		['Health_Low'] = { Color = Color3.fromRGB(255, 40, 40) },
		['Armorbar'] = true,
		['Armor_Text'] = true,
		['Armor_Color'] = { Color = Color3.fromRGB(0, 85, 255) },
		['Distance'] = true,
		['Distance_Color'] = { Color = Color3.fromRGB(255, 255, 255) },
		['Weapon'] = true,
		['Weapon_Color'] = { Color = Color3.fromRGB(255, 255, 255) },
		['EspFlags'] = true,
		['Flag_Color'] = { Color = Color3.fromRGB(255, 255, 255) },
		['Skeletons'] = false,
		['Skeleton_Color'] = { Color = Color3.fromRGB(255, 255, 255) },
		['Skeleton_Outline'] = true,
		['Skeleton_Outline_Color'] = { Color = Color3.fromRGB(0, 0, 0) },
		['Highlights'] = true,
		['Highlight_Fill'] = { Color = Color3.fromRGB(255, 255, 255) },
		['Highlight_Fill_Transparency'] = 0.5,
		['Highlight_Outline'] = true,
		['Highlight_Outline_Color'] = { Color = Color3.fromRGB(0, 0, 0) },
		['Highlight_Outline_Transparency'] = 0,
		['Highlight_Depth'] = 'AlwaysOnTop',
		['Tracers'] = false,
		['Tracer_Color'] = { Color = Color3.fromRGB(255, 255, 255) },
		['Tracer_Origin'] = 'Bottom',
		['Tracer_Thickness'] = 1,
		['Tracer_Outline'] = true,
		['Tracer_Outline_Color'] = { Color = Color3.fromRGB(0, 0, 0) },
		['Look'] = false,
		['Look_Color'] = { Color = Color3.fromRGB(255, 255, 255) },
		['Look_Outline'] = true,
		['Look_Outline_Color'] = { Color = Color3.fromRGB(0, 0, 0) },
		['Look_Length'] = 3,
		['Look_Thickness'] = 1,
	},
}

local Local = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local Rgb = Color3.fromRGB
local Pos = UDim2.new
local Vec = Vector2.new
local Tween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function SampleGrad(Colors, Stops, T)
	T = math.clamp(T, 0, 1)
	local Last = #Colors
	if Last == 0 then
		return Rgb(255, 255, 255)
	end
	if Last == 1 then
		return Colors[1]
	end

	for I = 1, Last - 1 do
		local T0 = Stops and Stops[I] or ((I - 1) / (Last - 1))
		local T1 = Stops and Stops[I + 1] or (I / (Last - 1))

		if T >= T0 and T <= T1 then
			local A = T1 > T0 and (T - T0) / (T1 - T0) or 0
			return Colors[I]:Lerp(Colors[I + 1], A)
		end
	end

	return Colors[Last]
end

local FillTrans = {
	Full = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.445355, 0.725),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Half = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 1),
	}),
}

local FillRot = {
	Top = 90,
	Bottom = -90,
}

local FlagOrder = {
	'Ragdoll',
	'Falling',
	'Jumping',
	'Climbing',
	'Swimming',
	'Seated',
	'Flying',
	'Running',
}

local FlagHold = 0.1

-- // Finobe's skeleton system | https://github.com/i77lhm
local Bones = {
	R15 = {
		{ 'Head', 'UpperTorso' },
		{ 'UpperTorso', 'LowerTorso' },
		{ 'UpperTorso', 'LeftUpperArm' },
		{ 'UpperTorso', 'RightUpperArm' },
		{ 'LeftUpperArm', 'LeftLowerArm' },
		{ 'RightUpperArm', 'RightLowerArm' },
		{ 'LowerTorso', 'LeftUpperLeg' },
		{ 'LowerTorso', 'RightUpperLeg' },
		{ 'LeftUpperLeg', 'LeftLowerLeg' },
		{ 'RightUpperLeg', 'RightLowerLeg' },
	},
}

local Joints = {
	Neck = { 'Torso', Vector3.new(0, 1, 0) },
	Pelvis = { 'Torso', Vector3.new(0, -1, 0) },
	RightArm = { 'Right Arm', Vector3.new(0, 1, 0) },
	LeftArm = { 'Left Arm', Vector3.new(0, 1, 0) },
	RightLeg = { 'Torso', Vector3.new(0.5, -1, 0) },
	LeftLeg = { 'Torso', Vector3.new(-0.5, -1, 0) },
	RightHand = { 'Right Arm', Vector3.new(0, -1, 0) },
	LeftHand = { 'Left Arm', Vector3.new(0, -1, 0) },
	RightFoot = { 'Right Leg', Vector3.new(0, -1, 0) },
	LeftFoot = { 'Left Leg', Vector3.new(0, -1, 0) },
}

Bones.R6 = {
	{ 'Head', Joints.Neck },
	{ Joints.Neck, Joints.Pelvis },
	{ Joints.Neck, Joints.RightArm },
	{ Joints.RightArm, Joints.RightHand },
	{ Joints.Neck, Joints.LeftArm },
	{ Joints.LeftArm, Joints.LeftHand },
	{ Joints.Pelvis, Joints.RightLeg },
	{ Joints.RightLeg, Joints.RightFoot },
	{ Joints.Pelvis, Joints.LeftLeg },
	{ Joints.LeftLeg, Joints.LeftFoot },
}

local BoneMax = math.max(#Bones.R15, #Bones.R6)


local function Joint(Char, Node)
	if type(Node) == 'string' then
		local Part = Char:FindFirstChild(Node)
		return Part and Part.Position
	end

	local Part = Char:FindFirstChild(Node[1])
	return Part and Part.CFrame * Node[2]
end


local function RegFont(Name, Id, Url)
	if not isfile(Id) then
		writefile(Id, game:HttpGet(Url))
	end

	local Path = Name .. '.font'
	local Data = {
		name = Name,
		faces = {
			{
				name = 'Normal',
				weight = 400,
				style = 'Normal',
				assetId = getcustomasset(Id),
			},
		},
	}

	writefile(Path, Http:JSONEncode(Data))
	return Font.new(
		getcustomasset(Path),
		Enum.FontWeight.Regular,
		Enum.FontStyle.Normal
	)
end

local Ok, Tempesta = pcall(RegFont,
	'PF Tempesta Seven',
	'PFTempestaSeven.ttf',
	'https://raw.githubusercontent.com/viitals/Fonts/main/PF%20Tempesta%20Seven.ttf'
)

if Ok then
	ESP.Font = Tempesta
end

local function Inst(Class, Props)
	local Obj = Instance.new(Class)
	for Key, Val in Props do
		if Key ~= 'Name' then
			Obj[Key] = Val
		end
	end
	Obj.Name = '\0'
	return Obj
end

local function CloneTree(Src)
	local Dst = Src:Clone()
	local Lookup = { [Src] = Dst }
	local From, To = Src:GetDescendants(), Dst:GetDescendants()

	for I, Obj in From do
		Lookup[Obj] = To[I]
	end

	return Dst, Lookup
end

local function Set(Obj, Key, Val)
	if Obj[Key] ~= Val then
		Obj[Key] = Val
	end
end

local function Paint(Frame, Grad, On, Cfg)
	if not On then
		Set(Frame, 'BackgroundTransparency', 1)
		return
	end

	local Col = Cfg.Col
	Set(Frame, 'BackgroundColor3', Col)
	Set(Frame, 'BackgroundTransparency', Cfg.Trans or 0.5)

	if Cfg.Static then
		Set(Grad, 'Enabled', false)
		return
	end

	Set(Grad, 'Enabled', true)

	if Cfg.Last ~= Col then
		Cfg.Last = Col
		Grad.Color = ColorSequence.new(Col)
	end

	if Cfg.Type == 'Half' then
		Set(Grad, 'Transparency', FillTrans.Half)
	else
		Set(Grad, 'Transparency', FillTrans.Full)
	end

	if Cfg.Spin then
		Set(Grad, 'Rotation', (os.clock() * (Cfg.Speed or 60)) % 360)
	else
		Set(Grad, 'Rotation', Cfg.Rot or FillRot.Bottom)
	end
end

local function Line()
	local Obj = Drawing.new('Line')
	Obj.Thickness = 1
	Obj.Transparency = 0
	Obj.Visible = false
	return Obj
end

local function KillLines(List)
	for _, Obj in List do
		Obj:Remove()
	end
end

local function StrokeLine(Obj, From, To, Col, Thick)
	Set(Obj, 'From', From)
	Set(Obj, 'To', To)
	Set(Obj, 'Color', Col)
	Set(Obj, 'Thickness', Thick or 1)
	Set(Obj, 'Visible', true)
end

local function Stroke(Parent)
	return Inst('UIStroke', {
		Parent = Parent,
		Color = Rgb(0, 0, 0),
		Thickness = 1,
		LineJoinMode = Enum.LineJoinMode.Miter,
	})
end

local function Border(Parent)
	return Inst('UIStroke', {
		Parent = Parent,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Rgb(0, 0, 0),
		Thickness = 1,
		LineJoinMode = Enum.LineJoinMode.Miter,
	})
end

function ESP:Get(Key)
	local Bag = self.Bag
	if Bag then
		local Hit = Bag[Key]
		if Hit ~= nil then
			return Hit
		end
	end

	local Src = self.ExtFlags or self.Flags
	local Val = Src[Key]

	if type(Val) == 'table' and Val.Get then
		Val = Val:Get()
	end

	if Bag and Val ~= nil then
		Bag[Key] = Val
	end

	return Val
end

function ESP:Color(Key, Fallback)
	local Bag = self.Bag
	local Id = Key .. '!'
	if Bag then
		local Hit = Bag[Id]
		if Hit then
			return Hit
		end
	end

	local Val = self:Get(Key)
	if type(Val) == 'table' then
		Val = Val.Color or Val[1] or Fallback
	else
		Val = Val or Fallback
	end

	if Bag then
		Bag[Id] = Val
	end

	return Val
end

function ESP:NameStr(Data)
	local Mode = self:Get('Name_Type') or 'Both'

	if Mode == 'Display' then
		return Data.Display
	end

	if Mode == 'Username' then
		return Data.Name
	end

	return Data.Display .. ' (@' .. Data.Name .. ')'
end

function ESP:Wts(World)
	local V, On = Cam:WorldToViewportPoint(World)
	return Vec(V.X, V.Y), On, V.Z
end

local BodyPart = {
	['Head'] = true,
	['Torso'] = true,
	['UpperTorso'] = true,
	['LowerTorso'] = true,
	['LeftArm'] = true,
	['RightArm'] = true,
	['Left Arm'] = true,
	['Right Arm'] = true,
	['LeftLeg'] = true,
	['RightLeg'] = true,
	['Left Leg'] = true,
	['Right Leg'] = true,
	['LeftUpperArm'] = true,
	['RightUpperArm'] = true,
	['LeftLowerArm'] = true,
	['RightLowerArm'] = true,
	['LeftHand'] = true,
	['RightHand'] = true,
	['LeftUpperLeg'] = true,
	['RightUpperLeg'] = true,
	['LeftLowerLeg'] = true,
	['RightLowerLeg'] = true,
	['LeftFoot'] = true,
	['RightFoot'] = true,
}

local BoxVerts = {
	Vector3.new(-1, -1, -1),
	Vector3.new(-1, 1, -1),
	Vector3.new(-1, 1, 1),
	Vector3.new(-1, -1, 1),
	Vector3.new(1, -1, -1),
	Vector3.new(1, 1, -1),
	Vector3.new(1, 1, 1),
	Vector3.new(1, -1, 1),
}

ESP.PartBag = setmetatable({}, { __mode = 'k' })

function ESP:IsRagdolled(Hum, Char)
	if not Hum then
		return false
	end

	if Hum.Sit or Hum.SeatPart then
		return false
	end

	local State = Hum:GetState()
	local HS = Enum.HumanoidStateType
	if State == HS.Seated then
		return false
	end

	Char = Char or Hum.Parent
	local Root = Char and Char:FindFirstChild('HumanoidRootPart')
	if (Char and Char:FindFirstChild('SeatWeld')) or (Root and Root:FindFirstChild('SeatWeld')) then
		return false
	end

	if Root then
		for _, Joint in Root:GetChildren() do
			if Joint:IsA('Weld') or Joint:IsA('WeldConstraint') or Joint:IsA('Motor6D') then
				local Other = (Joint.Part0 == Root and Joint.Part1) or (Joint.Part1 == Root and Joint.Part0)
				if Other and (Other:IsA('Seat') or Other:IsA('VehicleSeat')) then
					return false
				end
			end
		end
	end

	return State == HS.Ragdoll or State == HS.Physics or State == HS.GettingUp or State == HS.FallingDown
end

function ESP:BodyParts(Char)
	local Children = Char:GetChildren()
	local Count = #Children
	local Hit = self.PartBag[Char]
	if Hit and Hit.N == Count then
		return Hit.Parts
	end

	local Parts = {}
	for I = 1, Count do
		local Part = Children[I]
		if Part:IsA('BasePart') and BodyPart[Part.Name] then
			Parts[#Parts + 1] = Part
		end
	end

	self.PartBag[Char] = { N = Count, Parts = Parts }
	return Parts
end

function ESP:StableBounds(Root)
	local Center = Root.Position - Vector3.new(0, 0.25, 0)
	local Screen, On, Depth = self:Wts(Center)
	if not On or not Depth or Depth <= 0.15 then
		return
	end

	local Px = self.Px
	if not Px then
		Px = Cam.ViewportSize.Y / (2 * math.tan(math.rad(Cam.FieldOfView) * 0.5))
	end

	local H = math.max(math.floor((self.Height / Depth) * Px + 0.5), 4)
	local W = math.max(math.floor(H * (self.Width / self.Height) + 0.5), 4)

	return Vec(math.floor(Screen.X - W * 0.5 + 0.5), math.floor(Screen.Y - H * 0.5 + 0.5)), Vec(W, H)
end

function ESP:DynamicBounds(Char)
	local Parts = self:BodyParts(Char)
	if not Parts[1] then
		return
	end

	local Min3, Max3
	for I = 1, #Parts do
		local Part = Parts[I]
		local CF, Size = Part.CFrame, Part.Size
		local A = (CF - Size * 0.5).Position
		local B = (CF + Size * 0.5).Position
		if Min3 then
			Min3 = Vector3.new(math.min(Min3.X, A.X, B.X), math.min(Min3.Y, A.Y, B.Y), math.min(Min3.Z, A.Z, B.Z))
			Max3 = Vector3.new(math.max(Max3.X, A.X, B.X), math.max(Max3.Y, A.Y, B.Y), math.max(Max3.Z, A.Z, B.Z))
		else
			Min3 = Vector3.new(math.min(A.X, B.X), math.min(A.Y, B.Y), math.min(A.Z, B.Z))
			Max3 = Vector3.new(math.max(A.X, B.X), math.max(A.Y, B.Y), math.max(A.Z, B.Z))
		end
	end

	local Center = (Min3 + Max3) * 0.5
	local Half = (Max3 - Min3) * 0.5
	local MinX, MinY = math.huge, math.huge
	local MaxX, MaxY = -math.huge, -math.huge
	local Hits = 0

	for I = 1, 8 do
		local Scr, _, Dep = self:Wts(Center + Half * BoxVerts[I])
		if Dep and Dep > 0.15 then
			Hits += 1
			MinX = math.min(MinX, Scr.X)
			MinY = math.min(MinY, Scr.Y)
			MaxX = math.max(MaxX, Scr.X)
			MaxY = math.max(MaxY, Scr.Y)
		end
	end

	if Hits < 2 then
		return
	end

	local Vp = self.Vp or Cam.ViewportSize
	local W = math.max(math.floor(MaxX - MinX + 0.5), 4)
	local H = math.max(math.floor(MaxY - MinY + 0.5), 4)
	if W > Vp.X or H > Vp.Y then
		return
	end

	return Vec(math.floor(MinX + 0.5), math.floor(MinY + 0.5)), Vec(W, H)
end

function ESP:Bounds(Char, Root, Ragdoll)
	if Ragdoll == nil then
		local Hum = Char:FindFirstChildOfClass('Humanoid')
		Ragdoll = self:IsRagdolled(Hum, Char)
	end

	if self:Get('Box_Dynamic') or Ragdoll then
		local Pos, Size = self:DynamicBounds(Char)
		if Pos then
			return Pos, Size
		end
	end

	return self:StableBounds(Root)
end

function ESP:Tool(Char)
	for _, Child in Char:GetChildren() do
		if Child:IsA('Tool') then
			local Name = Child.Name

			if Name:sub(1, 1) == '[' and Name:sub(-1) == ']' then
				return Name
			end

			return '[' .. Name .. ']'
		end
	end

	return ''
end

function ESP:Data(Plr)
	if Plr == Local then
		return
	end

	local Char = Plr.Character
	local Hum = Char and Char:FindFirstChildOfClass('Humanoid')
	local Root = Char and Char:FindFirstChild('HumanoidRootPart')

	if not Char or not Hum or Hum.Health <= 0 then
		return
	end

	if not Root then
		Root = Char:FindFirstChild('UpperTorso')
			or Char:FindFirstChild('Torso')
			or Char:FindFirstChild('LowerTorso')
			or Char:FindFirstChild('Head')
	end

	if not Root then
		return
	end

	local State = Hum:GetState()
	local HS = Enum.HumanoidStateType
	local Ragdoll = self:IsRagdolled(Hum, Char)
	local BoxPos, BoxSize = self:Bounds(Char, Root, Ragdoll)
	if not BoxPos then
		return
	end

	local Dist = math.floor((Root.Position - Cam.CFrame.Position).Magnitude + 0.5)
	local HPct = Hum.MaxHealth > 0 and Hum.Health / Hum.MaxHealth or 0
	local Armor = Hum:GetAttribute('Armor') or Char:GetAttribute('Armor') or 0
	local MaxArmor = Hum:GetAttribute('MaxArmor') or Char:GetAttribute('MaxArmor') or 100
	local APct = MaxArmor > 0 and math.clamp(Armor / MaxArmor, 0, 1) or 0
	local Tool = self:Get('Weapon') and self:Tool(Char) or ''
	local Air = State == HS.Freefall or State == HS.FallingDown or State == HS.Jumping
	local Climbing = State == HS.Climbing
	local Swimming = State == HS.Swimming
	local Seated = State == HS.Seated or Hum.Sit or Hum.SeatPart ~= nil
	local Flying = State == HS.Flying
	local Moving = Hum.MoveDirection.Magnitude > 0.05

	return {
		Pos = BoxPos,
		Size = BoxSize,
		Char = Char,
		Head = Char:FindFirstChild('Head'),
		Name = Plr.Name,
		Display = Plr.DisplayName,
		Dist = Dist,
		Health = HPct,
		HealthVal = math.floor(Hum.Health + 0.5),
		Armor = APct,
		ArmorVal = math.floor(Armor + 0.5),
		Weapon = Tool,
		Flags = {
			Ragdoll = Ragdoll,
			Falling = State == HS.Freefall or State == HS.FallingDown,
			Jumping = State == HS.Jumping,
			Climbing = Climbing,
			Swimming = Swimming,
			Seated = Seated,
			Flying = Flying,
			Running = Moving and not (Air or Climbing or Swimming or Seated or Ragdoll or Flying),
		},
	}
end

function ESP:Build()
	local Holder = Inst('Frame', {
		Name = 'Holder',
		BackgroundColor3 = Rgb(255, 255, 255),
		BackgroundTransparency = 0.6,
		BorderColor3 = Rgb(0, 0, 0),
		BorderSizePixel = 0,
		Size = Pos(0, 250, 0, 250),
	})

	local Left = Inst('Frame', {
		Name = 'Left',
		Parent = Holder,
		AnchorPoint = Vec(1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Position = Pos(0, -2, 0, 0),
		Size = Pos(0, 1, 1, 0),
	})

	Inst('UIListLayout', {
		Parent = Left,
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		VerticalFlex = Enum.UIFlexAlignment.Fill,
	})

	Inst('UIPadding', {
		Parent = Left,
		PaddingBottom = UDim.new(0, 1),
		PaddingTop = UDim.new(0, 1),
	})

	local BarHolder = Inst('Frame', {
		Name = 'BarHolder',
		Parent = Left,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Size = Pos(0, 5, 1, 0),
	})

	Inst('UIListLayout', {
		Parent = BarHolder,
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, -10),
	})

	local HealthBack = Inst('Frame', {
		Name = 'HealthBack',
		Parent = BarHolder,
		BackgroundColor3 = Rgb(0, 0, 0),
		BorderColor3 = Rgb(0, 0, 0),
		BorderSizePixel = 0,
		Size = Pos(0, 4, 1, 0),
	})

	local HealthBar = Inst('Frame', {
		Name = 'HealthBar',
		Parent = HealthBack,
		BackgroundColor3 = Rgb(255, 255, 255),
		BorderColor3 = Rgb(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Position = Pos(0, 1, 0.25, 0),
		Size = Pos(1, -2, 0.75, 0),
	})
	Border(HealthBar)

	Inst('UIGradient', {
		Parent = HealthBar,
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Rgb(0, 255, 80)),
			ColorSequenceKeypoint.new(0.4, Rgb(255, 230, 0)),
			ColorSequenceKeypoint.new(0.7, Rgb(255, 120, 0)),
			ColorSequenceKeypoint.new(1, Rgb(255, 40, 40)),
		}),
	})

	local HealthText = Inst('TextLabel', {
		Name = 'HealthText',
		Parent = HealthBar,
		AnchorPoint = Vec(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = Pos(0.5, 0, 0, 0),
		Size = Pos(0, 0, 0, 12),
		FontFace = ESP.Font,
		Text = '',
		TextColor3 = Rgb(0, 255, 80),
		TextSize = 12,
	})
	Stroke(HealthText)

	local Up = Inst('Frame', {
		Name = 'Up',
		Parent = Holder,
		AnchorPoint = Vec(0, 1),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = Pos(0, 0, 0, -2),
		Size = Pos(1, 0, 0, 1),
	})

	Inst('UIListLayout', {
		Parent = Up,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local TitleHolder = Inst('Frame', {
		Name = 'TitleHolder',
		Parent = Up,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Position = Pos(0, 1, 0, -5),
		Size = Pos(1, -2, 0, 0),
	})

	local NameText = Inst('TextLabel', {
		Name = 'NameText',
		Parent = TitleHolder,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = Pos(1, 0, 1, 0),
		FontFace = ESP.Font,
		Text = '',
		TextColor3 = Rgb(255, 255, 255),
		TextSize = 12,
	})
	Stroke(NameText)

	local Down = Inst('Frame', {
		Name = 'Down',
		Parent = Holder,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = Pos(0, -1, 1, 1),
		Size = Pos(1, 2, 0, 1),
	})

	local TitleHolder2 = Inst('Frame', {
		Name = 'TitleHolder',
		Parent = Down,
		BackgroundTransparency = 1,
		Position = Pos(0, 2, 0, 0),
		Size = Pos(1, -4, 0, 25),
	})

	Inst('UIListLayout', {
		Parent = TitleHolder2,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
	})

	Inst('UIPadding', {
		Parent = TitleHolder2,
		PaddingTop = UDim.new(0, 3),
	})

	local DistanceText = Inst('TextLabel', {
		Name = 'DistanceText',
		Parent = TitleHolder2,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = Pos(1, 0, 0, 10),
		FontFace = ESP.Font,
		Text = '',
		TextColor3 = Rgb(255, 255, 255),
		TextSize = 12,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	Stroke(DistanceText)

	Inst('UIPadding', {
		Parent = DistanceText,
		PaddingBottom = UDim.new(0, 11),
	})

	local WeaponText = Inst('TextLabel', {
		Name = 'WeaponText',
		Parent = TitleHolder2,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Position = Pos(0, 0, 0, -1),
		Size = Pos(1, 0, 0, 10),
		FontFace = ESP.Font,
		Text = '',
		TextColor3 = Rgb(255, 255, 255),
		TextSize = 12,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	Stroke(WeaponText)

	Inst('UIPadding', {
		Parent = WeaponText,
		PaddingBottom = UDim.new(0, 11),
	})

	local BarHolder2 = Inst('Frame', {
		Name = 'BarHolder',
		Parent = TitleHolder2,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = Pos(1, 0, 0, 0),
	})

	local ArmorBack = Inst('Frame', {
		Name = 'ArmorBack',
		Parent = BarHolder2,
		BackgroundColor3 = Rgb(0, 0, 0),
		BorderColor3 = Rgb(0, 0, 0),
		BorderSizePixel = 0,
		Size = Pos(1, 0, 0, 2),
	})
	Border(ArmorBack)

	local ArmorBar = Inst('Frame', {
		Name = 'ArmorBar',
		Parent = ArmorBack,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Rgb(255, 255, 255),
		BorderColor3 = Rgb(0, 0, 0),
		BorderSizePixel = 0,
		Size = Pos(0.5, 0, 1, 0),
	})
	Border(ArmorBar)

	Inst('UIGradient', {
		Parent = ArmorBar,
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Rgb(0, 85, 255)),
			ColorSequenceKeypoint.new(1, Rgb(0, 85, 255)),
		}),
	})

	local ArmorText = Inst('TextLabel', {
		Name = 'ArmorText',
		Parent = ArmorBar,
		AnchorPoint = Vec(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = Pos(1, 0, 0, 1),
		Size = Pos(0, 0, 0, 12),
		FontFace = ESP.Font,
		Text = '',
		TextColor3 = Rgb(0, 85, 255),
		TextSize = 12,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	Stroke(ArmorText)

	Inst('UIPadding', {
		Parent = BarHolder2,
		PaddingBottom = UDim.new(0, -2),
	})

	local Inline = Inst('UIStroke', {
		Name = 'BoundInline',
		Parent = Holder,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderOffset = UDim.new(0, -1),
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Color = Rgb(212, 213, 255),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	Inst('UIGradient', {
		Parent = Inline,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Rgb(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Rgb(199, 199, 199)),
		}),
	})

	local Outline = Inst('UIStroke', {
		Name = 'BoundOutline',
		Parent = Holder,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Color = Rgb(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter,
		Thickness = 3,
		ZIndex = 0,
	})

	local Right = Inst('Frame', {
		Name = 'Right',
		Parent = Holder,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Position = Pos(1, 2, 0, 0),
		Size = Pos(0, 1, 1, 0),
	})

	Inst('UIPadding', {
		Parent = Right,
		PaddingTop = UDim.new(0, -3),
	})

	local FlagsHolder = Inst('Frame', {
		Name = 'FlagsHolder',
		Parent = Right,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Position = Pos(0, 2, 0, 1),
		Size = Pos(0, 0, 1, -2),
	})

	Inst('UIListLayout', {
		Parent = FlagsHolder,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local FlagText = Inst('TextLabel', {
		Name = 'FlagText',
		Parent = FlagsHolder,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Size = Pos(1, 0, 0, 0),
		FontFace = ESP.Font,
		Text = '',
		TextColor3 = Rgb(255, 255, 255),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	Stroke(FlagText)

	local HolderGrad = Inst('UIGradient', {
		Parent = Holder,
		Rotation = -90,
		Color = ColorSequence.new(Rgb(212, 213, 255)),
		Transparency = FillTrans.Full,
	})

	local Corners = Inst('Frame', {
		Name = 'Corners',
		Parent = Holder,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = Pos(1, 0, 1, 0),
		Visible = false,
		ZIndex = 3,
	})

	local Layout = {
		{ Pos(0, -1, 0, -1), Pos(0.3, 0, 0, 1), Vec(0, 0), 0 },
		{ Pos(0, -1, 0, 0), Pos(0, 1, 0.3, 0), Vec(0, 0), 180 },
		{ Pos(1, 1, 0, -1), Pos(0.3, 0, 0, 1), Vec(1, 0), 0 },
		{ Pos(1, 1, 0, 0), Pos(0, 1, 0.3, 0), Vec(1, 0), 180 },
		{ Pos(0, -1, 1, 1), Pos(0.3, 0, 0, 1), Vec(0, 1), 0 },
		{ Pos(0, -1, 1, 1), Pos(0, 1, 0.3, 0), Vec(0, 1), -180 },
		{ Pos(1, 1, 1, 1), Pos(0.3, 0, 0, 1), Vec(1, 1), 0 },
		{ Pos(1, 1, 1, 1), Pos(0, 1, 0.3, 0), Vec(1, 1), -180 },
	}

	for I, Data in Layout do
		local Line = Inst('Frame', {
			Name = 'Corner' .. I,
			Parent = Corners,
			BorderSizePixel = 0,
			BackgroundColor3 = Rgb(255, 255, 255),
			Position = Data[1],
			Size = Data[2],
			AnchorPoint = Data[3],
			Rotation = Data[4],
		})
		Stroke(Line)
	end

	return Holder, {
		Inline = Inline,
		Outline = Outline,
		Corners = Corners,
		Holder = Holder,
		HolderGrad = HolderGrad,
		NameText = NameText,
		DistanceText = DistanceText,
		WeaponText = WeaponText,
		FlagsHolder = FlagsHolder,
		FlagText = FlagText,
		HealthBack = HealthBack,
		HealthBar = HealthBar,
		HealthText = HealthText,
		ArmorBack = ArmorBack,
		ArmorBar = ArmorBar,
		ArmorText = ArmorText,
	}
end

local Base = {}
Base.__index = Base

function Base:New()
	return setmetatable({ Items = {} }, self)
end

function Base:Kill()
	for _, Item in self.Items do
		if typeof(Item) == 'Instance' then
			Item:Destroy()
		end
	end
	table.clear(self.Items)
end

ESP.Box = setmetatable({}, { __index = Base })
ESP.Box.__index = ESP.Box

function ESP.Box:New(Refs)
	local Self = Base.New(self)
	Self.Inline = Refs.Inline
	Self.Outline = Refs.Outline
	Self.Corners = Refs.Corners
	Self.Lines = Refs.Corners:GetChildren()
	return Self
end

function ESP.Box:Draw(Esp, On)
	local Col = Esp:Color('Box_Color', Rgb(255, 255, 255))
	local Is2D = (Esp:Get('Box_Type') or '2D') == '2D'

	Set(self.Inline, 'Enabled', On and Is2D)
	Set(self.Outline, 'Enabled', On and Is2D)
	Set(self.Corners, 'Visible', On and not Is2D)

	if not On then
		return
	end

	Set(self.Inline, 'Color', Col)
	for _, Line in self.Lines do
		if Line:IsA('Frame') then
			Set(Line, 'BackgroundColor3', Col)
		end
	end
end

ESP.Fill = setmetatable({}, { __index = Base })
ESP.Fill.__index = ESP.Fill

function ESP.Fill:New(Refs)
	local Self = Base.New(self)
	Self.Frame = Refs.Holder
	Self.Grad = Refs.HolderGrad
	Self.Cfg = { Last = nil }
	return Self
end

function ESP.Fill:Draw(Esp, On)
	local Type = Esp:Get('Fill_Type') or 'Full'
	local Rot = Esp:Get('Fill_Rotation')
	if not Rot and Type ~= 'Full' then
		Rot = FillRot[Esp:Get('Fill_Half') or 'Top'] or FillRot.Top
	end

	self.Cfg.Col = Esp:Color('Fill_Color', Rgb(255, 255, 255))
	self.Cfg.Trans = Esp:Get('Fill_Transparency') or 0.5
	self.Cfg.Static = Esp:Get('Fill_Static')
	self.Cfg.Type = Type
	self.Cfg.Rot = Rot or FillRot.Bottom
	self.Cfg.Spin = Esp:Get('Fill_Spin')
	self.Cfg.Speed = Esp:Get('Fill_Spin_Speed') or 60
	Paint(self.Frame, self.Grad, On, self.Cfg)
end

ESP.Circ = setmetatable({}, { __index = Base })
ESP.Circ.__index = ESP.Circ

function ESP.Circ:New(Gui)
	local Self = Base.New(self)

	local Root = Inst('Frame', {
		Parent = Gui,
		AnchorPoint = Vec(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = Pos(0, 50, 0, 50),
		Visible = false,
	})

	Inst('UICorner', {
		Parent = Root,
		CornerRadius = UDim.new(1, 0),
	})

	Self.Stroke = Inst('UIStroke', {
		Parent = Root,
		Color = Rgb(255, 255, 255),
		Thickness = 1.1,
	})

	Self.Inner = Inst('Frame', {
		Parent = Root,
		BackgroundColor3 = Rgb(255, 255, 255),
		BorderSizePixel = 0,
		Size = Pos(1, 0, 1, 0),
	})

	Inst('UICorner', {
		Parent = Self.Inner,
		CornerRadius = UDim.new(1, 0),
	})

	Self.Grad = Inst('UIGradient', {
		Parent = Self.Inner,
		Rotation = -90,
		Color = ColorSequence.new(Rgb(255, 0, 75)),
		Transparency = FillTrans.Full,
	})

	Self.Root = Root
	Self.Cfg = { Last = nil }
	table.insert(Self.Items, Root)
	return Self
end

function ESP.Circ:Hide()
	Set(self.Root, 'Visible', false)
end

function ESP.Circ:Draw(On, Scr, Rad, Cfg)
	if not On or not Scr or not Rad then
		return self:Hide()
	end

	local Dia = math.max(math.floor(Rad * 2 + 0.5), 2)
	Set(self.Root, 'Visible', true)
	Set(self.Root, 'Position', UDim2.fromOffset(Scr.X, Scr.Y))
	Set(self.Root, 'Size', UDim2.fromOffset(Dia, Dia))

	if Cfg.Stroke then
		Set(self.Stroke, 'Enabled', true)
		Set(self.Stroke, 'Color', Cfg.Stroke)
	else
		Set(self.Stroke, 'Enabled', false)
	end

	Paint(self.Inner, self.Grad, Cfg.Fill, Cfg)
end

ESP.Head = setmetatable({}, { __index = Base })
ESP.Head.__index = ESP.Head

function ESP.Head:New(Gui)
	local Self = Base.New(self)
	Self.Gui = Gui
	return Self
end

function ESP.Head:Hide()
	if self.Circ then
		self.Circ:Hide()
	end
end

function ESP.Head:Kill()
	if self.Circ then
		self.Circ:Kill()
	end
end

function ESP.Head:Draw(Esp, On, Data)
	local Part = Data.Head
	if not On or not Part then
		return self:Hide()
	end

	if not self.Circ then
		self.Circ = ESP.Circ:New(self.Gui)
	end

	local Scr, Ok, Z = ESP:Wts(Part.Position)
	if not Ok or Z <= 0 then
		return self:Hide()
	end

	local Edge = ESP:Wts(Part.Position + Cam.CFrame.RightVector * (Part.Size.X * 0.5))
	local Rad = math.max(math.abs(Edge.X - Scr.X), 2)

	self.Circ.Cfg.Col = Esp:Color('Head_Fill_Color', Rgb(255, 0, 75))
	self.Circ.Cfg.Trans = Esp:Get('Head_Fill_Transparency') or 0.5
	self.Circ.Cfg.Static = Esp:Get('Head_Fill_Static')
	self.Circ.Cfg.Type = Esp:Get('Head_Fill_Type') or 'Full'
	self.Circ.Cfg.Rot = FillRot.Bottom
	self.Circ.Cfg.Spin = Esp:Get('Head_Spin')
	self.Circ.Cfg.Speed = Esp:Get('Head_Spin_Speed') or 60
	self.Circ.Cfg.Fill = Esp:Get('Head_Fill')
	self.Circ.Cfg.Stroke = Esp:Color('Head_Color', Rgb(255, 255, 255))
	self.Circ:Draw(true, Scr, Rad, self.Circ.Cfg)
end

ESP.Name = setmetatable({}, { __index = Base })
ESP.Name.__index = ESP.Name

function ESP.Name:New(Refs)
	local Self = Base.New(self)
	Self.Text = Refs.NameText
	return Self
end

function ESP.Name:Draw(Esp, On, Data)
	Set(self.Text, 'Visible', On)
	if On then
		Set(self.Text, 'TextColor3', Esp:Color('Name_Color', Rgb(255, 255, 255)))
		Set(self.Text, 'Text', Esp:NameStr(Data))
	end
end

ESP.Dist = setmetatable({}, { __index = Base })
ESP.Dist.__index = ESP.Dist

function ESP.Dist:New(Refs)
	local Self = Base.New(self)
	Self.Text = Refs.DistanceText
	Self.Weapon = Refs.WeaponText
	return Self
end

function ESP.Dist:Draw(Esp, On, Data)
	Set(self.Text, 'Visible', On)
	if On then
		Set(self.Text, 'TextColor3', Esp:Color('Distance_Color', Rgb(255, 255, 255)))
		Set(self.Text, 'Text', tostring(Data.Dist) .. ' st')
	end

	local WeaponOn = Esp:Get('Weapon') and Data.Weapon ~= ''
	Set(self.Weapon, 'Visible', WeaponOn)
	if WeaponOn then
		Set(self.Weapon, 'TextColor3', Esp:Color('Weapon_Color', Rgb(255, 255, 255)))
		Set(self.Weapon, 'Text', Data.Weapon)
	end
end

ESP.Bar = setmetatable({}, { __index = Base })
ESP.Bar.__index = ESP.Bar

function ESP.Bar:New(Back, Fill, Text, Vert)
	local Self = Base.New(self)
	Self.Back = Back
	Self.Fill = Fill
	Self.Text = Text
	Self.Grad = Fill:FindFirstChildOfClass('UIGradient')
	Self.Vert = Vert
	Self.Last = nil
	Self.Tween = nil
	return Self
end

function ESP.Bar:SetGrad(Colors, Stops, From, To)
	if not self.Grad then
		return
	end

	From = math.clamp(From or 0, 0, 1)
	To = math.clamp(To or 1, 0, 1)
	if To <= From then
		To = math.min(From + 0.001, 1)
	end

	local QFrom = math.floor(From * 40 + 0.5)
	local QTo = math.floor(To * 40 + 0.5)
	local Key = tostring(QFrom) .. ':' .. tostring(QTo)
	for _, Col in Colors do
		Key = Key .. tostring(Col)
	end

	if self.GradKey == Key then
		return
	end

	self.GradKey = Key

	local Span = To - From
	local Points = {
		ColorSequenceKeypoint.new(0, SampleGrad(Colors, Stops, From)),
	}

	for I = 1, #Colors do
		local T = Stops and Stops[I] or ((I - 1) / math.max(#Colors - 1, 1))
		if T > From + 0.001 and T < To - 0.001 then
			Points[#Points + 1] = ColorSequenceKeypoint.new((T - From) / Span, Colors[I])
		end
	end

	Points[#Points + 1] = ColorSequenceKeypoint.new(1, SampleGrad(Colors, Stops, To))
	self.Grad.Color = ColorSequence.new(Points)
end

function ESP.Bar:Draw(On, Pct, Val, Cfg)
	Set(self.Back, 'Visible', On)
	if not On then return end

	Pct = math.clamp(Pct or 0, 0, 1)
	if self.Vert then
		self:SetGrad(Cfg.Colors, Cfg.Stops, 1 - Pct, 1)
	else
		self:SetGrad(Cfg.Colors, Cfg.Stops, 0, 1)
	end

	local Size, Position
	if self.Vert then
		Size = Pos(1, -2, Pct, 0)
		Position = Pos(0, 1, 1 - Pct, 0)
	else
		Size = Pos(Pct, 0, 1, 0)
	end

	if self.Last == nil then
		self.Fill.Size = Size
		if Position then
			self.Fill.Position = Position
		end
	elseif math.abs(self.Last - Pct) >= 0.01 then
		if self.Tween then
			self.Tween:Cancel()
		end

		local Goals = { Size = Size }
		if Position then
			Goals.Position = Position
		end

		self.Tween = TweenService:Create(self.Fill, Tween, Goals)
		self.Tween:Play()
	end

	self.Last = Pct

	Val = Val or math.floor(Pct * 100 + 0.5)
	if self.Text then
		Set(self.Text, 'Visible', Cfg.Text and Val ~= 0 and Val ~= 100)

		local Col = Cfg.TextCol
		if Cfg.Dynamic and Cfg.Colors and Cfg.Stops then
			Col = SampleGrad(Cfg.Colors, Cfg.Stops, 1 - Pct)
		end

		Set(self.Text, 'TextColor3', Col)
		Set(self.Text, 'Text', tostring(Val))
	end
end

ESP.Flag = setmetatable({}, { __index = Base })
ESP.Flag.__index = ESP.Flag

function ESP.Flag:New(Refs)
	local Self = Base.New(self)
	Self.Holder = Refs.FlagsHolder
	Self.Temp = Refs.FlagText
	Self.Temp.Visible = false
	Self.Labels = {}
	Self.Hold = {}
	return Self
end

function ESP.Flag:Label(Name, Order, Col)
	local Lbl = self.Labels[Name]
	if not Lbl then
		Lbl = self.Temp:Clone()
		Lbl.Name = '\0'
		Lbl.Parent = self.Holder
		self.Labels[Name] = Lbl
		table.insert(self.Items, Lbl)
	end
	Set(Lbl, 'LayoutOrder', Order)
	Set(Lbl, 'Text', Name)
	Set(Lbl, 'TextColor3', Col)
	Set(Lbl, 'Visible', true)
	return Lbl
end

function ESP.Flag:Draw(Esp, On, Data)
	Set(self.Holder, 'Visible', On)
	if not On or not Data.Flags then return end

	local Col = Esp:Color('Flag_Color', Rgb(255, 255, 255))
	local Now = os.clock()
	local Order = 0

	for _, Name in FlagOrder do
		local Active = Data.Flags[Name]
		if Active then
			self.Hold[Name] = Now
		end

		local Show = Active or (self.Hold[Name] and Now - self.Hold[Name] < FlagHold)
		local Lbl = self.Labels[Name]

		if Show then
			Order += 1
			self:Label(Name, Order, Col)
		elseif Lbl then
			Set(Lbl, 'Visible', false)
		end
	end
end

-- // finobe's r15 skeleton mapping system | https://github.com/i77lhm
ESP.Skel = setmetatable({}, { __index = Base })
ESP.Skel.__index = ESP.Skel

function ESP.Skel:New()
	return Base.New(self)
end

function ESP.Skel:Boot()
	if not self.Lines then
		self.Lines = table.create(BoneMax)
	end

	if not self.Back then
		self.Back = table.create(BoneMax)
	end

	for I = 1, BoneMax do
		if not self.Back[I] then
			local Back = Line()
			Back.Thickness = 3
			Back.ZIndex = 1
			self.Back[I] = Back
		end

		if not self.Lines[I] then
			local LineObj = Line()
			LineObj.Thickness = 1
			LineObj.ZIndex = 2
			self.Lines[I] = LineObj
		end
	end
end

function ESP.Skel:Hide()
	if not self.Lines then
		return
	end

	for I = 1, BoneMax do
		Set(self.Lines[I], 'Visible', false)
		if self.Back[I] then
			Set(self.Back[I], 'Visible', false)
		end
	end
end

function ESP.Skel:Draw(Esp, On, Data)
	if not On then
		return self:Hide()
	end

	self:Boot()

	local Char = Data.Char
	local Rig = Char:FindFirstChild('UpperTorso') and Bones.R15 or Bones.R6
	local Col = Esp:Color('Skeleton_Color', Rgb(255, 255, 255))
	local OutlineCol = Esp:Color('Skeleton_Outline_Color', Rgb(0, 0, 0))

	for I = 1, BoneMax do
		local LineObj = self.Lines[I]
		local Back = self.Back[I]
		local Bone = Rig[I]
		local From = Bone and Joint(Char, Bone[1])
		local To = Bone and Joint(Char, Bone[2])

		if not From or not To then
			Set(LineObj, 'Visible', false)
			Set(Back, 'Visible', false)
			continue
		end

		local Start, OnA = ESP:Wts(From)
		local Finish, OnB = ESP:Wts(To)

		if OnA and OnB then
			StrokeLine(Back, Start, Finish, OutlineCol, 3)
			StrokeLine(LineObj, Start, Finish, Col, 1)
		else
			Set(LineObj, 'Visible', false)
			Set(Back, 'Visible', false)
		end
	end
end

function ESP.Skel:Kill()
	if self.Lines then
		KillLines(self.Lines)
	end

	if self.Back then
		KillLines(self.Back)
	end
end

ESP.HL = setmetatable({}, { __index = Base })
ESP.HL.__index = ESP.HL

local DepthMode = {
	AlwaysOnTop = Enum.HighlightDepthMode.AlwaysOnTop,
	Occluded = Enum.HighlightDepthMode.Occluded,
}

function ESP.HL:New()
	return Base.New(self)
end

function ESP.HL:Boot()
	if self.Inst then
		return
	end

	self.Inst = Inst('Highlight', {
		Parent = Hui,
		Enabled = false,
		FillColor = Rgb(255, 255, 255),
		FillTransparency = 0.5,
		OutlineColor = Rgb(0, 0, 0),
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	})
	table.insert(self.Items, self.Inst)
end

function ESP.HL:Hide()
	if not self.Inst then
		return
	end

	Set(self.Inst, 'Enabled', false)
	Set(self.Inst, 'Adornee', nil)
end

function ESP.HL:Draw(Esp, On, Char)
	local Hum = Char and Char:FindFirstChildOfClass('Humanoid')
	if not On or not Char or not Hum or Hum.Health <= 0 then
		return self:Hide()
	end

	self:Boot()

	local Outline = Esp:Get('Highlight_Outline')
	Set(self.Inst, 'Adornee', Char)
	Set(self.Inst, 'FillColor', Esp:Color('Highlight_Fill', Rgb(255, 255, 255)))
	Set(self.Inst, 'FillTransparency', Esp:Get('Highlight_Fill_Transparency') or 0.5)
	Set(self.Inst, 'OutlineColor', Esp:Color('Highlight_Outline_Color', Rgb(0, 0, 0)))
	Set(self.Inst, 'OutlineTransparency', Outline and (Esp:Get('Highlight_Outline_Transparency') or 0) or 1)
	Set(self.Inst, 'DepthMode', DepthMode[Esp:Get('Highlight_Depth')] or DepthMode.AlwaysOnTop)
	Set(self.Inst, 'Enabled', true)
end

ESP.Trace = setmetatable({}, { __index = Base })
ESP.Trace.__index = ESP.Trace

function ESP.Trace:New()
	return Base.New(self)
end

function ESP.Trace:Boot()
	if self.Line then
		return
	end

	self.Back = Line()
	self.Line = Line()
	self.Back.ZIndex = 1
	self.Line.ZIndex = 2
end

function ESP.Trace:Hide()
	if not self.Line then
		return
	end

	Set(self.Line, 'Visible', false)
	Set(self.Back, 'Visible', false)
end

function ESP.Trace:Draw(Esp, On, Data)
	if not On then
		return self:Hide()
	end

	self:Boot()

	local From = Esp.From
	local To = Vec(Data.Pos.X + Data.Size.X * 0.5, Data.Pos.Y + Data.Size.Y * 0.5)
	local Col = Esp:Color('Tracer_Color', Rgb(255, 255, 255))
	local Thick = Esp:Get('Tracer_Thickness') or 1

	StrokeLine(self.Line, From, To, Col, Thick)

	if Esp:Get('Tracer_Outline') then
		StrokeLine(self.Back, From, To, Esp:Color('Tracer_Outline_Color', Rgb(0, 0, 0)), Thick + 2)
	else
		Set(self.Back, 'Visible', false)
	end
end

function ESP.Trace:Kill()
	if self.Line then
		self.Line:Remove()
		self.Back:Remove()
	end
end

ESP.Look = setmetatable({}, { __index = Base })
ESP.Look.__index = ESP.Look

function ESP.Look:New()
	return Base.New(self)
end

function ESP.Look:Boot()
	if not self.Back then
		self.Back = Line()
		self.Back.Thickness = 3
		self.Back.ZIndex = 1
	end

	if not self.Line then
		self.Line = Line()
		self.Line.Thickness = 1
		self.Line.ZIndex = 2
	end
end

function ESP.Look:Hide()
	if self.Line then
		Set(self.Line, 'Visible', false)
	end

	if self.Back then
		Set(self.Back, 'Visible', false)
	end
end

function ESP.Look:Draw(Esp, On, Data)
	local Head = Data.Head
	if not On or not Head then
		return self:Hide()
	end

	local Start, OnA = ESP:Wts(Head.Position)
	local Finish, OnB = ESP:Wts(Head.Position + Head.CFrame.LookVector * (Esp:Get('Look_Length') or 3))
	if not OnA and not OnB then
		return self:Hide()
	end

	self:Boot()

	local Col = Esp:Color('Look_Color', Rgb(255, 255, 255))
	local Thick = Esp:Get('Look_Thickness') or 1
	local OutlineCol = Esp:Color('Look_Outline_Color', Rgb(0, 0, 0))

	StrokeLine(self.Back, Start, Finish, OutlineCol, Thick + 2)
	StrokeLine(self.Line, Start, Finish, Col, Thick)
end

function ESP.Look:Kill()
	if self.Line then
		self.Line:Remove()
	end

	if self.Back then
		self.Back:Remove()
	end
end

ESP.Object = {}
ESP.Object.__index = ESP.Object

function ESP.Object:New(Plr, Gui, Temp, TempRefs)
	local Self = setmetatable({ Plr = Plr }, ESP.Object)
	local Root, Lookup = CloneTree(Temp)
	Self.Root = Root
	Self.Root.Visible = false
	Self.Root.Parent = Gui

	local Refs = {}
	for Key, Obj in TempRefs do
		Refs[Key] = Lookup[Obj]
	end

	Self.Parts = {
		Box = ESP.Box:New(Refs),
		Fill = ESP.Fill:New(Refs),
		Name = ESP.Name:New(Refs),
		Dist = ESP.Dist:New(Refs),
		Health = ESP.Bar:New(Refs.HealthBack, Refs.HealthBar, Refs.HealthText, true),
		Armor = ESP.Bar:New(Refs.ArmorBack, Refs.ArmorBar, Refs.ArmorText, false),
		Flag = ESP.Flag:New(Refs),
		Skel = ESP.Skel:New(),
		HL = ESP.HL:New(),
		Head = ESP.Head:New(Gui),
		Trace = ESP.Trace:New(),
		Look = ESP.Look:New(),
	}

	return Self
end

function ESP.Object:Hide()
	Set(self.Root, 'Visible', false)
	self.Parts.Skel:Hide()
	self.Parts.HL:Hide()
	self.Parts.Head:Hide()
	self.Parts.Trace:Hide()
	self.Parts.Look:Hide()
end

function ESP.Object:Render(Esp, Data)
	Set(self.Root, 'Visible', true)
	Set(self.Root, 'Position', UDim2.fromOffset(Data.Pos.X, Data.Pos.Y))
	Set(self.Root, 'Size', UDim2.fromOffset(Data.Size.X, Data.Size.Y))

	self.Parts.Box:Draw(Esp, Esp:Get('Boxes'))
	self.Parts.Fill:Draw(Esp, Esp:Get('Fill'))
	self.Parts.Name:Draw(Esp, Esp:Get('Names'), Data)
	self.Parts.Dist:Draw(Esp, Esp:Get('Distance'), Data)
	self.Parts.Health:Draw(Esp:Get('Healthbar'), Data.Health, Data.HealthVal, Esp.HCfg)
	self.Parts.Armor:Draw(Esp:Get('Armorbar'), 1, 100, Esp.ACfg)
	self.Parts.Flag:Draw(Esp, Esp:Get('EspFlags'), Data)
	self.Parts.Skel:Draw(Esp, Esp:Get('Skeletons'), Data)
	self.Parts.HL:Draw(Esp, Esp:Get('Highlights'), Data.Char)
	self.Parts.Head:Draw(Esp, Esp:Get('Head'), Data)
	self.Parts.Trace:Draw(Esp, Esp:Get('Tracers'), Data)
	self.Parts.Look:Draw(Esp, Esp:Get('Look'), Data)
end


function ESP.Object:Kill()
	for _, Part in self.Parts do
		Part:Kill()
	end
	self.Root:Destroy()
end

function ESP:Add(Plr)
	if Plr == Local or self.Objects[Plr] then
		return
	end
	self.Objects[Plr] = ESP.Object:New(Plr, self.Gui, self.Temp, self.TempRefs)
end

function ESP:Rem(Plr)
	local Obj = self.Objects[Plr]
	if not Obj then return end
	Obj:Kill()
	self.Objects[Plr] = nil
end

function ESP:Pack()
	self.Bag = {}
	self.Vp = Cam.ViewportSize
	self.Px = self.Vp.Y / (2 * math.tan(math.rad(Cam.FieldOfView) * 0.5))

	local Vp = self.Vp
	local Origin = self:Get('Tracer_Origin') or 'Bottom'
	if Origin == 'Top' then
		self.From = Vec(Vp.X * 0.5, 0)
	elseif Origin == 'Center' then
		self.From = Vec(Vp.X * 0.5, Vp.Y * 0.5)
	elseif Origin == 'Mouse' then
		self.From = Input:GetMouseLocation()
	else
		self.From = Vec(Vp.X * 0.5, Vp.Y)
	end

	local H = self.HCfg
	if not H then
		H = { Colors = {}, Stops = { 0, 0.4, 0.7, 1 } }
		self.HCfg = H
	end
	H.Colors[1] = self:Color('Health_High', Rgb(0, 255, 80))
	H.Colors[2] = self:Color('Health_Mid', Rgb(255, 230, 0))
	H.Colors[3] = Rgb(255, 120, 0)
	H.Colors[4] = self:Color('Health_Low', Rgb(255, 40, 40))
	H.Text = self:Get('Health_Text')
	H.Dynamic = self:Get('Health_Text_Dynamic')
	H.TextCol = self:Color('Health_Text_Color', Rgb(0, 255, 80))

	local A = self.ACfg
	if not A then
		A = { Colors = {} }
		self.ACfg = A
	end
	local AC = self:Color('Armor_Color', Rgb(0, 85, 255))
	A.Colors[1] = AC
	A.Colors[2] = AC
	A.Text = self:Get('Armor_Text')
	A.TextCol = AC
end

function ESP:Step()
	Cam = Workspace.CurrentCamera
	if not Cam then return end

	self.Bag = {}

	if not self:Get('Enabled') then
		if not self.Off then
			self.Off = true
			for _, Obj in self.Objects do
				Obj:Hide()
			end
		end
		return
	end

	self.Off = false
	self:Pack()

	local HL = self:Get('Highlights')
	local Menu = getgenv().Library
	local MenuOpen = Menu and Menu.Window and Menu.Window.Open

	for Plr, Obj in self.Objects do
		local Data = self:Data(Plr)
		if Data then
			Obj:Render(self, Data)
			if MenuOpen then
				Obj.Parts.Skel:Hide()
				Obj.Parts.Look:Hide()
				Obj.Parts.Trace:Hide()
			end
		else
			Set(Obj.Root, 'Visible', false)
			Obj.Parts.Skel:Hide()
			Obj.Parts.Head:Hide()
			Obj.Parts.Trace:Hide()
			Obj.Parts.Look:Hide()
			Obj.Parts.HL:Draw(self, HL, Plr.Character)
		end
	end
end

function ESP:Init(ExtFlags)
	if self.Active then
		return self
	end

	self.Active = true
	self.ExtFlags = ExtFlags

	self.Gui = Inst('ScreenGui', {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1,
		Parent = Hui,
	})

	self.Temp, self.TempRefs = self:Build()
	self.Temp.Visible = false
	self.Temp.Parent = self.Gui

	for _, Plr in Players:GetPlayers() do
		self:Add(Plr)
	end

	table.insert(self.Conns, Players.PlayerAdded:Connect(function(Plr)
		self:Add(Plr)
	end))

	table.insert(self.Conns, Players.PlayerRemoving:Connect(function(Plr)
		self:Rem(Plr)
	end))

	table.insert(self.Conns, Run.Heartbeat:Connect(function()
		self:Step()
	end))

	return self
end

function ESP:Unload()
	for I = #self.Conns, 1, -1 do
		self.Conns[I]:Disconnect()
		self.Conns[I] = nil
	end

	for Plr in self.Objects do
		self:Rem(Plr)
	end

	if self.Gui then
		self.Gui:Destroy()
		self.Gui = nil
	end

	self.Active = false
end

ESP:Init()

return ESP
