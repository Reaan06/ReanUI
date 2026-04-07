--- @class UIElement
--- Clase raíz de todos los componentes visuales de ReanUI.
--- Implementa la composición básica: EventTarget + StyleManager + Jerarquía DOM.
local UIElement = {}
UIElement.__index = UIElement

-- Auto-incremento global thread-safe (dentro de un mismo lua_State)
local _next_id = 0
local function generate_id()
    _next_id = _next_id + 1
    return _next_id
end

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

--- Crea un nuevo elemento UI.
--- @tparam string tag Tipo de nodo (ej: "div", "button", "text").
--- @tparam table|nil attrs Atributos iniciales { id = "...", class = "..." }.
--- @treturn UIElement Una nueva instancia de UIElement.
function UIElement.new(tag, attrs)
    if type(tag) ~= "string" or tag == "" then
        error("[ReanUI:UIElement] tag must be a non-empty string.")
    end

    local self = setmetatable({}, UIElement)

    -- Identidad
    self._uid       = generate_id()
    self._tag       = tag
    self._id        = nil
    self._classes   = {}           -- Set: { ["btn"]=true, ["active"]=true }
    self._data      = {}           -- Atributos data-*

    -- Composición (Delegación a módulos especializados)
    self._listeners = {}           -- Almacén de EventTarget
    self._style     = StyleManager.new()
    self._dirty     = true         -- Requiere re-dibujado
    self._child_dirty = false      -- Algún descendiente requiere re-dibujado
    self._z_index   = 0            -- Capa de dibujado

    -- Shaders
    self._shaderPath = nil
    self._shaderParams = {}

    -- Foco e Interacción
    self._focusable = false        -- ¿Puede recibir foco de teclado?

    -- Jerarquía DOM
    self._parent    = nil          -- ref débil manual
    self._children  = {}           -- array ordenado

    -- Estado de ciclo de vida
    self._mounted   = false
    self._destroyed = false

    -- Hook: el StyleManager notifica cambios para que UIElement dispare el evento
    self._style:onChanged(function(prop, value)
        self:markDirty()
        self:dispatchEvent("stylechange", { property = prop, value = value })
    end)

    -- Aplicar atributos iniciales si se proporcionaron
    if type(attrs) == "table" then
        if attrs.id then self:setId(attrs.id) end
        if attrs.class then self:addClass(attrs.class) end
    end

    -- Ciclo de vida: onCreate
    self:onCreate()

    return self
end

-- ============================================================================
-- IDENTIDAD Y ATRIBUTOS
-- ============================================================================

--- Obtiene el tag del elemento.
--- @treturn string
function UIElement:getTag()   return self._tag end

--- Obtiene el identificador único (UID) generado por el sistema.
--- @treturn number
function UIElement:getUid()   return self._uid end

--- Asigna un ID al elemento (para selectores CSS #id).
--- @tparam string id
--- @treturn UIElement self
function UIElement:setId(id)
    if type(id) ~= "string" then return self end
    self._id = id
    return self
end

--- Obtiene el ID del elemento.
--- @treturn string|nil
function UIElement:getId()    return self._id end

--- Añade una o más clases separadas por espacio ("btn primary active").
--- @tparam string class_str
--- @treturn UIElement self
function UIElement:addClass(class_str)
    if type(class_str) ~= "string" then return self end
    for token in class_str:gmatch("%S+") do
        self._classes[token] = true
    end
    return self
end

function UIElement:removeClass(class_str)
    if type(class_str) ~= "string" then return self end
    for token in class_str:gmatch("%S+") do
        self._classes[token] = nil
    end
    return self
end

function UIElement:hasClass(name)
    return self._classes[name] == true
end

function UIElement:getClasses()
    local list = {}
    for k in pairs(self._classes) do list[#list + 1] = k end
    return list
end

--- Atributos data-* genéricos
function UIElement:setData(key, value)
    if type(key) ~= "string" then return self end
    self._data[key] = value
    return self
end

function UIElement:getData(key)
    return self._data[key]
end

-- ============================================================================
-- ESTILOS (Delegados al StyleManager)
-- ============================================================================

--- Cambia una propiedad de estilo CSS individual.
--- @tparam string prop Nombre de la propiedad (ej: "background-color").
--- @tparam any value Nuevo valor.
--- @treturn UIElement self
function UIElement:setStyle(prop, value)
    local ok, err = self._style:set(prop, value)
    if not ok and err then
        print(string.format("[ReanUI:Warning] %s (element: %s)",
              err, tostring(self._id or self._uid)))
    end
    return self
end

function UIElement:getStyle(prop)
    return self._style:get(prop)
end

--- Aplica un bloque de estilos CSS (formato string) completo.
--- @tparam string css_block Ejemplo: "width: 100px; height: 50px;"
--- @treturn UIElement self
function UIElement:setStyleSheet(css_block)
    self._style:applyBlock(css_block)
    return self
end

function UIElement:getAllStyles()
    return self._style:getAll()
end

function UIElement:animate(props, duration, easing, onComplete)
    local AnimationManager = require("src.core.AnimationManager")
    AnimationManager.animate(self, props, duration, easing, onComplete)
    return self
end

-- ============================================================================
-- SHADERS
-- ============================================================================

--- Asigna un shader al elemento.
-- @tparam string path Ruta al archivo .fx.
-- @tparam table|nil params Parámetros iniciales para el shader.
function UIElement:setShader(path, params)
    self._shaderPath = path
    self._shaderParams = params or {}
    self:markDirty()
    return self
end

function UIElement:getShaderPath()
    return self._shaderPath
end

function UIElement:getShaderParams()
    return self._shaderParams
end

--- Actualiza un parámetro específico del shader.
function UIElement:setShaderValue(name, value)
    self._shaderParams[name] = value
    self:markDirty() -- Marcar como dirty para que el renderer aplique el cambio
    return self
end

-- ============================================================================
-- RENDER & DIRTY SYSTEM
-- ============================================================================

function UIElement:markDirty()
    if self._dirty then return end
    self._dirty = true
    if self._parent then
        self._parent:markChildDirty()
    end
end

function UIElement:markChildDirty()
    if self._child_dirty then return end
    self._child_dirty = true
    if self._parent then
        self._parent:markChildDirty()
    end
end

function UIElement:isDirty()
    return self._dirty or self._child_dirty
end

function UIElement:setZIndex(z)
    self._z_index = tonumber(z) or 0
    self:markDirty()
    return self
end

function UIElement:getZIndex()
    return self._z_index
end

-- ============================================================================
-- GESTIÓN DE FOCO
-- ============================================================================

function UIElement:setFocusable(bool)
    self._focusable = bool == true
    return self
end

function UIElement:isFocusable()
    return self._focusable
end

--- Intenta dar el foco a este elemento.
function UIElement:focus()
    if not self._focusable or self._destroyed then return false end
    local InteractionManager = require("src.core.InteractionManager")
    InteractionManager.setFocusedElement(self)
    return true
end

--- Quita el foco de este elemento.
function UIElement:blur()
    local InteractionManager = require("src.core.InteractionManager")
    if InteractionManager.getFocusedElement() == self then
        InteractionManager.setFocusedElement(nil)
    end
end

-- ============================================================================
-- JERARQUÍA PADRE-HIJO
-- ============================================================================

--- Añade un elemento hijo al final de la lista de hijos.
--- @tparam UIElement child El componente a añadir.
--- @treturn UIElement self
function UIElement:appendChild(child)
    if not child or child._destroyed then
        error("[ReanUI:UIElement] Cannot append a nil or destroyed element.")
    end
    if child == self then
        error("[ReanUI:UIElement] Cyclic reference: cannot append an element to itself.")
    end

    -- Prevención de ciclos ascendentes
    local walker = self._parent
    while walker do
        if walker == child then
            error("[ReanUI:UIElement] Cyclic dependency: child is an ancestor of this element.")
        end
        walker = walker._parent
    end

    -- Si el hijo ya tiene padre, desvincularlo primero
    if child._parent then
        child._parent:removeChild(child)
    end

    child._parent = self
    self._children[#self._children + 1] = child

    if self._mounted and not child._mounted then
        child:_propagateMount()
    end

    return self
end

--- Elimina un elemento hijo de la lista.
--- @tparam UIElement child El componente a eliminar.
--- @treturn UIElement self
function UIElement:removeChild(child)
    if not child then return self end

    for i, c in ipairs(self._children) do
        if c == child then
            table.remove(self._children, i)
            child._parent = nil
            if child._mounted then
                child:_propagateUnmount()
            end
            return self
        end
    end
    return self
end

function UIElement:getParent()
    return self._parent
end

function UIElement:getChildren()
    return self._children
end

function UIElement:getChildCount()
    return #self._children
end

-- ============================================================================
-- EVENTOS (EventTarget Implementation)
-- ============================================================================

function UIElement:addEventListener(type, callback, options)
    return EventSystem.EventTarget.addEventListener(self, type, callback, options)
end

function UIElement:removeEventListener(type, callback, capture)
    return EventSystem.EventTarget.removeEventListener(self, type, callback, capture)
end

function UIElement:getListeners(type)
    return EventSystem.EventTarget.getListeners(self, type)
end

--- Dispara un evento usando el despachador centralizado (soporta propagación).
--- @param type string Nombre del evento
--- @param data table Datos adicionales
function UIElement:dispatchEvent(type, data)
    local event = EventSystem.Event.new(type, data)
    return EventSystem.EventDispatcher.dispatch(self, event)
end

-- ============================================================================
-- CICLO DE VIDA
-- ============================================================================

--- Invocado al instanciar. Override en subclases.
function UIElement:onCreate()
    self:dispatchEvent("create")
end

--- Invocado cuando el elemento entra al árbol visible. Override en subclases.
function UIElement:onRender()
    self:dispatchEvent("render")
end

--- Invocado al destruir. Override en subclases.
function UIElement:onDestroy()
    self:dispatchEvent("destroy")
end

--- Destruye el elemento y todos sus hijos recursivamente (liberación segura).
function UIElement:destroy()
    if self._destroyed then return end

    -- Destruir hijos bottom-up
    for i = #self._children, 1, -1 do
        self._children[i]:destroy()
    end

    -- Desvincularse del padre
    if self._parent then
        self._parent:removeChild(self)
    end

    self:onDestroy()

    -- Limpiar todas las referencias internas para evitar memory leaks
    -- _listeners es el almacén de EventTarget (ya NO existe self._events)
    self._listeners = {}
    self._style:clear()
    self._children  = {}
    self._parent    = nil
    self._data      = {}
    self._classes   = {}
    self._destroyed = true
end

function UIElement:isDestroyed()
    return self._destroyed
end

-- ============================================================================
-- PROPAGACIÓN INTERNA DE MOUNT/UNMOUNT
-- ============================================================================

function UIElement:_propagateMount()
    self._mounted = true
    self:dispatchEvent("mount")
    for _, child in ipairs(self._children) do
        child:_propagateMount()
    end
end

function UIElement:_propagateUnmount()
    for _, child in ipairs(self._children) do
        child:_propagateUnmount()
    end
    self._mounted = false
    self:dispatchEvent("unmount")
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function UIElement:debugPrint(indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    local id_str = self._id and ('#' .. self._id) or ""

    -- Construir class_str con table.concat para evitar O(n) en concatenación sucesiva
    local class_parts = {}
    for k in pairs(self._classes) do class_parts[#class_parts + 1] = "." .. k end
    local class_str = table.concat(class_parts)

    print(string.format("%s<%s%s%s> (uid:%d, dirty:%s, children:%d)",
        prefix, self._tag, id_str, class_str,
        self._uid, tostring(self._dirty), #self._children))

    for _, child in ipairs(self._children) do
        child:debugPrint(indent + 1)
    end
end

return UIElement
