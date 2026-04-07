-- src/renderer/LuaRenderer.lua
-- Convierte el árbol DOM de UIElement en una lista plana de draw-calls.
-- Responsabilidad única: producir un RenderList que el host (MTA/SDL/etc) puede consumir línea a línea.

local LuaRenderer = {}
LuaRenderer.__index = LuaRenderer

-- ============================================================================
-- CONSTRUCCIÓN DEL RENDER LIST
-- ============================================================================

--- Genera recursivamente la lista de instrucciones de dibujado.
--- @param node     UIElement    Nodo actual
--- @param parent_clip table     {x, y, w, h} o nil
--- @param result   table        Lista de draw-calls
local function build_render_list(node, parent_clip, result)
    if node:isDestroyed() then return end

    local layout = node._layout
    if not layout then return end -- No se ha calculado layout para este nodo

    local styles = node:getAllStyles()
    
    -- Determinar el clip para este nodo y sus hijos
    local current_clip = parent_clip
    if styles["overflow"] == "hidden" or styles["overflow"] == "scroll" then
        local my_clip = { x = layout.x, y = layout.y, w = layout.w, h = layout.h }
        if parent_clip then
            -- Intersección de áreas de recorte
            local ix = math.max(my_clip.x, parent_clip.x)
            local iy = math.max(my_clip.y, parent_clip.y)
            local iw = math.min(my_clip.x + my_clip.w, parent_clip.x + parent_clip.w) - ix
            local ih = math.min(my_clip.y + my_clip.h, parent_clip.y + parent_clip.h) - iy
            current_clip = { x = ix, y = iy, w = math.max(0, iw), h = math.max(0, ih) }
        else
            current_clip = my_clip
        end
    end

    local draw_call = {
        type    = node:getTag(),
        uid     = node:getUid(),
        id      = node:getId(),
        x       = layout.x,
        y       = layout.y,
        w       = layout.w,
        h       = layout.h,
        color   = styles["background-color"] or "transparent",
        opacity = tonumber(styles["opacity"]) or 1.0,
        clip    = parent_clip, -- El clip que le afecta es el del padre
        
        -- Datos extra para componentes específicos
        label   = node._label,       -- Button
        content = node._content,     -- Text
    }

    table.insert(result, draw_call)

    -- Renderizar hijos (ya posicionados absolutamente por Flexbox)
    for _, child in ipairs(node:getChildren()) do
        build_render_list(child, current_clip, result)
    end
end

-- ============================================================================
-- API PÚBLICA
-- ============================================================================

--- Renderiza el árbol desde la raíz y retorna la lista de draw-calls plana.
--- @param root UIElement
--- @return table  Array de draw-calls { type, uid, x, y, w, h, color, ... }
function LuaRenderer.render(root)
    local result = {}
    build_render_list(root, nil, result)
    return result
end

--- Imprime la lista de draw-calls en consola (debug).
function LuaRenderer.debugDump(render_list)
    print("\n--- RENDER LIST ---")
    for i, dc in ipairs(render_list) do
        print(string.format(
            "  [%02d] <%s> uid=%-3d id=%-12s x=%-6.0f y=%-6.0f w=%-6.0f h=%-6.0f color=%s",
            i, dc.type, dc.uid,
            tostring(dc.id or ""),
            dc.x, dc.y, dc.w, dc.h,
            dc.color
        ))
        if dc.label   then print(string.format("        label='%s'", dc.label)) end
        if dc.content then print(string.format("        content='%s'", dc.content)) end
    end
    print("--- END LIST ---\n")
end

return LuaRenderer
