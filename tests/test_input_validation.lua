-- tests/test_input_validation.lua
-- Suite de pruebas para el componente Input y Validadores.

local Input = require("src.components.Input")

print("\n==========================================================")
print("===  REANUI: TEST COMPONENTE INPUT & VALIDATION        ===")
print("==========================================================\n")

-- 1. Prueba de Input EMAIL
print("[TEST 1] Validación de Email:")
local inputEmail = Input.new("email")
inputEmail:setRequired(true)

print("  - Caso Vacío (Required): " .. (inputEmail:isValid() == false and "OK" or "FAIL"))
inputEmail:setValue("invalid-email")
print("  - Caso Inválido:         " .. (inputEmail:isValid() == false and "OK" or "FAIL"))
inputEmail:setValue("user@example.com")
print("  - Caso Válido:           " .. (inputEmail:isValid() == true and "OK" or "FAIL"))

-- 2. Prueba de Input NUMBER
print("\n[TEST 2] Validación de Número:")
local inputNum = Input.new("number")
inputNum:setValue("abc")
print("  - Caso Inválido (abc):   " .. (inputNum:isValid() == false and "OK" or "FAIL"))
inputNum:setValue("123.45")
print("  - Caso Válido (123.45):  " .. (inputNum:isValid() == true and "OK" or "FAIL"))

-- 3. Prueba de MaxLength y Sanitización
print("\n[TEST 3] MaxLength y Sanitización:")
local inputText = Input.new("text")
inputText:setMaxLength(5)
inputText:setValue("Ho\0la Mundo") -- "Ho" + null + "la" + "Mundo" (Truncar a 5)

print("  - Sanitización (Null):   " .. (not inputText:getValue():find("\0") and "OK" or "FAIL"))
print("  - MaxLength (Truncao):   " .. (#inputText:getValue() <= 5 and "OK" or "FAIL"))
print("  - Valor final:           " .. (inputText:getValue() == "Hola " and "OK" or "FAIL"))

-- 4. Prueba de Eventos (onChange)
print("\n[TEST 4] Eventos de Cambio:")
local changeCount = 0
inputText:addEventListener("change", function(data)
    changeCount = changeCount + 1
    print("    >> Valor actualizado: '" .. data.value .. "' (Total: " .. changeCount .. ")")
end)

inputText:setValue("A")
inputText:setValue("B")
print("  - Resultados:            " .. (changeCount == 2 and "OK" or "FAIL"))

-- 5. Ciclo de Vida Visual (Visual Verification via debugPrint)
print("\n[TEST 5] Ciclo de Vida Visual (Foco/Error):")
inputEmail:setValue("mal_formado")
inputEmail:onFocus()
inputEmail:debugPrint()
inputEmail:onBlur()
inputEmail:debugPrint()

print("\n==========================================================")
print("===  PRUEBAS DE INPUT COMPLETADAS                      ===")
print("==========================================================\n")
