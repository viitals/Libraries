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

local Run = Services['RunService']
local Http = Services['HttpService']
local CoreGui = Services['CoreGui']
local Players = Services['Players']
local Workspace = Services['Workspace']
local TweenService = Services['TweenService']
local Input = Services['UserInputService']

local Hui = CoreGui
if gethui then
	local Ok, Result = pcall(gethui)
	if Ok and Result then
		Hui = cloneref(Result)
	end
end

local Local = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local Rgb = Color3.fromRGB
local Pos = UDim2.new
local Off = UDim2.fromOffset
local Vec = Vector2.new
local Vec3 = Vector3.new
local Tween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Clock = os.clock
local Floor = math.floor
local Max = math.max
local Min = math.min
local Abs = math.abs
local Clamp = math.clamp
local Tan = math.tan
local Rad = math.rad
local Huge = math.huge

local HS = Enum.HumanoidStateType
local Ragdolled = {
	[HS.Ragdoll] = true,
	[HS.Physics] = true,
	[HS.GettingUp] = true,
	[HS.FallingDown] = true,
}

local ESP = {
	Objects = {},
	Conns = {},
	F = {},
	Font = Font.fromEnum(Enum.Font.SpecialElite),
	Size = 12,
	Height = 6,
	Width = 4,

	Flags = {
		['Enabled'] = false,
		['Team_Check'] = false,
		['Max_Distance'] = 0,
		['Names'] = false,
		['Name_Type'] = 'Both',
		['Name_Color'] = Rgb(255, 255, 255),
		['Boxes'] = false,
		['Box_Type'] = '2D',
		['Box_Dynamic'] = false,
		['Box_Color'] = Rgb(255, 255, 255),
		['Fill'] = false,
		['Fill_Color'] = Rgb(255, 255, 255),
		['Fill_Type'] = 'Full',
		['Fill_Half'] = 'Top',
		['Fill_Static'] = false,
		['Fill_Rotation'] = false,
		['Fill_Transparency'] = 0.5,
		['Fill_Spin'] = false,
		['Fill_Spin_Speed'] = 60,
		['Head'] = false,
		['Head_Color'] = Rgb(255, 255, 255),
		['Head_Fill'] = false,
		['Head_Fill_Color'] = Rgb(255, 0, 75),
		['Head_Fill_Type'] = 'Full',
		['Head_Fill_Static'] = false,
		['Head_Fill_Transparency'] = 0.5,
		['Head_Spin'] = false,
		['Head_Spin_Speed'] = 60,
		['Healthbar'] = false,
		['Health_Text'] = false,
		['Health_Text_Dynamic'] = false,
		['Health_Text_Color'] = Rgb(0, 255, 80),
		['Health_High'] = Rgb(0, 255, 80),
		['Health_Mid'] = Rgb(255, 230, 0),
		['Health_Low'] = Rgb(255, 40, 40),
		['Armorbar'] = false,
		['Armor_Text'] = false,
		['Armor_Color'] = Rgb(0, 85, 255),
		['Distance'] = false,
		['Distance_Color'] = Rgb(255, 255, 255),
		['Weapon'] = false,
		['Weapon_Color'] = Rgb(255, 255, 255),
		['EspFlags'] = false,
		['Flag_Color'] = Rgb(255, 255, 255),
		['Skeletons'] = false,
		['Skeleton_Color'] = Rgb(255, 255, 255),
		['Skeleton_Outline'] = true,
		['Skeleton_Outline_Color'] = Rgb(0, 0, 0),
		['Highlights'] = false,
		['Highlight_Fill'] = Rgb(255, 255, 255),
		['Highlight_Fill_Transparency'] = 0.5,
		['Highlight_Outline'] = true,
		['Highlight_Outline_Color'] = Rgb(255, 255, 255),
		['Highlight_Outline_Transparency'] = 0,
		['Highlight_Depth'] = 'AlwaysOnTop',
		['Tracers'] = false,
		['Tracer_Color'] = Rgb(255, 255, 255),
		['Tracer_Origin'] = 'Bottom',
		['Tracer_Thickness'] = 1,
		['Tracer_Outline'] = true,
		['Tracer_Outline_Color'] = Rgb(0, 0, 0),
		['Look'] = false,
		['Look_Color'] = Rgb(255, 255, 255),
		['Look_Outline'] = true,
		['Look_Outline_Color'] = Rgb(0, 0, 0),
		['Look_Length'] = 3,
		['Look_Thickness'] = 1,
	},
}

local function SampleGrad(Colors, Stops, T)
	T = Clamp(T, 0, 1)
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
	Neck = { 'Torso', Vec3(0, 1, 0) },
	Pelvis = { 'Torso', Vec3(0, -1, 0) },
	RightArm = { 'Right Arm', Vec3(0, 1, 0) },
	LeftArm = { 'Left Arm', Vec3(0, 1, 0) },
	RightLeg = { 'Torso', Vec3(0.5, -1, 0) },
	LeftLeg = { 'Torso', Vec3(-0.5, -1, 0) },
	RightHand = { 'Right Arm', Vec3(0, -1, 0) },
	LeftHand = { 'Left Arm', Vec3(0, -1, 0) },
	RightFoot = { 'Right Leg', Vec3(0, -1, 0) },
	LeftFoot = { 'Left Leg', Vec3(0, -1, 0) },
}

Bones.R6 = {
	{ 'Head', Joints['Neck'] },
	{ Joints['Neck'], Joints['Pelvis'] },
	{ Joints['Neck'], Joints['RightArm'] },
	{ Joints['RightArm'], Joints['RightHand'] },
	{ Joints['Neck'], Joints['LeftArm'] },
	{ Joints['LeftArm'], Joints['LeftHand'] },
	{ Joints['Pelvis'], Joints['RightLeg'] },
	{ Joints['RightLeg'], Joints['RightFoot'] },
	{ Joints['Pelvis'], Joints['LeftLeg'] },
	{ Joints['LeftLeg'], Joints['LeftFoot'] },
}

local BoneMax = Max(#Bones['R15'], #Bones['R6'])

local function JointName(Node)
	return type(Node) == 'string' and Node or Node[1]
end

local function JointPos(Part, Node)
	if type(Node) == 'string' then
		return Part.Position
	end
	return Part.CFrame * Node[2]
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
	ESP['Font'] = Tempesta
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

local function Paint(Frame, Grad, On, Cfg, State)
	if not On then
		if State['Vis'] ~= false then
			State['Vis'] = false
			Frame.BackgroundTransparency = 1
		end
		if State['Grad'] ~= false then
			State['Grad'] = false
			Grad.Enabled = false
		end
		return
	end

	local Col = Cfg['Col']
	if State['Vis'] ~= true or State['Col'] ~= Col or State['Trans'] ~= Cfg['Trans'] then
		State['Vis'] = true
		State['Col'] = Col
		State['Trans'] = Cfg['Trans']
		Frame.BackgroundColor3 = Col
		Frame.BackgroundTransparency = Cfg['Trans']
	end

	if Cfg['Static'] then
		if State['Grad'] ~= false then
			State['Grad'] = false
			Grad.Enabled = false
		end
		return
	end

	if State['Grad'] ~= true then
		State['Grad'] = true
		Grad.Enabled = true
	end

	if State['Last'] ~= Col then
		State['Last'] = Col
		Grad.Color = ColorSequence.new(Col)
	end

	local Seq = Cfg['Type'] == 'Half' and FillTrans['Half'] or FillTrans['Full']
	if State['Seq'] ~= Seq then
		State['Seq'] = Seq
		Grad.Transparency = Seq
	end

	local Rot = Cfg['Rot']
	if State['Rot'] ~= Rot then
		State['Rot'] = Rot
		Grad.Rotation = Rot
	end
end

local function Line(Thick, Z)
	local Obj = Drawing.new('Line')
	Obj.Thickness = Thick or 1
	Obj.Transparency = 0
	Obj.ZIndex = Z or 1
	Obj.Visible = false

	return {
		Obj = Obj,
		Vis = false,
		Thick = Thick or 1,
		X1 = -1,
		Y1 = -1,
		X2 = -1,
		Y2 = -1,
		Col = nil,
	}
end

local function KillLines(List)
	for _, Item in List do
		Item['Obj']:Remove()
	end
	table.clear(List)
end

local function HideLine(Item)
	if Item and Item['Vis'] then
		Item['Vis'] = false
		Item['Obj'].Visible = false
	end
end

local function StrokeLine(Item, X1, Y1, X2, Y2, Col, Thick)
	local Obj = Item['Obj']

	if Item['X1'] ~= X1 or Item['Y1'] ~= Y1 then
		Item['X1'] = X1
		Item['Y1'] = Y1
		Obj.From = Vec(X1, Y1)
	end

	if Item['X2'] ~= X2 or Item['Y2'] ~= Y2 then
		Item['X2'] = X2
		Item['Y2'] = Y2
		Obj.To = Vec(X2, Y2)
	end

	if Item['Col'] ~= Col then
		Item['Col'] = Col
		Obj.Color = Col
	end

	if Item['Thick'] ~= Thick then
		Item['Thick'] = Thick
		Obj.Thickness = Thick
	end

	if not Item['Vis'] then
		Item['Vis'] = true
		Obj.Visible = true
	end
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
	local F = self['F']
	local Val = F[Key]
	if Val ~= nil then
		return Val
	end

	Val = (self['ExtFlags'] or self['Flags'])[Key]
	if type(Val) == 'table' then
		if Val['Get'] then
			Val = Val:Get()
		end
		if type(Val) == 'table' then
			Val = Val['Color'] or Val[1]
		end
	end

	return Val
end

function ESP:Color(Key, Fallback)
	local Val = self:Get(Key)
	return Val ~= nil and Val or Fallback
end

function ESP:Raw(Key)
	local Src = self['ExtFlags'] or self['Flags']
	local Val = Src[Key]
	if type(Val) == 'table' and Val['Get'] then
		Val = Val:Get()
	end
	return Val
end

function ESP:NameStr(Data)
	local Mode = self['F']['Name_Type'] or 'Both'

	if Mode == 'Display' then
		return Data['Display']
	end

	if Mode == 'Username' then
		return Data['Name']
	end

	return Data['Both']
end

function ESP:Wts(World)
	local V, On = Cam:WorldToViewportPoint(World)
	return Vec(V.X, V.Y), On, V.Z
end

function ESP:Project(World)
	local V, On = Cam:WorldToViewportPoint(World)
	return V.X, V.Y, On, V.Z
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

local BoxDrop = Vec3(0, 0.25, 0)

local BoxVerts = {
	Vec3(-1, -1, -1),
	Vec3(-1, 1, -1),
	Vec3(-1, 1, 1),
	Vec3(-1, -1, 1),
	Vec3(1, -1, -1),
	Vec3(1, 1, -1),
	Vec3(1, 1, 1),
	Vec3(1, -1, 1),
}

function ESP:IsRagdolled(Hum, Char)
	if not Hum then
		return false
	end

	local State = Hum:GetState()
	if not Ragdolled[State] then
		return false
	end

	if Hum.Sit or Hum.SeatPart then
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

	return true
end

function ESP:StableBounds(X, Y, Depth)
	local Px = self['Px']
	local H = Max(Floor((self['Height'] / Depth) * Px + 0.5), 4)
	local W = Max(Floor(H * (self['Width'] / self['Height']) + 0.5), 4)

	return Floor(X - W * 0.5 + 0.5), Floor(Y - H * 0.5 + 0.5), W, H
end

function ESP:DynamicBounds(Obj, Char)
	local Parts = Obj:Limbs(Char)
	if not Parts[1] then
		return
	end

	local MinX3, MinY3, MinZ3 = Huge, Huge, Huge
	local MaxX3, MaxY3, MaxZ3 = -Huge, -Huge, -Huge

	for I = 1, #Parts do
		local Part = Parts[I]
		local CF, Size = Part.CFrame, Part.Size
		local A = (CF - Size * 0.5).Position
		local B = (CF + Size * 0.5).Position

		if A.X < MinX3 then MinX3 = A.X end
		if B.X < MinX3 then MinX3 = B.X end
		if A.Y < MinY3 then MinY3 = A.Y end
		if B.Y < MinY3 then MinY3 = B.Y end
		if A.Z < MinZ3 then MinZ3 = A.Z end
		if B.Z < MinZ3 then MinZ3 = B.Z end

		if A.X > MaxX3 then MaxX3 = A.X end
		if B.X > MaxX3 then MaxX3 = B.X end
		if A.Y > MaxY3 then MaxY3 = A.Y end
		if B.Y > MaxY3 then MaxY3 = B.Y end
		if A.Z > MaxZ3 then MaxZ3 = A.Z end
		if B.Z > MaxZ3 then MaxZ3 = B.Z end
	end

	local Center = Vec3((MinX3 + MaxX3) * 0.5, (MinY3 + MaxY3) * 0.5, (MinZ3 + MaxZ3) * 0.5)
	local Half = Vec3((MaxX3 - MinX3) * 0.5, (MaxY3 - MinY3) * 0.5, (MaxZ3 - MinZ3) * 0.5)

	local MinX, MinY = Huge, Huge
	local MaxX, MaxY = -Huge, -Huge
	local Hits = 0

	for I = 1, 8 do
		local Sx, Sy, _, Dep = self:Project(Center + Half * BoxVerts[I])
		if Dep > 0.15 then
			Hits += 1
			if Sx < MinX then MinX = Sx end
			if Sy < MinY then MinY = Sy end
			if Sx > MaxX then MaxX = Sx end
			if Sy > MaxY then MaxY = Sy end
		end
	end

	if Hits < 2 then
		return
	end

	local Vp = self['Vp']
	local W = Max(Floor(MaxX - MinX + 0.5), 4)
	local H = Max(Floor(MaxY - MinY + 0.5), 4)
	if W > Vp.X or H > Vp.Y then
		return
	end

	return Floor(MinX + 0.5), Floor(MinY + 0.5), W, H
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
		FontFace = ESP['Font'],
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
		FontFace = ESP['Font'],
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
		Position = Pos(0, -1, 1, 3),
		Size = Pos(1, 2, 0, 0),
	})

	local TitleHolder2 = Inst('Frame', {
		Name = 'TitleHolder',
		Parent = Down,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = Pos(0, 2, 0, 0),
		Size = Pos(1, -4, 0, 0),
	})

	Inst('UIListLayout', {
		Parent = TitleHolder2,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
	})

	local DistanceText = Inst('TextLabel', {
		Name = 'DistanceText',
		Parent = TitleHolder2,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = Pos(1, 0, 0, 12),
		FontFace = ESP['Font'],
		Text = '',
		TextColor3 = Rgb(255, 255, 255),
		TextSize = 12,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	Stroke(DistanceText)

	local WeaponText = Inst('TextLabel', {
		Name = 'WeaponText',
		Parent = TitleHolder2,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Size = Pos(1, 0, 0, 12),
		FontFace = ESP['Font'],
		Text = '',
		TextColor3 = Rgb(255, 255, 255),
		TextSize = 12,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	Stroke(WeaponText)

	local BarHolder2 = Inst('Frame', {
		Name = 'BarHolder',
		Parent = TitleHolder2,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 100,
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
		FontFace = ESP['Font'],
		Text = '',
		TextColor3 = Rgb(0, 85, 255),
		TextSize = 12,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	Stroke(ArmorText)

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
		FontFace = ESP['Font'],
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
		Transparency = FillTrans['Full'],
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

	local Edges = {}
	for I, Data in Layout do
		local Edge = Inst('Frame', {
			Name = 'Corner' .. I,
			Parent = Corners,
			BorderSizePixel = 0,
			BackgroundColor3 = Rgb(255, 255, 255),
			Position = Data[1],
			Size = Data[2],
			AnchorPoint = Data[3],
			Rotation = Data[4],
		})
		Stroke(Edge)
		Edges[I] = Edge
	end

	return Holder, {
		Inline = Inline,
		Outline = Outline,
		Corners = Corners,
		Edges = Edges,
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

function Base:Hide() end

function Base:Kill()
	for _, Item in self['Items'] do
		if typeof(Item) == 'Instance' then
			Item:Destroy()
		end
	end
	table.clear(self['Items'])
end

function ESP:BuildBox(Parent, InlineColor, OutlineColor)
	local Frame = Inst('Frame', {
		Parent = Parent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
	local Inline = Inst('UIStroke', {
		Parent = Frame,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderOffset = UDim.new(0, -1),
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Color = InlineColor or Rgb(255, 255, 255),
		LineJoinMode = Enum.LineJoinMode.Miter,
		Thickness = 1,
	})
	local Outline = Inst('UIStroke', {
		Parent = Frame,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Color = OutlineColor or Rgb(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter,
		Thickness = 3,
		ZIndex = 0,
	})
	return Frame, Inline, Outline
end

ESP.Box = setmetatable({}, { __index = Base })
ESP.Box.__index = ESP.Box

function ESP.Box:New(Refs)
	local Self = Base.New(self)
	Self['Inline'] = Refs['Inline']
	Self['Outline'] = Refs['Outline']
	Self['Corners'] = Refs['Corners']
	Self['Edges'] = Refs['Edges']
	return Self
end

function ESP.Box:Draw(Esp, On)
	local F = Esp['F']
	local Is2D = On and (F['Box_Type'] or '2D') == '2D'

	Set(self['Inline'], 'Enabled', Is2D)
	Set(self['Outline'], 'Enabled', Is2D)
	Set(self['Corners'], 'Visible', On and not Is2D)

	if not On then
		return
	end

	local Col = F['Box_Color']
	if self['Col'] == Col then
		return
	end

	self['Col'] = Col
	self['Inline'].Color = Col
	for _, Edge in self['Edges'] do
		Edge.BackgroundColor3 = Col
	end
end

ESP.Fill = setmetatable({}, { __index = Base })
ESP.Fill.__index = ESP.Fill

function ESP.Fill:New(Refs)
	local Self = Base.New(self)
	Self['Frame'] = Refs['Holder']
	Self['Grad'] = Refs['HolderGrad']
	Self['State'] = {}
	return Self
end

function ESP.Fill:Draw(Esp, On)
	Paint(self['Frame'], self['Grad'], On, Esp['FCfg'], self['State'])
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

	Self['Stroke'] = Inst('UIStroke', {
		Parent = Root,
		Color = Rgb(255, 255, 255),
		Thickness = 1,
	})

	Self['Inner'] = Inst('Frame', {
		Parent = Root,
		BackgroundColor3 = Rgb(255, 255, 255),
		BorderSizePixel = 0,
		Size = Pos(1, 0, 1, 0),
	})

	Inst('UICorner', {
		Parent = Self['Inner'],
		CornerRadius = UDim.new(1, 0),
	})

	Self['Grad'] = Inst('UIGradient', {
		Parent = Self['Inner'],
		Rotation = -90,
		Color = ColorSequence.new(Rgb(255, 0, 75)),
		Transparency = FillTrans['Full'],
	})

	Self['Root'] = Root
	Self['State'] = {}
	Self['Vis'] = false
	table.insert(Self['Items'], Root)
	return Self
end

function ESP.Circ:Hide()
	if self['Vis'] then
		self['Vis'] = false
		self['Root'].Visible = false
	end
end

function ESP.Circ:Draw(X, Y, Rad, Cfg)
	local Dia = Max(Floor(Rad * 2 + 0.5), 2)
	local Root = self['Root']

	if not self['Vis'] then
		self['Vis'] = true
		Root.Visible = true
	end

	if self['X'] ~= X or self['Y'] ~= Y then
		self['X'] = X
		self['Y'] = Y
		Root.Position = Off(X, Y)
	end

	if self['Dia'] ~= Dia then
		self['Dia'] = Dia
		Root.Size = Off(Dia, Dia)
	end

	local Line = Cfg['Stroke']
	if Line then
		Set(self['Stroke'], 'Enabled', true)
		if self['Line'] ~= Line then
			self['Line'] = Line
			self['Stroke'].Color = Line
		end
	else
		Set(self['Stroke'], 'Enabled', false)
	end

	Paint(self['Inner'], self['Grad'], Cfg['Fill'], Cfg, self['State'])
end

ESP.Head = setmetatable({}, { __index = Base })
ESP.Head.__index = ESP.Head

function ESP.Head:New()
	return Base.New(self)
end

function ESP.Head:Hide()
	if self['Circ'] then
		self['Circ']:Hide()
	end
end

function ESP.Head:Kill()
	if self['Circ'] then
		self['Circ']:Kill()
		self['Circ'] = nil
	end
end

function ESP.Head:Draw(Esp, On, Data)
	local Part = Data['Head']
	if not On or not Part then
		return self:Hide()
	end

	local X, Y, Ok, Z = Esp:Project(Part.Position)
	if not Ok or Z <= 0 then
		return self:Hide()
	end

	local Circ = self['Circ']
	if not Circ then
		Circ = ESP.Circ:New(Esp['Gui'])
		self['Circ'] = Circ
	end

	local Rd = Max(Part.Size.X * 0.5 / Z * Esp['Px'], 2)
	Circ:Draw(X, Y, Rd, Esp['HeadCfg'])
end

ESP.Name = setmetatable({}, { __index = Base })
ESP.Name.__index = ESP.Name

function ESP.Name:New(Refs)
	local Self = Base.New(self)
	Self['Text'] = Refs['NameText']
	return Self
end

function ESP.Name:Draw(Esp, On, Data)
	local Label = self['Text']
	Set(Label, 'Visible', On)
	if not On then
		return
	end

	local Col = Esp['F']['Name_Color']
	if self['Col'] ~= Col then
		self['Col'] = Col
		Label.TextColor3 = Col
	end

	local Str = Esp:NameStr(Data)
	if self['Str'] ~= Str then
		self['Str'] = Str
		Label.Text = Str
	end
end

ESP.Dist = setmetatable({}, { __index = Base })
ESP.Dist.__index = ESP.Dist

function ESP.Dist:New(Refs)
	local Self = Base.New(self)
	Self['Text'] = Refs['DistanceText']
	Self['Weapon'] = Refs['WeaponText']
	return Self
end

function ESP.Dist:Draw(Esp, On, Data)
	local F = Esp['F']
	local Label = self['Text']
	Set(Label, 'Visible', On)

	if On then
		local Col = F['Distance_Color']
		if self['Col'] ~= Col then
			self['Col'] = Col
			Label.TextColor3 = Col
		end

		local Dist = Data['Dist']
		if self['Dist'] ~= Dist then
			self['Dist'] = Dist
			Label.Text = Dist .. ' st'
		end
	end

	local Tool = Data['Weapon']
	local WeaponOn = F['Weapon'] and Tool ~= ''
	local Label2 = self['Weapon']
	Set(Label2, 'Visible', WeaponOn)

	if WeaponOn then
		local Col = F['Weapon_Color']
		if self['WCol'] ~= Col then
			self['WCol'] = Col
			Label2.TextColor3 = Col
		end

		if self['Tool'] ~= Tool then
			self['Tool'] = Tool
			Label2.Text = Tool
		end
	end
end

ESP.Bar = setmetatable({}, { __index = Base })
ESP.Bar.__index = ESP.Bar

function ESP.Bar:New(Back, Fill, Text, Vert)
	local Self = Base.New(self)
	Self['Back'] = Back
	Self['Fill'] = Fill
	Self['Text'] = Text
	Self['Grad'] = Fill:FindFirstChildOfClass('UIGradient')
	Self['Vert'] = Vert
	Self['Last'] = nil
	Self['Tween'] = nil
	return Self
end

function ESP.Bar:SetGrad(Cfg, From, To)
	local Grad = self['Grad']
	if not Grad then
		return
	end

	From = Clamp(From or 0, 0, 1)
	To = Clamp(To or 1, 0, 1)
	if To <= From then
		To = Min(From + 0.001, 1)
	end

	local QFrom = Floor(From * 40 + 0.5)
	local QTo = Floor(To * 40 + 0.5)
	local Stamp = Cfg['Stamp']

	if self['QFrom'] == QFrom and self['QTo'] == QTo and self['Stamp'] == Stamp then
		return
	end

	self['QFrom'] = QFrom
	self['QTo'] = QTo
	self['Stamp'] = Stamp

	local Colors, Stops = Cfg['Colors'], Cfg['Stops']
	local Span = To - From
	local Points = {
		ColorSequenceKeypoint.new(0, SampleGrad(Colors, Stops, From)),
	}

	for I = 1, #Colors do
		local T = Stops and Stops[I] or ((I - 1) / Max(#Colors - 1, 1))
		if T > From + 0.001 and T < To - 0.001 then
			Points[#Points + 1] = ColorSequenceKeypoint.new((T - From) / Span, Colors[I])
		end
	end

	Points[#Points + 1] = ColorSequenceKeypoint.new(1, SampleGrad(Colors, Stops, To))
	Grad.Color = ColorSequence.new(Points)
end

function ESP.Bar:Draw(On, Pct, Val, Cfg)
	Set(self['Back'], 'Visible', On)

	local Wrapper = self['Back'].Parent
	if Wrapper and Wrapper.Name == 'BarHolder' then
		Set(Wrapper, 'Visible', On)
	end

	if not On then
		return
	end

	Pct = Clamp(Pct or 0, 0, 1)
	local Vert = self['Vert']

	if Vert then
		self:SetGrad(Cfg, 1 - Pct, 1)
	else
		self:SetGrad(Cfg, 0, 1)
	end

	local Last = self['Last']
	if Last == nil or Abs(Last - Pct) >= 0.01 then
		local Size, Position
		if Vert then
			Size = Pos(1, -2, Pct, 0)
			Position = Pos(0, 1, 1 - Pct, 0)
		else
			Size = Pos(Pct, 0, 1, 0)
		end

		if Last == nil then
			self['Fill'].Size = Size
			if Position then
				self['Fill'].Position = Position
			end
		else
			if self['Tween'] then
				self['Tween']:Cancel()
			end

			local Goals = { Size = Size }
			if Position then
				Goals['Position'] = Position
			end

			self['Tween'] = TweenService:Create(self['Fill'], Tween, Goals)
			self['Tween']:Play()
		end

		self['Last'] = Pct
	end

	local Label = self['Text']
	if not Label then
		return
	end

	Val = Val or Floor(Pct * 100 + 0.5)
	Set(Label, 'Visible', Cfg['Text'] and Val ~= 0 and Val ~= 100)

	local Col = Cfg['TextCol']
	if Cfg['Dynamic'] and Cfg['Stops'] then
		Col = SampleGrad(Cfg['Colors'], Cfg['Stops'], 1 - Pct)
	end

	if self['Col'] ~= Col then
		self['Col'] = Col
		Label.TextColor3 = Col
	end

	if self['Val'] ~= Val then
		self['Val'] = Val
		Label.Text = tostring(Val)
	end
end

ESP.Flag = setmetatable({}, { __index = Base })
ESP.Flag.__index = ESP.Flag

function ESP.Flag:New(Refs)
	local Self = Base.New(self)
	Self['Holder'] = Refs['FlagsHolder']
	Self['Temp'] = Refs['FlagText']
	Self['Temp'].Visible = false
	Self['Labels'] = {}
	Self['Hold'] = {}
	return Self
end

function ESP.Flag:Label(Name, Order, Col)
	local Entry = self['Labels'][Name]
	if not Entry then
		local Lbl = self['Temp']:Clone()
		Lbl.Name = '\0'
		Lbl.Text = Name
		Lbl.Parent = self['Holder']
		Entry = { Lbl = Lbl, Vis = false }
		self['Labels'][Name] = Entry
		table.insert(self['Items'], Lbl)
	end

	local Lbl = Entry['Lbl']
	if Entry['Order'] ~= Order then
		Entry['Order'] = Order
		Lbl.LayoutOrder = Order
	end

	if Entry['Col'] ~= Col then
		Entry['Col'] = Col
		Lbl.TextColor3 = Col
	end

	if not Entry['Vis'] then
		Entry['Vis'] = true
		Lbl.Visible = true
	end
end

function ESP.Flag:Draw(Esp, On, Data)
	Set(self['Holder'], 'Visible', On)
	local Flags = Data['Flags']
	if not On or not Flags then
		return
	end

	local Col = Esp['F']['Flag_Color']
	local Now = Esp['Now']
	local Hold = self['Hold']
	local Order = 0

	for _, Name in FlagOrder do
		local Active = Flags[Name]
		if Active then
			Hold[Name] = Now
		end

		local Stamp = Hold[Name]
		if Active or (Stamp and Now - Stamp < FlagHold) then
			Order += 1
			self:Label(Name, Order, Col)
		else
			local Entry = self['Labels'][Name]
			if Entry and Entry['Vis'] then
				Entry['Vis'] = false
				Entry['Lbl'].Visible = false
			end
		end
	end
end

-- // Finobe's r15 skeleton mapping system | https://github.com/i77lhm
ESP.Skel = setmetatable({}, { __index = Base })
ESP.Skel.__index = ESP.Skel

function ESP.Skel:New()
	local Self = Base.New(self)
	Self['Map'] = {}
	Self['Stamp'] = 0
	return Self
end

function ESP.Skel:Boot()
	if self['Lines'] then
		return
	end

	self['Lines'] = table.create(BoneMax)
	self['Back'] = table.create(BoneMax)

	for I = 1, BoneMax do
		self['Back'][I] = Line(3, 1)
		self['Lines'][I] = Line(1, 2)
	end
end

function ESP.Skel:Hide()
	local Lines = self['Lines']
	if not Lines then
		return
	end

	for I = 1, BoneMax do
		HideLine(Lines[I])
		HideLine(self['Back'][I])
	end
end

function ESP.Skel:Build(Char, Now)
	if self['Char'] == Char and Now - self['Stamp'] < 0.5 then
		return self['Map']
	end

	self['Char'] = Char
	self['Stamp'] = Now

	local Map = self['Map']
	table.clear(Map)

	local Rig = Char:FindFirstChild('UpperTorso') and Bones['R15'] or Bones['R6']
	for I = 1, #Rig do
		local Bone = Rig[I]
		local A = Char:FindFirstChild(JointName(Bone[1]))
		local B = Char:FindFirstChild(JointName(Bone[2]))
		if A and B then
			Map[I] = { A, Bone[1], B, Bone[2] }
		end
	end

	return Map
end

function ESP.Skel:Draw(Esp, On, Data)
	if not On then
		return self:Hide()
	end

	self:Boot()

	local F = Esp['F']
	local Map = self:Build(Data['Char'], Esp['Now'])
	local Col = F['Skeleton_Color']
	local OutCol = F['Skeleton_Outline_Color']
	local Outline = F['Skeleton_Outline']
	local Lines, Back = self['Lines'], self['Back']

	for I = 1, BoneMax do
		local Bone = Map[I]
		if not Bone then
			HideLine(Lines[I])
			HideLine(Back[I])
			continue
		end

		local X1, Y1, OnA = Esp:Project(JointPos(Bone[1], Bone[2]))
		local X2, Y2, OnB = Esp:Project(JointPos(Bone[3], Bone[4]))

		if OnA and OnB then
			if Outline then
				StrokeLine(Back[I], X1, Y1, X2, Y2, OutCol, 3)
			else
				HideLine(Back[I])
			end
			StrokeLine(Lines[I], X1, Y1, X2, Y2, Col, 1)
		else
			HideLine(Lines[I])
			HideLine(Back[I])
		end
	end
end

function ESP.Skel:Kill()
	if self['Lines'] then
		KillLines(self['Lines'])
		KillLines(self['Back'])
		self['Lines'] = nil
		self['Back'] = nil
	end
	table.clear(self['Map'])
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
	if self['Inst'] then
		return
	end

	self['Inst'] = Inst('Highlight', {
		Parent = Hui,
		Enabled = false,
		FillColor = Rgb(255, 255, 255),
		FillTransparency = 0.5,
		OutlineColor = Rgb(0, 0, 0),
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	})
	table.insert(self['Items'], self['Inst'])
end

function ESP.HL:Hide()
	local Obj = self['Inst']
	if not Obj or not self['On'] then
		return
	end

	self['On'] = false
	self['Char'] = nil
	Obj.Enabled = false
	Obj.Adornee = nil
end

function ESP.HL:Draw(Esp, On, Char, Hum)
	if not On or not Char or not Hum or Hum.Health <= 0 then
		return self:Hide()
	end

	self:Boot()

	local F = Esp['F']
	local Obj = self['Inst']

	if self['Char'] ~= Char then
		self['Char'] = Char
		Obj.Adornee = Char
	end

	local Fill = F['Highlight_Fill']
	if self['Fill'] ~= Fill then
		self['Fill'] = Fill
		Obj.FillColor = Fill
	end

	local Trans = F['Highlight_Fill_Transparency'] or 0.5
	if self['Trans'] ~= Trans then
		self['Trans'] = Trans
		Obj.FillTransparency = Trans
	end

	local OutCol = F['Highlight_Outline_Color']
	if self['OutCol'] ~= OutCol then
		self['OutCol'] = OutCol
		Obj.OutlineColor = OutCol
	end

	local OutTrans = F['Highlight_Outline'] and (F['Highlight_Outline_Transparency'] or 0) or 1
	if self['OutTrans'] ~= OutTrans then
		self['OutTrans'] = OutTrans
		Obj.OutlineTransparency = OutTrans
	end

	local Depth = DepthMode[F['Highlight_Depth']] or DepthMode['AlwaysOnTop']
	if self['Depth'] ~= Depth then
		self['Depth'] = Depth
		Obj.DepthMode = Depth
	end

	if not self['On'] then
		self['On'] = true
		Obj.Enabled = true
	end
end

ESP.Trace = setmetatable({}, { __index = Base })
ESP.Trace.__index = ESP.Trace

function ESP.Trace:New()
	return Base.New(self)
end

function ESP.Trace:Boot()
	if self['Line'] then
		return
	end

	self['Back'] = Line(3, 1)
	self['Line'] = Line(1, 2)
end

function ESP.Trace:Hide()
	HideLine(self['Line'])
	HideLine(self['Back'])
end

function ESP.Trace:Draw(Esp, On, Data)
	if not On then
		return self:Hide()
	end

	self:Boot()

	local F = Esp['F']
	local X1, Y1 = Esp['FromX'], Esp['FromY']
	local X2 = Data['X'] + Data['W'] * 0.5
	local Y2 = Data['Y'] + Data['H'] * 0.5
	local Thick = F['Tracer_Thickness'] or 1

	StrokeLine(self['Line'], X1, Y1, X2, Y2, F['Tracer_Color'], Thick)

	if F['Tracer_Outline'] then
		StrokeLine(self['Back'], X1, Y1, X2, Y2, F['Tracer_Outline_Color'], Thick + 2)
	else
		HideLine(self['Back'])
	end
end

function ESP.Trace:Kill()
	if self['Line'] then
		self['Line']['Obj']:Remove()
		self['Back']['Obj']:Remove()
		self['Line'] = nil
		self['Back'] = nil
	end
end

ESP.Look = setmetatable({}, { __index = Base })
ESP.Look.__index = ESP.Look

function ESP.Look:New()
	return Base.New(self)
end

function ESP.Look:Boot()
	if self['Line'] then
		return
	end

	self['Back'] = Line(3, 1)
	self['Line'] = Line(1, 2)
end

function ESP.Look:Hide()
	HideLine(self['Line'])
	HideLine(self['Back'])
end

function ESP.Look:Draw(Esp, On, Data)
	local Head = Data['Head']
	if not On or not Head then
		return self:Hide()
	end

	local F = Esp['F']
	local CF = Head.CFrame
	local X1, Y1, OnA = Esp:Project(CF.Position)
	local X2, Y2, OnB = Esp:Project(CF.Position + CF.LookVector * (F['Look_Length'] or 3))

	if not OnA and not OnB then
		return self:Hide()
	end

	self:Boot()

	local Thick = F['Look_Thickness'] or 1
	if F['Look_Outline'] then
		StrokeLine(self['Back'], X1, Y1, X2, Y2, F['Look_Outline_Color'], Thick + 2)
	else
		HideLine(self['Back'])
	end

	StrokeLine(self['Line'], X1, Y1, X2, Y2, F['Look_Color'], Thick)
end

function ESP.Look:Kill()
	if self['Line'] then
		self['Line']['Obj']:Remove()
		self['Back']['Obj']:Remove()
		self['Line'] = nil
		self['Back'] = nil
	end
end

ESP.Object = {}
ESP.Object.__index = ESP.Object

function ESP.Object:New(Plr)
	local Self = setmetatable({
		Plr = Plr,
		Name = Plr.Name,
		Display = Plr.DisplayName,
		Both = Plr.DisplayName .. ' (@' .. Plr.Name .. ')',
		Limb = {},
		Stamp = 0,
		Data = { Flags = {} },
		Ready = false,
	}, ESP.Object)

	Self['Skel'] = ESP.Skel:New()
	Self['HL'] = ESP.HL:New()
	Self['Head'] = ESP.Head:New()
	Self['Trace'] = ESP.Trace:New()
	Self['Look'] = ESP.Look:New()

	return Self
end

function ESP.Object:Boot(Esp)
	if self['Ready'] then
		return
	end

	local Root, Lookup = CloneTree(Esp['Temp'])
	Root.Visible = false
	Root.Parent = Esp['Gui']
	self['Root'] = Root

	local Refs = {}
	for Key, Obj in Esp['TempRefs'] do
		if Key == 'Edges' then
			local Edges = {}
			for I, Edge in Obj do
				Edges[I] = Lookup[Edge]
			end
			Refs['Edges'] = Edges
		else
			Refs[Key] = Lookup[Obj]
		end
	end

	self['Box'] = ESP.Box:New(Refs)
	self['Fill'] = ESP.Fill:New(Refs)
	self['Label'] = ESP.Name:New(Refs)
	self['Dist'] = ESP.Dist:New(Refs)
	self['Health'] = ESP.Bar:New(Refs['HealthBack'], Refs['HealthBar'], Refs['HealthText'], true)
	self['Armor'] = ESP.Bar:New(Refs['ArmorBack'], Refs['ArmorBar'], Refs['ArmorText'], false)
	self['Flag'] = ESP.Flag:New(Refs)
	self['Ready'] = true
end

function ESP.Object:Refresh()
	local Char = self['Plr'].Character
	if Char ~= self['Char'] then
		self['Char'] = Char
		self['Hum'] = nil
		self['Part'] = nil
		self['HeadPart'] = nil
		self['Tool'] = nil
		self['ToolStr'] = ''
		table.clear(self['Limb'])
		self['Skel']['Char'] = nil
	end

	if not Char then
		return
	end

	local Hum = self['Hum']
	if not Hum or Hum.Parent ~= Char then
		Hum = Char:FindFirstChildOfClass('Humanoid')
		self['Hum'] = Hum
	end

	local Part = self['Part']
	if not Part or Part.Parent ~= Char then
		Part = Char:FindFirstChild('HumanoidRootPart')
			or Char:FindFirstChild('UpperTorso')
			or Char:FindFirstChild('Torso')
			or Char:FindFirstChild('LowerTorso')
			or Char:FindFirstChild('Head')
		self['Part'] = Part
	end

	local HeadPart = self['HeadPart']
	if not HeadPart or HeadPart.Parent ~= Char then
		self['HeadPart'] = Char:FindFirstChild('Head')
	end

	return Char, Hum, self['Part']
end

function ESP.Object:Limbs(Char)
	local Limb = self['Limb']
	local Now = Clock()

	if Limb[1] and Limb[1].Parent == Char and Now - self['Stamp'] < 0.5 then
		return Limb
	end

	self['Stamp'] = Now
	table.clear(Limb)

	for _, Part in Char:GetChildren() do
		if BodyPart[Part.Name] and Part:IsA('BasePart') then
			Limb[#Limb + 1] = Part
		end
	end

	return Limb
end

function ESP.Object:Weapon(Char)
	local Tool = Char:FindFirstChildOfClass('Tool')
	if Tool == self['Tool'] then
		return self['ToolStr']
	end

	self['Tool'] = Tool
	if not Tool then
		self['ToolStr'] = ''
		return ''
	end

	local Name = Tool.Name
	if Name:sub(1, 1) == '[' and Name:sub(-1) == ']' then
		self['ToolStr'] = Name
	else
		self['ToolStr'] = '[' .. Name .. ']'
	end

	return self['ToolStr']
end

function ESP.Object:Hide()
	if self['Ready'] and self['Vis'] then
		self['Vis'] = false
		self['Root'].Visible = false
	end

	self['Skel']:Hide()
	self['HL']:Hide()
	self['Head']:Hide()
	self['Trace']:Hide()
	self['Look']:Hide()
end

function ESP.Object:Render(Esp, Data)
	self:Boot(Esp)

	local F = Esp['F']
	local Root = self['Root']
	local X, Y = Data['X'], Data['Y']
	local W, H = Data['W'], Data['H']

	if not self['Vis'] then
		self['Vis'] = true
		Root.Visible = true
	end

	if self['X'] ~= X or self['Y'] ~= Y then
		self['X'] = X
		self['Y'] = Y
		Root.Position = Off(X, Y)
	end

	if self['W'] ~= W or self['H'] ~= H then
		self['W'] = W
		self['H'] = H
		Root.Size = Off(W, H)
	end

	self['Box']:Draw(Esp, F['Boxes'])
	self['Fill']:Draw(Esp, F['Fill'])
	self['Label']:Draw(Esp, F['Names'], Data)
	self['Dist']:Draw(Esp, F['Distance'], Data)
	self['Health']:Draw(F['Healthbar'], Data['Health'], Data['HealthVal'], Esp['HCfg'])
	self['Armor']:Draw(F['Armorbar'], 1, 100, Esp['ACfg'])
	self['Flag']:Draw(Esp, F['EspFlags'], Data)
	self['Skel']:Draw(Esp, F['Skeletons'], Data)
	self['HL']:Draw(Esp, F['Highlights'], Data['Char'], self['Hum'])
	self['Head']:Draw(Esp, F['Head'], Data)
	self['Trace']:Draw(Esp, F['Tracers'], Data)
	self['Look']:Draw(Esp, F['Look'], Data)
end

function ESP.Object:Kill()
	self['Skel']:Kill()
	self['HL']:Kill()
	self['Head']:Kill()
	self['Trace']:Kill()
	self['Look']:Kill()

	if self['Ready'] then
		self['Box']:Kill()
		self['Fill']:Kill()
		self['Label']:Kill()
		self['Dist']:Kill()
		self['Health']:Kill()
		self['Armor']:Kill()
		self['Flag']:Kill()
		self['Root']:Destroy()
		self['Ready'] = false
	end
end

function ESP:Data(Obj)
	local Char, Hum, Part = Obj:Refresh()
	if not Char or not Hum or not Part or Hum.Health <= 0 then
		return
	end

	local F = self['F']
	local CamPos = self['CamPos']
	local Where = Part.Position
	local Offset = Where - BoxDrop
	local Dist = (Where - CamPos).Magnitude

	local Cap = F['Max_Distance'] or 0
	if Cap > 0 and Dist > Cap then
		return
	end

	local X, Y, On, Depth = self:Project(Offset)
	if Depth <= 0.15 then
		return
	end

	local Ragdoll = self:IsRagdolled(Hum, Char)
	local Bx, By, Bw, Bh

	if F['Box_Dynamic'] or Ragdoll then
		local Vp = self['Vp']
		local Sx, Sy, Sw, Sh = self:StableBounds(X, Y, Depth)
		local Mx, My = Sw * 2, Sh * 2

		if X > -Mx and Y > -My and X < Vp.X + Mx and Y < Vp.Y + My then
			Bx, By, Bw, Bh = self:DynamicBounds(Obj, Char)
		end

		if not Bx and On then
			Bx, By, Bw, Bh = Sx, Sy, Sw, Sh
		end
	elseif On then
		Bx, By, Bw, Bh = self:StableBounds(X, Y, Depth)
	end

	if not Bx then
		return
	end

	local Data = Obj['Data']
	Data['X'] = Bx
	Data['Y'] = By
	Data['W'] = Bw
	Data['H'] = Bh
	Data['Char'] = Char
	Data['Head'] = Obj['HeadPart']
	Data['Name'] = Obj['Name']
	Data['Display'] = Obj['Display']
	Data['Both'] = Obj['Both']
	Data['Dist'] = Floor(Dist + 0.5)
	Data['Weapon'] = F['Weapon'] and Obj:Weapon(Char) or ''

	if F['Healthbar'] then
		local MaxHp = Hum.MaxHealth
		local Hp = Hum.Health
		Data['Health'] = MaxHp > 0 and Hp / MaxHp or 0
		Data['HealthVal'] = Floor(Hp + 0.5)
	else
		Data['Health'] = 0
		Data['HealthVal'] = 0
	end

	if F['EspFlags'] then
		local State = Hum:GetState()
		local Air = State == HS.Freefall or State == HS.FallingDown or State == HS.Jumping
		local Climbing = State == HS.Climbing
		local Swimming = State == HS.Swimming
		local Seated = State == HS.Seated or Hum.Sit or Hum.SeatPart ~= nil
		local Flying = State == HS.Flying
		local Moving = Hum.MoveDirection.Magnitude > 0.05

		local Flags = Data['Flags']
		Flags['Ragdoll'] = Ragdoll
		Flags['Falling'] = State == HS.Freefall or State == HS.FallingDown
		Flags['Jumping'] = State == HS.Jumping
		Flags['Climbing'] = Climbing
		Flags['Swimming'] = Swimming
		Flags['Seated'] = Seated
		Flags['Flying'] = Flying
		Flags['Running'] = Moving and not (Air or Climbing or Swimming or Seated or Ragdoll or Flying)
	end

	return Data
end

function ESP:Pack()
	local F = self['F']
	local Src = self['ExtFlags'] or self['Flags']

	for Key, Val in Src do
		if type(Val) == 'table' then
			if Val['Get'] then
				Val = Val:Get()
			end
			if type(Val) == 'table' then
				Val = Val['Color'] or Val[1]
			end
		end
		F[Key] = Val
	end

	local CF = Cam.CFrame
	self['CamPos'] = CF.Position
	self['Now'] = Clock()

	local Vp = Cam.ViewportSize
	self['Vp'] = Vp
	self['Px'] = Vp.Y / (2 * Tan(Rad(Cam.FieldOfView) * 0.5))

	local Origin = F['Tracer_Origin'] or 'Bottom'
	if Origin == 'Top' then
		self['FromX'], self['FromY'] = Vp.X * 0.5, 0
	elseif Origin == 'Center' then
		self['FromX'], self['FromY'] = Vp.X * 0.5, Vp.Y * 0.5
	elseif Origin == 'Mouse' then
		local M = Input:GetMouseLocation()
		self['FromX'], self['FromY'] = M.X, M.Y
	else
		self['FromX'], self['FromY'] = Vp.X * 0.5, Vp.Y
	end

	local Fill = self['FCfg']
	local Type = F['Fill_Type'] or 'Full'
	local Rot = F['Fill_Rotation']
	if not Rot and Type ~= 'Full' then
		Rot = FillRot[F['Fill_Half'] or 'Top'] or FillRot['Top']
	end

	Fill['Col'] = F['Fill_Color'] or Rgb(255, 255, 255)
	Fill['Trans'] = F['Fill_Transparency'] or 0.5
	Fill['Static'] = F['Fill_Static']
	Fill['Type'] = Type
	Fill['Spin'] = F['Fill_Spin']

	if Fill['Spin'] then
		Fill['Rot'] = Floor(self['Now'] * (F['Fill_Spin_Speed'] or 60)) % 360
	else
		Fill['Rot'] = Rot or FillRot['Bottom']
	end

	local Head = self['HeadCfg']
	Head['Col'] = F['Head_Fill_Color'] or Rgb(255, 0, 75)
	Head['Trans'] = F['Head_Fill_Transparency'] or 0.5
	Head['Static'] = F['Head_Fill_Static']
	Head['Type'] = F['Head_Fill_Type'] or 'Full'
	Head['Fill'] = F['Head_Fill']
	Head['Stroke'] = F['Head_Color']

	if F['Head_Spin'] then
		Head['Rot'] = Floor(self['Now'] * (F['Head_Spin_Speed'] or 60)) % 360
	else
		Head['Rot'] = FillRot['Bottom']
	end

	local H = self['HCfg']
	local Hi = F['Health_High'] or Rgb(0, 255, 80)
	local Mid = F['Health_Mid'] or Rgb(255, 230, 0)
	local Lo = F['Health_Low'] or Rgb(255, 40, 40)
	local Cols = H['Colors']

	if Cols[1] ~= Hi or Cols[2] ~= Mid or Cols[4] ~= Lo then
		Cols[1] = Hi
		Cols[2] = Mid
		Cols[3] = Rgb(255, 120, 0)
		Cols[4] = Lo
		H['Stamp'] += 1
	end

	H['Text'] = F['Health_Text']
	H['Dynamic'] = F['Health_Text_Dynamic']
	H['TextCol'] = F['Health_Text_Color'] or Hi

	local A = self['ACfg']
	local AC = F['Armor_Color'] or Rgb(0, 85, 255)
	if A['Colors'][1] ~= AC then
		A['Colors'][1] = AC
		A['Colors'][2] = AC
		A['Stamp'] += 1
	end

	A['Text'] = F['Armor_Text']
	A['TextCol'] = AC
end

function ESP:Step()
	Cam = Workspace.CurrentCamera
	if not Cam then
		return
	end

	if not self:Raw('Enabled') then
		if not self['Idle'] then
			self['Idle'] = true
			for _, Obj in self['Objects'] do
				Obj:Hide()
			end
		end
		return
	end

	self['Idle'] = false
	self:Boot()
	self:Pack()

	local F = self['F']
	local HL = F['Highlights']
	local Team = F['Team_Check'] and Local.Team
	local Menu = getgenv().Library
	local Shut = Menu and Menu.Window and Menu.Window.Open

	for Plr, Obj in self['Objects'] do
		local Data
		if Team and Plr.Team == Team then
			Obj:Hide()
			continue
		end

		Data = self:Data(Obj)

		if Data then
			Obj:Render(self, Data)
			if Shut then
				Obj['Skel']:Hide()
				Obj['Look']:Hide()
				Obj['Trace']:Hide()
			end
		else
			if Obj['Ready'] and Obj['Vis'] then
				Obj['Vis'] = false
				Obj['Root'].Visible = false
			end

			Obj['Skel']:Hide()
			Obj['Head']:Hide()
			Obj['Trace']:Hide()
			Obj['Look']:Hide()
			Obj['HL']:Draw(self, HL, Obj['Char'], Obj['Hum'])
		end
	end
end

function ESP:Add(Plr)
	if Plr == Local or self['Objects'][Plr] then
		return
	end
	self['Objects'][Plr] = ESP.Object:New(Plr)
end

function ESP:Rem(Plr)
	local Obj = self['Objects'][Plr]
	if not Obj then
		return
	end
	Obj:Kill()
	self['Objects'][Plr] = nil
end

function ESP:Boot()
	if self['Gui'] then
		return
	end

	self['Gui'] = Inst('ScreenGui', {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1,
		Parent = Hui,
	})

	self['Temp'], self['TempRefs'] = self:Build()
	self['Temp'].Visible = false
	self['Temp'].Parent = self['Gui']
end

function ESP:Init(ExtFlags)
	if ExtFlags then
		self['ExtFlags'] = ExtFlags
	end

	if self['Active'] then
		return self
	end

	self['Active'] = true
	self['FCfg'] = {}
	self['HeadCfg'] = {}
	self['HCfg'] = { Colors = {}, Stops = { 0, 0.4, 0.7, 1 }, Stamp = 0 }
	self['ACfg'] = { Colors = {}, Stamp = 0 }

	for _, Plr in Players:GetPlayers() do
		self:Add(Plr)
	end

	table.insert(self['Conns'], Players.PlayerAdded:Connect(function(Plr)
		self:Add(Plr)
	end))

	table.insert(self['Conns'], Players.PlayerRemoving:Connect(function(Plr)
		self:Rem(Plr)
	end))

	table.insert(self['Conns'], Run.Heartbeat:Connect(function()
		self:Step()
	end))

	return self
end

function ESP:Unload()
	for I = #self['Conns'], 1, -1 do
		self['Conns'][I]:Disconnect()
		self['Conns'][I] = nil
	end

	for Plr in self['Objects'] do
		self:Rem(Plr)
	end

	if self['Gui'] then
		self['Gui']:Destroy()
		self['Gui'] = nil
		self['Temp'] = nil
		self['TempRefs'] = nil
	end

	table.clear(self['F'])
	self['Active'] = false
end

ESP:Init()

return ESP
