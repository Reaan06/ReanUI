# Guía de API: ReanUI

Guía técnica del estado actual del API público.

## Módulo principal `src.ReanUI`

### `ReanUI.init(width, height, postGUI?) -> root`
Inicializa canvas/renderer y devuelve el nodo raíz.

### `ReanUI.create(tag, attrs?, children?) -> UIElement`
Factory declarativa de componentes.

### `ReanUI.update(width?, height?, dt?)`
Ejecuta animaciones, layout y render.

### `ReanUI.loadStyle(css_string) -> ok, err?`
Parsea y aplica CSS global por selectores.

### `ReanUI.setTheme(name) -> boolean`
Cambia el tema activo.

### `ReanUI.getThemeVariable(name, fallback?)`
Resuelve variables del tema (`var(--name)`).

### `ReanUI.handleMouseEvent(event_type, ...)`
Bridge de mouse (`move`, `button`, `wheel`) hacia `InteractionManager`.

### `ReanUI.handleKeyboardEvent(event_type, key, state)`
Bridge de teclado (`onClientKey`).

### `ReanUI.handleCharacterEvent(char)`
Bridge de caracteres (`onClientCharacter`).

## `UIElement` (base de todos los componentes)

### Árbol y ciclo de vida
- `appendChild(child)`
- `removeChild(child)`
- `getParent()`, `getChildren()`, `getChildCount()`
- `destroy()`, `isDestroyed()`

### Estilo
- `setStyle(prop, value)`
- `getStyle(prop)`
- `setStyleSheet(css_block)`
- `getAllStyles()`

### Clases/atributos
- `setId(id)`, `getId()`, `getUid()`, `getTag()`
- `addClass(classes)`, `removeClass(classes)`, `hasClass(name)`, `getClasses()`
- `setData(key, value)`, `getData(key)`

### Eventos
- `addEventListener(type, callback, options?)`
- `removeEventListener(type, callback, capture?)`
- `dispatchEvent(type, data?)`
- Alias de compatibilidad: `on`, `off`, `once`

### Interacción
- `setFocusable(bool)`, `isFocusable()`
- `focus()`, `blur()`

### Animación
- `animate(props, duration_ms, easing?, onComplete?)`

## Sistema de eventos (`src/event/EventSystem.lua`)

### Fases
1. `CAPTURING`
2. `AT_TARGET`
3. `BUBBLING`

### Objeto `Event`
- Campos: `type`, `data`, `target`, `currentTarget`, `eventPhase`, `bubbles`, `cancelable`.
- Métodos: `stopPropagation`, `stopImmediatePropagation`, `preventDefault`.

### `addEventListener` opciones
- `capture` (bool)
- `once` (bool)
- `passive` (bool, reservado)

## InteractionManager (`src/core/InteractionManager.lua`)

- Hit-testing por layout.
- Focus único global.
- Teclado se envía solo al elemento enfocado.
- Normalización de estado de tecla (`true/false` y `down/up`).
- TAB para navegación de foco.

## Componentes

### `Button`
- API principal: `onClick`, `press`, `setDisabled`.
- Compatibilidad legacy: `disable`, `enable`, `getState`, `onMouseEnter`, `onMouseLeave`, `onMouseDown`, `onMouseUp`.

### `Input`
- Valor: `getValue`, `setValue`, `clear`.
- Cursor: `setCursorPosition`, `getCursorPosition`, `moveCursor`.
- Edición: `appendChar`, `backspace`, `deleteForward`.
- Validación: `validate() -> boolean, message`, `isValid`, `getError`.
- Caret: `updateCaretBlink`, `isCaretVisible`.

### `Checkbox`
- Estado: `isChecked`, `setChecked`, `toggle`.
- Eventos: `onChange`.
- Compatibilidad: `press`.

### `ProgressBar`
- `setProgress(0..100)`, `getProgress`.

### `Scrollbox`
- Scroll por rueda (`mousewheel`) + clipping.

## Animaciones (`src/core/AnimationManager.lua`)

- API en milisegundos (`animate`).
- Motor interno en segundos (`tick(dt_seconds)`).
- Interpolación:
- Colores HEX (`#RRGGBB`)
- Dimensiones (`px`, `%`)
- Números (`opacity`, `z-index`, etc.)
- Limpieza automática de animaciones completadas + callback `onComplete`.

## Renderer y Canvas

### `Renderer`
- Recolección de drawables por dirty flag.
- Orden por `z-index`.
- Render de input con texto/placeholder + caret.

### `MtaCanvas`
- `drawRect`, `drawText`, `drawImage`, `drawShader`.
- Render targets cacheados por `uid`:
- `pushRenderTarget(uid,w,h)`
- `popRenderTarget()`
- `drawCachedElement(element, drawFn)`
- Recuperación de contexto DX: `onClientRestore`.

## Temas

Variables base recomendadas:
- `--primary-color`
- `--bg-color`
- `--bg-alt`
- `--text-color`
- `--text-muted`
- `--border-color`
- `--shadow-color`

## Runtime

- ReanUI está definido para ejecutarse en modo 100% Lua.
- El parser CSS usado en runtime es `src/parser/css_parser.lua`.
