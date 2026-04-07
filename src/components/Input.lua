-- src/components/Input.lua
-- Componente Input PRO (ReanUI)
-- Soporta tipos de texto, validación, sanitización y manejo de estados.

local UIElement = require("src.core.UIElement")
local Validators = require("src.validators.InputValidators")

local Input = {}
Input.__index = Input
setmetatable(Input, { __index = UIElement })

-- Configuración por defecto
Input.TYPES = {
    TEXT     = "text",
    EMAIL    = "email",
    PASSWORD = "password",
    NUMBER   = "number",
    TEL      = "tel"
}

function Input.new(inputType, attrs)
    local self = UIElement.new("input", attrs)
    setmetatable(self, Input)

    -- Configuración Inicial
    self._type        = inputType or Input.TYPES.TEXT
    self._value       = ""
    self._placeholder = ""
    self._maxlength   = 0   -- 0 = Sin límite
    self._required    = false
    self._readonly    = false

    -- Estado de Validación
    self._is_focused  = false
    self._is_valid    = true
    self._error_msg   = ""

    -- Estilos Base Modernos
    self:addClass("input")
    self:setStyle("display", "flex")
    self:setStyle("align-items", "center")
    self:setStyle("padding", "10px 15px")
    self:setStyle("height", "45px")
    self:setStyle("border", "2px solid var(--rean-border)")
    self:setStyle("border-radius", "8px")
    self:setStyle("background-color", "var(--rean-bg-alt)")
    self:setStyle("color", "var(--rean-text)")
    self:setStyle("font-size", "16px")
    self:setStyle("width", "100%")
    self:setStyle("transition", "border-color 0.2s, background-color 0.2s")
    self:setStyle("cursor", "text")

    return self
end

-- ============================================================================
-- PROPIEDADES Y CONTENIDO
-- ============================================================================

function Input:getValue()
    return self._value
end

function Input:setValue(val)
    if self._readonly then return self end

    -- 1. Sanitizar entrada para seguridad
    local cleanVal = Validators.sanitize(val)

    -- 2. Validar Max Length
    if self._maxlength > 0 and #cleanVal > self._maxlength then
        cleanVal = cleanVal:sub(1, self._maxlength)
    end

    -- 3. Actualizar valor y disparar eventos
    local oldVal = self._value
    self._value = cleanVal

    if oldVal ~= self._value then
        self:dispatchEvent("change", { value = self._value, old_value = oldVal })
        self:validate() -- Validar al cambiar el valor
    end

    return self
end

function Input:setPlaceholder(text)
    self._placeholder = tostring(text or "")
    return self
end

function Input:setRequired(required)
    self._required = required == true
    return self
end

function Input:setMaxLength(n)
    self._maxlength = tonumber(n) or 0
    return self
end

function Input:setReadonly(bool)
    self._readonly = bool == true
    self:setStyle("opacity", self._readonly and "0.6" or "1.0")
    self:setStyle("cursor", self._readonly and "not-allowed" or "text")
    return self
end

-- ============================================================================
-- VALIDACIÓN
-- ============================================================================

--- Realiza la validación según el tipo y disparar feedback visual.
--- @return boolean, string (válido, mensaje_error)
function Input:validate()
    local val = self._value
    local isValid = true
    local msg = ""

    -- 1. Validación de Obligatoriedad
    if self._required and (not val or val == "") then
        isValid = false
        msg = "Este campo es requerido."
    end

    -- 2. Validación de Tipo
    if isValid and val ~= "" then
        if self._type == Input.TYPES.EMAIL then
            if not Validators.isEmail(val) then
                isValid = false
                msg = "Formato de email inválido."
            end
        elseif self._type == Input.TYPES.NUMBER then
            if not Validators.isNumber(val) then
                isValid = false
                msg = "Solo se permiten números."
            end
        elseif self._type == Input.TYPES.TEL then
            if not Validators.isTel(val) then
                isValid = false
                msg = "Formato de teléfono inválido."
            end
        end
    end

    -- 3. Aplicar Estados Visuales
    self._is_valid = isValid
    self._error_msg = msg

    if not self._is_valid then
        self:addClass("is-error")
        self:removeClass("is-success")
        self:setStyle("border-color", "var(--rean-error)")
    else
        self:removeClass("is-error")
        if val ~= "" then
            self:addClass("is-success")
            self:setStyle("border-color", "var(--rean-success)")
        else
            self:removeClass("is-success")
            self:setStyle("border-color", self._is_focused and "var(--rean-accent-hover)" or "var(--rean-border)")
        end
    end

    self:dispatchEvent("validate", { is_valid = isValid, error_msg = msg })
    return isValid, msg
end

function Input:isValid()
    return self:validate()
end

function Input:getError()
    return self._error_msg
end

-- ============================================================================
-- EVENTOS DE INTERACCIÓN
-- ============================================================================

function Input:onFocus()
    if self._readonly then return end
    self._is_focused = true
    self:addClass("is-focused")
    if self._is_valid then
        self:setStyle("border-color", "var(--rean-accent-hover)")
    end
    self:dispatchEvent("focus")
end

function Input:onBlur()
    self._is_focused = false
    self:removeClass("is-focused")
    if self._is_valid then
        self:setStyle("border-color", "var(--rean-border)")
    end
    self:validate() -- Validar al salir
    self:dispatchEvent("blur")
end

-- Simulación de entrada de texto manual (útil para pruebas)
function Input:appendChar(char)
    if self._readonly then return end
    self:setValue(self._value .. tostring(char))
    self:dispatchEvent("input", { char = char, value = self._value })
end

function Input:clear()
    self:setValue("")
    return self
end

-- ============================================================================
-- OVERRIDES
-- ============================================================================

function Input:debugPrint(indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    local val_str = (self._type == Input.TYPES.PASSWORD) and (string.rep("*", #self._value)) or self._value
    local status = self._is_valid and "[OK]" or ("[ERROR: " .. self._error_msg .. "]")
    
    print(string.format('%s<Input type="%s" value="%s" placeholder="%s" %s uid=%d>',
        prefix, self._type, val_str, self._placeholder, status, self:getUid()))
end

return Input
