#ifndef REANUI_NODE_H
#define REANUI_NODE_H

#include <stddef.h>
#include <stdint.h>

typedef struct {
    float width, height;
    float margin[4];
    float padding[4];
    uint32_t bg_color;
    uint32_t text_color;
} ComputedStyle;

typedef struct Node Node;
struct Node {
    int id;
    uint8_t is_dirty;
    ComputedStyle style;
    
    float abs_x, abs_y;
    float layout_w, layout_h;
    
    char* text_content; // Custom property

    Node* parent;
    Node** children;
    size_t num_children;
    size_t capacity;
};

Node* rui_node_create(void);
void rui_node_destroy(Node* node);
void rui_node_add_child(Node* parent, Node* child);

#endif // REANUI_NODE_H
