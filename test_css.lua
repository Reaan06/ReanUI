-- test_css.lua
local ui = require("reanui")

print("\n=== TEST FASE 2: PARSER CSS ESTRICTO ===")
local view = ui.createView()

print("\n[->] Inyectando bloque CSS completo (incluye espacios vacíos y formatos rudos)...")
local css_string = [[
    width:   450px ;
    height   : 300px;
    background-color: #FA05B2 ;
    
    atributo-invalido ; -- tolerante a esto sin crashear
    
    background-color: #FFAA22 -- Sobreescribimos asumiendo la falta del ';' al final
]]

-- Llamamos al nuevo método parser
local ok = view:setStyleSheet(css_string)
print("Estado del parsing CSS:", ok)

-- Validamos que el binding hizo su trabajo e internalizó las primitivas flotantes y decimales (hex) de color
print("\n[->] Resultados Matemáticos calculados internamente en C:")
view:debugPrint()

print("\n=== SUCCESS ===")
