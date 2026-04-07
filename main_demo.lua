-- main_demo.lua
-- Demostración final: Integración total de ReanUI
-- Carga CSS, crea componentes declarativos, calcula layout y produce draw-calls.

local ReanUI = require("src.ReanUI")

print("\n==========================================================")
print("===  REANUI: DEMOSTRACIÓN FINAL DE ARQUITECTURA        ===")
print("==========================================================")

-- 1. Definimos el diseño visual en CSS estándar
local stylesheet = [[
    /* Root de la aplicación */
    div#app-root {
        background-color: #0d0d0d;
        padding: 50px;
        gap: 20px;
    }

    /* Estilos globales para componentes */
    .btn {
        background-color: #333;
        border-radius: 8px;
        flex-grow: 1;
        height: 60px;
        justify-content: center;
        align-items: center;
    }

    .btn:hover {
        background-color: #444;
    }

    .primary {
        background-color: #e94560;
    }

    text {
        color: #ffffff;
        font-size: 18px;
    }

    #app-title {
        color: #e94560;
        font-size: 32px;
        margin-bottom: 20px;
    }
]]

-- 2. Cargamos el CSS en el motor
print("[1] Cargando hojas de estilo CSS...")
ReanUI.loadStyle(stylesheet)

-- 3. Inicializamos el render root (Pantalla 1920x1080)
print("[2] Iniciando lienzo de 1920x1080...")
local screen = ReanUI.init(1920, 1080)

-- 4. Creación declarativa de la Interfaz (Estilo React/Vue)
print("[3] Construyendo interfaz de forma declarativa...")
local myUI = ReanUI.create("div", { id = "app-root" }, {
    ReanUI.create("text", { id = "app-title" }, "Dashboard ReanUI"),
    
    ReanUI.create("div", { id = "header", style = "flex_direction: row; gap: 15px; width: 100%; height: 100px;" }, {
        ReanUI.create("button", { class = "btn primary" }, "Nueva Tarea"),
        ReanUI.create("button", { class = "btn" }, "Configuración"),
        ReanUI.create("button", { class = "btn" }, "Ayuda"),
    }),

    ReanUI.create("div", { id = "content", style = "background-color: #16213e; height: 500px; width: 100%; padding: 20px;" }, {
        ReanUI.create("text", {}, "Bienvenido al sistema nativo de ReanUI."),
        ReanUI.create("text", { style = "color: #888; font-size: 14px;" }, "Resolviendo Layout Flexbox en tiempo real...")
    })
})

-- Añadimos la UI al root del sistema
screen:appendChild(myUI)

-- 5. Realizamos el cálculo de Layout y generamos la Render List para el Host (MTA/DX)
print("[4] Procesando Motor Flexbox y generando Draw Calls...")
local render_list = ReanUI.update()

-- 6. Debug Dump de lo que el motor gráfico recibiría
print("\n--- OUTPUT PARA EL MOTOR GRÁFICO (HOST RENDERER) ---")
for i, dc in ipairs(render_list) do
    if i < 15 then -- Limitar salida para brevedad
        print(string.format("  Draw: %-8s | At: (%-5d, %-5d) | Size: %-5dx%-5d | Color: %s", 
            dc.type:upper(), dc.x, dc.y, dc.w, dc.h, dc.color))
    end
end

print("\n[5] Simulando interacción: Press button 'Nueva Tarea'...")
local btn = myUI:getChildren()[2]:getChildren()[1] -- Navegación simple por el árbol
btn:addEventListener("click", function() print("    >> ¡ACCIÓN DISPARADA DESDE LUA!") end)
btn:press()

print("\n==========================================================")
print("===  REANUI: DEMO COMPLETADA EXITOSAMENTE              ===")
print("==========================================================")
