#include <stdlib.h>
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
    if (!n->children) {
        rui_free(n);
        return NULL; /* Falló la asignación del array de hijos */
    }

    return n;
}

void rui_node_add_child(Node* parent, Node* child) {
    if (!parent || !child) return;

    /* Crecer el array dinámicamente con factor x2 (igual que vector<>) */
    if (parent->num_children >= parent->capacity) {
        int new_cap = parent->capacity == 0 ? 4 : parent->capacity * 2;
        Node** new_arr = (Node**)realloc(parent->children, sizeof(Node*) * (size_t)new_cap);
        if (!new_arr) return; /* OOM: no modificar el árbol si no hay memoria */
        parent->children = new_arr;
        parent->capacity = new_cap;
    }

    parent->children[parent->num_children++] = child;
    child->parent = parent;
}

void rui_node_destroy(Node* node) {
    if (!node) return;

    /* Destruir hijos recursivamente antes de liberar el padre (DFS post-order) */
    for (int i = 0; i < node->num_children; i++) {
        rui_node_destroy(node->children[i]);
    }

    if (node->children) {
        rui_free(node->children);
        node->children = NULL;
    }
    rui_free(node);
}
