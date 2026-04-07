--- @module Utils
--- Biblioteca de utilidades de producción para ReanUI.
--- Proporciona submódulos especializados para manipulación de datos, rendiemiento y depuración.
local Utils = {}

-- ============================================================================
-- UTILS.COLOR  — Manipulación de colores
-- ============================================================================

--- @section Color
Utils.Color = {}

--- Convierte un string hexadecimal a tabla RGB(A).
--- @tparam string hex Formatos soportados: "#RGB", "#RRGGBB", "#RRGGBBAA".
--- @treturn table|nil Tabla {r, g, b [, a]} o nil si el formato es inválido.
function Utils.Color.hexToRgb(hex)
    if type(hex) ~= "string" then return nil end
    hex = hex:gsub("^#", "")
    if #hex == 3 then
        hex = hex:gsub("(.)", "%1%1")
    end
    local len = #hex
    if len ~= 6 and len ~= 8 then return nil end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not (r and g and b) then return nil end

    if len == 8 then
        local a = tonumber(hex:sub(7, 8), 16)
        return { r = r, g = g, b = b, a = a }
    end
    return { r = r, g = g, b = b }
end

--- Convierte valores RGB (0-255) a string hexadecimal "#RRGGBB".
--- @param r number  0-255
--- @param g number  0-255
--- @param b number  0-255
--- @param a number|nil  0-255 (opcional)
--- @return string
function Utils.Color.rgbToHex(r, g, b, a)
    r = math.floor(math.max(0, math.min(255, r)))
    g = math.floor(math.max(0, math.min(255, g)))
    b = math.floor(math.max(0, math.min(255, b)))
    if a then
        a = math.floor(math.max(0, math.min(255, a)))
        return string.format("#%02X%02X%02X%02X", r, g, b, a)
    end
    return string.format("#%02X%02X%02X", r, g, b)
end

--- Parsea un color de múltiples formatos a tabla {r, g, b}.
--- Acepta: "#RRGGBB", "rgb(r, g, b)", {r=, g=, b=}
--- @param color string|table
--- @return table|nil  { r, g, b }
function Utils.Color.parseColor(color)
    if type(color) == "table" then
        return { r = color.r or 0, g = color.g or 0, b = color.b or 0, a = color.a }
    end
    if type(color) ~= "string" then return nil end

    -- #RRGGBB
    if color:sub(1, 1) == "#" then
        return Utils.Color.hexToRgb(color)
    end

    -- rgb(r, g, b) / rgba(r, g, b, a)
    local r, g, b = color:match("rgb%D+(%d+)%D+(%d+)%D+(%d+)")
    if r then return { r = tonumber(r), g = tonumber(g), b = tonumber(b) } end

    local r2, g2, b2, a2 = color:match("rgba%D+(%d+)%D+(%d+)%D+(%d+)%D+([%d%.]+)")
    if r2 then
        return { r = tonumber(r2), g = tonumber(g2), b = tonumber(b2), a = math.floor((tonumber(a2) or 1) * 255) }
    end

    return nil
end

--- Aclara un color hexadecimal en un porcentaje dado.
--- @param hex    string  "#RRGGBB"
--- @param amount number  0.0 - 1.0
--- @return string  "#RRGGBB"
function Utils.Color.lighten(hex, amount)
    local c = Utils.Color.hexToRgb(hex)
    if not c then return hex end
    amount = amount or 0.1
    return Utils.Color.rgbToHex(
        math.min(255, c.r + 255 * amount),
        math.min(255, c.g + 255 * amount),
        math.min(255, c.b + 255 * amount)
    )
end

--- Oscurece un color hexadecimal en un porcentaje dado.
--- @param hex    string  "#RRGGBB"
--- @param amount number  0.0 - 1.0
--- @return string  "#RRGGBB"
function Utils.Color.darken(hex, amount)
    local c = Utils.Color.hexToRgb(hex)
    if not c then return hex end
    amount = amount or 0.1
    return Utils.Color.rgbToHex(
        math.max(0, c.r - 255 * amount),
        math.max(0, c.g - 255 * amount),
        math.max(0, c.b - 255 * amount)
    )
end

--- Mezcla dos colores hexadecimales con un factor (0 = color1, 1 = color2).
--- @param hex1   string
--- @param hex2   string
--- @param t      number  0.0 - 1.0
--- @return string  "#RRGGBB"
function Utils.Color.mix(hex1, hex2, t)
    local c1 = Utils.Color.hexToRgb(hex1)
    local c2 = Utils.Color.hexToRgb(hex2)
    if not (c1 and c2) then return hex1 end
    t = math.max(0, math.min(1, t or 0.5))
    return Utils.Color.rgbToHex(
        c1.r + (c2.r - c1.r) * t,
        c1.g + (c2.g - c1.g) * t,
        c1.b + (c2.b - c1.b) * t
    )
end

--- @section String
Utils.String = {}

--- Elimina espacios en blanco al inicio y al final de una cadena.
--- @tparam string s Cadena de entrada.
--- @treturn string Cadena limpia.
function Utils.String.trim(s)
    if type(s) ~= "string" then return s end
    return s:match("^%s*(.-)%s*$")
end

--- Verifica si un string comienza con un prefijo.
--- @param s      string
--- @param prefix string
--- @return boolean
function Utils.String.startsWith(s, prefix)
    if type(s) ~= "string" or type(prefix) ~= "string" then return false end
    return s:sub(1, #prefix) == prefix
end

--- Verifica si un string termina con un sufijo.
--- @param s      string
--- @param suffix string
--- @return boolean
function Utils.String.endsWith(s, suffix)
    if type(s) ~= "string" or type(suffix) ~= "string" then return false end
    if #suffix == 0 then return true end
    return s:sub(-#suffix) == suffix
end

--- Verifica si un string contiene un substring.
--- @param s   string
--- @param sub string
--- @return boolean
function Utils.String.includes(s, sub)
    if type(s) ~= "string" or type(sub) ~= "string" then return false end
    return s:find(sub, 1, true) ~= nil
end

--- Divide un string por un separador.
--- @param s   string
--- @param sep string  Separador (literal)
--- @return table  Array de strings
function Utils.String.split(s, sep)
    if type(s) ~= "string" then return {} end
    sep = sep or "%s"
    local result = {}
    -- Si el sep es un literal, escapamos los caracteres especiales de patron
    local pattern = "([^" .. sep:gsub("[%(%)%.%%%+%-%*%?%[%^%$]", "%%%1") .. "]*)"
    for match in s:gmatch(pattern) do
        result[#result + 1] = match
    end
    return result
end

--- Interpolación de strings con variables: "Hola {nombre}!" → "Hola mundo!"
--- @param template string  String con marcadores {key}
--- @param vars     table   Tabla de variables { key = value }
--- @return string
function Utils.String.interpolate(template, vars)
    if type(template) ~= "string" then return tostring(template) end
    vars = vars or {}
    return (template:gsub("{(%w+)}", function(key)
        return tostring(vars[key] or "{" .. key .. "}")
    end))
end

--- Repite un string N veces.
--- @param s string
--- @param n number
--- @return string
function Utils.String.repeat_(s, n)
    local result = {}
    for i = 1, n do result[i] = s end
    return table.concat(result)
end

--- Rellena un string a la izquierda hasta una longitud dada.
--- @param s     string
--- @param len   number
--- @param char  string  Carácter de relleno (por defecto " ")
--- @return string
function Utils.String.padStart(s, len, char)
    s = tostring(s)
    char = char or " "
    while #s < len do s = char .. s end
    return s
end

--- @section Table
Utils.Table = {}

--- Crea una copia superficial (shallow) de una tabla.
--- @tparam table t Tabla a clonar.
--- @treturn table Copia de la tabla.
function Utils.Table.clone(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    setmetatable(copy, getmetatable(t))
    return copy
end

--- Crea una copia profunda de una tabla (recursiva).
--- Maneja referencias circulares mediante un mapa de vistos.
--- @param t    table
--- @param seen table|nil  (interno)
--- @return table
function Utils.Table.deepClone(t, seen)
    if type(t) ~= "table" then return t end
    seen = seen or {}
    if seen[t] then return seen[t] end

    local copy = {}
    seen[t] = copy
    for k, v in pairs(t) do
        copy[Utils.Table.deepClone(k, seen)] = Utils.Table.deepClone(v, seen)
    end
    setmetatable(copy, getmetatable(t))
    return copy
end

--- Combina múltiples tablas en una nueva (shallow merge, el último gana).
--- @param ...  tables  Una o más tablas a combinar
--- @return table
function Utils.Table.merge(...)
    local result = {}
    for _, t in ipairs({...}) do
        if type(t) == "table" then
            for k, v in pairs(t) do result[k] = v end
        end
    end
    return result
end

--- Filtra una tabla (array) con una función predicado.
--- @param t   table
--- @param fn  function  Recibe (value, key), debe retornar boolean
--- @return table  Nuevo array con los elementos que pasaron el filtro
function Utils.Table.filter(t, fn)
    local result = {}
    for i, v in ipairs(t) do
        if fn(v, i) then result[#result + 1] = v end
    end
    return result
end

--- Mapea un array a uno nuevo aplicando una función a cada elemento.
--- @param t   table
--- @param fn  function  Recibe (value, index), retorna nuevo valor
--- @return table  Nuevo array transformado
function Utils.Table.map(t, fn)
    local result = {}
    for i, v in ipairs(t) do
        result[i] = fn(v, i)
    end
    return result
end

--- Reduce un array a un único valor acumulado.
--- @param t    table
--- @param fn   function  Recibe (accumulator, value, index)
--- @param init any       Valor inicial del acumulador
--- @return any
function Utils.Table.reduce(t, fn, init)
    local acc = init
    for i, v in ipairs(t) do
        acc = fn(acc, v, i)
    end
    return acc
end

--- Verifica si una tabla contiene un valor determinado.
--- @param t   table
--- @param val any
--- @return boolean
function Utils.Table.includes(t, val)
    for _, v in pairs(t) do
        if v == val then return true end
    end
    return false
end

--- Cuenta los elementos de una tabla (incluyendo claves no numéricas).
--- @param t table
--- @return number
function Utils.Table.count(t)
    if type(t) ~= "table" then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

--- Extrae solo las claves de una tabla en un array.
--- @param t table
--- @return table
function Utils.Table.keys(t)
    local result = {}
    for k in pairs(t) do result[#result + 1] = k end
    return result
end

--- Extrae solo los valores de una tabla en un array.
--- @param t table
--- @return table
function Utils.Table.values(t)
    local result = {}
    for _, v in pairs(t) do result[#result + 1] = v end
    return result
end

--- @section Number
Utils.Number = {}

--- Limita un valor numérico entre un mínimo y un máximo.
--- @tparam number n Valor de entrada.
--- @tparam number min Límite inferior.
--- @tparam number max Límite superior.
--- @treturn number Valor limitado.
function Utils.Number.clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

--- Interpolación lineal entre a y b con factor t (0-1).
--- @param a number  Valor inicial
--- @param b number  Valor final
--- @param t number  Factor de interpolación (0.0 - 1.0)
--- @return number
function Utils.Number.lerp(a, b, t)
    return a + (b - a) * t
end

--- Redondea un número a N decimales.
--- @param n      number
--- @param places number  Dígitos decimales (0 = entero)
--- @return number
function Utils.Number.roundTo(n, places)
    local factor = 10 ^ (places or 0)
    return math.floor(n * factor + 0.5) / factor
end

--- Genera un número aleatorio en el rango [min, max].
--- @param min number
--- @param max number
--- @return number
function Utils.Number.randomRange(min, max)
    return min + math.random() * (max - min)
end

--- Convierte radianes a grados.
--- @param rad number
--- @return number
function Utils.Number.toDegrees(rad)
    return rad * (180 / math.pi)
end

--- Convierte grados a radianes.
--- @param deg number
--- @return number
function Utils.Number.toRadians(deg)
    return deg * (math.pi / 180)
end

--- Normaliza un valor dentro de un rango a 0-1.
--- @param n   number
--- @param min number
--- @param max number
--- @return number
function Utils.Number.normalize(n, min, max)
    if max == min then return 0 end
    return (n - min) / (max - min)
end

--- Verifica si un número está en el rango [min, max] (inclusive).
--- @param n   number
--- @param min number
--- @param max number
--- @return boolean
function Utils.Number.inRange(n, min, max)
    return n >= min and n <= max
end

--- @section Validation
Utils.Validation = {}

--- Verifica si un valor es un número.
function Utils.Validation.isNumber(v)   return type(v) == "number" end
function Utils.Validation.isString(v)   return type(v) == "string" end
function Utils.Validation.isTable(v)    return type(v) == "table" end
function Utils.Validation.isFunction(v) return type(v) == "function" end
function Utils.Validation.isBoolean(v)  return type(v) == "boolean" end
function Utils.Validation.isNil(v)      return v == nil end

--- Verifica si una tabla, string o número están "vacíos" / en 0.
--- @param v any
--- @return boolean
function Utils.Validation.isEmpty(v)
    if v == nil then return true end
    if type(v) == "string" then return #v == 0 end
    if type(v) == "table" then return next(v) == nil end
    if type(v) == "number" then return v == 0 end
    return false
end

--- Verifica si una tabla tiene una propiedad (clave) determinada.
--- @param t   table
--- @param key string|number
--- @return boolean
function Utils.Validation.hasProperty(t, key)
    if type(t) ~= "table" then return false end
    return t[key] ~= nil
end

--- Verifica si un valor es un entero.
--- @param v any
--- @return boolean
function Utils.Validation.isInteger(v)
    return type(v) == "number" and math.floor(v) == v
end

--- Verifica si un string tiene formato de color hexadecimal válido.
--- @param s string
--- @return boolean
function Utils.Validation.isHexColor(s)
    if type(s) ~= "string" then return false end
    return s:match("^#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]?[0-9A-Fa-f]?[0-9A-Fa-f]?$") ~= nil
end

--- @section Performance
Utils.Performance = {}

--- Crea una función 'debounced' que solo se ejecuta tras un tiempo de inactividad.
--- Útil para búsquedas en tiempo real o redimensionamiento de ventanas.
--- @tparam function fn Función original.
--- @tparam number delay Tiempo de retardo en milisegundos.
--- @treturn function Función envuelta.
function Utils.Performance.debounce(fn, delay)
    local last_call = -math.huge
    local delay_s = (delay or 300) / 1000.0

    local debounced = {
        _pending = false,
        _args    = nil
    }

    setmetatable(debounced, {
        __call = function(self, ...)
            self._args = {...}
            self._pending = true
            last_call = os.clock()
        end
    })

    -- tick() debe llamarse en el game loop con el dt actual para que funcione
    local _unpack = table.unpack or unpack

    function debounced:tick()
        if self._pending and (os.clock() - last_call) >= delay_s then
            self._pending = false
            fn(_unpack(self._args or {}))
        end
    end

    function debounced:flush()
        if self._pending then
            self._pending = false
            fn(_unpack(self._args or {}))
        end
    end

    return debounced
end

--- Asegura que una función no se llame más de una vez por `interval` ms.
--- @param fn       function
--- @param interval number  En milisegundos
--- @return function  Función throttled. Ignora llamadas intermedias.
function Utils.Performance.throttle(fn, interval)
    local last_execution = -math.huge
    local interval_s = (interval or 100) / 1000.0

    return function(...)
        local now = os.clock()
        if (now - last_execution) >= interval_s then
            last_execution = now
            return fn(...)
        end
    end
end

--- Memoriza el resultado de una función pura basándose en sus argumentos.
--- Solo funciona correctamente con argumentos que sean válidos como claves de tabla.
--- @param fn function
--- @return function  Función memoizada con caché propio.
function Utils.Performance.memoize(fn)
    local cache = {}
    return function(...)
        local args = {...}
        local key = table.concat(
            Utils.Table.map(args, function(v)
                return type(v) == "table" and tostring(v) or tostring(v)
            end),
            "\0"
        )
        if cache[key] == nil then
            cache[key] = fn(...)
        end
        return cache[key]
    end
end

--- @section Debug
Utils.Debug = {}

--- Genera una representación textual legible (Pretty Print) de cualquier valor Lua.
--- Soporta tablas anidadas y referencias circulares.
--- @tparam any v Cualquier valor Lua (número, tabla, función, etc).
--- @tparam number|nil depth Profundidad máxima de recursión (4 por defecto).
--- @treturn string Cadena resultante.
function Utils.Debug.inspect(v, depth, seen, indent)
    depth  = depth  or 4
    seen   = seen   or {}
    indent = indent or ""

    local t = type(v)

    if t == "number" then
        return tostring(v)
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "nil" then
        return "nil"
    elseif t == "function" then
        return "<function " .. tostring(v) .. ">"
    elseif t == "table" then
        if seen[v] then return "<circular ref>" end
        if depth <= 0 then return "{...}" end
        seen[v] = true

        local mt   = getmetatable(v)
        local tag  = (mt and mt.__name) and (" [" .. mt.__name .. "]") or ""
        local child_indent = indent .. "  "
        local parts = {}

        for k, val in pairs(v) do
            local key_str = type(k) == "string" and k or "[" .. tostring(k) .. "]"
            local val_str = Utils.Debug.inspect(val, depth - 1, seen, child_indent)
            parts[#parts + 1] = child_indent .. key_str .. " = " .. val_str
        end

        seen[v] = nil -- Permitir reuso si la misma tabla aparece en otra rama
        if #parts == 0 then
            return "{}" .. tag
        end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}" .. tag
    else
        return "<" .. t .. ": " .. tostring(v) .. ">"
    end
end

--- Imprime un inspect en consola con un título opcional.
--- @param v     any
--- @param label string|nil
function Utils.Debug.logTable(v, label)
    if label then
        print("[DEBUG | " .. tostring(label) .. "] " .. Utils.Debug.inspect(v))
    else
        print("[DEBUG] " .. Utils.Debug.inspect(v))
    end
end

--- Aserción con mensaje descriptivo personalizado.
--- En lugar de un "assertion failed!" genérico, muestra un mensaje claro.
--- @param condition boolean
--- @param message   string
--- @param level     number|nil  Nivel del error (defecto: 2)
function Utils.Debug.assert(condition, message, level)
    if not condition then
        error("[ReanUI:Assert] " .. tostring(message), level or 2)
    end
    return true
end

--- Registra un mensaje de tiempo (perf timing básico).
--- @param label string
--- @return function  Llama al retorno para obtener el tiempo transcurrido.
function Utils.Debug.timer(label)
    local start = os.clock()
    return function()
        local elapsed = (os.clock() - start) * 1000
        print(string.format("[Timer] %s: %.3fms", tostring(label), elapsed))
        return elapsed
    end
end

return Utils
