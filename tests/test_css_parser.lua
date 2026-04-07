local parser = require("src.parser.css_parser")

-- Prueba de parseo CSS con parser Lua
local css = [[
    .btn {
        background-color: #ff0000;
        color: rgba(0, 255, 0, 1.0);
        width: 200px;
    }
    div#main {
        margin: 10px;
        border-color: #0000ff88;
    }
]]

print("--- Iniciando prueba de parseo CSS (Lua) ---")
local tree, err = parser.parse_css_string(css)

if not tree then
    print("Error:", err)
    os.exit(1)
end

print("Resultado del parseo:")
for selector, props in pairs(tree) do
    print(string.format("Selector: [%s]", selector))
    for name, val in pairs(props) do
        if type(val) == "number" then
            print(string.format("  - %s: 0x%08X (Color)", name, val))
        else
            print(string.format("  - %s: %s (String)", name, val))
        end
    end
end

print("--- Prueba completada con éxito ---")
