--[[
    HYPER'S DESYNC - BLACK EDITION (V2.1)
    Visual: Black Hub / Dark Theme
    Funcionalidade: Ghosting + Orbital Physics + Desync
    Otimização: SUNC 100% (Madium / 2026)
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Parâmetros de Configuração
local HyperSettings = {
    Active = false,
    Intensity = 36,
    Smoothing = 0.12,
    GhostColor = Color3.fromRGB(0, 150, 255), -- Azul Neon para contraste no preto
    HubColor = Color3.fromRGB(0, 0, 0),       -- PRETO ABSOLUTO
    AccentColor = Color3.fromRGB(40, 40, 40)  -- Grafite para bordas
}

local state = {
    ghostModel = nil,
    currentVelo = Vector3.new(0,0,0)
}

-- [ SISTEMA DE LIMPEZA ]
local function cleanup()
    if state.ghostModel then state.ghostModel:Destroy() end
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name == "HyperMarker" then v:Destroy() end
    end
end

-- [ SISTEMA DE GHOSTING ]
local function createHyperGhost()
    cleanup()
    local char = LocalPlayer.Character
    if not char then return end
    
    char.Archivable = true
    local ghost = char:Clone()
    char.Archivable = false
    ghost.Name = "HyperGhost"
    
    for _, v in ipairs(ghost:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = true
            v.CanCollide = false
            v.Material = Enum.Material.ForceField
            v.Color = HyperSettings.GhostColor
            v.Transparency = 0.6
        elseif v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Humanoid") then
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
if GuiParent:FindFirstChild("HyperDesyncHub") then GuiParent.HyperDesyncHub:Destroy() end

local ScreenGui = Instance.new("ScreenGui", GuiParent)
ScreenGui.Name = "HyperDesyncHub"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 180, 0, 90)
MainFrame.Position = UDim2.new(0.5, -90, 0.82, 0)
MainFrame.BackgroundColor3 = HyperSettings.HubColor
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

-- Detalhes Visuais (Bordas e Cantos)
local Corner = Instance.new("UICorner", MainFrame)
Corner.CornerRadius = UDim.new(0, 6)

local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = HyperSettings.AccentColor
Stroke.Thickness = 1.5

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "HYPER'S DESYNC"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.85, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.075, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleBtn.Text = "STATUS: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
ToggleBtn.Font = Enum.Font.Code
ToggleBtn.TextSize = 12

local BtnCorner = Instance.new("UICorner", ToggleBtn)
local BtnStroke = Instance.new("UIStroke", ToggleBtn)
BtnStroke.Color = Color3.fromRGB(30, 30, 30)

-- [ LÓGICA OPERACIONAL ]
ToggleBtn.MouseButton1Click:Connect(function()
    HyperSettings.Active = not HyperSettings.Active
    if HyperSettings.Active then
        ToggleBtn.Text = "STATUS: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
        BtnStroke.Color = Color3.fromRGB(0, 150, 80)
        createHyperGhost()
    else
        ToggleBtn.Text = "STATUS: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        BtnStroke.Color = Color3.fromRGB(30, 30, 30)
        cleanup()
    end
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root and HyperSettings.Active then
        local t = tick()
        local targetVelo = Vector3.new(math.sin(t * 11) * HyperSettings.Intensity, 0, math.cos(t * 11) * HyperSettings.Intensity)
        state.currentVelo = state.currentVelo:Lerp(targetVelo, HyperSettings.Smoothing)
        
        local oldV = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = state.currentVelo
        
        if state.ghostModel then
            local gRoot = state.ghostModel:FindFirstChild("HumanoidRootPart")
            if gRoot then
                -- Atualiza a posição do Fantasma com base no Desync de rede
                gRoot.CFrame = root.CFrame * CFrame.new(state.currentVelo * 0.055)
            end
        end
        
        RunService.RenderStepped:Wait()
        root.AssemblyLinearVelocity = oldV
    end
end)

print("Hyper's Desync: Black Edition carregada com sucesso.")

