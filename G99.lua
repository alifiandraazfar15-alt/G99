--[[
    ============================================
    99-V3 CLEAN EDITION + UPGRADED FPS/Shaders/ESP
    Creator: FarrXyz
    Channel: https://whatsapp.com/channel/0029VbCRZ9s72WTr3Ab77u2h
    ============================================
    FITUR:
    - ESP (Highlight + Name + Distance + Health + Box + Team Color)
    - FPS Booster (Low/Medium/High)
    - FPS Widget
    - Shaders (Cinematic, Vibrant, Realistic)
    - Player List + Teleport
    - Server Hop
    - Player Music (default OFF) + UI sendiri
    - Loader Animation
    - Anti AI Slop (no emoji)
    ============================================
]]

print("99-V3 START")

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- CONFIG
local CONFIG = {
    ESPEnabled = true,
    ShowName = true,
    ShowDistance = true,
    ShowHealth = true,
    ShowBox = false,
    TeamColor = true,
    MaxDistance = 500,
    FPSBoostLevel = "Medium", -- Low, Medium, High (default OFF)
    FPSBoostEnabled = false,
    FPSWidgetEnabled = true,
    ShaderPreset = "Vibrant", -- Cinematic, Vibrant, Realistic (default OFF)
    ShadersEnabled = false,
    MusicEnabled = false,
    MusicVolume = 0.5,
    MaxPlayerCount = 12,
    MinPlayerCount = 1,
}

-- COLORS
local COLORS = {
    Background = Color3.fromRGB(15, 15, 18),
    Surface = Color3.fromRGB(22, 22, 28),
    SurfaceLight = Color3.fromRGB(30, 30, 38),
    Primary = Color3.fromRGB(0, 170, 255),
    PrimaryDark = Color3.fromRGB(0, 120, 200),
    Success = Color3.fromRGB(0, 200, 120),
    Danger = Color3.fromRGB(255, 70, 70),
    Text = Color3.fromRGB(240, 240, 245),
    TextDim = Color3.fromRGB(140, 140, 150),
    Border = Color3.fromRGB(40, 40, 50),
}

local espStore = {}
local fpsWidgetRefs = {}
local playerListScroll = nil
local playerListButtons = {}
local shaderInstances = {}
local musicRefs = { Sound = nil, Widget = nil, Status = nil, PlayBtn = nil }

-- ================================
-- FPS BOOSTER (UPGRADED)
-- ================================
local fpsBoostStore = {}
local descConnection = nil
local boostApplied = false

local function disableEffect(obj, level)
    pcall(function()
        if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            if obj.Enabled then
                fpsBoostStore[obj] = true
                obj.Enabled = false
            end
        elseif obj:IsA("Beam") or obj:IsA("Trail") then
            if obj.Enabled then
                fpsBoostStore[obj] = true
                obj.Enabled = false
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if obj.Transparency < 1 then
                fpsBoostStore[obj] = obj.Transparency
                obj.Transparency = 1
            end
        elseif obj:IsA("BasePart") then
            if obj.CastShadow then
                fpsBoostStore[obj] = true
                obj.CastShadow = false
            end
        elseif obj:IsA("Light") then
            if obj.Enabled then
                fpsBoostStore[obj] = true
                obj.Enabled = false
            end
        end
    end)
end

local function applyFPSBoost(level)
    if boostApplied then return end
    boostApplied = true
    
    local lighting = Lighting
    pcall(function()
        lighting.GlobalShadows = false
        lighting.ShadowSoftness = 0
        lighting.FogEnd = 100000
        lighting.FogStart = 100000
        lighting.EnvironmentDiffuseScale = 0
        lighting.EnvironmentSpecularScale = 0
    end)
    
    -- Level High: matiin lebih agresif
    if level == "High" then
        pcall(function()
            lighting.EnvironmentDiffuseScale = 0
            lighting.EnvironmentSpecularScale = 0
            lighting.GlobalShadows = false
            lighting.ShadowSoftness = 0
        end)
    end
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        disableEffect(obj, level)
    end
    
    if descConnection then descConnection:Disconnect() end
    descConnection = Workspace.DescendantAdded:Connect(function(obj)
        if not CONFIG.FPSBoostEnabled then return end
        task.wait(0.05)
        disableEffect(obj, CONFIG.FPSBoostLevel)
    end)
    
    print("FPS Boost applied (level: " .. level .. ")")
end

local function removeFPSBoost()
    if not boostApplied then return end
    boostApplied = false
    
    pcall(function()
        Lighting.GlobalShadows = true
        Lighting.ShadowSoftness = 0.5
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
    end)
    
    for obj, state in pairs(fpsBoostStore) do
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj.Enabled = state
            elseif obj:IsA("Beam") or obj:IsA("Trail") then
                obj.Enabled = state
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = state
            elseif obj:IsA("BasePart") then
                obj.CastShadow = state
            elseif obj:IsA("Light") then
                obj.Enabled = state
            end
        end)
    end
    fpsBoostStore = {}
    
    if descConnection then
        descConnection:Disconnect()
        descConnection = nil
    end
    print("FPS Boost removed")
end

-- ================================
-- SHADERS (UPGRADED - PRESETS)
-- ================================
local function clearShaders()
    for _, s in ipairs(shaderInstances) do
        pcall(function() s:Destroy() end)
    end
    shaderInstances = {}
end

local function applyShaders(preset)
    if next(shaderInstances) then return end
    
    -- Color Correction
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "99V3_CC"
    
    -- Bloom
    local bloom = Instance.new("BloomEffect")
    bloom.Name = "99V3_Bloom"
    
    -- Depth of Field
    local dof = Instance.new("DepthOfFieldEffect")
    dof.Name = "99V3_DoF"
    
    -- Sun Rays
    local rays = Instance.new("SunRaysEffect")
    rays.Name = "99V3_Rays"
    
    -- Atmosphere
    local atm = Instance.new("Atmosphere")
    atm.Name = "99V3_Atm"
    
    -- Preset Configuration
    if preset == "Cinematic" then
        cc.Brightness = -0.02
        cc.Contrast = 0.25
        cc.Saturation = -0.05
        cc.TintColor = Color3.fromRGB(255, 240, 220)
        
        bloom.Intensity = 1.2
        bloom.Size = 40
        bloom.Threshold = 0.8
        
        dof.FarIntensity = 0.3
        dof.FocusDistance = 20
        dof.InFocusRadius = 15
        dof.NearIntensity = 0.8
        
        rays.Intensity = 0.15
        rays.Spread = 1
        
        atm.Density = 0.4
        atm.Color = Color3.fromRGB(180, 180, 190)
        atm.Decay = Color3.fromRGB(80, 80, 90)
        atm.Glare = 0.3
        atm.Haze = 2
    elseif preset == "Realistic" then
        cc.Brightness = 0
        cc.Contrast = 0.1
        cc.Saturation = 0.1
        cc.TintColor = Color3.fromRGB(255, 255, 255)
        
        bloom.Intensity = 0.4
        bloom.Size = 16
        bloom.Threshold = 1.1
        
        dof.FarIntensity = 0.1
        dof.FocusDistance = 50
        dof.InFocusRadius = 40
        dof.NearIntensity = 0.5
        
        rays.Intensity = 0.05
        rays.Spread = 0.5
        
        atm.Density = 0.2
        atm.Color = Color3.fromRGB(199, 199, 199)
        atm.Decay = Color3.fromRGB(106, 112, 125)
        atm.Glare = 0.1
        atm.Haze = 1
    else -- Vibrant
        cc.Brightness = 0.05
        cc.Contrast = 0.2
        cc.Saturation = 0.35
        cc.TintColor = Color3.fromRGB(255, 250, 240)
        
        bloom.Intensity = 0.8
        bloom.Size = 28
        bloom.Threshold = 0.9
        
        dof.FarIntensity = 0.15
        dof.FocusDistance = 30
        dof.InFocusRadius = 25
        dof.NearIntensity = 0.75
        
        rays.Intensity = 0.12
        rays.Spread = 0.8
        
        atm.Density = 0.3
        atm.Color = Color3.fromRGB(199, 199, 199)
        atm.Decay = Color3.fromRGB(106, 112, 125)
        atm.Glare = 0.2
        atm.Haze = 1.5
    end
    
    cc.Parent = Lighting
    bloom.Parent = Lighting
    dof.Parent = Lighting
    rays.Parent = Lighting
    atm.Parent = Lighting
    
    table.insert(shaderInstances, cc)
    table.insert(shaderInstances, bloom)
    table.insert(shaderInstances, dof)
    table.insert(shaderInstances, rays)
    table.insert(shaderInstances, atm)
    
    print("Shaders applied: " .. preset)
end

local function removeShaders()
    clearShaders()
    print("Shaders removed")
end

-- ================================
-- PLAYER MUSIC
-- ================================
local function stopMusic()
    if musicRefs.Sound then
        musicRefs.Sound:Stop()
        musicRefs.Sound:Destroy()
        musicRefs.Sound = nil
    end
    if musicRefs.Status then
        musicRefs.Status.Text = "Stopped"
        musicRefs.Status.TextColor3 = COLORS.TextDim
    end
end

local function playMusic(query)
    if musicRefs.Sound then
        musicRefs.Sound:Stop()
        musicRefs.Sound:Destroy()
        musicRefs.Sound = nil
    end
    if musicRefs.Status then
        musicRefs.Status.Text = "Searching..."
        musicRefs.Status.TextColor3 = COLORS.Primary
    end
    task.spawn(function()
        local ok, err = pcall(function()
            local url = "https://xozy-api.vercel.app/api/downloader/ytplay?q=" .. HttpService:UrlEncode(query) .. "&quality=320"
            local raw = game:HttpGet(url)
            local data = HttpService:JSONDecode(raw)
            if not data or not data.status or not data.download or not data.download.downloadUrl then
                error("API response invalid")
            end
            local sound = Instance.new("Sound")
            sound.Name = "99V3_Music"
            sound.SoundId = data.download.downloadUrl
            sound.Volume = CONFIG.MusicVolume
            sound.Looped = false
            sound.Parent = SoundService
            sound:Play()
            musicRefs.Sound = sound
            if musicRefs.Status then
                musicRefs.Status.Text = "Playing: " .. tostring(data.download.title):sub(1, 40)
                musicRefs.Status.TextColor3 = COLORS.Success
            end
            sound.Ended:Connect(function()
                if musicRefs.Status then
                    musicRefs.Status.Text = "Ended"
                    musicRefs.Status.TextColor3 = COLORS.TextDim
                end
            end)
        end)
        if not ok then
            warn("Music error: " .. tostring(err))
            if musicRefs.Status then
                musicRefs.Status.Text = "Error: " .. tostring(err):sub(1, 30)
                musicRefs.Status.TextColor3 = COLORS.Danger
            end
        end
    end)
end

-- ================================
-- UI COMPONENTS
-- ================================
local function createSection(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.Primary
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function createToggle(parent, text, defaultState, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 56, 0, 30)
    switch.Position = UDim2.new(1, -56, 0.5, -15)
    switch.BackgroundColor3 = defaultState and COLORS.Primary or COLORS.SurfaceLight
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.Parent = row

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = defaultState and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = switch

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = defaultState
    switch.MouseButton1Click:Connect(function()
        state = not state
        local targetPos = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        local targetColor = state and COLORS.Primary or COLORS.SurfaceLight
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
        TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        callback(state)
    end)
end

local function createInput(parent, placeholder, defaultText, callback)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 42)
    box.BackgroundColor3 = COLORS.SurfaceLight
    box.Text = defaultText or ""
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = COLORS.TextDim
    box.TextColor3 = COLORS.Text
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.Parent = parent

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 8)
    boxCorner.Parent = box

    local boxPad = Instance.new("UIPadding")
    boxPad.PaddingLeft = UDim.new(0, 12)
    boxPad.PaddingRight = UDim.new(0, 12)
    boxPad.Parent = box

    box.FocusLost:Connect(function()
        callback(box.Text)
    end)
end

local function createLoader(parent)
    local loader = Instance.new("Frame")
    loader.Name = "Loader"
    loader.Size = UDim2.new(1, 0, 1, 0)
    loader.BackgroundColor3 = COLORS.Background
    loader.BorderSizePixel = 0
    loader.ZIndex = 10
    loader.Parent = parent

    local loaderCorner = Instance.new("UICorner")
    loaderCorner.CornerRadius = UDim.new(0, 14)
    loaderCorner.Parent = loader

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0.35, -15)
    title.BackgroundTransparency = 1
    title.Text = "99-V3"
    title.TextColor3 = COLORS.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.Parent = loader

    local dotsFrame = Instance.new("Frame")
    dotsFrame.Size = UDim2.new(0, 80, 0, 20)
    dotsFrame.Position = UDim2.new(0.5, -40, 0.5, 10)
    dotsFrame.BackgroundTransparency = 1
    dotsFrame.Parent = loader

    local dotLayout = Instance.new("UIListLayout")
    dotLayout.FillDirection = Enum.FillDirection.Horizontal
    dotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    dotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    dotLayout.Padding = UDim.new(0, 6)
    dotLayout.Parent = dotsFrame

    local dots = {}
    for _ = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.BackgroundColor3 = COLORS.Primary
        dot.Parent = dotsFrame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = dot
        table.insert(dots, dot)
    end

    task.spawn(function()
        while loader.Parent do
            for _, dot in ipairs(dots) do
                task.spawn(function()
                    TweenService:Create(dot, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
                    task.wait(0.3)
                    TweenService:Create(dot, TweenInfo.new(0.3), {BackgroundTransparency = 0.7}):Play()
                end)
                task.wait(0.15)
            end
        end
    end)

    return loader
end

-- ================================
-- MUSIC WIDGET UI
-- ================================
local function createMusicWidget(screenGui)
    local Widget = Instance.new("Frame")
    Widget.Name = "MusicWidget"
    Widget.Size = UDim2.new(0, 280, 0, 240)
    Widget.Position = UDim2.new(0, 15, 0, 160)
    Widget.BackgroundColor3 = COLORS.Background
    Widget.BorderSizePixel = 0
    Widget.Active = true
    Widget.Draggable = true
    Widget.Visible = false
    Widget.Parent = screenGui

    local wCorner = Instance.new("UICorner")
    wCorner.CornerRadius = UDim.new(0, 14)
    wCorner.Parent = Widget

    local wStroke = Instance.new("UIStroke")
    wStroke.Color = COLORS.Border
    wStroke.Thickness = 1
    wStroke.Transparency = 0.3
    wStroke.Parent = Widget

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = COLORS.Surface
    header.BorderSizePixel = 0
    header.Parent = Widget

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0, 14)
    hCorner.Parent = header

    local hPatch = Instance.new("Frame")
    hPatch.Size = UDim2.new(1, 0, 0, 12)
    hPatch.Position = UDim2.new(0, 0, 1, -12)
    hPatch.BackgroundColor3 = COLORS.Surface
    hPatch.BorderSizePixel = 0
    hPatch.Parent = header

    local hTitle = Instance.new("TextLabel")
    hTitle.Size = UDim2.new(0.7, 0, 1, 0)
    hTitle.Position = UDim2.new(0, 14, 0, 0)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "Player Music"
    hTitle.TextColor3 = COLORS.Text
    hTitle.Font = Enum.Font.GothamBold
    hTitle.TextSize = 14
    hTitle.TextXAlignment = Enum.TextXAlignment.Left
    hTitle.Parent = header

    local closeW = Instance.new("TextButton")
    closeW.Size = UDim2.new(0, 30, 0, 30)
    closeW.Position = UDim2.new(1, -36, 0.5, -15)
    closeW.BackgroundColor3 = COLORS.SurfaceLight
    closeW.Text = "X"
    closeW.TextColor3 = COLORS.Text
    closeW.Font = Enum.Font.GothamBold
    closeW.TextSize = 12
    closeW.AutoButtonColor = false
    closeW.Parent = header

    local cwCorner = Instance.new("UICorner")
    cwCorner.CornerRadius = UDim.new(0, 8)
    cwCorner.Parent = closeW

    -- Body
    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 1, -42)
    body.Position = UDim2.new(0, 0, 0, 42)
    body.BackgroundTransparency = 1
    body.Parent = Widget

    local bLayout = Instance.new("UIListLayout")
    bLayout.Padding = UDim.new(0, 8)
    bLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bLayout.Parent = body

    local bPad = Instance.new("UIPadding")
    bPad.PaddingTop = UDim.new(0, 12)
    bPad.PaddingLeft = UDim.new(0, 14)
    bPad.PaddingRight = UDim.new(0, 14)
    bPad.PaddingBottom = UDim.new(0, 12)
    bPad.Parent = body

    -- Search input
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, 0, 0, 40)
    searchBox.BackgroundColor3 = COLORS.SurfaceLight
    searchBox.Text = ""
    searchBox.PlaceholderText = "Cari lagu..."
    searchBox.PlaceholderColor3 = COLORS.TextDim
    searchBox.TextColor3 = COLORS.Text
    searchBox.Font = Enum.Font.GothamMedium
    searchBox.TextSize = 14
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = body

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 8)
    sbCorner.Parent = searchBox

    local sbPad = Instance.new("UIPadding")
    sbPad.PaddingLeft = UDim.new(0, 12)
    sbPad.PaddingRight = UDim.new(0, 12)
    sbPad.Parent = searchBox

    -- Buttons
    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, 0, 0, 40)
    btnRow.BackgroundTransparency = 1
    btnRow.Parent = body

    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0.48, 0, 1, 0)
    playBtn.BackgroundColor3 = COLORS.Primary
    playBtn.Text = "Play"
    playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 14
    playBtn.Parent = btnRow

    local pbCorner = Instance.new("UICorner")
    pbCorner.CornerRadius = UDim.new(0, 8)
    pbCorner.Parent = playBtn

    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0.48, 0, 1, 0)
    stopBtn.Position = UDim2.new(0.52, 0, 0, 0)
    stopBtn.BackgroundColor3 = COLORS.SurfaceLight
    stopBtn.Text = "Stop"
    stopBtn.TextColor3 = COLORS.Text
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 14
    stopBtn.Parent = btnRow

    local stCorner = Instance.new("UICorner")
    stCorner.CornerRadius = UDim.new(0, 8)
    stCorner.Parent = stopBtn

    -- Volume
    local volLabel = Instance.new("TextLabel")
    volLabel.Size = UDim2.new(1, 0, 0, 20)
    volLabel.BackgroundTransparency = 1
    volLabel.Text = "Volume: 50%"
    volLabel.TextColor3 = COLORS.TextDim
    volLabel.Font = Enum.Font.GothamMedium
    volLabel.TextSize = 12
    volLabel.TextXAlignment = Enum.TextXAlignment.Left
    volLabel.Parent = body

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    sliderBg.BackgroundColor3 = COLORS.SurfaceLight
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = body

    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(1, 0)
    sliderBgCorner.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(CONFIG.MusicVolume, 0, 1, 0)
    sliderFill.BackgroundColor3 = COLORS.Primary
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg

    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    sliderFillCorner.Parent = sliderFill

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(1, 0, 1, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.Parent = sliderBg

    sliderBtn.MouseButton1Down:Connect(function()
        local function updateVol(input)
            local relX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            CONFIG.MusicVolume = relX
            sliderFill.Size = UDim2.new(relX, 0, 1, 0)
            volLabel.Text = "Volume: " .. math.floor(relX * 100) .. "%"
            if musicRefs.Sound then
                musicRefs.Sound.Volume = relX
            end
        end
        local conn
        conn = RunService.RenderStepped:Connect(function()
            local mouse = game:GetService("UserInputService"):GetMouseLocation()
            updateVol({Position = mouse})
        end)
        local inputEnded
        inputEnded = game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                conn:Disconnect()
                inputEnded:Disconnect()
            end
        end)
    end)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 22)
    status.BackgroundTransparency = 1
    status.Text = "Stopped"
    status.TextColor3 = COLORS.TextDim
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextTruncate = Enum.TextTruncate.AtEnd
    status.Parent = body

    musicRefs.Widget = Widget
    musicRefs.Status = status
    musicRefs.PlayBtn = playBtn

    playBtn.MouseButton1Click:Connect(function()
        local q = searchBox.Text
        if q and #q > 0 then playMusic(q) end
    end)
    stopBtn.MouseButton1Click:Connect(function() stopMusic() end)
    closeW.MouseButton1Click:Connect(function()
        Widget.Visible = false
        CONFIG.MusicEnabled = false
    end)

    return Widget
end

-- ================================
-- PLAYER LIST / TELEPORT / SERVER HOP (SAMA)
-- ================================
local function teleportToPlayer(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local targetChar = targetPlayer.Character
    if not targetChar then return end
    local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return end
    hrp.CFrame = CFrame.new(targetHrp.Position + Vector3.new(0, 3, 0))
    print("Teleported to: " .. targetPlayer.Name)
end

local function refreshPlayerList()
    if not playerListScroll then return end
    for _, btn in pairs(playerListButtons) do btn:Destroy() end
    playerListButtons = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 42)
            btn.BackgroundColor3 = COLORS.SurfaceLight
            btn.Text = player.Name
            btn.TextColor3 = COLORS.Text
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 14
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = playerListScroll
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = btn
            local btnPad = Instance.new("UIPadding")
            btnPad.PaddingLeft = UDim.new(0, 14)
            btnPad.Parent = btn
            btn.MouseButton1Click:Connect(function()
                teleportToPlayer(player)
                btn.BackgroundColor3 = COLORS.Primary
                task.wait(0.2)
                btn.BackgroundColor3 = COLORS.SurfaceLight
            end)
            playerListButtons[player] = btn
        end
    end
end

local function serverHop()
    local ok, err = pcall(function()
        local TeleportService = game:GetService("TeleportService")
        local servers = {}
        local cursor = ""
        repeat
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&cursor=%s", game.PlaceId, cursor)
            local response = HttpService:JSONDecode(game:HttpGet(url))
            if response and response.data then
                for _, server in ipairs(response.data) do
                    if server.playing and server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, {id = server.id, playing = server.playing, maxPlayers = server.maxPlayers})
                    end
                end
                cursor = response.nextPageCursor or ""
            else
                cursor = ""
            end
        until cursor == "" or cursor == nil
        local best = nil
        for _, server in ipairs(servers) do
            if server.playing >= CONFIG.MinPlayerCount and server.playing <= CONFIG.MaxPlayerCount then
                if not best or server.playing > best.playing then best = server end
            end
        end
        if best then
            print("Found: " .. best.id .. " (" .. best.playing .. "/" .. best.maxPlayers .. ")")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LocalPlayer)
        else
            error("Server not found!")
        end
    end)
    if not ok then warn("Server Hop error: " .. tostring(err)) end
end

-- ================================
-- ESP SYSTEM (UPGRADED)
-- ================================
local function getTeamColor(player)
    if not CONFIG.TeamColor then
        return COLORS.Primary
    end
    if player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end
    return COLORS.Primary
end

local function createESP(player)
    if player == LocalPlayer then return end
    if espStore[player] then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local color = getTeamColor(player)

    local data = {}
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = char
    highlight.Parent = char
    data.highlight = highlight

    -- Box ESP
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "99V3_Box"
    box.Size = Vector3.new(2, 2, 1)
    box.Adornee = char
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.7
    box.Color3 = color
    box.Parent = char
    data.box = box

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = COLORS.Text
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Visible = CONFIG.ShowName
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 18)
    distLabel.Position = UDim2.new(0, 0, 0, 22)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0 studs"
    distLabel.TextColor3 = color
    distLabel.TextStrokeTransparency = 0
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 12
    distLabel.Visible = CONFIG.ShowDistance
    distLabel.Parent = billboard

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0, 18)
    healthLabel.Position = UDim2.new(0, 0, 0, 40)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "100 / 100"
    healthLabel.TextColor3 = COLORS.Success
    healthLabel.TextStrokeTransparency = 0
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 12
    healthLabel.Visible = CONFIG.ShowHealth
    healthLabel.Parent = billboard

    data.billboard = billboard
    data.nameLabel = nameLabel
    data.distLabel = distLabel
    data.healthLabel = healthLabel
    data.color = color
    data.boxEnabled = CONFIG.ShowBox

    espStore[player] = data
end

local function removeESP(player)
    if espStore[player] then
        if espStore[player].highlight then espStore[player].highlight:Destroy() end
        if espStore[player].billboard then espStore[player].billboard:Destroy() end
        if espStore[player].box then espStore[player].box:Destroy() end
        espStore[player] = nil
    end
end

local function refreshESPLabels()
    for _, data in pairs(espStore) do
        if data.nameLabel then data.nameLabel.Visible = CONFIG.ShowName end
        if data.distLabel then data.distLabel.Visible = CONFIG.ShowDistance end
        if data.healthLabel then data.healthLabel.Visible = CONFIG.ShowHealth end
        if data.box then
            data.box.Transparency = CONFIG.ShowBox and 0.7 or 1
        end
    end
end

local function setupAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESP(player)
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if CONFIG.ESPEnabled then
                    removeESP(player)
                    createESP(player)
                end
            end)
        end
    end
end

-- ================================
-- FPS COUNTER + WIDGET
-- ================================
local fpsValue = 0
local frameCount = 0
local lastTime = tick()

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastTime >= 1 then
        fpsValue = frameCount
        frameCount = 0
        lastTime = now
    end
end)

local function createFPSWidget(parent)
    local Widget = Instance.new("Frame")
    Widget.Name = "FPSWidget"
    Widget.Size = UDim2.new(0, 120, 0, 55)
    Widget.Position = UDim2.new(0, 15, 0, 80)
    Widget.BackgroundColor3 = COLORS.Surface
    Widget.BorderSizePixel = 0
    Widget.Active = true
    Widget.Draggable = true
    Widget.Parent = parent

    local wCorner = Instance.new("UICorner")
    wCorner.CornerRadius = UDim.new(0, 10)
    wCorner.Parent = Widget

    local wStroke = Instance.new("UIStroke")
    wStroke.Color = COLORS.Success
    wStroke.Thickness = 1.5
    wStroke.Transparency = 0.3
    wStroke.Parent = Widget

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, 0, 0, 32)
    fpsLabel.Position = UDim2.new(0, 0, 0, 4)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "60"
    fpsLabel.TextColor3 = COLORS.Success
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextSize = 24
    fpsLabel.Parent = Widget

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(1, 0, 0, 14)
    subLabel.Position = UDim2.new(0, 0, 0, 36)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = "FPS"
    subLabel.TextColor3 = COLORS.TextDim
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextSize = 10
    subLabel.Parent = Widget

    fpsWidgetRefs.Widget = Widget
    fpsWidgetRefs.fpsLabel = fpsLabel
    fpsWidgetRefs.stroke = wStroke
end

RunService.RenderStepped:Connect(function()
    if not CONFIG.FPSWidgetEnabled then return end
    if not fpsWidgetRefs.fpsLabel then return end
    fpsWidgetRefs.fpsLabel.Text = tostring(fpsValue)
    local color
    if fpsValue >= 50 then color = COLORS.Success
    elseif fpsValue >= 30 then color = Color3.fromRGB(255, 200, 0)
    else color = COLORS.Danger end
    fpsWidgetRefs.fpsLabel.TextColor3 = color
    fpsWidgetRefs.stroke.Color = color
end)

-- ================================
-- UPDATE ESP LOOP
-- ================================
RunService.RenderStepped:Connect(function()
    if not CONFIG.ESPEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for player, data in pairs(espStore) do
        if player.Character then
            local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
            if targetHrp and data.distLabel then
                local dist = (targetHrp.Position - hrp.Position).Magnitude
                data.distLabel.Text = string.format("%d studs", math.floor(dist))
                local visible = dist <= CONFIG.MaxDistance
                if data.billboard then data.billboard.Enabled = visible end
                if data.highlight then data.highlight.Enabled = visible end
                if data.box then data.box.Transparency = CONFIG.ShowBox and 0.7 or 1 end
                if targetHum and data.healthLabel then
                    local hp = math.floor(targetHum.Health)
                    local maxHp = math.floor(targetHum.MaxHealth)
                    data.healthLabel.Text = string.format("%d / %d", hp, maxHp)
                    local ratio = targetHum.Health / targetHum.MaxHealth
                    if ratio > 0.6 then
                        data.healthLabel.TextColor3 = COLORS.Success
                    elseif ratio > 0.3 then
                        data.healthLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                    else
                        data.healthLabel.TextColor3 = COLORS.Danger
                    end
                end
            end
        end
    end
end)

-- ================================
-- PLAYER EVENTS
-- ================================
Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    refreshPlayerList()
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if CONFIG.ESPEnabled then
            removeESP(player)
            createESP(player)
        end
        refreshPlayerList()
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    refreshPlayerList()
end)

-- ================================
-- MAIN UI
-- ================================
local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "99V3_AllInOne"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local Panel = Instance.new("Frame")
    Panel.Size = UDim2.new(0, 300, 0, 560)
    Panel.Position = UDim2.new(0.5, -150, 0.5, -280)
    Panel.BackgroundColor3 = COLORS.Background
    Panel.BorderSizePixel = 0
    Panel.Active = true
    Panel.Draggable = true
    Panel.Parent = ScreenGui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 14)
    panelCorner.Parent = Panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = COLORS.Border
    panelStroke.Thickness = 1
    panelStroke.Transparency = 0.3
    panelStroke.Parent = Panel

    local loader = createLoader(Panel)

    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = COLORS.Surface
    Header.BorderSizePixel = 0
    Header.Parent = Panel

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 14)
    headerCorner.Parent = Header

    local headerPatch = Instance.new("Frame")
    headerPatch.Size = UDim2.new(1, 0, 0, 14)
    headerPatch.Position = UDim2.new(0, 0, 1, -14)
    headerPatch.BackgroundColor3 = COLORS.Surface
    headerPatch.BorderSizePixel = 0
    headerPatch.Parent = Header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Position = UDim2.new(0, 18, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "99-V3"
    title.TextColor3 = COLORS.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = Header

    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0.3, 0, 1, 0)
    version.Position = UDim2.new(0.5, 0, 0, 0)
    version.BackgroundTransparency = 1
    version.Text = "v2.3"
    version.TextColor3 = COLORS.TextDim
    version.Font = Enum.Font.Gotham
    version.TextSize = 11
    version.TextXAlignment = Enum.TextXAlignment.Left
    version.Parent = Header

    local headerMin = Instance.new("TextButton")
    headerMin.Size = UDim2.new(0, 36, 0, 36)
    headerMin.Position = UDim2.new(1, -84, 0.5, -18)
    headerMin.BackgroundColor3 = COLORS.SurfaceLight
    headerMin.Text = "—"
    headerMin.TextColor3 = COLORS.Text
    headerMin.Font = Enum.Font.GothamBold
    headerMin.TextSize = 18
    headerMin.AutoButtonColor = false
    headerMin.Parent = Header

    local hMinCorner = Instance.new("UICorner")
    hMinCorner.CornerRadius = UDim.new(0, 8)
    hMinCorner.Parent = headerMin

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -44, 0.5, -18)
    closeBtn.BackgroundColor3 = COLORS.SurfaceLight
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.Text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = Header

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent = closeBtn

    -- Body
    local Body = Instance.new("ScrollingFrame")
    Body.Size = UDim2.new(1, 0, 1, -50)
    Body.Position = UDim2.new(0, 0, 0, 50)
    Body.BackgroundTransparency = 1
    Body.BorderSizePixel = 0
    Body.ScrollBarThickness = 3
    Body.ScrollBarImageColor3 = COLORS.Primary
    Body.CanvasSize = UDim2.new(0, 0, 0, 0)
    Body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Body.Parent = Panel

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 4)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = Body

    local bodyPad = Instance.new("UIPadding")
    bodyPad.PaddingTop = UDim.new(0, 12)
    bodyPad.PaddingLeft = UDim.new(0, 18)
    bodyPad.PaddingRight = UDim.new(0, 18)
    bodyPad.PaddingBottom = UDim.new(0, 12)
    bodyPad.Parent = Body

    -- ESP SECTION
    createSection(Body, "ESP")
    createToggle(Body, "Player ESP", CONFIG.ESPEnabled, function(state)
        CONFIG.ESPEnabled = state
        if state then setupAllESP()
        else
            for player, _ in pairs(espStore) do removeESP(player) end
        end
    end)
    createToggle(Body, "Show Name", CONFIG.ShowName, function(state)
        CONFIG.ShowName = state
        refreshESPLabels()
    end)
    createToggle(Body, "Show Distance", CONFIG.ShowDistance, function(state)
        CONFIG.ShowDistance = state
        refreshESPLabels()
    end)
    createToggle(Body, "Show Health", CONFIG.ShowHealth, function(state)
        CONFIG.ShowHealth = state
        refreshESPLabels()
    end)
    createToggle(Body, "Show Box", CONFIG.ShowBox, function(state)
        CONFIG.ShowBox = state
        refreshESPLabels()
    end)
    createToggle(Body, "Team Color", CONFIG.TeamColor, function(state)
        CONFIG.TeamColor = state
        for player, data in pairs(espStore) do
            local newColor = getTeamColor(player)
            if data.highlight then data.highlight.FillColor = newColor end
            if data.box then data.box.Color3 = newColor end
            if data.distLabel then data.distLabel.TextColor3 = newColor end
        end
    end)

    -- VISUAL
    createSection(Body, "VISUAL")
    createToggle(Body, "Shaders", CONFIG.ShadersEnabled, function(state)
        CONFIG.ShadersEnabled = state
        if state then applyShaders(CONFIG.ShaderPreset) else removeShaders() end
    end)
    -- Preset dropdown (simple: text input)
    createInput(Body, "Shader Preset (Cinematic/Vibrant/Realistic)", CONFIG.ShaderPreset, function(text)
        local preset = text:gsub("%s", "")
        if preset == "Cinematic" or preset == "Vibrant" or preset == "Realistic" then
            CONFIG.ShaderPreset = preset
            if CONFIG.ShadersEnabled then
                removeShaders()
                applyShaders(preset)
            end
        end
    end)

    -- MUSIC
    createSection(Body, "MUSIC")
    createToggle(Body, "Player Music", CONFIG.MusicEnabled, function(state)
        CONFIG.MusicEnabled = state
        if musicRefs.Widget then
            musicRefs.Widget.Visible = state
            if state then musicRefs.Widget.Position = UDim2.new(0, 15, 0, 160) end
        end
    end)

    -- PERFORMANCE
    createSection(Body, "PERFORMANCE")
    createToggle(Body, "FPS Booster", CONFIG.FPSBoostEnabled, function(state)
        CONFIG.FPSBoostEnabled = state
        if state then applyFPSBoost(CONFIG.FPSBoostLevel) else removeFPSBoost() end
    end)
    -- Level input
    createInput(Body, "Boost Level (Low/Medium/High)", CONFIG.FPSBoostLevel, function(text)
        local level = text:gsub("%s", "")
        if level == "Low" or level == "Medium" or level == "High" then
            CONFIG.FPSBoostLevel = level
            if CONFIG.FPSBoostEnabled then
                removeFPSBoost()
                applyFPSBoost(level)
            end
        end
    end)
    createToggle(Body, "FPS Widget", CONFIG.FPSWidgetEnabled, function(state)
        CONFIG.FPSWidgetEnabled = state
        if fpsWidgetRefs.Widget then fpsWidgetRefs.Widget.Visible = state end
    end)

    -- TELEPORT
    createSection(Body, "TELEPORT")
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Size = UDim2.new(1, 0, 0, 200)
    playerListFrame.BackgroundColor3 = COLORS.Surface
    playerListFrame.BorderSizePixel = 0
    playerListFrame.Parent = Body
    local plCorner = Instance.new("UICorner")
    plCorner.CornerRadius = UDim.new(0, 8)
    plCorner.Parent = playerListFrame
    playerListScroll = Instance.new("ScrollingFrame")
    playerListScroll.Size = UDim2.new(1, -10, 1, -10)
    playerListScroll.Position = UDim2.new(0, 5, 0, 5)
    playerListScroll.BackgroundTransparency = 1
    playerListScroll.BorderSizePixel = 0
    playerListScroll.ScrollBarThickness = 3
    playerListScroll.ScrollBarImageColor3 = COLORS.Primary
    playerListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playerListScroll.Parent = playerListFrame
    local plLayout = Instance.new("UIListLayout")
    plLayout.Padding = UDim.new(0, 5)
    plLayout.SortOrder = Enum.SortOrder.LayoutOrder
    plLayout.Parent = playerListScroll
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(1, 0, 0, 42)
    refreshBtn.BackgroundColor3 = COLORS.Primary
    refreshBtn.Text = "Refresh Player List"
    refreshBtn.TextColor3 = COLORS.Text
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 13
    refreshBtn.Parent = Body
    local rbCorner = Instance.new("UICorner")
    rbCorner.CornerRadius = UDim.new(0, 8)
    rbCorner.Parent = refreshBtn
    refreshBtn.MouseButton1Click:Connect(function()
        refreshPlayerList()
        refreshBtn.Text = "Refreshed"
        task.wait(1)
        refreshBtn.Text = "Refresh Player List"
    end)

    -- SERVER HOP
    createSection(Body, "SERVER HOP")
    createInput(Body, "Max Player Count", tostring(CONFIG.MaxPlayerCount), function(text)
        local num = tonumber(text)
        if num and num > 0 then CONFIG.MaxPlayerCount = num end
    end)
    createInput(Body, "Min Player Count", tostring(CONFIG.MinPlayerCount), function(text)
        local num = tonumber(text)
        if num and num >= 0 then CONFIG.MinPlayerCount = num end
    end)
    local hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(1, 0, 0, 42)
    hopBtn.BackgroundColor3 = COLORS.Primary
    hopBtn.Text = "Server Hop"
    hopBtn.TextColor3 = COLORS.Text
    hopBtn.Font = Enum.Font.GothamBold
    hopBtn.TextSize = 14
    hopBtn.Parent = Body
    local hbCorner = Instance.new("UICorner")
    hbCorner.CornerRadius = UDim.new(0, 8)
    hbCorner.Parent = hopBtn
    hopBtn.MouseButton1Click:Connect(function()
        hopBtn.Text = "Searching..."
        task.spawn(function()
            serverHop()
            task.wait(2)
            hopBtn.Text = "Server Hop"
        end)
    end)

    local credit = Instance.new("TextLabel")
    credit.Size = UDim2.new(1, 0, 0, 25)
    credit.BackgroundTransparency = 1
    credit.Text = "by FarrXyz"
    credit.TextColor3 = COLORS.TextDim
    credit.Font = Enum.Font.Gotham
    credit.TextSize = 11
    credit.Parent = Body

    -- Fade out loader
    task.spawn(function()
        task.wait(1.5)
        TweenService:Create(loader, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        for _, child in ipairs(loader:GetDescendants()) do
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
            elseif child:IsA("Frame") then
                TweenService:Create(child, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            end
        end
        task.wait(0.6)
        loader:Destroy()
    end)

    -- MINIMIZE BUTTON
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinimizeButton"
    minBtn.Size = UDim2.new(0, 60, 0, 60)
    minBtn.Position = UDim2.new(0, 15, 0.3, 0)
    minBtn.BackgroundColor3 = COLORS.Primary
    minBtn.Text = "99"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 18
    minBtn.AutoButtonColor = false
    minBtn.Active = true
    minBtn.Draggable = true
    minBtn.Visible = false
    minBtn.Parent = ScreenGui
    local minBtnCorner = Instance.new("UICorner")
    minBtnCorner.CornerRadius = UDim.new(1, 0)
    minBtnCorner.Parent = minBtn
    local minBtnStroke = Instance.new("UIStroke")
    minBtnStroke.Color = Color3.fromRGB(255, 255, 255)
    minBtnStroke.Thickness = 2
    minBtnStroke.Transparency = 0.5
    minBtnStroke.Parent = minBtn

    closeBtn.MouseButton1Click:Connect(function()
        Panel.Visible = false
        minBtn.Visible = false
        if musicRefs.Widget then musicRefs.Widget.Visible = false end
    end)
    headerMin.MouseButton1Click:Connect(function()
        Panel.Visible = false
        minBtn.Visible = true
        if musicRefs.Widget then musicRefs.Widget.Visible = false end
    end)
    minBtn.MouseButton1Click:Connect(function()
        Panel.Visible = true
        minBtn.Visible = false
        if CONFIG.MusicEnabled and musicRefs.Widget then
            musicRefs.Widget.Visible = true
        end
    end)

    -- Music Widget
    createMusicWidget(ScreenGui)

    return ScreenGui
end

-- ================================
-- INIT
-- ================================
print("Setup ESP...")
setupAllESP()

print("Create UI...")
local mainGui = createUI()

print("Create FPS Widget...")
createFPSWidget(mainGui)

print("FPS Boost (default OFF)...")
-- default off

task.wait(0.5)
refreshPlayerList()

-- RE-ATTACH SYSTEM
local function reattachGUI()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    if not pg:FindFirstChild("99V3_AllInOne") then
        print("GUI hilang, re-create...")
        local newGui = createUI()
        createFPSWidget(newGui)
        task.wait(0.3)
        refreshPlayerList()
    else
        pg:FindFirstChild("99V3_AllInOne").Enabled = true
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    reattachGUI()
end)

task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg and not pg:FindFirstChild("99V3_AllInOne") then
                reattachGUI()
            end
        end)
    end
end)

print("99-V3 LOADED!")
print("Creator: FarrXyz")
print("Channel: https://whatsapp.com/channel/0029VbCRZ9s72WTr3Ab77u2h")
