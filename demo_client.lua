-- demo_client.lua
-- Script de demostración interactiva de ReanUI para MTA:SA.

-- Verificación de dependencias
local function checkDependencies()
    if not ReanUI then
        outputDebugString("[ReanUI:Demo] Error: ReanUI no se cargó correctamente. Revisa el meta.xml.", 1)
        return false
    end
    return true
end

-- Función principal de inicialización de la Demo
local function startDemo()
    if not checkDependencies() then return end
    
    -- 1. Inicializar ReanUI (Foco en pantalla completa con soporte post-GUI)
    local sw, sh = getScreenSize()
    local root = ReanUI.init(sw, sh, true)
    
    -- 2. Mostrar cursos y habilitar UI
    showCursor(true)
    
    -- 3. Cargar Estilos Globales desde stylesheet.css
    local file = fileOpen("stylesheet.css")
    if file then
        local css = fileRead(file, fileGetSize(file))
        fileClose(file)
        
        -- Verificar si estamos en cliente que pre-parsea o usar bypass si no hay parser C.
        -- En cliente MTA real sin parser C, loadStyle podría fallar si require("build.reanui") falla.
        -- ReanUI.loadStyle() intentará llamar a Lexbor.
        local success, err = pcall(function()
            ReanUI.loadStyle(css)
        end)
        
        if not success then
             outputDebugString("[ReanUI:Demo] Aviso: Parser nativo no disponible. Simulando estilos para propósitos de la demo.", 3)
             -- Aquí idealmente cargaríamos un fallback pre-parseado, parseador Lua puro u omitiríamos estilos.
        end
    else
        outputDebugString("[ReanUI:Demo] Error: No se encontró stylesheet.css", 1)
    end
    
    -- 4. Construir la Interfaz de Usuario usando las clases del CSS
    local panel = ReanUI.create("div", { class = "glass-panel" }, {
        ReanUI.create("div", { class = "header" }, {
            ReanUI.create("text", { class = "title" }, "ReanUI"),
            ReanUI.create("text", { class = "subtitle" }, "MTA:SA Modern UI Framework")
        }),
        
        ReanUI.create("div", { class = "form-group" }, {
            ReanUI.create("text", { class = "label" }, "Username"),
            ReanUI.create("input", { class = "input-field", placeholder = "Enter your username..." })
        }),

        ReanUI.create("div", { class = "form-group" }, {
            ReanUI.create("text", { class = "label" }, "Password"),
            ReanUI.create("input", { class = "input-field", placeholder = "Enter your password..." })
        }),
        
        ReanUI.create("button", { class = "btn-primary" }, "Login"),
        
        ReanUI.create("div", { class = "shader-box" }, {
            ReanUI.create("text", { class = "shader-text" }, "Blur Shader Active")
        })
    })
    
    -- Añadir el panel a la raíz
    root:appendChild(panel)
    
    -- Posicionar el panel en el centro de la pantalla
    panel:setStyle("position", "absolute")
    panel:setStyle("left", (sw - 480) / 2)
    panel:setStyle("top", (sh - 550) / 2)
    
    -- Aplicar shader de blur al sub-panel
    local blurPanel = panel:getChildren()[4] -- Índice 4 (0: header, 1: username, 2: pass, 3: btn, 4: shader-box. Pero es Lua, base 1: 1..5)
    blurPanel = panel:getChildren()[5]
    if blurPanel then
        blurPanel:setShader("assets/shaders/blur.fx", { blurFactor = 4.0 })
    end
    
    -- Eventos de Interacción
    local loginBtn = panel:getChildren()[4] 
    if loginBtn then
        loginBtn:addEventListener("click", function()
            outputChatBox("#00f2fe[ReanUI]#ffffff Login attempt processed!", 255, 255, 255, true)
        end)
    end
    
    outputChatBox("#00f2fe[ReanUI]#ffffff Recurso iniciado correctamente. Usa el cursor para interactuar.", 255, 255, 255, true)
end

-- Ejecutar cuando el recurso del cliente cargue
addEventHandler("onClientResourceStart", resourceRoot, startDemo)
