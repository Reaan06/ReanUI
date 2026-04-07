#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include "dom/node.h"
#include "css/parser.h"
#include "layout/box_model.h"

typedef struct {
    Node* node;
    int is_managed_by_lua;
} LuaNodeUserData;

static int l_parse_css(lua_State *L) {
    const char* css_string = luaL_checkstring(L, 1);

    Node* root = rui_parse_css(css_string);
    if (!root) {
        lua_pushnil(L);
        lua_pushstring(L, "[ReanUI] Failed to parse CSS: invalid or empty input.");
        return 2;  /* Patrón estándar Lua: nil, mensaje_de_error */
    }

    LuaNodeUserData *ud = (LuaNodeUserData *)lua_newuserdata(L, sizeof(LuaNodeUserData));
    luaL_getmetatable(L, "ReanUI_Node");
    lua_setmetatable(L, -2);

    ud->node = root;
    ud->is_managed_by_lua = 1;

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
    luaL_newmetatable(L, "ReanUI_Node");
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_register(L, NULL, node_methods);
    
    luaL_register(L, "reanui", reanui_funcs);
    return 1;
}
