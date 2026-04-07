#ifndef REANUI_PARSER_H
#define REANUI_PARSER_H

#include "dom/node.h"
#include <stdint.h>

/**
 * @struct rui_css_val_type_t
 * @brief Identificador del tipo de dato contenido en una propiedad.
 */
typedef enum {
    RUI_CSS_TYPE_STRING,
    RUI_CSS_TYPE_COLOR  ///< Representado como uint32_t (AARRGGBB)
} rui_css_val_type_t;

/**
 * @struct rui_css_prop_t
 * @brief Par clave-valor para una propiedad CSS con soporte de tipos.
 */
typedef struct {
    char* name;
    rui_css_val_type_t type;
    union {
        char* str;
        uint32_t color;
    } val;
} rui_css_prop_t;

/**
 * @struct rui_css_rule_t
 * @brief Regla CSS que asocia un selector con múltiples propiedades.
 */
typedef struct {
    char* selector;
    rui_css_prop_t* props;
    uint32_t num_props;
} rui_css_rule_t;

/**
 * @struct rui_css_stylesheet_t
 * @brief Estructura raíz que contiene todas las reglas parseadas.
 */
typedef struct {
    rui_css_rule_t* rules;
    uint32_t num_rules;
} rui_css_stylesheet_t;

/**
 * @brief Parsea un string que contiene sintaxis CSS estructural.
 * @param css_string El contenido CSS crudo.
 * @return Puntero a rui_css_stylesheet_t parseado, o NULL en caso de error.
 */
rui_css_stylesheet_t* rui_parse_css(const char* css_string);

/**
 * @brief Libera la memoria de una hoja de estilo completa.
 * @param sheet La estructura a liberar.
 */
void rui_free_css_stylesheet(rui_css_stylesheet_t* sheet);

#endif // REANUI_PARSER_H
