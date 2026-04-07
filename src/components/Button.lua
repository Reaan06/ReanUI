-- src/components/Button.lua
-- Componente Button PRO (ReanUI)
-- Soporta estados, debouncing, temas y transiciones.

local UIElement = require("src.core.UIElement")

local Button = {}
Button.__index = Button
setmetatable(Button, { __index = UIElement })

local function nowMs()
    if type(getTickCount) == "function" then
        return getTickCount()
    end
    return os.time() * 1000
end

-- Configuración por defecto
Button.DEBOUNCE_MS = 300

function Button.new(label, icon, attrs)
    local self = UIElement.new("button", attrs)
    setmetatable(self, Button)

    -- Estado interno
    self._label         = tostring(label or "")
    self._icon          = icon or nil
    self._disabled      = false
    self._last_click_ms = 0
    
    -- Flags de interactividad (gestionados externamente o vía métodos)
    self._is_hovered    = false
    self._is_active     = false

    -- Estilos Base Modernos
    self:addClass("btn")
    self:setStyleSheet([[
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 8px;
        padding: 10px 20px;
        height: 40px;
        border-radius: 8px;
        transition: background-color 0.2s, transform 0.1s, opacity 0.2s;
        cursor: pointer;
        background-color: var(--rean-accent);
        color: var(--rean-text);
        border: none;
    ]])
    
    self:_attachInternalListeners()
    
    return self
end

function Button:_attachInternalListeners()
    self:addEventListener("mouseenter", function(e)
        if self._disabled then return end
        self._is_hovered = true
        self:addClass("is-hover")
        self:setStyle("background-color", "var(--rean-accent-hover)")
    end)

    self:addEventListener("mouseleave", function(e)
        if self._disabled then return end
        self._is_hovered = false
        self._is_active = false
        self:removeClass("is-hover")
        self:removeClass("is-active")
        self:setStyle("background-color", "var(--rean-accent)")
        self:setStyle("transform", "scale(1.0)")
    end)

    self:addEventListener("mousedown", function(e)
        if self._disabled then return end
        self._is_active = true
        self:addClass("is-active")
        self:setStyle("background-color", "var(--rean-accent-active)")
        self:setStyle("transform", "scale(0.95)")
    end)

    self:addEventListener("mouseup", function(e)
        if self._disabled then return end
        self._is_active = false
        self:removeClass("is-active")
        self:setStyle("transform", "scale(1.0)")
        self:setStyle("background-color", self._is_hovered and "var(--rean-accent-hover)" or "var(--rean-accent)")
    end)
end

-- ============================================================================
-- PROPIEDADES Y CONTENIDO
-- ============================================================================

function Button:getLabel()
    return self._label
end

function Button:setLabel(text)
    self._label = tostring(text)
    self:dispatchEvent("contentchange", { label = self._label })
    return self
end

function Button:setIcon(path)
    self._icon = path
    self:dispatchEvent("contentchange", { icon = self._icon })
    return self
end

function Button:applyTheme(theme_name)
    -- Deprecated: El tema ahora es global en ReanUI.
    return self
end

-- ============================================================================
-- GESTIÓN DE ESTADOS INTERNOS
-- ============================================================================

function Button:setDisabled(disabled)
    self._disabled = disabled
    if disabled then
        self:addClass("is-disabled")
        self:setStyle("background-color", "var(--rean-border)")
        self:setStyle("color", "var(--rean-text-muted)")
        self:setStyle("cursor", "not-allowed")
        self:setStyle("opacity", "0.6")
    else
        self:removeClass("is-disabled")
        self:setStyle("background-color", "var(--rean-accent)")
        self:setStyle("color", "var(--rean-text)")
        self:setStyle("cursor", "pointer")
        self:setStyle("opacity", "1.0")
    end
    return self
end

-- Compatibilidad API legacy
function Button:disable()
    return self:setDisabled(true)
end

function Button:enable()
    return self:setDisabled(false)
end

function Button:getState()
    if self._disabled then return "disabled" end
    if self._is_active then return "active" end
    if self._is_hovered then return "hover" end
    return "normal"
end

function Button:onMouseEnter()
    if self._disabled then return self end
    self._is_hovered = true
    self:addClass("is-hover")
    self:setStyle("background-color", "var(--rean-accent-hover)")
    return self
end

function Button:onMouseLeave()
    if self._disabled then return self end
    self._is_hovered = false
    self._is_active = false
    self:removeClass("is-hover")
    self:removeClass("is-active")
    self:setStyle("background-color", "var(--rean-accent)")
    self:setStyle("transform", "scale(1.0)")
    return self
end

function Button:onMouseDown()
    if self._disabled then return self end
    self._is_active = true
    self:addClass("is-active")
    self:setStyle("background-color", "var(--rean-accent-active)")
    self:setStyle("transform", "scale(0.95)")
    return self
end

function Button:onMouseUp()
    if self._disabled then return self end
    self._is_active = false
    self:removeClass("is-active")
    self:setStyle("transform", "scale(1.0)")
    self:setStyle("background-color", self._is_hovered and "var(--rean-accent-hover)" or "var(--rean-accent)")
    return self
end



-- ============================================================================
-- EVENTOS Y CALLBACKS
-- ============================================================================

--- Wrapper con soporte para Debouncing y Callbacks Asíncronos.
--- @param callback function
function Button:onClick(callback)
    if type(callback) ~= "function" then return self end
    
    self:addEventListener("click", function(data)
        -- 1. Verificación de cooldown (Debounce)
        local now = nowMs()
        if (now - self._last_click_ms) < Button.DEBOUNCE_MS then
            return -- Ignorar clic muy rápido
        end
        self._last_click_ms = now
        
        -- 2. Ejecución del callback
        -- Soporta callbacks que bloquean o corrutinas si el host lo implementa
        callback(self, data)
    end)
    return self
end

--- Simulación manual de presión completa (Down + Up + Click)
--- En el nuevo sistema, el InteractionManager llama a este método al detectar un ciclo Up-Down.
function Button:press()
    if self._disabled then return self end
    
    -- El debouncing y el despacho del evento 'click' 
    -- ocurrirán aquí si queremos centralizar la lógica de negocio del clic.
    local now = nowMs()
    if (now - self._last_click_ms) < Button.DEBOUNCE_MS then
        return self
    end
    self._last_click_ms = now

    self:dispatchEvent("click", { 
        timestamp = now, 
        uid = self:getUid(),
        label = self._label 
    })
    return self
end

-- ============================================================================
-- OVERRIDES
-- ============================================================================

function Button:debugPrint(indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    local status = self._disabled and "[DISABLED]" or "[ACTIVE]"
    print(string.format('%s<Button "%s" %s uid=%d theme=%s>',
        prefix, self._label, status, self:getUid(), "current"))
end

return Button
