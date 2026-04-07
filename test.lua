-- test.lua (Lua-only)
local ReanUI = require("src.ReanUI")

_G.getScreenSize = function() return 1280, 720 end
_G.addEventHandler = function() end

print("\n--- 1. Testing Element Creation ---")
local root = ReanUI.init(800, 600)
local view = ReanUI.create("div", { id = "root" })
root:appendChild(view)
print("Success! Created element uid:", view:getUid())

print("\n--- 2. Testing Style API ---")
view:setStyle("width", "350px")
view:setStyle("background-color", "#1a1a1a")
print("width:", view:getStyle("width"))
print("background-color:", view:getStyle("background-color"))

print("\n--- 3. Testing Validation Guards ---")
local status, err = pcall(function()
    view:setStyle(123, "50px")
end)
print("Result passing invalid prop type -> Status:", status)
print("Error:", err)

print("\n--- Process Finished (Lua-only runtime) ---\n")
