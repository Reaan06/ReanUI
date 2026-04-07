#ifndef REAN_UI_H
#define REAN_UI_H

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdint.h>

// Estructura interna C (DOM Node optimizado)
typedef struct {
    int id;
    
    // Optimizaciones: Uso de primitivas nativas en lugar de arrays de chars
    float width;
    float height;
    uint32_t bg_color;
    
    int is_managed_by_lua;
} ReanElement;

// Interface Userdata
typedef struct {
    ReanElement* element;
} ReanUserData;

// Macro de exportación estricta
#ifdef _WIN32
  #define REAN_API __declspec(dllexport)
#else
  #define REAN_API __attribute__((visibility("default")))
#endif

REAN_API int luaopen_reanui(lua_State *L);

#endif // REAN_UI_H
