--[[
    HYPER'S DESYNC V4 - RAKNET & ORBITAL EDITION
    Fins Educacionais: Manipulação de Pacotes (0x1B) e Estética Trigonométrica
    Visual: Black Hub / Blue Electricity / RakNet Hooking
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Parâmetros de Baixo Nível e Visual
local Hyper = {
    Active = false,
    Intensity = 45,
    PacketId = 0x1B, -- Pacote de Física Bruta
    OuterRadius = 3.5,
    InnerRadius = 2.0,
    OrbitalSpeed = 2.8,
    GhostColor = Color3.fromRGB(0, 100, 255)
}

local state = {
    ghostModel = nil,
    vfxConn = nil,
    hooked = false,
    currentVelo = Vector3.new(0, 0, 0),
    orbitalParts = {}
}

-- [ 1. GERENCIAMENTO DE MEMÓRIA E LIMPEZA ROBUSTA ]
local function cleanup()
    if state.vfxConn then state.vfxConn:Disconnect(); state.vfxConn = nil end
    if state.ghostModel then state.ghostModel:Destroy(); state.ghostModel = nil end
    
    for _, part in ipairs(state.orbitalParts) do
        if part then part:Destroy() end
    end
    state.orbitalParts = {}
    
    if state.hooked and raknet then
        raknet.remove_send_hook()
        state.hooked = false
    end
end

-- [ 2. MANIPULAÇÃO DE BAIXO NÍVEL (RAKNET HOOK) ]
local function raknet_hook(packet)
    if packet.PacketId == Hyper.PacketId and Hyper.Active then
        local buf = packet.AsBuffer
        -- Sobrescreve o timestamp para criar lag artificial controlado
        buffer.writeu32(buf, 1, 0xFFFFFFFF)
        packet:SetData(buf)
    end
end

-- [ 3. COMPLEXIDADE VISUAL E MATEMÁTICA (ORBITAL) ]
local function createOrbitalEffect(pos)
    local rCount = 24
    for i = 1, rCount do
        local dot = Instance.new("Part")
        dot.Size = Vector3.new(0.2, 0.2, 0.2)
        dot.Shape = Enum.PartType.Ball
        dot.Material = Enum.Material.Neon
        dot.Color = Hyper.GhostColor
        dot.Anchored = true
        dot.CanCollide = false
        dot.Parent = workspace
        
        local att = Instance.new("Attachment", dot)
        local em = Instance.new("ParticleEmitter", att)
        em.Color = ColorSequence.new(Hyper.GhostColor, Color3.new(1,1,1))
        em.Size = NumberSequence.new(0.1, 0)
        em.Lifetime = NumberRange.new(0.2, 0.4)
        em.Rate = 5
        
        table.insert(state.orbitalParts, dot)
    end
end

local function createGhost()
    cleanup()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    char.Archivable = true
    local ghost = char:Clone()
    char.Archivable = false
    ghost.Name = "HyperGhost_RakNet"
    
    -- Limpeza Profunda (Performance Elevada)
    for _, v in ipairs(ghost:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = true
            v.CanCollide = false
            v.Transparency = 0.7
            v.Material = Enum.Material.ForceField
            v.Color = Hyper.GhostColor
        elseif v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Animator") or v:IsA("Humanoid") then
            v:Destroy()
        end
    end
    
    local hl = Instance.new("Highlight", ghost)
    hl.FillColor = Hyper.GhostColor
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    ghost.Parent = game.Workspace.Terrain
    state.ghostModel = ghost
    createOrbitalEffect(char.HumanoidRootPart.Position)
end

-- [ 4. HUB PROFISSIONAL - BLACK EDITION ]
local GuiParent = (gethui and gethui()) or game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui", GuiParent)
ScreenGui.Name = "HyperDesync_Rak"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 190, 0, 95)
Main.Position = UDim2.new(0.5, -95, 0.8, 0)
Main.BackgroundColor3 = Color3.new(0,0,0)
Main.Draggable = true
Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(35,35,35)

local Btn = Instance.new("TextButton", Main)
Btn.Size = UDim2.new(0.85, 0, 0, 40)
Btn.Position = UDim2.new(0.075, 0, 0.4, 0)
Btn.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Btn.Text = "RAKNET DESYNC: OFF"
Btn.TextColor3 = Color3.new(1,1,1)
Btn.Font = Enum.Font.Code
Instance.new("UICorner", Btn)

-- Lógica de Interpolação e Loops
Btn.MouseButton1Click:Connect(function()
    Hyper.Active = not Hyper.Active
    if Hyper.Active then
        Btn.Text = "RAKNET DESYNC: ON"
        Btn.TextColor3 = Color3.fromRGB(0, 200, 255)
        createGhost()
        if raknet then raknet.add_send_hook(raknet_hook); state.hooked = true end
    else
        Btn.Text = "RAKNET DESYNC: OFF"
        Btn.TextColor3 = Color3.new(1,1,1)
        cleanup()
    end
end)

RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if Hyper.Active and root then
        local t = tick()
        
        -- Cálculo Trigonométrico para Desync e Orbitals
        local veloX = math.sin(t * 12) * Hyper.Intensity
        local veloZ = math.cos(t * 12) * Hyper.Intensity
        state.currentVelo = state.currentVelo:Lerp(Vector3.new(veloX, 0, veloZ), 0.15)
        
        root.AssemblyLinearVelocity = state.currentVelo
        
        -- Atualização Dinâmica do Ghost e Anéis
        if state.ghostModel then
            local gRoot = state.ghostModel:FindFirstChild("HumanoidRootPart")
            if gRoot then
                gRoot.CFrame = root.CFrame * CFrame.new(state.currentVelo * 0.05)
                
                -- Movimento dos Anéis Orbitais (Trigonometria Pura)
                for i, dot in ipairs(state.orbitalParts) do
                    local angle = (i / #state.orbitalParts) * math.pi * 2 + (t * Hyper.OrbitalSpeed)
                    local x = math.cos(angle) * Hyper.OuterRadius
                    local z = math.sin(angle) * Hyper.OuterRadius
                    dot.CFrame = gRoot.CFrame * CFrame.new(x, -3, z)
                end
            end
        end
        
        RunService.RenderStepped:Wait()
        root.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
end)
