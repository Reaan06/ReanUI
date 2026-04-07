#include "../../include/ReanUI/Style.h"

namespace ReanUI {

class LayoutProcessor {
public:
    /**
     * Calcula las posiciones absolutas en pantalla (Box Model Flow)
     * @param node Nodo objetivo del layout
     * @param global_x Posición base originaria heredada (X)
     * @param global_y Posición base originaria heredada (Y)
     * @param dpi_scale Ajuste de densidades resolutivas para UI multi-pantalla escalable
     */
    static void CalculateLayout(std::shared_ptr<StyleNode>& node, float global_x, float global_y, float dpi_scale = 1.0f) {
        if (!node) return; // Tolerancia a punteros caducados

        // 1. EXPANSIÓN BOX MODEL: Compute Area WxH
        // (Content Width + Padding L + Padding R) escalado al DPI global
        node->computed_width = (node->width + node->padding[1] + node->padding[3]) * dpi_scale;
        node->computed_height = (node->height + node->padding[0] + node->padding[2]) * dpi_scale;

        // 2. OFFSET LAYOUT ROOT: Posición XY inicial sumando margen top/left.
        node->computed_x = global_x + (node->margin[3] * dpi_scale);
        node->computed_y = global_y + (node->margin[0] * dpi_scale);

        // 3. FLUJO RECURSIVO (Stack Vertical "Display: Block")
        // La zona interna de este nodo, a partir de la cual dibujaremos a los hijos, comienza después de SU padding.
        float current_y_flow = node->computed_y + (node->padding[0] * dpi_scale);
        float child_x_anchor = node->computed_x + (node->padding[3] * dpi_scale);

        // Iteración cache-friendly sobre los std::shared_ptr
        for (auto& child : node->children) {
            
            // Llamada Top-Down: Pasamos el anchor Y de flujo y pre-escalamos 
            CalculateLayout(child, child_x_anchor, current_y_flow, dpi_scale);
            
            // Empujar el canvas virtual hacia abajo en base al alto resultante del hijo + el espacio de separación exterior.
            current_y_flow += child->computed_height + (child->margin[0] * dpi_scale) + (child->margin[2] * dpi_scale);
        }
    }
};

} // namespace ReanUI
