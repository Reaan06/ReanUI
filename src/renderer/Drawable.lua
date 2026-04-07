-- src/renderer/Drawable.lua
-- Definición de primitivas gráficas de ReanUI.

local Drawable = {}
Drawable.__index = Drawable

function Drawable.new(type, data)
    local self = setmetatable({
        type = type,
        data = data or {},
        z_index = 0,
        opacity = 1.0,
        clip = nil, -- {x, y, w, h}
        shader = nil, -- shaderPath
        shaderParams = nil
    }, Drawable)
    return self
end

-- ============================================================================
-- TIPOS DE DRAWABLES (Factory Methods)
-- ============================================================================

function Drawable.Rect(x, y, w, h, color, radius)
    return Drawable.new("rect", {
        x = x, y = y, w = w, h = h,
        color = color or "#ffffff",
        radius = radius or 0
    })
end

function Drawable.Text(x, y, text, color, size, font)
    return Drawable.new("text", {
        x = x, y = y,
        text = text or "",
        color = color or "#ffffff",
        size = size or 16,
        font = font or "default"
    })
end

function Drawable.Image(x, y, w, h, path)
    return Drawable.new("image", {
        x = x, y = y, w = w, h = h,
        path = path
    })
end

function Drawable.Gradient(x, y, w, h, colors, direction)
    return Drawable.new("gradient", {
        x = x, y = y, w = w, h = h,
        colors = colors or {"#ffffff", "#000000"},
        direction = direction or "vertical"
    })
end

-- ============================================================================
-- UTILS
-- ============================================================================

function Drawable:setZIndex(z)
    self.z_index = tonumber(z) or 0
end

function Drawable:setClip(rect)
    self.clip = rect
end

function Drawable:setShader(path, params)
    self.shader = path
    self.shaderParams = params
end

return Drawable
