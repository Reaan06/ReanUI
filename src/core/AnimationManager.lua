-- Gestiona interpolaciones de estilo con easing y ciclos de vida deterministas.
local StyleManager = require("src.core.StyleManager")

local AnimationManager = {}

-- Estructura:
-- _active_animations[uid] = { jobs = { job1, job2, ... } }
-- job = {
--   element_ref = weak_ref,
--   onComplete = function|nil,
--   properties = {
--     [prop] = { from, to, type, duration_s, elapsed_s, easing_fn }
--   }
-- }
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
        if t < 1 / d1 then
            return n1 * t * t
        elseif t < 2 / d1 then
            t = t - 1.5 / d1
            return n1 * t * t + 0.75
        elseif t < 2.5 / d1 then
            t = t - 2.25 / d1
            return n1 * t * t + 0.9375
        else
            t = t - 2.625 / d1
            return n1 * t * t + 0.984375
        end
    end
}

-- ============================================================================
-- HELPERS
-- ============================================================================

local function clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

local function makeWeakRef(value)
    return setmetatable({ value = value }, { __mode = "v" })
end

local function formatNumber(v)
    local rounded = math.floor(v + 0.5)
    if math.abs(v - rounded) < 1e-6 then
        return tostring(rounded)
    end

    local s = string.format("%.4f", v)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    return s
end

local function parseNumber(value)
    if type(value) == "number" then return value end
    if type(value) ~= "string" then return nil end
    return tonumber(value:match("^%s*(.-)%s*$"))
end

local function parseDimension(value)
    if type(value) ~= "string" then return nil end
    local numberPart, unit = value:match("^%s*([%+%-]?[%d%.]+)%s*([%a%%]+)%s*$")
    local n = tonumber(numberPart)
    if not n or not unit then return nil end
    if unit ~= "px" and unit ~= "%" then return nil end
    return n, unit
end

local function isHexColor(value)
    return type(value) == "string" and value:match("^#%x%x%x%x%x%x$") ~= nil
end

local function hexToRgb(hex)
    return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

local function rgbToHex(r, g, b)
    local function clampChannel(v)
        v = math.floor(v)
        if v < 0 then return 0 end
        if v > 255 then return 255 end
        return v
    end

    return string.format("#%02x%02x%02x", clampChannel(r), clampChannel(g), clampChannel(b))
end

local function interpolate(from, to, t, propType)
    if from == nil then return to end
    if to == nil then return from end

    -- 1) Colores HEX #RRGGBB
    if (propType == "color" or (isHexColor(from) and isHexColor(to))) and isHexColor(from) and isHexColor(to) then
        local r1, g1, b1 = hexToRgb(from)
        local r2, g2, b2 = hexToRgb(to)
        return rgbToHex(r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t)
    end

    -- 2) Dimensiones (px / %)
    local d1, u1 = parseDimension(from)
    local d2, u2 = parseDimension(to)
    if d1 and d2 and u1 == u2 and (propType == "dimension" or u1 == "px" or u1 == "%") then
        return formatNumber(d1 + (d2 - d1) * t) .. u1
    end

    -- 3) Valores numéricos puros (opacity, z-index, etc)
    local n1 = parseNumber(from)
    local n2 = parseNumber(to)
    if n1 and n2 and (propType == "number" or type(from) == "number" or type(to) == "number") then
        return formatNumber(n1 + (n2 - n1) * t)
    end

    -- Fallback: cambiar solo al finalizar.
    return (t >= 1) and to or from
end

local function hasProperties(properties)
    for _ in pairs(properties) do
        return true
    end
    return false
end

local function safeOnComplete(callback, element)
    if not callback then return end
    local ok, err = pcall(callback, element)
    if not ok then
        print("[ReanUI:AnimationError] onComplete failed: " .. tostring(err))
    end
end

local function removeOverlappingProperties(uid, props)
    local slot = _active_animations[uid]
    if not slot or not slot.jobs then return end

    local jobs = slot.jobs
    for j = #jobs, 1, -1 do
        local job = jobs[j]
        for prop in pairs(props) do
            job.properties[prop] = nil
        end
        if not hasProperties(job.properties) then
            table.remove(jobs, j)
        end
    end

    if #jobs == 0 then
        _active_animations[uid] = nil
    end
end

-- ============================================================================
-- API PÚBLICA
-- ============================================================================

--- Inicia una animación.
--- API pública: `duration_ms` en milisegundos.
--- Motor interno: segundos (float).
function AnimationManager.animate(element, props, duration_ms, easing, onComplete)
    if not element or type(props) ~= "table" then return false end
    if not element.getUid or not element.setStyle or not element.getStyle then return false end

    local uid = element:getUid()
    if not uid then return false end

    local duration_s = (tonumber(duration_ms) or 0) / 1000
    if duration_s < 0 then duration_s = 0 end

    local easingFn = AnimationManager.EASING[easing or "linear"] or AnimationManager.EASING.linear

    -- Reemplazar conflictos de propiedad en animaciones activas del mismo elemento.
    removeOverlappingProperties(uid, props)

    -- Duración cero: aplicar inmediato y completar.
    if duration_s == 0 then
        for prop, target in pairs(props) do
            element:setStyle(prop, target)
        end
        safeOnComplete(onComplete, element)
        return true
    end

    local job = {
        element_ref = makeWeakRef(element),
        onComplete = onComplete,
        properties = {}
    }

    for prop, target in pairs(props) do
        job.properties[prop] = {
            from = element:getStyle(prop),
            to = target,
            type = StyleManager.VALID_PROPERTIES[prop] or "string",
            duration_s = duration_s,
            elapsed_s = 0,
            easing_fn = easingFn
        }
    end

    if not hasProperties(job.properties) then
        safeOnComplete(onComplete, element)
        return true
    end

    local slot = _active_animations[uid]
    if not slot then
        slot = { jobs = {} }
        _active_animations[uid] = slot
    end
    slot.jobs[#slot.jobs + 1] = job

    return true
end

--- Actualiza todas las animaciones activas.
--- `dt` debe venir en SEGUNDOS para precisión de sub-frame.
--- Determinista: solo procesa `_active_animations`.
function AnimationManager.tick(dt)
    local dt_s = tonumber(dt)
    if not dt_s or dt_s <= 0 then return 0 end

    local active_count = 0

    for uid, slot in pairs(_active_animations) do
        local jobs = slot.jobs

        for j = #jobs, 1, -1 do
            local job = jobs[j]
            local element = job.element_ref and job.element_ref.value or nil

            if not element or (element.isDestroyed and element:isDestroyed()) then
                table.remove(jobs, j)
            else
                local finished = true

                for prop, anim in pairs(job.properties) do
                    anim.elapsed_s = math.min(anim.duration_s, anim.elapsed_s + dt_s)
                    local progress = (anim.duration_s > 0) and (anim.elapsed_s / anim.duration_s) or 1
                    progress = clamp01(progress)

                    local eased = anim.easing_fn and anim.easing_fn(progress) or progress
                    eased = clamp01(eased)

                    local value = interpolate(anim.from, anim.to, eased, anim.type)
                    if value ~= nil then
                        element:setStyle(prop, value)
                    end

                    if progress >= 1 then
                        job.properties[prop] = nil
                    else
                        finished = false
                    end
                end

                if finished or not hasProperties(job.properties) then
                    table.remove(jobs, j)
                    safeOnComplete(job.onComplete, element)
                else
                    active_count = active_count + 1
                end
            end
        end

        if #jobs == 0 then
            _active_animations[uid] = nil
        end
    end

    return active_count
end

-- Debug/diagnóstico opcional.
function AnimationManager.getActiveCount()
    local total = 0
    for _, slot in pairs(_active_animations) do
        total = total + #slot.jobs
    end
    return total
end

return AnimationManager
