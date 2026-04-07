-- src/components/ProgressBar.lua
-- Componente ProgressBar (ReanUI)
-- Gestiona una barra de carga con un track externo y un fill interno.

local UIElement = require("src.core.UIElement")
local ThemeManager = require("src.theme.ThemeManager")

local ProgressBar = {}
ProgressBar.__index = ProgressBar
setmetatable(ProgressBar, { __index = UIElement })

function ProgressBar.new(value, attrs)
    local self = UIElement.new("progress", attrs)
    setmetatable(self, ProgressBar)

    -- Estado interno (0 a 100)
    local initialValue = tonumber(value) or 0
    self._value = math.max(0, math.min(100, initialValue))

    -- 1. Estilos del TRACK (Contenedor externo)
    self:addClass("progress-track")
    self:setStyleSheet([[
        display: flex;
        width: 100%;
        height: 12px;
        background-color: var(--rean-bg-alt);
        border-radius: 6px;
        overflow: hidden;
        padding: 0px;
    ]])

    -- 2. Crear Nodo FILL (Relleno interno)
    self._fill = UIElement.new("div", { class = "progress-fill" })
    
    -- Nota: En el nuevo sistema, el fill simplemente usa var() 
    -- y el StyleManager del nodo hijo lo resuelve.
    self._fill:setStyle("background-color", "var(--primary-color)")
    self._fill:setStyle("height", "100%")
    self._fill:setStyle("border-radius", "6px")
    self._fill:setStyle("transition", "width 0.3s ease-out")
    
    -- Ajustar ancho inicial del fill
    self._fill:setStyle("width", self._value .. "%")
    
    -- Vincular fill como hijo único
    self:appendChild(self._fill)

    return self
end

-- ============================================================================
-- GESTIÓN DE VALOR
-- ============================================================================

function ProgressBar:getProgress()
    return self._value
end

function ProgressBar:setProgress(value)
    local newVal = math.max(0, math.min(100, tonumber(value or 0)))
    
    if self._value ~= newVal then
        self._value = newVal
        
        -- Actualizar ancho del nodo hijo FILL
        self._fill:setStyle("width", self._value .. "%")
        
        -- Notificar cambio
        self:dispatchEvent("change", { value = self._value })
    end
    
    return self
end

-- ============================================================================
-- OVERRIDES
-- ============================================================================

function ProgressBar:debugPrint(indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    print(string.format('%s<ProgressBar value=%d%% uid=%d>',
        prefix, self._value, self:getUid()))
    
    -- Los hijos se imprimen recursivamente por UIElement:debugPrint
end

return ProgressBar
