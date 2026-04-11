local ThemeManager = require("src.theme.ThemeManager")
local FontManager = require("src.utils.FontManager")

local CSSProcessor = {}

local sx, sy = guiGetScreenSize()
local remBase = 16

function CSSProcessor.resolveValue(value, contextSize)
    if type(value) == "number" then
        return value
    elseif type(value) == "string" then
        local varName = value:match("^var%((%-%-%a+%-?%a*)%)$")
        if varName then return ThemeManager.getVariable(varName) or 0 end
        
        local num, unit = value:match("^(%-?%d+%.?%d*)(%a?%%?)$")
        if not num or not unit or unit == "" then return tonumber(value) or 0 end
        
        num = tonumber(num)
        if unit == "%" then return (num / 100) * (contextSize or 0)
        elseif unit == "vw" then return (num / 100) * sx
        elseif unit == "vh" then return (num / 100) * sy
        elseif unit == "rem" then return num * remBase
        elseif unit == "px" then return num end
    end
    return value
end

function CSSProcessor.computeStyle(element)
    local style = ThemeManager.getStyleForElement(element)
    local parent = element.parent
    local pW = parent and parent.computedStyle.width or sx
    local pH = parent and parent.computedStyle.height or sy
    
    local computed = {
        x = CSSProcessor.resolveValue(style.x or 0, pW),
        y = CSSProcessor.resolveValue(style.y or 0, pH),
        width = CSSProcessor.resolveValue(style.width or 100, pW),
        height = CSSProcessor.resolveValue(style.height or 100, pH),
        color = CSSProcessor.resolveValue(style.color or tocolor(255, 255, 255, 255)),
        hoverColor = CSSProcessor.resolveValue(style.hoverColor or style.color),
        opacity = CSSProcessor.resolveValue(style.opacity or 1),
        borderRadius = CSSProcessor.resolveValue(style.borderRadius or 0, 100),
        border = CSSProcessor.resolveValue(style.border or 0, 100),
        borderColor = CSSProcessor.resolveValue(style.borderColor or style.color or tocolor(255, 255, 255, 255)),
        
        -- Propiedades de Texto
        textColor = CSSProcessor.resolveValue(style.textColor or tocolor(255, 255, 255, 255)),
        fontSize = CSSProcessor.resolveValue(style.fontSize or 10, 100),
        font = style.font or FontManager.getDefault(),
        textAlign = style.textAlign or "left",
        verticalAlign = style.verticalAlign or "top",
        textShadow = style.textShadow or false,
        colorCoded = style.colorCoded == nil and true or style.colorCoded
    }
    
    if element.hovered and style.hoverColor then
        computed.color = computed.hoverColor
    end
    
    local absX, absY = computed.x, computed.y
    if parent and parent.computedStyle then
        absX = parent.computedStyle.absX + computed.x
        absY = parent.computedStyle.absY + computed.y
    end
    
    computed.absX = absX
    computed.absY = absY
    
    return computed
end

return CSSProcessor
