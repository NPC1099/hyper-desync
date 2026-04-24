--[[
    HYPER'S HUB V8 - REAL CLONE DESYNC
    Lógica: Forced Instancing & Network Projection
    Visual: Black Hub / Real Ghost
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Hyper = {
    Active = false,
    Intensity = 45,
    GhostDistance = 6, -- Distância real de separação do clone
    Smoothing = 0.1,
    GhostColor = Color3.fromRGB(0, 150, 255)
}

local state = {
    ghostModel = nil,
    currentVelo = Vector3.new(0, 0, 0)
}

-- [ FUNÇÃO DE CLONAGEM REAL ]
local function createRealGhost()
    if state.ghostModel then state.ghostModel:Destroy() end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    char.Archivable = true
    local ghost = char:Clone()
    char.Archivable = false
    ghost.Name = "HyperGhost_Real"
    
    -- Limpeza e configuração do material
    for _, v in ipairs(ghost:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = true
            v.CanCollide = false
            v.CastShadow = false
            v.Transparency = 0.5
            v.Material = Enum.Material.Neon
            v.Color = Hyper.GhostColor
        elseif v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Humanoid") or v:IsA("Highlight") then
            v:Destroy()
        end
    end
    
    -- Efeito de visibilidade total
    local hl = Instance.new("Highlight")
    hl.FillColor = Hyper.GhostColor
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = ghost
    
    -- O Ghost deve ficar no Workspace, mas fora do seu modelo
    ghost.Parent = workspace
    state.ghostModel = ghost
end

-- [ INTERFACE HYPER'S HUB ]
local GuiParent = (gethui and gethui()) or game:GetService("CoreGui")
if GuiParent:FindFirstChild("HypersHub") then GuiParent.HypersHub:Destroy() end

local ScreenGui = Instance.new("ScreenGui", GuiParent)
ScreenGui.Name = "HypersHub"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 130)
Main.Position = UDim2.new(0.5, -100, 0.8, 0)
Main.BackgroundColor3 = Color3.new(0,0,0)
Main.Draggable = true
Main.Active = true
Instance.new("UICorner", Main)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(60, 60, 60)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "HYPER'S HUB"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.BackgroundTransparency = 1

local OnBtn = Instance.new("TextButton", Main)
OnBtn.Size = UDim2.new(0.4, 0, 0, 40)
OnBtn.Position = UDim2.new(0.07, 0, 0.5, 0)
OnBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
OnBtn.Text = "ON"
OnBtn.TextColor3 = Color3.new(1, 1, 1)
OnBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OnBtn)

local OffBtn = Instance.new("TextButton", Main)
OffBtn.Size = UDim2.new(0.4, 0, 0, 40)
OffBtn.Position = UDim2.new(0.53, 0, 0.5, 0)
OffBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
OffBtn.Text = "OFF"
OffBtn.TextColor3 = Color3.new(1, 1, 1)
OffBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OffBtn)

OnBtn.MouseButton1Click:Connect(function()
    Hyper.Active = true
    OnBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    OffBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    createRealGhost()
end)

OffBtn.MouseButton1Click:Connect(function()
    Hyper.Active = false
    OnBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    OffBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    if state.ghostModel then state.ghostModel:Destroy(); state.ghostModel = nil end
end)

-- [ MOTOR DE DESYNC REAL ]
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if Hyper.Active and root then
        -- Garantir que o Ghost existe
        if not state.ghostModel or not state.ghostModel.Parent then
            createRealGhost()
        end

        local t = tick()
        
        -- Gerar um vetor de Desync que realmente se afasta
        -- Em vez de girar rápido, ele oscila em uma posição fixa falsa
        local desyncPos = Vector3.new(
            math.sin(t * 3) * Hyper.GhostDistance, 
            0, 
            math.cos(t * 3) * Hyper.GhostDistance
        )
        
        -- Manip
            
