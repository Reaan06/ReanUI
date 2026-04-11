# ReanUI Professional Blueprint: The Definitive DX Library for MTA:SA

Este documento establece la hoja de ruta estratégica para convertir a **ReanUI** en la librería de interfaces más avanzada de MTA:SA, fusionando la potencia visual de la web (CSS) con el rendimiento de DirectX.

## 🏛️ 1. Arquitectura del Sistema (Core-Driven)

### 1.1 El Motor de Renderizado Híbrido (V2)
- **Clipping Rectangles**: Implementar `dxSetBlendMode("modulate_add")` y `dxSetRenderTarget` con rectángulos de recorte para contenedores tipo `ScrollPane`.
- **Z-Index Real**: Gestión automática de profundidad basada en la posición en el árbol y propiedades de estilo.
- **Draw Call Batching**: Agrupar rectángulos y textos de la misma capa para reducir llamadas a la GPU.

### 1.2 Motor CSS Declarativo (The Brain)
- **Selectores**: Implementar selectores por clase (`.btn`), ID (`#main`) y tipo (`Container`).
- **Unidades Dinámicas**: Soporte para `px`, `%`, `vh`, `vw` y `rem` (basado en el tamaño de fuente raíz).
- **Herencia de Estilos**: Propagación automática de propiedades (color de texto, fuente, opacidad) de padres a hijos.

---

## 🛠️ 2. Fases de Implementación (Roadmap)

### Fase 1: El Cerebro CSS (Prioridad Alta)
- [ ] **Step 1: CSS Parser**: Crear un analizador que convierta tablas de estilo en propiedades computadas.
- [ ] **Step 2: Style Adapter**: Implementar la lógica que reacciona a cambios en el estado (hover, focus, active) y aplica los estilos correspondientes.
- [ ] **Step 3: Theme Manager**: Soporte para variables CSS (`--primary-color`) y cambio de tema en tiempo real (Dark/Light Mode).

### Fase 2: Componentes Industriales (The Body)
- [ ] **Step 1: Text & Fonts**: Motor de texto con soporte para emojis, colores hexadecimales en línea (`#RRGGBB`) y alineación inteligente.
- [ ] **Step 2: Form Elements**: 
    - `Edit`: Campo de texto con caret animado, selección y máscara de contraseña.
    - `Checkbox/RadioButton`: Componentes con micro-animaciones SVG.
    - `Switch`: Botón de alternancia con suavizado elástico.
- [ ] **Step 3: Data Elements**: 
    - `GridList`: Listado de datos optimizado para miles de filas (Virtual Scrolling).
    - `ScrollPane`: Contenedor con barras de desplazamiento automáticas.

### Fase 3: Visual FX & Shaders (The Soul)
- [ ] **Step 1: Blur & Shadows**: Shaders de desenfoque Gaussiano y sombras paralelas (`box-shadow`) aplicables a cualquier contenedor.
- [ ] **Step 2: Gradients**: Soporte para gradientes lineales y radiales vía Shaders DX.
- [ ] **Step 3: SVG Masking**: Uso de máscaras SVG para formas complejas y recortes dinámicos.

### Fase 4: Tooling & DX (Developer Experience)
- [ ] **Step 1: Exports**: Crear una API de exportación profesional para que otros recursos usen ReanUI sin importar los archivos.
- [ ] **Step 2: Debugger Pro**: Una interfaz visual de depuración que permita inspeccionar el árbol de elementos y sus estilos en tiempo real (Inspector de Elementos).
- [ ] **Step 3: Documentation**: Wiki técnica completa y ejemplos de uso "Plug & Play".

---

## 🚀 3. Estándares Técnicos

- **Rendimiento**: < 0.5ms de CPU por cada 100 elementos complejos.
- **Memoria**: < 50MB de VRAM para interfaces de tamaño medio.
- **Compatibilidad**: Funcionamiento fluido en resoluciones desde 1024x768 hasta 4K.
- **Sintaxis**: Código limpio, modular y totalmente orientado a objetos (OOP).

---

## 📅 4. Próximos Pasos Inmediatos
1.  **Refinar el Parser CSS** para que acepte tablas anidadas y selectores.
2.  **Implementar el componente `Edit`** (es el más difícil técnicamente y definirá la robustez del motor).
3.  **Crear el sistema de Eventos de Burbujeo** (Click, Scroll, KeyPress).
