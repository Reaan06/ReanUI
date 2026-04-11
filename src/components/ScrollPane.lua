local UIElement = require("src.core.UIElement")

local ScrollPane = {}
ScrollPane.__index = ScrollPane
setmetatable(ScrollPane, {__index = UIElement})

function ScrollPane:new(x, y, w, h, props)
    props = props or {}
    local o = UIElement:new({
        x = x or 0, y = y or 0,
        width = w or 200, height = h or 200,
        style = props.style or {}
    })
    
    o.type = "ScrollPane"
    o.scrollX = 0
    o.scrollY = 0
    o.contentWidth = props.contentWidth or w
    o.contentHeight = props.contentHeight or h
    
    setmetatable(o, self)
    
    -- Los ScrollPanes siempre necesitan RenderTarget para el clipping
    o._update = true
    o:updateStyle()
    return o
end

function ScrollPane:addChild(child)
    UIElement.addChild(self, child)
    -- Al añadir un hijo, recalculamos el tamaño del contenido si es necesario
    -- Por ahora manual o automático basado en los hijos
    self:updateContentSize()
end

function ScrollPane:updateContentSize()
    local maxW, maxH = self.width, self.height
    for _, child in ipairs(self.children) do
        maxW = math.max(maxW, child.x + child.width)
        maxH = math.max(maxH, child.y + child.height)
    end
    self.contentWidth = maxW
    self.contentHeight = maxH
end

function ScrollPane:scrollTo(x, y)
    self.scrollX = math.max(0, math.min(x, self.contentWidth - self.width))
    self.scrollY = math.max(0, math.min(y, self.contentHeight - self.height))
    self._update = true
end

-- El Renderer usará scrollX/Y para desplazar el dibujado dentro del RT
return ScrollPane
