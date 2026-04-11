local Color = require("src.utils.Color")

local ShapeGenerator = {}

-- Genera un SVG de rectángulo redondeado
function ShapeGenerator.createRoundedRectangle(w, h, r, color, border, borderColor)
    local hexColor = Color.toHex(color)
    local alpha = Color.getAlpha(color)
    
    local borderStr = ""
    if border and border > 0 then
        local hexBorder = Color.toHex(borderColor or color)
        local borderAlpha = Color.getAlpha(borderColor or color)
        borderStr = string.format([[stroke="%s" stroke-width="%d" stroke-opacity="%f"]], hexBorder, border, borderAlpha)
    end
    
    -- Ajustamos un poco el tamaño para evitar recortes en los bordes de la textura
    local svg = string.format([[
        <svg width="%d" height="%d">
            <rect x="%f" y="%f" rx="%d" ry="%d" width="%f" height="%f" 
            fill="%s" fill-opacity="%f" %s />
        </svg>
    ]], w, h, border/2, border/2, r, r, w-border, h-border, hexColor, alpha, borderStr)
    
    return svg
end

return ShapeGenerator
