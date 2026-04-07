-- src/renderer/MtaCanvas.lua
-- Implementación del backend de renderizado para MTA:SA usando dxDraw*.

local MtaCanvas = {}
MtaCanvas.__index = MtaCanvas

-- Cache para recursos costosos (MTA requiere gestión manual)
local _resourceCache = {
    fonts = {},
    textures = {},
    shaders = {},
    renderTargets = {}
}

--- Constructor del Canvas para MTA.
-- @tparam number width Ancho del lienzo (normalmente screen width).
-- @tparam number height Alto del lienzo (normalmente screen height).
-- @tparam boolean postGUI Si se dibuja encima de la GUI de MTA.
function MtaCanvas.new(width, height, postGUI)
    local self = setmetatable({
        width = width or 1920,
        height = height or 1080,
        postGUI = postGUI or false,
        _activeClip = nil
    }, MtaCanvas)

    -- Cargar shader de rectángulos redondeados por defecto
    self:_initShader()
    
    return self
end

function MtaCanvas:_initShader()
    if not _resourceCache.shaders.rounded then
        _resourceCache.shaders.rounded = dxCreateShader("src/renderer/shaders/rounded_rect.fx")
    end
    
    -- Shader de blur para sombras (pre-procesado o pool)
    if not _resourceCache.shaders.blur then
        _resourceCache.shaders.blur = dxCreateShader("assets/shaders/blur.fx")
    end
end

-- ============================================================================
-- MÉTODOS DE DIBUJO
-- ============================================================================

--- Dibuja un rectángulo con soporte de bordes redondeados vía Shader.
function MtaCanvas:drawRect(x, y, w, h, color, radius)
    radius = radius or 0
    if radius > 0 and _resourceCache.shaders.rounded then
        local shader = _resourceCache.shaders.rounded
        
        -- Configurar parámetros del shader
        dxSetShaderValue(shader, "rectSize", {w, h})
        dxSetShaderValue(shader, "radius", radius)
        
        -- Convertir color HEX/Int a tabla RGBA para el shader {r, g, b, a}
        local a = bitExtract(color, 24, 8) / 255
        local r = bitExtract(color, 16, 8) / 255
        local g = bitExtract(color, 8, 8) / 255
        local b = bitExtract(color, 0, 8) / 255
        dxSetShaderValue(shader, "color", {r, g, b, a})
        
        -- Dibujar el shader
        dxDrawImage(x, y, w, h, shader, 0, 0, 0, color, self.postGUI)
    else
        -- Dibujo estándar (rectangular)
        dxDrawRectangle(x, y, w, h, color, self.postGUI)
    end
end

--- Dibuja texto con sistema de caché de fuentes.
function MtaCanvas:drawText(x, y, text, color, fontSize, fontFace)
    fontFace = fontFace or "default"
    local fontKey = fontFace .. "_" .. tostring(fontSize)
    
    local dxFont = "default"
    if fontSize > 12 or fontFace ~= "default" then
        if not _resourceCache.fonts[fontKey] then
            -- Si es un archivo .ttf o una fuente del sistema
            _resourceCache.fonts[fontKey] = dxCreateFont(fontFace, fontSize) or "default"
        end
        dxFont = _resourceCache.fonts[fontKey]
    end

    dxDrawText(text, x, y, x, y, color, 1, dxFont, "left", "top", false, false, self.postGUI)
end

--- Dibuja una imagen con sistema de caché de texturas.
function MtaCanvas:drawImage(x, y, w, h, imagePathOrTexture)
    local texture = imagePathOrTexture
    if type(imagePathOrTexture) == "string" then
        if not _resourceCache.textures[imagePathOrTexture] then
            _resourceCache.textures[imagePathOrTexture] = dxCreateTexture(imagePathOrTexture)
        end
        texture = _resourceCache.textures[imagePathOrTexture]
    end

    if texture then
        dxDrawImage(x, y, w, h, texture, 0, 0, 0, 0xFFFFFFFF, self.postGUI)
    end
end

--- Dibuja una sombra con soporte de Blur vía Shader.
function MtaCanvas:drawShadow(x, y, w, h, radius, blur, color)
    local blurValue = blur or 0
    if blurValue > 0 and _resourceCache.shaders.blur then
        local shader = _resourceCache.shaders.blur
        dxSetShaderValue(shader, "blurFactor", blurValue)
        -- Dibujar el shader con offset de sombra
        self:drawShader(x + 2, y + 2, w, h, shader, color)
    else
        -- Sombra plana
        local shadowOffset = blurValue > 0 and blurValue or 4
        self:drawRect(x + shadowOffset, y + shadowOffset, w, h, color, radius)
    end
end

--- Dibuja un shader específico.
function MtaCanvas:drawShader(x, y, w, h, shader, color, postGUI)
    if not shader or not isElement(shader) then return end
    dxDrawImage(x, y, w, h, shader, 0, 0, 0, color or 0xFFFFFFFF, postGUI ~= nil and postGUI or self.postGUI)
end

--- Crea o recupera un Render Target.
function MtaCanvas:createRenderTarget(w, h, withAlpha)
    local key = w .. "x" .. h .. (withAlpha and "_a" or "")
    if not _resourceCache.renderTargets[key] then
        _resourceCache.renderTargets[key] = dxCreateRenderTarget(w, h, withAlpha)
    end
    return _resourceCache.renderTargets[key]
end

--- Establece el Render Target actual.
function MtaCanvas:setRenderTarget(rt, clear)
    dxSetRenderTarget(rt, clear)
end

--- Limpia el Render Target actual.
function MtaCanvas:clearRenderTarget(rt, color)
    if rt then
        dxSetRenderTarget(rt)
        dxDrawRectangle(0, 0, 1, 1, color or 0x00000000) -- Limpiar con color
        dxSetRenderTarget() -- Restaurar
    end
end

--- Establece el área de recorte.
function MtaCanvas:setClip(x, y, w, h)
    if x and y and w and h then
        dxSetClipRectangle(x, y, w, h)
        self._activeClip = {x, y, w, h}
    else
        dxSetClipRectangle()
        self._activeClip = nil
    end
end

-- ============================================================================
-- LIMPIEZA
-- ============================================================================

function MtaCanvas:destroy()
    -- Aunque el cache es estático, en un cambio de recurso querríamos liberar todo
    for _, font in pairs(_resourceCache.fonts) do 
        if isElement(font) then destroyElement(font) end 
    end
    for _, tex in pairs(_resourceCache.textures) do 
        if isElement(tex) then destroyElement(tex) end 
    end
    for _, rt in pairs(_resourceCache.renderTargets) do
        if isElement(rt) then destroyElement(rt) end
    end
    _resourceCache = { fonts={}, textures={}, shaders={}, renderTargets={} }
end

return MtaCanvas
