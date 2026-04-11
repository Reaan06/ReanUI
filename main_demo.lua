local ReanUI = require("src.ReanUI")

-- 1. Inicializar ReanUI
ReanUI:init()

-- 2. Registrar Estilos Globales
ReanUI.Theme.registerClass("card", {
    color = tocolor(25, 25, 25, 255),
    borderRadius = 25,
    border = 1,
    borderColor = tocolor(55, 55, 55, 255)
})

ReanUI.Theme.registerClass("btn", {
    color = "var(--primary)",
    hoverColor = tocolor(0, 150, 255, 255),
    borderRadius = 12,
    textColor = tocolor(255, 255, 255, 255)
})

-- 3. Crear Ventana Principal
local mainCard = ReanUI:create("Container", "20vw", "15vh", "60vw", "70vh", {
    className = "card"
})

-- Título
ReanUI:create("Label", "0", "0", "100%", "60", {
    text = "ReanUI Professional v2.0",
    style = { fontSize = 16, textAlign = "center", verticalAlign = "center" }
}):addChildTo(mainCard)

-- 4. Crear ScrollPane (Área de contenido)
local scroll = ReanUI:create("ScrollPane", "5%", "15%", "90%", "65%", {
    style = { color = tocolor(20, 20, 20, 255), borderRadius = 15 }
})
mainCard:addChild(scroll)

-- Añadir elementos al ScrollPane para probar el scroll
for i = 1, 10 do
    local item = ReanUI:create("Container", "5%", (i-1)*120 + 20, "90%", "100", {
        style = { color = tocolor(40, 40, 40, 255), borderRadius = 10 }
    })
    scroll:addChild(item)
    
    ReanUI:create("Label", "20", "20", "200", "30", {
        text = "Item de Prueba #" .. i,
        style = { fontSize = 12 }
    }):addChildTo(item)
    
    ReanUI:create("Button", "70%", "30", "25%", "40", {
        text = "Action " .. i,
        className = "btn"
    }):addChildTo(item)
end

-- 5. Footer con input
local footer = ReanUI:create("Container", "5%", "85%", "90%", "10%", {
    style = { color = tocolor(15, 15, 15, 255), borderRadius = 10 }
})
mainCard:addChild(footer)

local chatInput = ReanUI:create("Edit", "5", "5", "70%", "90%", {
    placeholder = "Escribe un mensaje aquí...",
    style = { color = tocolor(10, 10, 10, 255), borderRadius = 8 }
})
footer:addChild(chatInput)

local sendBtn = ReanUI:create("Button", "75%", "5", "20%", "90%", {
    text = "SEND",
    className = "btn"
})
footer:addChild(sendBtn)

outputChatBox("[ReanUI] Fase 1 y 2 COMPLETADAS. Prueba el Scroll con la rueda del ratón.", 0, 255, 0)
