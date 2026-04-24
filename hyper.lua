--[[
    HYPER'S HUB V6 - PREDICTOR EDITION
    Visual: Black & Neon Concept
    Sistemas: RakNet Physics + Dynamic Ghosting
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Hyper = {
    Active = false,
    Intensity = 38,
    GhostOffset = 0.05,
    Smoothing = 0.2,
    GhostColor = Color3.fromRGB(0, 150, 255)
}

local state = {
    ghostModel = nil,
    currentVelo = Vector3.new(0, 0, 0)
}

-- [ LIMPEZA ]
local function cleanup()
    if state.ghostModel then state.ghostModel:Destroy(); state.ghostModel = nil end
end

-- [ GHOST ]
local function createGhost()
    cleanup()
    local char = LocalPlayer.Character
    if not char then return end
    char.Archivable = true
    local ghost = char:Clone()
    char.Archivable = false
    
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
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(40, 40, 40)
Stroke.Thickness = 2

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "HYPER'S HUB"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.BackgroundTransparency = 1

-- Botão ON
local OnBtn = Instance.new("TextButton", Main)
OnBtn.Size = UDim2.new(0.4, 0, 0, 40)
OnBtn.Position = UDim2.new(0.07, 0, 0.45, 0)
OnBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
OnBtn.Text = "ON"
OnBtn.TextColor3 = Color3.new(1, 1, 1)
OnBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OnBtn)

-- Botão OFF
local OffBtn = Instance.new("TextButton", Main)
OffBtn.Size = UDim2.new(0.4, 0, 0, 40)
OffBtn.Position = UDim2.new(0.53, 0, 0.45, 0)
OffBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
OffBtn.Text = "OFF"
OffBtn.TextColor3 = Color3.new(1, 1, 1)
OffBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OffBtn)

-- Eventos de Clique
OnBtn.MouseButton1Click:Connect(function()
    Hyper.Active = true
    OnBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    OffBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    createGhost()
end)

OffBtn.MouseButton1Click:Connect(function()
    Hyper.Active = false
    OnBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
    OffBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 50)
    cleanup()
end)

-- [ MOTOR DE FÍSICA ]
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if Hyper.Active and root and hum then
        local t = tick()
        local moveVelocity = hum.MoveDirection * hum.WalkSpeed
        local desyncVelo = Vector3.new(math.sin(t * 14) * Hyper.Intensity, 0, math.cos(t * 14) * Hyper.Intensity)
        
        state.currentVelo = state.currentVelo:Lerp(desyncVelo, Hyper.Smoothing)
        local oldV = root.AssemblyLinearVelocity
        
        root.AssemblyLinearVelocity = state.currentVelo + moveVelocity
        
        if state.ghostModel then
            local gRoot = state.ghostModel:FindFirstChild("HumanoidRootPart")
            if gRoot then
                gRoot.CFrame = root.CFrame * CFrame.new(state.currentVelo * Hyper.GhostOffset)
            end
        end
        
        RunService.RenderStepped:Wait()
        root.AssemblyLinearVelocity = oldV
    end
end)
