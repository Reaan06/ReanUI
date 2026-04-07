-- test_layout.lua
local ui = require("reanui")

print("\n=== TEST FASE 3: MOTOR DE LAYOUT y BOX MODEL ===")

-- 1. Creamos Nodos
local rootView = ui.createView()
local header = ui.createView()
local body = ui.createView()
local button = ui.createView() -- hijo del body

-- 2. Damos propiedades. ROOT View será relativo a la pantalla (100% de la base inyectada desde Lua)
rootView:setStyleSheet("width: 100%; height: 100%;")

-- El Header ocupa el 100% de la pantalla base y 80px estáticos
header:setStyleSheet("width: 100%; height: 80px;")

-- El cuerpo ocupa el centro horizontal, tomando la mitad 50% y de alto 500px
body:setStyleSheet("width: 50%; height: 500px;")

-- El botón tomará dinámicamente un % del ancho computado del "body"
button:setStyleSheet("width: 80%; height: 60px;")

-- 3. Generamos Relaciones Cíclicas de Prueba (Mantenemos hard refs por el GC en test)
rootView:addChild(header)
rootView:addChild(body)
body:addChild(button)

-- Test de Sistema Cíclico Inquebrantable
print("\n[!] Simulando un Developer despistado que mete un Parent ciclado (Stack Overflow prevention):")
local status, err = pcall(function()
    body:addChild(rootView) -- Esto provocaría un bucle infinito en el for del layout, C debe bloquearlo
end)
print("Safety Status:", status, "Error capturado:", err)


-- 4. Ejecutar el pipeline de Frame Layout ultra rudo a 1920x1080 (Pantalla Completa Simulada)
print("\n[>>] Corriendo Recursividad de Layout C Puro con Res base 1920x1080...\n")
rootView:calculateLayout(1920.0, 1080.0)

-- 5. Imprimir el Canvas Resultante List para Rendeo:
print("--- DOM CANVAS (Render List Final) ---")
print("1. Root View:")
rootView:debugPrint()

print("2. Header inside root (Should take full 1920 w and Stack at Y=0):")
header:debugPrint()

print("3. Body inside root (Should take 50% => 960 w and Stack below Header Y=80):")
body:debugPrint()

print("4. Button inside Body (Should take 80% of Body => 768 w and Y=80 (same Y but pushed relative basically...):")
-- Nota: En display-block apila Y en su offset del padre, el Box Model C está haciendo el root global coord Y
button:debugPrint()

print("\n=== SUCCESS ===")
