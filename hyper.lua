--[[
    HYPER'S DESYNC V3 - FULL FUNCTIONAL
    Lógica: Network Velocity Manipulation + Dynamic Ghosting
    Status: Revisado para 23 de Abril de 2026
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HyperSettings = {
    Active = false,
    Intensity = 42,        -- Força da dessincronização
    Smoothing = 0.15,      -- Suavidade do movimento
    VisualOffset = 0.06,   -- Distância do Ghost
    GhostColor = Color3.fromRGB(0, 150, 255)
}

local state = {
    ghostModel = nil,
    currentVelo = Vector3.new(0, 0, 0),
    connection = nil
}

-- [ FUNÇÃO DE GHOST DINÂMICO ]
local function createDynamicGhost()
    if state.ghostModel then state.ghostModel:Destroy() end
    local char = LocalPlayer.Character
    if not char then return end
    
    char.Archivable = true
    local ghost = char:Clone()
    char.Archivable = false
    ghost.Name = "HyperGhost_Dynamic"
    
    for _, v in ipairs(ghost:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = true
            v.CanCollide = false
            v.Transparency = 0.7
            v.Material = Enum.Material.ForceField
            v.Color = HyperSettings.GhostColor
        elseif v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Humanoid") or v:IsA("Highlight") then
            v:Destroy()
        end
    end
    
    local hl = Instance.new("Highlight", ghost)
    hl.FillColor = HyperSettings.GhostColor
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    ghost.Parent = game.Workspace.Terrain
    state.ghostModel = ghost
end

-- [ INTERFACE BLACK HUB ]
local GuiParent = (gethui and gethui()) or game:GetService("CoreGui")
if GuiParent:FindFirstChild("HyperHubV3") then GuiParent.HyperHubV2:Destroy() end

local ScreenGui = Instance.new("ScreenGui", GuiParent)
ScreenGui.Name = "HyperHubV3"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 180, 0, 90)
MainFrame.Position = UDim2.new(0.5, -90, 0.8, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(40,40,40)

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.85, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.075, 0, 0.35, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15,15,15)
ToggleBtn.Text = "DESYNC: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.Code
Instance.new("UICorner", ToggleBtn)

-- [ LÓGICA DE EXECUÇÃO REAL ]
ToggleBtn.MouseButton1Click:Connect(function()
    HyperSettings.Active = not HyperSettings.Active
    if HyperSettings.Active then
        ToggleBtn.Text = "DESYNC: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
        createDynamicGhost()
    else
        ToggleBtn.Text = "DESYNC: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        if state.ghostModel then state.ghostModel:Destroy() end
    end
end)

-- LOOP PRINCIPAL DE MANIPULAÇÃO DE REDE (NETWORK)
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if HyperSettings.Active and root then
        -- 1. Manipulação de Velocidade (A alma do Desync)
        -- Geramos um vetor de força que o servidor tenta rastrear, mas o cliente ignora
        local t = tick() * 14 -- Frequência de oscilação
        local targetVelo = Vector3.new(math.sin(t) * HyperSettings.Intensity, 0, math.cos(t) * HyperSettings.Intensity)
        
        state.currentVelo = state.currentVelo:Lerp(targetVelo, HyperSettings.Smoothing)
        
        local oldV = root.AssemblyLinearVelocity
        
        -- Injetamos a velocidade falsa no frame de física
        root.AssemblyLinearVelocity = state.currentVelo
        
        -- 2. Atualização DYNAMICA do Ghost
        if state.ghostModel then
            local gRoot = state.ghostModel:FindFirstChild("HumanoidRootPart")
            if gRoot then
                -- O Ghost agora segue o jogador com interpolação de rede
                -- Ele mostra onde sua hitbox está sendo "jogada" pelo desync
                gRoot.CFrame = root.CFrame * CFrame.new(state.currentVelo * HyperSettings.VisualOffset)
            end
        end
        
        -- Sincronia de Renderização (Obrigatório para o Madium não crashar)
        RunService.RenderStepped:Wait()
        
        -- Resetamos localmente para você não sair voando na sua tela
        root.AssemblyLinearVelocity = oldV
    end
end)
