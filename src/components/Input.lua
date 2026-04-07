-- src/components/Input.lua
-- Componente Input PRO (ReanUI)
-- Soporta tipos de texto, validación, sanitización y manejo de estados.

local UIElement = require("src.core.UIElement")
local Validators = require("src.validators.InputValidators")

local Input = {}
Input.__index = Input
setmetatable(Input, { __index = UIElement })

local function nowSeconds()
    if type(getTickCount) == "function" then
        return getTickCount() / 1000
    end
    return os.clock()
end

local function parsePaddingLeft(padding)
    if type(padding) ~= "string" then return 0 end
    local parts = {}
    for token in padding:gmatch("%S+") do
        parts[#parts + 1] = token
    end
    local function px(v)
        return tonumber((v or "0"):match("([%+%-]?[%d%.]+)")) or 0
    end
    if #parts == 1 then return px(parts[1]) end
    if #parts == 2 then return px(parts[2]) end
    if #parts == 3 then return px(parts[2]) end
    if #parts >= 4 then return px(parts[4]) end
    return 0
end

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

    -- Estado de edición real
    self._cursor_pos = 0 -- índice de cursor [0..#_value]
    self._caret_visible = false
    self._caret_blink_interval = 0.5
    self._last_caret_toggle = nowSeconds()

    -- Estilos Base Modernos
    self:addClass("input")
    self:setStyle("display", "flex")
    self:setStyle("align-items", "center")
    self:setStyle("padding", "10px 15px")
    self:setStyle("height", "45px")
    self:setStyle("border", "2px solid var(--border-color)")
    self:setStyle("border-radius", "8px")
    self:setStyle("background-color", "var(--bg-alt)")
    self:setStyle("color", "var(--text-color)")
    self:setStyle("border-color", "var(--border-color)")
    self:setStyle("font-size", "16px")
    self:setStyle("width", "100%")
    self:setStyle("transition", "border-color 0.2s, background-color 0.2s")
    self:setStyle("cursor", "text")

    self:setFocusable(true)

    self:_attachInternalListeners()

    if type(attrs) == "table" and attrs.placeholder then
        self:setPlaceholder(attrs.placeholder)
    end

    return self
end

function Input:_attachInternalListeners()
    -- Escuchar eventos de teclado cuando tiene el foco
    self:addEventListener("character", function(event)
        self:appendChar(event.character)
    end)

    self:addEventListener("keydown", function(event)
        if event.state and event.state ~= "down" then return end
        if event.key == "backspace" then
            self:backspace()
        elseif event.key == "delete" then
            self:deleteForward()
        elseif event.key == "arrow_l" then
            self:moveCursor(-1)
        elseif event.key == "arrow_r" then
            self:moveCursor(1)
        elseif event.key == "home" then
            self:setCursorPosition(0)
        elseif event.key == "end" then
            self:setCursorPosition(#self._value)
        elseif event.key == "enter" or event.key == "num_enter" then
            self:dispatchEvent("submit", { value = self._value })
        end
    end)

    self:addEventListener("focus", function()
        self:onFocus()
    end)

    self:addEventListener("blur", function()
        self:onBlur()
    end)
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
    self._cursor_pos = math.min(self._cursor_pos, #self._value)

    if oldVal ~= self._value then
        self:dispatchEvent("change", { value = self._value, old_value = oldVal })
        self:validate() -- Validar al cambiar el valor
        self:markDirty()
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
        self:setStyle("border-color", "var(--error-color, #ef4444)")
    else
        self:removeClass("is-error")
        if val ~= "" then
            self:addClass("is-success")
            self:setStyle("border-color", "var(--success-color, #22c55e)")
        else
            self:removeClass("is-success")
            self:setStyle("border-color", self._is_focused and "var(--primary-color)" or "var(--border-color)")
        end
    end

    self:dispatchEvent("validate", { is_valid = isValid, error_msg = msg })
    self:markDirty()
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


-- Simulación de entrada de texto manual (útil para pruebas)
function Input:appendChar(char)
    if self._readonly then return end
    local c = tostring(char or "")
    if c == "" then return end

    local before = self._value:sub(1, self._cursor_pos)
    local after = self._value:sub(self._cursor_pos + 1)
    self:setValue(before .. c .. after)
    self._cursor_pos = math.min(#self._value, self._cursor_pos + #c)
    self:resetCaretBlink()
    self:dispatchEvent("input", { char = char, value = self._value })
end

function Input:clear()
    self:setValue("")
    self._cursor_pos = 0
    self:resetCaretBlink()
    return self
end

function Input:backspace()
    if self._readonly or #self._value == 0 or self._cursor_pos <= 0 then return end
    local before = self._value:sub(1, self._cursor_pos - 1)
    local after = self._value:sub(self._cursor_pos + 1)
    self:setValue(before .. after)
    self._cursor_pos = math.max(0, self._cursor_pos - 1)
    self:resetCaretBlink()
    self:dispatchEvent("input", { type = "backspace", value = self._value })
end

function Input:deleteForward()
    if self._readonly or #self._value == 0 or self._cursor_pos >= #self._value then return end
    local before = self._value:sub(1, self._cursor_pos)
    local after = self._value:sub(self._cursor_pos + 2)
    self:setValue(before .. after)
    self:resetCaretBlink()
    self:dispatchEvent("input", { type = "delete", value = self._value })
end

function Input:moveCursor(delta)
    delta = tonumber(delta) or 0
    self:setCursorPosition(self._cursor_pos + delta)
end

function Input:setCursorPosition(pos)
    local n = tonumber(pos) or 0
    self._cursor_pos = math.max(0, math.min(#self._value, math.floor(n)))
    self:resetCaretBlink()
    self:markDirty()
    return self
end

function Input:getCursorPosition()
    return self._cursor_pos
end

function Input:resetCaretBlink()
    self._caret_visible = true
    self._last_caret_toggle = nowSeconds()
    self:markDirty()
end

function Input:updateCaretBlink()
    if not self._is_focused then
        if self._caret_visible then
            self._caret_visible = false
            self:markDirty()
        end
        return
    end

    local now = nowSeconds()
    if (now - self._last_caret_toggle) >= self._caret_blink_interval then
        self._caret_visible = not self._caret_visible
        self._last_caret_toggle = now
        self:markDirty()
    end
end

function Input:isCaretVisible()
    return self._is_focused and self._caret_visible
end

function Input:getDisplayValue()
    if self._type == Input.TYPES.PASSWORD then
        return string.rep("*", #self._value)
    end
    return self._value
end

function Input:getPaddingLeft()
    return parsePaddingLeft(self:getStyle("padding"))
end

function Input:onFocus()
    if self._readonly then return end
    self._is_focused = true
    self._cursor_pos = math.min(self._cursor_pos, #self._value)
    self:addClass("is-focused")
    self:resetCaretBlink()
    if self._is_valid then
        self:setStyle("border-color", "var(--primary-color)")
    end
end

function Input:onBlur()
    self._is_focused = false
    self:removeClass("is-focused")
    if self._is_valid then
        self:setStyle("border-color", "var(--border-color)")
    end
    self:validate() -- Validar al salir
    self:markDirty()
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
