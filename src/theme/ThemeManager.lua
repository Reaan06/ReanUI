local ThemeManager = {
    _classes = {},
    _ids = {},
    _types = {},
    _variables = {
        ["--primary"] = tocolor(0, 120, 255, 255),
        ["--secondary"] = tocolor(255, 50, 50, 255),
        ["--bg"] = tocolor(20, 20, 20, 255),
        ["--border"] = tocolor(80, 80, 80, 255)
    }
}

function ThemeManager.registerClass(name, style)
    ThemeManager._classes[name] = style
end

function ThemeManager.registerID(id, style)
    ThemeManager._ids[id] = style
end

function ThemeManager.registerType(typeName, style)
    ThemeManager._types[typeName] = style
end

function ThemeManager.getVariable(name)
    return ThemeManager._variables[name]
end

function ThemeManager.setVariable(name, value)
    ThemeManager._variables[name] = value
end

-- Obtiene el estilo combinado para un elemento
function ThemeManager.getStyleForElement(element)
    local combinedStyle = {}
    
    -- 1. Estilos por tipo
    if element.type and ThemeManager._types[element.type] then
        for k, v in pairs(ThemeManager._types[element.type]) do
            combinedStyle[k] = v
        end
    end
    
    -- 2. Estilos por clase (soporta múltiples clases separadas por espacios)
    if element.className then
        for class in element.className:gmatch("%S+") do
            if ThemeManager._classes[class] then
                for k, v in pairs(ThemeManager._classes[class]) do
                    combinedStyle[k] = v
                end
            end
        end
    end
    
    -- 3. Estilos por ID
    if element.id and ThemeManager._ids[element.id] then
        for k, v in pairs(ThemeManager._ids[element.id]) do
            combinedStyle[k] = v
        end
    end
    
    -- 4. Estilo en línea (sobrescribe todo)
    if element.style then
        for k, v in pairs(element.style) do
            combinedStyle[k] = v
        end
    end
    
    return combinedStyle
end

return ThemeManager
