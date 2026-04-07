-- src/layout/FlexboxLayout.lua
-- Motor Flexbox simplificado de 2 pasadas (inspirado en yoga-layout).
-- Solo responsabilidad de cálculo: no modifica estilos, escribe en node._layout.

local FlexboxLayout = {}

-- ============================================================================
-- PROPIEDADES SOPORTADAS (referencia)
-- ============================================================================
-- flex-direction    : "row" | "column"           (default: "row")
-- justify-content   : "flex-start" | "center" | "flex-end" | "space-between" | "space-around"
-- align-items       : "flex-start" | "center" | "flex-end" | "stretch"
-- flex-grow         : number >= 0                 (default: 0)
-- flex-shrink       : number >= 0                 (default: 1)
-- flex-basis        : px | % | "auto"
-- gap               : px
-- margin / padding  : px (uniforme por ahora)
-- width / height    : px | % | "auto"

-- ============================================================================
-- UTILIDADES
-- ============================================================================

local function clamp(val, min_v, max_v)
    if val ~= val then return min_v end               -- NaN guard
    if val == math.huge or val == -math.huge then return max_v or min_v end
    return math.max(min_v, math.min(max_v or val, val))
end

--- Parsea un valor CSS a número. Retorna (number, unit_string).
--- @param val string|number
--- @param base number  Tamaño referencia para resolución de porcentajes
local function parse_value(val, base)
    if type(val) == "number" then return val, "px" end
    if type(val) ~= "string" then return 0, "auto" end

    val = val:match("^%s*(.-)%s*$")
    if val == "auto" or val == "" then return 0, "auto" end

    local n, unit = val:match("^([%-]?[%d%.]+)(.-)$")
    n = tonumber(n)
    if not n or n ~= n then return 0, "auto" end     -- NaN guard

    unit = (unit or "px"):lower():match("^%s*(.-)%s*$")
    if unit == "%" then return n * (base or 0) / 100, "%" end
    return n, unit == "" and "px" or unit
end

--- Extrae un número limpio de un estilo. Retorna 0 si no existe.
local function style_num(styles, key, base)
    local n = parse_value(styles[key], base)
    return clamp(n, 0)
end

--- Lee el shorthand de margin/padding y devuelve un valor uniforme.
local function shorthand(styles, key, base)
    local v, unit = parse_value(styles[key], base)
    return (unit == "auto") and 0 or clamp(v, 0)
end

-- ============================================================================
-- PASO 1: Resolución de dimensiones propias (sin posicionar)
-- ============================================================================

--- Calcula el tamaño "base" de un nodo antes de aplicar flex-grow/shrink.
--- @param node    UIElement
--- @param parent_w number   Ancho disponible del contenedor padre
--- @param parent_h number   Alto disponible del contenedor padre
--- @return number, number   (base_w, base_h)
local function resolve_base_size(node, parent_w, parent_h)
    local s = node:getAllStyles()

    local pad_x = shorthand(s, "padding", parent_w) * 2
    local pad_y = shorthand(s, "padding", parent_h) * 2
    local mar_x = shorthand(s, "margin", parent_w) * 2
    local mar_y = shorthand(s, "margin", parent_h) * 2

    local w_raw, w_unit = parse_value(s["width"], parent_w)
    local h_raw, h_unit = parse_value(s["height"], parent_h)

    local is_w_auto = (w_unit == "auto")
    local is_h_auto = (h_unit == "auto")

    -- Si es auto en ancho, por defecto intentamos ocupar el espacio (comportamiento block)
    -- Si es auto en alto, colapsamos a 0 hasta que haya contenido (simplificado)
    local base_w = is_w_auto and (parent_w - mar_x) or clamp(w_raw, 0)
    local base_h = is_h_auto and 0 or clamp(h_raw, 0)

    -- flex-basis sobreescribe el eje principal si está definido
    local fb_raw, fb_unit = parse_value(s["flex-basis"], parent_w)
    if fb_unit ~= "auto" then 
        base_w = clamp(fb_raw, 0) 
        is_w_auto = false
    end

    return base_w + pad_x, base_h + pad_y, is_w_auto, is_h_auto
end

-- ============================================================================
-- PASO 2: Distribución flex (grow/shrink) sobre el eje principal
-- ============================================================================

--- Aplica flex-grow/shrink sobre el espacio libre en el eje principal.
--- @param items       table   Lista de { node, main_size, cross_size, grow, shrink }
--- @param free_space  number  Espacio sobrante positivo o negativo
--- @param is_row      boolean True si el eje principal es horizontal
local function distribute_flex(items, free_space, is_row)
    if free_space == 0 or #items == 0 then return end

    if free_space > 0 then
        -- Fase grow
        local total_grow = 0
        for _, item in ipairs(items) do total_grow = total_grow + item.grow end
        if total_grow <= 0 then return end

        local unit = free_space / total_grow
        for _, item in ipairs(items) do
            item.main_size = item.main_size + (unit * item.grow)
        end

    else
        -- Fase shrink (free_space < 0, hay overflow)
        local total_shrink = 0
        for _, item in ipairs(items) do
            total_shrink = total_shrink + (item.shrink * item.main_size)
        end
        if total_shrink <= 0 then return end

        for _, item in ipairs(items) do
            local factor = (item.shrink * item.main_size) / total_shrink
            item.main_size = clamp(item.main_size + free_space * factor, 0)
        end
    end
end

-- ============================================================================
-- MOTOR DE LAYOUT PRINCIPAL (Recursivo)
-- ============================================================================

--- Calcula recursivamente las posiciones de todos los nodos del árbol.
--- Escribe los resultados en node._layout = { x, y, w, h }.
--- @param container UIElement  Nodo contenedor (raíz on primer llamado)
--- @param max_w     number
--- @param max_h     number
--- @param offset_x  number     Coordenada X absoluta de inicio (default 0)
--- @param offset_y  number     Coordenada Y absoluta de inicio (default 0)
function FlexboxLayout.calculateLayout(container, max_w, max_h, offset_x, offset_y)
    offset_x = offset_x or 0
    offset_y = offset_y or 0

    -- Guard de seguridad NaN / Inf
    max_w = clamp(max_w or 0, 0, 1e9)
    max_h = clamp(max_h or 0, 0, 1e9)

    local s = container:getAllStyles()

    local pad   = shorthand(s, "padding", max_w)
    local gap   = style_num(s, "gap", max_w)
    local dir   = (s["flex-direction"] or "column"):lower()
    local is_row = (dir == "row")
    local jc    = (s["justify-content"] or "flex-start"):lower()
    local ai    = (s["align-items"]     or "stretch"):lower()

    -- Área interna disponible tras el padding del contenedor
    local inner_w = clamp(max_w - pad * 2, 0)
    local inner_h = clamp(max_h - pad * 2, 0)

    -- Registrar el layout propio del contenedor
    container._layout = {
        x = offset_x,
        y = offset_y,
        w = max_w,
        h = max_h,
    }

    local children = container:getChildren()
    if #children == 0 then return end

    -- -------------------------
    -- PASADA 1: Resolver tamaños base de cada hijo e información flex
    -- -------------------------
    local items = {}
    local total_main = 0
    local total_cross = 0

    for _, child in ipairs(children) do
        local cs = child:getAllStyles()
        local mar     = shorthand(cs, "margin",   is_row and inner_w or inner_h)
        local bw, bh, is_w_auto, is_h_auto = resolve_base_size(child, inner_w, inner_h)

        local grow   = clamp(tonumber(cs["flex-grow"])   or 0, 0)
        local shrink = clamp(tonumber(cs["flex-shrink"]) or 1, 0)

        local main_size  = is_row and bw or bh
        local cross_size = is_row and bh or bw

        total_main  = total_main  + main_size  + mar * 2
        total_cross = math.max(total_cross, cross_size)

        table.insert(items, {
            node       = child,
            main_size  = main_size,
            cross_size = cross_size,
            grow       = grow,
            shrink     = shrink,
            margin     = mar,
            is_cross_auto = is_row and is_h_auto or is_w_auto,
        })
    end

    -- Espacio libre en el eje principal (descontamos los gaps)
    local gaps_total  = gap * math.max(0, #items - 1)
    local inner_main  = is_row and inner_w or inner_h
    local free_space  = inner_main - total_main - gaps_total

    -- -------------------------
    -- PASADA 2: Aplicar flex-grow / flex-shrink
    -- -------------------------
    distribute_flex(items, free_space, is_row)

    -- Recalcular free_space luego del flex (puede ser 0 exacto o remanente de shrink)
    local used_main = gaps_total
    for _, item in ipairs(items) do
        used_main = used_main + item.main_size + item.margin * 2
    end
    free_space = inner_main - used_main

    -- -------------------------
    -- justify-content: determina la posición de inicio en el eje principal
    -- -------------------------
    local cursor_main
    local between_space = 0
    local around_space  = 0

    if      jc == "flex-end"      then cursor_main = free_space
    elseif  jc == "center"        then cursor_main = free_space / 2
    elseif  jc == "space-between" then
        cursor_main = 0
        between_space = #items > 1 and (free_space / (#items - 1)) or 0
    elseif  jc == "space-around"  then
        around_space  = free_space / #items
        cursor_main   = around_space / 2
    else -- flex-start (default)
        cursor_main = 0
    end

    cursor_main = cursor_main + pad

    -- -------------------------
    -- Posicionar cada hijo e invocar recursión
    -- -------------------------
    -- Desplazamiento por Scroll
    local sx = container._scroll_x or 0
    local sy = container._scroll_y or 0
    local max_main_content = pad
    local max_cross_content = pad

    for _, item in ipairs(items) do
        -- (Alineación cross_pos se calcula aquí arriba como local por item)
        cursor_main = cursor_main + item.margin
        
        -- (Re-usamos la lógica de alineación previa que define cross_pos)
        local inner_cross = is_row and inner_h or inner_w
        local cross_pos
        if     ai == "flex-end"  then cross_pos = pad + inner_cross - item.cross_size - item.margin
        elseif ai == "center"    then cross_pos = pad + (inner_cross - item.cross_size) / 2
        elseif ai == "stretch" then
            if item.is_cross_auto then
                item.cross_size = inner_cross - item.margin * 2
            end
            cross_pos = pad + item.margin
        else -- flex-start
            cross_pos = pad + item.margin
        end

        local child_x, child_y, child_w, child_h
        if is_row then
            child_x = offset_x + cursor_main - sx
            child_y = offset_y + cross_pos - sy
            child_w = item.main_size
            child_h = item.cross_size
        else
            child_x = offset_x + cross_pos - sx
            child_y = offset_y + cursor_main - sy
            child_w = item.cross_size
            child_h = item.main_size
        end

        FlexboxLayout.calculateLayout(item.node, child_w, child_h, child_x, child_y)

        -- Actualizar máximos para scroll (Tamaño del contenido real)
        max_main_content = math.max(max_main_content, cursor_main + item.main_size + pad)
        max_cross_content = math.max(max_cross_content, cross_pos + item.cross_size + pad)

        -- Avanzar cursor
        cursor_main = cursor_main + item.main_size + item.margin + gap + between_space
        if jc == "space-around" then cursor_main = cursor_main + around_space end
    end

    if is_row then
        container._content_w = max_main_content
        container._content_h = max_cross_content
    else
        container._content_w = max_cross_content
        container._content_h = max_main_content
    end
end

-- ============================================================================
-- GETTER DE LAYOUT CALCULADO
-- ============================================================================

--- Retorna el resultado del layout de un nodo tras calculateLayout().
--- @param node UIElement
--- @return table|nil  { x, y, w, h }
function FlexboxLayout.getNodeLayout(node)
    return node._layout
end

return FlexboxLayout
