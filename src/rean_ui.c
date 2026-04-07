#include "rean_ui.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>

#define REAN_METATABLE "ReanElementMeta"

// ============================================================================
// UTILIDADES DEL PARSER (SOPORTE PORCENTUAL Y MATEMÁTICO)
// ============================================================================

static void str_trim(const char *start, const char *end, const char **out_start, const char **out_end) {
    while (start < end && isspace((unsigned char)*start)) start++;
    while (end > start && isspace((unsigned char)*(end - 1))) end--;
    *out_start = start;
    *out_end = end;
}

static uint32_t parse_hex_color(const char *start, const char *end) {
    if (start < end && *start == '#') start++;
    uint32_t color = 0;
    while (start < end) {
        char c = *start;
        color <<= 4;
        if (c >= '0' && c <= '9') color |= (c - '0');
        else if (c >= 'A' && c <= 'F') color |= (c - 'A' + 10);
        else if (c >= 'a' && c <= 'f') color |= (c - 'a' + 10);
        start++;
    }
    return color;
}

// Retorna el valor float numérico e inyecta en out_is_percent si contenía '%'
static float parse_css_value(const char *start, const char *end, uint8_t *out_is_percent) {
    char buf[32];
    size_t len = end - start;
    if (len >= sizeof(buf)) len = sizeof(buf) - 1;
    strncpy(buf, start, len);
    buf[len] = '\0';
    
    *out_is_percent = 0;
    for (int i = len - 1; i >= 0; i--) {
        if (buf[i] == '%') {
            *out_is_percent = 1;
            buf[i] = '\0'; // Limpiamos el % para que atof lo lea sin errores
            break;
        } else if (buf[i] == 'x' || buf[i] == 'p') {
            buf[i] = '\0'; // Limpiamos los 'px' al final
        }
    }
    return (float)atof(buf);
}

// ============================================================================
// MEMORIA Y ÁRBOL DE VARIABLES C INTERNAS
// ============================================================================

static ReanElement* rean_alloc_element(void) {
    /* Usar rui_malloc para que el allocator centralizado pueda rastrear esta alloc */
    ReanElement* el = (ReanElement*)rui_malloc(sizeof(ReanElement));
    if (el) {
        el->id = 1;
        el->is_managed_by_lua = 1;
        el->width = 0.0f; el->height = 0.0f;
        el->width_is_percent = 0; el->height_is_percent = 0;
        el->bg_color = 0;

        el->computed_x = 0; el->computed_y = 0;
        el->computed_width = 0; el->computed_height = 0;

        el->parent = NULL;
        el->children = NULL;
        el->num_children = 0;
        el->cap_children = 0;
    }
    return el;
}


static void rean_free_element(ReanElement* el) {
    if (!el) return;
    if (el->children) {
        rui_free(el->children);
        el->children = NULL;
    }
    rui_free(el);
}


// ============================================================================
// MOTOR DE LAYOUT BOX (ALTO RENDIMIENTO EN PROFUNDIDAD)
// ============================================================================

void rean_calculate_layout(ReanElement *node, float parent_x, float parent_y, float parent_w, float parent_h) {
    if (!node) return;
    
    // --- Box Model (Fase 1): Cálculo Absoluto de Dimensiones ---
    // Si la medida es un porcentaje, calculamos respecto al computed_width/height inyectado por el padre
    if (node->width_is_percent) {
        node->computed_width = parent_w * (node->width / 100.0f);
    } else {
        node->computed_width = node->width;
    }
    
    if (node->height_is_percent) {
        node->computed_height = parent_h * (node->height / 100.0f);
    } else {
        node->computed_height = node->height;
    }
    
    // --- Box Model (Fase 2): Flujo Descendente Estándar (Block Flow) ---
    // Todos los hijos partiendo desde el (X, Y) top-left local computado de ESTE nodo anfitrión.
    float current_child_y = node->computed_y; 
    
    for (int i = 0; i < node->num_children; i++) {
        ReanElement *child = node->children[i];
        
        // Coordenadas Absolutas al root (Pantalla completa), útil para dibujado en DirectX/OpenGL final
        child->computed_x = node->computed_x;       // Snap al left del padre
        child->computed_y = current_child_y;        // Bajar en base a hermanos superiores
        
        // --- Recursividad: Viaje en Profundidad (DFS Layout) ---
        // Al hijo le mandamos TUS computed_width/height como su lienzo/bounds parental base
        rean_calculate_layout(child, child->computed_x, child->computed_y, node->computed_width, node->computed_height);
        
        // Sumamos el area top-bottom del hijo recientemente resuelto.
        // Esto empuja matemáticamente hacia abajo al siguiente hijo (Display Block behavior).
        current_child_y += child->computed_height; 
    }
}

// ============================================================================
// PARSER EXCLUSIVO CSS (UPDATE CON %)
// ============================================================================

/* Aplica una propiedad CSS parseada a un elemento. Extrae la duplicación del parser. */
static void apply_css_property(ReanElement *el,
                                const char *k_s, const char *k_e,
                                const char *v_s, const char *v_e) {
    size_t klen = (size_t)(k_e - k_s);
    if (klen == 5 && strncmp(k_s, "width", 5) == 0) {
        el->width = parse_css_value(v_s, v_e, &el->width_is_percent);
    } else if (klen == 6 && strncmp(k_s, "height", 6) == 0) {
        el->height = parse_css_value(v_s, v_e, &el->height_is_percent);
    } else if (klen == 16 && strncmp(k_s, "background-color", 16) == 0) {
        el->bg_color = parse_hex_color(v_s, v_e);
    }
}

static void rean_parse_css_block(ReanElement *el, const char *css_string) {
    if (!css_string) return;
    const char *p = css_string;
    const char *key_start = p;
    const char *key_end = NULL;
    const char *val_start = NULL;
    int state = 0;

    while (*p) {
        if (state == 0) {
            if (*p == ':') {
                key_end = p; val_start = p + 1; state = 1;
            } else if (*p == ';') {
                key_start = p + 1;
            }
        } else if (state == 1) {
            if (*p == ';') {
                const char *k_s, *k_e, *v_s, *v_e;
                str_trim(key_start, key_end, &k_s, &k_e);
                str_trim(val_start, p, &v_s, &v_e);
                apply_css_property(el, k_s, k_e, v_s, v_e);
                state = 0; key_start = p + 1;
            }
        }
        p++;
    }

    /* Manejar la última declaración sin punto y coma final */
    if (state == 1) {
        const char *k_s, *k_e, *v_s, *v_e;
        str_trim(key_start, key_end, &k_s, &k_e);
        str_trim(val_start, p, &v_s, &v_e);
        apply_css_property(el, k_s, k_e, v_s, v_e);
    }
}


// ============================================================================
// LUA API INTERFACES (MÉTODOS OOP)
// ============================================================================

static int rean_lua_add_child(lua_State *L) {
    ReanUserData* parent_ud = (ReanUserData*)luaL_checkudata(L, 1, REAN_METATABLE);
    ReanUserData* child_ud = (ReanUserData*)luaL_checkudata(L, 2, REAN_METATABLE);
    
    ReanElement* parent = parent_ud->element;
    ReanElement* child = child_ud->element;
    
    if (!parent || !child) {
        return luaL_error(L, "[ReanUI] Attempt to use a destroyed Element.");
    }
    
    // STRICT SECURITY: Prevención matemática de referencias cíclicas cruzadas (Anti Stack-Overflow)
    ReanElement* walker = parent;
    while (walker != NULL) {
        if (walker == child) {
            return luaL_error(L, "[ReanUI] Cyclic Dependency Blocked! You cannot add a parent/ancestor as a child.");
        }
        walker = walker->parent;
    }
    
    // Inserción en Vector Dinámico de Punteros C (Aseguramos la capacidad antes de asignar)
    if (parent->num_children >= parent->cap_children) {
        int new_cap = parent->cap_children == 0 ? 4 : parent->cap_children * 2;
        ReanElement** new_arr = (ReanElement**)realloc(parent->children, sizeof(ReanElement*) * new_cap);
        if (!new_arr) {
            return luaL_error(L, "[ReanUI] Out of Heap memory scaling children array");
        }
        parent->children = new_arr;
        parent->cap_children = new_cap;
    }
    
    // Vínculo bidireccional puro C
    child->parent = parent;
    parent->children[parent->num_children] = child;
    parent->num_children++;
    
    // IMPORTANTE: Dejamos child->is_managed_by_lua INTACTO para que Lua recolecte el hijo si nadie lo apunta
    return 0;
}

static int rean_lua_calculate_layout(lua_State *L) {
    ReanUserData* parent_ud = (ReanUserData*)luaL_checkudata(L, 1, REAN_METATABLE);
    if (!parent_ud->element) return 0;
    
    // Tomar las medidas raíces estáticas que simulan ser el anfitrión (1920x1080 defecto)
    float screen_w = (float)luaL_optnumber(L, 2, 1920.0);
    float screen_h = (float)luaL_optnumber(L, 3, 1080.0);
    
    // Resetear inicio de lienzo nativo 
    parent_ud->element->computed_x = 0;
    parent_ud->element->computed_y = 0;
    
    // Lanzar el motor super sónico C
    rean_calculate_layout(parent_ud->element, 0, 0, screen_w, screen_h);
    
    return 0;
}

static int rean_lua_set_stylesheet(lua_State *L) {
    ReanUserData* ud = (ReanUserData*)luaL_checkudata(L, 1, REAN_METATABLE);
    const char* css = luaL_checkstring(L, 2);
    if (ud->element) rean_parse_css_block(ud->element, css);
    return 0;
}

static int rean_lua_debug_print(lua_State *L) {
    ReanUserData* ud = (ReanUserData*)luaL_checkudata(L, 1, REAN_METATABLE);
    ReanElement* el = ud->element;
    if (el) {
        printf("[ReanUI-RenderBox] ID: %d | Absolute: X: %.1f, Y: %.1f | Calc WxH: %.1fx%.1f | ChildCount: %d\n", 
               el->id, el->computed_x, el->computed_y, el->computed_width, el->computed_height, el->num_children);
    }
    return 0;
}

static int rean_lua_gc(lua_State *L) {
    ReanUserData* ud = (ReanUserData*)luaL_checkudata(L, 1, REAN_METATABLE);
    // Limpieza de recursos locales de arrays si la OOP del Lua decide colapsar el marco (GC tick)
    if (ud->element && ud->element->is_managed_by_lua) {
        rean_free_element(ud->element);
        ud->element = NULL;
    }
    return 0;
}

static const struct luaL_Reg rean_element_methods[] = {
    {"addChild", rean_lua_add_child},
    {"calculateLayout", rean_lua_calculate_layout},
    {"setStyleSheet", rean_lua_set_stylesheet},
    {"debugPrint", rean_lua_debug_print},
    {"__gc", rean_lua_gc},
    {NULL, NULL}
};

static int rean_create_view(lua_State *L) {
    ReanUserData* ud = (ReanUserData*)lua_newuserdata(L, sizeof(ReanUserData));
    luaL_getmetatable(L, REAN_METATABLE);
    lua_setmetatable(L, -2);
    ud->element = rean_alloc_element();
    return 1; 
}

static const struct luaL_Reg rean_module_funcs[] = {
    {"createView", rean_create_view},
    {NULL, NULL}
};

REAN_API int luaopen_reanui(lua_State *L) {
    luaL_newmetatable(L, REAN_METATABLE);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_register(L, NULL, rean_element_methods);
    lua_pop(L, 1);
    luaL_register(L, "reanui", rean_module_funcs);
    return 1;
}
