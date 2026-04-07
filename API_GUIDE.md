# Guía de API: ReanUI 📚

Esta guía proporciona la referencia técnica completa para el desarrollo de interfaces con ReanUI.

---

## 🏗️ Módulo Principal: `ReanUI`

El punto de entrada para inicializar y gestionar el ciclo de vida de la aplicación.

### `ReanUI.init(width, height)`
Inicializa el motor y crea el nodo raíz.
- **Parámetros**:
  - `width` (number): Ancho inicial del lienzo.
  - `height` (number): Alto inicial del lienzo.
- **Retorno**: Instancia de `Container` (root).

### `ReanUI.create(tag, attrs, children)`
Método factoría para crear componentes de forma declarativa.
- **Parámetros**:
  - `tag` (string): Identificador del componente ("button", "text", "div", etc).
  - `attrs` (table): Tabla de atributos (`{ id = "myId", class = "myClass", style = "..." }`).
  - `children` (table|string): Lista de elementos hijos o contenido textual.
- **Retorno**: Instancia de `UIElement` (o subclase).

### `ReanUI.update(width, height, dt)`
Procesa el layout y prepara el frame para el renderizado.
- **Parámetros**:
  - `width`, `height`: Dimensiones actuales (para resize).
  - `dt` (number): Tiempo transcurrido (para animaciones).

---

## 🧩 Clase Base: `UIElement`

Todos los componentes heredan de esta clase.

### Métodos del DOM
- `appendChild(child)`: Añade un hijo al final de la lista.
- `removeChild(child)`: Elimina un hijo específico.
- `getParent()` / `getChildren()`: Navegación por el árbol.
- `destroy()`: Elimina el elemento y limpia sus recursos.

### Estilo y Clases
- `setStyle(property, value)`: Cambia una propiedad CSS individual.
- `setStyleSheet(css_string)`: Aplica un bloque completo de CSS.
- `addClass(name)` / `removeClass(name)`: Gestión de clases para selectores.

### Eventos
- `addEventListener(type, callback, useCapture)`: Registra un listener.
- `removeEventListener(type, callback)`: Elimina un listener.
- `dispatchEvent(type, data)`: Dispara un evento personalizado.

---

## 🎨 Propiedades CSS Soportadas

ReanUI soporta una whitelist de propiedades optimizadas:

- **Layout**: `width`, `height`, `margin`, `padding`, `display` (flex/block), `z-index`, `gap`.
- **Flexbox**: `flex-direction`, `justify-content`, `align-items`, `flex-grow`, `flex-basis`.
- **Visual**: `color`, `background-color`, `border-radius`, `opacity`.
- **Sombra**: `shadow-color`, `shadow-blur`.

---

## 🖱️ Sistema de Eventos

ReanUI implementa el flujo estándar del W3C:

1.  **Phase 1 (Capturing)**: El evento baja desde el Root hasta el Target.
2.  **Phase 2 (Target)**: Se ejecuta en el elemento emisor.
3.  **Phase 3 (Bubbling)**: El evento sube desde el Target hasta el Root.

### Eventos del Sistema
- `click`, `dblclick`: Interacciones de ratón.
- `mouseenter`, `mouseleave`: Hover.
- `input`, `change`: Para componentes de entrada como `Input` o `Checkbox`.
- `scroll`: Disparado por componentes con overflow.

---

## 📦 Catálogo de Componentes

### `Button`
Contenedor clickeable con estados de hover automáticos.
- **Eventos**: `click`.

### `Input`
Campo de texto editable.
- **Propiedades**: `:getValue()`, `:setValue(text)`.
- **Eventos**: `input`, `focus`, `blur`.

### `Scrollbox`
Contenedor con soporte para scroll y recorte (clipping).
- **CSS**: `overflow: scroll`.

### `ProgressBar`
Visualizador de progreso numérico.
- **Propiedades**: `:setProgress(0-100)`.
