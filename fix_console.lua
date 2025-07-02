-- Script to fix BisamConsole issues

-- First, find and destroy any existing BisamConsole ScreenGui
local function destroyExistingConsole()
    -- Check in CoreGui first
    local success, result = pcall(function()
        local coreGui = game:GetService("CoreGui")
        local existingGui = coreGui:FindFirstChild("BisamConsole")
        if existingGui then
            print("Found BisamConsole in CoreGui, destroying it...")
            existingGui:Destroy()
            return true
        end
        return false
    end)
    
    -- If not found in CoreGui or if CoreGui is not accessible, check PlayerGui
    if not success or not result then
        pcall(function()
            local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local existingGui = playerGui:FindFirstChild("BisamConsole")
                if existingGui then
                    print("Found BisamConsole in PlayerGui, destroying it...")
                    existingGui:Destroy()
                    return true
                end
            end
            return false
        end)
    end
    
    print("Searching for any remaining BisamConsole instances...")
    -- As a fallback, search all descendants of game
    for _, service in pairs(game:GetChildren()) do
        pcall(function()
            for _, obj in pairs(service:GetDescendants()) do
                if obj.Name == "BisamConsole" and obj:IsA("ScreenGui") then
                    print("Found BisamConsole in " .. service.Name .. ", destroying it...")
                    obj:Destroy()
                end
            end
        end)
    end
    
    print("BisamConsole cleanup completed")
end

-- Destroy existing console
destroyExistingConsole()

-- Now load the hello.lua script from GitHub
print("Loading BisamConsole...")
local BisamConsole = loadstring(game:HttpGet('https://raw.githubusercontent.com/DexCodeSX/lua/refs/heads/main/hello.lua'))()
BisamConsole:Initialize()

print("BisamConsole has been reloaded with fixes")