local UIElement = require("src.core.UIElement")

local BaseComponent = {}
BaseComponent.__index = BaseComponent
setmetatable(BaseComponent, {__index = UIElement})

function BaseComponent:new(o)
    o = UIElement:new(o)
    setmetatable(o, self)
    return o
end

return BaseComponent
