local HookLibrary = {}
HookLibrary.Hooks = {}

local function HasOTH()
	return type(oth) == 'table'
		and type(oth.hook) == 'function'
		and type(oth.unhook) == 'function'
		and type(oth.get_root_callback) == 'function'
end

local function HasRestoreFunction()
	return type(restorefunction) == 'function'
end

local function GetMetamethod(Name)
	local Meta = getrawmetatable(game)
	if type(Meta) ~= 'table' then return nil end
	local Method = Meta[Name]
	if type(Method) ~= 'function' then return nil end
	return Method
end

local UnpackLimit = 200

local function Unpack(Packed, Start, Stop)
	Start = Start or 1
	Stop = Stop or Packed.n or #Packed
	if Start > Stop then return end
	if Stop - Start < UnpackLimit then
		return table.unpack(Packed, Start, Stop)
	end
	local Mid = Start + UnpackLimit - 1
	return table.unpack(Packed, Start, Mid), Unpack(Packed, Mid + 1, Stop)
end

HookLibrary.Unpack = Unpack

local function HookTarget(Self, Target, Handler)
	if Self.Hooks[Target] then return false end

	local Original = nil
	local UseOTH = false

	if HasOTH() and iscclosure(Target) then
		UseOTH = true
		local Ok = pcall(oth.hook, Target, newcclosure(function() end))
		if not Ok then
			UseOTH = false
		else
			pcall(oth.unhook, Target)
		end
	end

	local function RawClosure(...)
		local Hook = Self.Hooks[Target]

		if not Hook or not Hook.Enabled then
			if UseOTH then
				return oth.get_root_callback()(...)
			end
			return Original(...)
		end

		local CalledOriginal = false

		local function CallOriginal(...)
			CalledOriginal = true
			if UseOTH then
				return oth.get_root_callback()(...)
			end
			return Original(...)
		end

		local Rets = table.pack(pcall(Handler, CallOriginal, ...))

		if Rets[1] and Rets[2] then
			if Rets.n == 2 then return end
			return Unpack(Rets, 3, Rets.n)
		end

		if CalledOriginal then
			if not Rets[1] then
				error(Rets[2], 0)
			end
			return
		end

		if UseOTH then
			return oth.get_root_callback()(...)
		end
		return Original(...)
	end

	local HookedClosure = newcclosure(RawClosure)

	if UseOTH then
		pcall(oth.hook, Target, HookedClosure)
	else
		Original = hookfunction(Target, HookedClosure)
	end

	Self.Hooks[Target] = {
		Original = function(...)
			if UseOTH then return oth.get_root_callback()(...) end
			return Original(...)
		end,
		Restore = Original,
		Callback = HookedClosure,
		Target = Target,
		UseOTH = UseOTH,
		Enabled = true,
	}

	return true
end

function HookLibrary:Hook(Name, Handler)
	if type(Handler) ~= 'function' then return false end

	if type(Name) == 'function' then
		return HookTarget(self, Name, Handler)
	end

	if type(Name) ~= 'string' then return false end
	if self.Hooks[Name] then return false end

	local UseOTH = false
	local Target = nil
	local Original = nil

	local function RawClosure(...)
		local Hook = self.Hooks[Name]

		if not Hook or not Hook.Enabled then
			if UseOTH then
				return oth.get_root_callback()(...)
			end
			return Original(...)
		end

		local CalledOriginal = false

		local function CallOriginal(...)
			CalledOriginal = true
			if UseOTH then
				return oth.get_root_callback()(...)
			end
			return Original(...)
		end

		local Rets = table.pack(pcall(Handler, CallOriginal, ...))

		if Rets[1] and Rets[2] then
			if Rets.n == 2 then return end
			return Unpack(Rets, 3, Rets.n)
		end

		if CalledOriginal then
			if not Rets[1] then
				error(Rets[2], 0)
			end
			return
		end

		if UseOTH then
			return oth.get_root_callback()(...)
		end
		return Original(...)
	end

	local HookedClosure = newcclosure(RawClosure)

	if HasOTH() then
		Target = GetMetamethod(Name)
		if type(Target) == 'function' and iscclosure(Target) then
			UseOTH = true
			local Ok = pcall(oth.hook, Target, HookedClosure)
			if not Ok then
				UseOTH = false
				Target = nil
			end
		end
	end

	if not UseOTH then
		Target = GetMetamethod(Name)
		Original = hookmetamethod(game, Name, HookedClosure)
	end

	self.Hooks[Name] = {
		Original = function(...)
			if UseOTH then return oth.get_root_callback()(...) end
			return Original(...)
		end,
		Restore = Original,
		Callback = HookedClosure,
		Target = Target,
		UseOTH = UseOTH,
		Enabled = true,
	}

	return true
end

function HookLibrary:HookFunction(Target, Handler)
	if type(Target) ~= 'function' then return false end
	return self:Hook(Target, Handler)
end

function HookLibrary:IsHooked(Name)
	return self.Hooks[Name] ~= nil
end

function HookLibrary:SetEnabled(Name, State)
	if type(State) ~= 'boolean' then return false end
	local Hook = self.Hooks[Name]
	if not Hook then return false end
	Hook.Enabled = State
	return true
end

function HookLibrary:GetOriginal(Name)
	local Hook = self.Hooks[Name]
	return Hook and Hook.Original
end

function HookLibrary:Unhook(Name)
	local Hook = self.Hooks[Name]
	if not Hook then return false end

	if Hook.UseOTH then
		pcall(oth.unhook, Hook.Target)
	elseif HasRestoreFunction() then
		pcall(restorefunction, Hook.Target)
	elseif type(Name) == 'string' and Hook.Restore then
		pcall(hookmetamethod, game, Name, Hook.Restore)
	elseif Hook.Target and Hook.Restore then
		pcall(hookfunction, Hook.Target, Hook.Restore)
	end

	self.Hooks[Name] = nil
	return true
end

function HookLibrary:UnhookFunction(Target)
	if type(Target) ~= 'function' then return false end
	return self:Unhook(Target)
end

function HookLibrary:ClearHooks()
	local Names = {}
	for Name in pairs(self.Hooks) do
		Names[#Names + 1] = Name
	end
	for Index = 1, #Names do
		self:Unhook(Names[Index])
	end
end

return HookLibrary
