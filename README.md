# ReanUI

ReanUI es una libreria de interfaces para **MTA:SA** escrita para runtime **Lua 5.1/LuaJIT**.

Su objetivo es permitir crear UI moderna con una sintaxis cercana a CSS, manteniendo una arquitectura simple:
- `Core`: estado, estilos, layout, input y animaciones.
- `EventSystem`: propagacion capture/target/bubble.
- `Renderer`: traduccion del arbol UI a draw calls de MTA (`dxDraw...`).

## Estado actual

- Runtime logico en Lua.
- Backend MTA con `RenderTarget`, shaders y dirty-flagging.
- Input funcional (foco, teclado, cursor/caret, submit, validacion).
- Suite canonica de 5 tests robustos.

## Requisitos

- MTA:SA cliente.
- Entorno Lua 5.1 compatible.
- Resource con `meta.xml` y shaders:
  - `assets/shaders/rounded_rect.fx`
  - `assets/shaders/blur.fx`

## Inicio rapido

```lua
local ReanUI = require("src.ReanUI")

ReanUI.setTheme("dark")
ReanUI.loadStyle([[
input { border-color: var(--border-color); }
.primary { background-color: var(--primary-color); }
]])

local root = ReanUI.init(1280, 720)
local input = ReanUI.create("input", { id = "name", class = "primary", placeholder = "Escribe..." })
root:appendChild(input)
```

En MTA, `ReanUI.init()` enlaza automaticamente:
- `onClientRender`
- `onClientKey`
- `onClientCharacter`
- `onClientRestore`

## API esencial

- `ReanUI.init(width, height, postGUI)`
- `ReanUI.create(tag, attrs, children)`
- `ReanUI.loadStyle(css_string)`
- `ReanUI.setTheme(name)`
- `ReanUI.update(width, height, dt)`
- `ReanUI.handleMouseEvent(type, ...)`
- `ReanUI.handleKeyboardEvent(type, key, state)`
- `ReanUI.handleCharacterEvent(char)`
- `ReanUI.animate(element, props, duration_ms, easing, onComplete)`
- `ReanUI.shutdown()`

## Ejecutar tests

```bash
lua run_tests.lua
```

Tambien puedes correrlos individualmente:

```bash
lua tests/test_event_system.lua
lua tests/test_input_keyboard.lua
lua tests/test_animation_engine.lua
lua tests/test_renderer_mta_backend.lua
lua tests/test_css_theme_integration.lua
```

## Documentacion

- Guia de uso en lenguaje natural: `docs/USAGE_ES.md`
- Arquitectura y flujo tecnico: `docs/ARCHITECTURE_ES.md`
