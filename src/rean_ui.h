#ifndef REAN_UI_H
#define REAN_UI_H

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdint.h>

// Pre-declaración para auto-referenciar la jerarquía
typedef struct ReanElement ReanElement;

// Estructura interna C (Box Model DOM Node)
struct ReanElement {
    int id;
    
    // Layout Inicial (Directivas del CSS pre-computadas)
    float width;
    float height;
    uint8_t width_is_percent;  // Flag optimizada (1 = % , 0 = px)
    uint8_t height_is_percent; // Flag optimizada (1 = % , 0 = px)
    uint32_t bg_color;
    
    // Resultados del Motor Layout (Coordenadas de dibujado finales, ultra rápidas pre-frame)
    float computed_x;
    float computed_y;
    float computed_width;
    float computed_height;
    
    // Relación de parentesco
    ReanElement* parent;
    ReanElement** children; // Arreglo Dinámico contiguo amigable en caché
    int num_children;
    int cap_children;
    
    int is_managed_by_lua;
};

// Interface Userdata
typedef struct {
    ReanElement* element;
} ReanUserData;

#ifdef _WIN32
  #define REAN_API __declspec(dllexport)
#else
  #define REAN_API __attribute__((visibility("default")))
#endif

REAN_API int luaopen_reanui(lua_State *L);

#endif // REAN_UI_H
