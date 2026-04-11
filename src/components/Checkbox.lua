local UIElement = require("src.core.UIElement")

local Checkbox = {}
Checkbox.__index = Checkbox
setmetatable(Checkbox, {__index = UIElement})

function Checkbox:new(x, y, w, h, props)
    props = props or {}
    local o = UIElement:new({
        x = x or 0, y = y or 0,
        width = w or 20, height = h or 20,
        style = props.style or {}
    })
    
    o.checked = props.checked or false
    o.type = "Checkbox"
    
    setmetatable(o, self)
    o:updateStyle()
    return o
end

function Checkbox:onClick()
    self.checked = not self.checked
    self._update = true
    triggerEvent("onCheckboxChange", self, self.checked)
end

-- El Renderer usará o.checked para dibujar el símbolo
return Checkbox
