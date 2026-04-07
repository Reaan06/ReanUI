# Arquitectura Tecnica

## Componentes principales

- `src/event/EventSystem.lua`
  - Define `Event`, `EventTarget`, `EventDispatcher`.
  - Propagacion capture/target/bubble con `pcall` por listener.

- `src/core/UIElement.lua`
  - Nodo base de todos los componentes.
  - Integra estilos, jerarquia, dirty flags, foco y dispatch de eventos.

- `src/core/InteractionManager.lua`
  - Traduce mouse/teclado en eventos semanticos.
  - Mantiene hovered/pressed/focused y navegacion TAB.

- `src/core/AnimationManager.lua`
  - API en ms y motor interno en segundos.
  - Interpolacion de color hex, dimensiones y numeros.
  - Limpieza automatica + `onComplete`.

- `src/renderer/MtaCanvas.lua`
  - Puente a `dxDraw...` de MTA.
  - Cache de texturas/fonts/shaders.
  - RenderTargets por UID + dirty redraw + restore.

## Flujo por frame

1. Host dispara `onClientRender`.
2. `ReanUI.update()` calcula `dt` y ejecuta animaciones.
3. `FlexboxLayout` actualiza cajas.
4. `Renderer` genera drawables ordenados por z-index.
5. `MtaCanvas` emite draw calls a MTA.

## Fronteras de error

- Parse CSS: retorna `ok, err`.
- Listeners de eventos: encapsulados con `pcall`.
- Shaders/RT: recreacion defensiva en `onClientRestore`.
- Input: sanitizacion + validacion inmediata.

## Pruebas canonicas

1. `test_event_system.lua`
2. `test_input_keyboard.lua`
3. `test_animation_engine.lua`
4. `test_renderer_mta_backend.lua`
5. `test_css_theme_integration.lua`

Todas son deterministas y usan stubs cuando el host MTA no existe.
