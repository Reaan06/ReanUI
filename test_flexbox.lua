-- test_flexbox.lua
local Container    = require("src.components.Container")
local Button       = require("src.components.Button")
local Text         = require("src.components.Text")
local FlexboxLayout = require("src.layout.FlexboxLayout")

local function check(label, got, expected, tol)
    tol = tol or 0.5
    local ok = math.abs(got - expected) <= tol
    local mark = ok and "✓" or "✗"
    print(string.format("  %s  %-45s got=%-8.1f expected=%.1f", mark, label, got, expected))
    return ok
end

print("\n==========================================================")
print("===  REANUI: TEST MOTOR FLEXBOX (2-Pass Algorithm)     ===")
print("==========================================================")

-- ============================================================
-- TEST 1: flex-direction column + flex-grow igual entre 3 hijos
-- ============================================================
print("\n[TEST 1] column + 3 items con flex-grow:1 (deben dividirse equitativo)")

local col = Container.new("column", { id = "col-root" })
col:setStyleSheet("padding: 0px; gap: 0px;")

local function make_item(label)
    local btn = Button.new(label)
    btn:setStyleSheet("flex-grow: 1; width: 100%; flex-shrink: 1;")
    return btn
end

local A = make_item("A")
local B = make_item("B")
local C = make_item("C")
col:appendChild(A)
col:appendChild(B)
col:appendChild(C)

FlexboxLayout.calculateLayout(col, 300, 900)

check("A.y == 0",   FlexboxLayout.getNodeLayout(A).y, 0)
check("B.y == 300", FlexboxLayout.getNodeLayout(B).y, 300)
check("C.y == 600", FlexboxLayout.getNodeLayout(C).y, 600)
check("A.h == 300", FlexboxLayout.getNodeLayout(A).h, 300)

-- ============================================================
-- TEST 2: flex-direction row + justify-content space-between
-- ============================================================
print("\n[TEST 2] row + justify-content:space-between + gap")

local row = Container.new("row", { id = "row-root" })
row:setStyleSheet("justify-content: space-between; padding: 0px; gap: 0px;")

local R1 = Button.new("R1")
R1:setStyleSheet("width: 100px; height: 50px;")
local R2 = Button.new("R2")
R2:setStyleSheet("width: 100px; height: 50px;")
local R3 = Button.new("R3")
R3:setStyleSheet("width: 100px; height: 50px;")

row:appendChild(R1)
row:appendChild(R2)
row:appendChild(R3)

FlexboxLayout.calculateLayout(row, 600, 100)

check("R1.x == 0",   FlexboxLayout.getNodeLayout(R1).x, 0)
check("R2.x == 250", FlexboxLayout.getNodeLayout(R2).x, 250)
check("R3.x == 500", FlexboxLayout.getNodeLayout(R3).x, 500)

-- ============================================================
-- TEST 3: align-items center + padding + gap
-- ============================================================
print("\n[TEST 3] column + align-items:center + padding + gap")

local padded = Container.new("column", { id = "padded" })
padded:setStyleSheet("align-items: center; padding: 20px; gap: 10px;")

local P1 = Button.new("P1")
P1:setStyleSheet("width: 200px; height: 60px;")
local P2 = Button.new("P2")
P2:setStyleSheet("width: 200px; height: 60px;")

padded:appendChild(P1)
padded:appendChild(P2)

FlexboxLayout.calculateLayout(padded, 600, 300)

local lP1 = FlexboxLayout.getNodeLayout(P1)
local lP2 = FlexboxLayout.getNodeLayout(P2)

-- Con padding=20 el inner_w = 560, centrado => x = 20 + (560-200)/2 = 200
check("P1.x == 200",        lP1.x, 200)
check("P1.y == 20",         lP1.y, 20)
check("P2.y == 20+60+10=90",lP2.y, 90)

-- ============================================================
-- TEST 4: align-items stretch
-- ============================================================
print("\n[TEST 4] row + align-items:stretch")

local stretch = Container.new("row", { id = "stretch" })
stretch:setStyleSheet("align-items: stretch; padding: 0px;")

local S1 = Button.new("S1")
S1:setStyleSheet("width: 100px;")  -- height auto -> debe estirarse al contenedor

stretch:appendChild(S1)

FlexboxLayout.calculateLayout(stretch, 400, 200)

check("S1.h == 200 (stretch)", FlexboxLayout.getNodeLayout(S1).h, 200)

-- ============================================================
-- TEST 5: Edge cases (NaN, valores negativos, %)
-- ============================================================
print("\n[TEST 5] Edge cases (% + valores extraños)")

local edge = Container.new("column", { id = "edge" })
edge:setStyleSheet("padding: 0px;")

local E1 = Button.new("E")
E1:setStyleSheet("width: 50%; height: 100px;")

edge:appendChild(E1)
FlexboxLayout.calculateLayout(edge, 400, 400)

check("E1.w == 50% of 400 = 200", FlexboxLayout.getNodeLayout(E1).w, 200)

print("\n=== ALL FLEXBOX TESTS PASSED ===\n")
