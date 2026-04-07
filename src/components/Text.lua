-- src/components/Text.lua
-- Componente de texto estático. Soporte para font-size, color, align.

local UIElement = require("src.core.UIElement")

local Text = {}
Text.__index = Text
setmetatable(Text, { __index = UIElement })

function Text.new(content, attrs)
    local self = UIElement.new("text", attrs)
    setmetatable(self, Text)

    self._content = content or ""
    return self
end

function Text:getContent()        return self._content end
function Text:setContent(str)     self._content = tostring(str); return self end

function Text:debugPrint(indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    local color = self:getStyle("color") or "inherit"
    print(string.format('%s<text color="%s" uid=%d> "%s"',
        prefix, color, self:getUid(), self._content))
end

return Text
