-- Forsaken Monster Magnet v2 (physics-based, не обход авторитета)
local Players = game:GetService("Players")
local RunSvc  = game:GetService("RunService")
local LP = Players.LocalPlayer

local CONFIG = {
    folder = workspace:WaitForChild("Entities"),
    force  = 40000,
    speed  = 60,
    tick   = 0.05,
    on     = true,
}

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
        lv.MaxForce = CONFIG.force
        lv.Attachment0 = att
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.Parent = part
    end
    return lv
end

RunSvc.Heartbeat:Connect(function()
    if not CONFIG.on then return end
    local char = LP.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, e in CONFIG.folder:GetChildren() do
        local r = rootOf(e)
        if r then
            local dir = (myRoot.Position - r.Position)
            local dist = dir.Magnitude
            if dist < 200 and dist > 0.5 then
                ensureVel(r).VectorVelocity = dir.Unit * CONFIG.speed
            end
        end
    end
end)
