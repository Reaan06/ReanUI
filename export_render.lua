-- export_render.lua
-- Script encargado de volcar el estado matemático de ReanUI a JSON para el visualizador.

local ReanUI = require("src.ReanUI")

-- 1. Mismo diseño del demo real
local stylesheet = [[
    div#app-root {
        background-color: #0d0d0d;
        padding: 50px;
        gap: 20px;
    }
    .btn {
        background-color: #333;
        height: 60px;
        width: 100%;
        margin-bottom: 5px;
    }
    .primary { background-color: #e94560; }
    text { color: #ffffff; font-size: 18px; }
    #app-title { color: #e94560; font-size: 32px; margin-bottom: 20px; }
]]

ReanUI.loadStyle(stylesheet)
local screen = ReanUI.init(1920, 1080)

local myUI = ReanUI.create("div", { id = "app-root" }, {
    ReanUI.create("text", { id = "app-title" }, "Dashboard ReanUI"),
    ReanUI.create("div", { style = "flex_direction: row; gap: 15px; width: 100%; height: 100px;" }, {
        ReanUI.create("button", { class = "btn primary" }, "Nueva Tarea"),
        ReanUI.create("button", { class = "btn" }, "Configuración"),
        ReanUI.create("button", { class = "btn" }, "Ayuda"),
    }),
    ReanUI.create("div", { style = "background-color: #16213e; height: 500px; width: 100%; padding: 20px;" }, {
        ReanUI.create("text", {}, "Bienvenido al sistema nativo de ReanUI."),
        ReanUI.create("text", { style = "color: #999; font-size: 14px;" }, "Resolviendo Layout Flexbox en tiempo real...")
    })
})

screen:appendChild(myUI)

-- 2. Obtener lista de dibujado
local render_list = ReanUI.update()

-- 3. Serializador JSON simplificado para Lua puro
local function escape(s)
    return s:gsub('"', '\\"'):gsub('\n', '\\n')
end

local function to_json(list)
    local items = {}
    for _, dc in ipairs(list) do
        local entry = string.format(
            '{"type":"%s", "x":%d, "y":%d, "w":%d, "h":%d, "color":"%s", "label":"%s", "content":"%s"}',
            dc.type, dc.x, dc.y, dc.w, dc.h, dc.color,
            escape(dc.label or ""), escape(dc.content or "")
        )
        table.insert(items, entry)
    end
    return "[" .. table.concat(items, ",") .. "]"
end

-- 4. Guardar archivo
local file = io.open("render_data.json", "w")
if file then
    file:write(to_json(render_list))
    file:close()
    print("[ReanUI] RenderList exportada a render_data.json exitosamente.")
else
    print("[Error] No se pudo abrir el archivo para escritura.")
end
