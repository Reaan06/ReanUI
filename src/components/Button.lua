local UIElement = require("src.core.UIElement")

local Button = {}
Button.__index = Button
setmetatable(Button, {__index = UIElement})

function Button:new(x, y, w, h, props)
    props = props or {}
    
    local o = UIElement:new({
        x = x or 0,
        y = y or 0,
        width = w or 100,
        height = h or 40,
        style = props.style or {}
    })
    
    o.text = props.text or "Button"
    o.type = "Button"
    
    setmetatable(o, self)
    
    -- Ajustar estilos por defecto de botón
    if not o.style.textAlign then o.style.textAlign = "center" end
    if not o.style.verticalAlign then o.style.verticalAlign = "center" end
    
    o:updateStyle()
    
    return o
end

return Button
