local UIElement = require("src.core.UIElement")

local Container = {}
Container.__index = Container
setmetatable(Container, {__index = UIElement})

function Container:new(x, y, w, h, style)
    -- En ReanUI V2, pasamos todo al constructor de UIElement via el objeto style
    local o = UIElement:new({
        x = x or 0,
        y = y or 0,
        width = w or 100,
        height = h or 100,
        style = style or {}
    })
    
    setmetatable(o, self)
    
    -- Forzar actualización inicial
    o:updateStyle()
    
    return o
end

return Container
