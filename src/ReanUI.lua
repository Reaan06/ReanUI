local Renderer = require("src.renderer.Renderer")
local StateManager = require("src.core.StateManager")
local ThemeManager = require("src.theme.ThemeManager")

ReanUI = {
    roots = {},
    renderer = Renderer:new(),
    _initialized = false
}

-- Exponer ThemeManager
ReanUI.Theme = ThemeManager

function ReanUI:init()
    if self._initialized then return end
    
    addEventHandler("onClientRender", root, function()
        StateManager.update(self.roots)
        self.renderer:render(self.roots)
    end)
    
    self._initialized = true
    outputDebugString("[ReanUI] Motor CSS V2 e interacciones iniciado.")
end

function ReanUI:create(className, x, y, w, h, props)
    props = props or {}
    
    local class = require("src.components." .. (className or "Container"))
    
    -- Inyectar propiedades de ReanUI
    local element = class:new(x, y, w, h, props.style)
    element.id = props.id
    element.className = props.className
    element.type = className
    
    -- Si no tiene padre, lo registramos como raíz
    if not element.parent then
        table.insert(self.roots, element)
    end
    
    element:updateStyle()
    
    return element
end

function ReanUI:addElement(element)
    if not element.parent then
        table.insert(self.roots, element)
    end
end

return ReanUI
