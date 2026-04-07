-- src/renderer/Canvas.lua
-- Abstracción de la superficie de dibujo.
-- Este archivo es el puente con el motor gráfico (Love2D, MTA, etc).

local Canvas = {}
Canvas.__index = Canvas

function Canvas.new(width, height, backend)
    local self = setmetatable({
        width = width or 1920,
        height = height or 1080,
        _active_clip = nil,
        _backend = backend or {} -- Tabla con funciones drawRect, drawText, etc.
    }, Canvas)
    return self
end

-- ============================================================================
-- MÉTODOS DE DIBUJO (Delegación al Backend)
-- ============================================================================

function Canvas:drawRect(x, y, w, h, color, radius)
    if self._backend.drawRect then
        self._backend.drawRect(x, y, w, h, color, radius)
    end
end

function Canvas:drawText(x, y, text, color, size, font)
    if self._backend.drawText then
        self._backend.drawText(x, y, text, color, size, font)
    end
end

function Canvas:drawImage(x, y, w, h, path)
    if self._backend.drawImage then
        self._backend.drawImage(x, y, w, h, path)
    end
end

function Canvas:drawShadow(x, y, w, h, radius, blur, color)
    if self._backend.drawShadow then
        self._backend.drawShadow(x, y, w, h, radius, blur, color)
    end
end

-- ============================================================================
-- ESTADO GRÁFICO
-- ============================================================================

function Canvas:setClip(x, y, w, h)
    if x and y and w and h then
        self._active_clip = { x = x, y = y, w = w, h = h }
        -- love.graphics.setScissor(x, y, w, h)
    else
        self._active_clip = nil
        -- love.graphics.setScissor()
    end
end

function Canvas:getClip()
    return self._active_clip
end

-- ============================================================================
-- UTILS
-- ============================================================================

--- Convierte un color Hex "#RRGGBB" o "#RRGGBBAA" a valores 0-1.
function Canvas:parseColor(hex)
    if not hex or type(hex) ~= "string" then return 1, 1, 1, 1 end
    hex = hex:gsub("#", "")
    local r = tonumber("0x"..hex:sub(1,2)) / 255
    local g = tonumber("0x"..hex:sub(3,4)) / 255
    local b = tonumber("0x"..hex:sub(5,6)) / 255
    local a = hex:len() >= 8 and (tonumber("0x"..hex:sub(7,8)) / 255) or 1.0
    return r, g, b, a
end

return Canvas
