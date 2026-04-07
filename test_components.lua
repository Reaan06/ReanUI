-- test_components.lua
-- Test integral: componentes + árbol DOM + eventos + renderer

local Container   = require("src.components.Container")
local Button      = require("src.components.Button")
local Text        = require("src.components.Text")
local LuaRenderer = require("src.renderer.LuaRenderer")

print("\n==========================================================")
print("===  REANUI: TEST COMPONENTES + RENDERER PIPELINE      ===")
print("==========================================================")

-- ============================================================
-- TEST 1: Componentes Concretos
-- ============================================================
print("\n[TEST 1] Instanciación de Componentes")

local root = Container.new("column", { id = "app-root" })
root:setStyleSheet("width: 1920px; height: 1080px; background-color: #0d0d0d;")

local header = Container.new("row", { id = "header", class = "top-bar" })
header:setStyleSheet("width: 1920px; height: 80px; background-color: #1a1a2e; padding: 10px;")

local title = Text.new("ReanUI Demo", { id = "app-title" })
title:setStyleSheet("color: #e94560; font-size: 24px;")

local submitBtn = Button.new("Iniciar Sesión", { id = "btn-login", class = "btn primary" })
submitBtn:setStyleSheet("width: 200px; height: 50px; background-color: #e94560;")

local cancelBtn = Button.new("Cancelar", { id = "btn-cancel" })
cancelBtn:setStyleSheet("width: 200px; height: 50px; background-color: #333;")

print("  Container direction:", root:getDirection())
print("  Button label:", submitBtn:getLabel())
print("  Text content:", title:getContent())

-- ============================================================
-- TEST 2: Árbol DOM
-- ============================================================
print("\n[TEST 2] Construir árbol DOM")
root:appendChild(header)
header:appendChild(title)
root:appendChild(submitBtn)
root:appendChild(cancelBtn)

root:debugPrint()

-- ============================================================
-- TEST 3: Eventos en Componentes
-- ============================================================
print("\n[TEST 3] Eventos de Componentes")

submitBtn:addEventListener("click", function(data)
    print("  [click] Button presionado:", data.label)
end)

cancelBtn:addEventListener("click", function(data)
    print("  [click] Cancel presionado:", data.label)
end)

-- Button disabled no debe disparar click
submitBtn:disable()
submitBtn:press()
print("  Submit click mientras disabled (silencioso):", submitBtn:getState())

submitBtn:enable()
submitBtn:press()

cancelBtn:press()

-- ============================================================
-- TEST 4: Render Pipeline
-- ============================================================
print("\n[TEST 4] Pipeline Renderer (DOM -> Draw Calls)")
local render_list = LuaRenderer.render(root)
LuaRenderer.debugDump(render_list)
print("  Total draw-calls generados:", #render_list)

-- ============================================================
-- TEST 5: Limpieza de memoria
-- ============================================================
print("[TEST 5] Destrucción segura del árbol completo")
root:destroy()
print("  root destroyed:", root:isDestroyed())
print("  title destroyed:", title:isDestroyed())
print("  submitBtn destroyed:", submitBtn:isDestroyed())

print("\n=== ALL TESTS PASSED ===\n")
