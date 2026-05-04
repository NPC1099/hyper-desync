--[[ 
    NETWORK FORENSICS V12 - UNIVERSAL & STABLE
    Foco: Compatibilidade Total, Sincronia de Velocidade e Reset de CFrame.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- --- CONFIGURAÇÕES DE ENGENHARIA ---
local UPDATE_RATE = 0.05 
local MAX_POOL_SIZE = 180 
local TRAIL_LIFETIME = 0.45
local SMOOTHING_FACTOR = 0.2

local TrailPool = {}
local PlayerData = {}
local accumulator = 0

-- Pasta para organização
local DebugFolder = workspace:FindFirstChild("NetDebug") or Instance.new("Folder")
DebugFolder.Name = "NetDebug"
DebugFolder.Parent = workspace

-- --- SISTEMA DE POOLING PROFISSIONAL (RESET TOTAL) ---
local function getTrailPart()
    for _, item in ipairs(TrailPool) do
        if not item.Active then
            item.Active = true
            item.Life = TRAIL_LIFETIME
            -- Reset Total de Propriedades
            local p = item.Part
            p.Size = Vector3.new(0.6, 0.6, 0.6)
            p.Transparency = 0.6
            p.Material = Enum.Material.Neon
            p.Color = Color3.new(1, 1, 1) 
            return p
        end
    end
    
    if #TrailPool < MAX_POOL_SIZE then
        local p = Instance.new("Part")
        p.Size = Vector3.new(0.6, 0.6, 0.6)
        p.Anchored, p.CanCollide = true, false
        p.Material = Enum.Material.Neon
        p.Parent = DebugFolder
        local newItem = {Part = p, Active = true, Life = TRAIL_LIFETIME}
        table.insert(TrailPool, newItem)
        return p
    end
    return nil
end

local function releaseTrail(item)
    item.Active = false
    item.Part.Transparency = 1
    -- Move para longe para evitar glitches visuais
    item.Part.CFrame = CFrame.new(0, -9999, 0)
end

local function updatePool(dt)
    for _, item in ipairs(TrailPool) do
        if item.Active then
            item.Life = item.Life - dt
            if item.Life <= 0 then
                releaseTrail(item)
            end
        end
    end
end

-- Limpeza de memória
Players.PlayerRemoving:Connect(function(p) PlayerData[p] = nil end)

-- --- LOOP DE ANÁLISE (COMPATIBILIDADE UNIVERSAL) ---
RunService.Heartbeat:Connect(function(dt)
    updatePool(dt)
    
    accumulator = accumulator + dt
    if accumulator < UPDATE_RATE then return end
    local tickDt = math.max(accumulator, 1e-4) 
    accumulator = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Inicialização Segura
                if not PlayerData[player] then
                    PlayerData[player] = {
                        lastPos = hrp.Position,
                        lastVel = hrp.Velocity,
                        smoothAccel = Vector3.new(0,0,0),
                        errorScore = 0
                    }
                end

                local data = PlayerData[player]
                local currentPos = hrp.Position
                local currentVel = hrp.Velocity

                -- 1. Cálculo de Velocidade Blend e Aceleração
                local measuredVel = (currentPos - data.lastPos) / tickDt
                local blendedVel = (measuredVel + currentVel) * 0.5
                local rawAccel = (blendedVel - data.lastVel) / tickDt
                data.smoothAccel = (data.smoothAccel * (1 - SMOOTHING_FACTOR)) + (rawAccel * SMOOTHING_FACTOR)

                -- 2. Predição Física
                local predictedPos = data.lastPos + (blendedVel * tickDt) + (0.5 * data.smoothAccel * tickDt * tickDt)
                local predictionError = (currentPos - predictedPos).Magnitude

                -- 3. Lógica de Erro com Filtro de Teleporte (Sem 'continue' para ser Universal)
                if predictionError > 80 then
                    -- Reset por teleporte/respawn
                    data.errorScore = 0
                    data.lastPos = currentPos
                    data.lastVel = currentVel
                else
                    -- Threshold Dinâmico e Score
                    local dynamicThreshold = 6 + (currentVel.Magnitude * 0.08) + (data.smoothAccel.Magnitude * 0.02)
                    
                    if predictionError > dynamicThreshold then
                        data.errorScore = math.min((data.errorScore or 0) + 1.6, 20)
                    else
                        data.errorScore = math.max(0, (data.errorScore or 0) - 0.5)
                    end

                    -- 4. Visualização
                    local pPart = getTrailPart()
                    if pPart then
                        pPart.Color = Color3.new(0, 1, 1)
                        pPart.CFrame = CFrame.new(predictedPos)
                    end

                    if data.errorScore > 5 then
                        local rPart = getTrailPart()
                        if rPart then
                            rPart.Color = Color3.new(1, 0, 0)
                            rPart.Size = Vector3.new(2.2, 2.2, 2.2)
                            rPart.CFrame = CFrame.new(currentPos)
                        end
                    end

                    -- Atualização de Estado (Consistente com o modelo físico)
                    data.lastPos = currentPos
                    data.lastVel = blendedVel
                end
            end
        end
    end
end)
