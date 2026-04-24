--[[
    HYPER'S HUB V7 - PERSISTENT GHOSTING
    Visual: Black & Neon Concept
    Fix: Ghost Displacement & Auto-Respawn
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Hyper = {
    Active = false,
    Intensity = 40,
    GhostOffset = 0.07, -- Aumentado para o clone se afastar mais do corpo
    Smoothing = 0.18,
    GhostColor = Color3.fromRGB(0, 150, 255)
}

local state = {
    ghostModel = nil,
    currentVelo = Vector3.new(0, 0, 0)
}

-- [ FUNÇÃO DE CRIAÇÃO DO CLONE ]
local function createGhost()
    if state.ghostModel then state.ghostModel:Destroy() end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    char.Archivable = true
    local ghost = char:Clone()
    char.Archivable = false
    ghost.Name = "HyperGhost_V7"
    
    for _, v in ipairs(ghost:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = true
            v.CanCollide = false
            v.Transparency = 0.6
            v.Material = Enum.Material.ForceField
            v.Color = Hyper.GhostColor
        elseif v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Animator") or v:IsA("Humanoid") then
            v:Destroy()
        end
    end
    
    local hl = Instance.new("Highlight", ghost)
    hl.FillColor = Hyper.GhostColor
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    ghost.Parent = game.Workspace.Terrain
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
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(50, 50, 50)
Stroke.Thickness = 2

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
    OnBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
    OffBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    createGhost()
end)

OffBtn.MouseButton1Click:Connect(function()
    Hyper.Active = false
    OnBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    OffBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    if state.ghostModel then state.ghostModel:Destroy(); state.ghostModel = nil end
end)

-- [ MOTOR DE FÍSICA E ATUALIZAÇÃO DO GHOST ]
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if Hyper.Active and root and hum then
        -- Verificação de integridade do Ghost
        if not state.ghostModel or not state.ghostModel.Parent then
            createGhost()
        end

        local t = tick()
        local moveVelocity = hum.MoveDirection * hum.WalkSpeed
        
        -- Cálculo de Desync (Vetor de deslocamento circular)
        local desyncVelo = Vector3.new(
            math.sin(t * 15) * Hyper.Intensity, 
            0, 
            math.cos(t * 15) * Hyper.Intensity
        )
        
        state.currentVelo = state.currentVelo:Lerp(desyncVelo, Hyper.Smoothing)
        local oldV = root.AssemblyLinearVelocity
        
        -- Aplica a velocidade "mentirosa" para o servidor
        root.AssemblyLinearVelocity = state.currentVelo + moveVelocity
        
        -- ATUALIZAÇÃO DE POSIÇÃO DO CLONE (Faz ele se mover de verdade)
        if state.ghostModel then
            local gRoot = state.ghostModel:FindFirstChild("HumanoidRootPart")
            if gRoot then
                -- O Clone agora se desloca fisicamente para onde o servidor te vê
                gRoot.CFrame = root.CFrame * CFrame.new(state.currentVelo * Hyper.GhostOffset)
            end
        end
        
        RunService.RenderStepped:Wait()
        root.AssemblyLinearVelocity = oldV
    end
end)
