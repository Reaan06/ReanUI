#include "memory.h"
#include <stdlib.h>

void* rui_malloc(size_t size) {
    return malloc(size); // Placeholder for arena allocator
}

void rui_free(void* ptr) {
    free(ptr);
}
