-- src/validators/InputValidators.lua
-- Módulo encargado de la lógica de validación y sanitización de entradas.

local InputValidators = {}

--- Sanitiza un string eliminando caracteres de control y espacios extra.
--- Previene inyecciones básicas y asegura consistencia.
function InputValidators.sanitize(text)
    if type(text) ~= "string" then return "" end
    -- Eliminar caracteres Null, retornos de carro, saltos de línea (si es inline)
    local clean = text:gsub("[%z\r\n]", "")
    return clean:match("^%s*(.-)%s*$") -- Trim
end

--- Validador de Email (RFC5322 simplificado para patrones Lua)
function InputValidators.isEmail(text)
    if not text or text == "" then return false end
    -- Heurística: [algo]@[algo].[dominio]
    -- Lua patterns no son Regex completos, usamos una aproximación robusta:
    local pattern = "^[%w%.%_%-%+]+@[%w%.%_%-]+%.%w%w+$"
    return text:match(pattern) ~= nil
end

--- Validador de Números (Enteros y Decimales)
function InputValidators.isNumber(text)
    if not text or text == "" then return false end
    -- Soporta: 123, -123, 123.45, .45
    return tonumber(text) ~= nil
end

--- Validador de Teléfono (Internacional básico)
function InputValidators.isTel(text)
    if not text or text == "" then return false end
    -- Soporta: +12345678, 12345678, y guiones opcionales
    local clean = text:gsub("[%s%-%(%)]", "")
    return clean:match("^%s*[%+]?%d+%s*$") ~= nil
end

--- Validador Genérico via Regex (Pasado por el usuario)
function InputValidators.matchRegex(text, pattern)
    if not text or not pattern then return false end
    return text:match(pattern) ~= nil
end

return InputValidators
