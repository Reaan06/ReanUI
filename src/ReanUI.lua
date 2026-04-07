--- @module ReanUI
--- Punto de entrada principal de la librería ReanUI.
--- Coordina el Parser, el Layout y el Renderer.

local UIElement     = require("src.core.UIElement")
local Button        = require("src.components.Button")
local Text          = require("src.components.Text")
local Container     = require("src.components.Container")
local Checkbox      = require("src.components.Checkbox")
local ProgressBar   = require("src.components.ProgressBar")
local Input         = require("src.components.Input")
local Scrollbox     = require("src.components.Scrollbox")
local FlexboxLayout = require("src.layout.FlexboxLayout")
local Renderer      = require("src.renderer.Renderer")
local Canvas        = require("src.renderer.Canvas")
local MtaCanvas     = require("src.renderer.MtaCanvas")
local ThemeManager = require("src.theme.ThemeManager")
local InteractionManager = require("src.core.InteractionManager")
local AnimationManager = require("src.core.AnimationManager")

local ReanUI = {}

--- Versión actual de la librería.
ReanUI.VERSION = "0.1.0"

-- Árbol de estilos globales (estilo CSS cargado)
local _global_styles = {} -- { [selector] = { props } }

-- Nodo raíz por defecto (normalmente el "Screen")
local _root = nil
local _renderer = Renderer.new()
local _canvas = nil -- Se inicializa en ReanUI.init()

-- Mapeo de tags a clases de componentes
local _component_map = {
    div      = Container,
    button   = Button,
    text     = Text,
    checkbox = Checkbox,
    progress = ProgressBar,
    input    = Input,
    scrollbox = Scrollbox,
}

-- ============================================================================
-- GESTIÓN DE ESTILOS
-- ============================================================================

--- Carga un bloque de CSS global para toda la aplicación.
function ReanUI.loadStyle(css_string)
    -- Parser CSS 100% Lua
    local css_parser = require("src.parser.css_parser")
    local tree, err = css_parser.parse_css_string(css_string)
    if err then return false, err end
    
    -- Mezclar con estilos existentes
    for selector, props in pairs(tree) do
        _global_styles[selector] = props
    end
    return true
end

--- Cambia el tema global de la aplicación.
--- @tparam string name Nombre del tema ("dark", "light", etc.)
--- @treturn boolean Si el tema se aplicó correctamente.
function ReanUI.setTheme(name)
    return ThemeManager.setTheme(name)
end

--- Genera el valor de una variable de tema.
--- @tparam string name Nombre de la variable (sin var()).
--- @tparam any|nil fallback Valor de respaldo.
--- @treturn any Valor resuelto.
function ReanUI.getThemeVariable(name, fallback)
    return ThemeManager.resolve("var(" .. name .. ")") or fallback
end

--- Aplica los estilos globales a un elemento según sus selectores.
--- @tparam UIElement element El elemento al que aplicar estilos.
function ReanUI.applyGlobalStyles(element)
    local tag = element:getTag()
    local id = element:getId()
    local classes = element:getClasses() or {}
    
    -- 1. Por Tag
    if _global_styles[tag] then
        for k, v in pairs(_global_styles[tag]) do element:setStyle(k, v) end
    end
    
    -- 2. Por Clase
    for _, class in ipairs(classes) do
        local sel = "." .. class
        if _global_styles[sel] then
            for k, v in pairs(_global_styles[sel]) do element:setStyle(k, v) end
        end
    end
    
    -- 3. Por ID
    if id then
        local sel = "#" .. id
        if _global_styles[sel] then
            for k, v in pairs(_global_styles[sel]) do element:setStyle(k, v) end
        end
    end
end

-- ============================================================================
-- CREACIÓN DE ELEMENTOS
-- ============================================================================

--- Crea un elemento UI de forma declarativa (Factoría principal).
--- @tparam string tag Identificador del componente ("div", "button", "text", etc).
--- @tparam table|nil attrs Atributos iniciales { id, class, style, ... }.
--- @tparam table|string|nil children Lista de hijos o contenido textual inicial.
--- @treturn UIElement Nueva instancia del componente.
function ReanUI.createElement(tag, attrs, children)
    local class = _component_map[tag] or UIElement
    
    -- Extraer el contenido si es un componente de valor único (text, button, progress, etc.)
    local content = (type(children) == "string" or type(children) == "number") and children or ""
    local element = class.new(tag == "text" and content or (tag == "button" and content or (tag == "progress" and content or tag)), attrs)
    
    -- Aplicar estilos específicos pasados en el constructor
    if attrs and attrs.style then
        element:setStyleSheet(attrs.style)
    end
    
    -- Aplicar reglas del CSS global
    ReanUI.applyGlobalStyles(element)
    
    -- Añadir hijos
    if type(children) == "table" then
        for _, child in ipairs(children) do
            element:appendChild(child)
        end
    end
    
    return element
end

--- Alias de createElement.
ReanUI.create = ReanUI.createElement

-- ============================================================================
-- CICLO DE RENDERIZADO
-- ============================================================================

--- Inicializa el nodo raíz y el sistema de UI.
function ReanUI.init(width, height, postGUI)
    local sw, sh = 1920, 1080
    if getScreenSize then sw, sh = getScreenSize() end
    
    width = width or sw
    height = height or sh
    
    -- Instanciar Backend de MTA
    _canvas = MtaCanvas.new(width, height, postGUI)
    
    _root = Container.new("column", { id = "screen-root" })
    _root:setStyle("width", width)
    _root:setStyle("height", height)
    _root:setStyle("padding", "0px")
    
    -- Autovinculado al render de MTA si existe
    if addEventHandler then
        addEventHandler("onClientRender", root, function()
            local dt = 1/60 -- Aproximado o calcular real
            ReanUI.update(nil, nil, dt)
        end)
        
        -- Teclado y Caracteres
        addEventHandler("onClientKey", root, function(key, state)
            ReanUI.handleKeyboardEvent("key", key, state)
        end)
        addEventHandler("onClientCharacter", root, function(char)
            ReanUI.handleCharacterEvent(char)
        end)
        
        -- Recuperación de recursos de MTA (Shaders, RTs)
        addEventHandler("onClientRestore", root, function()
            local ShaderManager = require("src.shaders.ShaderManager")
            ShaderManager.clearCache()
            if _canvas and _canvas.onClientRestore then
                _canvas:onClientRestore()
            end
        end)
    end
    
    return _root
end

--- Obtiene el nodo raíz actual.
--- @treturn Container|nil
function ReanUI.getRoot()
    return _root
end

--- Actualiza el motor de UI (Layout, Animaciones y Renderizado).
--- Debe llamarse en cada frame del bucle principal del Host.
--- @tparam number|nil width Nuevo ancho de pantalla (para resize).
--- @tparam number|nil height Nuevo alto de pantalla (para resize).
--- @tparam number|nil dt Delta time en segundos para animaciones.
--- @treturn UIElement|nil El nodo raíz procesado.
function ReanUI.update(width, height, dt)
    if not _root then return nil end
    
    -- 0. Actualizar Animaciones
    if dt and dt > 0 then
        AnimationManager.tick(dt)
    end
    
    -- Forzar dimensiones si el host cambió (resize)
    if width then _root:setStyle("width", width) end
    if height then _root:setStyle("height", height) end
    
    -- 1. Calcular Layout (Motor Flexbox)
    local w = tonumber(_root:getStyle("width")) or 1920
    local h = tonumber(_root:getStyle("height")) or 1080
    FlexboxLayout.calculateLayout(_root, w, h, 0, 0)
    
    -- 2. Producir Render (Usar el nuevo motor profesional)
    _renderer:render(_root, _canvas)
    
    return _root
end

-- ============================================================================
-- INTERACCIÓN (Host Bridge)
-- ============================================================================

--- Inyecta eventos de ratón desde el Host al sistema de UI.
--- @tparam string event_type Tipo de evento ("move", "button", "wheel").
--- @param ... Parámetros específicos (x, y, button, state, delta...).
function ReanUI.handleMouseEvent(event_type, ...)
    if not _root then return end
    
    if event_type == "move" then
        local x, y = ...
        InteractionManager.handleMouseMove(_root, x, y)
    elseif event_type == "button" then
        local button, state, x, y = ...
        InteractionManager.handleMouseButton(_root, button, state, x, y)
    elseif event_type == "wheel" then
        local delta, x, y = ...
        InteractionManager.handleMouseWheel(_root, delta, x, y)
    end
end

--- Inyecta eventos de teclado desde el Host al sistema de UI.
function ReanUI.handleKeyboardEvent(event_type, key, state)
    if not _root then return end
    return InteractionManager.handleKeyboardKey(_root, key, state)
end

--- Inyecta entrada de caracteres (texto) al sistema de UI.
function ReanUI.handleCharacterEvent(char)
    if not _root then return end
    return InteractionManager.handleCharacterInput(char)
end

-- ============================================================================
-- ANIMACIONES
-- ============================================================================

--- Crea una animación para un elemento.
--- @tparam UIElement element Elemento a animar.
--- @tparam table props Propiedades finales { width = 200, opacity = 0 }.
--- @tparam number duration Duración en milisegundos.
--- @tparam string|nil easing Nombre de la función de suavizado ("linear" por defecto).
--- @tparam function|nil onComplete Callback al finalizar.
function ReanUI.animate(element, props, duration, easing, onComplete)
    return AnimationManager.animate(element, props, duration, easing, onComplete)
end

-- ============================================================================
-- DEBUGGING Y EVENTOS
-- ============================================================================

--- Habilita o deshabilita el rastreo de eventos en consola.
--- @tparam boolean enabled
function ReanUI.traceEvents(enabled)
    local EventSystem = require("src.event.EventSystem")
    EventSystem.traceEvents(enabled)
end

--- Obtiene la lista de listeners registrados para un elemento.
--- @tparam UIElement element
--- @tparam string|nil type Tipo de evento opcional.
--- @treturn table
function ReanUI.getListeners(element, type)
    if element and element.getListeners then
        return element:getListeners(type)
    end
    return {}
end

return ReanUI
