-- tests/test_utils.lua
-- Suite de pruebas exhaustiva para src/utils/Utils.lua

local Utils = require("src.utils.Utils")

local PASS, FAIL = 0, 0
local function test(label, condition)
    if condition then
        print("  [OK]   " .. label)
        PASS = PASS + 1
    else
        print("  [FAIL] " .. label)
        FAIL = FAIL + 1
    end
end

print("\n==========================================================")
print("===  REANUI: TEST UTILS LIBRARY                        ===")
print("==========================================================")

-- ============================================================================
-- Color Utils
-- ============================================================================
print("\n── Utils.Color ─────────────────────────────────────────")

local c = Utils.Color.hexToRgb("#FF0000")
test("hexToRgb #FF0000 → r=255", c and c.r == 255)
test("hexToRgb #FF0000 → g=0",   c and c.g == 0)
test("hexToRgb #FF0000 → b=0",   c and c.b == 0)

local c2 = Utils.Color.hexToRgb("#03A")   -- Shorthand
test("hexToRgb shorthand #03A → g=51", c2 and c2.g == 51)

test("rgbToHex(255,0,0) = #FF0000",     Utils.Color.rgbToHex(255, 0, 0) == "#FF0000")
test("rgbToHex con alpha",              Utils.Color.rgbToHex(255, 0, 0, 128) == "#FF000080")

local parsed = Utils.Color.parseColor("rgb(100, 150, 200)")
test("parseColor rgb() → r=100",  parsed and parsed.r == 100)
test("parseColor rgb() → b=200",  parsed and parsed.b == 200)

local light = Utils.Color.lighten("#888888", 0.2)
test("lighten produce hex válido",  type(light) == "string" and light:sub(1,1) == "#")

local dark = Utils.Color.darken("#888888", 0.2)
test("darken produce hex válido",   type(dark) == "string")

local mixed = Utils.Color.mix("#000000", "#FFFFFF", 0.5)
local mc = Utils.Color.hexToRgb(mixed)
test("mix 50% negro/blanco → ~127", mc and mc.r >= 125 and mc.r <= 130)

-- ============================================================================
-- String Utils
-- ============================================================================
print("\n── Utils.String ─────────────────────────────────────────")

test("trim espacios inicio/fin",      Utils.String.trim("  hello  ") == "hello")
test("trim sin espacios",             Utils.String.trim("hi") == "hi")
test("startsWith true",               Utils.String.startsWith("ReanUI", "Rean"))
test("startsWith false",              not Utils.String.startsWith("ReanUI", "UI"))
test("endsWith true",                 Utils.String.endsWith("ReanUI", "UI"))
test("endsWith false",                not Utils.String.endsWith("ReanUI", "Rean"))
test("includes subtring presente",    Utils.String.includes("Hello World", "World"))
test("includes substring ausente",    not Utils.String.includes("Hello", "world"))

local parts = Utils.String.split("a,b,c", ",")
test("split a,b,c → 3 partes",        #parts == 3)
test("split primer elemento = 'a'",   parts[1] == "a")

local interp = Utils.String.interpolate("Hola {nombre}, tienes {edad} años.", { nombre = "Rean", edad = 21 })
test("interpolate remplaza {nombre}", Utils.String.includes(interp, "Rean"))
test("interpolate remplaza {edad}",   Utils.String.includes(interp, "21"))
test("interpolate clave ausente",     Utils.String.includes(interp, "{edad}") == false)

test("padStart '5' → '005'",          Utils.String.padStart("5", 3, "0") == "005")

-- ============================================================================
-- Table Utils
-- ============================================================================
print("\n── Utils.Table ──────────────────────────────────────────")

local orig = { a = 1, b = 2 }
local cloned = Utils.Table.clone(orig)
test("clone produce tabla nueva",     cloned ~= orig)
test("clone copia valores",           cloned.a == 1 and cloned.b == 2)

cloned.a = 99
test("clone es superficial (original no cambia)", orig.a == 1)

local deep = { x = { y = { z = 42 } } }
local deepC = Utils.Table.deepClone(deep)
deepC.x.y.z = 0
test("deepClone aísla niveles profundos", deep.x.y.z == 42)

local merged = Utils.Table.merge({ a = 1 }, { b = 2 }, { a = 99 })
test("merge combina tablas",          merged.b == 2)
test("merge el último gana",          merged.a == 99)

local filtered = Utils.Table.filter({1, 2, 3, 4, 5}, function(v) return v % 2 == 0 end)
test("filter pares → {2, 4}",         #filtered == 2 and filtered[1] == 2)

local mapped = Utils.Table.map({1, 2, 3}, function(v) return v * 10 end)
test("map multiplica por 10",         mapped[1] == 10 and mapped[3] == 30)

local sum = Utils.Table.reduce({1, 2, 3, 4}, function(acc, v) return acc + v end, 0)
test("reduce suma = 10",              sum == 10)

test("includes valor presente",       Utils.Table.includes({10, 20, 30}, 20))
test("includes valor ausente",        not Utils.Table.includes({10, 20}, 99))

test("count tabla mixta",             Utils.Table.count({a=1, b=2, c=3}) == 3)
test("keys devuelve claves",          Utils.Table.count(Utils.Table.keys({a=1, b=2})) == 2)
test("values devuelve valores",       Utils.Table.includes(Utils.Table.values({a=5}), 5))

-- ============================================================================
-- Number Utils
-- ============================================================================
print("\n── Utils.Number ─────────────────────────────────────────")

test("clamp dentro del rango",        Utils.Number.clamp(5, 0, 10) == 5)
test("clamp por debajo del mín",      Utils.Number.clamp(-5, 0, 10) == 0)
test("clamp por encima del máx",      Utils.Number.clamp(15, 0, 10) == 10)
test("lerp t=0 retorna a",            Utils.Number.lerp(0, 100, 0) == 0)
test("lerp t=1 retorna b",            Utils.Number.lerp(0, 100, 1) == 100)
test("lerp t=0.5 retorna 50",         Utils.Number.lerp(0, 100, 0.5) == 50)
test("roundTo 2 decimales",           Utils.Number.roundTo(3.14159, 2) == 3.14)
test("roundTo 0 decimales = entero",  Utils.Number.roundTo(3.7, 0) == 4)
test("toDegrees π = 180",             math.abs(Utils.Number.toDegrees(math.pi) - 180) < 0.001)
test("toRadians 180 = π",             math.abs(Utils.Number.toRadians(180) - math.pi) < 0.001)
test("normalize 5 en [0,10] = 0.5",   Utils.Number.normalize(5, 0, 10) == 0.5)
test("inRange: 5 en [0,10]",          Utils.Number.inRange(5, 0, 10))
test("inRange: 11 fuera de [0,10]",   not Utils.Number.inRange(11, 0, 10))

local rnd = Utils.Number.randomRange(10, 20)
test("randomRange en [10,20]",        rnd >= 10 and rnd <= 20)

-- ============================================================================
-- Validation Utils
-- ============================================================================
print("\n── Utils.Validation ─────────────────────────────────────")

test("isNumber con 42",           Utils.Validation.isNumber(42))
test("isNumber con string",       not Utils.Validation.isNumber("42"))
test("isString con 'hello'",      Utils.Validation.isString("hello"))
test("isTable con {}",            Utils.Validation.isTable({}))
test("isEmpty string vacío",      Utils.Validation.isEmpty(""))
test("isEmpty tabla vacía",       Utils.Validation.isEmpty({}))
test("isEmpty nil",               Utils.Validation.isEmpty(nil))
test("isEmpty string NO vacío",   not Utils.Validation.isEmpty("hi"))
test("hasProperty clave existe",  Utils.Validation.hasProperty({x=1}, "x"))
test("hasProperty clave ausente", not Utils.Validation.hasProperty({x=1}, "y"))
test("isInteger 4 → true",        Utils.Validation.isInteger(4))
test("isInteger 4.5 → false",     not Utils.Validation.isInteger(4.5))
test("isHexColor #FF0000 válido", Utils.Validation.isHexColor("#FF0000"))
test("isHexColor XYZ inválido",   not Utils.Validation.isHexColor("XYZ"))

-- ============================================================================
-- Performance Utils
-- ============================================================================
print("\n── Utils.Performance ────────────────────────────────────")

-- Memoize
local call_count = 0
local expensive = Utils.Performance.memoize(function(n)
    call_count = call_count + 1
    return n * n
end)
expensive(4)
expensive(4)
expensive(4)
test("memoize ejecuta fn solo 1 vez para mismo arg", call_count == 1)
expensive(5)
test("memoize ejecuta fn para arg nuevo",            call_count == 2)

-- Throttle
local throttle_count = 0
local throttled = Utils.Performance.throttle(function() throttle_count = throttle_count + 1 end, 100)
for i = 1, 10 do throttled() end
test("throttle bloquea llamadas intermedias",  throttle_count == 1)

-- Debounce
local debounce_result = nil
local debounced = Utils.Performance.debounce(function(v) debounce_result = v end, 100)
debounced("a"); debounced("b"); debounced("c")
test("debounce pendiente antes del flush",    debounce_result == nil)
debounced:flush()
test("debounce flush ejecuta con último arg", debounce_result == "c")

-- ============================================================================
-- Debug Utils
-- ============================================================================
print("\n── Utils.Debug ──────────────────────────────────────────")

local out = Utils.Debug.inspect({ name = "Rean", value = 42, nested = { x = 1 } })
test("inspect devuelve string",       type(out) == "string")
test("inspect contiene clave 'name'", Utils.String.includes(out, "name"))
test("inspect maneja anidado",        Utils.String.includes(out, "nested"))

local out2 = Utils.Debug.inspect("hello")
test("inspect string literal",        out2 == '"hello"')

local ok, err = pcall(Utils.Debug.assert, false, "Prueba de assert fallido")
test("assert lanza error si false",   not ok and Utils.String.includes(err, "Prueba de assert"))
test("assert pasa si true",           Utils.Debug.assert(true, "No debería fallar") == true)

print("\n==========================================================")
print(string.format("===  RESULTADO: %d OK  |  %d FAIL  %s", PASS, FAIL, FAIL == 0 and "✓ TODO OK" or "✗ HAY FALLOS"))
print("==========================================================\n")
