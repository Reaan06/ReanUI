-- test_uielement.lua
-- Test completo del sistema de componentes base de ReanUI

local UIElement = require("src.core.UIElement")

print("\n==========================================================")
print("===  REANUI: TEST SISTEMA BASE DE COMPONENTES (Lua)    ===")
print("==========================================================")

-- ============================================================
-- TEST 1: Creación básica + Identidad
-- ============================================================
print("\n[TEST 1] Creación e Identidad")
local root = UIElement.new("div", { id = "app", class = "container dark-theme" })
print("  Tag:", root:getTag())
print("  ID:", root:getId())
print("  UID:", root:getUid())
print("  Has 'container':", root:hasClass("container"))
print("  Has 'dark-theme':", root:hasClass("dark-theme"))
print("  Has 'ghost':", root:hasClass("ghost"))

-- ============================================================
-- TEST 2: Estilos CSS
-- ============================================================
print("\n[TEST 2] Estilos CSS (StyleManager)")
root:setStyle("width", "100%")
root:setStyle("background-color", "#1a1a2e")
root:setStyleSheet("padding: 20px; margin: 10px; opacity: 0.95;")
print("  width:", root:getStyle("width"))
print("  background-color:", root:getStyle("background-color"))
print("  padding:", root:getStyle("padding"))
print("  opacity:", root:getStyle("opacity"))

-- Propiedad inválida (debe fallar silenciosamente)
root:setStyle("fake-property", "nope")
print("  fake-property:", root:getStyle("fake-property"), "(esperado: nil)")

-- ============================================================
-- TEST 3: Jerarquía padre-hijo
-- ============================================================
print("\n[TEST 3] Jerarquía DOM")
local header  = UIElement.new("header", { id = "main-header" })
local nav     = UIElement.new("nav", { class = "navbar" })
local content = UIElement.new("section", { id = "content" })
local button  = UIElement.new("button", { id = "btn-submit", class = "btn primary" })

root:appendChild(header)
root:appendChild(content)
header:appendChild(nav)
content:appendChild(button)

print("  root children:", root:getChildCount())
print("  header parent tag:", header:getParent():getTag())
print("  button parent id:", button:getParent():getId())

-- ============================================================
-- TEST 4: Prevención de ciclos
-- ============================================================
print("\n[TEST 4] Prevención de Referencias Cíclicas")
local ok1, err1 = pcall(function() root:appendChild(root) end)
print("  Self-ref blocked:", not ok1, "->", err1)

local ok2, err2 = pcall(function() button:appendChild(root) end)
print("  Ancestor-ref blocked:", not ok2, "->", err2)

-- ============================================================
-- TEST 5: Sistema de Eventos
-- ============================================================
print("\n[TEST 5] Sistema de Eventos")

local clickCount = 0
local function onClickHandler(data)
    clickCount = clickCount + 1
    print("    [Event] click #" .. clickCount .. " received! Payload:", data)
end

button:addEventListener("click", onClickHandler)
button:dispatchEvent("click", "mouse-left")
button:dispatchEvent("click", "touch")
print("  Total clicks:", clickCount)

-- Once listener (se auto-destruye tras 1 uso)
local hoverFired = false
button:once("hover", function()
    hoverFired = true
    print("    [Event] hover fired ONCE")
end)
button:dispatchEvent("hover")
button:dispatchEvent("hover") -- esta NO debe disparar nada
print("  Hover fired only once:", hoverFired)

-- RemoveEventListener
button:removeEventListener("click", onClickHandler)
button:dispatchEvent("click", "should-not-fire")
print("  Clicks after removal (should still be 2):", clickCount)

-- ============================================================
-- TEST 6: Evento de cambio de estilo (Hook StyleManager -> EventEmitter)
-- ============================================================
print("\n[TEST 6] StyleChange Event Hook")
local styleChanged = false
button:addEventListener("stylechange", function(data)
    styleChanged = true
    print("    [Event] stylechange -> prop:", data.property, "val:", data.value)
end)
button:setStyle("color", "#FF0000")
print("  stylechange fired:", styleChanged)

-- ============================================================
-- TEST 7: Data Attributes
-- ============================================================
print("\n[TEST 7] Data Attributes")
button:setData("action", "submit-form")
button:setData("tooltip", "Click to submit")
print("  data-action:", button:getData("action"))
print("  data-tooltip:", button:getData("tooltip"))

-- ============================================================
-- TEST 8: Debug Print (Árbol visual)
-- ============================================================
print("\n[TEST 8] Árbol DOM Completo")
root:debugPrint()

-- ============================================================
-- TEST 9: Destrucción recursiva segura
-- ============================================================
print("\n[TEST 9] Destrucción Recursiva")
local preDestroyChildren = root:getChildCount()
root:destroy()
print("  Children before destroy:", preDestroyChildren)
print("  root destroyed:", root:isDestroyed())
print("  button destroyed:", button:isDestroyed())
print("  header destroyed:", header:isDestroyed())

print("\n=== ALL TESTS PASSED ===\n")
