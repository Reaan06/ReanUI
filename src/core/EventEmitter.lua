-- src/core/EventEmitter.lua
-- Sistema de eventos desacoplado. Mixin reutilizable para cualquier objeto Lua.

local EventEmitter = {}
EventEmitter.__index = EventEmitter

-- Eventos soportados nativamente por ReanUI
EventEmitter.SUPPORTED_EVENTS = {
    click       = true,
    hover       = true,
    focus       = true,
    blur        = true,
    mouseenter  = true,
    mouseleave  = true,
    keydown     = true,
    keyup       = true,
    change      = true,
    scroll      = true,
    resize      = true,
    -- Ciclo de vida interno
    create      = true,
    render      = true,
    destroy     = true,
    mount       = true,
    unmount     = true,
    stylechange = true,
}

function EventEmitter.new()
    local self = setmetatable({}, EventEmitter)
    self._listeners = {}  -- { [eventName] = { {fn=callback, once=bool}, ... } }
    return self
end

--- Registra un listener para un evento.
--- @param event_name string
--- @param callback function
--- @param once boolean|nil  Si true, se auto-elimina tras la primera invocación.
function EventEmitter:addEventListener(event_name, callback, once)
    if type(event_name) ~= "string" then
        error("[ReanUI:EventEmitter] event_name must be a string, got " .. type(event_name))
    end
    if type(callback) ~= "function" then
        error("[ReanUI:EventEmitter] callback must be a function, got " .. type(callback))
    end

    if not self._listeners[event_name] then
        self._listeners[event_name] = {}
    end

    -- Evitar duplicados exactos del mismo callback
    for _, entry in ipairs(self._listeners[event_name]) do
        if entry.fn == callback then return self end
    end

    table.insert(self._listeners[event_name], { fn = callback, once = once or false })
    return self
end

--- Atajo: listener que se ejecuta una sola vez y se auto-destruye.
function EventEmitter:once(event_name, callback)
    return self:addEventListener(event_name, callback, true)
end

--- Elimina un listener específico. Si no se pasa callback, elimina TODOS los de ese evento.
function EventEmitter:removeEventListener(event_name, callback)
    if type(event_name) ~= "string" then return self end

    if not callback then
        self._listeners[event_name] = nil
        return self
    end

    local bucket = self._listeners[event_name]
    if not bucket then return self end

    for i = #bucket, 1, -1 do
        if bucket[i].fn == callback then
            table.remove(bucket, i)
        end
    end

    if #bucket == 0 then self._listeners[event_name] = nil end
    return self
end

--- Dispara un evento. Pasa datos opcionales a cada listener.
--- @param event_name string
--- @param data any  Payload libre que se entrega al callback.
function EventEmitter:dispatchEvent(event_name, data)
    if type(event_name) ~= "string" then return false end

    local bucket = self._listeners[event_name]
    if not bucket then return false end

    -- Iteramos en copia superficial para que un listener pueda removerse a sí mismo sin romper el for
    local snapshot = {}
    for i, entry in ipairs(bucket) do snapshot[i] = entry end

    for _, entry in ipairs(snapshot) do
        entry.fn(data)
        if entry.once then
            self:removeEventListener(event_name, entry.fn)
        end
    end

    return true
end

--- Limpia absolutamente todo. Llamar en destrucción del objeto anfitrión.
function EventEmitter:removeAllListeners()
    self._listeners = {}
    return self
end

return EventEmitter
