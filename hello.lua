--[[  
    Bisam Console (BETA)
    A modern, professional console GUI for Roblox with improved functionality and mobile support.
    Modified for Roblox exploits and loadstring compatibility.
    
    Usage with loadstring:
    loadstring(game:HttpGet('https://raw.githubusercontent.com/DexCodeSX/lua/refs/heads/main/hello.lua'))():Initialize()
]]--

local BisamConsole = {}

-- Create a self-executing function for loadstring compatibility
local function CreateBisamConsole()

-- Configuration
local CONFIG = {
    TITLE = "Bisam Console (BETA)",
    TOGGLE_TEXT = "BC",
    COLORS = {
        BACKGROUND = Color3.fromRGB(30, 30, 30),
        HEADER = Color3.fromRGB(40, 40, 40),
        TEXT = Color3.fromRGB(255, 255, 255),
        ERROR = Color3.fromRGB(255, 80, 80),
        WARNING = Color3.fromRGB(255, 200, 80),
        TIMESTAMP = Color3.fromRGB(150, 150, 150),
        BUTTON = Color3.fromRGB(60, 60, 60),
        BUTTON_HOVER = Color3.fromRGB(80, 80, 80),
        GRADIENT_START = Color3.fromRGB(85, 170, 255),
        GRADIENT_END = Color3.fromRGB(170, 85, 255),
        FILTER_ENABLED = Color3.fromRGB(80, 200, 120),
        FILTER_DISABLED = Color3.fromRGB(200, 80, 80)
    },
    CORNER_RADIUS = UDim.new(0, 6),
    PADDING = UDim.new(0, 8),
    FONT = Enum.Font.Gotham,
    TEXT_SIZE = 14,
    HEADER_HEIGHT = 40,
    BUTTON_SIZE = UDim2.new(0, 30, 0, 30),
    TOGGLE_SIZE = UDim2.new(0, 40, 0, 40),
    MOBILE_HOLD_TIME = 0.5,
    ANIMATION_TIME = 0.3
}

-- Variables
local gui = nil
local mainFrame = nil
local consoleFrame = nil
local scrollingFrame = nil
local headerFrame = nil
local toggleButton = nil
local filterMenu = nil

local isPaused = false
local isDragging = false
local dragStartPosition = nil
local dragStartOffset = nil
local holdStartTime = nil
local messageCount = 0

local filters = {
    error = true,
    output = true,
    warning = true,
    timestamp = true
}

-- Utility Functions
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or CONFIG.CORNER_RADIUS
    corner.Parent = parent
    return corner
end

local function createPadding(parent, padding)
    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingTop = padding or CONFIG.PADDING
    uiPadding.PaddingBottom = padding or CONFIG.PADDING
    uiPadding.PaddingLeft = padding or CONFIG.PADDING
    uiPadding.PaddingRight = padding or CONFIG.PADDING
    uiPadding.Parent = parent
    return uiPadding
end

local function createGradientText(parent, text, size, position)
    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = size or UDim2.new(1, 0, 1, 0)
    textLabel.Position = position or UDim2.new(0, 0, 0, 0)
    textLabel.Font = CONFIG.FONT
    textLabel.TextSize = CONFIG.TEXT_SIZE
    textLabel.Text = text
    textLabel.TextColor3 = CONFIG.COLORS.TEXT
    textLabel.Parent = parent
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.COLORS.GRADIENT_START),
        ColorSequenceKeypoint.new(1, CONFIG.COLORS.GRADIENT_END)
    })
    gradient.Parent = textLabel
    
    return textLabel, gradient
end

local function createButton(parent, text, size, position, callback)
    local button = Instance.new("TextButton")
    button.BackgroundColor3 = CONFIG.COLORS.BUTTON
    button.Size = size or CONFIG.BUTTON_SIZE
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.Font = CONFIG.FONT
    button.TextSize = CONFIG.TEXT_SIZE
    button.Text = text or ""
    button.TextColor3 = CONFIG.COLORS.TEXT
    button.AutoButtonColor = false
    button.Parent = parent
    
    createCorner(button)
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = CONFIG.COLORS.BUTTON_HOVER
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = CONFIG.COLORS.BUTTON
    end)
    
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

local function createSearchBar(parent, position, size)
    local searchContainer = Instance.new("Frame")
    searchContainer.BackgroundColor3 = CONFIG.COLORS.BUTTON
    searchContainer.Size = size or UDim2.new(0.3, 0, 0, 30)
    searchContainer.Position = position or UDim2.new(0, 0, 0, 0)
    searchContainer.Parent = parent
    
    createCorner(searchContainer)
    
    local searchBox = Instance.new("TextBox")
    searchBox.BackgroundTransparency = 1
    searchBox.Size = UDim2.new(1, -10, 1, 0)
    searchBox.Position = UDim2.new(0, 5, 0, 0)
    searchBox.Font = CONFIG.FONT
    searchBox.TextSize = CONFIG.TEXT_SIZE
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search..."
    searchBox.TextColor3 = CONFIG.COLORS.TEXT
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchContainer
    
    return searchContainer, searchBox
end

local function createFilterCircle(parent, enabled, position)
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = position or UDim2.new(0, 0, 0, 0)
    circle.BackgroundColor3 = enabled and CONFIG.COLORS.FILTER_ENABLED or CONFIG.COLORS.FILTER_DISABLED
    circle.Parent = parent
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0) -- Make it a perfect circle
    uiCorner.Parent = circle
    
    return circle
end

local function createFilterOption(parent, text, enabled, position, callback)
    local optionFrame = Instance.new("Frame")
    optionFrame.BackgroundTransparency = 1
    optionFrame.Size = UDim2.new(1, 0, 0, 30)
    optionFrame.Position = position or UDim2.new(0, 0, 0, 0)
    optionFrame.Parent = parent
    
    local circle = createFilterCircle(optionFrame, enabled, UDim2.new(0, 0, 0.5, -8))
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.Font = CONFIG.FONT
    label.TextSize = CONFIG.TEXT_SIZE
    label.Text = text
    label.TextColor3 = CONFIG.COLORS.TEXT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = optionFrame
    
    local button = Instance.new("TextButton")
    button.BackgroundTransparency = 1
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Text = ""
    button.Parent = optionFrame
    
    if callback then
        button.MouseButton1Click:Connect(function()
            local newState = not enabled
            enabled = newState
            circle.BackgroundColor3 = enabled and CONFIG.COLORS.FILTER_ENABLED or CONFIG.COLORS.FILTER_DISABLED
            callback(newState)
        end)
    end
    
    return optionFrame, circle, enabled
end

-- Main Functions
function BisamConsole:Initialize()
    if gui then return end
    
    -- Create ScreenGui
    gui = Instance.new("ScreenGui")
    gui.Name = "BisamConsole"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- For exploit environment, always use CoreGui
    local success, result = pcall(function()
        gui.Parent = game:GetService("CoreGui")
        return true
    end)
    
    if not success then
        -- Fallback if CoreGui is not accessible
        pcall(function()
            gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
    
    -- Create main frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.BackgroundColor3 = CONFIG.COLORS.BACKGROUND
    mainFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
    mainFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
    mainFrame.Parent = gui
    createCorner(mainFrame)
    
    -- Create header
    self:CreateHeader()
    
    -- Create console frame
    self:CreateConsoleFrame()
    
    -- Create control buttons
    self:CreateControlButtons()
    
    -- Create toggle button (initially hidden)
    self:CreateToggleButton()
    
    -- Create filter menu (initially hidden)
    self:CreateFilterMenu()
    
    -- Connect to LogService
    self:ConnectLogService()
    
    return self
end

function BisamConsole:CreateHeader()
    headerFrame = Instance.new("Frame")
    headerFrame.Name = "Header"
    headerFrame.BackgroundColor3 = CONFIG.COLORS.HEADER
    headerFrame.Size = UDim2.new(1, 0, 0, CONFIG.HEADER_HEIGHT)
    headerFrame.Parent = mainFrame
    createCorner(headerFrame)
    
    -- Make only the top corners rounded
    local bottomFrame = Instance.new("Frame")
    bottomFrame.BackgroundColor3 = CONFIG.COLORS.HEADER
    bottomFrame.Size = UDim2.new(1, 0, 0.5, 0)
    bottomFrame.Position = UDim2.new(0, 0, 0.5, 0)
    bottomFrame.BorderSizePixel = 0
    bottomFrame.Parent = headerFrame
    
    -- Title with gradient
    local title, gradient = createGradientText(headerFrame, CONFIG.TITLE, UDim2.new(0.7, 0, 1, 0), UDim2.new(0, 10, 0, 0))
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Animate gradient
    task.spawn(function()
        while headerFrame and headerFrame.Parent do
            for i = 0, 1, 0.005 do
                if not gradient or not gradient.Parent then break end
                gradient.Offset = Vector2.new(i, 0)
                task.wait(0.03)
            end
        end
    end)
    
    -- Close button
    local closeButton = createButton(headerFrame, "X", UDim2.new(0, 30, 0, 30), UDim2.new(1, -40, 0.5, -15), function()
        gui:Destroy()
        gui = nil
    end)
    
    -- Minimize button
    local minimizeButton = createButton(headerFrame, "-", UDim2.new(0, 30, 0, 30), UDim2.new(1, -80, 0.5, -15), function()
        self:MinimizeConsole()
    end)
    
    -- Make header draggable
    headerFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartPosition = input.Position
            dragStartOffset = mainFrame.Position
            
            -- For mobile hold detection
            if input.UserInputType == Enum.UserInputType.Touch then
                holdStartTime = tick()
            end
        end
    end)
    
    headerFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
            holdStartTime = nil
        end
    end)
    
    headerFrame.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPosition
            mainFrame.Position = UDim2.new(
                dragStartOffset.X.Scale, dragStartOffset.X.Offset + delta.X,
                dragStartOffset.Y.Scale, dragStartOffset.Y.Offset + delta.Y
            )
        end
    end)
    
    return headerFrame
end

function BisamConsole:CreateConsoleFrame()
    consoleFrame = Instance.new("Frame")
    consoleFrame.Name = "ConsoleFrame"
    consoleFrame.BackgroundTransparency = 1
    consoleFrame.Size = UDim2.new(1, 0, 1, -(CONFIG.HEADER_HEIGHT + 40))
    consoleFrame.Position = UDim2.new(0, 0, 0, CONFIG.HEADER_HEIGHT)
    consoleFrame.Parent = mainFrame
    
    scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "ScrollingFrame"
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.Size = UDim2.new(1, -16, 1, 0)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.ScrollBarThickness = 6
    scrollingFrame.ScrollBarImageColor3 = CONFIG.COLORS.BUTTON_HOVER
    scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollingFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    scrollingFrame.Parent = consoleFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = scrollingFrame
    
    createPadding(scrollingFrame)
    
    -- Auto-scroll to bottom when new messages are added
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not isPaused then
            scrollingFrame.CanvasPosition = Vector2.new(0, listLayout.AbsoluteContentSize.Y)
        end
    end)
    
    return consoleFrame
end

function BisamConsole:CreateControlButtons()
    local controlFrame = Instance.new("Frame")
    controlFrame.Name = "ControlFrame"
    controlFrame.BackgroundTransparency = 1
    controlFrame.Size = UDim2.new(1, 0, 0, 40)
    controlFrame.Position = UDim2.new(0, 0, 1, -40)
    controlFrame.Parent = mainFrame
    
    -- Copy button
    local copyButton = createButton(controlFrame, "Copy", UDim2.new(0, 60, 0, 30), UDim2.new(0, 10, 0.5, -15), function()
        self:CopyConsoleContent()
    end)
    
    -- Clear button
    local clearButton = createButton(controlFrame, "Clear", UDim2.new(0, 60, 0, 30), UDim2.new(0, 80, 0.5, -15), function()
        self:ClearConsole()
    end)
    
    -- Pause/Start button
    local pauseButton = createButton(controlFrame, "Pause", UDim2.new(0, 60, 0, 30), UDim2.new(0, 150, 0.5, -15), function()
        isPaused = not isPaused
        pauseButton.Text = isPaused and "Start" or "Pause"
    end)
    
    -- Search bar
    local searchContainer, searchBox = createSearchBar(controlFrame, UDim2.new(0.5, -100, 0.5, -15), UDim2.new(0.3, 0, 0, 30))
    
    -- Add nil check before connecting signal
    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            self:FilterConsoleBySearch(searchBox.Text)
        end)
    end
    
    -- Filter button
    local filterButton = createButton(controlFrame, "Filters", UDim2.new(0, 60, 0, 30), UDim2.new(1, -70, 0.5, -15), function()
        self:ToggleFilterMenu()
    end)
    
    return controlFrame
end

function BisamConsole:CreateToggleButton()
    toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = CONFIG.TOGGLE_SIZE
    toggleButton.Position = UDim2.new(0.9, 0, 0.9, 0)
    toggleButton.BackgroundColor3 = CONFIG.COLORS.BACKGROUND
    toggleButton.Visible = false
    toggleButton.Parent = gui
    createCorner(toggleButton, UDim.new(0, 8))
    
    -- Gradient text
    local toggleText, gradient = createGradientText(toggleButton, CONFIG.TOGGLE_TEXT)
    
    -- Animate gradient
    task.spawn(function()
        while toggleButton and toggleButton.Parent do
            for i = 0, 1, 0.005 do
                if not gradient or not gradient.Parent then break end
                gradient.Offset = Vector2.new(i, 0)
                task.wait(0.03)
            end
        end
    end)
    
    -- Toggle functionality
    toggleButton.MouseButton1Click:Connect(function()
        self:MaximizeConsole()
    end)
    
    -- Mobile drag functionality
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            holdStartTime = tick()
            dragStartPosition = input.Position
            dragStartOffset = toggleButton.Position
        end
    end)
    
    toggleButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local holdDuration = tick() - (holdStartTime or 0)
            holdStartTime = nil
            
            if holdDuration < CONFIG.MOBILE_HOLD_TIME then
                -- Short tap, toggle console
                if not isDragging then
                    self:MaximizeConsole()
                end
            end
            
            isDragging = false
        end
    end)
    
    toggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and holdStartTime then
            local holdDuration = tick() - holdStartTime
            
            if holdDuration >= CONFIG.MOBILE_HOLD_TIME then
                -- Long hold, enable dragging
                isDragging = true
                local delta = input.Position - dragStartPosition
                toggleButton.Position = UDim2.new(
                    dragStartOffset.X.Scale, dragStartOffset.X.Offset + delta.X,
                    dragStartOffset.Y.Scale, dragStartOffset.Y.Offset + delta.Y
                )
            end
        end
    end)
    
    return toggleButton
end

function BisamConsole:CreateFilterMenu()
    filterMenu = Instance.new("Frame")
    filterMenu.Name = "FilterMenu"
    filterMenu.BackgroundColor3 = CONFIG.COLORS.BACKGROUND
    filterMenu.Size = UDim2.new(0, 200, 0, 220)
    filterMenu.Position = UDim2.new(0.5, -100, 0.5, -110)
    filterMenu.Visible = false
    filterMenu.Parent = gui
    createCorner(filterMenu)
    
    -- Title
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Font = CONFIG.FONT
    title.TextSize = CONFIG.TEXT_SIZE
    title.Text = "Filter Options"
    title.TextColor3 = CONFIG.COLORS.TEXT
    title.Parent = filterMenu
    
    -- Options container
    local optionsFrame = Instance.new("Frame")
    optionsFrame.BackgroundTransparency = 1
    optionsFrame.Size = UDim2.new(1, 0, 0, 140)
    optionsFrame.Position = UDim2.new(0, 0, 0, 30)
    optionsFrame.Parent = filterMenu
    createPadding(optionsFrame)
    
    -- Filter options
    local errorOption, errorCircle = createFilterOption(optionsFrame, "Error Messages", filters.error, UDim2.new(0, 0, 0, 0), function(enabled)
        filters.error = enabled
        self:ApplyFilters()
    end)
    
    local outputOption, outputCircle = createFilterOption(optionsFrame, "Output Messages", filters.output, UDim2.new(0, 0, 0, 35), function(enabled)
        filters.output = enabled
        self:ApplyFilters()
    end)
    
    local warningOption, warningCircle = createFilterOption(optionsFrame, "Warning Messages", filters.warning, UDim2.new(0, 0, 0, 70), function(enabled)
        filters.warning = enabled
        self:ApplyFilters()
    end)
    
    local timestampOption, timestampCircle = createFilterOption(optionsFrame, "Show Timestamps", filters.timestamp, UDim2.new(0, 0, 0, 105), function(enabled)
        filters.timestamp = enabled
        self:ApplyFilters()
    end)
    
    -- Buttons
    local buttonFrame = Instance.new("Frame")
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Size = UDim2.new(1, 0, 0, 40)
    buttonFrame.Position = UDim2.new(0, 0, 1, -50)
    buttonFrame.Parent = filterMenu
    
    local saveButton = createButton(buttonFrame, "Save", UDim2.new(0, 80, 0, 30), UDim2.new(0, 10, 0.5, -15), function()
        filterMenu.Visible = false
    end)
    
    local closeButton = createButton(buttonFrame, "Close", UDim2.new(0, 80, 0, 30), UDim2.new(1, -90, 0.5, -15), function()
        filterMenu.Visible = false
    end)
    
    -- Close when clicking outside
    local closeDetector = Instance.new("TextButton")
    closeDetector.BackgroundTransparency = 1
    closeDetector.Size = UDim2.new(1, 0, 1, 0)
    closeDetector.Text = ""
    closeDetector.ZIndex = -1
    closeDetector.Parent = gui
    closeDetector.Visible = false
    
    closeDetector.MouseButton1Click:Connect(function()
        filterMenu.Visible = false
        closeDetector.Visible = false
    end)
    
    return filterMenu
end

function BisamConsole:ConnectLogService()
    local LogService = game:GetService("LogService")
    
    -- Process existing logs
    local logs = {}
    pcall(function()
        logs = LogService:GetLogHistory()
    end)
    
    for _, log in ipairs(logs) do
        self:AddConsoleMessage(log.message, log.messageType)
    end
    
    -- Connect to new logs
    LogService.MessageOut:Connect(function(message, messageType)
        if not isPaused then
            task.spawn(function()
                self:AddConsoleMessage(message, messageType)
            end)
        end
    end)
    
    return self
end

function BisamConsole:AddConsoleMessage(message, messageType)
    if not scrollingFrame or not scrollingFrame.Parent then return end
    
    -- Check filters
    local shouldShow = true
    if messageType == Enum.MessageType.MessageError and not filters.error then
        shouldShow = false
    elseif messageType == Enum.MessageType.MessageOutput and not filters.output then
        shouldShow = false
    elseif messageType == Enum.MessageType.MessageWarning and not filters.warning then
        shouldShow = false
    end
    
    if not shouldShow then return end
    
    -- Create message container
    local messageFrame = Instance.new("Frame")
    messageFrame.Name = "Message_" .. messageCount
    messageFrame.BackgroundTransparency = 1
    messageFrame.Size = UDim2.new(1, 0, 0, 0) -- Auto-size based on content
    messageFrame.AutomaticSize = Enum.AutomaticSize.Y
    messageFrame.LayoutOrder = messageCount
    messageFrame.Parent = scrollingFrame
    
    messageCount = messageCount + 1
    
    -- Add timestamp if enabled
    if filters.timestamp then
        local timestamp = os.date("[%H:%M:%S] ")
        local timestampLabel = Instance.new("TextLabel")
        timestampLabel.BackgroundTransparency = 1
        timestampLabel.Size = UDim2.new(0, 70, 0, 20)
        timestampLabel.Position = UDim2.new(0, 0, 0, 0)
        timestampLabel.Font = CONFIG.FONT
        timestampLabel.TextSize = CONFIG.TEXT_SIZE - 2
        timestampLabel.Text = timestamp
        timestampLabel.TextColor3 = CONFIG.COLORS.TIMESTAMP
        timestampLabel.TextXAlignment = Enum.TextXAlignment.Left
        timestampLabel.Parent = messageFrame
    end
    
    -- Determine message color and prefix
    local textColor = CONFIG.COLORS.TEXT
    local prefix = ""
    local xOffset = filters.timestamp and 70 or 0
    
    if messageType == Enum.MessageType.MessageError then
        textColor = CONFIG.COLORS.ERROR
        prefix = "ERROR: "
    elseif messageType == Enum.MessageType.MessageWarning then
        textColor = CONFIG.COLORS.WARNING
        prefix = "WARN: "
    elseif messageType == Enum.MessageType.MessageOutput then
        textColor = CONFIG.COLORS.TEXT
        prefix = "OUTPUT: "
    end
    
    -- Create message text
    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -xOffset, 0, 0)
    textLabel.Position = UDim2.new(0, xOffset, 0, 0)
    textLabel.Font = CONFIG.FONT
    textLabel.TextSize = CONFIG.TEXT_SIZE
    textLabel.Text = prefix .. message
    textLabel.TextColor3 = textColor
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.TextWrapped = true
    textLabel.AutomaticSize = Enum.AutomaticSize.Y
    textLabel.Parent = messageFrame
    
    -- Store message type as attribute for filtering
    messageFrame:SetAttribute("MessageType", tostring(messageType))
    messageFrame:SetAttribute("Message", message)
    
    return messageFrame
end

function BisamConsole:MinimizeConsole()
    mainFrame.Visible = false
    toggleButton.Visible = true
end

function BisamConsole:MaximizeConsole()
    mainFrame.Visible = true
    toggleButton.Visible = false
end

function BisamConsole:ToggleFilterMenu()
    filterMenu.Visible = not filterMenu.Visible
    
    -- Show/hide click detector
    local closeDetector = gui:FindFirstChild("TextButton")
    if closeDetector then
        closeDetector.Visible = filterMenu.Visible
        if filterMenu.Visible then
            closeDetector.ZIndex = filterMenu.ZIndex - 1
        end
    end
end

function BisamConsole:CopyConsoleContent()
    local searchText = ""
    local searchBox = nil
    
    -- Find search box
    for _, child in pairs(mainFrame:GetDescendants()) do
        if child:IsA("TextBox") and child.PlaceholderText == "Search..." then
            searchBox = child
            searchText = child.Text
            break
        end
    end
    
    local content = ""
    
    for _, child in pairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") and child.Visible then
            local messageType = child:GetAttribute("MessageType")
            local message = child:GetAttribute("Message")
            
            if message then
                -- Add timestamp if enabled
                if filters.timestamp then
                    local timestamp = os.date("[%H:%M:%S] ")
                    content = content .. timestamp
                end
                
                -- Add prefix based on message type
                if messageType == tostring(Enum.MessageType.MessageError) then
                    content = content .. "ERROR: "
                elseif messageType == tostring(Enum.MessageType.MessageWarning) then
                    content = content .. "WARN: "
                elseif messageType == tostring(Enum.MessageType.MessageOutput) then
                    content = content .. "OUTPUT: "
                end
                
                content = content .. message .. "\n"
            end
        end
    end
    
    -- Copy to clipboard
    if setclipboard then
        setclipboard(content)
    elseif writefile then
        -- Fallback for exploits that don't have setclipboard but have writefile
        pcall(function()
            writefile("BisamConsoleLog.txt", content)
        end)
    end
end

function BisamConsole:ClearConsole()
    for _, child in pairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    messageCount = 0
end

function BisamConsole:FilterConsoleBySearch(searchText)
    -- Ensure searchText is not nil before calling lower()
    searchText = searchText and searchText:lower() or ""
    
    for _, child in pairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") then
            local message = child:GetAttribute("Message")
            
            if message then
                if searchText == "" then
                    child.Visible = true
                else
                    child.Visible = message:lower():find(searchText, 1, true) ~= nil
                end
            end
        end
    end
end

function BisamConsole:ApplyFilters()
    for _, child in pairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") then
            local messageType = child:GetAttribute("MessageType")
            
            if messageType then
                local shouldShow = true
                
                if messageType == tostring(Enum.MessageType.MessageError) and not filters.error then
                    shouldShow = false
                elseif messageType == tostring(Enum.MessageType.MessageOutput) and not filters.output then
                    shouldShow = false
                elseif messageType == tostring(Enum.MessageType.MessageWarning) and not filters.warning then
                    shouldShow = false
                end
                
                child.Visible = shouldShow
            end
            
            -- Update timestamp visibility
            for _, descendant in pairs(child:GetDescendants()) do
                if descendant:IsA("TextLabel") and descendant.TextColor3 == CONFIG.COLORS.TIMESTAMP then
                    descendant.Visible = filters.timestamp
                    
                    -- Adjust message position based on timestamp visibility
                    for _, sibling in pairs(child:GetChildren()) do
                        if sibling:IsA("TextLabel") and sibling ~= descendant then
                            sibling.Position = UDim2.new(0, filters.timestamp and 70 or 0, 0, 0)
                            sibling.Size = UDim2.new(1, filters.timestamp and -70 or 0, 0, 0)
                        end
                    end
                end
            end
        end
    end
end

end

-- Execute the function to create the module
CreateBisamConsole()

-- Return the module for both require and loadstring compatibility
return BisamConsole