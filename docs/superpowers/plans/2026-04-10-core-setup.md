# ReanUI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el motor base de ReanUI con soporte para estilos declarativos (CSS-like) y arquitectura desacoplada.

**Architecture:** Capas (Domain, Adapters, Infrastructure) con inyección de dependencias para el renderizador.

**Tech Stack:** Lua (MTA:SA environment).

---

### Task 1: Estructura del Proyecto

**Files:**
- Create: `src/core/UIElement.lua`
- Create: `src/adapters/StyleAdapter.lua`

- [ ] **Step 1: Crear estructura de carpetas**
```bash
mkdir -p src/domain src/adapters src/infrastructure src/theme
```

- [ ] **Step 2: Crear clase base UIElement (Domain)**
```lua
UIElement = {}
UIElement.__index = UIElement
function UIElement:new(o) o = o or {}; setmetatable(o, self); return o end
return UIElement
```

- [ ] **Step 3: Crear StyleAdapter básico**
```lua
StyleAdapter = {}
function StyleAdapter:process(cssTable)
    -- Lógica de normalización de CSS
    return cssTable
end
return StyleAdapter
```

- [ ] **Step 4: Commit**
```bash
git add src/core/UIElement.lua src/adapters/StyleAdapter.lua
git commit -m "feat: init project structure and core classes"
```
