local ReanUI = require("src.ReanUI")

_G.getScreenSize = function() return 800, 600 end
_G.addEventHandler = function() end

local function assertTrue(cond, msg)
    if not cond then
        error("[FAIL] " .. msg)
    end
end

local root = ReanUI.init(800, 600)
local gp = ReanUI.create("div", { id = "gp" })
local p = ReanUI.create("div", { id = "p" })
local c = ReanUI.create("button", { id = "c" }, "ok")
root:appendChild(gp)
gp:appendChild(p)
p:appendChild(c)

local order = {}

local cap = function(e) order[#order + 1] = "gp-cap" end
local bub = function(e) order[#order + 1] = "gp-bub" end
local pbub = function(e)
    order[#order + 1] = "p-bub"
    e:stopPropagation()
end
local target = function(e) order[#order + 1] = "c-target" end

gp:addEventListener("click", cap, true)
gp:addEventListener("click", bub)
p:addEventListener("click", pbub)
c:addEventListener("click", target)

local ok = c:dispatchEvent("click", { detail = "x" })
assertTrue(ok == true, "dispatch debe devolver true cuando no hay preventDefault")
assertTrue(table.concat(order, ",") == "gp-cap,c-target,p-bub", "orden de propagacion invalido")

local onceCount = 0
c:addEventListener("once", function() onceCount = onceCount + 1 end, { once = true })
c:dispatchEvent("once")
c:dispatchEvent("once")
assertTrue(onceCount == 1, "listener once debe ejecutarse una sola vez")

-- Debe no romper el dispatch al lanzar error en callback
c:addEventListener("boom", function() error("boom") end)
local ok2 = c:dispatchEvent("boom")
assertTrue(ok2 == true, "dispatch debe continuar aunque un listener falle")

print("PASS tests/test_event_system.lua")
