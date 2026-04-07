# Guia de Uso (ES)

## 1. Que problema resuelve ReanUI

ReanUI te deja construir interfaces en MTA sin pelear con `dxDraw...` en cada pantalla.
Tu defines componentes y estilos, y la libreria se encarga de layout, eventos, foco, teclado y render.

## 2. Flujo recomendado de trabajo

1. Inicializa ReanUI una sola vez con `ReanUI.init(...)`.
2. Carga estilos globales con `ReanUI.loadStyle(...)`.
3. Crea componentes con `ReanUI.create(...)`.
4. Conecta eventos de negocio (`click`, `submit`, etc.).
5. Si necesitas animar, usa `ReanUI.animate(...)`.

## 3. Ejemplo real minimo

```lua
local ReanUI = require("src.ReanUI")

ReanUI.setTheme("dark")
ReanUI.loadStyle([[
#screen { padding: 16px; gap: 8px; }
input { border-color: var(--border-color); }
]])

local root = ReanUI.init(1366, 768)
local screen = ReanUI.create("div", { id = "screen" }, {
    ReanUI.create("text", {}, "Login"),
    ReanUI.create("input", { id = "email", placeholder = "correo" }),
    ReanUI.create("button", { class = "primary" }, "Entrar")
})

root:appendChild(screen)
```

## 4. Input y teclado

`Input` ya soporta comportamiento real:
- foco unico,
- escritura por `onClientCharacter`,
- `backspace`, `delete`, `arrow_l`, `arrow_r`, `home`, `end`,
- evento `submit` con Enter,
- caret parpadeante,
- `validate()` devuelve `(boolean, mensaje)` y actualiza estado visual.

## 5. Eventos y propagacion

ReanUI usa fases de evento:
- `capture` (de ancestro a descendiente),
- `target`,
- `bubble` (de descendiente a ancestro).

Puedes registrar listeners con:
- `addEventListener(type, callback, options)`
- `removeEventListener(...)`
- `once(...)` o `options.once = true`

## 6. Buenas practicas

- Usa `id` para reglas unicas y `class` para estilos reutilizables.
- Evita animar demasiadas propiedades por frame; prioriza opacidad y color.
- Limpia la UI al recargar recurso con `ReanUI.shutdown()`.
- Si algo falla, primero valida tema, CSS y foco activo.

## 7. Debug rapido

- `ReanUI.traceEvents(true)` para rastrear eventos.
- `ReanUI.getListeners(element, "click")` para inspeccionar listeners.
- `lua run_tests.lua` para regresion local.
