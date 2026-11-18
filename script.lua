--[[
    Xen FF3 - Football Fusion 3
    UI: Airflow
    Credits: Original logic adapted for Airflow UI
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
while not Player do
    Player = Players.LocalPlayer
    task.wait()
end

-- Load Airflow
local Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/PookiePepelsss/Airflow-UI/refs/heads/main/Source.luau"))()
Airflow:LoadFont({Name = "ValleySans"})

-- Settings
local autocatchon = false
local catchdistance = 10
local magson = false
local magsrange = 20
local magsdelayon = false
local magsdelay = 0
local showhitboxon = false
local hitboxes = {}
local catchresizeon = false
local catchresizerange = 10
local lmgg = 0
local magmode = "FTI"
local speedEnabled = false
local speedValue = 0.1
local movementLoop = nil
local jumpoweron = false
local jumpboost = 50
local nojpcooldownon = false
local njcconnections = {}
local pullvector = false
local pullvectorpower = 1
local pullvectordistance = 5
local clicktackleon = false
local clicktacklerange = 5
local ballpathOn = false
local ballpathColor = Color3.fromRGB(128, 0, 128)
local ballpathConnection = nil
local deleteOOBEnabled = false

-- Helper Functions
local function gotfb()
    local character = Player.Character
    if not character then return false end
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():match("football") or tool:FindFirstChild("Handle")) then
            return true
        end
    end
    return false
end

local function getAllFootballBalls()
    local balls = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart")
            and obj.Name:lower():match("football")
            and not obj.Anchored
        then
            table.insert(balls, obj)
        end
    end
    return balls
end

local function findclosestball()
    local character = Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = character.HumanoidRootPart
    local closestball, mindist = nil, math.huge
    for _, ball in ipairs(getAllFootballBalls()) do
        local dist = (hrp.Position - ball.Position).Magnitude
        if dist < mindist then closestball, mindist = ball, dist end
    end
    return closestball, mindist
end

local function hitboxx(oid)
    if not oid or hitboxes[oid] or not magson or not showhitboxon then return end
    local holder = oid:FindFirstAncestorOfClass("Model")
    if holder and Players:GetPlayerFromCharacter(holder) then return end
    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Size = Vector3.new(magsrange, magsrange, magsrange)
    hitbox.Anchored = true
    hitbox.CanCollide = false
    hitbox.Transparency = 0.2
    hitbox.Material = Enum.Material.ForceField
    hitbox.Color = Color3.fromRGB(128, 0, 128)
    hitbox.CastShadow = false
    hitbox.CFrame = oid.CFrame
    hitbox.Shape = Enum.PartType.Ball
    hitbox.Parent = oid
    hitboxes[oid] = { part = hitbox }
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not oid or not oid.Parent or not magson or not showhitboxon then
            if hitbox then hitbox:Destroy() end
            if connection then connection:Disconnect() end
            hitboxes[oid] = nil
            return
        end
        local h = oid:FindFirstAncestorOfClass("Model")
        if h and Players:GetPlayerFromCharacter(h) then
            if hitbox then hitbox:Destroy() end
            if connection then connection:Disconnect() end
            hitboxes[oid] = nil
            return
        end
        hitbox.CFrame = oid.CFrame
        hitbox.Size = Vector3.new(magsrange, magsrange, magsrange)
        hitbox.Color = Color3.fromRGB(128, 0, 128)
    end)
end

local function fitbalsize()
    for oid, data in pairs(hitboxes) do
        if data and data.part then
            data.part.Size = Vector3.new(magsrange, magsrange, magsrange)
        else
            if data and data.part then data.part:Destroy() end
            hitboxes[oid] = nil
        end
    end
end

local function removeHitboxes()
    for oid, football in pairs(hitboxes) do
        if football.part then football.part:Destroy() end
    end
    hitboxes = {}
end

local function footballhitbox()
    if not magson then return end
    for _, ball in ipairs(getAllFootballBalls()) do
        hitboxx(ball)
    end
end

local function getfutbal()
    local character = Player.Character
    if not (character and character:FindFirstChild("HumanoidRootPart")) then return nil end
    local playerpos = character.HumanoidRootPart.Position
    local range = math.max(magsrange, 1)
    local closest, mindist = nil, math.huge
    for _, ball in ipairs(getAllFootballBalls()) do
        local dist = (ball.Position - playerpos).Magnitude
        if dist < mindist and dist <= range then
            closest, mindist = ball, dist
        end
    end
    return closest
end

local function catch(ball)
    if not ball then return nil end
    local character = Player.Character
    if not character then return nil end

    local candidates = {}
    local cl = character:FindFirstChild("CatchLeft")
    local cr = character:FindFirstChild("CatchRight")
    if cl and cl:IsA("BasePart") then table.insert(candidates, cl) end
    if cr and cr:IsA("BasePart") then table.insert(candidates, cr) end

    if #candidates == 0 then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then table.insert(candidates, hrp) end
    end

    local closest, mindist = nil, math.huge
    for _, cp in ipairs(candidates) do
        local dist = (cp.Position - ball.Position).Magnitude
        if dist < mindist then closest, mindist = cp, dist end
    end
    return closest
end

local function rrrrrrrsizenugget(character)
    if not character then return end
    local catchleft = character:FindFirstChild("CatchLeft")
    local catchright = character:FindFirstChild("CatchRight")
    if catchresizeon then
        if catchleft then catchleft.Size = Vector3.new(catchresizerange, catchresizerange, catchresizerange) catchleft.Transparency = 1 end
        if catchright then catchright.Size = Vector3.new(catchresizerange, catchresizerange, catchresizerange) catchright.Transparency = 1 end
    else
        if catchleft then catchleft.Size = Vector3.new(0.75, 5, 1.5) catchleft.Transparency = 1 end
        if catchright then catchright.Size = Vector3.new(0.75, 5, 1.5) catchright.Transparency = 1 end
    end
end

local function startMovementSystem()
    if not movementLoop then
        movementLoop = RunService.Heartbeat:Connect(function(dt)
            if not speedEnabled then return end
            local character = Player.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then return end
            local hrp = character.HumanoidRootPart
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.MoveDirection.Magnitude > 0 then
                local moveVector = humanoid.MoveDirection * (speedValue * 8) * dt
                hrp.CFrame = hrp.CFrame + moveVector
            end
        end)
    end
end

local function stopMovementSystem()
    if movementLoop then
        movementLoop:Disconnect()
        movementLoop = nil
    end
end

local function whenmoving(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidrootpart = character:WaitForChild("HumanoidRootPart")
    humanoid.StateChanged:Connect(function(_, newstate)
        if newstate == Enum.HumanoidStateType.Jumping and jumpoweron then
            task.wait(0.05)
            humanoidrootpart.AssemblyLinearVelocity = humanoidrootpart.AssemblyLinearVelocity + Vector3.new(0, jumpboost - 50, 0)
        end
    end)
end

local function njc(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid")
    local connection = RunService.Stepped:Connect(function()
        if nojpcooldownon then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
    end)
    njcconnections[char] = connection
end

local function findclosestsleveesor(maxdistance)
    local character = Player.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closestdistance = maxdistance
    local closestcharacter = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == Player or plr.Team == Player.Team then continue end
        local targetchar = plr.Character
        if not targetchar then continue end
        local targethrp = targetchar:FindFirstChild("HumanoidRootPart")
        if not targethrp then continue end
        local hasfootball = false
        for _, item in ipairs(targetchar:GetChildren()) do
            if item:IsA("Tool") and item.Name:match("Football") then hasfootball = true break end
        end
        if not hasfootball then continue end
        local distance = (hrp.Position - targethrp.Position).Magnitude
        if distance < closestdistance then
            closestdistance = distance
            closestcharacter = targetchar
        end
    end
    return closestcharacter
end

local function beamProjectile(g, v0, x0, t1)
    local c = 0.125
    local p3 = 0.5 * g * t1 * t1 + v0 * t1 + x0
    local p2 = p3 - (g * t1 * t1 + v0 * t1) / 3
    local p1 = (c * g * t1 * t1 + 0.5 * v0 * t1 + x0 - c * (x0 + p3)) / (3 * c) - p2
    local curve0 = (p1 - x0).Magnitude
    local curve1 = (p2 - p3).Magnitude
    local b = (x0 - p3).Unit
    local r1 = (p1 - x0).Unit
    local u1 = r1:Cross(b).Unit
    local r2 = (p2 - p3).Unit
    local u2 = r2:Cross(b).Unit
    b = u1:Cross(r1).Unit
    local cf1 = CFrame.new(x0.X, x0.Y, x0.Z, r1.X, u1.X, b.X, r1.Y, u1.Y, b.Y, r1.Z, u1.Z, b.Z)
    local cf2 = CFrame.new(p3.X, p3.Y, p3.Z, r2.X, u2.X, b.X, r2.Y, u2.Y, b.Y, r2.Z, u2.Z, b.Z)
    return curve0, -curve1, cf1, cf2
end

local function TriggerTouchEvent()
    local Camera = Workspace.CurrentCamera
    local xPos = Camera.ViewportSize.X / 2
    local yPos = Camera.ViewportSize.Y / 2
    VIM:SendTouchEvent(1, Enum.UserInputState.Begin.Value, xPos, yPos)
    task.wait(0.005)
    VIM:SendTouchEvent(1, Enum.UserInputState.End.Value, xPos, yPos)
end

-- =====================
--        AIRFLOW UI
-- =====================

local Window = Airflow:CreateWindow({
    Title = "ByteWTF",
    Subtitle = "ByteWTF ff3",
    LoadingTitle = "BYTE FF3",
    LoadingText = "Football Fusion 3",
    Keybind = Enum.KeyCode.RightControl,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XenFF3",
        FileName = "XenFF3Config"
    },
})

-- =====================
--    CATCHING TAB
-- =====================

local CatchingTab = Window:CreateTab("Catching", "hand")

-- Mags Section
local MagsSection = CatchingTab:CreateSection("Magnetism")

CatchingTab:CreateToggle({
    Name = "Mags",
    Default = false,
    Flag = "MagsToggle",
    Callback = function(Value)
        magson = Value
        if not Value then
            removeHitboxes()
        elseif showhitboxon then
            footballhitbox()
        end
    end,
})

local MagsRangeSlider = CatchingTab:CreateSlider({
    Name = "Mags Range",
    Range = {1, 30},
    Increment = 0.1,
    Suffix = " studs",
    Default = 20,
    Flag = "MagsRange",
    Callback = function(Value)
        magsrange = Value
        if magson and showhitboxon then fitbalsize() end
    end,
})

CatchingTab:CreateSlider({
    Name = "Mags Delay",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "s",
    Default = 0,
    Flag = "MagsDelay",
    Callback = function(Value)
        magsdelay = Value
        magsdelayon = Value > 0
    end,
})

CatchingTab:CreateDropdown({
    Name = "Mag Type",
    Options = {"Blatant", "Legit"},
    Default = "Blatant",
    Flag = "MagType",
    Callback = function(Option)
        -- Airflow passes a plain string for single-select dropdowns
        local val = type(Option) == "table" and Option[1] or Option
        local newRange = (val == "Blatant") and 20 or 8
        magsrange = newRange
        pcall(function() MagsRangeSlider:Set(newRange) end)
    end,
})

CatchingTab:CreateDropdown({
    Name = "Mag Mode",
    Options = {"FTI", "CFrame"},
    Default = "FTI",
    Flag = "MagMode",
    Callback = function(Option)
        magmode = type(Option) == "table" and Option[1] or Option
    end,
})

CatchingTab:CreateToggle({
    Name = "Show Hitbox",
    Default = false,
    Flag = "ShowHitbox",
    Callback = function(Value)
        showhitboxon = Value
        if not Value then
            removeHitboxes()
        elseif magson then
            footballhitbox()
        end
    end,
})

-- Auto Catch Section
local AutoCatchSection = CatchingTab:CreateSection("Auto Catch")

CatchingTab:CreateToggle({
    Name = "Auto Catch",
    Default = false,
    Flag = "AutoCatch",
    Callback = function(Value)
        autocatchon = Value
    end,
})

CatchingTab:CreateSlider({
    Name = "Auto Catch Radius",
    Range = {1, 25},
    Increment = 1,
    Suffix = " studs",
    Default = 10,
    Flag = "AutoCatchRadius",
    Callback = function(Value)
        catchdistance = Value
    end,
})

-- Catch Resize Section
local CatchResizeSection = CatchingTab:CreateSection("Catch Resize")

CatchingTab:CreateToggle({
    Name = "Catch Resize",
    Default = false,
    Flag = "CatchResize",
    Callback = function(Value)
        catchresizeon = Value
        rrrrrrrsizenugget(Player.Character)
    end,
})

CatchingTab:CreateSlider({
    Name = "Catch Resize Range",
    Range = {1, 20},
    Increment = 0.5,
    Suffix = " studs",
    Default = 10,
    Flag = "CatchResizeRange",
    Callback = function(Value)
        catchresizerange = Value
        rrrrrrrsizenugget(Player.Character)
    end,
})

-- Ball Path Section
local BallPathSection = CatchingTab:CreateSection("Ball Path")

CatchingTab:CreateToggle({
    Name = "Ball Path",
    Default = false,
    Flag = "BallPath",
    Callback = function(Value)
        ballpathOn = Value
        if not Value then
            if ballpathConnection then ballpathConnection:Disconnect() ballpathConnection = nil end
            for _, obj in ipairs(Workspace.Terrain:GetChildren()) do
                if obj:IsA("Beam") and obj.Name == "BallPath" then obj:Destroy()
                elseif obj:IsA("Attachment") and obj.Name == "BallPathAttachment" then obj:Destroy() end
            end
        else
            if ballpathConnection then ballpathConnection:Disconnect() end
            ballpathConnection = Workspace.ChildAdded:Connect(function(ball)
                if ball.Name:lower():find("football") and ball:IsA("BasePart") then
                    task.wait()
                    local vel = ball.Velocity
                    local pos = ball.Position
                    local c0, c1, cf1, cf2 = beamProjectile(Vector3.new(0, -28, 0), vel, pos, 10)
                    local beam = Instance.new("Beam")
                    local a0 = Instance.new("Attachment")
                    local a1 = Instance.new("Attachment")
                    beam.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, ballpathColor),
                        ColorSequenceKeypoint.new(1, ballpathColor)
                    }
                    beam.Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.01, 0),
                        NumberSequenceKeypoint.new(0.99, 0),
                        NumberSequenceKeypoint.new(1, 0.01)
                    }
                    beam.CurveSize0 = c0
                    beam.CurveSize1 = c1
                    beam.Segments = 1750
                    beam.Width0 = 1
                    beam.Width1 = 1
                    beam.Name = "BallPath"
                    beam.Parent = Workspace.Terrain
                    a0.Parent = Workspace.Terrain
                    a1.Parent = Workspace.Terrain
                    a0.Name = "BallPathAttachment"
                    a1.Name = "BallPathAttachment"
                    a0.CFrame = a0.Parent.CFrame:Inverse() * cf1
                    a1.CFrame = a1.Parent.CFrame:Inverse() * cf2
                    beam.Attachment0 = a0
                    beam.Attachment1 = a1
                    local hbConn
                    hbConn = RunService.Heartbeat:Connect(function()
                        if ball.Velocity.Magnitude < 1 then
                            hbConn:Disconnect()
                            beam:Destroy() a0:Destroy() a1:Destroy()
                        end
                    end)
                    task.spawn(function()
                        repeat task.wait() until not ball.Parent
                        if beam and beam.Parent then beam:Destroy() end
                        if a0 and a0.Parent then a0:Destroy() end
                        if a1 and a1.Parent then a1:Destroy() end
                    end)
                end
            end)
        end
    end,
})

-- =====================
--    PHYSICS TAB
-- =====================

local PhysicsTab = Window:CreateTab("Physics", "zap")

-- Speed Section
local SpeedSection = PhysicsTab:CreateSection("Speed")

PhysicsTab:CreateToggle({
    Name = "CFrame Speed",
    Default = false,
    Flag = "CFrameSpeed",
    Callback = function(Value)
        speedEnabled = Value
        if Value then startMovementSystem() else stopMovementSystem() end
    end,
})

PhysicsTab:CreateSlider({
    Name = "Speed Value",
    Range = {0.1, 1.2},
    Increment = 0.1,
    Default = 0.1,
    Flag = "SpeedValue",
    Callback = function(Value)
        speedValue = Value
    end,
})

-- Jump Power Section
local JumpSection = PhysicsTab:CreateSection("Jump Power")

PhysicsTab:CreateToggle({
    Name = "Jump Power",
    Default = false,
    Flag = "JumpPower",
    Callback = function(Value)
        jumpoweron = Value
    end,
})

PhysicsTab:CreateSlider({
    Name = "Jump Boost",
    Range = {50, 65},
    Increment = 1,
    Default = 50,
    Flag = "JumpBoost",
    Callback = function(Value)
        jumpboost = Value
    end,
})

-- Jump Cooldown Section
local JumpCDSection = PhysicsTab:CreateSection("Jump Cooldown")

PhysicsTab:CreateToggle({
    Name = "No Jump Cooldown",
    Default = false,
    Flag = "NoJumpCooldown",
    Callback = function(Value)
        nojpcooldownon = Value
        if not Value and Player.Character then
            local conn = njcconnections[Player.Character]
            if conn then conn:Disconnect() njcconnections[Player.Character] = nil end
        elseif Value and Player.Character then
            njc(Player.Character)
        end
    end,
})

-- Pull Vector Section
local PullSection = PhysicsTab:CreateSection("Pull Vector")

PhysicsTab:CreateToggle({
    Name = "Pull Vector",
    Default = false,
    Flag = "PullVector",
    Callback = function(Value)
        pullvector = Value
    end,
})

PhysicsTab:CreateSlider({
    Name = "Pull Vector Speed",
    Range = {1, 3},
    Increment = 0.1,
    Default = 1,
    Flag = "PullSpeed",
    Callback = function(Value)
        pullvectorpower = Value
    end,
})

PhysicsTab:CreateSlider({
    Name = "Pull Vector Radius",
    Range = {1, 25},
    Increment = 1,
    Suffix = " studs",
    Default = 5,
    Flag = "PullRadius",
    Callback = function(Value)
        pullvectordistance = Value
    end,
})

-- Tackle Section
local TackleSection = PhysicsTab:CreateSection("Tackle")

PhysicsTab:CreateToggle({
    Name = "Click Tackle",
    Default = false,
    Flag = "ClickTackle",
    Callback = function(Value)
        clicktackleon = Value
    end,
})

PhysicsTab:CreateSlider({
    Name = "Click Tackle Range",
    Range = {1, 15},
    Increment = 1,
    Suffix = " studs",
    Default = 5,
    Flag = "ClickTackleRange",
    Callback = function(Value)
        clicktacklerange = Value
    end,
})

-- Misc Section
local MiscSection = PhysicsTab:CreateSection("Misc")

PhysicsTab:CreateToggle({
    Name = "Delete Out Of Bounds",
    Default = false,
    Flag = "DeleteOOB",
    Callback = function(Value)
        deleteOOBEnabled = Value
    end,
})

-- =====================
--    SETTINGS TAB
-- =====================

local SettingsTab = Window:CreateTab("Settings", "settings")

local SettingsSection = SettingsTab:CreateSection("UI")

SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        -- Cleanup
        magson = false
        autocatchon = false
        speedEnabled = false
        pullvector = false
        jumpoweron = false
        nojpcooldownon = false
        clicktackleon = false
        ballpathOn = false
        deleteOOBEnabled = false
        removeHitboxes()
        stopMovementSystem()
        if ballpathConnection then ballpathConnection:Disconnect() end
        for _, obj in ipairs(Workspace.Terrain:GetChildren()) do
            if obj:IsA("Beam") and obj.Name == "BallPath" then obj:Destroy()
            elseif obj:IsA("Attachment") and obj.Name == "BallPathAttachment" then obj:Destroy() end
        end
        for char, conn in pairs(njcconnections) do
            if conn then conn:Disconnect() end
        end
        njcconnections = {}
        Window:Destroy()
    end,
})

-- =====================
--   MAIN GAME LOOPS
-- =====================

-- Mags Loop
RunService.Heartbeat:Connect(function()
    if not magson then return end

    local now = tick()
    if magsdelayon and (now - lmgg) < magsdelay then return end

    if magsrange <= 0 then magsrange = 20 end

    local ball = getfutbal()
    if not ball then
        if magsdelayon then lmgg = now end
        return
    end

    local catchpart = catch(ball)
    if not catchpart then
        if magsdelayon then lmgg = now end
        return
    end

    if magmode == "CFrame" then
        ball.CFrame = catchpart.CFrame
        if ball.AssemblyLinearVelocity.Magnitude > 0 then
            ball.AssemblyLinearVelocity = Vector3.zero
        end
    else
        if typeof(firetouchinterest) == "function" then
            local ok = pcall(function()
                firetouchinterest(catchpart, ball, 0)
                task.wait()
                firetouchinterest(catchpart, ball, 1)
            end)
            if not ok then
                ball.CFrame = catchpart.CFrame
            end
        else
            ball.CFrame = catchpart.CFrame
        end
    end

    if magsdelayon then lmgg = now end
end)

-- Hitbox on ball added
Workspace.ChildAdded:Connect(function(child)
    if child.Name:lower():match("football") and magson and showhitboxon and child:IsA("BasePart") then
        hitboxx(child)
    end
end)

-- Auto Catch Loop
task.spawn(function()
    while task.wait(0.02) do
        if not autocatchon then continue end
        local ball, distance = findclosestball()
        if ball and distance <= catchdistance then
            TriggerTouchEvent()
        end
    end
end)

-- Pull Vector Loop
task.spawn(function()
    while task.wait(0.1) do
        if not pullvector then continue end
        local character = Player.Character
        if not character then continue end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        for _, ball in ipairs(getAllFootballBalls()) do
            local distance = (hrp.Position - ball.Position).Magnitude
            if distance <= pullvectordistance then
                local direction = (ball.Position - hrp.Position).Unit
                hrp.AssemblyLinearVelocity = direction * pullvectorpower * 25
            end
        end
    end
end)

-- Delete OOB Loop
task.spawn(function()
    while task.wait(1) do
        if not deleteOOBEnabled then continue end
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("BasePart") and obj.Position.Y < -100 then
                obj:Destroy()
            end
        end
    end
end)

-- Click Tackle Input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not clicktackleon then return end
        local slveesor = findclosestsleveesor(clicktacklerange)
        if slveesor and slveesor:FindFirstChild("HumanoidRootPart") then
            local character = Player.Character
            if not character then return end
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            hrp.CFrame = slveesor.HumanoidRootPart.CFrame
        end
    end
end)

-- Character Setup
if Player.Character then
    rrrrrrrsizenugget(Player.Character)
    whenmoving(Player.Character)
    njc(Player.Character)
end

Player.CharacterAdded:Connect(function(char)
    rrrrrrrsizenugget(char)
    whenmoving(char)
    njc(char)
end)

Airflow:Notify({
    Title = "Byte.WTF",
    Content = "Script loaded successfully!",
    Duration = 5,
    Type = "Success",
    Icon = "check",
})
