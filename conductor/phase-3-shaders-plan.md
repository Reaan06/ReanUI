# ReanUI Phase 3: Visual FX & Shaders Implementation Plan

Este plan detalla la implementación de los efectos visuales avanzados (Shaders) en ReanUI, integrados con el motor CSS y el renderizador híbrido.

## Objetivo
Añadir capacidades de Shaders (Sombras, Desenfoque y Gradientes) a ReanUI con un rendimiento de nivel industrial (bajo consumo de GPU y CPU).

## Key Files & Context
- `src/renderer/ShaderManager.lua`: Gestor central de efectos visuales.
- `src/renderer/Renderer.lua`: Actualización para aplicar shaders en el ciclo de dibujado.
- `src/core/CSSProcessor.lua`: Soporte para propiedades visuales complejas (`boxShadow`, `backdropFilter`).
- `files/fx/box_shadow.fx`: Archivo HLSL para sombras suaves.
- `files/fx/blur.fx`: Archivo HLSL para desenfoque de fondo.

## Implementation Steps

### Task 1: Infraestructura de Shaders (ShaderManager)
- [ ] **Step 1**: Crear `src/renderer/ShaderManager.lua` para:
    - Cargar y cachear shaders (`dxCreateShader`).
    - Exponer una API simple: `applyBlur(rt, radius)`, `applyShadow(rt, x, y, size, color)`.
    - Gestionar la destrucción de shaders al cerrar el recurso.

### Task 2: Implementación de HLSL (Files)
- [ ] **Step 1**: Crear `files/fx/box_shadow.fx`: Un shader de desenfoque gaussiano optimizado para sombras de UI.
- [ ] **Step 2**: Crear `files/fx/blur.fx`: Un shader de desenfoque para fondos de contenedores.
- [ ] **Step 3**: Actualizar `meta.xml` para incluir estos archivos como `type="client"`.

### Task 3: Integración en el Renderizador (Renderer)
- [ ] **Step 1**: Actualizar `Renderer.lua` para detectar propiedades de sombra y desenfoque.
- [ ] **Step 2**: Implementar el orden de dibujado correcto: 
    1. Dibujar sombra (si existe).
    2. Dibujar fondo con desenfoque (si existe).
    3. Dibujar contenido normal (incluyendo hijos).

### Task 4: Soporte CSS para Efectos Visuales
- [ ] **Step 1**: Actualizar `CSSProcessor.lua` para parsear:
    - `boxShadow`: Ej: `"0 4 10 #00000088"` (x, y, blur, color).
    - `backdropFilter`: Ej: `"blur(10)"`.
    - `background`: Soporte para gradientes lineales simples (vía shader).

## Verification & Testing
- [ ] **Verificación de Calidad**: Comprobar que las sombras se ven suaves y no "pixeladas".
- [ ] **Verificación de Rendimiento**: Asegurar que el uso de shaders no causa caídas de FPS significativas en interfaces con muchos elementos.
- [ ] **Verificación Visual**: Probar el efecto "Glassmorphism" (blur + semi-transparencia).
