# ReanUI

Framework de UI para Lua con arquitectura modular: eventos tipo DOM (capture/target/bubble), layout flexbox, renderer con dirty-flagging, temas y backend MTA.

## Estado del proyecto
- Motor de eventos unificado (`src/event/EventSystem.lua`).
- Animaciones refactorizadas con tiempo interno en segundos (`src/core/AnimationManager.lua`).
- Input funcional con foco, cursor, edición por teclado y validación visual inmediata (`src/components/Input.lua`).
- Backend MTA con render targets, shaders y recuperación en `onClientRestore` (`src/renderer/MtaCanvas.lua`).
- Runtime oficial 100% Lua para MTA.

## Requisitos
- Lua 5.x (se recomienda Lua 5.4 o LuaJIT para integración en juegos).

## Instalación rápida
```bash
git clone https://github.com/reaan/ReanUI.git
cd ReanUI
```

## Variables de entorno sugeridas
```bash
export LUA_PATH="./?.lua;./src/?.lua;;"
```

## Inicio rápido
```lua
local ReanUI = require("src.ReanUI")

local root = ReanUI.init(800, 600)

local input = ReanUI.create("input", {
    id = "email",
    placeholder = "Email"
})

input:addEventListener("submit", function(e)
    print("Submit:", e.value)
end)

root:appendChild(input)
ReanUI.update(800, 600, 1/60)
```

## Arquitectura (resumen)
- `src/core`: núcleo (`UIElement`, animaciones, interacción).
- `src/event`: sistema de eventos con fases.
- `src/layout`: layout flexbox.
- `src/components`: componentes (`Button`, `Input`, `Checkbox`, etc.).
- `src/renderer`: renderer y backend MTA.
- `src/theme`: temas y resolución de variables CSS.
- `src/parser`: parser CSS en Lua.

## Eventos
- API principal: `addEventListener`, `removeEventListener`, `dispatchEvent`.
- Compatibilidad: `on`, `off`, `once` en `UIElement`.
- Fases soportadas:
1. Capture
2. Target
3. Bubble

## Input y teclado
- Solo el elemento con foco recibe teclado (`InteractionManager`).
- Soporta: `character`, `backspace`, `delete`, `arrow_l`, `arrow_r`, `home`, `end`, `enter`.
- Incluye caret parpadeante y estado visual de validación (error/success).

## MTA backend
`src/renderer/MtaCanvas.lua` implementa:
- `drawRect`, `drawText`, `drawImage`.
- `pushRenderTarget(uid,w,h)` / `popRenderTarget()`.
- Cache por `uid` + dirty redraw.
- `applyShader(shaderPath, params)`.
- Restauración de recursos con `onClientRestore`.

## Tests
Ejecutar un test individual:
```bash
lua tests/test_interaction.lua
```

Ejecutar toda la suite:
```bash
cat > /tmp/rean_all_tests.txt <<'EOF'
test.lua
test_components.lua
test_css.lua
test_flexbox.lua
test_layout.lua
test_uielement.lua
tests/test_advanced_themes.lua
tests/test_animations.lua
tests/test_button_full.lua
tests/test_checkbox.lua
tests/test_event_propagation.lua
tests/test_global_themes.lua
tests/test_input_validation.lua
tests/test_interaction.lua
tests/test_css_parser.lua
tests/test_progress.lua
tests/test_renderer_perf.lua
tests/test_scrollbox.lua
tests/test_utils.lua
EOF

fail=0
while IFS= read -r t; do
  [ -z "$t" ] && continue
  echo "===== RUN $t ====="
  lua "$t" || fail=1
done < /tmp/rean_all_tests.txt
exit $fail
```

## MTA como recurso
1. Copia el proyecto en `resources/[ui]/reanui`.
2. Verifica `meta.xml`.
3. Inicia con `start reanui`.

## Documentación API
Referencia técnica: [API_GUIDE.md](/home/reaan/ReanUI/ReanUI/API_GUIDE.md)

## Contribución
- Mantener estilo de código y comentarios claros.
- Añadir/actualizar tests al cambiar comportamiento.
- Evitar romper compatibilidad pública sin migración explícita.
