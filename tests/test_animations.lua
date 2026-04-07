-- tests/test_animations.lua
-- Suite de pruebas para el AnimationManager (Interpolaciones y Ticks).

local ReanUI = require("src.ReanUI")

print("\n==========================================================")
print("===  REANUI: TEST ANIMATION ENGINE                     ===")
print("==========================================================\n")

-- 1. Setup
local root = ReanUI.init(800, 600)
local btn = ReanUI.create("button", { id = "anim-target" }, "Animate Me")
root:appendChild(btn)

-- Estado inicial
btn:setStyle("width", "100px")
btn:setStyle("background-color", "#000000")
ReanUI.update()

print("[INFO] Estado Inicial:")
print("  - Width: ", btn:getStyle("width"))
print("  - Color: ", btn:getStyle("background-color"))

-- 2. Iniciar Animación
-- De 100px a 200px, y de Negro a Blanco en 1000ms (1s)
local finished = false
btn:animate({
    ["width"] = "200px",
    ["background-color"] = "#ffffff"
}, 1000, "linear", function()
    finished = true
    print("    >> Callback onComplete disparado!")
end)

-- 3. Simular Ticks
print("\n[TEST 1] Interpolación al 50% (dt = 0.5s):")
ReanUI.update(800, 600, 0.5)

local w50 = btn:getStyle("width")
local c50 = btn:getStyle("background-color")
print("  - Width (esperado 150px): ", w50)
print("  - Color (esperado #7f7f7f):", c50)

local ok1 = (w50 == "150px" or w50 == "150.0px")
local ok2 = (c50 == "#7f7f7f")
print("  - Resultado: ", (ok1 and ok2) and "OK" or "FAIL")

print("\n[TEST 2] Finalización (dt = 0.6s adicional):")
ReanUI.update(800, 600, 0.6)

local w100 = btn:getStyle("width")
local c100 = btn:getStyle("background-color")
print("  - Width (esperado 200px): ", w100)
print("  - Color (esperado #ffffff):", c100)
print("  - Callback ejecutado:      ", (finished and "OK" or "FAIL"))

local ok3 = (w100 == "200px" or w100 == "200.0px")
local ok4 = (c100 == "#ffffff")
print("  - Resultado: ", (ok3 and ok4) and "OK" or "FAIL")

print("\n==========================================================")
print("===  PRUEBAS DE ANIMACIÓN COMPLETADAS                  ===")
print("==========================================================\n")
