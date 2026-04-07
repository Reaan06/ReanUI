-- test_layout.lua (Lua-only)
local Container = require("src.components.Container")
local Button = require("src.components.Button")
local FlexboxLayout = require("src.layout.FlexboxLayout")

print("\n=== TEST LAYOUT (LUA) ===")

local root = Container.new("column", { id = "root" })
local header = Container.new("row", { id = "header" })
local body = Container.new("column", { id = "body" })
local button = Button.new("CTA")

root:setStyleSheet("width: 1920px; height: 1080px;")
header:setStyleSheet("width: 100%; height: 80px;")
body:setStyleSheet("width: 50%; height: 500px;")
button:setStyleSheet("width: 80%; height: 60px;")

root:appendChild(header)
root:appendChild(body)
body:appendChild(button)

print("\n[!] Probando bloqueo de ciclo:")
local status, err = pcall(function()
    body:appendChild(root)
end)
print("Safety Status:", status, "Error capturado:", err)

print("\n[>>] Calculando layout 1920x1080...\n")
FlexboxLayout.calculateLayout(root, 1920, 1080, 0, 0)

print("--- DOM CANVAS (Render List Final) ---")
root:debugPrint()
header:debugPrint()
body:debugPrint()
button:debugPrint()

print("\n=== SUCCESS ===")
