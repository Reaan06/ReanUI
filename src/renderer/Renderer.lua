-- src/renderer/Renderer.lua
-- Orquestador de renderizado y gestión de Drawables.
-- Responsabilidad: Capturar el estado de la UI y convertirlo en una lista ordenada para el Canvas.

local Drawable = require("src.renderer.Drawable")
local ShaderManager = require("src.shaders.ShaderManager")

local Renderer = {}
Renderer.__index = Renderer

function Renderer.new()
    local self = setmetatable({
        _draw_list  = {},   -- Lista final ordenada de Drawables
        _cache      = {},   -- { [uid] = { drawables = {}, clip = {} } }
        _last_width = 0,
        _last_height = 0,
        _z_dirty    = true  -- true = necesita re-ordenar la draw list
    }, Renderer)
    return self
end

-- ============================================================================
-- CORE RENDERING
-- ============================================================================

--- Procesa recursivamente el árbol para recolectar Drawables.
--- @param node         UIElement
--- @param parent_clip  table|nil
--- @param result       table      Acumulador de Drawables
local function collect_drawables(node, parent_clip, result, cache)
    if node:isDestroyed() then return end

    local layout = node._layout
    if not layout then return end

    local styles = node:getAllStyles()
    local uid = node:getUid()

    -- 1. DETERMINAR CLIP
    local current_clip = parent_clip
    if styles["overflow"] == "hidden" or styles["overflow"] == "scroll" then
        local my_clip = { x = layout.x, y = layout.y, w = layout.w, h = layout.h }
        if parent_clip then
            local ix = math.max(my_clip.x, parent_clip.x)
            local iy = math.max(my_clip.y, parent_clip.y)
            local iw = math.min(my_clip.x + my_clip.w, parent_clip.x + parent_clip.w) - ix
            local ih = math.min(my_clip.y + my_clip.h, parent_clip.y + parent_clip.h) - iy
            current_clip = { x = ix, y = iy, w = math.max(0, iw), h = math.max(0, ih) }
        else
            current_clip = my_clip
        end
    end

    -- 2. RECONSTRUIR DRAWABLE SI ES DIRTY
    local node_drawables = {}
    
    if node._dirty then
        -- Crear Drawable principal (Fondo/Rect)
        local bg_color = styles["background-color"]
        if bg_color and bg_color ~= "transparent" then
            local rect = Drawable.Rect(
                layout.x, layout.y, layout.w, layout.h, 
                bg_color, 
                tonumber(styles["border-radius"]) or 0
            )
            table.insert(node_drawables, rect)
        end

        -- Crear Drawable de SOMBRA (si tiene shadow-color o similar)
        local shadow_color = styles["shadow-color"]
        if shadow_color and shadow_color ~= "transparent" then
            local blur = tonumber(styles["shadow-blur"]) or 5
            local shadow = Drawable.new("shadow", {
                x = layout.x, y = layout.y, w = layout.w, h = layout.h,
                radius = tonumber(styles["border-radius"]) or 0,
                blur = blur,
                color = shadow_color
            })
            table.insert(node_drawables, 1, shadow) -- Dibujar sombras primero (detrás)
        end

        -- Crear Drawable de texto (si es un nodo Text)
        if node:getTag() == "text" and node._content then
            local text = Drawable.Text(
                layout.x, layout.y, 
                node._content, 
                styles["color"], 
                tonumber(styles["font-size"])
            )
            table.insert(node_drawables, text)
        end

        -- Aplicar SHADER si el nodo lo tiene
        if node._shaderPath then
            for _, d in ipairs(node_drawables) do
                d:setShader(node._shaderPath, node._shaderParams)
            end
        end

        -- Configurar propiedades comunes
        local z = node:getZIndex()
        local was_z = cache[uid] and cache[uid][1] and cache[uid][1].z_index
        for _, d in ipairs(node_drawables) do
            d:setZIndex(z)
            d.opacity = tonumber(styles["opacity"]) or 1.0
        end

        -- Guardar en caché y limpiar flag
        cache[uid] = node_drawables
        node._dirty = false
        -- Si el z_index cambió, marcar la lista como sucia para re-sort
        if was_z ~= z then
            cache._z_dirty = true
        end
    else
        node_drawables = cache[uid] or {}
    end

    -- 3. INSERTAR EN LA LISTA FINAL CON CLIP ACTUAL
    for _, d in ipairs(node_drawables) do
        d:setClip(parent_clip)
        table.insert(result, d)
    end

    -- 4. RECURSIÓN
    for _, child in ipairs(node:getChildren()) do
        collect_drawables(child, current_clip, result, cache)
    end
    
    node._child_dirty = false
end

--- Genera la lista de dibujado para el frame actual.
function Renderer:render(root, canvas)
    local draw_list = {}
    
    -- 1. Recolección de primitivas (con optimización de dirty-flags)
    collect_drawables(root, nil, draw_list, self._cache)

    -- 2. Ordenar por Z-Index solo si algo cambió (Stable Sort)
    --    Se omite el sort en frames donde ningún z_index fue modificado.
    if self._cache._z_dirty or self._z_dirty then
        table.sort(draw_list, function(a, b)
            return a.z_index < b.z_index
        end)
        self._cache._z_dirty = false
        self._z_dirty = false
    end

    -- 3. Ejecutar Draw Calls sobre el Canvas
    for _, d in ipairs(draw_list) do
        canvas:setClip(d.clip and d.clip.x, d.clip and d.clip.y, d.clip and d.clip.w, d.clip and d.clip.h)
        
        -- Si el Drawable tiene un shader, usarlo
        if d.shader then
            local shader = ShaderManager.getShader(d.shader)
            if shader then
                ShaderManager.applyParams(shader, d.shaderParams)
                canvas:drawShader(d.data.x, d.data.y, d.data.w, d.data.h, shader, d.data.color)
            end
        elseif d.type == "rect" then
            canvas:drawRect(d.data.x, d.data.y, d.data.w, d.data.h, d.data.color, d.data.radius)
        elseif d.type == "text" then
            canvas:drawText(d.data.x, d.data.y, d.data.text, d.data.color, d.data.size)
        elseif d.type == "image" then
            canvas:drawImage(d.data.x, d.data.y, d.data.w, d.data.h, d.data.path)
        elseif d.type == "shadow" then
            canvas:drawShadow(d.data.x, d.data.y, d.data.w, d.data.h, d.data.radius, d.data.blur, d.data.color)
        end
    end
    
    -- Limpiar clip final
    canvas:setClip()
    
    return #draw_list
end

return Renderer
