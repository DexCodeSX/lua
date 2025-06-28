# Bisam Console (BETA)

A modern, professional console GUI for Roblox with improved functionality and mobile support. Modified for Roblox exploits and loadstring compatibility.

## Features

### Modern UI Design
- Professional, clean appearance with gradient text effects
- Mobile-responsive layout
- Single ScreenGui implementation (no destruction/recreation)

### Header Elements
- Title: "Bisam Console (BETA)" with gradient text effect
- Control Buttons: Close and Minimize buttons

### Button Functions

#### Close Button
- Destroys the entire UI when clicked

#### Minimize Button
- Converts UI to small toggle button with gradient text "BC"
- **Mobile Interaction**:
  - Hold for 0.5 seconds to enable drag mode
  - Release hold to stop dragging
  - Tap toggle button to reopen full UI

#### Main Control Buttons
- **Copy**: Copies all console content (or search results if search is active)
- **Clear**: Clears all console content
- **Pause/Start**: Toggles console logging (button text changes between "Pause" and "Start")
- **Search Bar**: Search through console messages
- **Filter Menu**: Opens popup with filtering options

### Filter Menu (Popup)
- **Visual Indicators**:
  - Green circle = enabled filter
  - Red circle = disabled filter
- **Filter Options**:
  - Error messages
  - Output messages
  - Warning messages
  - Timestamp display
- **Controls**: "Save" and "Close" buttons
- **Mobile**: Tap outside popup to close

### Console Functionality
- **Message Types & Colors**:
  - Timestamp: Gray text
  - Error: Red text with "ERROR:" prefix
  - Output: White text with "OUTPUT:" prefix
  - Warning: Yellow text with "WARN:" prefix
- **Technical Features**:
  - ScrollingFrame with infinite scrolling for console output
  - Threading using `task.spawn` for console operations
  - Support for `\n` newlines similar to F9 developer console
  - Smooth scrolling with animated scroll bar

## Installation

### For Roblox Exploits

**Method 1: Using GitHub loadstring**
```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/DexCodeSX/lua/refs/heads/main/hello.lua'))():Initialize()
```

**Method 2: Using local file**
```lua
-- If you have the file saved locally
local BisamConsole = loadstring(readfile("hello.lua"))()
BisamConsole:Initialize()
```

### For Roblox Studio/Games

1. Add the `hello.lua` script to your Roblox game as a ModuleScript
2. Require the module in your script
3. Initialize the console

```lua
-- Load the Bisam Console module
local BisamConsole = require(path.to.BisamConsole)

-- Initialize the console
BisamConsole:Initialize()
```

## Usage Example

See `example.lua` for a complete usage example.

### For Roblox Exploits

```lua
-- Load the Bisam Console module using loadstring
loadstring(game:HttpGet('https://raw.githubusercontent.com/DexCodeSX/lua/refs/heads/main/hello.lua'))():Initialize()

-- Regular output message
print("This is a regular output message")

-- Warning message
warn("This is a warning message")

-- Error message (using pcall to generate an error)
pcall(function()
    error("This is an error message")
end)
```

### For Roblox Studio/Games

```lua
-- Load the Bisam Console module
local BisamConsole = require(path.to.BisamConsole)

-- Initialize the console
BisamConsole:Initialize()

-- Regular output message
print("This is a regular output message")
```

## API Reference

### BisamConsole:Initialize()
Initializes and displays the console GUI.

### BisamConsole:MinimizeConsole()
Minimizes the console to a small toggle button.

### BisamConsole:MaximizeConsole()
Maximizes the console from the toggle button to full view.

### BisamConsole:ClearConsole()
Clears all messages from the console.

### BisamConsole:CopyConsoleContent()
Copies all visible console content to the clipboard.

### BisamConsole:ToggleFilterMenu()
Toggles the visibility of the filter menu.

### BisamConsole:ApplyFilters()
Applies the current filter settings to the console messages.

### BisamConsole:FilterConsoleBySearch(searchText)
Filters console messages based on the provided search text.

## Mobile Support

The Bisam Console is fully optimized for mobile devices:
- Responsive layout adapts to different screen sizes
- Special touch interactions for the minimize button
- Easy-to-use filter menu with touch-friendly controls

## Exploit-Specific Features

- Compatible with Roblox exploits using loadstring
- Fallback mechanisms for different exploit capabilities
- Clipboard support with setclipboard or writefile fallback
- CoreGui integration with PlayerGui fallback

## Code Quality

- Clean, well-commented Lua code
- Optimized performance with threading
- Professional coding standards
- Mobile compatibility throughout