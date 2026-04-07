#include "rean_ui.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>

#define REAN_METATABLE "ReanElementMeta"

// ============================================================================
// UTILIDADES DEL PARSER ULTRA-LIGERO
// ============================================================================

// Aplica trim simulando mutabilidad pero solo manipulando punteros (Super rápido y seguro en memoria)
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

static float parse_px_value(const char *start, const char *end) {
    char buf[32];
    size_t len = end - start;
    if (len >= sizeof(buf)) len = sizeof(buf) - 1;
    strncpy(buf, start, len);
    buf[len] = '\0';
    return (float)atof(buf); // atof es rápido para parsing float genérico
}

// ============================================================================
// LÓGICA DE C INTERNA
// ============================================================================

static ReanElement* rean_alloc_element(void) {
    ReanElement* el = (ReanElement*)malloc(sizeof(ReanElement));
    if (el) {
        el->id = 1; 
        el->is_managed_by_lua = 1;
        el->width = 0.0f;
        el->height = 0.0f;
        el->bg_color = 0;
    }
    return el;
}

static void rean_free_element(ReanElement* el) {
    if (el) free(el);
}

// PARSER ESTRELLA LENGUAJE CSS
static void rean_parse_css_block(ReanElement *el, const char *css_string) {
    if (!css_string) return;

    const char *p = css_string;
    const char *key_start = p;
    const char *key_end = NULL;
    const char *val_start = NULL;
    
    // States: 0 = Buscando clave (key), 1 = Buscando valor (value)
    int state = 0; 
    
    while (*p) {
        if (state == 0) {
            if (*p == ':') {
                key_end = p;
                val_start = p + 1;
                state = 1;
            } else if (*p == ';') {
                // CSS mal formado (ej. "width;"), reiniciar tracker tolerante a fallos
                key_start = p + 1;
            }
        } else if (state == 1) {
            if (*p == ';') {
                const char *k_start, *k_end, *v_start, *v_end;
                str_trim(key_start, key_end, &k_start, &k_end);
                str_trim(val_start, p, &v_start, &v_end);
                
                size_t k_len = k_end - k_start;
                if (k_len == 5 && strncmp(k_start, "width", 5) == 0) {
                    el->width = parse_px_value(v_start, v_end);
                } else if (k_len == 6 && strncmp(k_start, "height", 6) == 0) {
                    el->height = parse_px_value(v_start, v_end);
                } else if (k_len == 16 && strncmp(k_start, "background-color", 16) == 0) {
                    el->bg_color = parse_hex_color(v_start, v_end);
                }
                
                state = 0;
                key_start = p + 1;
            }
        }
        p++;
    }
    
    // Soporte final tolerante (por si olvidaron el ';' en la última línea)
    if (state == 1) {
        const char *k_start, *k_end, *v_start, *v_end;
        str_trim(key_start, key_end, &k_start, &k_end);
        str_trim(val_start, p, &v_start, &v_end);
        size_t k_len = k_end - k_start;
        if (k_len == 5 && strncmp(k_start, "width", 5) == 0) {
            el->width = parse_px_value(v_start, v_end);
        } else if (k_len == 6 && strncmp(k_start, "height", 6) == 0) {
            el->height = parse_px_value(v_start, v_end);
        } else if (k_len == 16 && strncmp(k_start, "background-color", 16) == 0) {
            el->bg_color = parse_hex_color(v_start, v_end);
        }
    }
}

// ============================================================================
// MÉTODOS DE LA INSTANCIA (LUA)
// ============================================================================

static int rean_lua_set_stylesheet(lua_State *L) {
    ReanUserData* ud = (ReanUserData*)luaL_checkudata(L, 1, REAN_METATABLE);
    const char* css = luaL_checkstring(L, 2);
    
    if (!ud->element) {
        return luaL_error(L, "[ReanUI] Critical: Attempt to modify a destroyed or corrupted element.");
    }
    
    // Procesamiento lineal super rápido sin modificar el string nativo local
    rean_parse_css_block(ud->element, css);
    
    lua_pushboolean(L, 1);
    return 1;
}

static int rean_lua_set_style(lua_State *L) {
    ReanUserData* ud = (ReanUserData*)luaL_checkudata(L, 1, REAN_METATABLE);
    const char* prop = luaL_checkstring(L, 2);
    const char* value = luaL_checkstring(L, 3);
    
    if (!ud->element) {
        return luaL_error(L, "[ReanUI] Critical: Attempt to modify a destroyed element.");
    }

    // Compatibilidad retroactiva reenfocada a las nuevas variables numéricas primitivas
    if (strcmp(prop, "width") == 0) {
        ud->element->width = parse_px_value(value, value + strlen(value));
    } else if (strcmp(prop, "height") == 0) {
        ud->element->height = parse_px_value(value, value + strlen(value));
    } else if (strcmp(prop, "backgroundColor") == 0) {
        ud->element->bg_color = parse_hex_color(value, value + strlen(value));
    } else {
        lua_pushboolean(L, 0); 
        return 1;
    }
    
    lua_pushboolean(L, 1);
    return 1;
}

static int rean_lua_gc(lua_State *L) {
    ReanUserData* ud = (ReanUserData*)luaL_checkudata(L, 1, REAN_METATABLE);
    if (ud->element && ud->element->is_managed_by_lua) {
        rean_free_element(ud->element);
        ud->element = NULL;
    }
    return 0;
}

// Función auxiliar de test expuesta para validar la info pre-render sin getters
static int rean_lua_debug_print(lua_State *L) {
    ReanUserData* ud = (ReanUserData*)luaL_checkudata(L, 1, REAN_METATABLE);
    if (ud->element) {
        printf("[ReanUI-Debug] ID: %d | W: %.1f | H: %.1f | COLOR: #%06X\n", 
               ud->element->id, ud->element->width, ud->element->height, ud->element->bg_color);
    }
    return 0;
}

static const struct luaL_Reg rean_element_methods[] = {
    {"setStyle", rean_lua_set_style},
    {"setStyleSheet", rean_lua_set_stylesheet},
    {"debugPrint", rean_lua_debug_print},
    {"__gc", rean_lua_gc},
    {NULL, NULL}
};

// ============================================================================
// GLOBALES Y EXPORTS
// ============================================================================

static int rean_create_view(lua_State *L) {
    ReanUserData* ud = (ReanUserData*)lua_newuserdata(L, sizeof(ReanUserData));
    luaL_getmetatable(L, REAN_METATABLE);
    lua_setmetatable(L, -2);
    ud->element = rean_alloc_element();
    if (!ud->element) return luaL_error(L, "[ReanUI] Error allocating memory.");
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
