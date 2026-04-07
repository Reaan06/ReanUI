#include "css/parser.h"
#include <lexbor/css/css.h>
#include <lexbor/core/base.h>
#include <lexbor/core/str.h>
#include <lexbor/core/mraw.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <stdbool.h>

/**
 * @brief Helper para convertir strings de color CSS a uint32_t (AARRGGBB).
 */
static uint32_t parse_color(const char* val) {
    if (!val) return 0xFF000000;
    while(isspace(*val)) val++;

    if (*val == '#') {
        char* end;
        uint32_t hex = (uint32_t)strtoul(val + 1, &end, 16);
        size_t len = end - (val + 1);
        
        if (len == 3) {
            uint32_t r = (hex >> 8) & 0xF;
            uint32_t g = (hex >> 4) & 0xF;
            uint32_t b = hex & 0xF;
            return 0xFF000000 | (r << 20) | (r << 16) | (g << 12) | (g << 8) | (b << 4) | b;
        } else if (len == 6) {
            return 0xFF000000 | hex;
        } else if (len == 8) {
            return hex;
        }
    }

    if (strstr(val, "rgb")) {
        int r, g, b;
        float a = 1.0f;
        if (sscanf(val, "rgba(%d,%d,%d,%f)", &r, &g, &b, &a) >= 4 || 
            sscanf(val, "rgb(%d,%d,%d)", &r, &g, &b) >= 3) {
            uint32_t alpha = (uint32_t)(a * 255.0f);
            return (alpha << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
        }
    }

    return 0xFF000000;
}

typedef struct {
    lexbor_str_t *str;
    lexbor_mraw_t *mraw;
} rui_lexbor_cb_ctx_t;

static lxb_status_t rui_serialize_callback(const lxb_char_t *data, size_t len, void *ctx) {
    rui_lexbor_cb_ctx_t *c = (rui_lexbor_cb_ctx_t *)ctx;
    if (lexbor_str_append(c->str, c->mraw, data, len) == NULL) {
        return LXB_STATUS_ERROR_MEMORY_ALLOCATION;
    }
    return LXB_STATUS_OK;
}

static char* rui_serialize_to_string(const void* obj, lxb_css_style_serialize_f func, lexbor_mraw_t *mraw) {
    lexbor_str_t str = {0};
    rui_lexbor_cb_ctx_t ctx = {&str, mraw};
    
    if (func(obj, rui_serialize_callback, &ctx) != LXB_STATUS_OK) {
        lexbor_str_destroy(&str, mraw, false);
        return NULL;
    }
    
    char* result = strdup((const char*)str.data);
    lexbor_str_destroy(&str, mraw, false);
    return result;
}

// Wrapper para serialización de nombres de declaración
static lxb_status_t rui_decl_name_callback(const void *decl, lexbor_serialize_cb_f cb, void *ctx) {
    return lxb_css_rule_declaration_serialize_name((const lxb_css_rule_declaration_t *)decl, cb, ctx);
}

// Wrapper para serialización de valores de declaración
static lxb_status_t rui_decl_value_callback(const void *decl, lexbor_serialize_cb_f cb, void *ctx) {
    return lxb_css_rule_declaration_serialize((const lxb_css_rule_declaration_t *)decl, cb, ctx);
}

rui_css_stylesheet_t* rui_parse_css(const char* css_string) {
    if (!css_string) return NULL;

    lxb_css_parser_t *parser = lxb_css_parser_create();
    if (lxb_css_parser_init(parser, NULL) != LXB_STATUS_OK) {
        lxb_css_parser_destroy(parser, true);
        return NULL;
    }

    lxb_css_stylesheet_t *stylesheet = lxb_css_stylesheet_create(NULL);
    if (!stylesheet) {
        lxb_css_parser_destroy(parser, true);
        return NULL;
    }

    if (lxb_css_stylesheet_parse(stylesheet, parser, (const lxb_char_t *)css_string, strlen(css_string)) != LXB_STATUS_OK) {
        lxb_css_stylesheet_destroy(stylesheet, true);
        lxb_css_parser_destroy(parser, true);
        return NULL;
    }

    rui_css_stylesheet_t* rui_sheet = (rui_css_stylesheet_t*)calloc(1, sizeof(rui_css_stylesheet_t));
    if (!rui_sheet) {
        lxb_css_stylesheet_destroy(stylesheet, true);
        lxb_css_parser_destroy(parser, true);
        return NULL;
    }

    lxb_css_rule_t *rule = stylesheet->root;
    uint32_t rule_count = 0;
    while (rule) {
        if (rule->type == LXB_CSS_RULE_STYLE) rule_count++;
        rule = rule->next;
    }

    rui_sheet->rules = (rui_css_rule_t*)calloc(rule_count, sizeof(rui_css_rule_t));
    
    rule = stylesheet->root;
    while (rule) {
        if (rule->type == LXB_CSS_RULE_STYLE) {
            lxb_css_rule_style_t *style_rule = lxb_css_rule_style(rule);
            rui_css_rule_t *rui_rule = &rui_sheet->rules[rui_sheet->num_rules];

            size_t sel_len;
            lxb_char_t *sel_str = lxb_css_selector_serialize_list_chain_char(style_rule->selector, &sel_len);
            if (sel_str) {
                rui_rule->selector = strdup((const char*)sel_str);
                free(sel_str);
            }

            lxb_css_rule_declaration_list_t *decl_list = style_rule->declarations;
            uint32_t decl_count = decl_list->count;
            rui_rule->props = (rui_css_prop_t*)calloc(decl_count, sizeof(rui_css_prop_t));

            lxb_css_rule_t *decl_rule = decl_list->first;
            while (decl_rule) {
                if (decl_rule->type == LXB_CSS_RULE_DECLARATION) {
                    lxb_css_rule_declaration_t *decl = lxb_css_rule_declaration(decl_rule);
                    rui_css_prop_t *p = &rui_rule->props[rui_rule->num_props];

                    p->name = rui_serialize_to_string(decl, (lxb_css_style_serialize_f)rui_decl_name_callback, stylesheet->memory->mraw);
                    char* raw_val = rui_serialize_to_string(decl, (lxb_css_style_serialize_f)rui_decl_value_callback, stylesheet->memory->mraw);

                    if (raw_val) {
                        if (p->name && (strstr(p->name, "color") || strstr(p->name, "background"))) {
                            p->type = RUI_CSS_TYPE_COLOR;
                            p->val.color = parse_color(raw_val);
                            free(raw_val);
                        } else {
                            p->type = RUI_CSS_TYPE_STRING;
                            p->val.str = raw_val;
                        }
                    }
                    rui_rule->num_props++;
                }
                decl_rule = decl_rule->next;
            }
            rui_sheet->num_rules++;
        }
        rule = rule->next;
    }

    lxb_css_stylesheet_destroy(stylesheet, true);
    lxb_css_parser_destroy(parser, true);

    return rui_sheet;
}

void rui_free_css_stylesheet(rui_css_stylesheet_t* sheet) {
    if (!sheet) return;
    for (uint32_t i = 0; i < sheet->num_rules; i++) {
        if (sheet->rules[i].selector) free(sheet->rules[i].selector);
        for (uint32_t j = 0; j < sheet->rules[i].num_props; j++) {
            if (sheet->rules[i].props[j].name) free(sheet->rules[i].props[j].name);
            if (sheet->rules[i].props[j].type == RUI_CSS_TYPE_STRING && sheet->rules[i].props[j].val.str) {
                free(sheet->rules[i].props[j].val.str);
            }
        }
        if (sheet->rules[i].props) free(sheet->rules[i].props);
    }
    if (sheet->rules) free(sheet->rules);
    free(sheet);
}
