-- src/components/Container.lua
-- Contenedor genérico de layout. Soporta flex-direction row y column.

local UIElement = require("src.core.UIElement")

local Container = {}
Container.__index = Container
setmetatable(Container, { __index = UIElement })

function Container.new(direction, attrs)
    local self = UIElement.new("div", attrs)
    setmetatable(self, Container)

    direction = direction or "column"
    self:setStyle("flex-direction", direction)
    return self
end

function Container:setDirection(dir)
    if dir ~= "row" and dir ~= "column" then
        error("[ReanUI:Container] direction must be 'row' or 'column'")
    end
    self:setStyle("flex-direction", dir)
    return self
end

function Container:getDirection()
    return self:getStyle("flex-direction")
end

return Container
