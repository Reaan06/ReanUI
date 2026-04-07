/**
 * @file rean_ui.h
 * @brief Core structures and API definitions for ReanUI Native Engine.
 */

#ifndef REAN_UI_H
#define REAN_UI_H

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdint.h>

/**
 * @struct ReanElement
 * @brief Internal C structure representing a UI node in the DOM.
 * Optimized for cache locality and fast layout calculations.
 */
typedef struct ReanElement ReanElement;

struct ReanElement {
    int id; ///< Unique identifier for the element.
    
    /* Layout Directives (Pre-computed from CSS) */
    float width;              ///< Desired width (px or %).
    float height;             ///< Desired height (px or %).
    uint8_t width_is_percent;  ///< Flag: 1 if width is %, 0 if px.
    uint8_t height_is_percent; ///< Flag: 1 if height is %, 0 if px.
    uint32_t bg_color;         ///< Background color in 0xRRGGBBAA format.
    
    /* Computed Layout Results (Final screen coordinates) */
    float computed_x;      ///< Final X position in the screen.
    float computed_y;      ///< Final Y position in the screen.
    float computed_width;  ///< Final width in pixels.
    float computed_height; ///< Final height in pixels.
    
    /* Hierarchy Management */
    ReanElement* parent;      ///< Pointer to the parent node (NULL for root).
    ReanElement** children;   ///< Dynamic array of pointers to child nodes.
    int num_children;         ///< Current number of children.
    int cap_children;         ///< Current capacity of the children array.
    
    int is_managed_by_lua;    ///< Flag indicating if Lua GC should track this.
};

/**
 * @struct ReanUserData
 * @brief Lua Userdata structure for ReanElement wrapping.
 */
typedef struct {
    ReanElement* element;
} ReanUserData;

#ifdef _WIN32
  #define REAN_API __declspec(dllexport)
#else
  #define REAN_API __attribute__((visibility("default")))
#endif

/**
 * @brief Main entry point for the Lua module.
 * Registers classes and global functions in the Lua state.
 */
REAN_API int luaopen_reanui(lua_State *L);

#endif // REAN_UI_H
