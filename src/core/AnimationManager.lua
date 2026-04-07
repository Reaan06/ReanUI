-- Gestiona la interpolación temporal de propiedades CSS con soporte de easing.
local StyleManager = require("src.core.StyleManager")

local AnimationManager = {}

-- Estado de animaciones activas
-- Estructura: { [uid] = { [prop] = { from, to, duration, elapsed, easing, onComplete } } }
local _active_animations = {}

-- ============================================================================
-- BIBLIOTECA DE EASING
-- ============================================================================

AnimationManager.EASING = {
    linear = function(t) return t end,
    easeIn = function(t) return t * t end,
    easeOut = function(t) return t * (2 - t) end,
    easeInOut = function(t) 
        return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t 
    end,
    bounce = function(t)
        local n1 = 7.5625
        local d1 = 2.75
        if t < 1 / d1 then return n1 * t * t
        elseif t < 2 / d1 then t = t - 1.5 / d1 return n1 * t * t + 0.75
        elseif t < 2.5 / d1 then t = t - 2.25 / d1 return n1 * t * t + 0.9375
        else t = t - 2.625 / d1 return n1 * t * t + 0.984375 end
    end
}

-- ============================================================================
-- INTERPOLADORES
-- ============================================================================

local function hexToRgb(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

local function rgbToHex(r, g, b)
    return string.format("#%02x%02x%02x", 
        math.floor(math.min(255, math.max(0, r))),
        math.floor(math.min(255, math.max(0, g))),
        math.floor(math.min(255, math.max(0, b))))
end

local function interpolate(from, to, t, pType)
    if not from or not to then return to end
    
    -- Caso: Números puros u Opacidad
    if type(from) == "number" and type(to) == "number" then
        return from + (to - from) * t
    end

    -- Caso: Colores (#RRGGBB)
    if pType == "color" and type(from) == "string" and from:find("^#") then
        local r1, g1, b1 = hexToRgb(from)
        local r2, g2, b2 = hexToRgb(to)
        return rgbToHex(r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t)
    end

    -- Caso: Dimensiones (40px, 100%)
    if pType == "dimension" and type(from) == "string" then
        local n1, u1 = from:match("([%-]?[%d%.]+)(.*)")
        local n2, u2 = to:match("([%-]?[%d%.]+)(.*)")
        n1, n2 = tonumber(n1), tonumber(n2)
        if n1 and n2 and u1 == u2 then
            return (n1 + (n2 - n1) * t) .. u1
        end
    end

    -- Fallback: Switch abrupto al final
    return t < 1 and from or to
end

-- ============================================================================
-- CORE LOGIC
-- ============================================================================

--- Inicia o actualiza una animación para un elemento.
function AnimationManager.animate(element, props, duration, easing, onComplete)
    local uid = element:getUid()
    _active_animations[uid] = _active_animations[uid] or {}
    
    local easingFn = AnimationManager.EASING[easing or "linear"] or AnimationManager.EASING.linear
    
    for prop, targetValue in pairs(props) do
        local fromValue = element:getStyle(prop)
        
        -- Si ya hay una animación en curso para esta propiedad, usar su valor actual como 'from'
        -- para una transición suave.
        _active_animations[uid][prop] = {
            from        = fromValue,
            to          = targetValue,
            duration    = duration or 1.0,
            elapsed     = 0,
            easing      = easingFn,
            onComplete  = onComplete
        }
    end
end

--- Ticker global: actualiza todas las animaciones activas.
--- @param dt number Tiempo transcurrido desde el último tick en SEGUNDOS.
function AnimationManager.tick(dt)
    for uid, anims in pairs(_active_animations) do
        local element = nil -- Se obtendría de un registro global si fuera necesario, 
                            -- pero aquí almacenaremos la referencia del elemento en la animación.
                            -- (Mejorado abajo para capturar el elemento)
        
        local finishedProps = {}
        
        for prop, data in pairs(anims) do
            -- Capturar el elemento la primera vez (hack por simplicidad de hash)
            -- En una implementación real, tendríamos un NodeRegistry.
            -- Por ahora, pasamos el elemento en el 'animate'
        end
    end
end

-- ACTUALIZACIÓN: Rediseño del tick para ser más robusto con la captura de elementos.
function AnimationManager.tick(dt)
    for uid, anims in pairs(_active_animations) do
        local element = nil
        local hasActive = false

        for prop, data in pairs(anims) do
            data.elapsed = data.elapsed + dt
            local t = math.min(1.0, data.elapsed / data.duration)
            local easedT = data.easing(t)

            -- Obtener el tipo de propiedad para el interpolador
            local pType = StyleManager.VALID_PROPERTIES[prop] or "string"
            
            local currentVal = interpolate(data.from, data.to, easedT, pType)
            
            -- Aplicamos el estilo directamente al elemento (necesitamos la ref)
            -- Para simplicidad, asumo que el elemento está vivo y el parent (ReanUI) lo gestiona.
            if data.element then
                data.element:setStyle(prop, currentVal)
                if t >= 1 then
                    if data.onComplete then data.onComplete(data.element) end
                    anims[prop] = nil
                else
                    hasActive = true
                end
            end
        end

        if not hasActive then
            _active_animations[uid] = nil
        end
    end
end

-- Re-escribo animate para incluir la referencia al elemento
function AnimationManager.animate(element, props, duration, easing, onComplete)
    local uid = element:getUid()
    _active_animations[uid] = _active_animations[uid] or {}
    
    local easingFn = AnimationManager.EASING[easing or "linear"] or AnimationManager.EASING.linear
    
    for prop, targetValue in pairs(props) do
        local fromValue = element:getStyle(prop)
        _active_animations[uid][prop] = {
            element     = element,
            from        = fromValue,
            to          = targetValue,
            duration    = (duration or 1000) / 1000, -- Convertir a segundos
            elapsed     = 0,
            easing      = easingFn,
            onComplete  = onComplete
        }
    end
end

return AnimationManager
