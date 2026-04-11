local FontManager = {
    _fonts = {},
    _defaultFont = "default"
}

local sx, sy = guiGetScreenSize()
local sw, sh = sx/1366, sy/768

function FontManager.load(path, size, bold)
    local key = string.format("%s_%d_%s", path, size, tostring(bold))
    if FontManager._fonts[key] then return FontManager._fonts[key] end
    
    if fileExists(path) then
        local font = dxCreateFont(path, size * sw, bold)
        if font then
            FontManager._fonts[key] = font
            return font
        end
    end
    return "default"
end

function FontManager.getDefault()
    return FontManager._defaultFont
end

return FontManager
