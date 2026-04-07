local AnimationManager = require("src.core.AnimationManager")

local function assertTrue(cond, msg)
    if not cond then error("[FAIL] " .. msg) end
end

local function assertEq(a, b, msg)
    if a ~= b then
        error(string.format("[FAIL] %s | expected=%s got=%s", msg, tostring(b), tostring(a)))
    end
end

local element = {
    _uid = 999,
    _styles = {
        ["background-color"] = "#000000",
        width = "10px",
        opacity = "0",
    },
    _destroyed = false
}

function element:getUid() return self._uid end
function element:getStyle(prop) return self._styles[prop] end
function element:setStyle(prop, value) self._styles[prop] = value end
function element:isDestroyed() return self._destroyed end

local completed = 0
local ok = AnimationManager.animate(
    element,
    {
        ["background-color"] = "#ffffff",
        width = "110px",
        opacity = 1
    },
    1000, -- API en milisegundos
    "linear",
    function()
        completed = completed + 1
    end
)
assertTrue(ok == true, "animate debe aceptar animaciones validas")
assertEq(AnimationManager.getActiveCount(), 1, "debe registrar una animacion activa")

local activeAfterHalf = AnimationManager.tick(0.5) -- interno en segundos
assertEq(activeAfterHalf, 1, "a mitad de duracion debe seguir activa")
assertEq(element:getStyle("width"), "60px", "interpolacion de dimensiones px")
assertEq(element:getStyle("opacity"), "0.5", "interpolacion numerica")
assertEq(element:getStyle("background-color"), "#7f7f7f", "interpolacion color hex")
assertEq(completed, 0, "onComplete no debe disparar antes de finalizar")

local activeAfterEnd = AnimationManager.tick(0.5)
assertEq(activeAfterEnd, 0, "al finalizar no deben quedar animaciones activas")
assertEq(AnimationManager.getActiveCount(), 0, "registro interno debe limpiarse")
assertEq(element:getStyle("width"), "110px", "valor final width")
assertEq(element:getStyle("opacity"), "1", "valor final opacity")
assertEq(element:getStyle("background-color"), "#ffffff", "valor final color")
assertEq(completed, 1, "onComplete debe ejecutar una vez")

print("PASS tests/test_animation_engine.lua")
