local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    entitiesFolder = workspace:FindFirstChild("Entities"),
    tickRate       = 0.1,
    radius         = 8,
    spawnJitter    = 3,
    yOffset        = 0,
    enabled        = true,
}

local function getEntityRoot(e)
    return e:FindFirstChild("HumanoidRootPart")
        or e:FindFirstChild("Torso")
        or e:FindFirstChild("Head")
        or e.PrimaryPart
        or e:FindFirstChildWhichIsA("BasePart")
end

local function getEntityHumanoid(e)
    return e:FindFirstChildOfClass("Humanoid")
        or e:FindFirstChildWhichIsA("Humanoid")
end

local entities = {}
if CONFIG.entitiesFolder then
    local function addEntity(obj)
        if obj:IsA("Model") and (getEntityRoot(obj) or getEntityHumanoid(obj)) then
            table.insert(entities, obj)
        end
    end
    for _, obj in ipairs(CONFIG.entitiesFolder:GetChildren()) do addEntity(obj) end
    CONFIG.entitiesFolder.ChildAdded:Connect(addEntity)
    CONFIG.entitiesFolder.ChildRemoved:Connect(function(obj)
        for i, e in ipairs(entities) do
            if e == obj then table.remove(entities, i); break end
        end
    end)
else
    return
end

local gui = Instance.new("ScreenGui")
gui.Name = "MTGui"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 180, 0, 110)
main.Position = UDim2.new(0, 30, 0, 200)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.Text = "Monster TP"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = main

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -16, 0, 28)
toggle.Position = UDim2.new(0, 8, 0, 26)
toggle.BackgroundColor3 = Color3.fromRGB(60, 170, 80)
toggle.Text = "ON"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.BorderSizePixel = 0
toggle.AutoButtonColor = false
toggle.Parent = main
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)

local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(1, -16, 0, 14)
radiusLabel.Position = UDim2.new(0, 8, 0, 58)
radiusLabel.BackgroundTransparency = 1
radiusLabel.TextColor3 = Color3.new(1,1,1)
radiusLabel.Font = Enum.Font.Gotham
radiusLabel.TextSize = 12
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Text = "Distance: 8"
radiusLabel.Parent = main

local radiusBox = Instance.new("TextBox")
radiusBox.Size = UDim2.new(1, -16, 0, 24)
radiusBox.Position = UDim2.new(0, 8, 0, 76)
radiusBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
radiusBox.TextColor3 = Color3.new(1,1,1)
radiusBox.Font = Enum.Font.Gotham
radiusBox.TextSize = 13
radiusBox.PlaceholderText = "8"
radiusBox.Text = "8"
radiusBox.BorderSizePixel = 0
radiusBox.ClearTextOnFocus = false
radiusBox.Parent = main
Instance.new("UICorner", radiusBox).CornerRadius = UDim.new(0, 4)

toggle.MouseButton1Click:Connect(function()
    CONFIG.enabled = not CONFIG.enabled
    toggle.Text = CONFIG.enabled and "ON" or "OFF"
    toggle.BackgroundColor3 = CONFIG.enabled and Color3.fromRGB(60, 170, 80) or Color3.fromRGB(170, 60, 60)
end)

radiusBox.FocusLost:Connect(function()
    local n = tonumber(radiusBox.Text)
    if n then
        CONFIG.radius = math.clamp(n, 1, 100)
        radiusBox.Text = tostring(CONFIG.radius)
    else
        radiusBox.Text = tostring(CONFIG.radius)
    end
    radiusLabel.Text = "Distance: " .. CONFIG.radius
end)

local dragging, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
main.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

task.spawn(function()
    while true do
        if CONFIG.enabled then
            local char = LocalPlayer.Character
            if char then
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    local pPos  = root.Position
                    local look  = root.CFrame.LookVector
                    local base  = pPos + look * CONFIG.radius + Vector3.new(0, CONFIG.yOffset, 0)
                    for i = #entities, 1, -1 do
                        local e = entities[i]
                        if e and e.Parent then
                            local eRoot = getEntityRoot(e)
                            if eRoot then
                                local off = Vector3.new(
                                    math.random(-CONFIG.spawnJitter, CONFIG.spawnJitter),
                                    0,
                                    math.random(-CONFIG.spawnJitter, CONFIG.spawnJitter)
                                )
                                eRoot.CFrame = CFrame.new(base + off)
                            end
                        else
                            table.remove(entities, i)
                        end
                    end
                end
            end
        end
        task.wait(CONFIG.tickRate)
    end
end)
