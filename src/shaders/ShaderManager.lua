-- src/shaders/ShaderManager.lua
-- Módulo de gestión centralizada de Shaders para ReanUI en MTA:SA.

local ShaderManager = {}
local _cache = {} -- { [path] = shaderElement }

--- Obtiene un shader de la caché o lo crea si no existe.
-- @tparam string path Ruta al archivo .fx.
-- @treturn element|nil El elemento shader de MTA.
function ShaderManager.getShader(path)
    if not path or type(path) ~= "string" then return nil end
    
    if _cache[path] and isElement(_cache[path]) then
        return _cache[path]
    end
    
    local shader = dxCreateShader(path)
    if shader then
        _cache[path] = shader
    else
        outputDebugString("[ReanUI:ShaderManager] Failed to create shader: " .. path, 2)
    end
    
    return shader
end

--- Aplica una tabla de parámetros (uniforms) a un shader.
-- @tparam element shader El elemento shader de MTA.
-- @tparam table params Diccionario de { nombre = valor }.
function ShaderManager.applyParams(shader, params)
    if not shader or not isElement(shader) or not params then return end
    
    for key, value in pairs(params) do
        dxSetShaderValue(shader, key, value)
    end
end

--- Destruye un shader específico y lo elimina de la caché.
-- @tparam string path Ruta al archivo .fx.
function ShaderManager.destroyShader(path)
    if _cache[path] then
        if isElement(_cache[path]) then
            destroyElement(_cache[path])
        end
        _cache[path] = nil
    end
end

--- Limpia toda la caché de shaders (útil para onClientRestore o reinicio).
function ShaderManager.clearCache()
    for path, shader in pairs(_cache) do
        if isElement(shader) then
            destroyElement(shader)
        end
    end
    _cache = {}
end

return ShaderManager
