-- src/core/InteractionManager.lua
-- Cerebro de interactividad de ReanUI.
-- Traduce coordenadas crudas del mouse/teclado en eventos semánticos (click, hover, focus).

local InteractionManager = {}

-- Estado actual de la interacción global
InteractionManager._hovered         = nil  -- UIElement bajo el mouse
InteractionManager._pressed         = nil  -- UIElement pulsado actualmente
InteractionManager._focused         = nil  -- UIElement con foco de teclado
InteractionManager._last_mouse_pos  = { x = 0, y = 0 }
InteractionManager._last_click_time = 0
InteractionManager._last_click_target = nil

-- ============================================================================
-- ALGORITMO HIT-TESTING
-- ============================================================================

--- Realiza una búsqueda recursiva inversa (hijos primero, los últimos arriba)
--- para encontrar el elemento en la coordenada (x, y).
--- @param node UIElement
--- @param x    number
--- @param y    number
--- @return UIElement|nil
function InteractionManager.hitTest(node, x, y)
    if not node or node:isDestroyed() then return nil end

    -- 1. Intentar con los hijos primero (Z-Order: los últimos hijos están arriba)
    local children = node:getChildren()
    for i = #children, 1, -1 do
        local target = InteractionManager.hitTest(children[i], x, y)
        if target then return target end
    end

    -- 2. Si ningún hijo hitteó, verificar si el nodo actual contiene el punto
    local layout = node._layout
    if layout and 
       x >= layout.x and x <= (layout.x + layout.w) and
       y >= layout.y and y <= (layout.y + layout.h) then
        return node
    end

    return nil
end

-- ============================================================================
-- PROCESAMIENTO DEeventos
-- ============================================================================

--- Procesa el movimiento del mouse para gestionar estados :hover.
function InteractionManager.handleMouseMove(root, x, y)
    InteractionManager._last_mouse_pos = { x = x, y = y }
    local target = InteractionManager.hitTest(root, x, y)

    if target ~= InteractionManager._hovered then
        -- 1. Salir del anterior
        if InteractionManager._hovered then
            InteractionManager._hovered:dispatchEvent("mouseleave", { x = x, y = y })
            -- Simular llamado de método si existe (legacy/convenience)
            if InteractionManager._hovered.onMouseLeave then 
                InteractionManager._hovered:onMouseLeave() 
            end
        end

        -- 2. Entrar al nuevo
        InteractionManager._hovered = target
        if InteractionManager._hovered then
            InteractionManager._hovered:dispatchEvent("mouseenter", { x = x, y = y })
            if InteractionManager._hovered.onMouseEnter then 
                InteractionManager._hovered:onMouseEnter() 
            end
        end
    end
end

--- Procesa clics de mouse.
function InteractionManager.handleMouseButton(root, button, state, x, y)
    local target = InteractionManager.hitTest(root, x, y)

    if state == "down" then
        InteractionManager._pressed = target
        if target then
            -- Gestionar FOCO
            if target ~= InteractionManager._focused then
                if InteractionManager._focused and InteractionManager._focused.onBlur then 
                    InteractionManager._focused:onBlur() 
                end
                InteractionManager._focused = target
                if target.onFocus then target:onFocus() end
            end

            target:dispatchEvent("mousedown", { button = button, x = x, y = y })
            if target.onMouseDown then target:onMouseDown() end
        else
            -- Clic fuera limpia el foco
            InteractionManager._focused = nil
        end

    elseif state == "up" then
        if target then
            target:dispatchEvent("mouseup", { button = button, x = x, y = y })
            if target.onMouseUp then target:onMouseUp() end

            -- Si es el mismo que se presionó, disparar CLICK
            if target == InteractionManager._pressed then
                local now = os.clock()
                target:dispatchEvent("click", { button = button, x = x, y = y })
                
                -- Doble clic (umbral de 300ms)
                if target == InteractionManager._last_click_target and (now - InteractionManager._last_click_time) < 0.3 then
                    target:dispatchEvent("dblclick", { button = button, x = x, y = y })
                end
                
                InteractionManager._last_click_time = now
                InteractionManager._last_click_target = target
                
                if target.press then target:press() end -- Conveniencia para componentes
            end
        end
        InteractionManager._pressed = nil
    end
end

--- Procesa la rueda del mouse para Scroll.
function InteractionManager.handleMouseWheel(root, delta, x, y)
    local target = InteractionManager.hitTest(root, x, y)
    if not target then return false end
    
    -- Disparar como evento burbujeable
    return target:dispatchEvent("mousewheel", { delta = delta, x = x, y = y })
end

return InteractionManager
