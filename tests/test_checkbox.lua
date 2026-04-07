-- tests/test_checkbox.lua
-- Suite de pruebas para el componente Checkbox.

local ReanUI = require("src.ReanUI")

print("\n==========================================================")
print("===  REANUI: TEST COMPONENTE CHECKBOX                  ===")
print("==========================================================\n")

-- 1. Creación declarativa
print("[TEST 1] Creación mediante ReanUI.create:")
local cb = ReanUI.create("checkbox", { id = "check-remember" }, false)
print("  - Tipo correcto: ", (cb:getTag() == "checkbox" and "OK" or "FAIL"))
print("  - ID correcto:   ", (cb:getId() == "check-remember" and "OK" or "FAIL"))
print("  - Estado inicial:", (not cb:isChecked() and "OK" or "FAIL"))

-- 2. Cambio de estado manual
print("\n[TEST 2] Ciclo de cambios (Toggle / SetChecked):")
cb:toggle()
print("  - Toggle (True):  ", (cb:isChecked() and "OK" or "FAIL"))
print("  - Clase inyectada:", (cb:hasClass("is-checked") and "OK" or "FAIL"))

cb:setChecked(false)
print("  - SetChecked(F): ", (not cb:isChecked() and "OK" or "FAIL"))
print("  - Clase removida: ", (not cb:hasClass("is-checked") and "OK" or "FAIL"))

-- 3. Eventos
print("\n[TEST 3] Verificación de Eventos (onChange):")
local lastVal = nil
cb:onChange(function(element, checked)
    lastVal = checked
    print("    >> Evento onChange disparado: " .. tostring(checked))
end)

cb:press() -- Simular clic (toggle)
print("  - Resultados:    ", (lastVal == true and "OK" or "FAIL"))

-- 4. Visual Debug
print("\n[TEST 4] Representación Visual (Debug):")
cb:debugPrint()

print("\n==========================================================")
print("===  PRUEBAS DE CHECKBOX COMPLETADAS                   ===")
print("==========================================================\n")
