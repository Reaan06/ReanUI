# ReanUI Hybrid Rendering Engine (dxLibrary Optimized)

Este plan detalla la implementación del motor de renderizado híbrido para ReanUI, basado en la lógica de `dxLibrary` pero optimizado para el uso de CSS y Shaders mediante una estructura de árbol y RenderTargets inteligentes.

## Objetivo
Crear un motor de renderizado que soporte jerarquías complejas, herencia de estilos (CSS) y efectos visuales avanzados (Shaders) con un rendimiento óptimo (mínimo uso de VRAM y CPU).

## Key Files & Context
- `src/core/UIElement.lua`: Clase base para todos los componentes (posición, tamaño, jerarquía).
- `src/renderer/Renderer.lua`: Lógica de renderizado recursivo y gestión de RenderTargets.
- `src/ReanUI.lua`: Punto de entrada y gestión del ciclo de vida (`onClientRender`).

## Implementation Steps

### Task 1: Refactorización de UIElement (Domain)
- [ ] **Step 1**: Actualizar `src/core/UIElement.lua` para soportar:
    - Jerarquía de árbol (`parent`, `children`).
    - Propiedades de geometría (`x`, `y`, `w`, `h`).
    - Flag `_update` para control de cambios (dirty state).
    - Métodos `addChild`, `removeChild`, `setProperty`.

### Task 2: Motor de Renderizado Híbrido (Renderer)
- [ ] **Step 1**: Implementar la lógica recursiva en `src/renderer/Renderer.lua`:
    - Función `renderElement(element, parentRT)`:
        - Si el elemento necesita RT (por CSS/Shaders): crear/actualizar y dibujar en él.
        - Si no: dibujar directamente en `parentRT`.
    - Gestión de `dxSetBlendMode` para transparencia anidada correcta.
    - Implementar el "Dirty State": Solo redibujar RTs si `element._update` es true o si el buffer de MTA se perdió (`onClientRestore`).
- [ ] **Step 2**: Crear helpers en `src/renderer/Renderer.lua` para detectar si un elemento requiere RT (ej: `hasComplexStyles(element)`).

### Task 3: Integración y Gestión Global
- [ ] **Step 1**: Actualizar `src/ReanUI.lua`:
    - Gestionar los `rootElements` (elementos sin padre).
    - Hookear `onClientRender` para iniciar la recursión desde las raíces.
    - Hookear `onClientRestore` para marcar todos los elementos como `_update = true`.

### Task 4: Componentes Base y Prueba
- [ ] **Step 1**: Crear un componente de prueba simple (ej: un Panel en `src/components/Container.lua`) que use el nuevo motor.
- [ ] **Step 2**: Crear un script de demostración `main_demo.lua` para validar el renderizado jerárquico.

## Verification & Testing
- [ ] **Verificación Visual**: Comprobar que los elementos hijos se mueven y escalan con sus padres.
- [ ] **Verificación de Transparencia**: Asegurar que la opacidad del padre afecta a los hijos sin errores de mezcla (ghosting).
- [ ] **Verificación de Rendimiento**: Monitorear el uso de memoria de video (VRAM) para asegurar que no se crean RTs innecesarios.
