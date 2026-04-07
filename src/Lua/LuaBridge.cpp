#include "../../include/ReanUI/Style.h"
#include <lua.hpp> // Incluye "lua.h", "lauxlib.h" en wrapper C++
#include <string>

using namespace ReanUI;

// =========================================================
// UTILIDADES DEL MOTOR DE C++
// =========================================================

// Convierte colores Hex (#RRGGBB o #AARRGGBB) a bits ARGB estándar en MTA / DirectX
uint32_t ParseHexToARGB(const std::string& hexStr) {
    if (hexStr.empty() || hexStr[0] != '#') return 0xFF000000; // Fallback: solid black
    
    try {
        std::string cleanHex = hexStr.substr(1);
        uint32_t raw_color = std::stoul(cleanHex, nullptr, 16);
        
        // Si nos pasan #RRGGBB (6 digitos) le inyectamos opacidad 255 (FF) por bitwise
        if (cleanHex.length() == 6) {
            return 0xFF000000 | raw_color; 
        }
        return raw_color; // Si mandó #AARRGGBB pasa exacto.
        
    } catch (...) {
        // Tolerancia a fallos: Devuelve rojo en caso de que manden letras
        return 0xFFFF0000; 
    }
}

// =========================================================
// PUENTE C-API -> LUA (EXPORTADOS)
// =========================================================

extern "C" int Lua_SetBackgroundColor(lua_State* L) {
    // 1. Obtener userdata
    // En C++20 almacenamos el `std::shared_ptr<StyleNode>` usando "Placement new" dentro de Userdata.
    auto** ud_wrapper = reinterpret_cast<std::shared_ptr<StyleNode>**>(luaL_checkudata(L, 1, "ReanElementMeta"));
    
    // 2. Validación Robusta Null-Safe
    if (!ud_wrapper || !*ud_wrapper || !(*ud_wrapper)->get()) {
        luaL_error(L, "[ReanUI: Exception] Access violation. Invalid or uninitialized userdata component.");
        return 0;
    }

    // 3. Conversión de Tipos con C-API Validator
    if (lua_type(L, 2) != LUA_TSTRING) {
        luaL_error(L, "[ReanUI: TypeError] SetBackgroundColor requires a HEX string (e.g., '#FF0000').");
        return 0; // Código de retorno de control
    }
    
    const char* str_val = lua_tostring(L, 2);
    
    // 4. Inyección en Memoria
    std::shared_ptr<StyleNode> node = **ud_wrapper;
    node->background_color = ParseHexToARGB(std::string(str_val));

    lua_pushboolean(L, 1);
    return 1;
}
