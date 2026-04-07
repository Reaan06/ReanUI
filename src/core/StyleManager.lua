-- Responsabilidad única: almacenar, leer, clonar y aplicar deltas de estilo.
local ThemeManager = require("src.theme.ThemeManager")

local StyleManager = {}
StyleManager.__index = StyleManager

-- Propiedades válidas para ReanUI (whitelist estricta)
StyleManager.VALID_PROPERTIES = {
    width               = "dimension",
    height              = "dimension",
    color               = "color",
    ["background-color"] = "color",
    margin              = "shorthand",
    ["margin-top"]      = "dimension",
    ["margin-right"]    = "dimension",
    ["margin-bottom"]   = "dimension",
    ["margin-left"]     = "dimension",
    padding             = "shorthand",
    ["padding-top"]     = "dimension",
    ["padding-right"]   = "dimension",
    ["padding-bottom"]  = "dimension",
    ["padding-left"]    = "dimension",
    border              = "shorthand",
    ["border-radius"]   = "dimension",
    ["font-size"]       = "dimension",
    display             = "keyword",
    ["flex-direction"]  = "keyword",
    ["justify-content"] = "keyword",
    ["align-items"]     = "keyword",
    opacity             = "number",
    ["z-index"]         = "number",
    position            = "keyword",
    top                 = "dimension",
    left                = "dimension",
    right               = "dimension",
    bottom              = "dimension",
    ["flex-grow"]       = "number",
    ["flex-shrink"]     = "number",
    ["flex-basis"]      = "dimension",
    gap                 = "dimension",
    transition          = "string",
    transform           = "string",
    cursor              = "keyword",
    ["border-color"]    = "color",
    ["shadow-color"]    = "color",
    ["shadow-blur"]     = "dimension",
    ["shadow-offset-x"] = "dimension",
    ["shadow-offset-y"] = "dimension",
}

function StyleManager.new()
    local self = setmetatable({}, StyleManager)
    self._styles = {}         -- { ["background-color"] = "#FF0000", ... }
    self._on_change = nil     -- Callback opcional que el UIElement inyecta para dirty-flagging
    return self
end

--- Registra un hook de cambio (lo usa UIElement para disparar "stylechange")
function StyleManager:onChanged(callback)
    self._on_change = callback
end

--- Setea una propiedad CSS validada.
--- @param prop string
--- @param value string|number
function StyleManager:set(prop, value)
    if type(prop) ~= "string" then
        error("[ReanUI:StyleManager] Property name must be a string.")
    end

    local normalized = prop:lower():match("^%s*(.-)%s*$")

    local isVariable = normalized:match("^%-%-")
    if not StyleManager.VALID_PROPERTIES[normalized] and not isVariable then
        return false, "Unknown CSS property: " .. normalized
    end
    
    self._styles[normalized] = tostring(value)

    if self._on_change then self._on_change(normalized, value) end
    return true
end

--- Lee una propiedad. Retorna nil si no existe.
--- Las keys en _styles ya están normalizadas (minusc./sin espacios) desde set().
--- Resuelve variables CSS var() si están presentes.
function StyleManager:get(prop)
    if type(prop) ~= "string" then return nil end
    -- Lookup directo: sin regex, sin lower(). O(1) puro.
    local val = self._styles[prop]
    if val == nil then
        -- Fallback: normalizar por si el caller pasó valor sin normalizar
        val = self._styles[prop:lower():match("^%s*(.-)%s*$")]
    end

    -- Si el valor contiene una variable var(), resolverla dinámicamente
    if type(val) == "string" and val:find("var%s*%(", 1, false) then
        return ThemeManager.resolve(val)
    end

    return val
end

--- Aplica un bloque CSS inline de un solo golpe ("width: 100px; color: red;")
function StyleManager:applyBlock(css_string)
    if type(css_string) ~= "string" then return end

    for declaration in css_string:gmatch("([^;]+)") do
        local prop, val = declaration:match("([^:]+)%s*:%s*(.+)")
        if prop and val then
            self:set(prop, val:match("^%s*(.-)%s*$"))
        end
    end
end

--- Clona completamente los estilos en una nueva instancia.
function StyleManager:clone()
    local copy = StyleManager.new()
    for k, v in pairs(self._styles) do
        copy._styles[k] = v
    end
    return copy
end

--- Devuelve la tabla raw de estilos (read-only snapshot).
function StyleManager:getAll()
    local snapshot = {}
    for k, v in pairs(self._styles) do snapshot[k] = v end
    return snapshot
end

--- Elimina una propiedad.
function StyleManager:remove(prop)
    if type(prop) ~= "string" then return end
    self._styles[prop:lower():match("^%s*(.-)%s*$")] = nil
end

--- Limpieza total.
function StyleManager:clear()
    self._styles = {}
end

return StyleManager
