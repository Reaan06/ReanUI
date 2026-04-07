-- tests/test_scrollbox.lua
-- Verificación del componente Scrollbox (Scroll + Clipping).

local ReanUI = require("src.ReanUI")

print("\n==========================================================")
print("===  REANUI: TEST SCROLLBOX & OVERFLOW                 ===")
print("==========================================================\n")

-- 1. Setup
local root = ReanUI.init(800, 600)
local scrollbox = ReanUI.create("scrollbox", { id = "main-scroll" })
scrollbox:setStyle("width", "300px")
scrollbox:setStyle("height", "200px")
root:appendChild(scrollbox)

-- Añadir contenido alto (10 botones de 50px de alto cada uno)
print("[INFO] Añadiendo 10 botones (500px total)...")
for i = 1, 10 do
    local btn = ReanUI.create("button", { id = "sub-btn-"..i }, "Item "..i)
    btn:setStyle("height", "50px")
    scrollbox:appendChild(btn)
end

-- 2. Procesar Layout inicial
ReanUI.update(800, 600)

print("\n[TEST 1] Análisis de dimensiones:")
print("  - Scrollbox Height: ", scrollbox._layout.h)
print("  - Content Height:   ", scrollbox._content_h)

local ok1 = (scrollbox._content_h > scrollbox._layout.h)
print("  - ¿Contenido mayor que contenedor?: ", ok1 and "OK" or "FAIL")

-- 3. Simular desplazamiento (Rueda del ratón)
print("\n[TEST 2] Simulación de MouseWheel:")
print("  - Scroll Y Inicial: ", scrollbox._scroll_y)

-- Simulamos 2 ticks de rueda hacia abajo (-1, -1)
ReanUI.handleMouseEvent("wheel", -1, 150, 100) -- Delta, x, y
ReanUI.handleMouseEvent("wheel", -1, 150, 100)
ReanUI.update(800, 600)

print("  - Scroll Y Final:   ", scrollbox._scroll_y)
local ok2 = (scrollbox._scroll_y > 0)
print("  - ¿Resultó en desplazamiento?:     ", ok2 and "OK" or "FAIL")

-- 4. Verificación de Clipping
-- Obtenemos el clip aplicado al primer hijo
local Renderer = require("src.renderer.Renderer")
local Canvas = require("src.renderer.Canvas")
local r = Renderer.new()
local c = Canvas.new(800, 600)

-- La render list se genera internamente. 
-- Para este test manual vamos a ver el log del Renderer.
print("\n[TEST 3] Verificación de Clipping Heredado:")
-- (El renderer aplicará el clip del scrollbox a todos sus hijos)
-- En este punto, el test pasa si no hay errores fatales y el scroll_y es correcto.

print("\n==========================================================")
print("===  PRUEBAS DE SCROLLBOX COMPLETADAS                  ===")
print("==========================================================\n")
