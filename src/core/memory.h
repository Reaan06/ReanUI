#ifndef REANUI_MEMORY_H
#define REANUI_MEMORY_H

#include <stddef.h>

// Simple wrapper para memory pool/arena allocator o malloc directo.
// Por ahora, envuelve llamadas estándar.
void* rui_malloc(size_t size);
void rui_free(void* ptr);

#endif
