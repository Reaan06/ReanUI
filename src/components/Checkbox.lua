-- src/components/Checkbox.lua
-- Componente Checkbox (ReanUI)
-- Gestiona estados booleanos y visuales.

local UIElement = require("src.core.UIElement")

local Checkbox = {}
Checkbox.__index = Checkbox
setmetatable(Checkbox, { __index = UIElement })

function Checkbox.new(checked, attrs)
    local self = UIElement.new("checkbox", attrs)
    setmetatable(self, Checkbox)

    -- Estado interno
    self._checked = checked == true

    -- Estilos Base Modernos (Cuadrado con borde)
    self:addClass("checkbox")
    self:setStyleSheet([[
        display: flex;
        width: 24px;
        height: 24px;
        border: 2px solid var(--rean-border);
        border-radius: 4px;
        background-color: var(--rean-bg-alt);
        cursor: pointer;
        transition: background-color 0.1s, border-color 0.1s;
        justify-content: center;
        align-items: center;
    ]])

    -- Inicializar estado visual
    if self._checked then
        self:addClass("is-checked")
        self:setStyle("background-color", "var(--rean-accent)")
        self:setStyle("border-color", "var(--rean-accent)")
    end

    return self
end

-- ============================================================================
-- GESTIÓN DE ESTADO
-- ============================================================================

function Checkbox:isChecked()
    return self._checked
end

function Checkbox:setChecked(bool)
    local newVal = bool == true
    if self._checked ~= newVal then
        self._checked = newVal
        
        -- Actualizar clases y estilos dinámicos
        if self._checked then
            self:addClass("is-checked")
            self:setStyle("background-color", "var(--rean-accent)")
            self:setStyle("border-color", "var(--rean-accent)")
        else
            self:removeClass("is-checked")
            self:setStyle("background-color", "var(--rean-bg-alt)")
            self:setStyle("border-color", "var(--rean-border)")
        end

        self:dispatchEvent("change", { checked = self._checked })
    end
    return self
end

function Checkbox:toggle()
    return self:setChecked(not self._checked)
end

-- ============================================================================
-- EVENTOS (Shorthands)
-- ============================================================================

--- Wrapper para facilitar la escucha del cambio de estado.
function Checkbox:onChange(callback)
    if type(callback) ~= "function" then return self end
    self:addEventListener("change", function(data)
        callback(self, data.checked)
    end)
    return self
end

-- Simulación manual de interactividad
function Checkbox:press()
    return self:toggle()
end

-- ============================================================================
-- OVERRIDES
-- ============================================================================

function Checkbox:debugPrint(indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    local status = self._checked and "[X]" or "[ ]"
    print(string.format('%s<Checkbox %s uid=%d>',
        prefix, status, self:getUid()))
end

return Checkbox
