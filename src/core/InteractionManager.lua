-- src/core/InteractionManager.lua
-- Cerebro de interactividad de ReanUI.
-- Traduce coordenadas crudas del mouse/teclado en eventos semánticos (click, hover, focus).

local InteractionManager = {}
local EventSystem = require("src.event.EventSystem")

-- Estado actual de la interacción global
InteractionManager._hovered         = nil  -- UIElement bajo el mouse
InteractionManager._pressed         = nil  -- UIElement pulsado actualmente
InteractionManager._focused         = nil  -- UIElement con foco de teclado
InteractionManager._last_mouse_pos  = { x = 0, y = 0 }
InteractionManager._last_click_time = 0
InteractionManager._last_click_target = nil
InteractionManager._focusable_pool = {} -- Cache temporal para navegación por TAB

local function dispatch(target, eventType, data)
    if not target then return false end
    local event = EventSystem.Event.new(eventType, data)
    return EventSystem.EventDispatcher.dispatch(target, event)
end

local function normalizeKeyState(state)
    if state == true or state == "down" then return "down" end
    if state == false or state == "up" then return "up" end
    return state
end

local function nowMs()
    if type(getTickCount) == "function" then
        return getTickCount()
    end
    return math.floor(os.clock() * 1000)
end

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
            dispatch(InteractionManager._hovered, "mouseleave", { x = x, y = y })
            if InteractionManager._hovered.onMouseLeave then
                InteractionManager._hovered:onMouseLeave()
            end
        end

        -- 2. Entrar al nuevo
        InteractionManager._hovered = target
        if InteractionManager._hovered then
            dispatch(InteractionManager._hovered, "mouseenter", { x = x, y = y })
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
            local shouldFocus = target.isFocusable and target:isFocusable()
            if shouldFocus and target ~= InteractionManager._focused then
                if InteractionManager._focused then 
                    dispatch(InteractionManager._focused, "blur")
                    if InteractionManager._focused.onBlur then
                        InteractionManager._focused:onBlur()
                    end
                end
                InteractionManager._focused = target
                dispatch(target, "focus")
                if target.onFocus then
                    target:onFocus()
                end
            end

            dispatch(target, "mousedown", { button = button, x = x, y = y })
            if target.onMouseDown then
                target:onMouseDown()
            end
        else
            -- Clic fuera limpia el foco
            InteractionManager._focused = nil
        end

    elseif state == "up" then
        if target then
            dispatch(target, "mouseup", { button = button, x = x, y = y })
            if target.onMouseUp then
                target:onMouseUp()
            end

            -- Si es el mismo que se presionó, disparar CLICK
            if target == InteractionManager._pressed then
                local now = nowMs()
                dispatch(target, "click", { button = button, x = x, y = y })
                
                -- Doble clic (umbral de 300ms)
                if target == InteractionManager._last_click_target and (now - InteractionManager._last_click_time) < 300 then
                    dispatch(target, "dblclick", { button = button, x = x, y = y })
                end
                
                InteractionManager._last_click_time = now
                InteractionManager._last_click_target = target
                if target.press then
                    target:press()
                end
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
    return dispatch(target, "mousewheel", { delta = delta, x = x, y = y })
end

-- ============================================================================
-- GESTIÓN DE FOCO Y TECLADO
-- ============================================================================

function InteractionManager.getFocusedElement()
    return InteractionManager._focused
end

function InteractionManager.setFocusedElement(element)
    if element == InteractionManager._focused then return end
    
    -- Blur previo
    if InteractionManager._focused then
        dispatch(InteractionManager._focused, "blur")
        if InteractionManager._focused.onBlur then
            InteractionManager._focused:onBlur()
        end
    end
    
    -- Focus nuevo
    InteractionManager._focused = element
    if element then
        dispatch(element, "focus")
        if element.onFocus then
            element:onFocus()
        end
    end
end

--- Procesa la tecla presionada (MTA onClientKey).
function InteractionManager.handleKeyboardKey(root, key, state)
    local keyState = normalizeKeyState(state)
    if keyState ~= "down" then return end -- Solo procesar key-down
    
    -- Interceptar TAB para navegación
    if key == "tab" then
        local shiftPressed = false
        if type(getKeyState) == "function" then
            shiftPressed = getKeyState("lshift") or getKeyState("rshift")
        end
        InteractionManager._navigateTab(root, shiftPressed)
        return true
    end
    
    -- Reenviar al elemento con foco
    local focused = InteractionManager._focused
    if focused then
        return dispatch(focused, "keydown", { key = key, state = keyState })
    end
end

--- Procesa la entrada de carácter (MTA onClientCharacter).
function InteractionManager.handleCharacterInput(char)
    local focused = InteractionManager._focused
    if focused then
        return dispatch(focused, "character", { character = char })
    end
end

-- Helper: Busca todos los elementos focusables en el árbol (DFS)
local function collect_focusables(node, list)
    if not node or node:isDestroyed() then return end
    if node:isFocusable() then table.insert(list, node) end
    for _, child in ipairs(node:getChildren()) do
        collect_focusables(child, list)
    end
end

--- Lógica de navegación cíclica con TAB.
function InteractionManager._navigateTab(root, reverse)
    local pool = {}
    collect_focusables(root, pool)
    if #pool == 0 then return end
    
    local currentIdx = 0
    for i, el in ipairs(pool) do
        if el == InteractionManager._focused then
            currentIdx = i
            break
        end
    end
    
    local nextIdx
    if reverse then
        nextIdx = currentIdx <= 1 and #pool or currentIdx - 1
    else
        nextIdx = currentIdx >= #pool and 1 or currentIdx + 1
    end
    
    InteractionManager.setFocusedElement(pool[nextIdx])
end

return InteractionManager
