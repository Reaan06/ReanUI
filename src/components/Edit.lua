local UIElement = require("src.core.UIElement")

local Edit = {}
Edit.__index = Edit
setmetatable(Edit, {__index = UIElement})

local activeInput = nil

function Edit:new(x, y, w, h, props)
    props = props or {}
    
    local o = UIElement:new({
        x = x or 0,
        y = y or 0,
        width = w or 200,
        height = h or 40,
        style = props.style or {}
    })
    
    o.text = props.text or ""
    o.placeholder = props.placeholder or "Type here..."
    o.type = "Edit"
    o.focused = false
    o.caretPos = #o.text
    o.masked = props.masked or false
    o.maxCharacters = props.maxCharacters or 100
    
    setmetatable(o, self)
    
    -- Estilos por defecto de Edit
    if o.style.color == nil then o.style.color = tocolor(25, 25, 25, 255) end
    if o.style.borderRadius == nil then o.style.borderRadius = 8 end
    if o.style.textAlign == nil then o.style.textAlign = "left" end
    if o.style.verticalAlign == nil then o.style.verticalAlign = "center" end
    
    o:updateStyle()
    
    return o
end

function Edit:onMouseEnter()
    UIElement.onMouseEnter(self)
end

function Edit:onMouseLeave()
    UIElement.onMouseLeave(self)
end

function Edit:onFocus()
    if activeInput and activeInput ~= self then
        activeInput:onBlur()
    end
    self.focused = true
    activeInput = self
    guiSetInputEnabled(true)
    self._update = true
end

function Edit:onBlur()
    self.focused = false
    activeInput = nil
    guiSetInputEnabled(false)
    self._update = true
end

-- Handlers globales de input
addEventHandler("onClientCharacter", root, function(character)
    if activeInput and activeInput.focused then
        if #activeInput.text < activeInput.maxCharacters then
            activeInput.text = activeInput.text .. character
            activeInput.caretPos = #activeInput.text
            activeInput._update = true
            triggerEvent("onEditChange", activeInput, activeInput.text)
        end
    end
end)

addEventHandler("onClientKey", root, function(button, press)
    if not press then return end
    if activeInput and activeInput.focused then
        if button == "backspace" then
            if #activeInput.text > 0 then
                activeInput.text = activeInput.text:sub(1, -2)
                activeInput.caretPos = #activeInput.text
                activeInput._update = true
                triggerEvent("onEditChange", activeInput, activeInput.text)
            end
        elseif button == "enter" or button == "num_enter" or button == "tab" then
            activeInput:onBlur()
        end
    end
end)

-- Actualizar el Renderer para dibujar el caret y el placeholder
return Edit
