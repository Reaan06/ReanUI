local StateManager = {
    hoveredElement = nil,
    focusedElement = nil,
    activeElement = nil,
    _click = false
}

function StateManager.isCursorOver(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    local sx, sy = guiGetScreenSize()
    cx, cy = cx * sx, cy * sy
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

function StateManager.update(roots)
    local foundHover = nil
    local function findHover(elements)
        if not elements then return nil end
        for i = #elements, 1, -1 do
            local element = elements[i]
            if element.visible then
                local childHover = findHover(element.children)
                if childHover then return childHover end
                local s = element.computedStyle
                if StateManager.isCursorOver(s.absX or 0, s.absY or 0, element.width, element.height) then return element end
            end
        end
        return nil
    end
    foundHover = findHover(roots)
    if foundHover ~= StateManager.hoveredElement then
        if StateManager.hoveredElement then StateManager.hoveredElement:onMouseLeave() end
        StateManager.hoveredElement = foundHover
        if foundHover then foundHover:onMouseEnter() end
    end
    local isClicked = getKeyState("mouse1")
    if isClicked and not StateManager._click then
        if foundHover then
            if foundHover ~= StateManager.focusedElement then
                if StateManager.focusedElement and StateManager.focusedElement.onBlur then StateManager.focusedElement:onBlur() end
                StateManager.focusedElement = foundHover
                if foundHover.onFocus then foundHover:onFocus() end
            end
            if foundHover.onClick then foundHover:onClick() end
            triggerEvent("onClick", foundHover)
        else
            if StateManager.focusedElement and StateManager.focusedElement.onBlur then StateManager.focusedElement:onBlur() end
            StateManager.focusedElement = nil
        end
    end
    StateManager._click = isClicked
end

-- Soporte para Scroll en ScrollPanes
addEventHandler("onClientKey", root, function(button, press)
    if not press then return end
    if button == "mouse_wheel_up" or button == "mouse_wheel_down" then
        if StateManager.hoveredElement then
            -- Buscar el primer ancestro que sea ScrollPane
            local target = StateManager.hoveredElement
            while target do
                if target.type == "ScrollPane" then
                    local step = 30
                    if button == "mouse_wheel_up" then target:scrollTo(target.scrollX, target.scrollY - step)
                    else target:scrollTo(target.scrollX, target.scrollY + step) end
                    return
                end
                target = target.parent
            end
        end
    end
end)

return StateManager
