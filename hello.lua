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
        -- Modern sleek primary colors
        BACKGROUND = Color3.fromRGB(22, 22, 26),       -- Darker background for better contrast
        HEADER = Color3.fromRGB(32, 32, 38),           -- Slightly lighter header
        TEXT = Color3.fromRGB(240, 240, 245),          -- Softer white text
        ERROR = Color3.fromRGB(255, 75, 75),           -- Vibrant red for errors
        WARNING = Color3.fromRGB(255, 190, 60),        -- Warm yellow for warnings
        INFO = Color3.fromRGB(65, 160, 255),           -- Bright blue for info
        TIMESTAMP = Color3.fromRGB(140, 140, 150),     -- Subtle gray for timestamps
        BUTTON = Color3.fromRGB(45, 45, 55),           -- Deeper button color
        BUTTON_HOVER = Color3.fromRGB(65, 65, 80),     -- Lighter hover state
        GRADIENT_START = Color3.fromRGB(65, 180, 255), -- Vibrant blue start
        GRADIENT_END = Color3.fromRGB(180, 75, 255),   -- Rich purple end
        FILTER_ENABLED = Color3.fromRGB(70, 210, 110), -- Brighter green
        FILTER_DISABLED = Color3.fromRGB(210, 70, 70), -- Brighter red
        DRAG_INDICATOR = Color3.fromRGB(180, 75, 255), -- Drag indicator color
        GLOW_EFFECT = Color3.fromRGB(120, 120, 255)    -- Glow effect color
    },
    CORNER_RADIUS = UDim.new(0, 8),                   -- Slightly more rounded corners
    PADDING = UDim.new(0, 10),                         -- More padding for better spacing
    FONT = Enum.Font.GothamSemibold,                   -- Semibold for better readability
    TEXT_SIZE = 14,
    HEADER_HEIGHT = 42,                                -- Slightly taller header
    BUTTON_SIZE = UDim2.new(0, 32, 0, 32),             -- Slightly larger buttons
    TOGGLE_SIZE = UDim2.new(0, 45, 0, 45),             -- Larger toggle for mobile
    MOBILE_HOLD_TIME = 0.5,                            -- Hold time for dragging (exactly 0.5s)
    ANIMATION_TIME = 0.25,                             -- Faster animations
    TOGGLE_SHADOW_SIZE = 4,                            -- Increased shadow size for toggle button
    TOGGLE_SHADOW_TRANSPARENCY = 0.7,                  -- Shadow transparency
    MOBILE_DRAG_FEEDBACK = true,                       -- Enable visual feedback for mobile dragging
    TOUCH_FEEDBACK_INTENSITY = 0.8,                    -- Intensity of touch feedback (0-1)
    SNAP_TO_EDGE_THRESHOLD = 0.1,                      -- Threshold for snapping to edges (0-1)
    DRAG_ANIMATION_SPEED = 0.3                         -- Speed of drag animations
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
    info = true,     -- New filter for Info messages
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
    -- Create container with modern styling
    local searchContainer = Instance.new("Frame")
    searchContainer.BackgroundColor3 = CONFIG.COLORS.BUTTON
    searchContainer.Size = size or UDim2.new(0.3, 0, 0, 30)
    searchContainer.Position = position or UDim2.new(0, 0, 0, 0)
    searchContainer.Parent = parent
    
    createCorner(searchContainer, UDim.new(0, 8)) -- More rounded corners
    
    -- Add subtle inner stroke for depth
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.COLORS.GRADIENT_START
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = searchContainer
    
    -- Create search icon
    local searchIcon = Instance.new("TextLabel")
    searchIcon.BackgroundTransparency = 1
    searchIcon.Size = UDim2.new(0, 20, 0, 20)
    searchIcon.Position = UDim2.new(0, 8, 0.5, -10)
    searchIcon.Font = Enum.Font.GothamBold
    searchIcon.TextSize = CONFIG.TEXT_SIZE
    searchIcon.Text = "🔍" -- Search icon
    searchIcon.TextColor3 = CONFIG.COLORS.TEXT
    searchIcon.TextTransparency = 0.3
    searchIcon.Parent = searchContainer
    
    -- Create search box with improved styling
    local searchBox = Instance.new("TextBox")
    searchBox.BackgroundTransparency = 1
    searchBox.Size = UDim2.new(1, -40, 1, 0)
    searchBox.Position = UDim2.new(0, 30, 0, 0)
    searchBox.Font = CONFIG.FONT
    searchBox.TextSize = CONFIG.TEXT_SIZE
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search..."
    searchBox.TextColor3 = CONFIG.COLORS.TEXT
    searchBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 190) -- Lighter placeholder text
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchContainer
    
    -- Create clear button (X) that appears when text is entered
    local clearButton = Instance.new("TextButton")
    clearButton.BackgroundTransparency = 1
    clearButton.Size = UDim2.new(0, 20, 0, 20)
    clearButton.Position = UDim2.new(1, -25, 0.5, -10)
    clearButton.Font = Enum.Font.GothamBold
    clearButton.TextSize = CONFIG.TEXT_SIZE
    clearButton.Text = "×" -- × symbol for clear
    clearButton.TextColor3 = CONFIG.COLORS.TEXT
    clearButton.Visible = false -- Only show when there's text
    clearButton.Parent = searchContainer
    
    -- Show/hide clear button based on text content
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        clearButton.Visible = searchBox.Text ~= ""
    end)
    
    -- Clear text when button is clicked
    clearButton.MouseButton1Click:Connect(function()
        searchBox.Text = ""
    end)
    
    -- Visual feedback for hover and focus
    local function updateVisualState()
        if searchBox:IsFocused() then
            -- Focused state
            stroke.Color = CONFIG.COLORS.GRADIENT_END
            stroke.Transparency = 0.5
            searchIcon.TextTransparency = 0
        else
            -- Normal state
            stroke.Color = CONFIG.COLORS.GRADIENT_START
            stroke.Transparency = 0.7
            searchIcon.TextTransparency = 0.3
        end
    end
    
    searchBox.Focused:Connect(updateVisualState)
    searchBox.FocusLost:Connect(updateVisualState)
    
    -- Add subtle animation when focusing
    searchBox.Focused:Connect(function()
        -- Slight grow animation
        local originalSize = searchContainer.Size
        local originalPos = searchContainer.Position
        
        searchContainer:TweenSize(
            UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 4, 
                      originalSize.Y.Scale, originalSize.Y.Offset + 2),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.1,
            true
        )
        
        searchContainer:TweenPosition(
            UDim2.new(originalPos.X.Scale, originalPos.X.Offset - 2, 
                      originalPos.Y.Scale, originalPos.Y.Offset - 1),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.1,
            true
        )
    end)
    
    searchBox.FocusLost:Connect(function()
        -- Return to original size
        searchContainer:TweenSize(
            size or UDim2.new(0.3, 0, 0, 30),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.1,
            true
        )
        
        searchContainer:TweenPosition(
            position or UDim2.new(0, 0, 0, 0),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.1,
            true
        )
    end)
    
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
    
    -- Create container for main frame (without shadow)
    local frameContainer = Instance.new("Frame")
    frameContainer.Name = "FrameContainer"
    frameContainer.BackgroundTransparency = 1
    frameContainer.Size = UDim2.new(0.6, 0, 0.6, 0) -- No extra padding needed
    frameContainer.Position = UDim2.new(0.2, 0, 0.2, 0)
    frameContainer.Parent = gui
    
    -- Create main frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.BackgroundColor3 = CONFIG.COLORS.BACKGROUND
    mainFrame.Size = UDim2.new(1, 0, 1, 0) -- Full size of container
    mainFrame.Position = UDim2.new(0, 0, 0, 0) -- No offset needed
    mainFrame.Parent = frameContainer
    createCorner(mainFrame)
    
    -- Add subtle gradient background for modern look
    local backgroundGradient = Instance.new("UIGradient")
    backgroundGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.COLORS.BACKGROUND),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 45))
    })
    backgroundGradient.Rotation = 45
    backgroundGradient.Parent = mainFrame
    
    -- Add subtle inner stroke for depth
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 70)
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = mainFrame
    
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
    
    -- Create a separate top border with gradient
    local topBorder = Instance.new("Frame")
    topBorder.Name = "TopBorder"
    topBorder.BackgroundColor3 = CONFIG.COLORS.GRADIENT_START
    topBorder.BorderSizePixel = 0
    topBorder.Size = UDim2.new(1, 0, 0, 2)
    topBorder.Position = UDim2.new(0, 0, 0, 0)
    topBorder.ZIndex = headerFrame.ZIndex + 1
    topBorder.Parent = headerFrame
    
    -- Add gradient to top border
    local borderGradient = Instance.new("UIGradient")
    borderGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.COLORS.GRADIENT_START),
        ColorSequenceKeypoint.new(1, CONFIG.COLORS.GRADIENT_END)
    })
    borderGradient.Parent = topBorder
    
    -- Animate border gradient
    task.spawn(function()
        while headerFrame and headerFrame.Parent do
            for i = 0, 1, 0.005 do
                if not borderGradient or not borderGradient.Parent then break end
                borderGradient.Offset = Vector2.new(i, 0)
                task.wait(0.03)
            end
        end
    end)
    
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
    title.TextSize = CONFIG.TEXT_SIZE + 2 -- Slightly larger text
    title.Font = Enum.Font.GothamBold -- Bold font for better visibility
    
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
    
    -- Close button with improved styling
    local closeButton = createButton(headerFrame, "X", UDim2.new(0, 30, 0, 30), UDim2.new(1, -40, 0.5, -15), function()
        gui:Destroy()
        gui = nil
    end)
    closeButton.Font = Enum.Font.GothamBold
    
    -- Add hover color change for close button
    closeButton.MouseEnter:Connect(function()
        closeButton.BackgroundColor3 = CONFIG.COLORS.ERROR
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    closeButton.MouseLeave:Connect(function()
        closeButton.BackgroundColor3 = CONFIG.COLORS.BUTTON
        closeButton.TextColor3 = CONFIG.COLORS.TEXT
    end)
    
    -- Minimize button with improved styling
    local minimizeButton = createButton(headerFrame, "-", UDim2.new(0, 30, 0, 30), UDim2.new(1, -80, 0.5, -15), function()
        self:MinimizeConsole()
    end)
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.TextSize = CONFIG.TEXT_SIZE + 2
    
    -- Add hover color change for minimize button
    minimizeButton.MouseEnter:Connect(function()
        minimizeButton.BackgroundColor3 = CONFIG.COLORS.BUTTON_HOVER
    end)
    
    minimizeButton.MouseLeave:Connect(function()
        minimizeButton.BackgroundColor3 = CONFIG.COLORS.BUTTON
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
    
    -- Search bar
    local searchContainer, searchBox = createSearchBar(controlFrame, UDim2.new(0.5, -100, 0.5, -15), UDim2.new(0.4, 0, 0, 30))
    
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
    -- Create main toggle button container with improved styling
    toggleButton = Instance.new("Frame")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = CONFIG.TOGGLE_SIZE
    toggleButton.Position = UDim2.new(0.9, 0, 0.9, 0)
    toggleButton.BackgroundColor3 = CONFIG.COLORS.BACKGROUND
    toggleButton.Visible = false
    toggleButton.Parent = gui
    createCorner(toggleButton, UDim.new(0, 12)) -- More rounded corners
    
    -- Add enhanced shadow effect for better depth perception
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217" -- Soft shadow image
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = CONFIG.TOGGLE_SHADOW_TRANSPARENCY
    shadow.Size = UDim2.new(1, CONFIG.TOGGLE_SHADOW_SIZE * 2, 1, CONFIG.TOGGLE_SHADOW_SIZE * 2)
    shadow.Position = UDim2.new(0, -CONFIG.TOGGLE_SHADOW_SIZE, 0, -CONFIG.TOGGLE_SHADOW_SIZE)
    shadow.ZIndex = toggleButton.ZIndex - 1
    shadow.Parent = toggleButton
    
    -- Add subtle inner stroke with gradient for depth
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.COLORS.GRADIENT_START
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = toggleButton
    
    -- Gradient text with improved styling
    local toggleText, gradient = createGradientText(toggleButton, CONFIG.TOGGLE_TEXT)
    toggleText.TextSize = CONFIG.TEXT_SIZE + 2 -- Slightly larger text
    toggleText.Font = Enum.Font.GothamBold -- Bold font for better visibility
    
    -- Clickable button (transparent overlay)
    local button = Instance.new("TextButton")
    button.Name = "ClickHandler"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = toggleButton.ZIndex + 1
    button.Parent = toggleButton
    
    -- Visual feedback for touch/hover with improved animation
    local hoverEffect = Instance.new("Frame")
    hoverEffect.Name = "HoverEffect"
    hoverEffect.Size = UDim2.new(1, 0, 1, 0)
    hoverEffect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hoverEffect.BackgroundTransparency = 1 -- Start fully transparent
    hoverEffect.ZIndex = toggleButton.ZIndex
    hoverEffect.Parent = toggleButton
    createCorner(hoverEffect, UDim.new(0, 12))
    
    -- Animate gradient with smoother animation
    task.spawn(function()
        while toggleButton and toggleButton.Parent do
            for i = 0, 1, 0.005 do
                if not gradient or not gradient.Parent then break end
                gradient.Offset = Vector2.new(i, 0)
                task.wait(0.03)
            end
        end
    end)
    
    -- Create drag indicator with improved visual feedback
    local dragIndicator = Instance.new("Frame")
    dragIndicator.Name = "DragIndicator"
    dragIndicator.Size = UDim2.new(0.6, 0, 0, 0) -- Will be animated
    dragIndicator.Position = UDim2.new(0.2, 0, 0.5, 0)
    dragIndicator.AnchorPoint = Vector2.new(0, 0.5)
    dragIndicator.BackgroundColor3 = CONFIG.COLORS.DRAG_INDICATOR -- Use new color from CONFIG
    dragIndicator.BackgroundTransparency = 0.2
    dragIndicator.BorderSizePixel = 0
    dragIndicator.Visible = false
    dragIndicator.Parent = toggleButton
    createCorner(dragIndicator, UDim.new(1, 0)) -- Fully rounded
    
    -- Create hold progress indicator with improved styling
    local holdIndicator = Instance.new("Frame")
    holdIndicator.Name = "HoldIndicator"
    holdIndicator.Size = UDim2.new(0, 0, 0, 4) -- Slightly thicker
    holdIndicator.Position = UDim2.new(0, 0, 1, -4)
    holdIndicator.BackgroundColor3 = CONFIG.COLORS.GRADIENT_END
    holdIndicator.BorderSizePixel = 0
    holdIndicator.Visible = false
    holdIndicator.Parent = toggleButton
    createCorner(holdIndicator, UDim.new(0, 2)) -- Slightly rounded corners
    
    -- Add glow effect for active state
    local glowEffect = Instance.new("ImageLabel")
    glowEffect.Name = "GlowEffect"
    glowEffect.BackgroundTransparency = 1
    glowEffect.Image = "rbxassetid://1316045217" -- Same soft glow image
    glowEffect.ImageColor3 = CONFIG.COLORS.GLOW_EFFECT -- Use new color from CONFIG
    glowEffect.ImageTransparency = 1 -- Start invisible
    glowEffect.Size = UDim2.new(1, 20, 1, 20)
    glowEffect.Position = UDim2.new(0, -10, 0, -10)
    glowEffect.ZIndex = toggleButton.ZIndex - 1
    glowEffect.Parent = toggleButton
    
    -- Toggle functionality for PC
    button.MouseButton1Click:Connect(function()
        if not isDragging then -- Only toggle if not dragging
            self:MaximizeConsole()
        end
    end)
    
    -- Hover effect for PC with smoother animation
    button.MouseEnter:Connect(function()
        -- Animate hover effect with CONFIG animation time
        game:GetService("TweenService"):Create(
            hoverEffect,
            TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.8}
        ):Play()
    end)
    
    button.MouseLeave:Connect(function()
        -- Animate hover effect out with CONFIG animation time
        game:GetService("TweenService"):Create(
            hoverEffect,
            TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        ):Play()
    end)
    
    -- Enhanced mobile touch functionality with 0.5s hold time
    local HOLD_TIME = 0.5 -- Exactly 0.5 seconds as requested
    
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            holdStartTime = tick()
            dragStartPosition = input.Position
            dragStartOffset = toggleButton.Position
            isDragging = false -- Reset dragging state on new touch
            
            -- Show and animate hold indicator
            holdIndicator.Visible = true
            holdIndicator.Size = UDim2.new(0, 0, 0, 4)
            
            -- Animate hold indicator with smooth progress
            task.spawn(function()
                local startTime = tick()
                while holdStartTime and tick() - startTime < HOLD_TIME do
                    local progress = (tick() - startTime) / HOLD_TIME
                    -- Use TweenService instead of custom method
                    game:GetService("TweenService"):Create(
                        holdIndicator,
                        TweenInfo.new(0.03, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                        {Size = UDim2.new(progress, 0, 0, 4)}
                    ):Play()
                    task.wait(0.03)
                end
                
                -- If still holding after time elapsed, show drag indicator
                if holdStartTime and tick() - startTime >= HOLD_TIME then
                    holdIndicator.Visible = false
                    dragIndicator.Visible = true
                    isDragging = true -- Set dragging to true after hold time
                    
                    -- Animate drag indicator appearance
                    game:GetService("TweenService"):Create(
                        dragIndicator,
                        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                        {Size = UDim2.new(0.6, 0, 0, 6)}
                    ):Play()
                    
                    -- Pulse glow effect to indicate drag mode with CONFIG animation time
                    game:GetService("TweenService"):Create(
                        glowEffect,
                        TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {ImageTransparency = 0.7} -- Semi-transparent
                    ):Play()
                end
            end)
        end
    end)
    
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local holdDuration = tick() - (holdStartTime or 0)
            local wasHolding = holdStartTime ~= nil
            holdStartTime = nil
            
            -- Hide indicators
            holdIndicator.Visible = false
            dragIndicator.Visible = false
            
            -- Hide glow effect with CONFIG animation time
            game:GetService("TweenService"):Create(
                glowEffect,
                TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {ImageTransparency = 1} -- Fully transparent
            ):Play()
            
            if wasHolding and holdDuration < HOLD_TIME then
                -- Short tap, toggle console
                if not isDragging then
                    self:MaximizeConsole()
                end
            end
            
            -- Add enhanced animation when releasing drag
            if isDragging then
                -- Snap to grid effect with improved positioning
                local posX = toggleButton.Position.X.Scale
                local posY = toggleButton.Position.Y.Scale
                
                -- Snap to edges if close with better edge detection using CONFIG threshold
                local threshold = CONFIG.SNAP_TO_EDGE_THRESHOLD
                if posX < threshold then posX = 0.02 end
                if posX > (1 - threshold) then posX = 0.98 end
                if posY < threshold then posY = 0.02 end
                if posY > (1 - threshold) then posY = 0.98 end
                
                -- Animate to snapped position with smoother animation using CONFIG speed
                game:GetService("TweenService"):Create(
                    toggleButton,
                    TweenInfo.new(CONFIG.DRAG_ANIMATION_SPEED, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {Position = UDim2.new(posX, 0, posY, 0)}
                ):Play()
                
                -- Add subtle scale effect when releasing with CONFIG animation time
                local originalSize = toggleButton.Size
                local growTween = game:GetService("TweenService"):Create(
                    toggleButton,
                    TweenInfo.new(CONFIG.ANIMATION_TIME / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(originalSize.X.Scale * 1.1, originalSize.X.Offset, 
                                     originalSize.Y.Scale * 1.1, originalSize.Y.Offset)}
                )
                
                growTween.Completed:Connect(function()
                    game:GetService("TweenService"):Create(
                        toggleButton,
                        TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                        {Size = originalSize}
                    ):Play()
                end)
                
                growTween:Play()
            end
            
            isDragging = false
        end
    end)
    
    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and holdStartTime then
            local holdDuration = tick() - holdStartTime
            
            -- Check if we're already dragging or if we've held long enough
            if isDragging or holdDuration >= HOLD_TIME then
                -- Set dragging flag if not already set
                isDragging = true
                
                -- Add visual feedback for active dragging with CONFIG intensity
                if CONFIG.MOBILE_DRAG_FEEDBACK then
                    -- Use TweenService for smooth transition
                    game:GetService("TweenService"):Create(
                        hoverEffect,
                        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {BackgroundTransparency = 1 - CONFIG.TOUCH_FEEDBACK_INTENSITY}
                    ):Play()
                end
                
                -- Calculate delta and apply with smooth movement
                local delta = input.Position - dragStartPosition
                
                -- Get screen size for boundary checking
                local screenSize = gui.AbsoluteSize
                local buttonSize = toggleButton.AbsoluteSize
                
                -- Calculate new position with boundary limits
                local newXOffset = dragStartOffset.X.Offset + delta.X
                local newYOffset = dragStartOffset.Y.Offset + delta.Y
                
                -- Ensure button stays within screen bounds
                local maxX = screenSize.X - buttonSize.X
                local maxY = screenSize.Y - buttonSize.Y
                
                newXOffset = math.clamp(newXOffset, 0, maxX)
                newYOffset = math.clamp(newYOffset, 0, maxY)
                
                toggleButton.Position = UDim2.new(
                    dragStartOffset.X.Scale, newXOffset,
                    dragStartOffset.Y.Scale, newYOffset
                )
            end
        end
    end)
    
    return toggleButton
end

function BisamConsole:CreateFilterMenu()
    -- Create container for shadow effect
    local menuContainer = Instance.new("Frame")
    menuContainer.Name = "FilterMenuContainer"
    menuContainer.BackgroundTransparency = 1 -- Fully transparent background
    menuContainer.Size = UDim2.new(0, 240, 0, 295)  -- Larger to accommodate shadow
    menuContainer.Position = UDim2.new(0.5, -120, 0.5, -147)  -- Centered
    menuContainer.Visible = false
    menuContainer.Parent = gui
    
    -- Create shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1 -- Fully transparent background
    shadow.Image = "rbxassetid://1316045217" -- Soft shadow image
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.Position = UDim2.new(0, 0, 0, 0)
    shadow.ZIndex = 0
    shadow.Parent = menuContainer
    
    -- Create main filter menu frame
    filterMenu = Instance.new("Frame")
    filterMenu.Name = "FilterMenu"
    filterMenu.BackgroundColor3 = CONFIG.COLORS.BACKGROUND
    filterMenu.Size = UDim2.new(1, -20, 1, -20)  -- Adjust for shadow
    filterMenu.Position = UDim2.new(0, 10, 0, 10)  -- Center in container
    filterMenu.Parent = menuContainer
    createCorner(filterMenu, UDim.new(0, 10))  -- More rounded corners
    
    -- Add subtle inner stroke for depth
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.COLORS.GRADIENT_START
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = filterMenu
    
    -- Create a top border with gradient (similar to header)
    local topBorder = Instance.new("Frame")
    topBorder.Name = "TopBorder"
    topBorder.BackgroundColor3 = CONFIG.COLORS.GRADIENT_START
    topBorder.BorderSizePixel = 0
    topBorder.Size = UDim2.new(1, 0, 0, 2)
    topBorder.Position = UDim2.new(0, 0, 0, 0)
    topBorder.ZIndex = filterMenu.ZIndex + 1
    topBorder.Parent = filterMenu
    
    -- Add gradient to top border
    local borderGradient = Instance.new("UIGradient")
    borderGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.COLORS.GRADIENT_START),
        ColorSequenceKeypoint.new(1, CONFIG.COLORS.GRADIENT_END)
    })
    borderGradient.Parent = topBorder
    
    -- Animate border gradient
    task.spawn(function()
        while filterMenu and filterMenu.Parent do
            for i = 0, 1, 0.005 do
                if not borderGradient or not borderGradient.Parent then break end
                borderGradient.Offset = Vector2.new(i, 0)
                task.wait(0.03)
            end
        end
    end)
    
    -- Title with gradient
    local titleContainer = Instance.new("Frame")
    titleContainer.BackgroundTransparency = 1
    titleContainer.Size = UDim2.new(1, 0, 0, 40)
    titleContainer.Parent = filterMenu
    
    local title, titleGradient = createGradientText(titleContainer, "Filter Options")
    title.Font = Enum.Font.GothamBold
    title.TextSize = CONFIG.TEXT_SIZE + 2
    
    -- Options container with scrolling for mobile
    local optionsContainer = Instance.new("Frame")
    optionsContainer.BackgroundTransparency = 1
    optionsContainer.Size = UDim2.new(1, 0, 0, 185)  -- Increased height
    optionsContainer.Position = UDim2.new(0, 0, 0, 40)
    optionsContainer.Parent = filterMenu
    
    local optionsFrame = Instance.new("ScrollingFrame")
    optionsFrame.BackgroundTransparency = 1
    optionsFrame.Size = UDim2.new(1, 0, 1, 0)
    optionsFrame.CanvasSize = UDim2.new(0, 0, 0, 185)  -- Match container height initially
    optionsFrame.ScrollBarThickness = 4
    optionsFrame.ScrollBarImageColor3 = CONFIG.COLORS.GRADIENT_END
    optionsFrame.Parent = optionsContainer
    createPadding(optionsFrame)
    
    -- Add layout for options
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.Padding = UDim.new(0, 12)  -- More spacing between options
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Parent = optionsFrame
    
    -- Filter options with improved styling
    local function createEnhancedFilterOption(text, enabled, icon, color, callback)
        local option = Instance.new("Frame")
        option.BackgroundColor3 = Color3.fromRGB(45, 45, 55)  -- Slightly lighter than background
        option.Size = UDim2.new(1, 0, 0, 40)  -- Taller for better touch targets
        option.Parent = optionsFrame
        createCorner(option, UDim.new(0, 6))
        
        -- Indicator circle
        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(0, 20, 0, 20)
        circle.Position = UDim2.new(0, 10, 0.5, -10)
        circle.BackgroundColor3 = enabled and CONFIG.COLORS.FILTER_ENABLED or CONFIG.COLORS.FILTER_DISABLED
        circle.Parent = option
        createCorner(circle, UDim.new(1, 0))  -- Perfect circle
        
        -- Icon indicator (optional)
        if icon then
            local iconLabel = Instance.new("TextLabel")
            iconLabel.BackgroundTransparency = 1
            iconLabel.Size = UDim2.new(0, 20, 0, 20)
            iconLabel.Position = UDim2.new(0, 10, 0.5, -10)
            iconLabel.Font = Enum.Font.GothamBold
            iconLabel.TextSize = 14
            iconLabel.Text = icon
            iconLabel.TextColor3 = CONFIG.COLORS.BACKGROUND
            iconLabel.ZIndex = circle.ZIndex + 1
            iconLabel.Parent = option
        end
        
        -- Label
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 40, 0, 0)
        label.Font = CONFIG.FONT
        label.TextSize = CONFIG.TEXT_SIZE
        label.Text = text
        label.TextColor3 = CONFIG.COLORS.TEXT
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = option
        
        -- Color indicator
        if color then
            local colorIndicator = Instance.new("Frame")
            colorIndicator.Size = UDim2.new(0, 4, 0.6, 0)
            colorIndicator.Position = UDim2.new(1, -14, 0.2, 0)
            colorIndicator.BackgroundColor3 = color
            colorIndicator.BorderSizePixel = 0
            colorIndicator.Parent = option
            createCorner(colorIndicator, UDim.new(0, 2))
        end
        
        -- Button overlay
        local button = Instance.new("TextButton")
        button.BackgroundTransparency = 1
        button.Size = UDim2.new(1, 0, 1, 0)
        button.Text = ""
        button.Parent = option
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            option.BackgroundColor3 = Color3.fromRGB(55, 55, 65)  -- Lighter on hover
        end)
        
        button.MouseLeave:Connect(function()
            option.BackgroundColor3 = Color3.fromRGB(45, 45, 55)  -- Back to normal
        end)
        
        if callback then
            button.MouseButton1Click:Connect(function()
                local newState = not enabled
                enabled = newState
                circle.BackgroundColor3 = enabled and CONFIG.COLORS.FILTER_ENABLED or CONFIG.COLORS.FILTER_DISABLED
                callback(newState)
                
                -- Add click animation
                local clickEffect = Instance.new("Frame")
                clickEffect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                clickEffect.BackgroundTransparency = 0.8
                clickEffect.Size = UDim2.new(1, 0, 1, 0)
                clickEffect.Parent = option
                createCorner(clickEffect, UDim.new(0, 6))
                
                -- Fade out animation
                task.spawn(function()
                    for i = 0.8, 1, 0.1 do
                        if not clickEffect or not clickEffect.Parent then break end
                        clickEffect.BackgroundTransparency = i
                        task.wait(0.01)
                    end
                    if clickEffect and clickEffect.Parent then
                        clickEffect:Destroy()
                    end
                end)
            end)
        end
        
        return option, circle, enabled
    end
    
    -- Create filter options with icons and color indicators
    local errorOption = createEnhancedFilterOption("Error Messages", filters.error, "!", CONFIG.COLORS.ERROR, function(enabled)
        filters.error = enabled
        self:ApplyFilters()
    end)
    
    local outputOption = createEnhancedFilterOption("Output Messages", filters.output, "O", CONFIG.COLORS.TEXT, function(enabled)
        filters.output = enabled
        self:ApplyFilters()
    end)
    
    local warningOption = createEnhancedFilterOption("Warning Messages", filters.warning, "⚠", CONFIG.COLORS.WARNING, function(enabled)
        filters.warning = enabled
        self:ApplyFilters()
    end)
    
    local infoOption = createEnhancedFilterOption("Info Messages", filters.info, "i", CONFIG.COLORS.INFO, function(enabled)
        filters.info = enabled
        self:ApplyFilters()
    end)
    
    local timestampOption = createEnhancedFilterOption("Show Timestamps", filters.timestamp, "⏱", CONFIG.COLORS.TIMESTAMP, function(enabled)
        filters.timestamp = enabled
        self:ApplyFilters()
    end)
    
    -- Update canvas size based on content
    optionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        optionsFrame.CanvasSize = UDim2.new(0, 0, 0, optionsLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Buttons container
    local buttonFrame = Instance.new("Frame")
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Size = UDim2.new(1, 0, 0, 50)
    buttonFrame.Position = UDim2.new(0, 0, 1, -50)
    buttonFrame.Parent = filterMenu
    
    -- Close button with improved styling
    local closeButton = createButton(buttonFrame, "Close", UDim2.new(0, 120, 0, 36), UDim2.new(0.5, -60, 0.5, -18), function()
        -- Animate closing
        task.spawn(function()
            for i = 1, 0, -0.1 do
                if not menuContainer or not menuContainer.Parent then break end
                menuContainer.BackgroundTransparency = i
                task.wait(0.01)
            end
            menuContainer.Visible = false
            
            -- Also hide close detector
            local closeDetector = gui:FindFirstChild("CloseDetector")
            if closeDetector then
                closeDetector.Visible = false
            end
        end)
    end)
    closeButton.Font = Enum.Font.GothamSemibold
    
    -- Close when clicking outside
    local closeDetector = Instance.new("TextButton")
    closeDetector.Name = "CloseDetector"
    closeDetector.BackgroundTransparency = 1
    closeDetector.Size = UDim2.new(1, 0, 1, 0)
    closeDetector.Text = ""
    closeDetector.ZIndex = menuContainer.ZIndex - 1
    closeDetector.Parent = gui
    closeDetector.Visible = false
    
    closeDetector.MouseButton1Click:Connect(function()
        -- Animate closing
        task.spawn(function()
            for i = 1, 0, -0.1 do
                if not menuContainer or not menuContainer.Parent then break end
                menuContainer.BackgroundTransparency = i
                task.wait(0.01)
            end
            menuContainer.Visible = false
            closeDetector.Visible = false
        end)
    end)
    
    -- Store reference to container for animations
    filterMenu.Parent.Visible = false
    
    return menuContainer
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
        -- Always process messages since we removed the Pause button
        task.spawn(function()
            self:AddConsoleMessage(message, messageType)
        end)
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
    elseif messageType == Enum.MessageType.MessageInfo and not filters.info then
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
    elseif messageType == Enum.MessageType.MessageInfo then
        textColor = CONFIG.COLORS.INFO
        prefix = "INFO: "
    elseif messageType == Enum.MessageType.MessageOutput then
        textColor = CONFIG.COLORS.TEXT
        prefix = "OUTPUT: "
    end
    
    -- Create message text with syntax highlighting
    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -xOffset, 0, 0)
    textLabel.Position = UDim2.new(0, xOffset, 0, 0)
    textLabel.Font = CONFIG.FONT
    textLabel.TextSize = CONFIG.TEXT_SIZE
    textLabel.RichText = true  -- Enable rich text for syntax highlighting
    
    -- Apply syntax highlighting
    local highlightedMessage = message
    
    -- Highlight keywords, strings, numbers, and comments
    if messageType == Enum.MessageType.MessageOutput or 
       messageType == Enum.MessageType.MessageInfo then
        -- Highlight Lua keywords
        highlightedMessage = highlightedMessage:gsub(
            "(\\b)(and|break|do|else|elseif|end|false|for|function|if|in|local|nil|not|or|repeat|return|then|true|until|while)(\\b)", 
            "%1<font color='rgb(85,170,255)'>%2</font>%3"
        )
        
        -- Highlight strings
        highlightedMessage = highlightedMessage:gsub(
            "([\"\\'])(.-)%1", 
            "<font color='rgb(200,180,100)'>%1%2%1</font>"
        )
        
        -- Highlight numbers
        highlightedMessage = highlightedMessage:gsub(
            "(\\b)([0-9]+)(\\b)", 
            "%1<font color='rgb(170,120,255)'>%2</font>%3"
        )
        
        -- Highlight comments
        highlightedMessage = highlightedMessage:gsub(
            "(%-%-.-)", 
            "<font color='rgb(100,180,100)'>%1</font>"
        )
    end
    
    -- Set the text with prefix and highlighting
    textLabel.Text = prefix .. highlightedMessage
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
    -- Save current position for animation
    local startPos = mainFrame.Position
    local startSize = mainFrame.Size
    
    -- Animate minimizing
    local targetPos = UDim2.new(toggleButton.Position.X.Scale, toggleButton.Position.X.Offset, 
                               toggleButton.Position.Y.Scale, toggleButton.Position.Y.Offset)
    local targetSize = UDim2.new(0, 0, 0, 0)
    
    -- Store original transparency values
    local originalTransparencies = {}
    for _, child in pairs(mainFrame:GetDescendants()) do
        if child:IsA("GuiObject") and child.BackgroundTransparency < 1 then
            originalTransparencies[child] = child.BackgroundTransparency
            child.BackgroundTransparency = math.min(child.BackgroundTransparency + 0.2, 1)
        end
    end
    
    -- Animate
    task.spawn(function()
        local startTime = tick()
        local duration = CONFIG.ANIMATION_TIME
        
        while tick() - startTime < duration do
            local alpha = (tick() - startTime) / duration
            local easedAlpha = 1 - (1 - alpha) * (1 - alpha) -- Ease out quad
            
            -- Animate size and position
            mainFrame.Size = UDim2.new(
                startSize.X.Scale + (targetSize.X.Scale - startSize.X.Scale) * easedAlpha,
                startSize.X.Offset + (targetSize.X.Offset - startSize.X.Offset) * easedAlpha,
                startSize.Y.Scale + (targetSize.Y.Scale - startSize.Y.Scale) * easedAlpha,
                startSize.Y.Offset + (targetSize.Y.Offset - startSize.Y.Offset) * easedAlpha
            )
            
            mainFrame.Position = UDim2.new(
                startPos.X.Scale + (targetPos.X.Scale - startPos.X.Scale) * easedAlpha,
                startPos.X.Offset + (targetPos.X.Offset - startPos.X.Offset) * easedAlpha,
                startPos.Y.Scale + (targetPos.Y.Scale - startPos.Y.Scale) * easedAlpha,
                startPos.Y.Offset + (targetPos.Y.Offset - startPos.Y.Offset) * easedAlpha
            )
            
            task.wait()
        end
        
        -- Finish animation
        mainFrame.Visible = false
        mainFrame.Size = startSize
        mainFrame.Position = startPos
        
        -- Restore original transparency values
        for obj, transparency in pairs(originalTransparencies) do
            if obj and obj.Parent then
                obj.BackgroundTransparency = transparency
            end
        end
        
        -- Show toggle button with a fade-in effect
        toggleButton.BackgroundTransparency = 1
        toggleButton.Visible = true
        
        -- Fade in toggle button
        for i = 1, 0, -0.1 do
            if not toggleButton or not toggleButton.Parent then break end
            toggleButton.BackgroundTransparency = i
            task.wait(0.01)
        end
        toggleButton.BackgroundTransparency = 0
    end)
end

function BisamConsole:MaximizeConsole()
    -- Save toggle button position for animation
    local startPos = toggleButton.Position
    
    -- Prepare main frame for animation
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = startPos
    mainFrame.Visible = true
    
    -- Target size and position - fixed to use absolute values to avoid size bugs
    local targetSize = UDim2.new(0.6, 0, 0.6, 0) -- Fixed consistent size
    local targetPos = UDim2.new(0.2, 0, 0.2, 0) -- Fixed position
    
    -- Reset the frameContainer size to ensure consistent UI sizing
    if mainFrame and mainFrame.Parent then
        mainFrame.Parent.Size = targetSize
        mainFrame.Parent.Position = targetPos
    end
    
    -- Apply initial transparency
    local originalTransparencies = {}
    for _, child in pairs(mainFrame:GetDescendants()) do
        if child:IsA("GuiObject") and child.BackgroundTransparency < 1 then
            originalTransparencies[child] = child.BackgroundTransparency
            child.BackgroundTransparency = math.min(child.BackgroundTransparency + 0.5, 1)
        end
    end
    
    -- Hide toggle button with fade out
    task.spawn(function()
        for i = 0, 1, 0.2 do
            if not toggleButton or not toggleButton.Parent then break end
            toggleButton.BackgroundTransparency = i
            task.wait(0.01)
        end
        toggleButton.Visible = false
        toggleButton.BackgroundTransparency = 0
    end)
    
    -- Animate main frame
    task.spawn(function()
        local startTime = tick()
        local duration = CONFIG.ANIMATION_TIME
        
        while tick() - startTime < duration do
            local alpha = (tick() - startTime) / duration
            local easedAlpha = alpha * (2 - alpha) -- Ease out quad
            
            -- Animate size and position
            mainFrame.Size = UDim2.new(
                targetSize.X.Scale * easedAlpha,
                targetSize.X.Offset * easedAlpha,
                targetSize.Y.Scale * easedAlpha,
                targetSize.Y.Offset * easedAlpha
            )
            
            -- Adjust position to keep centered
            mainFrame.Position = UDim2.new(
                0.5, -(mainFrame.Size.X.Offset * 0.5),
                0.5, -(mainFrame.Size.Y.Offset * 0.5)
            )
            
            task.wait()
        end
        
        -- Finish animation
        mainFrame.Size = targetSize
        mainFrame.Position = targetPos
        
        -- Restore original transparency values with animation
        for obj, transparency in pairs(originalTransparencies) do
            if obj and obj.Parent then
                task.spawn(function()
                    for i = obj.BackgroundTransparency, transparency, -0.1 do
                        if not obj or not obj.Parent then break end
                        obj.BackgroundTransparency = math.max(i, transparency)
                        task.wait(0.01)
                    end
                    obj.BackgroundTransparency = transparency
                end)
            end
        end
    end)
end

function BisamConsole:ToggleFilterMenu()
    if filterMenu and filterMenu.Parent then
        local menuContainer = filterMenu.Parent
        local closeDetector = gui:FindFirstChild("CloseDetector")
        
        if not menuContainer.Visible then
            -- Show filter menu with animation
            menuContainer.Visible = true
            menuContainer.BackgroundTransparency = 1 -- Keep fully transparent
            
            -- Position menu relative to toggle button if it exists
            if toggleButton and toggleButton.Parent then
                local togglePos = toggleButton.AbsolutePosition
                local toggleSize = toggleButton.AbsoluteSize
                
                -- Calculate position to appear near toggle button
                local screenSize = gui.AbsoluteSize
                local menuSize = menuContainer.AbsoluteSize
                
                -- Position in the corner of the screen, away from the toggle button
                -- This ensures it's always visible and in a consistent location
                local xPos = screenSize.X - menuSize.X - 20 -- 20px from right edge
                local yPos = 20 -- 20px from top edge
                
                -- Make sure it's fully visible on screen
                xPos = math.clamp(xPos, 20, screenSize.X - menuSize.X - 20)
                yPos = math.clamp(yPos, 20, screenSize.Y - menuSize.Y - 20)
                
                menuContainer.Position = UDim2.new(0, xPos, 0, yPos)
            end
            
            -- Show close detector
            if closeDetector then
                closeDetector.Visible = true
            end
            
            -- Animate opening
            task.spawn(function()
                -- Scale animation
                menuContainer.Size = UDim2.new(0, menuContainer.AbsoluteSize.X * 0.9, 0, menuContainer.AbsoluteSize.Y * 0.9)
                
                -- Fade in animation for the filter menu, not the container
                local filterMenuFrame = menuContainer:FindFirstChild("FilterMenu")
                if filterMenuFrame then
                    -- Start with more transparency
                    filterMenuFrame.BackgroundTransparency = 0.5
                    
                    -- Animate to full opacity
                    for i = 5, 0, -1 do
                        if not filterMenuFrame or not filterMenuFrame.Parent then break end
                        filterMenuFrame.BackgroundTransparency = i/10
                        menuContainer.Size = UDim2.new(0, menuContainer.AbsoluteSize.X + (menuContainer.AbsoluteSize.X * 0.01), 
                                                     0, menuContainer.AbsoluteSize.Y + (menuContainer.AbsoluteSize.Y * 0.01))
                        task.wait(0.01)
                    end
                end
                
                -- Ensure final size
                menuContainer.Size = UDim2.new(0, 240, 0, 295)
            end)
        else
            -- Hide with animation
            task.spawn(function()
                -- Animate the filter menu frame, not the container
                local filterMenuFrame = menuContainer:FindFirstChild("FilterMenu")
                if filterMenuFrame then
                    -- Fade out animation for the filter menu
                    for i = 0, 10 do
                        if not filterMenuFrame or not filterMenuFrame.Parent then break end
                        filterMenuFrame.BackgroundTransparency = i/10
                        menuContainer.Size = UDim2.new(0, menuContainer.AbsoluteSize.X - (menuContainer.AbsoluteSize.X * 0.01), 
                                                     0, menuContainer.AbsoluteSize.Y - (menuContainer.AbsoluteSize.Y * 0.01))
                        task.wait(0.01)
                    end
                end
                
                menuContainer.Visible = false
                
                -- Hide close detector
                if closeDetector then
                    closeDetector.Visible = false
                end
            end)
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
                elseif messageType == tostring(Enum.MessageType.MessageInfo) then
                    content = content .. "INFO: "
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
                elseif messageType == tostring(Enum.MessageType.MessageInfo) and not filters.info then
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