UIElement = {}
UIElement.__index = UIElement

function UIElement:new(o)
    o = o or {}
    setmetatable(o, self)
    return o
end

return UIElement
