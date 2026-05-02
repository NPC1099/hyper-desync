repeat task.wait() until game:IsLoaded()
pcall(function() setfpscap(999) end)
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local SoundService   = game:GetService("SoundService")
local Lighting       = game:GetService("Lighting")
local HttpService    = game:GetService("HttpService")
local LocalPlayer    = Players.LocalPlayer
local VisualSetters = {}
local mobileButtonContainer
local apMain
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local NORMAL_SPEED = 60
local CARRY_SPEED  = 30
local LAGGER_SPEED = 15
local FOV_VALUE    = 70
local UI_SCALE     = isMobile and 0.65 or 1.0
local function getMobileOptimized(pcValue, mobileValue)
    return isMobile and mobileValue or pcValue
end
local lastNoclipUpdate = 0
RunService.Stepped:Connect(function()
    local now = tick()
    if now - lastNoclipUpdate < 0.1 then return end
    lastNoclipUpdate = now
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)
local speedToggled       = false
local fastestStealEnabled = false
local laggerToggled      = false
local autoBatToggled     = false
local hittingCooldown    = false
local fullAutoPlayEnabled = false
local fullAutoPlayConn = nil
local fullAutoPlayLeftEnabled = false
local fullAutoPlayRightEnabled = false
local fullAutoPlayLeftConn = nil
local fullAutoPlayRightConn = nil
local fullAutoLeftSetter = nil
local fullAutoRightSetter = nil
local brainrotReturnLeftEnabled  = false
local brainrotReturnRightEnabled = false
local brainrotReturnCooldown     = false
local lastKnownHealth            = 100
local G_myPlotSide               = nil
local G_myPlotName               = nil
local G_tpAutoEnabled            = false
local G_autoPlayAfterTP          = false
local G_countdownActive          = false
local ultraModeEnabled           = false
local autoSwingEnabled           = false
local noCamCollisionEnabled      = false
local noCamCollisionConn         = nil
local noCamParts                 = {}
local _antiLagDescConn           = nil
local lastBatSwing               = 0
local BAT_SWING_COOLDOWN         = 0.12
local SPAWN_DETECT_RADIUS        = 40
local COUNTDOWN_TARGET           = 4.9
local SPAWN_Z_RIGHT_THRESHOLD    = 60
local SPAWN_LEFT                 = Vector3.new(-466.429901, 0, 113.553757)
local SPAWN_RIGHT                = Vector3.new(-466.42984,  0, 6.55357218)
local AP_Offsets  = {{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0}}
local APR_Offsets = {{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0}}
local BR_L2 = Vector3.new(-475.5, -3.75, 100.5)
local BR_L3 = Vector3.new(-486.5, -3.75, 100.5)
local BR_R2 = Vector3.new(-475.50, -3.95, 17.55)
local BR_R3 = Vector3.new(-486.76, -3.95, 17.55)
local Keybinds = {
    AutoBat        = Enum.KeyCode.E,
    SpeedToggle    = Enum.KeyCode.Q,
    LaggerToggle   = Enum.KeyCode.R,
    InfiniteJump   = Enum.KeyCode.M,
    UIToggle       = Enum.KeyCode.U,
    DropBrainrot   = Enum.KeyCode.X,
    FloatToggle    = Enum.KeyCode.J,
    FullAutoLeft   = Enum.KeyCode.G,
    FullAutoRight  = Enum.KeyCode.H,
    TPDown         = Enum.KeyCode.F,
}
local isStealing     = false
local stealStartTime = nil
local StealData      = {}
local lastStealTick  = 0
local plotCache      = {}
local plotCacheTime  = {}
local cachedPrompts  = {}
local promptCacheTime= 0
local Settings = {
    AutoStealEnabled = false,
    StealRadius      = 20,
    StealDuration    = 0.25,
}
local Values = {
    STEAL_RADIUS         = 20,
    STEAL_DURATION       = 0.2,
    STEAL_COOLDOWN       = 0.1,
    PLOT_CACHE_DURATION  = 2,
    PROMPT_CACHE_REFRESH = 0.15,
    DEFAULT_GRAVITY      = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER            = 35,
    HOP_COOLDOWN         = 0.08,
}
local function detectMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil, nil end
    local myName = LocalPlayer.DisplayName or LocalPlayer.Name
    for _, plot in ipairs(plots:GetChildren()) do
        local ok, result = pcall(function()
            local sign = plot:FindFirstChild("PlotSign"); if not sign then return nil end
            local sg = sign:FindFirstChild("SurfaceGui"); if not sg then return nil end
            local fr = sg:FindFirstChild("Frame"); if not fr then return nil end
            local tl = fr:FindFirstChild("TextLabel"); if not tl then return nil end
            if tl.Text:find(myName, 1, true) then
                local spawnObj = plot:FindFirstChild("Spawn")
                if spawnObj then
                    local z = spawnObj.CFrame.Position.Z
                    return z < SPAWN_Z_RIGHT_THRESHOLD and "left" or "right"
                end
            end
            return nil
        end)
        if ok and result then return result, plot.Name end
    end
    return nil, nil
end

local function refreshMyPlotSide()
    local side, plotName = detectMyPlot()
    G_myPlotSide = side; G_myPlotName = plotName
    return side
end

task.spawn(function()
    while true do
        task.wait(2)
        if G_tpAutoEnabled then refreshMyPlotSide() end
    end
end)

task.spawn(function()
    local plots = workspace:WaitForChild("Plots", 30); if not plots then return end
    local myName = LocalPlayer.DisplayName or LocalPlayer.Name
    local function watchPlot(plot)
        pcall(function()
            local tl = plot:WaitForChild("PlotSign",5):WaitForChild("SurfaceGui",5):WaitForChild("Frame",5):WaitForChild("TextLabel",5)
            if not tl then return end
            tl:GetPropertyChangedSignal("Text"):Connect(function() refreshMyPlotSide() end)
            if tl.Text:find(myName, 1, true) then refreshMyPlotSide() end
        end)
    end
    for _, plot in ipairs(plots:GetChildren()) do task.spawn(watchPlot, plot) end
    plots.ChildAdded:Connect(function(plot) task.spawn(watchPlot, plot) end)
end)
local function calculateFastestStealSpeed()
    local char = LocalPlayer.Character; if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    
    local targetPos = nil
    if fullAutoPlayLeftEnabled then
        local pts = {FAP_L1, FAP_L2, FAP_L3, FAP_L4, FAP_L5}
        local phase = FAP_LeftPhase
        if type(phase) ~= "number" or phase < 1 then phase = 1 end
        if phase > 5 then phase = 5 end
        targetPos = pts[phase]
    elseif fullAutoPlayRightEnabled then
        local pts = {FAP_R1, FAP_R2, FAP_R3, FAP_R4, FAP_R5}
        local phase = FAP_RightPhase
        if type(phase) ~= "number" or phase < 1 then phase = 1 end
        if phase > 5 then phase = 5 end
        targetPos = pts[phase]
    else
        return nil
    end
    
    if not targetPos then return end
    
    local dist = Vector3.new(
        targetPos.X - hrp.Position.X,
        0,
        targetPos.Z - hrp.Position.Z
    ).Magnitude
    
    if dist < 0.1 then return end
    local TARGET_TIME = 1.65
    local requiredSpeed = dist / TARGET_TIME
    
    -- clamp to reasonable range
    requiredSpeed = math.clamp(requiredSpeed, 1, 9999)
    
    return requiredSpeed
end

RunService.Heartbeat:Connect(function()
    if not fastestStealEnabled then return end
    if not (fullAutoPlayLeftEnabled or fullAutoPlayRightEnabled) then return end
    local char = LocalPlayer.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local md = hum.MoveDirection; if md.Magnitude == 0 then return end
    local spd = calculateFastestStealSpeed()
    if spd then
        hrp.AssemblyLinearVelocity = Vector3.new(md.X * spd, hrp.AssemblyLinearVelocity.Y, md.Z * spd)
    end
end)

local function syncStealSettings()
    Values.STEAL_RADIUS   = Settings.StealRadius
    Values.STEAL_DURATION = Settings.StealDuration
    Settings.StealRadius  = Values.STEAL_RADIUS
    Settings.StealDuration= Values.STEAL_DURATION
end
local STEAL_COOLDOWN       = Values.STEAL_COOLDOWN
local PLOT_CACHE_DURATION  = Values.PLOT_CACHE_DURATION
local PROMPT_CACHE_REFRESH = Values.PROMPT_CACHE_REFRESH
local Enabled = {
    AntiRagdoll  = false,
    AutoSteal    = false,
    InfiniteJump = false,
    ShinyGraphics= false,
    Optimizer    = false,
    Unwalk       = false,
    RemoveAccessories = false,
}
local Connections          = {}
local originalTransparency = {}
local savedAnimations      = {}
local xrayEnabled = false
local h, hrp, speedLbl
local progressConnection = nil
local gui, main
local speedSwBg, speedSwCircle
local laggerSwBg, laggerSwCircle
local batSwBg, batSwCircle
local waitingForKey = nil
local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end
local function isMyPlotByName(plotName)
    local currentTime = tick()
    if plotCache[plotName] and (currentTime - (plotCacheTime[plotName] or 0)) < PLOT_CACHE_DURATION then
        return plotCache[plotName]
    end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then plotCache[plotName]=false; plotCacheTime[plotName]=currentTime; return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then plotCache[plotName]=false; plotCacheTime[plotName]=currentTime; return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yourBase = sign:FindFirstChild("YourBase")
        if yourBase and yourBase:IsA("BillboardGui") then
            local result = yourBase.Enabled == true
            plotCache[plotName]=result; plotCacheTime[plotName]=currentTime
            return result
        end
    end
    plotCache[plotName]=false; plotCacheTime[plotName]=currentTime
    return false
end
local function findNearestPrompt()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local currentTime = tick()
    if currentTime - promptCacheTime < PROMPT_CACHE_REFRESH and #cachedPrompts > 0 then
        local nearestPrompt, nearestDist, nearestName = nil, math.huge, nil
        for _, data in ipairs(cachedPrompts) do
            if data.spawn then
                local dist = (data.spawn.Position - root.Position).Magnitude
                if dist <= Settings.StealRadius and dist < nearestDist then
                    nearestPrompt = data.prompt; nearestDist = dist; nearestName = data.name
                end
            end
        end
        if nearestPrompt then return nearestPrompt, nearestDist, nearestName end
    end
    cachedPrompts = {}; promptCacheTime = currentTime
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local nearestPrompt, nearestDist, nearestName = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, podium in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base  = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - root.Position).Magnitude
                    local att = spawn:FindFirstChild("PromptAttachment")
                    if att then
                        for _, ch in ipairs(att:GetChildren()) do
                            if ch:IsA("ProximityPrompt") then
                                table.insert(cachedPrompts, {prompt=ch, spawn=spawn, name=podium.Name})
                                if dist <= Settings.StealRadius and dist < nearestDist then
                                    nearestPrompt=ch; nearestDist=dist; nearestName=podium.Name
                                end
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
    return nearestPrompt, nearestDist, nearestName
end
local ProgressLabel, ProgressPercentLabel, ProgressBarFill, RadiusInput, DurationInput
local function ResetProgressBar()
    if ProgressLabel        then ProgressLabel.Text = "READY" end
    if ProgressPercentLabel then ProgressPercentLabel.Text = "" end
    if ProgressBarFill      then ProgressBarFill.Size = UDim2.new(0,0,1,0) end
end
local function executeSteal(prompt, name)
    local currentTime = tick()
    if currentTime - lastStealTick < STEAL_COOLDOWN then return end
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt] = {hold={}, trigger={}, ready=true}
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger, c.Function) end
                end
            else StealData[prompt].useFallback = true end
        end)
    end
    local data = StealData[prompt]
    if not data.ready then return end
    data.ready=false; isStealing=true; stealStartTime=currentTime; lastStealTick=currentTime
    if ProgressLabel then ProgressLabel.Text = name or "STEALING..." end
    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then progressConnection:Disconnect(); return end
        local prog = math.clamp((tick()-stealStartTime)/Settings.StealDuration, 0, 1)
        if ProgressBarFill      then ProgressBarFill.Size = UDim2.new(prog,0,1,0) end
        if ProgressPercentLabel then ProgressPercentLabel.Text = math.floor(prog*100).."%" end
    end)
    task.spawn(function()
        local ok = false
        pcall(function()
            if not data.useFallback then
                for _, f in ipairs(data.hold) do task.spawn(f) end
                task.wait(Settings.StealDuration)
                for _, f in ipairs(data.trigger) do task.spawn(f) end
                ok=true
            end
        end)
        if not ok and fireproximityprompt then
            pcall(function() fireproximityprompt(prompt); ok=true end)
        end
        if not ok then
            pcall(function()
                prompt:InputHoldBegin(); task.wait(Settings.StealDuration); prompt:InputHoldEnd(); ok=true
            end)
        end
        task.wait(Settings.StealDuration * 0.3)
        if progressConnection then progressConnection:Disconnect() end
        ResetProgressBar()
        task.wait(0.05)
        data.ready=true; isStealing=false
    end)
end
local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local p,_,n = findNearestPrompt()
        if p then
            local char = LocalPlayer.Character
            local hrpLocal = char and char:FindFirstChild("HumanoidRootPart")
            if hrpLocal then
                hrpLocal.AssemblyLinearVelocity = Vector3.new(0, hrpLocal.AssemblyLinearVelocity.Y, 0)
            end
            executeSteal(p,n)
        end
    end)
end
local function stopAutoSteal()
    if Connections.autoSteal then Connections.autoSteal:Disconnect(); Connections.autoSteal=nil end
    isStealing=false; lastStealTick=0
    plotCache={}; plotCacheTime={}; cachedPrompts={}
    ResetProgressBar()
end
local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local st = hum:GetState()
            if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    local pm = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                    if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
                end)
                if root then root.Velocity=Vector3.new(0,0,0); root.RotVelocity=Vector3.new(0,0,0) end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end
        end
    end)
end
local function stopAntiRagdoll()
    if Connections.antiRagdoll then Connections.antiRagdoll:Disconnect(); Connections.antiRagdoll=nil end
end
local IJ_JumpConn = nil
local IJ_FallConn = nil
local function startInfiniteJump()
    if IJ_JumpConn then IJ_JumpConn:Disconnect() end
    if IJ_FallConn then IJ_FallConn:Disconnect() end
    IJ_JumpConn = UserInputService.JumpRequest:Connect(function()
        if not Enabled.InfiniteJump then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z) end
    end)
    IJ_FallConn = RunService.Heartbeat:Connect(function()
        if not Enabled.InfiniteJump then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and root.Velocity.Y < -120 then
            root.Velocity = Vector3.new(root.Velocity.X, -120, root.Velocity.Z)
        end
    end)
end
local function stopInfiniteJump()
    if IJ_JumpConn then IJ_JumpConn:Disconnect(); IJ_JumpConn = nil end
    if IJ_FallConn then IJ_FallConn:Disconnect(); IJ_FallConn = nil end
end
local function startUnwalk()
    local c = LocalPlayer.Character; if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim = c:FindFirstChild("Animate")
    if anim then savedAnimations.Animate=anim:Clone(); anim:Destroy() end
end
local function stopUnwalk()
    local c = LocalPlayer.Character
    if c and savedAnimations.Animate then savedAnimations.Animate:Clone().Parent=c; savedAnimations.Animate=nil end
end
local xrayDescendantConn = nil
local function isXrayTarget(obj)
    if not obj:IsA("BasePart") then return false end
    if not obj.Anchored then return false end
    local n = obj.Name:lower(); local pn = (obj.Parent and obj.Parent.Name:lower()) or ""
    return n:find("base") ~= nil or pn:find("base") ~= nil
end
local function applyXrayToPart(obj)
    pcall(function()
        if isXrayTarget(obj) and originalTransparency[obj] == nil then
            originalTransparency[obj] = obj.LocalTransparencyModifier
            obj.LocalTransparencyModifier = 0.85
        end
    end)
end
local function applyXrayToAll()
    pcall(function() for _, obj in ipairs(workspace:GetDescendants()) do applyXrayToPart(obj) end end)
end
local function startXrayWatcher()
    if xrayDescendantConn then return end
    xrayDescendantConn = workspace.DescendantAdde
