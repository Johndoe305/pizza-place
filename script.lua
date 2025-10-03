-- Script Otimizado OP: Supply Teleporter com Verificação Total
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Variáveis de controle
local isActive = false
local remote
local originalCFrame = nil -- Armazena a posição original
local initialSupplyCount = 0 -- Conta inicial de supplies

-- Função para encontrar o remote
local function findRemote()
    local reg = (getreg or debug.getregistry)()
    for i = 1, #reg do
        local f = reg[i]
        if type(f) == "table" and rawget(f, "FireServer") and rawget(f, "BindEvents") then
            remote = f
            print("Remote encontrado:", remote)
            return
        end
    end
    warn("Remote não encontrado! O teleporte pode não funcionar.")
end

-- Função para mover objetos com segurança
local function moveThing(bmd, location)
    if remote and bmd and bmd.Parent then
        print("Tentando mover:", bmd.Name, "para:", location)
        local success, err = pcall(function()
            remote:FireServer("UpdateProperty", bmd, "CFrame", location)
        end)
        if not success then
            warn("Erro ao mover:", bmd.Name, "Erro:", err)
            return false
        end
        wait(0.1) -- Pequeno delay para evitar conflitos
        return true
    else
        warn("Erro: remote, bmd ou bmd.Parent não existe para:", bmd)
        return false
    end
end

-- Função para criar um tween
local function createTween(object, targetCFrame, duration)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

-- Função para contar supplies no mapa
local function countSupplies()
    local count = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("supply") or obj.Name:lower():find("box") or obj:FindFirstAncestor("AllSupplyBoxes")) then
            count = count + 1
        end
    end
    return count
end

-- Delay para garantir carregamento
wait(10)

-- Criação da GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SupplyTeleporterGui"
ScreenGui.Parent = game:GetService("CoreGui")
print("ScreenGui criado!")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 100)
Frame.Position = UDim2.new(0.5, -110, 0.5, -50)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.ZIndex = 2000
Frame.Parent = ScreenGui
print("Frame criado!")

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Supply Teleporter"
Title.TextColor3 = Color3.fromRGB(255, 200, 50)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextStrokeTransparency = 0.7
Title.ZIndex = 2001
Title.Parent = Frame
print("Título criado!")

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.8, 0, 0, 40)
ToggleButton.Position = UDim2.new(0.1, 0, 0.3, 0)
ToggleButton.Text = "Ativar Teleporte"
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 12
ToggleButton.ZIndex = 2001
ToggleButton.Parent = Frame
print("Botão criado!")

local UICornerButton = Instance.new("UICorner")
UICornerButton.CornerRadius = UDim.new(0, 8)
UICornerButton.Parent = ToggleButton

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
StatusLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
StatusLabel.Text = "Status: Desativado"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.ZIndex = 2001
StatusLabel.Parent = Frame
print("StatusLabel criada!")

-- Encontrar remote ao iniciar
findRemote()

-- Função para teletransportar supplies e jogador com tween
local function teleportSuppliesAndPlayer()
    while isActive and wait() do
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            warn("Aguardando personagem ou HumanoidRootPart...")
            wait(1)
            continue
        end

        -- Salvar posição original do jogador antes de qualquer movimento
        originalCFrame = character.HumanoidRootPart.CFrame

        -- Contar supplies iniciais para validação
        initialSupplyCount = countSupplies()
        print("Contagem inicial de supplies:", initialSupplyCount)

        -- Encontrar a posição de uma supply para teleportar o jogador
        local supplyFolder = Workspace:FindFirstChild("AllSupplyBoxes")
        if not supplyFolder then
            warn("Pasta AllSupplyBoxes não encontrada no Workspace!")
            wait(1)
            continue
        end

        local targetSupply = nil
        for _, supply in pairs(supplyFolder:GetDescendants()) do
            if supply and supply.Parent and supply:IsA("BasePart") then
                targetSupply = supply
                break
            end
        end
        if not targetSupply then
            warn("Nenhuma supply válida encontrada na pasta AllSupplyBoxes ou descendentes!")
            wait(1)
            continue
        end

        -- Passo 1: Iniciar tween do jogador até a supply
        local supplyCFrame = targetSupply.CFrame * CFrame.new(0, 2, 0) -- Posição acima da supply
        print("Iniciando tween do jogador para:", supplyCFrame)
        local tween = createTween(character.HumanoidRootPart, supplyCFrame, 0.1) -- 0.1 segundos para teleporte rápido

        -- Passo 2: Teleportar todas as supplies para a posição original imediatamente
        local supplyTargetCFrame = originalCFrame * CFrame.new(0, 2, -2) -- Posição perto da original
        local movedCount = 0
        for _, supply in pairs(Workspace:GetDescendants()) do
            if supply:IsA("BasePart") and (supply.Name:lower():find("supply") or supply.Name:lower():find("box") or supply:FindFirstAncestor("AllSupplyBoxes")) then
                print("Tentando teleportar supply:", supply.Name)
                if moveThing(supply, supplyTargetCFrame) then
                    movedCount = movedCount + 1
                end
            end
        end

        -- Verificação: Se não moveu todas as supplies, cancela o processo
        if movedCount < initialSupplyCount then
            warn("Falha: Movidas", movedCount, "de", initialSupplyCount, "supplies. Processo abortado!")
            isActive = false
            ToggleButton.Text = "Ativar Teleporte"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            StatusLabel.Text = "Status: Desativado"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            character.HumanoidRootPart.CFrame = originalCFrame -- Volta imediatamente
            break
        end

        -- Passo 3: Aguarda o tween e retorna
        tween.Completed:Wait()
        wait(0.1) -- Pequeno delay para estabilidade
    end
end

-- Evento do botão
ToggleButton.MouseButton1Click:Connect(function()
    print("Botão clicado!")
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        warn("Personagem ou HumanoidRootPart não encontrado!")
        return
    end

    if not isActive then
        -- Ativação
        originalCFrame = character.HumanoidRootPart.CFrame
        isActive = true
        ToggleButton.Text = "Desativar Teleporte"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        StatusLabel.Text = "Status: Ativado"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        spawn(teleportSuppliesAndPlayer)
        print("Teleporte de supplies ativado!")
    else
        -- Desativação
        isActive = false
        ToggleButton.Text = "Ativar Teleporte"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        StatusLabel.Text = "Status: Desativado"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        if originalCFrame then
            print("Retornando à posição original:", originalCFrame)
            character.HumanoidRootPart.CFrame = originalCFrame
        end
        print("Teleporte de supplies desativado!")
    end
end)
