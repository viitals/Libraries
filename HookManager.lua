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
    if type(Meta) ~= 'table' then
        return nil
    end

    local Method = Meta[Name]
    if type(Method) ~= 'function' then
        return nil
    end

    return Method
end

local UnpackLimit = 200

local function Unpack(Packed, Start, Stop)
    Start = Start or 1
    Stop = Stop or Packed.n or #Packed

    if Start > Stop then
        return
    end

    if Stop - Start < UnpackLimit then
        return table.unpack(Packed, Start, Stop)
    end

    local Mid = Start + UnpackLimit - 1
    return table.unpack(Packed, Start, Mid), Unpack(Packed, Mid + 1, Stop)
end

HookLibrary.Unpack = Unpack

local function HookTarget(self, Target, Handler)
    if self.Hooks[Target] then
        return false
    end

    local UseOTH = false
    local RootFunction = nil

    local function CallRoot(...)
        if UseOTH then
            return oth.get_root_callback()(...)
        end

        return RootFunction(...)
    end

    local function RawClosure(...)
        local Hook = self.Hooks[Target]
        local Args = table.pack(...)

        if not Hook or not Hook.Enabled then
            return CallRoot(Unpack(Args))
        end

        local Rets = table.pack(pcall(Handler, Args.n, CallRoot, Unpack(Args)))

        if Rets[1] and Rets[3] then
            if Rets.n == 3 then
                return Rets[2]
            end
            return Rets[2], Unpack(Rets, 4, Rets.n)
        end

        return CallRoot(Unpack(Args))
    end

    local HookedClosure = newcclosure(RawClosure)

    if HasOTH() and iscclosure(Target) then
        UseOTH = true

        local HookSuccess = pcall(oth.hook, Target, HookedClosure)
        if not HookSuccess then
            UseOTH = false
        end
    end

    if not UseOTH then
        RootFunction = hookfunction(Target, HookedClosure)
    end

    self.Hooks[Target] = {
        Original = CallRoot,
        Restore = RootFunction,
        Callback = HookedClosure,
        Target = Target,
        UseOTH = UseOTH,
        Enabled = true,
    }

    return true
end

function HookLibrary:Hook(Name, Handler)
    if type(Handler) ~= 'function' then
        return false
    end

    if type(Name) == 'function' then
        return HookTarget(self, Name, Handler)
    end

    if type(Name) ~= 'string' then
        return false
    end

    if self.Hooks[Name] then
        return false
    end

    local UseOTH = false
    local Target = nil
    local RootFunction = nil

    local function CallRoot(...)
        if UseOTH then
            return oth.get_root_callback()(...)
        end

        return RootFunction(...)
    end

    local function RawClosure(...)
        local Hook = self.Hooks[Name]
        local Args = table.pack(...)

        if not Hook or not Hook.Enabled then
            return CallRoot(Unpack(Args))
        end

        local Rets = table.pack(pcall(Handler, Args.n, CallRoot, Unpack(Args)))

        if Rets[1] and Rets[3] then
            if Rets.n == 3 then
                return Rets[2]
            end
            return Rets[2], Unpack(Rets, 4, Rets.n)
        end

        return CallRoot(Unpack(Args))
    end

    local HookedClosure = newcclosure(RawClosure)

    if HasOTH() then
        Target = GetMetamethod(Name)

        if type(Target) == 'function' and iscclosure(Target) then
            UseOTH = true

            local HookSuccess = pcall(oth.hook, Target, HookedClosure)
            if not HookSuccess then
                UseOTH = false
                Target = nil
            end
        end
    end

    if not UseOTH then
        Target = GetMetamethod(Name)
        RootFunction = hookmetamethod(game, Name, HookedClosure)
    end

    self.Hooks[Name] = {
        Original = CallRoot,
        Restore = RootFunction,
        Callback = HookedClosure,
        Target = Target,
        UseOTH = UseOTH,
        Enabled = true,
    }

    return true
end

function HookLibrary:HookFunction(Target, Handler)
    if type(Target) ~= 'function' then
        return false
    end
    return self:Hook(Target, Handler)
end

function HookLibrary:IsHooked(Name)
    return self.Hooks[Name] ~= nil
end

function HookLibrary:SetEnabled(Name, State)
    if type(State) ~= 'boolean' then
        return false
    end

    local Hook = self.Hooks[Name]

    if not Hook then
        return false
    end

    Hook.Enabled = State
    return true
end

function HookLibrary:GetOriginal(Name)
    local Hook = self.Hooks[Name]
    return Hook and Hook.Original
end

function HookLibrary:Unhook(Name)
    local Hook = self.Hooks[Name]

    if not Hook then
        return false
    end

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
    if type(Target) ~= 'function' then
        return false
    end
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
