-- src/parser/css_parser.lua
-- Módulo parseador de CSS 100% nativo para Lua 5.3+

local css_parser = {}

-- ============================================================================
-- DICCIONARIO DE PROPIEDADES (WHITELIST)
-- ============================================================================
local CSS_SUPPORTED_PROPERTIES = {
    color = true,
    margin = true,
    padding = true,
    width = true,
    height = true,
    background = true,
    border = true,
    ["background-color"] = true,
    ["border-radius"] = true,
    ["font-size"] = true,
    display = true,
    ["flex-direction"] = true,
    ["justify-content"] = true,
    ["align-items"] = true,
    ["flex-grow"] = true,
    ["flex-shrink"] = true,
    ["flex-basis"] = true,
    ["gap"] = true,
    ["flex"] = true,
    ["border"] = true,
}

-- ============================================================================
-- UTILIDADES INTERNAS (camelCase)
-- ============================================================================

local function trimString(str)
    if not str then return "" end
    return str:match("^%s*(.-)%s*$")
end

local function parsePropertiesBlock(blockStr)
    local resultProps = {}
    
    -- Itera sobre cada declaración separada por ';'
    for declaration in blockStr:gmatch("([^;]+)") do
        local prop, val = declaration:match("([^:]+)%s*:%s*(.+)")
        
        if prop and val then
            local normProp = css_parser.normalize_css_property(prop)
            local cleanVal = trimString(val)
            
            -- Filtraje estricto de propiedades por White-List para UI pura
            if CSS_SUPPORTED_PROPERTIES[normProp] then
                resultProps[normProp] = cleanVal
            end
        end
    end
    
    return resultProps
end

-- ============================================================================
-- MÉTODOS PÚBLICOS EXPORTADOS (snake_case)
-- ============================================================================

-- normalize_css_property: Limpia e indexa el key de la propiedad
function css_parser.normalize_css_property(prop_name)
    if type(prop_name) ~= "string" then return nil end
    return trimString(prop_name):lower()
end

-- parse_css_selector: Extrae múltiples selectores separados por comas (Ej: ".btn, #id")
function css_parser.parse_css_selector(selector_string)
    local selectorsArray = {}
    if type(selector_string) ~= "string" then return selectorsArray end
    
    for selectorPattern in selector_string:gmatch("([^,]+)") do
        local cleanSelector = trimString(selectorPattern)
        if cleanSelector ~= "" then
            table.insert(selectorsArray, cleanSelector)
        end
    end
    
    return selectorsArray
end

-- parse_css_string: Convierte CSS plano o anidado en nodos lua (Table Tree)
function css_parser.parse_css_string(css_string)
    if type(css_string) ~= "string" then
        return nil, "Exception [CssParser]: Invalid input type. Expected string."
    end
    
    local parsedTree = {}
    
    -- Heurística Branching: Detectar si es un bloque completo (con jerarquía {})
    -- o si es un 'Inline Style' primitivo ("color: red; width: 10px")
    local hasBlocks = css_string:find("{")
    
    if hasBlocks then
        -- Regex Patterning para extraccion iterativa de bloques Selectors {}
        for selectorSection, bodySection in css_string:gmatch("([^{}]+)%s*{%s*([^{}]*)%s*}") do
            local selectorsList = css_parser.parse_css_selector(selectorSection)
            local propertiesMap = parsePropertiesBlock(bodySection)
            
            -- Inyección combinada de N-Selectores hacia la misma regla mapeada (Memory Refs)
            for _, sel in ipairs(selectorsList) do
                parsedTree[sel] = propertiesMap
            end
        end
    else
        -- Parseo lineal plano al no haber llaves de selector
        parsedTree = parsePropertiesBlock(css_string)
    end
    
    return parsedTree, nil
end

return css_parser
