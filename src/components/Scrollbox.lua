-- src/components/Scrollbox.lua
-- Contenedor con soporte para scroll y clipping.

local UIElement = require("src.core.UIElement")
local ThemeManager = require("src.theme.ThemeManager")

local Scrollbox = {}
Scrollbox.__index = Scrollbox
setmetatable(Scrollbox, { __index = UIElement })

function Scrollbox.new(attrs)
    local self = UIElement.new("container", attrs)
    setmetatable(self, Scrollbox)

    -- Estado de scroll
    self._scroll_x = 0
    self._scroll_y = 0
    self._max_scroll_y = 0
    
    -- Estilo por defecto (overflow hidden es CLAVE)
    self:setStyleSheet([[
        display: flex;
        flex-direction: column;
        overflow: hidden;
        background-color: var(--bg-secondary, #2a2a2a);
        border-radius: 8px;
        padding: 5px;
    ]])

    -- Escuchar evento de rueda (bubbling desde InteractionManager)
    self:addEventListener("mousewheel", function(e)
        self:scroll(e.data.delta * -20) -- Sensibilidad del scroll
        e:stopPropagation()
    end)

    return self
end

function Scrollbox:appendChild(child)
    -- Los hijos de un Scrollbox no deben encogerse, de lo contrario
    -- el Flexbox intentará meterlos todos en el espacio visible.
    if child.setStyle then
        child:setStyle("flex-shrink", 0)
    end
    return UIElement.appendChild(self, child)
end

function Scrollbox:scroll(delta)
    -- El límite real de scroll es (altura contenido - altura contenedor)
    local layout = self._layout
    if not layout then return end
    
    -- El FlexboxLayout guarda el tamaño total del contenido en _content_h
    local content_h = self._content_h or 0
    local view_h = layout.h
    
    self._max_scroll_y = math.max(0, content_h - view_h)
    
    local new_scroll = self._scroll_y + delta
    self._scroll_y = math.max(0, math.min(self._max_scroll_y, new_scroll))
    
    -- Al cambiar el scroll, debemos marcar como "dirty" para actualizar el Renderer 
    -- y forzar un nuevo layout de los hijos (recalculo de sus posiciones absolutas)
    self:markDirty()
end

--- Sobrecarga del renderizado (opcional si queremos añadir la barra visual)
--- En ReanUI el Renderer usa la lista de hijos, por lo que podemos añadir 
--- un nodo interno tipo "scrollbar" o manejarlo en el Renderer final.
--- Por ahora lo mantenemos simple: el Renderer dibujará hijos hitteando el clip.

return Scrollbox
