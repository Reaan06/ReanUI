-- src/theme/ThemeManager.lua
-- Motor profesional de resolución de temas y variables CSS.

local ThemeManager = {}

-- Configuración Interna
ThemeManager._current_name = "dark"
ThemeManager._variables    = {}
ThemeManager._cache        = {}   -- Memoización de resoluciones complejas

--- Limpia el caché de resoluciones. Invocado al cambiar de tema.
function ThemeManager._clearCache()
    ThemeManager._cache = {}
end

--- Carga un tema desde archivo con soporte para hot-reloading.
--- @param name string Nombre del tema (dark, light, etc.)
function ThemeManager.setTheme(name)
    local theme_path = "src.theme.themes." .. name
    
    -- Soporte Hot-Reloading: forzar recarga del archivo Lua
    package.loaded[theme_path] = nil
    local ok, theme_data = pcall(require, theme_path)
    
    if not ok then
        print("[ReanUI:ThemeManager] Error cargando tema '" .. name .. "': " .. tostring(theme_data))
        return false
    end
    
    ThemeManager._current_name = name
    ThemeManager._variables    = theme_data
    ThemeManager._clearCache()
    
    print("[ReanUI:ThemeManager] Tema actualizado a: " .. name)
    return true
end

--- Busca el valor de una variable en el tema actual.
function ThemeManager.getVariable(name, fallback)
    local val = ThemeManager._variables[name]
    if val == nil then return fallback end
    return val
end

--- Resuelve expresiones de tipo 'var(--nombre, fallback)'.
--- Soporta resoluciones recursivas limitadas para evitar ciclos.
--- @param input string El valor a procesar (ej: "var(--primary-color, #f00)")
--- @param depth number (Opcional) Profundidad recursiva
function ThemeManager.resolve(input, depth)
    depth = depth or 0
    if depth > 5 then return input end -- Límite para prevenir ciclos infinitos

    if type(input) ~= "string" or not input:find("var%(") then
        return input
    end

    -- Consultar caché para evitar re-parseo
    if ThemeManager._cache[input] then
        return ThemeManager._cache[input]
    end

    -- Patrón: var( <nombre> [, <fallback>] )
    local resolved = input:gsub("var%s*%(%s*([%w%-%_]+)%s*,?%s*([^%)]*)%s*%)", function(name, fallback)
        local val = ThemeManager.getVariable(name)
        
        if val == nil then
            -- Si no existe, usar fallback (si hay) o el nombre original
            val = (fallback ~= "") and fallback or name
        end
        
        -- Resolución recursiva (permite --a: var(--b))
        return ThemeManager.resolve(val, depth + 1)
    end)

    -- Guardar en caché antes de retornar
    ThemeManager._cache[input] = resolved
    return resolved
end

-- Inicialización por defecto
ThemeManager.setTheme("dark")

return ThemeManager
