--- @module EventSystem
--- Sistema de eventos de alto rendimiento inspirado en el DOM de la W3C.
--- Proporciona gestión de fases de captura, objetivo y burbujeo.
local EventSystem = {}

-- ============================================================================
-- CONSTANTES Y PHASES
-- ============================================================================

EventSystem.PHASE = {
    NONE = 0,
    CAPTURING = 1,
    AT_TARGET = 2,
    BUBBLING = 3
}

-- ============================================================================
--- @class Event
--- Representa un objeto de evento que viaja por el árbol de UI.
local Event = {}
Event.__index = Event

--- Crea una nueva instancia de Evento.
--- @tparam string type Nombre del evento (ej: "click", "mouseenter").
--- @tparam table|nil data Datos personalizados asociados al evento.
--- @treturn Event Instancia del evento.
function Event.new(type, data)
    local self = setmetatable({
        type = type,
        data = data or {},
        target = nil,             -- El elemento que disparó el evento
        currentTarget = nil,      -- El elemento que está procesando el evento ahora
        eventPhase = EventSystem.PHASE.NONE,
        bubbles = true,
        cancelable = true,
        timeStamp = os.clock(),
        
        _stopped = false,         -- stopPropagation()
        _immediateStopped = false, -- stopImmediatePropagation()
        _defaultPrevented = false  -- preventDefault()
    }, Event)
    return self
end

function Event:stopPropagation()
    self._stopped = true
end

function Event:stopImmediatePropagation()
    self._immediateStopped = true
    self._stopped = true
end

function Event:preventDefault()
    if self.cancelable then
        self._defaultPrevented = true
    end
end

-- ============================================================================
--- @class EventTarget
--- Interfaz para objetos que pueden recibir eventos y tener listeners.
local EventTarget = {}
EventTarget.__index = EventTarget

function EventTarget.new()
    local self = setmetatable({
        _listeners = {} -- { [type] = { {fn, capture, once, passive}, ... } }
    }, EventTarget)
    return self
end

--- Registra un nuevo manejador de eventos.
--- @tparam string event_type Nombre del evento.
--- @tparam function callback Función a ejecutar.
--- @tparam table|boolean|nil options Opciones: { capture, once, passive } o booleano para 'capture'.
function EventTarget:addEventListener(event_type, callback, options)
    if not self._listeners[event_type] then self._listeners[event_type] = {} end
    
    local opt = type(options) == "table" and options or { capture = options or false }
    
    -- Evitar duplicados
    for _, l in ipairs(self._listeners[event_type]) do
        if l.fn == callback and l.capture == opt.capture then return end
    end
    
    table.insert(self._listeners[event_type], {
        fn = callback,
        capture = opt.capture or false,
        once = opt.once or false,
        passive = opt.passive or false
    })
end

function EventTarget:removeEventListener(event_type, callback, capture)
    local bucket = self._listeners[event_type]
    if not bucket then return end
    
    capture = capture or false
    for i = #bucket, 1, -1 do
        if bucket[i].fn == callback and bucket[i].capture == capture then
            table.remove(bucket, i)
        end
    end
end

--- Obtiene los listeners registrados (Debugging).
function EventTarget:getListeners(event_type)
    if not event_type then return self._listeners end
    return self._listeners[event_type] or {}
end

-- ============================================================================
--- @class EventDispatcher
--- Orquestador responsable de la propagación de eventos por el árbol.
local EventDispatcher = {}

--- Inicia el ciclo de propagación (Capture -> Target -> Bubble).
--- @tparam UIElement target El elemento emisor original.
--- @tparam Event event Objeto de evento a despachar.
--- @treturn boolean Si el evento no fue cancelado mediante preventDefault().
function EventDispatcher.dispatch(target, event)
    if not target or not event then return end
    
    event.target = target

    -- 1. Construir ruta (Chain) desde el target hasta el root → invertir en O(n)
    --    Antes: table.insert(chain, 1, curr) era O(n²) porque desplaza todos los elementos.
    --    Ahora: append O(1) + swap O(n/2) = O(n) total.
    local chain = {}
    local curr = target
    while curr do
        chain[#chain + 1] = curr   -- O(1)
        curr = curr:getParent()
    end
    -- Invertir en un solo paso para obtener [root, ..., target]
    local n = #chain
    for i = 1, math.floor(n / 2) do
        chain[i], chain[n - i + 1] = chain[n - i + 1], chain[i]
    end
    
    -- 2. CAPTURING PHASE (Phase 1)
    event.eventPhase = EventSystem.PHASE.CAPTURING
    for i = 1, #chain - 1 do
        if event._stopped then break end
        local node = chain[i]
        EventDispatcher._invokeListeners(node, event, true)
    end
    
    -- 3. AT_TARGET PHASE (Phase 2)
    if not event._stopped then
        event.eventPhase = EventSystem.PHASE.AT_TARGET
        EventDispatcher._invokeListeners(target, event)
    end
    
    -- 4. BUBBLING PHASE (Phase 3)
    if event.bubbles and not event._stopped then
        event.eventPhase = EventSystem.PHASE.BUBBLING
        for i = #chain - 1, 1, -1 do
            if event._stopped then break end
            local node = chain[i]
            EventDispatcher._invokeListeners(node, event, false)
        end
    end
    
    return not event._defaultPrevented
end

--- Invocación interna de callbacks con pcall para seguridad.
function EventDispatcher._invokeListeners(element, event, capture)
    local bucket = element:getListeners(event.type)
    if #bucket == 0 then return end
    
    event.currentTarget = element
    
    -- Usamos una copia para permitir removeEventListener durante la iteración
    local listeners = {}
    for i, l in ipairs(bucket) do listeners[i] = l end
    
    for _, l in ipairs(listeners) do
        if event._immediateStopped then break end
        
        -- Lógica de filtrado por fase:
        -- 1. En AT_TARGET, ejecutamos TODOS los listeners.
        -- 2. En CAPTURING/BUBBLING, solo los que coincidan con la fase 'capture'.
        local shouldInvoke = false
        if event.eventPhase == EventSystem.PHASE.AT_TARGET then
            shouldInvoke = true
        elseif l.capture == capture then
            shouldInvoke = true
        end

        if shouldInvoke then
            -- Debug trace (opcional)
            if EventSystem._traceEnabled then
                print(string.format("[EventTrace] %s | Phase: %d | Node: %s", 
                      event.type, event.eventPhase, tostring(element:getId() or element:getUid())))
            end

            local ok, err = pcall(l.fn, event)
            if not ok then
                print(string.format("[ReanUI:EventError] Error in listener for '%s' on node '%s': %s", 
                      event.type, tostring(element:getId() or element:getUid()), tostring(err)))
            end
            
            if l.once then
                element:removeEventListener(event.type, l.fn, l.capture)
            end
        end
    end
end

-- Exportar clases
EventSystem.Event = Event
EventSystem.EventTarget = EventTarget
EventSystem.EventDispatcher = EventDispatcher
EventSystem._traceEnabled = false

function EventSystem.traceEvents(enabled)
    EventSystem._traceEnabled = (enabled == nil) and true or enabled
end

return EventSystem
