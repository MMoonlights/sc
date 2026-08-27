-- Forsaken Monster Magnet v2 (UI build)
local Players = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RunSvc   = game:GetService("RunService")
local LP       = Players.LocalPlayer

local folder = workspace:WaitForChild("Entities")

local CONFIG = {
    on     = true,
    force  = 40000,
    speed  = 60,
    range  = 200,
    tick   = 0.05,
}

-- cleanup если уже был запущен
local old = LP.PlayerGui:FindFirstChild("MagnetGuiV2")
if old then old:Destroy() end

-- helpers
local function rootOf(e)
    return e:FindFirstChild("HumanoidRootPart")
        or e:FindFirstChild("Torso")
        or e.PrimaryPart
end

local function ensureVel(part)
    local att = part:FindFirstChild("__a")
    if not att then
        att = Instance.new("Attachment"); att.Name = "__a"; att.Parent = part
    end
    local lv = part:FindFirstChild("__lv")
    if not lv then
        lv = Instance.new("LinearVelocity")
        lv.Name = "__lv"
        lv.Attachment0 = att
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.Parent = part
    end
    lv.MaxForce = CONFIG.force
    return lv
end

local function make(cls, props)
    local i = Instance.new(cls)
    for k, v in pairs(props) do i[k] = v end
    return i
end

-- GUI
local gui = make("ScreenGui", {Name="MagnetGuiV2", ResetOnSpawn=false, Parent=LP:WaitForChild("PlayerGui")})
local main = make("Frame", {
    Size=UDim2.new(0,200,0,260),
    Position=UDim2.new(0,30,0,180),
    BackgroundColor3=Color3.fromRGB(20,20,20),
    BorderSizePixel=0,
    Parent=gui,
})
Instance.new("UICorner", main).CornerRadius = UDim.new(0,8)

local title = make("TextLabel", {
    Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
    Text="Monster Magnet v2", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=14, Parent=main,
})

-- ON/OFF
local toggle = make("TextButton", {
    Size=UDim2.new(1,-16,0,28), Position=UDim2.new(0,8,0,26),
    BackgroundColor3=Color3.fromRGB(60,170,80),
    Text="ON", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=14,
    BorderSizePixel=0, AutoButtonColor=false, Parent=main,
})
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,6)

-- sliders
local function slider(yPos, label, min, max, def, key, fmt)
    local lbl = make("TextLabel", {
        Size=UDim2.new(1,-16,0,14), Position=UDim2.new(0,8,0,yPos),
        BackgroundTransparency=1, TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.Gotham, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left,
        Text=string.format("%s: %s", label, fmt(CONFIG[key])),
        Parent=main,
    })
    local box = make("TextBox", {
        Size=UDim2.new(1,-16,0,24), Position=UDim2.new(0,8,0,yPos+16),
        BackgroundColor3=Color3.fromRGB(45,45,45),
        TextColor3=Color3.new(1,1,1), Font=Enum.Font.Gotham, TextSize=13,
        PlaceholderText=tostring(def), Text=tostring(CONFIG[key]),
        BorderSizePixel=0, ClearTextOnFocus=false, Parent=main,
    })
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            CONFIG[key] = math.clamp(n, min, max)
        end
        box.Text = tostring(CONFIG[key])
        lbl.Text = string.format("%s: %s", label, fmt(CONFIG[key]))
    end)
end

slider(60,  "Force",  1000, 200000, 40000, "force", function(v) return string.format("%d", v) end)
slider(106, "Speed",  10,   300,    60,    "speed", function(v) return string.format("%d", v) end)
slider(152, "Range",  20,   1000,   200,   "range", function(v) return string.format("%d", v) end)

-- status
local status = make("TextLabel", {
    Size=UDim2.new(1,-16,0,18), Position=UDim2.new(0,8,0,202),
    BackgroundTransparency=1, TextColor3=Color3.fromRGB(180,180,180),
    Font=Enum.Font.Gotham, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left,
    Text="entities: 0", Parent=main,
})

-- credits
make("TextLabel", {
    Size=UDim2.new(1,-16,0,12), Position=UDim2.new(0,8,0,222),
    BackgroundTransparency=1, TextColor3=Color3.fromRGB(90,90,90),
    Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left,
    Text="Forsaken magnet — physics drag, not TP", Parent=main,
})

-- toggle logic
toggle.MouseButton1Click:Connect(function()
    CONFIG.on = not CONFIG.on
    toggle.Text = CONFIG.on and "ON" or "OFF"
    toggle.BackgroundColor3 = CONFIG.on and Color3.fromRGB(60,170,80) or Color3.fromRGB(170,60,60)
    if not CONFIG.on then
        for _, e in folder:GetChildren() do
            local r = rootOf(e)
            if r then
                local lv = r:FindFirstChild("__lv")
                if lv then lv.VectorVelocity = Vector3.zero end
            end
        end
    end
end)

-- drag
local dragging, dragStart, startPos
main.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = i.Position; startPos = main.Position
    end
end)
main.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                  startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- loop
RunSvc.Heartbeat:Connect(function()
    if not CONFIG.on then return end
    local char = LP.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local n = 0
    for _, e in folder:GetChildren() do
        local r = rootOf(e)
        if r then
            local dir = myRoot.Position - r.Position
            local dist = dir.Magnitude
            if dist < CONFIG.range and dist > 0.5 then
                ensureVel(r).VectorVelocity = dir.Unit * CONFIG.speed
                n = n + 1
            else
                local lv = r:FindFirstChild("__lv")
                if lv then lv.VectorVelocity = Vector3.zero end
            end
        end
    end
    status.Text = string.format("entities: %d | range: %d", n, CONFIG.range)
end)
