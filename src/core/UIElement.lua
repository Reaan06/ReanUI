local CSSProcessor = require("src.core.CSSProcessor")

local UIElement = {}
UIElement.__index = UIElement

function UIElement:new(o)
    o = o or {}
    
    o.id = o.id or nil
    o.className = o.className or nil
    o.type = o.type or "UIElement"
    
    o.style = o.style or {}
    o.children = o.children or {}
    o.parent = o.parent or nil
    
    o.width = o.width or 100
    o.height = o.height or 100
    o.x = o.x or 0
    o.y = o.y or 0
    
    o.visible = o.visible == nil and true or o.visible
    o.disabled = o.disabled == nil and false or o.disabled
    o.hovered = false
    
    o._update = true
    o.computedStyle = { width = 0, height = 0, absX = 0, absY = 0 }
    
    setmetatable(o, self)
    o:updateStyle()
    
    return o
end

function UIElement:addChild(child)
    if not child then return false end
    if child.parent then child.parent:removeChild(child) end
    child.parent = self
    table.insert(self.children, child)
    self._update = true
    child:updateStyle()
    return true
end

function UIElement:addChildTo(parent)
    if not parent then return false end
    parent:addChild(self)
    return self
end

function UIElement:removeChild(child)
    for i, v in ipairs(self.children) do
        if v == child then
            table.remove(self.children, i)
            child.parent = nil
            self._update = true
            return true
        end
    end
    return false
end

function UIElement:updateStyle()
    self.computedStyle = CSSProcessor.computeStyle(self)
    for _, child in ipairs(self.children) do child:updateStyle() end
    self._update = true
end

function UIElement:setProperty(key, value)
    if self.style[key] ~= value then
        self.style[key] = value
        self:updateStyle()
    end
end

function UIElement:onMouseEnter() self.hovered = true; self:updateStyle() end
function UIElement:onMouseLeave() self.hovered = false; self:updateStyle() end

return UIElement
