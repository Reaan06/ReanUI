#pragma once

#include <cstdint>
#include <memory>
#include <vector>

namespace ReanUI {

// Alineación estricta de 16-bytes para acoplamiento de caché L1 (SIMD friendly).
// Usamos final para asegurar que el compilador desvirtualice accesos al no haber polimorfismo.
struct alignas(16) StyleNode final {
    // Box Model Properties: Top, Right, Bottom, Left
    float margin[4]{0.f, 0.f, 0.f, 0.f};
    float padding[4]{0.f, 0.f, 0.f, 0.f};
    
    // Core Dimensions (User Defined)
    float width{0.f};
    float height{0.f};
    
    // Decorators
    float border_radius{0.f};
    uint32_t background_color{0x00000000}; // Formato AARRGGBB nativo MTA/DirectX

    // Graph Relations (Safety Memory Management)
    // std::weak_ptr rompe el ciclo de referencias fuertes impidiendo fugas (Memory Leaks)
    std::weak_ptr<StyleNode> parent;  
    
    // std::shared_ptr asegura que los hijos vivan mientras el contenedor padre viva
    std::vector<std::shared_ptr<StyleNode>> children;

    // Computed Output (Cálculos de retorno para el Renderer)
    float computed_x{0.f};
    float computed_y{0.f};
    float computed_width{0.f};
    float computed_height{0.f};
};

} // namespace ReanUI
