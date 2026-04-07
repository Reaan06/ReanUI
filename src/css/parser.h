#ifndef REANUI_PARSER_H
#define REANUI_PARSER_H

#include "dom/node.h"

// Parsea un string que contiene sintaxis CSS estructural y 
// devuelve el Nodo Raíz (DOM Root).
Node* rui_parse_css(const char* css_string);

#endif // REANUI_PARSER_H
