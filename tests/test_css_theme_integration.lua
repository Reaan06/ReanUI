local ReanUI = require("src.ReanUI")
local ThemeManager = require("src.theme.ThemeManager")

_G.getScreenSize = function() return 1024, 768 end
_G.addEventHandler = function() end

local function assertTrue(cond, msg)
    if not cond then error("[FAIL] " .. msg) end
end

local function assertEq(a, b, msg)
    if a ~= b then
        error(string.format("[FAIL] %s | expected=%s got=%s", msg, tostring(b), tostring(a)))
    end
end

local okTheme = ReanUI.setTheme("dark")
assertTrue(okTheme == true, "setTheme(dark) debe ser exitoso")

local okStyle, err = ReanUI.loadStyle([[
input {
  border-color: var(--border-color);
  color: var(--text-color);
}
.primary {
  background-color: var(--primary-color);
  border-radius: 6px;
}
#cta {
  width: 220px;
}
]])
assertTrue(okStyle == true, "loadStyle debe parsear CSS valido: " .. tostring(err))

local root = ReanUI.init(1024, 768)
local input = ReanUI.create("input", { id = "cta", class = "primary", placeholder = "email" })
root:appendChild(input)
ReanUI.update(1024, 768, 1 / 60)

-- Variables del tema deben resolverse al leer estilo
assertEq(input:getStyle("border-color"), ThemeManager.getVariable("--border-color"), "resolucion de var(--border-color)")
assertEq(input:getStyle("color"), ThemeManager.getVariable("--text-color"), "resolucion de var(--text-color)")
assertEq(input:getStyle("background-color"), ThemeManager.getVariable("--primary-color"), "regla de clase + variable de tema")
assertEq(input:getStyle("width"), "220px", "regla por id debe aplicar")
assertEq(input:getStyle("border-radius"), "6px", "regla por clase debe aplicar")

-- Smoke test de input funcional sobre tema/css cargado
input:focus()
ReanUI.handleCharacterEvent("a")
ReanUI.handleCharacterEvent("@")
ReanUI.handleCharacterEvent("b")
assertEq(input:getValue(), "a@b", "input debe seguir funcional tras aplicar css/theme")

print("PASS tests/test_css_theme_integration.lua")
