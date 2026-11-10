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
local BarTime = 0.2

local Clock = os.clock
local Floor = math.floor
local Max = math.max
local Min = math.min
local Abs = math.abs
local Clamp = math.clamp
local Tan = math.tan
local Rad = math.rad
local Huge = math.huge

local White = Rgb(255, 255, 255)
local Black = Rgb(0, 0, 0)
local Miter = Enum.LineJoinMode.Miter
local BorderMode = Enum.ApplyStrokeMode.Border
local InnerStroke = Enum.BorderStrokePosition.Inner

local HS = Enum.HumanoidStateType
local Ragdolled = { [HS.Ragdoll] = true, [HS.Physics] = true, [HS.GettingUp] = true, [HS.FallingDown] = true }

local ESP = {
	Objects = {},
	Conns = {},
	F = {},
	Saved = {},
	Font = Font.new('rbxasset://fonts/families/fs Tahoma Bold 8px.json'),
	Size = 12,
	Height = 6,
	Width = 4,

	Flags = {
		['Enabled'] = false, ['Team_Check'] = false, ['Max_Distance'] = 0,
		['Names'] = false, ['Name_Type'] = 'Both', ['Name_Color'] = White,
		['Boxes'] = false, ['Box_Type'] = '2D', ['Box_Dynamic'] = false, ['Box_Color'] = White,
		['Fill'] = false, ['Fill_Color'] = White, ['Fill_Type'] = 'Full', ['Fill_Half'] = 'Top', ['Fill_Static'] = false,
		['Fill_Rotation'] = false, ['Fill_Transparency'] = 0.5, ['Fill_Spin'] = false, ['Fill_Spin_Speed'] = 60,
		['Head'] = false, ['Head_Color'] = White, ['Head_Fill'] = false, ['Head_Fill_Color'] = Rgb(255, 0, 75), ['Head_Fill_Type'] = 'Full',
		['Head_Fill_Static'] = false, ['Head_Fill_Transparency'] = 0.5, ['Head_Spin'] = false, ['Head_Spin_Speed'] = 60,
		['Head_Outline'] = true, ['Head_Outline_Color'] = Black,
		['Healthbar'] = false, ['Health_Text'] = false, ['Health_Text_Dynamic'] = false, ['Health_Text_Color'] = Rgb(0, 255, 80),
		['Health_High'] = Rgb(0, 255, 80), ['Health_Mid'] = Rgb(255, 230, 0), ['Health_Low'] = Rgb(255, 40, 40),
		['Armorbar'] = false, ['Armor_Text'] = false, ['Armor_Color'] = Rgb(0, 85, 255),
		['Distance'] = false, ['Distance_Color'] = White,
		['Weapon'] = false, ['Weapon_Color'] = White,
		['EspFlags'] = false, ['Flag_Color'] = White,
		['Skeletons'] = false, ['Skeleton_Color'] = White, ['Skeleton_Outline'] = true, ['Skeleton_Outline_Color'] = Black,
		['Highlights'] = false, ['Highlight_Fill'] = White, ['Highlight_Fill_Transparency'] = 0.5, ['Highlight_Outline'] = true,
		['Highlight_Outline_Color'] = White, ['Highlight_Outline_Transparency'] = 0, ['Highlight_Depth'] = 'AlwaysOnTop',
		['Tracers'] = false, ['Tracer_Color'] = White, ['Tracer_Origin'] = 'Bottom', ['Tracer_Thickness'] = 1,
		['Tracer_Outline'] = true, ['Tracer_Outline_Color'] = Black,
		['Look'] = false, ['Look_Color'] = White, ['Look_Outline'] = true, ['Look_Outline_Color'] = Black,
		['Look_Length'] = 3, ['Look_Thickness'] = 1,
	},
}

-- // Lookups
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

local FillRot = { Top = 90, Bottom = -90 }
local FlagOrder = { 'Ragdoll', 'Falling', 'Jumping', 'Climbing', 'Swimming', 'Seated', 'Flying', 'Running' }
local FlagHold = 0.1
local DepthMode = {
	AlwaysOnTop = Enum.HighlightDepthMode.AlwaysOnTop,
	Occluded = Enum.HighlightDepthMode.Occluded,
}

local BodyPart = {}
for _, Name in {
	'Head', 'Torso', 'UpperTorso', 'LowerTorso', 'LeftArm', 'RightArm', 'Left Arm', 'Right Arm',
	'LeftLeg', 'RightLeg', 'Left Leg', 'Right Leg', 'LeftUpperArm', 'RightUpperArm', 'LeftLowerArm', 'RightLowerArm',
	'LeftHand', 'RightHand', 'LeftUpperLeg', 'RightUpperLeg', 'LeftLowerLeg', 'RightLowerLeg', 'LeftFoot', 'RightFoot',
} do
	BodyPart[Name] = true
end

local BoxDrop = Vec3(0, 0.25, 0)
local BoxVerts = {
	Vec3(-1, -1, -1), Vec3(-1, 1, -1), Vec3(-1, 1, 1), Vec3(-1, -1, 1),
	Vec3(1, -1, -1), Vec3(1, 1, -1), Vec3(1, 1, 1), Vec3(1, -1, 1),
}

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
	if type(Node) == 'string' then
		return Node
	end
	return Node[1]
end

local function JointPos(Part, Node)
	if type(Node) == 'string' then
		return Part.Position
	end
	return Part.CFrame * Node[2]
end

-- // Font
local function SnapAdvances(Data)
	local function ReadU16(At)
		local High, Low = string.byte(Data, At + 1, At + 2)
		return High * 256 + Low
	end

	if #Data < 12 or string.sub(Data, 1, 4) ~= '\0\1\0\0' then
		return Data
	end

	local Tables = {}
	for Index = 0, ReadU16(4) - 1 do
		local Entry = 12 + Index * 16
		Tables[string.sub(Data, Entry + 1, Entry + 4)] = ReadU16(Entry + 8) * 65536 + ReadU16(Entry + 10)
	end

	local Hhea, Hmtx = Tables['hhea'], Tables['hmtx']
	if not Hhea or not Hmtx then
		return Data
	end

	local Pieces, Copied = {}, 0
	for Glyph = 0, ReadU16(Hhea + 34) - 1 do
		local At = Hmtx + Glyph * 4
		local Advance = ReadU16(At)
		local Snapped = Floor(Advance / 64 + 0.5) * 64

		if Snapped ~= Advance then
			table.insert(Pieces, string.sub(Data, Copied + 1, At))
			table.insert(Pieces, string.char(Floor(Snapped / 256), Snapped % 256))
			Copied = At + 2
		end
	end
	table.insert(Pieces, string.sub(Data, Copied + 1))

	return table.concat(Pieces)
end

local function LoadFont()
	local Shared = getgenv().CustomFontUrl
	if Shared then
		return Font.new(Shared)
	end

	local Folder = 'Prefire/Fonts'
	local SourcePath = Folder .. '/fs Tahoma Bold 8px.ttf'
	local TtfPath = Folder .. '/fs Tahoma Bold 8px Snapped.ttf'
	local JsonPath = Folder .. '/fs Tahoma Bold 8px Snapped.json'

	for _, Path in { 'Prefire', Folder } do
		if not isfolder(Path) then
			makefolder(Path)
		end
	end

	if not isfile(TtfPath) then
		local Source = isfile(SourcePath) and readfile(SourcePath)
			or game:HttpGet('https://raw.githubusercontent.com/viitals/Fonts/main/fs%20Tahoma%208px%20Regular.ttf')
		writefile(SourcePath, Source)
		writefile(TtfPath, SnapAdvances(Source))
	end

	writefile(JsonPath, Http:JSONEncode({
		name = 'fs Tahoma Bold 8px',
		faces = {
			{ name = 'Regular', weight = 400, style = 'normal', assetId = getcustomasset(TtfPath) },
		},
	}))

	local Url = getcustomasset(JsonPath)
	getgenv().CustomFontUrl = Url
	return Font.new(Url)
end

local Ok, Tahoma = pcall(LoadFont)
if Ok then
	ESP['Font'] = Tahoma
end

-- // Helpers
local function SampleGrad(Colors, Stops, T)
	T = Clamp(T, 0, 1)
	local Last = #Colors
	if Last == 0 then
		return White
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

local function Inst(Class, Props, Defaults)
	local Obj = Instance.new(Class)
	if Defaults then
		for Key, Val in Defaults do
			if Props[Key] == nil then
				Obj[Key] = Val
			end
		end
	end
	for Key, Val in Props do
		Obj[Key] = Val
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

local function Update(Store, Key, Obj, Prop, Val)
	if Store[Key] ~= Val then
		Store[Key] = Val
		Obj[Prop] = Val
	end
end

local function FitCentered(Label, Width, Store)
	local Odd = (Width - Floor(Label.TextBounds.X + 0.5)) % 2 == 1
	if Store[Label] ~= Odd then
		Store[Label] = Odd
		local Size = Label.Size
		Label.Size = Pos(Size.X.Scale, Odd and -1 or 0, Size.Y.Scale, Size.Y.Offset)
	end
end

local function FitAnchored(Label, Store)
	local Odd = Floor(Label.TextBounds.X + 0.5) % 2 == 1
	if Store[Label] ~= Odd then
		Store[Label] = Odd
		Label.AnchorPoint = Vec(Odd and 0 or 0.5, 0.5)
		Label.Size = Pos(0, Odd and 1 or 0, 0, 12)
	end
end

local function Unwrap(Val)
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

local function Paint(Frame, Grad, On, Cfg, State)
	if not On then
		Update(State, 'Trans', Frame, 'BackgroundTransparency', 1)
		Update(State, 'GradOn', Grad, 'Enabled', false)
		return
	end

	local Col = Cfg['Col']
	Update(State, 'Col', Frame, 'BackgroundColor3', Col)
	Update(State, 'Trans', Frame, 'BackgroundTransparency', Cfg['Trans'])
	Update(State, 'GradOn', Grad, 'Enabled', not Cfg['Static'])

	if Cfg['Static'] then
		return
	end

	if State['Last'] ~= Col then
		State['Last'] = Col
		Grad.Color = ColorSequence.new(Col)
	end

	Update(State, 'Seq', Grad, 'Transparency', Cfg['Type'] == 'Half' and FillTrans['Half'] or FillTrans['Full'])
	Update(State, 'Rot', Grad, 'Rotation', Cfg['Rot'])
end

local function Stroke(Parent, Border)
	return Inst('UIStroke', {
		Parent = Parent,
		ApplyStrokeMode = Border and BorderMode or nil,
		Color = Black,
		Thickness = 1,
		LineJoinMode = Miter,
	})
end

local function BoxStrokes(Frame, InlineColor, OutlineColor)
	local Inline = Inst('UIStroke', {
		Parent = Frame,
		ApplyStrokeMode = BorderMode,
		BorderOffset = UDim.new(0, -1),
		BorderStrokePosition = InnerStroke,
		Color = InlineColor,
		LineJoinMode = Miter,
		Thickness = 1,
	})

	local Outline = Inst('UIStroke', {
		Parent = Frame,
		ApplyStrokeMode = BorderMode,
		BorderStrokePosition = InnerStroke,
		Color = OutlineColor,
		LineJoinMode = Miter,
		Thickness = 3,
		ZIndex = 0,
	})

	return Inline, Outline
end

-- // Drawing lines
local function GuiLine(Parent, Z)
	local Frame = Inst('Frame', {
		Parent = Parent,
		AnchorPoint = Vec(0.5, 0.5),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 10 + Z,
	})
	local Ends = { From = Vec(0, 0), To = Vec(0, 0), Thickness = 1 }

	return setmetatable({}, {
		__index = {
			Remove = function()
				Frame:Destroy()
			end,
		},
		__newindex = function(_, Key, Val)
			if Key == 'Color' then
				Frame.BackgroundColor3 = Val
			elseif Key == 'Visible' then
				Frame.Visible = Val
			elseif Ends[Key] ~= nil then
				Ends[Key] = Val

				local A, B, Thick = Ends['From'], Ends['To'], Ends['Thickness']
				local X1, Y1 = Floor(A.X) + 0.5, Floor(A.Y) + 0.5
				local X2, Y2 = Floor(B.X) + 0.5, Floor(B.Y) + 0.5
				local DX, DY = X2 - X1, Y2 - Y1
				local Length = Floor(math.sqrt(DX * DX + DY * DY) + 0.5) + Thick
				local CX, CY = (X1 + X2) * 0.5, (Y1 + Y2) * 0.5
				local PX, PY = Floor(CX), Floor(CY)

				Frame.Position = Off(PX, PY)
				Frame.Size = Off(Length, Thick)
				Frame.AnchorPoint = Vec(0.5 - (CX - PX) / Length, 0.5 - (CY - PY) / Thick)
				Frame.Rotation = math.deg(math.atan2(DY, DX))
			end
		end,
	})
end

local function Line(Thick, Z, Parent)
	local Obj = Parent and GuiLine(Parent, Z) or Drawing.new('Line')
	Obj.Thickness = Thick
	Obj.Transparency = 0
	Obj.ZIndex = Z
	Obj.Visible = false

	return { Obj = Obj, Vis = false, Thick = Thick, X1 = -1, Y1 = -1, X2 = -1, Y2 = -1 }
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

	Update(Item, 'Col', Obj, 'Color', Col)
	Update(Item, 'Thick', Obj, 'Thickness', Thick)
	Update(Item, 'Vis', Obj, 'Visible', true)
end

local function NewPair(Parent)
	return { Back = Line(3, 1, Parent), Front = Line(1, 2, Parent) }
end

local function HidePair(Pair)
	if Pair then
		HideLine(Pair['Front'])
		HideLine(Pair['Back'])
	end
end

local function KillPair(Pair)
	Pair['Front']['Obj']:Remove()
	Pair['Back']['Obj']:Remove()
end

local function DrawPair(Pair, X1, Y1, X2, Y2, Col, Thick, Outline, OutCol)
	if Outline then
		StrokeLine(Pair['Back'], X1, Y1, X2, Y2, OutCol, Thick + 2)
	else
		HideLine(Pair['Back'])
	end
	StrokeLine(Pair['Front'], X1, Y1, X2, Y2, Col, Thick)
end

-- // Flags + projection
function ESP:Source(Key)
	local Ext = self['ExtFlags']
	local Val = Ext and Ext[Key]
	if Val == nil then
		return self['Flags'][Key]
	end
	return Val
end

function ESP:Get(Key)
	local Val = self['F'][Key]
	if Val ~= nil then
		return Val
	end
	return Unwrap(self:Source(Key))
end

function ESP:Color(Key, Fallback)
	local Val = self:Get(Key)
	return Val ~= nil and Val or Fallback
end

function ESP:Raw(Key)
	local Val = self:Source(Key)
	if type(Val) == 'table' and Val['Get'] then
		Val = Val:Get()
	end
	return Val
end

function ESP:NameStr(Data)
	local Mode = self['F']['Name_Type']
	if Mode == 'Display' then
		return Data['Display']
	elseif Mode == 'Username' then
		return Data['Name']
	end
	return Data['Both']
end

function ESP:Wts(World)
	local V, On = Cam:WorldToViewportPoint(World)
	return Vec(V.X, V.Y), On, V.Z
end

function ESP:View()
	return Cam.CFrame, Cam.ViewportSize, Cam.FieldOfView
end

function ESP:Mouse()
	return Input:GetMouseLocation()
end

function ESP:Project(World)
	local V, On = Cam:WorldToViewportPoint(World)
	return V.X, V.Y, On, V.Z
end

function ESP:IsRagdolled(Hum, Char)
	if not Hum or not Ragdolled[Hum:GetState()] or Hum.Sit or Hum.SeatPart then
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
	local H = Max(Floor((self['Height'] / Depth) * self['Px'] + 0.5), 4)
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

		MinX3, MaxX3 = Min(MinX3, A.X, B.X), Max(MaxX3, A.X, B.X)
		MinY3, MaxY3 = Min(MinY3, A.Y, B.Y), Max(MaxY3, A.Y, B.Y)
		MinZ3, MaxZ3 = Min(MinZ3, A.Z, B.Z), Max(MaxZ3, A.Z, B.Z)
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
			MinX, MaxX = Min(MinX, Sx), Max(MaxX, Sx)
			MinY, MaxY = Min(MinY, Sy), Max(MaxY, Sy)
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

-- // Template
function ESP:Build()
	local Clear = { BackgroundTransparency = 1 }
	local TextBase = { BackgroundTransparency = 1, FontFace = self['Font'], Text = '', TextColor3 = White, TextSize = 12 }

	local function Group(Props)
		return Inst('Frame', Props, Clear)
	end

	local function Label(Props)
		local Obj = Inst('TextLabel', Props, TextBase)
		Stroke(Obj)
		return Obj
	end

	local function List(Parent, Props)
		Props['Parent'] = Parent
		Props['SortOrder'] = Enum.SortOrder.LayoutOrder
		return Inst('UIListLayout', Props)
	end

	local Holder = Inst('Frame', {
		BackgroundColor3 = White,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Size = Off(250, 250),
	})

	-- // Left (health)
	local Left = Group({
		Parent = Holder,
		AnchorPoint = Vec(1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = Pos(0, -2, 0, 0),
		Size = Pos(0, 1, 1, 0),
	})

	List(Left, {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 2),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		VerticalFlex = Enum.UIFlexAlignment.Fill,
	})

	Inst('UIPadding', { Parent = Left, PaddingBottom = UDim.new(0, 1), PaddingTop = UDim.new(0, 1) })

	local BarHolder = Group({ Parent = Left, AutomaticSize = Enum.AutomaticSize.X, Size = Pos(0, 5, 1, 0) })
	List(BarHolder, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, -10) })

	local HealthBack = Inst('Frame', { Parent = BarHolder, BackgroundColor3 = Black, BorderSizePixel = 0, Size = Pos(0, 4, 1, 0) })

	local HealthBar = Inst('Frame', {
		Parent = HealthBack,
		BackgroundColor3 = White,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Position = Pos(0, 1, 0.25, 0),
		Size = Pos(1, -2, 0.75, 0),
	})
	Stroke(HealthBar, true)

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

	local HealthText = Label({
		Parent = HealthBar,
		AnchorPoint = Vec(0.5, 0.5),
		Position = Pos(0.5, 0, 0, 0),
		Size = Pos(0, 0, 0, 12),
		TextColor3 = Rgb(0, 255, 80),
	})

	-- // Up (name)
	local Up = Group({
		Parent = Holder,
		AnchorPoint = Vec(0, 1),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = Pos(0, 0, 0, -2),
		Size = Pos(1, 0, 0, 1),
	})
	List(Up, {})

	local TitleHolder = Group({
		Parent = Up,
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = Pos(0, 1, 0, -5),
		Size = Pos(1, -2, 0, 0),
	})

	local NameText = Label({ Parent = TitleHolder, AutomaticSize = Enum.AutomaticSize.Y, Size = Pos(1, 0, 1, 0) })

	-- // Down (distance, weapon, armor)
	local Down = Group({
		Parent = Holder,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = Pos(0, -1, 1, 3),
		Size = Pos(1, 2, 0, 0),
	})

	local BottomList = Group({
		Parent = Down,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = Pos(0, 2, 0, 0),
		Size = Pos(1, -4, 0, 0),
	})
	List(BottomList, { Padding = UDim.new(0, 3) })

	local DistanceText = Label({
		Parent = BottomList,
		LayoutOrder = 1,
		Size = Pos(1, 0, 0, 12),
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	local WeaponText = Label({
		Parent = BottomList,
		LayoutOrder = 2,
		Size = Pos(1, 0, 0, 12),
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	local ArmorHolder = Group({
		Parent = BottomList,
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 100,
		Size = Pos(1, 0, 0, 0),
	})

	local ArmorBack = Inst('Frame', { Parent = ArmorHolder, BackgroundColor3 = Black, BorderSizePixel = 0, Size = Pos(1, 0, 0, 2) })
	Stroke(ArmorBack, true)

	local ArmorBar = Inst('Frame', {
		Parent = ArmorBack,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = White,
		BorderSizePixel = 0,
		Size = Pos(0.5, 0, 1, 0),
	})
	Stroke(ArmorBar, true)

	Inst('UIGradient', { Parent = ArmorBar, Rotation = 90, Color = ColorSequence.new(Rgb(0, 85, 255)) })

	local ArmorText = Label({
		Parent = ArmorBar,
		AnchorPoint = Vec(0.5, 0.5),
		Position = Pos(1, 0, 0, 1),
		Size = Pos(0, 0, 0, 12),
		TextColor3 = Rgb(0, 85, 255),
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	-- // Box strokes
	local Inline, Outline = BoxStrokes(Holder, Rgb(212, 213, 255), Black)

	Inst('UIGradient', {
		Parent = Inline,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, White),
			ColorSequenceKeypoint.new(1, Rgb(199, 199, 199)),
		}),
	})

	-- // Right (flags)
	local Right = Group({
		Parent = Holder,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = Pos(1, 2, 0, 0),
		Size = Pos(0, 1, 1, 0),
	})

	Inst('UIPadding', { Parent = Right, PaddingTop = UDim.new(0, -3) })

	local FlagsHolder = Group({
		Parent = Right,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = Pos(0, 2, 0, 1),
		Size = Pos(0, 0, 1, -2),
	})
	List(FlagsHolder, {})

	local FlagText = Label({
		Parent = FlagsHolder,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = Pos(1, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	-- // Fill + corners
	local HolderGrad = Inst('UIGradient', {
		Parent = Holder,
		Rotation = -90,
		Color = ColorSequence.new(Rgb(212, 213, 255)),
		Transparency = FillTrans['Full'],
	})

	local Corners = Inst('Frame', {
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
		Edges[I] = Inst('Frame', {
			Parent = Corners,
			BorderSizePixel = 0,
			BackgroundColor3 = White,
			Position = Data[1],
			Size = Data[2],
			AnchorPoint = Data[3],
			Rotation = Data[4],
		})
		Stroke(Edges[I])
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

function ESP:BuildBox(Parent, InlineColor, OutlineColor)
	local Frame = Inst('Frame', { Parent = Parent, BackgroundTransparency = 1, BorderSizePixel = 0 })
	local Inline, Outline = BoxStrokes(Frame, InlineColor or White, OutlineColor or Black)
	return Frame, Inline, Outline
end

-- // Components
local Base = {}
Base.__index = Base

local function Class(Parent)
	local Object = setmetatable({}, { __index = Parent or Base })
	Object.__index = Object
	return Object
end

function Base:New(Refs)
	return setmetatable({ Items = {}, Refs = Refs }, self)
end

function Base:Kill()
	for _, Item in self['Items'] do
		if typeof(Item) == 'Instance' then
			Item:Destroy()
		end
	end
	table.clear(self['Items'])
end

ESP.Box = Class()

function ESP.Box:Draw(Esp, On, Data)
	local Refs, F = self['Refs'], Esp['F']
	local Is2D = On and (F['Box_Type'] or '2D') == '2D'

	Set(Refs['Inline'], 'Enabled', Is2D)
	Set(Refs['Outline'], 'Enabled', Is2D)
	Set(Refs['Corners'], 'Visible', On and not Is2D)

	if On and not Is2D then
		local Across, Down = Floor(Data['W'] * 0.3 + 0.5), Floor(Data['H'] * 0.3 + 0.5)
		if self['Across'] ~= Across or self['Down'] ~= Down then
			self['Across'], self['Down'] = Across, Down
			for Index, Edge in Refs['Edges'] do
				Edge.Size = Index % 2 == 1 and Off(Across, 1) or Off(1, Down)
			end
		end
	end

	if not On or self['Col'] == F['Box_Color'] then
		return
	end

	local Col = F['Box_Color']
	self['Col'] = Col
	Refs['Inline'].Color = Col
	for _, Edge in Refs['Edges'] do
		Edge.BackgroundColor3 = Col
	end
end

ESP.Fill = Class()

function ESP.Fill:Draw(Esp, On)
	Paint(self['Refs']['Holder'], self['Refs']['HolderGrad'], On, Esp['FCfg'], self)
end

ESP.Text = Class()

local Centered = { 'NameText', 'DistanceText', 'WeaponText' }

function ESP.Text:New(Refs)
	local Self = Base.New(self, Refs)
	for _, Key in Centered do
		local Label = Refs[Key]
		Label:GetPropertyChangedSignal('TextBounds'):Connect(function()
			FitCentered(Label, Self['Width'] or 0, Self)
		end)
	end
	return Self
end

function ESP.Text:Draw(Esp, Data)
	local F, Refs = Esp['F'], self['Refs']

	local Width = Data['W'] - 2
	if self['Width'] ~= Width then
		self['Width'] = Width
		for _, Key in Centered do
			FitCentered(Refs[Key], Width, self)
		end
	end

	local NameLabel = Refs['NameText']
	Set(NameLabel, 'Visible', F['Names'])
	if F['Names'] then
		Update(self, 'NameCol', NameLabel, 'TextColor3', F['Name_Color'])
		Update(self, 'NameStr', NameLabel, 'Text', Esp:NameStr(Data))
	end

	local DistLabel = Refs['DistanceText']
	Set(DistLabel, 'Visible', F['Distance'])
	if F['Distance'] then
		Update(self, 'DistCol', DistLabel, 'TextColor3', F['Distance_Color'])
		if self['Dist'] ~= Data['Dist'] then
			self['Dist'] = Data['Dist']
			DistLabel.Text = Data['Dist'] .. ' st'
		end
	end

	local Tool = Data['Weapon']
	local WeaponOn = F['Weapon'] and Tool ~= ''
	local WeaponLabel = Refs['WeaponText']
	Set(WeaponLabel, 'Visible', WeaponOn)
	if WeaponOn then
		Update(self, 'WeaponCol', WeaponLabel, 'TextColor3', F['Weapon_Color'])
		Update(self, 'Tool', WeaponLabel, 'Text', Tool)
	end
end

ESP.Head = Class()

function ESP.Head:Boot(Gui)
	if self['Root'] then
		return
	end

	local Root = Inst('Frame', {
		Parent = Gui,
		AnchorPoint = Vec(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = Off(50, 50),
		Visible = false,
	})
	Inst('UICorner', { Parent = Root, CornerRadius = UDim.new(1, 0) })

	self['Stroke'] = Inst('UIStroke', { Parent = Root, Color = White, Thickness = 1 })
	self['Outline'] = Inst('UIStroke', {
		Parent = Root,
		ApplyStrokeMode = BorderMode,
		BorderOffset = UDim.new(0, -1),
		BorderStrokePosition = Enum.BorderStrokePosition.Outer,
		Color = Black,
		Thickness = 3,
		ZIndex = 0,
	})
	self['Inner'] = Inst('Frame', { Parent = Root, BackgroundColor3 = White, BorderSizePixel = 0, Size = Pos(1, 0, 1, 0) })
	Inst('UICorner', { Parent = self['Inner'], CornerRadius = UDim.new(1, 0) })

	self['Grad'] = Inst('UIGradient', {
		Parent = self['Inner'],
		Rotation = -90,
		Color = ColorSequence.new(Rgb(255, 0, 75)),
		Transparency = FillTrans['Full'],
	})

	self['Root'] = Root
	self['Vis'] = false
	table.insert(self['Items'], Root)
end

function ESP.Head:Hide()
	if self['Vis'] then
		self['Vis'] = false
		self['Root'].Visible = false
	end
end

function ESP.Head:Kill()
	Base.Kill(self)
	table.clear(self)
	self['Items'] = {}
end

function ESP.Head:Draw(Esp, On, Data)
	local Part = Data['Head']
	if not On or not Part then
		self:Hide()
		return
	end

	local X, Y, Visible, Z = Esp:Project(Part.Position)
	if not Visible or Z <= 0 then
		self:Hide()
		return
	end

	self:Boot(Esp['Gui'])

	local Cfg, Root = Esp['HeadCfg'], self['Root']
	local Radius = Max(Part.Size.X * 0.5 / Z * Esp['Px'], 2)
	local Dia = Max(Floor(Radius + 0.5) * 2, 2)
	X, Y = Floor(X + 0.5), Floor(Y + 0.5)

	Update(self, 'Vis', Root, 'Visible', true)

	if self['X'] ~= X or self['Y'] ~= Y then
		self['X'] = X
		self['Y'] = Y
		Root.Position = Off(X, Y)
	end

	if self['Dia'] ~= Dia then
		self['Dia'] = Dia
		Root.Size = Off(Dia, Dia)
	end

	local Ring = Cfg['Stroke']
	local Outlined = Ring and Cfg['Outline'] and true or false
	Set(self['Stroke'], 'Enabled', Ring and true or false)
	Set(self['Outline'], 'Enabled', Outlined)

	if Ring then
		Update(self, 'Line', self['Stroke'], 'Color', Ring)
	end
	if Outlined then
		Update(self, 'OutCol', self['Outline'], 'Color', Cfg['OutlineColor'] or Black)
	end

	Paint(self['Inner'], self['Grad'], Cfg['Fill'], Cfg, self)
end

ESP.Bar = Class()

function ESP.Bar:New(Back, Fill, Text, Vert)
	local Self = Base.New(self)
	Self['Back'] = Back
	Self['Fill'] = Fill
	Self['Text'] = Text
	Self['Grad'] = Fill:FindFirstChildOfClass('UIGradient')
	Self['Vert'] = Vert

	if Text then
		Text:GetPropertyChangedSignal('TextBounds'):Connect(function()
			FitAnchored(Text, Self)
		end)
	end

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
	local Points = { ColorSequenceKeypoint.new(0, SampleGrad(Colors, Stops, From)) }

	for I = 1, #Colors do
		local T = Stops and Stops[I] or ((I - 1) / Max(#Colors - 1, 1))
		if T > From + 0.001 and T < To - 0.001 then
			Points[#Points + 1] = ColorSequenceKeypoint.new((T - From) / Span, Colors[I])
		end
	end

	Points[#Points + 1] = ColorSequenceKeypoint.new(1, SampleGrad(Colors, Stops, To))
	Grad.Color = ColorSequence.new(Points)
end

function ESP.Bar:Draw(On, Pct, Val, Cfg, Span)
	Set(self['Back'], 'Visible', On)
	Set(self['Back'].Parent, 'Visible', On)

	if not On then
		return
	end

	Pct = Clamp(Pct or 0, 0, 1)
	local Vert = self['Vert']
	self:SetGrad(Cfg, Vert and 1 - Pct or 0, 1)

	local Now = Clock()
	if self['To'] == nil then
		self['From'], self['To'], self['Start'] = Pct, Pct, Now
	elseif Abs(self['To'] - Pct) >= 0.01 then
		self['From'], self['To'], self['Start'] = self['Shown'], Pct, Now
	end

	local Alpha = Min((Now - self['Start']) / BarTime, 1)
	local Shown = self['From'] + (self['To'] - self['From']) * (1 - (1 - Alpha) ^ 2)
	local Filled = Floor(Span * Shown + 0.5)
	self['Shown'] = Shown

	if self['Filled'] ~= Filled or self['Span'] ~= Span then
		self['Filled'], self['Span'] = Filled, Span
		if Vert then
			self['Fill'].Size = Pos(1, -2, 0, Filled)
			self['Fill'].Position = Pos(0, 1, 0, Span - Filled)
		else
			self['Fill'].Size = Pos(0, Filled, 1, 0)
		end
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
	Update(self, 'Col', Label, 'TextColor3', Col)

	if self['Val'] ~= Val then
		self['Val'] = Val
		Label.Text = tostring(Val)
		FitAnchored(Label, self)
	end
end

ESP.Flag = Class()

function ESP.Flag:New(Refs)
	local Self = Base.New(self, Refs)
	Refs['FlagText'].Visible = false
	Self['Labels'] = {}
	Self['Hold'] = {}
	return Self
end

function ESP.Flag:Label(Name, Order, Col)
	local Entry = self['Labels'][Name]
	if not Entry then
		local Lbl = self['Refs']['FlagText']:Clone()
		Lbl.Name = '\0'
		Lbl.Text = Name
		Lbl.Parent = self['Refs']['FlagsHolder']
		Entry = { Lbl = Lbl, Vis = false }
		self['Labels'][Name] = Entry
		table.insert(self['Items'], Lbl)
	end

	local Lbl = Entry['Lbl']
	Update(Entry, 'Order', Lbl, 'LayoutOrder', Order)
	Update(Entry, 'Col', Lbl, 'TextColor3', Col)
	Update(Entry, 'Vis', Lbl, 'Visible', true)
end

function ESP.Flag:Draw(Esp, On, Data)
	Set(self['Refs']['FlagsHolder'], 'Visible', On)
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
		elseif self['Labels'][Name] then
			local Entry = self['Labels'][Name]
			Update(Entry, 'Vis', Entry['Lbl'], 'Visible', false)
		end
	end
end

-- // Finobe's r15 skeleton mapping system | https://github.com/i77lhm
ESP.Skel = Class()

function ESP.Skel:New()
	local Self = Base.New(self)
	Self['Map'] = {}
	Self['Stamp'] = 0
	return Self
end

function ESP.Skel:Hide()
	local Pairs = self['Pairs']
	if Pairs then
		for I = 1, BoneMax do
			HidePair(Pairs[I])
		end
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
		self:Hide()
		return
	end

	if not self['Pairs'] then
		self['Pairs'] = table.create(BoneMax)
		for I = 1, BoneMax do
			self['Pairs'][I] = NewPair(Esp['LineParent'])
		end
	end

	local F, Pairs = Esp['F'], self['Pairs']
	local Map = self:Build(Data['Char'], Esp['Now'])

	for I = 1, BoneMax do
		local Bone = Map[I]
		local X1, Y1, OnA, X2, Y2, OnB
		if Bone then
			X1, Y1, OnA = Esp:Project(JointPos(Bone[1], Bone[2]))
			X2, Y2, OnB = Esp:Project(JointPos(Bone[3], Bone[4]))
		end

		if OnA and OnB then
			DrawPair(Pairs[I], X1, Y1, X2, Y2, F['Skeleton_Color'], 1, F['Skeleton_Outline'], F['Skeleton_Outline_Color'])
		else
			HidePair(Pairs[I])
		end
	end
end

function ESP.Skel:Kill()
	if self['Pairs'] then
		for _, Pair in self['Pairs'] do
			KillPair(Pair)
		end
		self['Pairs'] = nil
	end
	table.clear(self['Map'])
end

ESP.HL = Class()

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
		self:Hide()
		return
	end

	if not self['Inst'] then
		self['Inst'] = Inst('Highlight', {
			Parent = Hui,
			Enabled = false,
			FillColor = White,
			FillTransparency = 0.5,
			OutlineColor = Black,
			OutlineTransparency = 0,
			DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		})
		table.insert(self['Items'], self['Inst'])
	end

	local F, Obj = Esp['F'], self['Inst']
	local OutTrans = F['Highlight_Outline'] and (F['Highlight_Outline_Transparency'] or 0) or 1

	Update(self, 'Char', Obj, 'Adornee', Char)
	Update(self, 'Fill', Obj, 'FillColor', F['Highlight_Fill'])
	Update(self, 'Trans', Obj, 'FillTransparency', F['Highlight_Fill_Transparency'] or 0.5)
	Update(self, 'OutCol', Obj, 'OutlineColor', F['Highlight_Outline_Color'])
	Update(self, 'OutTrans', Obj, 'OutlineTransparency', OutTrans)
	Update(self, 'Depth', Obj, 'DepthMode', DepthMode[F['Highlight_Depth']] or DepthMode['AlwaysOnTop'])
	Update(self, 'On', Obj, 'Enabled', true)
end

local Single = Class()

function Single:Hide()
	HidePair(self['Pair'])
end

function Single:Kill()
	if self['Pair'] then
		KillPair(self['Pair'])
		self['Pair'] = nil
	end
end

ESP.Trace = Class(Single)

function ESP.Trace:Draw(Esp, On, Data)
	if not On then
		self:Hide()
		return
	end

	self['Pair'] = self['Pair'] or NewPair(Esp['LineParent'])

	local F = Esp['F']
	local X2 = Data['X'] + Data['W'] * 0.5
	local Y2 = Data['Y'] + Data['H'] * 0.5
	DrawPair(self['Pair'], Esp['FromX'], Esp['FromY'], X2, Y2, F['Tracer_Color'], F['Tracer_Thickness'] or 1, F['Tracer_Outline'], F['Tracer_Outline_Color'])
end

ESP.Look = Class(Single)

function ESP.Look:Draw(Esp, On, Data)
	local Head = Data['Head']
	if not On or not Head then
		self:Hide()
		return
	end

	local F, CF = Esp['F'], Head.CFrame
	local X1, Y1, OnA = Esp:Project(CF.Position)
	local X2, Y2, OnB = Esp:Project(CF.Position + CF.LookVector * (F['Look_Length'] or 3))

	if not OnA and not OnB then
		self:Hide()
		return
	end

	self['Pair'] = self['Pair'] or NewPair(Esp['LineParent'])
	DrawPair(self['Pair'], X1, Y1, X2, Y2, F['Look_Color'], F['Look_Thickness'] or 1, F['Look_Outline'], F['Look_Outline_Color'])
end

-- // Player object
local Lazy = { 'Skel', 'HL', 'Head', 'Trace', 'Look' }
local Templated = { 'Box', 'Fill', 'Text', 'Health', 'Armor', 'Flag' }

ESP.Object = {}
ESP.Object.__index = ESP.Object

function ESP.Object:New(Plr, Esp)
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

	for _, Key in Lazy do
		Self[Key] = (Esp or ESP)[Key]:New()
	end

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
			Refs['Edges'] = {}
			for I, Edge in Obj do
				Refs['Edges'][I] = Lookup[Edge]
			end
		else
			Refs[Key] = Lookup[Obj]
		end
	end

	self['Box'] = ESP.Box:New(Refs)
	self['Fill'] = ESP.Fill:New(Refs)
	self['Text'] = ESP.Text:New(Refs)
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
		self['Part'] = Char:FindFirstChild('HumanoidRootPart')
			or Char:FindFirstChild('UpperTorso')
			or Char:FindFirstChild('Torso')
			or Char:FindFirstChild('LowerTorso')
			or Char:FindFirstChild('Head')
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
	elseif Tool.Name:sub(1, 1) == '[' and Tool.Name:sub(-1) == ']' then
		self['ToolStr'] = Tool.Name
	else
		self['ToolStr'] = '[' .. Tool.Name .. ']'
	end

	return self['ToolStr']
end

function ESP.Object:Hide(KeepHighlight)
	if self['Ready'] and self['Vis'] then
		self['Vis'] = false
		self['Root'].Visible = false
	end

	for _, Key in Lazy do
		if Key ~= 'HL' or not KeepHighlight then
			self[Key]:Hide()
		end
	end
end

function ESP.Object:Render(Esp, Data)
	self:Boot(Esp)

	local F, Root = Esp['F'], self['Root']
	local X, Y = Data['X'], Data['Y']
	local W, H = Data['W'], Data['H']

	Update(self, 'Vis', Root, 'Visible', true)

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

	self['Box']:Draw(Esp, F['Boxes'], Data)
	self['Fill']:Draw(Esp, F['Fill'])
	self['Text']:Draw(Esp, Data)
	self['Health']:Draw(F['Healthbar'], Data['Health'], Data['HealthVal'], Esp['HCfg'], H - 2)
	self['Armor']:Draw(F['Armorbar'], 1, 100, Esp['ACfg'], W - 2)
	self['Flag']:Draw(Esp, F['EspFlags'], Data)
	self['Skel']:Draw(Esp, F['Skeletons'], Data)
	self['HL']:Draw(Esp, F['Highlights'], Data['Char'], self['Hum'])
	self['Head']:Draw(Esp, F['Head'], Data)
	self['Trace']:Draw(Esp, F['Tracers'], Data)
	self['Look']:Draw(Esp, F['Look'], Data)
end

function ESP.Object:Kill()
	for _, Key in Lazy do
		self[Key]:Kill()
	end

	if self['Ready'] then
		for _, Key in Templated do
			self[Key]:Kill()
		end
		self['Root']:Destroy()
		self['Ready'] = false
	end
end

-- // Per-frame data
function ESP:Data(Obj)
	local Char, Hum, Part = Obj:Refresh()
	if not Char or not Hum or not Part or Hum.Health <= 0 then
		return
	end

	local F = self['F']
	local Where = Part.Position
	local Dist = (Where - self['CamPos']).Magnitude

	local Cap = F['Max_Distance'] or 0
	if Cap > 0 and Dist > Cap then
		return
	end

	local X, Y, On, Depth = self:Project(Where - BoxDrop)
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
	Data['X'], Data['Y'], Data['W'], Data['H'] = Bx, By, Bw, Bh
	Data['Char'] = Char
	Data['Head'] = Obj['HeadPart']
	Data['Name'] = Obj['Name']
	Data['Display'] = Obj['Display']
	Data['Both'] = Obj['Both']
	Data['Dist'] = Floor(Dist + 0.5)
	Data['Weapon'] = F['Weapon'] and Obj:Weapon(Char) or ''

	if F['Healthbar'] then
		local MaxHp, Hp = Hum.MaxHealth, Hum.Health
		Data['Health'] = MaxHp > 0 and Hp / MaxHp or 0
		Data['HealthVal'] = Floor(Hp + 0.5)
	else
		Data['Health'] = 0
		Data['HealthVal'] = 0
	end

	if F['EspFlags'] then
		local State = Hum:GetState()
		local Falling = State == HS.Freefall or State == HS.FallingDown
		local Jumping = State == HS.Jumping
		local Climbing = State == HS.Climbing
		local Swimming = State == HS.Swimming
		local Seated = State == HS.Seated or Hum.Sit or Hum.SeatPart ~= nil
		local Flying = State == HS.Flying
		local Busy = Falling or Jumping or Climbing or Swimming or Seated or Ragdoll or Flying

		local Flags = Data['Flags']
		Flags['Ragdoll'] = Ragdoll
		Flags['Falling'] = Falling
		Flags['Jumping'] = Jumping
		Flags['Climbing'] = Climbing
		Flags['Swimming'] = Swimming
		Flags['Seated'] = Seated
		Flags['Flying'] = Flying
		Flags['Running'] = Hum.MoveDirection.Magnitude > 0.05 and not Busy
	end

	return Data
end

function ESP:Pack()
	local F = self['F']
	for Key, Val in self['Flags'] do
		F[Key] = Val
	end

	if self['ExtFlags'] then
		for Key, Val in self['ExtFlags'] do
			local Value = Unwrap(Val)
			if Value ~= nil then
				F[Key] = Value
			end
		end
	end

	local CamCF, Vp, Fov = self:View()
	self['CamCF'] = CamCF
	self['CamPos'] = CamCF.Position
	self['Now'] = Clock()
	self['Vp'] = Vp
	self['Px'] = Vp.Y / (2 * Tan(Rad(Fov) * 0.5))

	local Origin = F['Tracer_Origin']
	if Origin == 'Mouse' then
		local Mouse = self:Mouse()
		self['FromX'], self['FromY'] = Mouse.X, Mouse.Y
	else
		self['FromX'] = Vp.X * 0.5
		self['FromY'] = Origin == 'Top' and 0 or Origin == 'Center' and Vp.Y * 0.5 or Vp.Y
	end

	local Fill = self['FCfg']
	local Type = F['Fill_Type'] or 'Full'
	local Rot = F['Fill_Rotation']
	if not Rot and Type ~= 'Full' then
		Rot = FillRot[F['Fill_Half'] or 'Top'] or FillRot['Top']
	end

	Fill['Trans'] = F['Fill_Transparency'] or 0.5
	Fill['Static'] = F['Fill_Static']
	Fill['Type'] = Type
	Fill['Spin'] = F['Fill_Spin']
	Fill['Rot'] = Fill['Spin'] and Floor(self['Now'] * (F['Fill_Spin_Speed'] or 60)) % 360 or Rot or FillRot['Bottom']

	local Head = self['HeadCfg']
	Head['Trans'] = F['Head_Fill_Transparency'] or 0.5
	Head['Static'] = F['Head_Fill_Static']
	Head['Type'] = F['Head_Fill_Type'] or 'Full'
	Head['Fill'] = F['Head_Fill']
	Head['Outline'] = F['Head_Outline']
	Head['OutlineColor'] = F['Head_Outline_Color']
	Head['Rot'] = F['Head_Spin'] and Floor(self['Now'] * (F['Head_Spin_Speed'] or 60)) % 360 or FillRot['Bottom']

	local Health = self['HCfg']
	local High = F['Health_High'] or Rgb(0, 255, 80)
	local Mid = F['Health_Mid'] or Rgb(255, 230, 0)
	local Low = F['Health_Low'] or Rgb(255, 40, 40)
	local Cols = Health['Colors']

	if Cols[1] ~= High or Cols[2] ~= Mid or Cols[4] ~= Low then
		Cols[1], Cols[2], Cols[3], Cols[4] = High, Mid, Rgb(255, 120, 0), Low
		Health['Stamp'] += 1
	end

	Health['Text'] = F['Health_Text']
	Health['Dynamic'] = F['Health_Text_Dynamic']

	local Armor = self['ACfg']
	local ArmorCol = F['Armor_Color'] or Rgb(0, 85, 255)
	if Armor['Colors'][1] ~= ArmorCol then
		Armor['Colors'][1], Armor['Colors'][2] = ArmorCol, ArmorCol
		Armor['Stamp'] += 1
	end

	Armor['Text'] = F['Armor_Text']
	Armor['TextCol'] = ArmorCol

	self:Resolve()
end

function ESP:Resolve()
	local F, Head = self['F'], self['HeadCfg']
	self['FCfg']['Col'] = F['Fill_Color'] or White
	Head['Col'] = F['Head_Fill_Color'] or Rgb(255, 0, 75)
	Head['Stroke'] = F['Head_Color']
	self['HCfg']['TextCol'] = F['Health_Text_Color'] or F['Health_High'] or Rgb(0, 255, 80)
end

function ESP:Recolor(Col)
	local F, Saved = self['F'], self['Saved']
	for _, Key in self['TintKeys'] do
		Saved[Key] = F[Key]
		F[Key] = Col
	end
	self:Resolve()
end

function ESP:Restore()
	local F, Saved = self['F'], self['Saved']
	for _, Key in self['TintKeys'] do
		F[Key] = Saved[Key]
		Saved[Key] = nil
	end
	self:Resolve()
end

-- // Loop
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
	local Tint = self['Tint']
	local Keys = self['TintKeys']

	for Plr, Obj in self['Objects'] do
		if Team and Plr.Team == Team then
			Obj:Hide()
			continue
		end

		local Col = Tint and Tint(Plr)
		if Col == false then
			Obj:Hide()
			continue
		end

		Col = Keys and Col
		if Col then
			self:Recolor(Col)
		end

		local Data = self:Data(Obj)
		if Data then
			Obj:Render(self, Data)
			if Shut then
				Obj['Skel']:Hide()
				Obj['Look']:Hide()
				Obj['Trace']:Hide()
			end
		else
			Obj:Hide(true)
			Obj['HL']:Draw(self, HL, Obj['Char'], Obj['Hum'])
		end

		if Col then
			self:Restore()
		end
	end
end

function ESP:Add(Plr)
	if Plr ~= Local and not self['Objects'][Plr] then
		self['Objects'][Plr] = ESP.Object:New(Plr)
	end
end

function ESP:Rem(Plr)
	local Obj = self['Objects'][Plr]
	if Obj then
		Obj:Kill()
		self['Objects'][Plr] = nil
	end
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

function ESP:Configs()
	self['FCfg'] = {}
	self['HeadCfg'] = {}
	self['HCfg'] = { Colors = {}, Stops = { 0, 0.4, 0.7, 1 }, Stamp = 0 }
	self['ACfg'] = { Colors = {}, Stamp = 0 }
end

function ESP:Init(ExtFlags)
	if ExtFlags then
		self['ExtFlags'] = ExtFlags
	end

	if self['Active'] then
		return self
	end

	self['Active'] = true
	self:Configs()

	for _, Plr in Players:GetPlayers() do
		self:Add(Plr)
	end

	local Conns = self['Conns']
	table.insert(Conns, Players.PlayerAdded:Connect(function(Plr)
		self:Add(Plr)
	end))
	table.insert(Conns, Players.PlayerRemoving:Connect(function(Plr)
		self:Rem(Plr)
	end))
	table.insert(Conns, Run.Heartbeat:Connect(function()
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
	table.clear(self['Saved'])
	self['Tint'] = nil
	self['TintKeys'] = nil
	self['Active'] = false
end

-- // Menu preview
local Chams = Class()

function Chams:Hide()
	local Tinted = self['Tinted']
	if not Tinted then
		return
	end

	for Part, Original in Tinted do
		Part.Color = Original
	end

	self['Tinted'] = nil
	self['Char'] = nil
end

Chams.Kill = Chams.Hide

function Chams:Draw(Esp, On, Char)
	if not On or not Char then
		self:Hide()
		return
	end

	local F = Esp['F']
	local Fill = F['Highlight_Fill'] or White
	local Mix = 1 - (F['Highlight_Fill_Transparency'] or 0.5)
	if self['Char'] == Char and self['Fill'] == Fill and self['Mix'] == Mix then
		return
	end

	self:Hide()
	self['Char'], self['Fill'], self['Mix'] = Char, Fill, Mix
	self['Tinted'] = {}

	for _, Part in Char:GetDescendants() do
		if Part:IsA('BasePart') then
			self['Tinted'][Part] = Part.Color
			Part.Color = Part.Color:Lerp(Fill, Mix)
		end
	end
end

local Preview = setmetatable({ HL = Chams }, { __index = ESP })
Preview.__index = Preview

function ESP:CreatePreview(Viewport)
	local Overlay = Inst('Frame', {
		Parent = Viewport,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = Pos(1, 0, 1, 0),
	})

	local Self = setmetatable({ Viewport = Viewport, Gui = Overlay, LineParent = Overlay, F = {}, Saved = {} }, Preview)
	Self:Configs()
	Self['Temp'], Self['TempRefs'] = Self:Build()
	return Self
end

function Preview:View()
	local Camera = self['Camera']
	return Camera.CFrame, self['Viewport'].AbsoluteSize, Camera.FieldOfView
end

function Preview:Mouse()
	local Mouse = Input:GetMouseLocation() - self['Viewport'].AbsolutePosition
	local Gui = self['Viewport']:FindFirstAncestorOfClass('ScreenGui')
	if Gui and not Gui.IgnoreGuiInset then
		local Inset = Services['GuiService']:GetGuiInset()
		Mouse -= Inset
	end
	return Mouse
end

function Preview:Project(World)
	local Rel = self['CamCF']:PointToObjectSpace(World)
	local Depth = -Rel.Z
	local Vp = self['Vp']
	local X = Vp.X * 0.5 + Rel.X / Depth * self['Px']
	local Y = Vp.Y * 0.5 - Rel.Y / Depth * self['Px']
	return X, Y, Depth > 0 and X >= 0 and Y >= 0 and X <= Vp.X and Y <= Vp.Y, Depth
end

function Preview:Wts(World)
	local X, Y, On, Depth = self:Project(World)
	return Vec(X, Y), On, Depth
end

function Preview:Data(Obj)
	local Data = ESP.Data(self, Obj)
	if not Data or not self['F']['EspFlags'] then
		return Data
	end

	for _, Name in FlagOrder do
		if Data['Flags'][Name] then
			return Data
		end
	end

	Data['Flags']['Running'] = true
	return Data
end

function Preview:SetModel(Model, Camera)
	if self['Target'] then
		self['Target']:Kill()
		self['Target'] = nil
	end

	self['Camera'] = Camera
	if Model and Camera then
		self['Target'] = ESP.Object:New({ Name = Local.Name, DisplayName = Local.DisplayName, Character = Model }, self)
	end
end

function Preview:Step()
	local Target = self['Target']
	if not Target then
		return
	end

	self:Pack()

	local Data = self:Data(Target)
	if Data then
		Target:Render(self, Data)
	else
		Target:Hide()
	end
end

function Preview:Destroy()
	self:SetModel(nil)
	self['Gui']:Destroy()
end

ESP:Init()

return ESP
