local ReanUI = require("src.ReanUI")

_G.getScreenSize = function() return 800, 600 end
_G.addEventHandler = function() end
_G.getKeyState = function() return false end

local function assertTrue(cond, msg)
    if not cond then error("[FAIL] " .. msg) end
end

local root = ReanUI.init(800, 600)
local a = ReanUI.create("input", { id = "a", placeholder = "a" })
local b = ReanUI.create("input", { id = "b", placeholder = "b" })
root:appendChild(a)
root:appendChild(b)
ReanUI.update(800, 600, 1/60)

a:focus()
assertTrue(a:hasClass("is-focused"), "input A debe tener foco")

local submitted = false
a:addEventListener("submit", function(e)
    submitted = (e.value == a:getValue())
end)

ReanUI.handleCharacterEvent("h")
ReanUI.handleCharacterEvent("o")
ReanUI.handleCharacterEvent("l")
ReanUI.handleCharacterEvent("a")
assertTrue(a:getValue() == "hola", "input A debe recibir caracteres")

ReanUI.handleKeyboardEvent("key", "arrow_l", true)
ReanUI.handleKeyboardEvent("key", "arrow_l", true)
assertTrue(a:getCursorPosition() == 2, "cursor debe moverse a la izquierda")

ReanUI.handleKeyboardEvent("key", "backspace", true)
assertTrue(a:getValue() == "hla", "backspace debe borrar el caracter previo al cursor")

ReanUI.handleKeyboardEvent("key", "delete", true)
assertTrue(a:getValue() == "ha", "delete debe borrar el caracter al frente del cursor")

ReanUI.handleKeyboardEvent("key", "home", true)
assertTrue(a:getCursorPosition() == 0, "home debe mover cursor al inicio")
ReanUI.handleKeyboardEvent("key", "end", true)
assertTrue(a:getCursorPosition() == #a:getValue(), "end debe mover cursor al final")
ReanUI.handleKeyboardEvent("key", "enter", true)
assertTrue(submitted, "enter debe disparar submit")

-- Cambiar foco y comprobar aislamiento de teclado
b:focus()
ReanUI.handleCharacterEvent("z")
assertTrue(a:getValue() == "ha", "input A no debe cambiar sin foco")
assertTrue(b:getValue() == "z", "input B debe recibir caracteres con foco")

print("PASS tests/test_input_keyboard.lua")
