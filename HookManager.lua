local HookLibrary = {}

HookLibrary.Hooks = {}

local function HasOTH()
    return type(oth) == 'table' 
    and type(oth.hook) == 'function' 
    and type(oth.unhook) == 'function' 
    and type(oth.get_root_callback) == 'function'
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

function HookLibrary:Hook(Name, Handler)
    if type(Name) ~= 'string' or type(Handler) ~= 'function' then
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

        if not Hook or not Hook.Enabled then
            return CallRoot(...)
        end

        local ArgCount = select('#', ...)
        local Success, Value, Force = pcall(Handler, ArgCount, CallRoot, ...)

        if Success and Force then
            return Value
        end

        return CallRoot(...)
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
    else
        hookmetamethod(game, Name, Hook.Restore)
    end

    self.Hooks[Name] = nil

    return true
end

function HookLibrary:ClearHooks()
    for Name in pairs(self.Hooks) do
        self:Unhook(Name)
    end
end

return HookLibrary
