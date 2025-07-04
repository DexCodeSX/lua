--[[  
    Bisam Console Example
    This script demonstrates how to use the Bisam Console in a Roblox exploit environment.
    
    Recent improvements:
    - Added nil checks to prevent "attempt to index nil with 'Text'" errors
    - Enhanced error handling for better stability in exploit environments
    - Added Info message type with blue text and "INFO:" prefix
    - Removed Pause button and Save popup for better UX
    - Added syntax highlighting for code in messages
    - Improved modern UI design
]]--

-- Method 1: Using loadstring directly from GitHub
-- loadstring(game:HttpGet('https://raw.githubusercontent.com/DexCodeSX/lua/refs/heads/main/hello.lua'))():Initialize()

-- Method 2: If you have the file locally
-- Load the Bisam Console module
local BisamConsole = loadstring(readfile("hello.lua"))()

-- Initialize the console
BisamConsole:Initialize()

-- Example usage
local function testConsole()
    -- Regular output message
    print("This is a regular output message")
    
    -- Warning message
    warn("This is a warning message")
    
    -- Error message (using pcall to generate an error)
    pcall(function()
        error("This is an error message")
    end)
    
    -- Info message (new message type)
    if printidentity then -- Check if we're in an exploit environment
        -- Use LogService directly for Info messages
        game:GetService("LogService"):PublishAsync(Enum.MessageType.MessageInfo, "This is an info message")
    else
        -- Alternative method for environments without PublishAsync
        local message = Instance.new("Message")
        message.Text = "This is an info message"
        message.Parent = workspace
        task.wait(0.1)
        message:Destroy()
    end
    
    -- Code example with syntax highlighting
    print("function exampleCode()\n    local x = 10 -- This is a comment\n    if x > 5 then\n        return true\n    else\n        return false\n    end\nend")
    
    -- Multi-line message
    print("This is a multi-line message\nLine 2 of the message\nLine 3 of the message")
    
    -- Wait and send more messages
    task.wait(2)
    print("The console supports filtering and searching")
    warn("You can minimize the console to a small button")
    print("Try the different features of the console!")
end

-- Run the test
testConsole()

-- You can also add custom messages programmatically
local LogService = game:GetService("LogService")
LogService:Listen()

-- Example of sending messages at intervals
for i = 1, 5 do
    task.spawn(function()
        task.wait(i * 1.5)
        print("Programmatic message #" .. i)
    end)
end