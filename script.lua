-- ==========================================
--  RIVALS HUB + GUI (Исправленный)
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- Настройки по умолчанию
local Settings = {
    InfiniteJump = true,
    Speed = 50,
    ESP = true,
    AimBot = true,
    AimRange = 300,
    AimPart = "Head"
}

-- ==========================================
--  ГЛАВНАЯ ЛОГИКА
-- ==========================================

-- Функция получения персонажа
local function GetCharacter()
    local character = LocalPlayer.Character
    if not character then
        character = LocalPlayer.CharacterAdded:Wait()
    end
    return character
end

-- Применение скорости
local function ApplySpeed()
    local character = GetCharacter()
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = Settings.Speed
    end
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("Humanoid") then
            part.WalkSpeed = Settings.Speed
        end
    end
end

-- Обработка появления нового персонажа
LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    ApplySpeed()
    
    task.spawn(function()
        for i = 1, 10 do
            wait(0.5)
            ApplySpeed()
        end
    end)
end)

if LocalPlayer.Character then
    ApplySpeed()
end

-- Бесконечный прыжок
RunService.RenderStepped:Connect(function()
    if Settings.InfiniteJump then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    humanoid.Jump = true
                    humanoid.JumpPower = 50
                    humanoid.AutoRotate = true
                end
            end
        end
    end
end)

-- ==========================================
--  ESP С ОТСЛЕЖИВАНИЕМ УРОНА
-- ==========================================

-- Таблица для хранения здоровья игроков
local PlayerHealth = {}

-- Функция получения здоровья игрока
local function GetPlayerHealth(player)
    local character = player.Character
    if not character then return nil end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.Health, humanoid.MaxHealth
    end
    
    -- Пробуем найти здоровье в других местах
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("Humanoid") then
            return part.Health, part.MaxHealth
        end
    end
    
    return nil, nil
end

-- Обновление ESP
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local highlight = character:FindFirstChild("ESP_Highlight")
                
                if Settings.ESP then
                    if not highlight then
                        local hl = Instance.new("Highlight")
                        hl.Name = "ESP_Highlight"
                        hl.FillColor = Color3.fromRGB(255, 255, 0) -- Желтый по умолчанию
                        hl.OutlineColor = Color3.new(1, 1, 1)
                        hl.FillTransparency = 0.3
                        hl.OutlineTransparency = 0
                        hl.Parent = character
                        highlight = hl
                    end
                    
                    -- Проверяем здоровье
                    local currentHealth, maxHealth = GetPlayerHealth(player)
                    if currentHealth and maxHealth then
                        local previousHealth = PlayerHealth[player.Name]
                        
                        -- Если здоровье уменьшилось - красный
                        if previousHealth and currentHealth < previousHealth then
                            highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Красный при уроне
                            highlight.OutlineColor = Color3.fromRGB(255, 100, 100)
                            
                            -- Возвращаем желтый через 0.5 секунды
                            task.spawn(function()
                                wait(0.5)
                                if highlight and highlight.Parent then
                                    highlight.FillColor = Color3.fromRGB(255, 255, 0)
                                    highlight.OutlineColor = Color3.new(1, 1, 1)
                                end
                            end)
                        else
                            -- Проверяем, не установлен ли уже таймер на красный
                            if not highlight:GetAttribute("IsDamaged") then
                                highlight.FillColor = Color3.fromRGB(255, 255, 0)
                                highlight.OutlineColor = Color3.new(1, 1, 1)
                            end
                        end
                        
                        -- Сохраняем текущее здоровье
                        PlayerHealth[player.Name] = currentHealth
                    end
                else
                    if highlight then
                        highlight:Destroy()
                        PlayerHealth[player.Name] = nil
                    end
                end
            end
        end
    end
end

-- Мониторинг здоровья в реальном времени
task.spawn(function()
    while true do
        wait(0.1) -- Проверяем каждые 0.1 секунды для быстрой реакции на урон
        
        -- Сохраняем здоровье всех игроков
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local currentHealth, _ = GetPlayerHealth(player)
                if currentHealth then
                    local previousHealth = PlayerHealth[player.Name]
                    
                    -- Если здоровье уменьшилось - помечаем как поврежденного
                    if previousHealth and currentHealth < previousHealth then
                        local character = player.Character
                        if character then
                            local highlight = character:FindFirstChild("ESP_Highlight")
                            if highlight then
                                highlight:SetAttribute("IsDamaged", true)
                                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                                highlight.OutlineColor = Color3.fromRGB(255, 100, 100)
                                
                                -- Возвращаем желтый через 0.5 секунды
                                task.spawn(function()
                                    wait(0.5)
                                    if highlight and highlight.Parent then
                                        highlight.FillColor = Color3.fromRGB(255, 255, 0)
                                        highlight.OutlineColor = Color3.new(1, 1, 1)
                                        highlight:SetAttribute("IsDamaged", false)
                                    end
                                end)
                            end
                        end
                    end
                    
                    PlayerHealth[player.Name] = currentHealth
                end
            end
        end
    end
end)

-- Обновление ESP каждую секунду (для появления новых игроков)
task.spawn(function()
    while true do
        wait(1)
        UpdateESP()
    end
end)

-- ==========================================
--  AIMBOT
-- ==========================================

local MouseHeld = false

UIS.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MouseHeld = true
    end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MouseHeld = false
    end
end)

local function AutoFire()
    if not MouseHeld then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
end

local function GetClosestEnemy()
    local closest, closestDist = nil, Settings.AimRange
    local origin = Camera.CFrame.Position
    
    for _, enemy in ipairs(Players:GetPlayers()) do
        if enemy ~= LocalPlayer and enemy.Character then
            local humanoid = enemy.Character:FindFirstChildOfClass("Humanoid")
            local root = enemy.Character:FindFirstChild("HumanoidRootPart") or enemy.Character:FindFirstChild("Torso")
            
            if humanoid and root and humanoid.Health > 0 then
                local dist = (origin - root.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = enemy
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if Settings.AimBot and LocalPlayer.Character then
        local target = GetClosestEnemy()
        if target and target.Character then
            local part = target.Character:FindFirstChild(Settings.AimPart) or 
                         target.Character:FindFirstChild("HumanoidRootPart") or
                         target.Character:FindFirstChild("Torso")
            
            if part then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, part.Position)
                AutoFire()
            end
        end
    end
end)

-- ==========================================
--  GUI МЕНЮ
-- ==========================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RivalsHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 320)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
Title.Text = "RIVALS HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -70, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
MinimizeBtn.Text = "▼"
MinimizeBtn.TextColor3 = Color3.new(1, 1, 1)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

local yOffset = 50
local function CreateToggle(text, defaultVal, callback)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
    ToggleBtn.Position = UDim2.new(0.05, 0, 0, yOffset)
    ToggleBtn.BackgroundColor3 = defaultVal and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    ToggleBtn.Text = text .. " (" .. tostring(defaultVal) .. ")"
    ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    ToggleBtn.Font = Enum.Font.Gotham
    ToggleBtn.TextSize = 14
    ToggleBtn.Parent = MainFrame
    
    local state = defaultVal
    
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        ToggleBtn.Text = text .. " (" .. tostring(state) .. ")"
    end)
    
    yOffset = yOffset + 45
    return ToggleBtn
end

-- Создаем переключатели
CreateToggle("Бесконечный прыжок", Settings.InfiniteJump, function(state)
    Settings.InfiniteJump = state
end)

CreateToggle("Скорость (50)", true, function(state)
    Settings.Speed = state and 50 or 16
    ApplySpeed()
end)

CreateToggle("ESP (Wallhack)", Settings.ESP, function(state)
    Settings.ESP = state
    UpdateESP()
end)

CreateToggle("AimBot (Наведение)", Settings.AimBot, function(state)
    Settings.AimBot = state
end)

-- Сворачивание
local isMinimized = false
local function ToggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 250, 0, 40)
        MinimizeBtn.Text = "▲"
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child:IsA("TextButton") and child ~= MinimizeBtn and child ~= CloseBtn then
                child.Visible = false
            end
        end
    else
        MainFrame.Size = UDim2.new(0, 250, 0, 320)
        MinimizeBtn.Text = "▼"
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child:IsA("TextButton") and child ~= MinimizeBtn and child ~= CloseBtn then
                child.Visible = true
            end
        end
    end
end

MinimizeBtn.MouseButton1Click:Connect(ToggleMinimize)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Запуск
ApplySpeed()
UpdateESP()
print("Rivals Hub загружен! ESP: желтый - обычный, красный - при уроне.")
