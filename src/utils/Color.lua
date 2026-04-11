local Color = {}

function Color.toHex(color)
    if not color then return "#FFFFFF" end
    local r, g, b = bitExtract(color, 16, 8), bitExtract(color, 8, 8), bitExtract(color, 0, 8)
    return string.format("#%.2X%.2X%.2X", r, g, b)
end

function Color.getAlpha(color)
    if not color then return 1 end
    return bitExtract(color, 24, 8) / 255
end

function Color.rgbaToHex(r, g, b)
    return string.format("#%.2X%.2X%.2X", r, g, b)
end

return Color
