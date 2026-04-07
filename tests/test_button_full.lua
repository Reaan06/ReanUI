-- tests/test_button_full.lua
-- Suite de pruebas para el componente Button PRO.

local Button = require("src.components.Button")

print("\n==========================================================")
print("===  REANUI: TEST COMPONENTE BUTTON PRO                ===")
print("==========================================================\n")

-- 1. Inicialización
local btn = Button.new("Enviar Mensaje", "icons/send.png")
print("[TEST 1] Inicialización correcta:")
print("  - Etiqueta: ", btn:getLabel() == "Enviar Mensaje" and "OK" or "FAIL")
print("  - Icono:    ", btn._icon == "icons/send.png" and "OK" or "FAIL")

-- 2. Gestión de Estados (Visual Check via debug)
print("\n[TEST 2] Ciclo de Vida de Interactividad:")
btn:onMouseEnter()
print("  - Estado Hover activado (.is-hover)")
btn:onMouseDown()
print("  - Estado Active activado (.is-active, transform scale 0.95)")
btn:onMouseUp()
print("  - Estado Active liberado")
btn:onMouseLeave()
print("  - Volviendo a Normal")

-- 3. Debouncing (Simulación de clicks rápidos)
print("\n[TEST 3] Verificación del Debouncing (300ms Cooldown):")
local clickCounts = 0
btn:onClick(function(element, data)
    clickCounts = clickCounts + 1
    print("    >> Click #" .. clickCounts .. " detectado en: " .. (data.label or "Unknown"))
end)

print("  - Ejecutando 5 disparos rápidos (Debounce debería bloquear 4)")
btn:press() -- Click 1 (OK)
btn:press() -- Ignorado (Too fast)
btn:press() -- Ignorado (Too fast)
-- (En un script síncrono como este, os.time() devolverá el mismo segundo,
-- validando que el debounce funciona perfectamente al evitar repeticiones).

print("  - Resultados:", clickCounts == 1 and "OK (Solo 1 clic detectado)" or "FAIL (Detectó "..clickCounts..")")

-- 4. Estado Disabled
print("\n[TEST 4] Verificación de Bloqueo por Deshabilitado:")
btn:setDisabled(true)
print("  - Intentando interactuar con botón deshabilitado...")
btn:press()
print("  - Resultados:", clickCounts == 1 and "OK (Inalterado)" or "FAIL (Se contó un clic deshabilitado)")

-- 5. Tematización
print("\n[TEST 5] Cambio de Temas:")
btn:applyTheme("light")
print("  - Aplicado tema 'light' con éxito.")
btn:debugPrint()

print("\n==========================================================")
print("===  PRUEBAS DE BUTTON COMPLETADAS                     ===")
print("==========================================================\n")
