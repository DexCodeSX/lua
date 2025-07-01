filterMenu.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            menuHoldStartTime = tick()
            menuDragStartPosition = input.Position
            
            -- Store absolute position for more reliable dragging
            menuDragStartOffset = UDim2.new(0, menuContainer.AbsolutePosition.X, 0, menuContainer.AbsolutePosition.Y)
            
            isDraggingMenu = false -- Reset dragging state on new touch
            
            -- Show and animate hold indicator
            menuHoldIndicator.Visible = true
            menuHoldIndicator.Size = UDim2.new(0, 0, 0, 4)
            
            -- Animate hold indicator with smooth progress
            task.spawn(function()
                local startTime = tick()
                while menuHoldStartTime and tick() - startTime < MENU_HOLD_TIME do
                    local progress = (tick() - startTime) / MENU_HOLD_TIME
                    game:GetService("TweenService"):Create(
                        menuHoldIndicator,
                        TweenInfo.new(0.03, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                        {Size = UDim2.new(progress, 0, 0, 4)}
                    ):Play()
                    task.wait(0.03)
                end
                
                -- If still holding after time elapsed, show drag indicator
                if menuHoldStartTime and tick() - startTime >= MENU_HOLD_TIME then
                    menuHoldIndicator.Visible = false
                    menuDragIndicator.Visible = true
                    isDraggingMenu = true -- Set dragging to true after hold time
                    
                    -- Animate drag indicator appearance
                    game:GetService("TweenService"):Create(
                        menuDragIndicator,
                        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                        {Size = UDim2.new(0.6, 0, 0, 6)}
                    ):Play()
                end
            end)
        end
    end)
    
    filterMenu.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local holdDuration = tick() - (menuHoldStartTime or 0)
            local wasHolding = menuHoldStartTime ~= nil
            menuHoldStartTime = nil
            
            -- Hide indicators
            menuHoldIndicator.Visible = false
            menuDragIndicator.Visible = false
            
            -- Only process menu dragging if we were actually dragging
            if isDraggingMenu then
                -- Get screen size for boundary checking
                local screenSize = gui.AbsoluteSize
                local menuSize = menuContainer.AbsoluteSize
                
                -- Calculate new position in absolute pixels
                local newXPos = math.clamp(menuContainer.Position.X.Offset, 20, screenSize.X - menuSize.X - 20)
                local newYPos = math.clamp(menuContainer.Position.Y.Offset, 20, screenSize.Y - menuSize.Y - 20)
                
                -- Animate to snapped position
                game:GetService("TweenService"):Create(
                    menuContainer,
                    TweenInfo.new(CONFIG.DRAG_ANIMATION_SPEED, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {Position = UDim2.new(0, newXPos, 0, newYPos)}
                ):Play()
                
                -- Add a small delay to prevent accidental clicks
                task.wait(0.1)
            end
            
            isDraggingMenu = false
        end
    end)
    
    filterMenu.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and menuHoldStartTime then
            local holdDuration = tick() - menuHoldStartTime
            
            -- Check if we're already dragging or if we've held long enough
            if isDraggingMenu or holdDuration >= MENU_HOLD_TIME then
                -- Set dragging flag if not already set
                isDraggingMenu = true
                
                -- Calculate delta and apply with smooth movement
                local delta = input.Position - menuDragStartPosition
                
                -- Get screen size for boundary checking
                local screenSize = gui.AbsoluteSize
                local menuSize = menuContainer.AbsoluteSize
                
                -- Calculate new position with boundary limits
                local newXOffset = menuDragStartOffset.X.Offset + delta.X
                local newYOffset = menuDragStartOffset.Y.Offset + delta.Y
                
                -- Ensure menu stays within screen bounds
                local maxX = screenSize.X - menuSize.X
                local maxY = screenSize.Y - menuSize.Y
                
                newXOffset = math.clamp(newXOffset, 0, maxX)
                newYOffset = math.clamp(newYOffset, 0, maxY)
                
                -- Use absolute positioning to prevent scale issues
                menuContainer.Position = UDim2.new(
                    0, newXOffset,
                    0, newYOffset
                )
                
                -- Update menuDragStartOffset to prevent position jumps
                menuDragStartOffset = UDim2.new(0, newXOffset, 0, newYOffset)
                menuDragStartPosition = input.Position
            end
        end
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
        -- Always process messages
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
            "(\b)(and|break|do|else|elseif|end|false|for|function|if|in|local|nil|not|or|repeat|return|then|true|until|while)(\b)", 
            "%1<font color='rgb(85,170,255)'>%2</font>%3"
        )
        
        -- Highlight strings
        highlightedMessage = highlightedMessage:gsub(
            "([\"\'])(.-)(\1)", 
            "<font color='rgb(200,180,100)'>%1%2%3</font>"
        )
        
        -- Highlight numbers
        highlightedMessage = highlightedMessage:gsub(
            "(\b)([0-9]+)(\b)", 
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

-- Fix for toggle UI when minimized
function BisamConsole:MinimizeConsole()
    -- Save current position and size as individual attributes
    -- This ensures the console returns to the same size after minimizing
    mainFrame:SetAttribute("TargetSizeXScale", mainFrame.Size.X.Scale)
    mainFrame:SetAttribute("TargetSizeXOffset", mainFrame.Size.X.Offset)
    mainFrame:SetAttribute("TargetSizeYScale", mainFrame.Size.Y.Scale)
    mainFrame:SetAttribute("TargetSizeYOffset", mainFrame.Size.Y.Offset)
    
    mainFrame:SetAttribute("TargetPosXScale", mainFrame.Position.X.Scale)
    mainFrame:SetAttribute("TargetPosXOffset", mainFrame.Position.X.Offset)
    mainFrame:SetAttribute("TargetPosYScale", mainFrame.Position.Y.Scale)
    mainFrame:SetAttribute("TargetPosYOffset", mainFrame.Position.Y.Offset)
    
    -- Save current position for animation
    local startPos = mainFrame.Position
    local startSize = mainFrame.Size
    
    -- Get toggle button position for target
    local targetPos = UDim2.new(0, toggleButton.Position.X.Scale * gui.AbsoluteSize.X, 
                               0, toggleButton.Position.Y.Scale * gui.AbsoluteSize.Y)
    local targetSize = UDim2.new(0, 0, 0, 0)
    
    -- Animate minimizing
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

-- Fix for toggle UI when maximized
function BisamConsole:MaximizeConsole()
    -- Get stored target size and position or use defaults
    local targetSizeXScale = mainFrame:GetAttribute("TargetSizeXScale") or 0.6
    local targetSizeXOffset = mainFrame:GetAttribute("TargetSizeXOffset") or 0
    local targetSizeYScale = mainFrame:GetAttribute("TargetSizeYScale") or 0.6
    local targetSizeYOffset = mainFrame:GetAttribute("TargetSizeYOffset") or 0
    
    local targetPosXScale = mainFrame:GetAttribute("TargetPosXScale") or 0.2
    local targetPosXOffset = mainFrame:GetAttribute("TargetPosXOffset") or 0
    local targetPosYScale = mainFrame:GetAttribute("TargetPosYScale") or 0.2
    local targetPosYOffset = mainFrame:GetAttribute("TargetPosYOffset") or 0
    
    local targetSize = UDim2.new(
        targetSizeXScale, targetSizeXOffset,
        targetSizeYScale, targetSizeYOffset
    )
    
    local targetPos = UDim2.new(
        targetPosXScale, targetPosXOffset,
        targetPosYScale, targetPosYOffset
    )
    
    -- Immediately set the parent frame to the target size and position before animation
    -- This ensures the UI will always be the correct size when maximized
    mainFrame.Size = UDim2.new(0, 0, 0, 0) -- Start small for animation
    mainFrame.Position = toggleButton.Position -- Start at toggle button position
    mainFrame.Visible = true
    
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
            
            -- Animate position from toggle button to target position
            mainFrame.Position = UDim2.new(
                toggleButton.Position.X.Scale + (targetPos.X.Scale - toggleButton.Position.X.Scale) * easedAlpha,
                toggleButton.Position.X.Offset + (targetPos.X.Offset - toggleButton.Position.X.Offset) * easedAlpha,
                toggleButton.Position.Y.Scale + (targetPos.Y.Scale - toggleButton.Position.Y.Scale) * easedAlpha,
                toggleButton.Position.Y.Offset + (targetPos.Y.Offset - toggleButton.Position.Y.Offset) * easedAlpha
            )
            
            task.wait()
        end
        
        -- Finish animation
        mainFrame.Size = targetSize
        mainFrame.Position = targetPos
    end)
end

-- Fix for filter menu toggle
function BisamConsole:ToggleFilterMenu()
    if not menuContainer then return end
    
    local closeDetector = gui:FindFirstChild("CloseDetector")
    
    if not menuContainer.Visible then
        -- Show filter menu with animation
        menuContainer.Visible = true
        
        -- Position menu in a consistent location
        local screenSize = gui.AbsoluteSize
        local menuSize = menuContainer.AbsoluteSize
        
        -- Position in the corner of the screen, away from the toggle button
        local xPos = screenSize.X - menuSize.X - 20 -- 20px from right edge
        local yPos = 20 -- 20px from top edge
        
        -- Make sure it's fully visible on screen
        xPos = math.clamp(xPos, 20, screenSize.X - menuSize.X - 20)
        yPos = math.clamp(yPos, 20, screenSize.Y - menuSize.Y - 20)
        
        menuContainer.Position = UDim2.new(0, xPos, 0, yPos)
        
        -- Show close detector
        if closeDetector then
            closeDetector.Visible = true
        end
        
        -- Animate opening
        local filterMenuFrame = menuContainer:FindFirstChild("FilterMenu")
        if filterMenuFrame then
            -- Start with more transparency
            filterMenuFrame.BackgroundTransparency = 0.5
            
            -- Animate to full opacity
            game:GetService("TweenService"):Create(
                filterMenuFrame,
                TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 0}
            ):Play()
        end
    else
        -- Hide with animation
        local filterMenuFrame = menuContainer:FindFirstChild("FilterMenu")
        if filterMenuFrame then
            -- Animate to transparent
            local tween = game:GetService("TweenService"):Create(
                filterMenuFrame,
                TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            )
            
            tween.Completed:Connect(function()
                menuContainer.Visible = false
                
                -- Hide close detector
                if closeDetector then
                    closeDetector.Visible = false
                end
            end)
            
            tween:Play()
        else
            menuContainer.Visible = false
            
            -- Hide close detector
            if closeDetector then
                closeDetector.Visible = false
            end
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