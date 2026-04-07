local MtaCanvas = require("src.renderer.MtaCanvas")

local function assertTrue(cond, msg)
    if not cond then error("[FAIL] " .. msg) end
end

local function assertEq(a, b, msg)
    if a ~= b then
        error(string.format("[FAIL] %s | expected=%s got=%s", msg, tostring(b), tostring(a)))
    end
end

local calls = {
    rect = 0,
    text = 0,
    image = 0,
    setRT = 0,
    createRT = 0,
    createShader = 0,
    shaderValues = 0,
}

local rtId = 0
local shaderId = 0
local currentRT = nil
local elements = {}

_G.root = {}
_G.addEventHandler = function() end
_G.tocolor = function(r, g, b, a) return (a * 1000000) + (r * 10000) + (g * 100) + b end
_G.isElement = function(el) return type(el) == "table" and el.__is_mta_element == true end
_G.destroyElement = function(el) if el then el.__destroyed = true end end
_G.dxDrawRectangle = function() calls.rect = calls.rect + 1 end
_G.dxDrawText = function() calls.text = calls.text + 1 end
_G.dxDrawImage = function() calls.image = calls.image + 1 end
_G.dxCreateTexture = function(path)
    local el = { __is_mta_element = true, kind = "texture", path = path }
    elements[#elements + 1] = el
    return el
end
_G.dxCreateFont = function(path, size)
    local el = { __is_mta_element = true, kind = "font", path = path, size = size }
    elements[#elements + 1] = el
    return el
end
_G.dxCreateRenderTarget = function(w, h, withAlpha)
    calls.createRT = calls.createRT + 1
    rtId = rtId + 1
    local el = { __is_mta_element = true, kind = "rt", id = rtId, w = w, h = h, alpha = withAlpha }
    elements[#elements + 1] = el
    return el
end
_G.dxSetRenderTarget = function(rt)
    calls.setRT = calls.setRT + 1
    currentRT = rt
end
_G.dxGetRenderTarget = function() return currentRT end
_G.dxCreateShader = function(path)
    calls.createShader = calls.createShader + 1
    shaderId = shaderId + 1
    local el = { __is_mta_element = true, kind = "shader", id = shaderId, path = path }
    elements[#elements + 1] = el
    return el
end
_G.dxSetShaderValue = function(shader, key, value)
    calls.shaderValues = calls.shaderValues + 1
    shader[key] = value
end
_G.dxSetClipRectangle = function() end

local canvas = MtaCanvas.new(1280, 720, false)

canvas:drawRect(1, 2, 3, 4, "#ff0000")
canvas:drawText(5, 6, "hello", "#ffffff", 16, "default")
canvas:drawImage(7, 8, 9, 10, "assets/fake.png")
assertEq(calls.rect, 1, "drawRect debe invocar dxDrawRectangle")
assertEq(calls.text, 1, "drawText debe invocar dxDrawText")
assertEq(calls.image, 1, "drawImage debe invocar dxDrawImage")

local shader = canvas:applyShader("assets/shaders/blur.fx", { blurFactor = 4.0, tint = "#fff" })
assertTrue(shader ~= nil, "applyShader debe crear shader")
assertEq(calls.createShader, 1, "shader debe crearse una vez")
assertEq(calls.shaderValues, 2, "debe aplicar parametros shader")

local element = {
    _dirty = true,
    _child_dirty = false,
    _layout = { x = 10, y = 20, w = 100, h = 50 },
    getUid = function() return "node-1" end
}
local drawFnCalls = 0
local function drawFn()
    drawFnCalls = drawFnCalls + 1
    canvas:drawRect(0, 0, 10, 10, "#00ff00")
end

local cached = canvas:drawCachedElement(element, drawFn)
assertTrue(cached == true, "drawCachedElement debe usar render target")
assertEq(drawFnCalls, 1, "primera vez debe redibujar")
assertEq(calls.createRT, 1, "debe crear RT una vez")

element._dirty = false
local cached2 = canvas:drawCachedElement(element, drawFn)
assertTrue(cached2 == true, "segunda vez debe dibujar desde cache")
assertEq(drawFnCalls, 1, "sin dirty no debe redibujar contenido")

canvas:markRenderTargetDirty("node-1")
canvas:drawCachedElement(element, drawFn)
assertEq(drawFnCalls, 2, "dirty manual debe forzar redraw")

local createRTBeforeRestore = calls.createRT
canvas:onClientRestore()
canvas:drawCachedElement(element, drawFn)
assertTrue(calls.createRT > createRTBeforeRestore, "onClientRestore debe recrear RT")

print("PASS tests/test_renderer_mta_backend.lua")
