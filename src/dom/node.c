#include "dom/node.h"
#include "core/memory.h"

Node* rui_node_create(void) {
    Node* n = (Node*)rui_malloc(sizeof(Node));
    if (!n) return NULL;
    
    n->id = 0;
    n->is_dirty = 1;
    
    n->abs_x = 0; n->abs_y = 0;
    n->layout_w = 0; n->layout_h = 0;
    
    n->text_content = NULL;
    n->parent = NULL;
    
    n->num_children = 0;
    n->capacity = 4;
    n->children = (Node**)rui_malloc(sizeof(Node*) * n->capacity);
    
    return n;
}

void rui_node_add_child(Node* parent, Node* child) {
    if (parent->num_children >= parent->capacity) {
        // Here we could realloc, but for simplicity we skip.
        // Needs proper realloc wrapper in memory.c
    }
    parent->children[parent->num_children++] = child;
    child->parent = parent;
}

void rui_node_destroy(Node* node) {
    // Only destroy children if C fully owns them
    if (node->children) {
        rui_free(node->children);
    }
    rui_free(node);
}
