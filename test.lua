-- test.lua
local ui = require("reanui")

print("\n--- 1. Testing Element Creation ---")
local view = ui.createView()
print("Success! Created userdata:", view)

print("\n--- 2. Testing OOP Methods (camelCase) ---")
local ok1 = view:setStyle("width", "350px")
local ok2 = view:setStyle("backgroundColor", "#1a1a1a")
print("setStyle('width') response:", ok1)
print("setStyle('backgroundColor') response:", ok2)

print("\n--- 3. Testing Strict C-Validation (Memory & Types) ---")
local status, err = pcall(function()
    -- Attempting to pass a number instead of a string to provoke C parameter strict checks
    view:setStyle("padding", 50) 
end)
print("Result of passing an invalid type -> Status:", status)
print("Lua C-API Error Message Caught:", err)

print("\n--- Process Finished (Garbage Collector will clean memory in C automatically) ---\n")
