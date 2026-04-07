#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdlib.h>
#include "dom/node.h"
#include "css/parser.h"
#include "layout/box_model.h"

typedef struct {
    Node* node;
    int is_managed_by_lua;
} LuaNodeUserData;

static int l_parse_css(lua_State *L) {
    const char* css_string = luaL_checkstring(L, 1);

    rui_css_stylesheet_t* sheet = rui_parse_css(css_string);
    if (!sheet) {
        lua_pushnil(L);
        lua_pushstring(L, "[ReanUI] Failed to parse CSS: invalid syntax or out of memory.");
        return 2;
    }

    lua_newtable(L);
    for (uint32_t i = 0; i < sheet->num_rules; i++) {
        rui_css_rule_t* rule = &sheet->rules[i];
        
        lua_pushstring(L, rule->selector);
        lua_newtable(L);
        
        for (uint32_t j = 0; j < rule->num_props; j++) {
            rui_css_prop_t* p = &rule->props[j];
            lua_pushstring(L, p->name);
            
            if (p->type == RUI_CSS_TYPE_COLOR) {
                lua_pushnumber(L, (lua_Number)p->val.color);
            } else {
                lua_pushstring(L, p->val.str);
            }
            lua_settable(L, -3);
        }
        lua_settable(L, -3);
    }

    rui_free_css_stylesheet(sheet);
    return 1;
}

static int l_node_gc(lua_State *L) {
    LuaNodeUserData *ud = (LuaNodeUserData *)luaL_checkudata(L, 1, "ReanUI_Node");
    if (ud->node && ud->is_managed_by_lua) {
        rui_node_destroy(ud->node);
        ud->node = NULL;
    }
    return 0;
}

static int l_layout_tick(lua_State *L) {
    LuaNodeUserData *ud = (LuaNodeUserData *)luaL_checkudata(L, 1, "ReanUI_Node");
    if (ud->node) {
        rui_layout_compute(ud->node);
    }
    return 0;
}

static const struct luaL_Reg node_methods[] = {
    {"layout", l_layout_tick},
    {"__gc", l_node_gc},
    {NULL, NULL}
};

static const struct luaL_Reg reanui_funcs[] = {
    {"parse_css", l_parse_css},
    {NULL, NULL}
};

#ifdef _WIN32
  #define LUA_MOD_API __declspec(dllexport)
#else
  #define LUA_MOD_API __attribute__((visibility("default")))
#endif

LUA_MOD_API int luaopen_reanui(lua_State *L) {
    // Crear metatable para nodos
    luaL_newmetatable(L, "ReanUI_Node");
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, node_methods, 0);
    lua_pop(L, 1);
    
    // Crear librería principal
    luaL_newlib(L, reanui_funcs);
    return 1;
}
