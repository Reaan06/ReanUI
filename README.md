# ReanUI 🚀

**ReanUI** es un framework de interfaces de usuario (UI) de alto rendimiento para Lua, diseñado con un núcleo acelerado en C y un sistema de diseño basado en estándares de la web (CSS y Flexbox). 

Resuelve el problema de la complejidad y el bajo rendimiento en sistemas de UI tradicionales mediante un motor de renderizado con **Dirty-Flagging**, un sistema de eventos con **propagación completa** (bubbling/capturing) y un motor de **layout profesional** inspirado en Flexbox.

## 📋 Requisitos Previos

ReanUI utiliza un núcleo híbrido **C/Lua** para garantizar la máxima velocidad de renderizado. Para empezar, necesitas:

-   **Lua 5.1 / 5.4 / LuaJIT**: El motor principal del framework.
-   **CMake 3.14+**: Para la gestión de compilación y descarga de dependencias nativas.
-   **Compilador C99**: (GCC >= 7.0, Clang o MSVC 2019+) para compilar el motor de layout y CSS.
-   **Git**: Necesario para que CMake descargue automáticamente la librería `lexbor`.

## ⚙️ Instalación Paso a Paso

El proceso de instalación compila el núcleo nativo y configura el entorno para que Lua pueda cargar las librerías.

### 1. Clonar el repositorio
```bash
git clone https://github.com/reaan/ReanUI.git
cd ReanUI
```

### 2. Compilar el núcleo nativo (C)
ReanUI utiliza CMake para automatizar la descarga de `lexbor` y la compilación de los bridges de Lua.
```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .
```
Esto generará `libreanui.so` (Linux), `libreanui.dylib` (macOS) o `reanui.dll` (Windows).

### 3. Configurar el acceso desde Lua
Para que tus scripts reconozcan ReanUI, debes indicarle a Lua dónde buscar los archivos fuente y los binarios compilados:

```bash
# Desde la raíz del proyecto
export LUA_PATH="./?.lua;./src/?.lua;;"
export LUA_CPATH="./build/?.so;;"
```

## 🚀 Inicio Rápido

```lua
local ReanUI = require("src.ReanUI")

-- 1. Inicializar con las dimensiones de la pantalla
local root = ReanUI.init(800, 600)

-- 2. Crear un componente con estilos CSS
local btn = ReanUI.create("button", { id = "main-btn" }, "¡Haz clic!")
btn:setStyleSheet([[
    background-color: #2D3748;
    color: #FFFFFF;
    width: 200px;
    height: 50px;
    border-radius: 8px;
    justify-content: center;
]])

-- 3. Gestionar eventos
btn:addEventListener("click", function(e)
    print("Botón pulsado!")
end)

-- 4. Añadir al árbol y actualizar
root:appendChild(btn)
ReanUI.update(800, 600, 0.016) -- Basado en tu frame time
```

## 📂 Estructura del Proyecto

| Carpeta | Descripción |
| :--- | :--- |
| `src/core` | Núcleo del motor: Gestión de memoria, clases base (UIElement) y estilos. |
| `src/components` | Catálogo de componentes UI (Button, Input, Scrollbox, etc.). |
| `src/layout` | Motor de cálculo de geometría (Flexbox). |
| `src/renderer` | Sistema de dibujo, gestión de primitivas y clipping. |
| `src/event` | Sistema de eventos avanzado (DOM-like). |
| `src/theme` | Gestor de temas globales y variables CSS. |
| `src/bridge` | Enlace nativo entre Lua y C. |
| `tests` | Suite de pruebas automatizadas. |

## 🌐 Variables de Entorno

| Variable | Descripción | Ejemplo | Obligatoria |
| :--- | :--- | :--- | :--- |
| `LUA_PATH` | Ruta para localizar módulos Lua de ReanUI. | `./?.lua;;` | Sí |
| `LUA_CPATH` | Ruta para localizar la librería nativa (`.so`/`.dll`). | `./build/?.so;;` | Sí (si no está en path) |

## 🧪 Ejecución de Tests

ReanUI utiliza una suite de pruebas integrada que puedes ejecutar individualmente:

```bash
# Ejemplo: Probar el sistema de eventos
lua tests/test_event_propagation.lua

# Ejemplo: Probar el rendimiento del renderer
lua tests/test_renderer_perf.lua
```

## 🎮 Instalación como Recurso MTA:SA

ReanUI está diseñado para ser usado directamente como un recurso en **Multi Theft Auto: San Andreas**. Sigue estos pasos para integrarlo en tu servidor:

### 1. Preparar el Recurso
Copia la carpeta raíz de **ReanUI** en el directorio de recursos de tu servidor:
`server/mods/deathmatch/resources/[interfaz]/reanui/`

### 2. Configurar el meta.xml
El archivo `meta.xml` ya viene preconfigurado en la raíz. Si deseas integrar ReanUI dentro de otro recurso, asegúrate de incluir los scripts del núcleo en el orden correcto (ver `meta.xml` de referencia).

### 3. Uso Básico (Client-side)
```lua
-- En tu script cliente de MTA:
local sw, sh = getScreenSize()
local root = ReanUI.init(sw, sh)

-- Carga un estilo CSS externo
local file = fileOpen("stylesheet.css")
if file then
    local css = fileRead(file, fileGetSize(file))
    fileClose(file)
    pcall(function() ReanUI.loadStyle(css) end)
end

-- Crea y añade un elemento usando las clases de estilo
local btn = ReanUI.create("button", { class = "btn-primary" }, "¡Hola MTA Glassmorphism!")
root:appendChild(btn)
```

## 🧪 Ejecución de Tests y Demos (Glassmorphism)

ReanUI incluye una demo interactiva para MTA con un diseño **Glassmorphism Premium** que puedes iniciar inmediatamente:

1.  Asegúrate de que la carpeta del recurso se llame `reanui`.
2.  En la consola de comandos de MTA (F8) o del servidor, escribe: `start reanui`.
3.  Verás una interfaz moderna en el centro de tu pantalla, que incluye un panel translúcido, campos de texto interactivos, botones reactivos y efectos de shader de desenfoque de fondo en tiempo real.

## 🤝 Contribución

Las contribuciones son bienvenidas. Asegúrate de que tu código siga los estándares de documentación inline (LDoc) y que todos los tests pasen antes de enviar un Pull Request.
