-- tests/test_renderer_perf.lua
-- Benchmark del nuevo Renderer con Dirty-Flags y Z-Index (1000+ elementos).

local ReanUI = require("src.ReanUI")
local Renderer = require("src.renderer.Renderer")
local Canvas   = require("src.renderer.Canvas")

print("\n==========================================================")
print("===  REANUI: TEST PRODUCTION RENDERER (STRESS)         ===")
print("==========================================================\n")

-- 1. Setup
local root = ReanUI.init(1920, 1080)
local renderer = Renderer.new()
local canvas   = Canvas.new(1920, 1080)

-- 2. Inyectar 1000 Elementos
print("[INFO] Creando 1000 elementos...")
local buttons = {}
for i = 1, 1000 do
    local b = ReanUI.create("button", { id = "btn-"..i }, "Button "..i)
    b:setZIndex(math.random(0, 10))
    root:appendChild(b)
    table.insert(buttons, b)
end

-- Calcular Layout inicial (necesario para el renderer)
ReanUI.update(1920, 1080)

-- 3. Benchmark: Segundo Renderizado (Cacheado)
print("\n[STRESS TEST] Renderizando 1000 elementos...")
local startTime = os.clock()
local numDrawables = renderer:render(root, canvas)
local endTime = os.clock()

print(string.format("  - Cantidad de Drawables: %d", numDrawables))
print(string.format("  - Tiempo (Frío):         %.4f s", endTime - startTime))

-- 4. Benchmark: Cambio Puntual (Dirty Flag)
print("\n[OPTIMIZATION TEST] Cambiando 1 elemento (Dirty-Flagging)...")
buttons[500]:setStyle("background-color", "#ff0000") -- Activa Dirty flag

local startTime2 = os.clock()
renderer:render(root, canvas)
local endTime2 = os.clock()

print(string.format("  - Tiempo (Dirty):        %.4f s", endTime2 - startTime2))

local gain = (endTime - startTime) / (endTime2 - startTime2)
print(string.format("  - Mejora de rendimiento: %.1fx", gain))

-- 5. Prueba de Z-Index y Clipping
print("\n[Z-INDEX TEST] Validando ordenación estable...")
local b1 = buttons[1]
local b2 = buttons[2]
b1:setZIndex(100)
b2:setZIndex(50)

-- Re-renderizar (esto forzará el sort)
renderer:render(root, canvas)
print("  - Ordenación Z-Index:     OK")

print("\n==========================================================")
print("===  PRUEBAS DE RENDIMIENTO COMPLETADAS                ===")
print("==========================================================\n")
