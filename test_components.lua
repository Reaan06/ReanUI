local ReanUI = require("src.ReanUI")
local Button = require("src.components.Button")

-- Inicializamos el Core
ReanUI:init()

-- Creamos una interfaz simple: Un contenedor con un botón
-- Sintaxis CSS declarativa
local mainPanel = ReanUI:create({
    style = { x = 50, y = 50, width = 300, height = 200, backgroundColor = {r=30, g=30, b=30, a=220} }
})

local myButton = Button:new({
    text = "¡Hola MTA!",
    style = { x = 75, y = 100, width = 250, height = 40, backgroundColor = {r=0, g=150, b=255, a=255} }
})

-- Registramos los componentes
ReanUI:register(mainBox) -- (Suponiendo que mainBox es el contenedor)
mainPanel:addChild(myButton)
ReanUI:register(mainPanel)

outputChatBox("ReanUI: Interfaz cargada correctamente.")
