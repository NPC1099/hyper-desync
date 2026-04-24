--[[
    HYPER'S HUB V9 - RAKNET REAL DESYNC
    Fuso: VFX Original + RakNet Packet Manipulation
    Visual: Black Hub / ON-OFF System
]]

local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local rs = game:GetService("RunService")
local lp = players.LocalPlayer

-- Configurações Visuais Originais
local PI2 = math.pi * 2
local OUTER_RADIUS, INNER_RADIUS = 3.2, 1.8
local OUTER_SPEED, INNER_SPEED = 2.5, -3.5
local GROUND_OFFSET = 3.1

local HyperState = {
    Active = false,
    GhostModel = nil,
    GroundParts = {},
    Attachments = {},
    VfxConn = nil,
    Hooked = false
}

-- [ FUNÇÕES AUXILIARES DE VFX ]
local function cleanup()
    if HyperState.VfxConn then HyperState.VfxConn:Disconnect(); HyperState.VfxConn = nil end
    if HyperState.Hooked and raknet then raknet.remove_send_hook() end
    for _, p in ipairs(HyperState.GroundParts) do if p.dot then p.dot:Destroy() end end
    if HyperState.GhostModel then HyperState.GhostModel:Destroy(); HyperState.GhostModel = nil end
    HyperState.GroundParts = {}
    HyperState.Attachments = {}
    HyperState.Hooked = false
end

local function rakhook(packet)
    if packet.PacketId == 0x1B and HyperState.Active then
        local buf = packet.AsBuffer
        buffer.writeu32(buf, 1, 0xFFFFFFFF)
        packet:SetData(buf)
    end
end

local function makeRingDot(pos, radius, angle, col)
    local dot = Instance.new("Part")
    dot.Anchored, dot.CanCollide = true, false
    dot.Size = Vector3.new(0.2, 0.2, 0.2)
    dot.Material = Enum.Material.Neon
    dot.Color = col
    dot.Parent = workspace
    return dot
end

-- [ CRIAÇÃO DO DESYNC REAL ]
local function startDesync()
    cleanup()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local startPos = hrp.Position
    char.Archivable = true
    local ghost = char:Clone()
    char.Archivable = false
    
    -- Configuração do Ghost (conforme seu script)
    for _, v in ipairs(ghost:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored, v.CanCollide = true, false
            v.Transparency = 0.5
            v.Color = Color3.fromRGB(0, 40, 150)
        elseif v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Humanoid") then
            v:Destroy()
        end
    end
    
    local hl = Instance.new("Highlight", ghost)
    hl.FillColor = Color3.fromRGB(0, 100, 255)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    ghost:SetPrimaryPartCFrame(hrp.CFrame)
    ghost.Parent = workspace
    HyperState.GhostModel = ghost

    -- Criar Anéis de Chão
    for i = 1, 24 do
        local a = (i/24) * PI2
        table.insert(HyperState.GroundParts, {
            dot = makeRingDot(startPos, OUTER_RADIUS, a, Color3.fromRGB(0, 150, 255)),
            angle = a, isOuter = true
        })
    end

    -- Loop de Animação VFX
    HyperState.VfxConn = rs.Heartbeat:Connect(function()
        if not HyperState.Active then return end
        local t = tick()
        for _, p in ipairs(HyperState.GroundParts) do
            local rad = p.isOuter and OUTER_RADIUS or INNER_RADIUS
            local speed = p.isOuter and OUTER_SPEED or INNER_SPEED
            local curA = p.angle + t * speed
            p.dot.CFrame = CFrame.new(startPos.X + math.cos(curA) * rad, startPos.Y - GROUND_OFFSET, startPos.Z + math.sin(curA) * rad)
        end
    end)

    if raknet then 
        raknet.add_send_hook(rakhook)
        HyperState.Hooked = true
    end
end

-- [ INTERFACE HYPER'S HUB ]
local GuiParent = (gethui and gethui()) or game:GetService("CoreGui")
if GuiParent:FindFirstChild("HypersHubV9") then GuiParent.HypersHubV9:Destroy() end

local ScreenGui = Instance.new("ScreenGui", GuiParent)
ScreenGui.Name = "HypersHubV9"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 140)
Main.Position = UDim2.new(0.5, -100, 0.8, 0)
Main.BackgroundColor3 = Color3.new(0,0,0)
Main.Draggable = true
Main.Active = true
Instance.new("UICorner", Main)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(60,60,60)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "HYPER'S HUB"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.BackgroundTransparency = 1

local OnBtn = Instance.new("TextButton", Main)
OnBtn.Size = UDim2.new(0.4, 0, 0, 45)
OnBtn.Position = UDim2.new(0.07, 0, 0.5, 0)
OnBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
OnBtn.Text = "ON"
OnBtn.TextColor3 = Color3.new(1,1,1)
OnBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OnBtn)

local OffBtn = Instance.new("TextButton", Main)
OffBtn.Size = UDim2.new(0.4, 0, 0, 45)
OffBtn.Position = UDim2.new(0.53, 0, 0.5, 0)
OffBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
OffBtn.Text = "OFF"
OffBtn.TextColor3 = Color3.new(1,1,1)
OffBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OffBtn)

OnBtn.MouseButton1Click:Connect(function()
    HyperState.Active = true
    OnBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    OffBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    startDesync()
end)

OffBtn.MouseButton1Click:Connect(function()
    HyperState.Active = false
    OnBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    OffBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    cleanup()
end)
