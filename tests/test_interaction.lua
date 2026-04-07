-- tests/test_interaction.lua
-- Suite de pruebas para el InteractionManager (Hit-Testing y Eventos).

local ReanUI = require("src.ReanUI")

print("\n==========================================================")
print("===  REANUI: TEST INTERACTION MANAGER                  ===")
print("==========================================================\n")

-- 1. Setup de Interfaz
local root = ReanUI.init(800, 600)
local container = ReanUI.create("div", { id = "main-container", style = "padding: 50px; gap: 20px; height: 100%;" }, {
    ReanUI.create("button", { id = "btn-test" }, "Click Me"),
    ReanUI.create("input", { id = "input-test", placeholder = "Focus me" })
})
root:appendChild(container)

-- 2. Calcular Layout (Vital para hit-testing)
ReanUI.update()

local btn = container:getChildren()[1]
local input = container:getChildren()[2]

print("[DEBUG] Botón Height Style:", btn:getStyle("height"))
print("[DEBUG] Input Height Style: ", input:getStyle("height"))

local btn_l = btn._layout
print(string.format("[INFO] Botón calculado en: x=%d, y=%d, w=%d, h=%d", btn_l.x, btn_l.y, btn_l.w, btn_l.h))

-- 3. Prueba de HOVER
print("[TEST 1] Simulación de Hover (Mouse Move):")
-- Mover mouse sobre el botón (ubicación: center of button)
local mx, my = btn_l.x + btn_l.w/2, btn_l.y + btn_l.h/2
ReanUI.handleMouseEvent("move", mx, my)

print("  - Botón tiene clase 'is-hover': ", (btn:hasClass("is-hover") and "OK" or "FAIL"))
-- Comprobar si el color resultante es el del tema (ya resuelto)
local accentHover = ReanUI.getThemeVariable("--rean-accent-hover")
print("  - Botón color (accent-hover):  ", (btn:getStyle("background-color") == accentHover and "OK" or "FAIL"))

-- 4. Prueba de CLICK
print("\n[TEST 2] Simulación de Click (Down + Up):")
local clickCount = 0
btn:onClick(function()
    clickCount = clickCount + 1
    print("    >> Listener de Click disparado!")
end)

ReanUI.handleMouseEvent("button", "left", "down", mx, my)
print("  - Botón tiene clase 'is-active':", (btn:hasClass("is-active") and "OK" or "FAIL"))

ReanUI.handleMouseEvent("button", "left", "up", mx, my)
print("  - Click detectado:              ", (clickCount == 1 and "OK" or "FAIL"))

-- 5. Prueba de FOCO
print("\n[TEST 3] Gestión de Foco (Click en Input):")
local in_l = input._layout
local ix, iy = in_l.x + 10, in_l.y + 10

ReanUI.handleMouseEvent("button", "left", "down", ix, iy)
ReanUI.handleMouseEvent("button", "left", "up", ix, iy)

print("  - Input tiene clase 'is-focused':", (input:hasClass("is-focused") and "OK" or "FAIL"))
print("  - Botón ya no tiene foco:       ", (not btn:hasClass("is-active") and "OK" or "FAIL"))

-- 6. Limpieza de Hover
print("\n[TEST 4] Salida de área (Mouse Leave):")
ReanUI.handleMouseEvent("move", 0, 0) -- Mover a la esquina vacía
print("  - Botón ya no tiene 'is-hover': ", (not btn:hasClass("is-hover") and "OK" or "FAIL"))

print("\n==========================================================")
print("===  PRUEBAS DE INTERACCIÓN COMPLETADAS                ===")
print("==========================================================\n")
