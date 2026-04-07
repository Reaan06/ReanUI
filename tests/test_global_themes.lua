-- tests/test_global_themes.lua
-- Suite de pruebas para el ThemeManager y la consistencia visual global.

local ReanUI = require("src.ReanUI")

print("\n==========================================================")
print("===  REANUI: TEST THEMEMANAGER & GLOBAL STYLES         ===")
print("==========================================================\n")

-- 1. Estado Inicial (Dark por defecto)
ReanUI.setTheme("dark")
local btn = ReanUI.create("button", {}, "Botón Dark")
local bg_dark = btn:getStyle("--rean-bg")
local accent_dark = btn:getStyle("--rean-accent")

print("[TEST 1] Tema Dark Inicial:")
print("  - Botón creado con éxito.")
print("  - Variable --rean-bg:     " .. (bg_dark == "#0d0d0d" and "OK" or "FAIL ("..tostring(bg_dark)..")"))
print("  - Variable --rean-accent: " .. (accent_dark == "#e94560" and "OK" or "FAIL"))

-- 2. Cambio a Light
print("\n[TEST 2] Cambio Global a Tema Light:")
ReanUI.setTheme("light")
local input = ReanUI.create("input", { placeholder = "Escribe aquí..." })
local bg_light = input:getStyle("--rean-bg")
local accent_light = input:getStyle("--rean-accent")

print("  - Input creado tras cambio de tema.")
print("  - Variable --rean-bg:     " .. (bg_light == "#f5f5f5" and "OK" or "FAIL ("..tostring(bg_light)..")"))
print("  - Variable --rean-accent: " .. (accent_light == "#3b82f6" and "OK" or "FAIL"))

-- 3. Verificación de Otros Componentes
print("\n[TEST 3] Consistencia en Checkbox y ProgressBar (Light):")
local cb = ReanUI.create("checkbox", {}, true)
local pb = ReanUI.create("progress", {}, 50)

print("  - Checkbox Borde (Light):  " .. (cb:getStyle("--rean-border") == "#d1d5db" and "OK" or "FAIL"))
print("  - Progress Fill (Light):   " .. (pb:getChildren()[1]:getStyle("--rean-accent") == "#3b82f6" and "OK" or "FAIL"))

-- 4. Debug Print
print("\n[TEST 4] Representación Visual del Tema Actual:")
ReanUI.setTheme("dark") -- Volver a dark para la inspección final
local finalBtn = ReanUI.create("button", {}, "Final")
finalBtn:debugPrint()

print("\n==========================================================")
print("===  PRUEBAS DE TEMAS COMPLETADAS                      ===")
print("==========================================================\n")
