#include "css/parser.h"
#include <stdio.h>

// TODO: Integrate actual lexbor library here to traverse AST
// For now, this is a skeleton that returns a dummy node.
Node* rui_parse_css(const char* css_string) {
    if (!css_string) return NULL;
    
    // Aquí inicializaremos lexbor lxb_css_parser
    // lxb_css_parser_t *parser = lxb_css_parser_create();
    // lxb_css_parser_init(parser, NULL);
    // ... parse css_string and build the node tree.
    
    Node* root = rui_node_create();
    root->style.width = 800;
    root->style.height = 600;
    return root;
}
