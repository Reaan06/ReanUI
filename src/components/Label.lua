local UIElement = require("src.core.UIElement")

local Label = {}
Label.__index = Label
setmetatable(Label, {__index = UIElement})

function Label:new(x, y, w, h, props)
    props = props or {}
    
    local o = UIElement:new({
        x = x or 0,
        y = y or 0,
        width = w or 100,
        height = h or 20,
        style = props.style or {}
    })
    
    o.text = props.text or "Label"
    o.type = "Label"
    
    setmetatable(o, self)
    
    -- Los labels por defecto no tienen fondo
    if o.style.color == nil then o.style.color = tocolor(255, 255, 255, 0) end
    
    o:updateStyle()
    
    return o
end

return Label
