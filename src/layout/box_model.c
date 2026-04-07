#include "layout/box_model.h"

void rui_layout_compute(Node* root) {
    if (!root) return;
    
    // Básica propagación top-down para medidas absolutas
    if (root->parent) {
        root->abs_x = root->parent->abs_x; // + margins etc
        root->abs_y = root->parent->abs_y;
    } else {
        root->abs_x = 0;
        root->abs_y = 0;
    }
    
    root->layout_w = root->style.width;
    root->layout_h = root->style.height;
    
    root->is_dirty = 0;
    
    for (size_t i = 0; i < root->num_children; ++i) {
        rui_layout_compute(root->children[i]);
    }
}
