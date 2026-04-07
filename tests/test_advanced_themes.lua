-- tests/test_advanced_themes.lua
-- Suite de pruebas para el ThemeManager Avanzado (resolución var, fallbacks y hot-reload).

local ThemeManager = require("src.theme.ThemeManager")
local UIElement    = require("src.core.UIElement")

print("\n==========================================================")
print("===  REANUI: TEST ADVANCED THEMES (RESOLVE & CACHE)    ===")
print("==========================================================\n")

-- 1. Resolución Básica
print("[TEST 1] Resolución de variables estándar:")
ThemeManager.setTheme("dark")
local res1 = ThemeManager.resolve("var(--primary-color)")
print("  - var(--primary-color):  " .. (res1 == "#e94560" and "OK" or "FAIL ("..tostring(res1)..")"))

local res2 = ThemeManager.resolve("background: var(--bg-color)")
print("  - Mix String + var:      " .. (res2 == "background: #0d0d0d" and "OK" or "FAIL"))

-- 2. Fallbacks
print("\n[TEST 2] Fallbacks (Valor por defecto):")
local res3 = ThemeManager.resolve("var(--inexistente, #ffffff)")
print("  - var(--inexistente, #ffffff): " .. (res3 == "#ffffff" and "OK" or "FAIL"))

local res4 = ThemeManager.resolve("var(--inexistente)")
print("  - var(--inexistente) no fallback: " .. (res4 == "--inexistente" and "OK" or "FAIL"))

-- 3. Resolución Recursiva
print("\n[TEST 3] Resolución Recursiva:")
-- Inyectar manualmente para la prueba
ThemeManager._variables["--nivel1"] = "var(--nivel2)"
ThemeManager._variables["--nivel2"] = "#00ff00"
ThemeManager._clearCache()

local resRecursiva = ThemeManager.resolve("var(--nivel1)")
print("  - var(--nivel1) -> nivel2 -> color: " .. (resRecursiva == "#00ff00" and "OK" or "FAIL"))

-- 4. Hot-Reloading y Cambio de Tema
print("\n[TEST 4] Hot-Reloading y Cache Invalidation:")
ThemeManager.setTheme("light")
local resLight = ThemeManager.resolve("var(--primary-color)")
print("  - Cambio a Light:      " .. (resLight == "#3b82f6" and "OK" or "FAIL"))

-- 5. Integración con StyleManager
print("\n[TEST 5] Integración con StyleManager:")
local el = UIElement.new("div")
el:setStyle("color", "var(--text-color)")
print("  - StyleManager:get('color'): " .. (el:getStyle("color") == "#1f2937" and "OK" or "FAIL"))

print("\n==========================================================")
print("===  PRUEBAS DE DISEÑO COMPLETADAS                     ===")
print("==========================================================\n")
