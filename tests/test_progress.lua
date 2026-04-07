-- tests/test_progress.lua
-- Suite de pruebas para el componente ProgressBar.

local ReanUI = require("src.ReanUI")

print("\n==========================================================")
print("===  REANUI: TEST COMPONENTE PROGRESSBAR               ===")
print("==========================================================\n")

-- 1. Creación declarativa
print("[TEST 1] Inicialización y Clamping:")
local pb = ReanUI.create("progress", { id = "lvl-exp" }, 25)
print("  - Valor inicial (25%): ", (pb:getProgress() == 25 and "OK" or "FAIL"))

pb:setProgress(150)
print("  - Clamping Max (100%): ", (pb:getProgress() == 100 and "OK" or "FAIL"))

pb:setProgress(-10)
print("  - Clamping Min (0%):   ", (pb:getProgress() == 0 and "OK" or "FAIL"))

-- 2. Verificación de Sub-nodos (Fill style)
print("\n[TEST 2] Actualización de Nodo Fill:")
pb:setProgress(75)
local fill = pb:getChildren()[1]
local fillWidth = fill:getStyle("width")
print("  - Nodo hijo existe:    ", (fill ~= nil and "OK" or "FAIL"))
print("  - Ancho de estilo (75%):", (fillWidth == "75%" and "OK" or "FAIL"))

-- 3. Eventos
print("\n[TEST 3] Verificación de Eventos (onChange):")
local lastValue = nil
pb:addEventListener("change", function(data)
    lastValue = data.value
    print("    >> Evento change detectado: " .. data.value .. "%")
end)

pb:setProgress(90)
print("  - Resultados:          ", (lastValue == 90 and "OK" or "FAIL"))

-- 4. Visual Debug (Hierarchy check)
print("\n[TEST 4] Jerarquía Visual (Debug):")
pb:debugPrint()

print("\n==========================================================")
print("===  PRUEBAS DE PROGRESSBAR COMPLETADAS                ===")
print("==========================================================\n")
