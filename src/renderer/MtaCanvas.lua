-- src/renderer/MtaCanvas.lua
-- Backend Canvas para Multi Theft Auto: San Andreas (dx* API).

local MtaCanvas = {}
MtaCanvas.__index = MtaCanvas

local _cache = {
    textures = {},      -- [path] = texture
    fonts = {},         -- [name:size] = font
    shaders = {},       -- [path] = shader
    renderTargets = {}  -- [uid] = { rt, w, h, withAlpha, dirty }
}

local _restoreHandlerRegistered = false

local function hasFn(name)
    return type(_G[name]) == "function"
end

local function isMtaElement(el)
    return hasFn("isElement") and isElement(el)
end

local function toIntColor(color)
    if type(color) == "number" then
        return color
    end

    if type(color) ~= "string" then
        return 0xFFFFFFFF
    end

    local hex = color:gsub("#", "")
    if #hex == 6 then
        hex = hex .. "FF"
    end
    if #hex ~= 8 then
        return 0xFFFFFFFF
    end

    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255
    local a = tonumber(hex:sub(7, 8), 16) or 255

    if hasFn("tocolor") then
        return tocolor(r, g, b, a)
    end

    -- Fallback ARGB
    return (((a * 256 + r) * 256 + g) * 256 + b)
end

local function safeDestroy(el)
    if isMtaElement(el) and hasFn("destroyElement") then
        destroyElement(el)
    end
end

local function clearRenderTargets()
    for _, entry in pairs(_cache.renderTargets) do
        safeDestroy(entry.rt)
    end
    _cache.renderTargets = {}
end

function MtaCanvas.new(width, height, postGUI)
    local self = setmetatable({
        width = width or 1920,
        height = height or 1080,
        postGUI = postGUI == true,
        _activeClip = nil,
        _rtStack = {},
        _activeShader = nil
    }, MtaCanvas)

    if not _restoreHandlerRegistered and hasFn("addEventHandler") and _G.root then
        addEventHandler("onClientRestore", root, function()
            self:onClientRestore()
        end)
        _restoreHandlerRegistered = true
    end

    return self
end

-- ============================================================================
-- DIBUJO BASE
-- ============================================================================

function MtaCanvas:drawRect(x, y, w, h, color, radius)
    if not hasFn("dxDrawRectangle") then return end

    -- Rounded corners se manejan por shader cuando aplica en renderer.
    -- Aquí mantenemos una ruta rápida y estable para rect base.
    dxDrawRectangle(x, y, w, h, toIntColor(color), self.postGUI)
end

function MtaCanvas:drawText(x, y, text, color, fontSize, fontFace)
    if not hasFn("dxDrawText") then return end

    fontFace = fontFace or "default"
    fontSize = tonumber(fontSize) or 16
    local scale = fontSize / 16
    if scale <= 0 then scale = 1 end

    local font = fontFace
    if hasFn("dxCreateFont") and fontFace ~= "default" then
        local key = fontFace .. ":" .. tostring(fontSize)
        local cached = _cache.fonts[key]
        if not cached or not isMtaElement(cached) then
            cached = dxCreateFont(fontFace, fontSize)
            _cache.fonts[key] = cached or "default"
        end
        font = _cache.fonts[key]
    end

    dxDrawText(
        tostring(text or ""),
        x, y, x, y,
        toIntColor(color),
        scale,
        font or "default",
        "left", "top",
        false, false, self.postGUI
    )
end

function MtaCanvas:drawImage(x, y, w, h, imagePathOrTexture)
    if not hasFn("dxDrawImage") then return end

    local texture = imagePathOrTexture
    if type(imagePathOrTexture) == "string" then
        local cached = _cache.textures[imagePathOrTexture]
        if not cached or (hasFn("isElement") and not isElement(cached)) then
            if hasFn("dxCreateTexture") then
                cached = dxCreateTexture(imagePathOrTexture)
            end
            _cache.textures[imagePathOrTexture] = cached
        end
        texture = cached
    end

    if texture then
        dxDrawImage(x, y, w, h, texture, 0, 0, 0, 0xFFFFFFFF, self.postGUI)
    end
end

function MtaCanvas:drawShadow(x, y, w, h, radius, blur, color)
    local offset = tonumber(blur) or 4
    self:drawRect(x + offset, y + offset, w, h, color or "#00000088", radius or 0)
end

function MtaCanvas:drawShader(x, y, w, h, shader, color, postGUI)
    if not hasFn("dxDrawImage") then return end
    if not shader then shader = self._activeShader end
    if not shader then return end
    if hasFn("isElement") and not isElement(shader) then return end

    dxDrawImage(
        x, y, w, h, shader, 0, 0, 0,
        toIntColor(color or "#FFFFFFFF"),
        postGUI ~= nil and postGUI or self.postGUI
    )
end

-- ============================================================================
-- SHADERS
-- ============================================================================

function MtaCanvas:applyShader(shaderPath, params)
    if type(shaderPath) ~= "string" or shaderPath == "" then
        self._activeShader = nil
        return nil
    end
    if not hasFn("dxCreateShader") then
        self._activeShader = nil
        return nil
    end

    local shader = _cache.shaders[shaderPath]
    if not shader or (hasFn("isElement") and not isElement(shader)) then
        shader = dxCreateShader(shaderPath)
        _cache.shaders[shaderPath] = shader
    end

    if shader and type(params) == "table" and hasFn("dxSetShaderValue") then
        for key, value in pairs(params) do
            dxSetShaderValue(shader, key, value)
        end
    end

    self._activeShader = shader
    return shader
end

-- ============================================================================
-- RENDER TARGETS
-- ============================================================================

local function ensureRenderTarget(uid, w, h, withAlpha)
    if uid == nil then return nil end
    if not hasFn("dxCreateRenderTarget") then return nil end

    local iw = math.max(1, math.floor(tonumber(w) or 1))
    local ih = math.max(1, math.floor(tonumber(h) or 1))
    local alpha = withAlpha ~= false

    local entry = _cache.renderTargets[uid]
    local needsRecreate = (not entry) or (not isMtaElement(entry.rt)) or entry.w ~= iw or entry.h ~= ih or entry.withAlpha ~= alpha

    if needsRecreate then
        if entry then safeDestroy(entry.rt) end
        entry = {
            rt = dxCreateRenderTarget(iw, ih, alpha),
            w = iw,
            h = ih,
            withAlpha = alpha,
            dirty = true
        }
        _cache.renderTargets[uid] = entry
    end

    return entry
end

function MtaCanvas:pushRenderTarget(uid, w, h, withAlpha)
    local entry = ensureRenderTarget(uid, w, h, withAlpha)
    if not entry or not entry.rt or not hasFn("dxSetRenderTarget") then
        return nil
    end

    local prev = hasFn("dxGetRenderTarget") and dxGetRenderTarget() or nil
    self._rtStack[#self._rtStack + 1] = prev
    dxSetRenderTarget(entry.rt, true)
    return entry.rt
end

function MtaCanvas:popRenderTarget()
    if not hasFn("dxSetRenderTarget") then return end
    local prev = self._rtStack[#self._rtStack]
    self._rtStack[#self._rtStack] = nil
    dxSetRenderTarget(prev)
end

function MtaCanvas:markRenderTargetDirty(uid)
    local entry = _cache.renderTargets[uid]
    if entry then entry.dirty = true end
end

function MtaCanvas:drawRenderTarget(uid, x, y, w, h, color)
    local entry = _cache.renderTargets[uid]
    if not entry or not entry.rt or not hasFn("dxDrawImage") then return false end
    dxDrawImage(x, y, w or entry.w, h or entry.h, entry.rt, 0, 0, 0, toIntColor(color or "#FFFFFFFF"), self.postGUI)
    return true
end

--- Dibuja un elemento en RT con dirty optimization.
--- drawFn debe renderizar el contenido local del elemento en coords de RT.
function MtaCanvas:drawCachedElement(element, drawFn)
    if not element or not drawFn then return false end
    if not element.getUid or not element._layout then return false end

    local uid = element:getUid()
    local l = element._layout
    local entry = ensureRenderTarget(uid, l.w, l.h, true)
    if not entry then
        drawFn()
        return false
    end

    local dirty = entry.dirty or element._dirty or element._child_dirty
    if dirty then
        self:pushRenderTarget(uid, l.w, l.h, true)
        drawFn()
        self:popRenderTarget()
        entry.dirty = false
    end

    self:drawRenderTarget(uid, l.x, l.y, l.w, l.h)
    return true
end

-- ============================================================================
-- CLIP
-- ============================================================================

function MtaCanvas:setClip(x, y, w, h)
    if hasFn("dxSetClipRectangle") then
        if x and y and w and h then
            dxSetClipRectangle(x, y, w, h)
            self._activeClip = { x = x, y = y, w = w, h = h }
        else
            dxSetClipRectangle()
            self._activeClip = nil
        end
        return
    end

    -- Fallback no-MTA
    if x and y and w and h then
        self._activeClip = { x = x, y = y, w = w, h = h }
    else
        self._activeClip = nil
    end
end

-- ============================================================================
-- RECUPERACIÓN / LIMPIEZA
-- ============================================================================

function MtaCanvas:onClientRestore()
    -- Render targets y shaders pierden contexto DX: recrear y marcar dirty.
    local previousRT = _cache.renderTargets
    _cache.renderTargets = {}
    for uid, entry in pairs(previousRT) do
        safeDestroy(entry.rt)
        local recreated = ensureRenderTarget(uid, entry.w, entry.h, entry.withAlpha)
        if recreated then
            recreated.dirty = true
        end
    end

    for path, shader in pairs(_cache.shaders) do
        safeDestroy(shader)
        if hasFn("dxCreateShader") then
            _cache.shaders[path] = dxCreateShader(path)
        else
            _cache.shaders[path] = nil
        end
    end
end

function MtaCanvas:destroy()
    for _, font in pairs(_cache.fonts) do safeDestroy(font) end
    for _, texture in pairs(_cache.textures) do safeDestroy(texture) end
    for _, shader in pairs(_cache.shaders) do safeDestroy(shader) end
    clearRenderTargets()
    _cache.fonts = {}
    _cache.textures = {}
    _cache.shaders = {}
end

return MtaCanvas
