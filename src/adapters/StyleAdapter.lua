StyleAdapter = {}
StyleAdapter.__index = StyleAdapter

function StyleAdapter:process(cssTable)
    -- Lógica de normalización de CSS que será expandida
    return cssTable
end

return StyleAdapter
