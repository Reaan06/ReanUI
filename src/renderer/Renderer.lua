local ShapeGenerator = require("src.renderer.ShapeGenerator")

local Renderer = {}
Renderer.__index = Renderer

function Renderer:new()
    local o = { _vram_usage = 0, _force_update = false }
    setmetatable(o, self)
    addEventHandler("onClientRestore", root, function() o._force_update = true end)
    return o
end

function Renderer:needsRenderTarget(element)
    local style = element.computedStyle
    if element.type == "ScrollPane" then return true end
    if style.opacity and style.opacity < 1 then return true end
    if style.borderRadius and style.borderRadius > 0 then return true end
    return false
end

function Renderer:render(elements)
    if not elements then return end
    for _, element in ipairs(elements) do self:renderElement(element, nil, 0, 0) end
    self._force_update = false
end

function Renderer:renderElement(element, parentRT, offX, offY)
    if not element.visible then return end
    local needsRT = self:needsRenderTarget(element)
    if needsRT then self:renderWithRenderTarget(element, parentRT, offX, offY)
    else self:renderDirect(element, parentRT, offX, offY) end
end

function Renderer:drawBackground(element, x, y, w, h, isRT)
    local s = element.computedStyle
    local color = s.color or tocolor(255, 255, 255, 255)
    local r = s.borderRadius or 0
    if r > 0 then
        if not isElement(element._svg) or element._svgW ~= w or element._svgH ~= h or element._svgR ~= r or element._svgC ~= color then
            if isElement(element._svg) then destroyElement(element._svg) end
            local svgXML = ShapeGenerator.createRoundedRectangle(w, h, r, color, s.border, s.borderColor)
            element._svg = svgCreate(w, h, svgXML)
            element._svgW, element._svgH, element._svgR, element._svgC = w, h, r, color
        end
        if isElement(element._svg) then dxDrawImage(x, y, w, h, element._svg, 0, 0, 0, -1, isRT) end
    else dxDrawRectangle(x, y, w, h, color, isRT) end
end

function Renderer:drawText(element, x, y, w, h, isRT)
    local s = element.computedStyle
    local text = element.text or ""
    local color = s.textColor or tocolor(255, 255, 255, 255)
    
    if element.type == "Edit" and text == "" and not element.focused then
        text = element.placeholder or ""
        color = tocolor(100, 100, 100, 150)
    end
    if element.type == "Checkbox" then
        if element.checked then text = "✓"; s.textAlign = "center"; s.verticalAlign = "center" else return end
    end
    if text == "" and not element.focused then return end
    if s.textShadow then dxDrawText(text, x + 1, y + 1, x + w + 1, y + h + 1, tocolor(0, 0, 0, 150), 1, s.font, s.textAlign, s.verticalAlign, true, true, isRT, s.colorCoded) end
    dxDrawText(text, x, y, x + w, y + h, color, 1, s.font, s.textAlign, s.verticalAlign, true, true, isRT, s.colorCoded)
    if element.type == "Edit" and element.focused then
        local tw = dxGetTextWidth(text, 1, s.font, s.colorCoded)
        local th = dxGetFontHeight(1, s.font); local caretX = x + 5
        if s.textAlign == "center" then caretX = x + (w/2) + (tw/2) elseif s.textAlign == "right" then caretX = x + w - 5 else caretX = x + 5 + tw end
        if (getTickCount() % 1000) < 500 then dxDrawLine(caretX, y + (h/2) - (th/2), caretX, y + (h/2) + (th/2), tocolor(255, 255, 255, 255), 1, isRT) end
    end
end

function Renderer:renderDirect(element, parentRT, offX, offY)
    local s = element.computedStyle
    local drawX, drawY = element.x + offX, element.y + offY
    s.absX, s.absY = drawX, drawY
    self:drawBackground(element, drawX, drawY, element.width, element.height, false)
    self:drawText(element, drawX, drawY, element.width, element.height, false)
    if element.children then for _, child in ipairs(element.children) do self:renderElement(child, parentRT, drawX, drawY) end end
end

function Renderer:renderWithRenderTarget(element, parentRT, offX, offY)
    local s = element.computedStyle
    local drawX, drawY = element.x + offX, element.y + offY
    s.absX, s.absY = drawX, drawY
    if not isElement(element._rt) or element._rtW ~= element.width or element._rtH ~= element.height then
        if isElement(element._rt) then destroyElement(element._rt) end
        element._rt = dxCreateRenderTarget(element.width, element.height, true)
        element._rtW, element._rtH, element._update = element.width, element.height, true
    end
    if element._update or self._force_update or (element.type == "Edit" and element.focused) or element.type == "ScrollPane" then
        dxSetRenderTarget(element._rt, true)
        dxSetBlendMode("modulate_add")
        self:drawBackground(element, 0, 0, element.width, element.height, true)
        self:drawText(element, 0, 0, element.width, element.height, true)
        
        -- Inyectar desplazamiento en ScrollPanes
        local innerOffX, innerOffY = 0, 0
        if element.type == "ScrollPane" then
            innerOffX = -(element.scrollX or 0)
            innerOffY = -(element.scrollY or 0)
        end
        
        if element.children then for _, child in ipairs(element.children) do self:renderElement(child, element._rt, innerOffX, innerOffY) end end
        if not (element.type == "Edit" and element.focused) and element.type ~= "ScrollPane" then element._update = false end
        dxSetRenderTarget(parentRT)
        dxSetBlendMode("blend")
    end
    if isElement(element._rt) then
        dxSetBlendMode("add")
        dxDrawImage(drawX, drawY, element.width, element.height, element._rt, 0, 0, 0, tocolor(255, 255, 255, math.floor((s.opacity or 1) * 255)))
        dxSetBlendMode("blend")
    end
end

return Renderer
