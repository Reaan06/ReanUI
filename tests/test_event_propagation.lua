-- tests/test_event_propagation.lua
-- Suite de pruebas para el sistema de eventos (Capture, Bubble, Stop).

local ReanUI = require("src.ReanUI")

print("\n==========================================================")
print("===  REANUI: TEST ADVANCED EVENT SYSTEM                ===")
print("==========================================================\n")

-- 1. Setup Jerarquía: Grandparent > Parent > Child
local root = ReanUI.init(800, 600)
local gp = ReanUI.create("container", { id = "grandparent" })
local p  = ReanUI.create("container", { id = "parent" })
local c  = ReanUI.create("button",    { id = "child" }, "Click Me")

root:appendChild(gp)
gp:appendChild(p)
p:appendChild(c)

-- 2. Registrar Listeners en diferentes fases
local log = {}

-- Captura en Grandparent
gp:addEventListener("click", function(e)
    table.insert(log, "GP CAPTURE")
    print("  [Event] GP Capture phase: " .. e.eventPhase)
end, true) -- true = capture

-- Bubble en Grandparent
gp:addEventListener("click", function(e)
    table.insert(log, "GP BUBBLE")
    print("  [Event] GP Bubble phase: " .. e.eventPhase)
end) -- default = bubble

-- Bubble en Parent
p:addEventListener("click", function(e)
    table.insert(log, "PARENT BUBBLE")
    print("  [Event] Parent Bubble phase: " .. e.eventPhase)
    -- Detener aquí para que no llegue a GP Bubble
    e:stopPropagation()
    print("    >> stopPropagation() ejecutado en Parent")
end)

-- Target en Child
c:addEventListener("click", function(e)
    table.insert(log, "CHILD TARGET")
    print("  [Event] Child Target phase: " .. e.eventPhase)
end)

-- Listener "Once"
local onceCount = 0
c:addEventListener("testOnce", function()
    onceCount = onceCount + 1
end, { once = true })

-- 3. Iniciar Pruebas
print("[TEST 1] Propagación y stopPropagation:")
c:dispatchEvent("click", { detail = "test-data" })

-- Verificar resultados del log
-- Esperado: GP CAPTURE -> CHILD TARGET -> PARENT BUBBLE (y stop!)
local expected = {"GP CAPTURE", "CHILD TARGET", "PARENT BUBBLE"}
local ok1 = true
for i, v in ipairs(expected) do
    if log[i] ~= v then ok1 = false end
end

print("\n  - Estructura del log: " .. table.concat(log, " -> "))
print("  - Resultado Propagación: " .. (ok1 and "OK" or "FAIL"))

print("\n[TEST 2] Opciones del listener (Once):")
c:dispatchEvent("testOnce")
c:dispatchEvent("testOnce")
print("  - Ejecuciones (esperado 1): " .. onceCount)
print("  - Resultado Once: " .. (onceCount == 1 and "OK" or "FAIL"))

print("\n[TEST 3] Manejo de Errores (Safe Dispatch):")
c:addEventListener("errorTest", function()
    print("    (Simulando error en callback...)")
    error("Boom!")
end)
local okError = c:dispatchEvent("errorTest")
print("  - Dispatch continuó tras error: " .. (okError and "OK" or "FAIL"))

print("\n==========================================================")
print("===  PRUEBAS DE EVENTOS COMPLETADAS                    ===")
print("==========================================================\n")
