-- test_css.lua (Lua-only)
local parser = require("src.parser.css_parser")

print("\n=== TEST PARSER CSS (LUA) ===")
local css_string = [[
    .btn {
        width:   450px ;
        height   : 300px;
        background-color: #FA05B2 ;
    }
    #hero {
        color: #FFFFFF;
        atributo-invalido: nope;
    }
]]

local tree, err = parser.parse_css_string(css_string)
print("Error:", err)
print("Selectores parseados:", tree and "OK" or "FAIL")
print(".btn width:", tree[".btn"] and tree[".btn"]["width"])
print("#hero color:", tree["#hero"] and tree["#hero"]["color"])

print("\n=== SUCCESS ===")
