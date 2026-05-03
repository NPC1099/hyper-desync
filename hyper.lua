--[[
    HYPER'S DESYNC - V11
    Fins Educacionais: Estudo de renderização 2D e vetores de rede.
    Otimização: SUNC 2026 (Madium)
    Visual: Black & Cyan Industrial
]]

local rs = game:GetService("RunService")
local players = game:GetService("Players")
local lp = players.LocalPlayer
local camera = workspace.CurrentCamera

local Hyper = {
    Active = false,
    EspActive = false,
    Intensity = 40,
    TracerColor = Color3.fromRGB(0, 255, 255),
    EnemyColor = Color3.fromRGB(255, 0, 0)
}

local cache = {
    tracers = {},
    ghostModel = nil
}

-- [ SISTEMA DE TRACER (DRAWING API - STEALTH) ]
local function createTracer()
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Transparency = 0.8
    line.Color = Hyper.TracerColor
    return line
end

local function updateVisuals()
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local root = p.Character.HumanoidRootPart
            local pos, onScreen = camera:WorldToViewportPoint(root.Position)
            
            if Hyper.EspActive and onScreen then
                local tracer = cache.tracers[p] or createTracer()
                cache.tracers[p] = tracer
                tracer.Visible = true
                tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                tracer.To = Vector2.new(pos.X, pos.Y)
            else
                if cache.tracers[p] then cache.tracers[p].Visible = false end
            end
        else
            if cache.tracers[p] then cache.tracers[p].Visible = false end
        end
    end
end

-- [ INTERFACE HYPER'S DESYNC ]
local GuiParent = (gethui and gethui()) or game:GetService("CoreGui")
if GuiParent:FindFirstChild("HypersDesync") then GuiParent.HypersDesync:Destroy() end

local ScreenGui = Instance.new("ScreenGui", GuiParent)
ScreenGui.Name = "HypersDesync"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 220, 0, 180)
Main.Position = UDim2.new(0.5, -110, 0.7, 0)
Main.BackgroundColor3 = Color3.new(0,0,0)
Main.Draggable, Main.Active = true, true
Instance.new("UICorner", Main)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(80, 80, 80)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "HYPER'S DESYNC"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.BackgroundTransparency = 1

local OnBtn = Instance.new("TextButton", Main)
OnBtn.Size = UDim2.new(0.4, 0, 0, 40)
OnBtn.Position = UDim2.new(0.07, 0, 0.3, 0)
OnBtn.Text = "DESYNC ON"
OnBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OnBtn.TextColor3 = Color3.new(1,1,1)
OnBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OnBtn)

local OffBtn = Instance.new("TextButton", Main)
OffBtn.Size = UDim2.new(0.4, 0, 0, 40)
OffBtn.Position = UDim2.new(0.53, 0, 0.3, 0)
OffBtn.Text = "DESYNC OFF"
OffBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
OffBtn.TextColor3 = Color3.new(1,1,1)
OffBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OffBtn)

local EspBtn = Instance.new("TextButton", Main)
EspBtn.Size = UDim2.new(0.86, 0, 0, 45)
EspBtn.Position = UDim2.new(0.07, 0, 0.65, 0)
EspBtn.Text = "TRACER & ESP: OFF"
EspBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
EspBtn.TextColor3 = Color3.new(1,1,1)
EspBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", EspBtn)

-- [ GATILHOS ]
OnBtn.MouseButton1Click:Connect(function()
    Hyper.Active = true
    OnBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    OffBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
end)

OffBtn.MouseButton1Click:Connect(function()
    Hyper.Active = false
    OnBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    OffBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    if raknet then pcall(function() raknet.remove_send_hook() end) end
end)

EspBtn.MouseButton1Click:Connect(function()
    Hyper.EspActive = not Hyper.EspActive
    EspBtn.Text = Hyper.EspActive and "TRACER & ESP: ON" or "TRACER & ESP: OFF"
    EspBtn.BackgroundColor3 = Hyper.EspActive and Color3.fromRGB(0, 140, 200) or Color3.fromRGB(20, 20, 25)
end)

-- [ LOOP PRINCIPAL ]
rs.RenderStepped:Connect(function()
    updateVisuals()
    
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if Hyper.Active and root then
        local t = tick()
        local velo = Vector3.new(math.sin(t*14)*Hyper.Intensity, 0, math.cos(t*14)*Hyper.Intensity)
        root.AssemblyLinearVelocity = velo
        
        rs.Heartbeat:Wait()
        root.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
end)
