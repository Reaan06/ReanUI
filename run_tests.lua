local tests = {
    "tests/test_event_system.lua",
    "tests/test_input_keyboard.lua",
    "tests/test_animation_engine.lua",
    "tests/test_renderer_mta_backend.lua",
    "tests/test_css_theme_integration.lua",
}

local function fileExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local passed = 0
local failed = 0

for _, path in ipairs(tests) do
    io.write("[RUN] " .. path .. "\n")
    if not fileExists(path) then
        io.write("[FAIL] Missing test file: " .. path .. "\n")
        failed = failed + 1
    else
        local ok, err = pcall(dofile, path)
        if ok then
            passed = passed + 1
        else
            io.write("[FAIL] " .. path .. " -> " .. tostring(err) .. "\n")
            failed = failed + 1
        end
    end
end

io.write(string.format("\n[Test Summary] passed=%d failed=%d total=%d\n", passed, failed, #tests))
if failed > 0 then
    os.exit(1)
end
