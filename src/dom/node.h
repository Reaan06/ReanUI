/**
 * @file node.h
 * @brief Low-level DOM Node management for the layout engine.
 */

#ifndef REANUI_NODE_H
#define REANUI_NODE_H

#include <stddef.h>
#include <stdint.h>

/**
 * @struct ComputedStyle
 * @brief Stores resolved visual properties for a node after CSS parsing.
 */
typedef struct {
    float width, height;       ///< Dimensions in pixels.
    float margin[4];           ///< Margins: [top, right, bottom, left].
    float padding[4];          ///< Paddings: [top, right, bottom, left].
    uint32_t bg_color;         ///< Background color (hexa).
    uint32_t text_color;       ///< Text color (hexa).
} ComputedStyle;

/**
 * @struct Node
 * @brief Base Node structure for the internal C layout engine.
 */
typedef struct Node Node;
struct Node {
    int id;                    ///< Unique node ID.
    uint8_t is_dirty;          ///< Reset to 1 when layout needs recalculation.
    ComputedStyle style;       ///< Current resolved style.
    
    float abs_x, abs_y;        ///< Absolute X and Y on screen.
    float layout_w, layout_h;  ///< Final width and height after Flexbox.
    
    char* text_content;        ///< Raw text content (for text nodes).

    Node* parent;              ///< Pointer to parent Node.
    Node** children;           ///< Dynamic array of children.
    size_t num_children;       ///< Active children count.
    size_t capacity;           ///< Allocated capacity for children array.
};

/**
 * @brief Creates a new initialized Node.
 * @return Pointer to the new Node.
 */
Node* rui_node_create(void);

/**
 * @brief Recursively destroys a Node and all its descendants.
 * @param node The root of the subtree to destroy.
 */
void rui_node_destroy(Node* node);

/**
 * @brief Adds a child to a parent node, handling array resizing if necessary.
 * @param parent The parent node.
 * @param child The child node to append.
 */
void rui_node_add_child(Node* parent, Node* child);

#endif // REANUI_NODE_H
